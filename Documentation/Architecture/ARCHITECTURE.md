# UVVA · Backend

## 1. Visão geral

```
  Aparelho (SwiftData)                          CloudKit
  ┌──────────────────────────┐                  ┌──────────────────────────────┐
  │ Loja "Pessoal"           │ ◄── sync auto ──►│ Base privada (iCloud do user)│
  │ Loja "Conteúdo"          │ ◄── sync app ────│ Base pública (todos)         │
  └──────────────────────────┘                  └──────────────────────────────┘
```

Não há servidor próprio. A equipa da UVVA gere a base pública pelo CloudKit Dashboard.

## 2. SwiftData: duas lojas

| Loja | Conteúdo | Sincroniza |
| --- | --- | --- |
| **Pessoal** | Perfil, mapa, avaliações, Cellar, progresso, certificados, amigos, lembrete | Sozinha, com a base privada (SwiftData + CloudKit) |
| **Conteúdo** | vinhos, receitas, lições, glossário, perguntas do Quiz | Pela app, a partir da base pública (secção 4) |

As duas lojas ficam no mesmo `ModelContainer` (`AppStore.makeContainer`, package `Storage`), com duas `ModelConfiguration`: `Application Support/Content/Content.store` e `Application Support/Personal/Personal.store`. Os modelos SwiftData levam o sufixo `Entity` (`PalateMapEntity`, `WineEntity`) para não colidirem com os tipos de domínio do `Core`. Não há relações entre elas: o Pessoal aponta para um vinho pela `wineKey`.

### 2.1 Loja Pessoal

| Tabela | Campos |
| --- | --- |
| `Profile` | id, authProvider, authUserID, firstName, phone?, mapIsPublic, seenTours, language |
| `PalateMap` | values, createdAt, history |
| `Rating` | wineKey, verdict, date |
| `CellarEntry` | wineKey, dados do vinho, status, verdict, note, photoFront, photoBack, createdAt, updatedAt |
| `LessonProgress` | lessonId, currentStep, answers, completedAt, lastOpenedAt |
| `Certificate` | courseId, date |
| `Friend` | friendID, addedAt |
| `Reminder` | slot, days |

**`Profile`**
- `id`: um UUID criado no cadastro (decidido em 2026-10-31). Sincroniza pela base privada, por isso é igual em todos os aparelhos com o mesmo iCloud, e nunca é mostrado. Não depende da Apple nem do CloudKit, para poder ser levado para outro backend (Android). É ele que identifica o usuário na base pública, nos links de convite (`uvva.app/invite/<id>`) e nos pedidos de amizade. Não há handle.
- `phone`: opcional, no formato E.164 (`+351912345678`).
- `seenTours`: a lista dos tours já vistos, por exemplo `["home"]`. Um tour aparece se o seu id não está na lista.

**`PalateMap`** (um por conta)
- `values`: o mapa atual, `[eixo: valor]`, com os 8 eixos e valores de 0 a 9 (`["acidity": 6.4, "fruit": 5.0, …]`).
- `createdAt`: quando este mapa nasceu ("Keep this map" no Quiz).
- `history`: uma entrada por mudança, da mais antiga para a mais recente. A primeira é o mapa do Quiz. É o que o You › Map › Over time mostra (YOU-R10).

```swift
struct MapChange: Codable {
    var date: Date
    var cause: Cause          // .quiz ou .rating(wineKey, verdict)
    var values: [PalateAxis: Double] // o mapa depois desta mudança
}
```

O "antes" de uma mudança é a entrada anterior; a variação de cada eixo é a diferença entre as duas (HOME-R16, HOME-R24).

- **Refazer o Quiz** cria um `PalateMap` novo: `values` e `createdAt` novos, e `history` recomeça só com o Quiz (QUIZ-R18a).
- **Avaliar um vinho** muda `values` e acrescenta uma entrada a `history`.
- **Editar ou apagar uma avaliação** (CELLAR-R29) recalcula `values` e `history` a partir da primeira entrada, reaplicando as `Rating` que ainda existem.

**`Rating`** fica numa tabela própria, só com o vinho, o veredito e a data, por dois motivos:
- **Sync:** se dois aparelhos avaliarem sem rede, o CloudKit fica com a última versão do `PalateMap` e perderia entradas do `history`. As `Rating` são registos separados e nunca se perdem, então a app reconstrói o `history` a partir delas depois do sync (4.2).
- **Refazer o Quiz:** o `history` recomeça, mas as avaliações continuam a contar como "vinho avaliado" na Home e no Cellar (SHARED-R11).

**`Friend`**
- `friendID`: o `id` do amigo. Com ele, a app lê o `PublicProfile` do amigo (nome, foto e mapa).
- Limites do SwiftData com CloudKit: sem `@Attribute(.unique)` (a app evita duplicados), todos os campos opcionais ou com valor padrão, fotos em `.externalStorage`.
- O `UserDefaults` guarda só o que é do aparelho: data do último sync, versão do conteúdo, vista do Cellar.

### 2.2 Loja Conteúdo

| Tabela | Chave | Origem |
| --- | --- | --- |
| `Wine` | wineKey | Bundle (10 000 iniciais), depois a base pública |
| `Recipe` | id | Bundle |
| `Module`, `Lesson` | id | Bundle |
| `GlossaryTerm` | id | Bundle |
| `QuizQuestion` | axis + version | Bundle |

Na primeira abertura, a app copia o bundle para esta loja. Receitas, lições, glossário e perguntas só mudam com uma versão nova da app.

- **De onde vem o bundle.** `Application/Data` é a fonte editável. O script `Application/Scripts/pack_content.py` valida-a e escreve `UVVA/Resources/Content/` (`wines`, `recipes`, `learn`, `glossary`, `quiz` e `manifest.json`), que vai para dentro da app.
- **Quando importa.** O `manifest.version` é um hash do conteúdo. A app importa quando ele é diferente do `content.version` guardado no `UserDefaults`, e só grava a versão nova no fim do import.
- **Como importa.** Um `ContentImporter` (`@ModelActor`, package `Storage`) corre fora da main thread, pela ordem perguntas e glossário, receitas, lições, vinhos. Receitas, lições, glossário e perguntas são substituídos; os vinhos são atualizados pela `wineKey`, e um vinho que veio da base pública, ou que está protegido (Cellar, avaliação), nunca é apagado.
- **Onde fica.** `Application Support/Content/Content.store`, fora do backup do iPhone (a loja reconstrói-se a partir do bundle).

**`wineKey`:** o identificador único de um vinho, igual ao campo `id` do `UVVAWines.json` e ao `recordName` do `CatalogWine`. É um slug de produtor, nome e ano, nesta ordem: minúsculas, sem acentos, e cada sequência de caracteres que não seja letra ou número vira um `-` (`isole-e-olena-chianti-classico-2010`). Sem limite de tamanho.
- **Vinho sem ano** (não vintage): o ano fica de fora da chave (`osborne-pedro-ximenez-1827-sweet-sherry-sherry`) e a app não mostra o ano.
- **Dois vinhos com o mesmo produtor, nome e ano** são vinhos diferentes com nome incompleto: o nome passa a incluir o que os distingue no rótulo, normalmente a denominação (`e-guigal-hermitage-white-2007` e `e-guigal-cotes-du-rhone-white-2007`). A chave nunca leva sufixos como `-2`.
- A mesma função calcula a chave no empacotamento do bundle, no Dashboard e nos vinhos escaneados (4.3), para que o mesmo vinho tenha sempre a mesma chave.

## 3. CloudKit: tabelas

### 3.1 Base privada

As tabelas da Loja Pessoal (2.1), criadas e sincronizadas pelo SwiftData. Ficam no iCloud do usuário, sem custo para a UVVA.

### 3.2 Base pública

| Tabela | recordName | Campos | Quem escreve |
| --- | --- | --- | --- |
| `CatalogWine` | wineKey | dados do vinho, 8 eixos, `segment`, status (`approved`, `pending`, `rejected`) | Equipa (Dashboard) e usuários (vinhos escaneados, como `pending`) |
| `PublicProfile` | id do usuário | firstName, avatar, values (vazio se o mapa não é público) | O dono |
| `ContactKey` | SHA-256(telefone E.164 + sal) | userID | O dono |
| `FriendRequest` | `<id de>-<id para>` | from, to, status (`pending`, `accepted`, `declined`) | Quem envia e quem recebe |
| `Announcement` | id | title, body, date | Equipa (Dashboard) |

- `recordName` igual à chave impede duplicados sem servidor: criar um registo que já existe falha.
- `segment` é um número que agrupa vinhos parecidos no paladar. Serve para pedir ao CloudKit só os vinhos certos (4.1). Como é calculado fica no [`MATCH.md`](../App/Features/Shared/MATCH.md).
- Índices no Dashboard: *queryable* em `CatalogWine.segment`, `CatalogWine.status`, `CatalogWine.modificationDate` e `FriendRequest.to`.

## 4. Sincronização

### 4.1 Vinhos: sempre 10 000 no aparelho

A base pública tem todos os vinhos. O aparelho guarda só 10 000, os mais úteis para o paladar do usuário.

A cada abertura da app (no máximo uma vez a cada 24 h):

1. **Pedir os novos.** A app pede ao CloudKit os `CatalogWine` com `status = approved`, `segment` entre os segmentos do mapa do usuário e `modificationDate` depois do último sync. No máximo 1000.
2. **Inserir.** Os novos entram na Loja Conteúdo.
3. **Remover os velhos.** Para voltar aos 10 000, a app apaga os vinhos com menor match com o paladar.
4. **Guardar a data** do sync no `UserDefaults`.

**Um vinho nunca é removido** se o usuário o tem no Cellar ou numa avaliação.

Quando o usuário refaz o Quiz e o mapa muda muito, os segmentos mudam. O sync seguinte ignora a data e pede os 1000 melhores dos segmentos novos.

### 4.2 Dados pessoais

O SwiftData sincroniza a Loja Pessoal com a base privada sozinho: grava no aparelho, sobe quando há rede, e recebe as mudanças de outros aparelhos com o mesmo iCloud.

- **Telefone novo:** depois do login, a app procura o `Profile` na base privada. Se existe, os dados descem e o usuário entra direto.
- **Conflitos:** o CloudKit fica com a última versão de cada registo. As `Rating` nunca se perdem, porque só são acrescentadas. Depois de receber `Rating` de outro aparelho, a app reconstrói `values` e `history` do `PalateMap` a partir delas.

### 4.3 Vinhos escaneados

1. O usuário fotografa um rótulo e avalia o vinho.
2. Se a `wineKey` não está na Loja Conteúdo, a app cria um `CatalogWine` com `status = pending`, só com os dados do vinho (sem fotos, nota ou veredito).
3. A equipa aprova no Dashboard. Aprovado, o vinho entra no sync de todos (4.1).

### 4.4 Amigos e mapa público

- **Mapa público:** a cada mudança do `PalateMap`, a app atualiza o seu `PublicProfile`.
- **Quick add:** a app calcula a chave de cada telefone da agenda e pede esses `ContactKey` ao CloudKit de uma vez. Os que existem são contatos na UVVA.
- **Pedido de amizade:** "Add" cria um `FriendRequest`. Quem recebe aceita, e os dois gravam um `Friend` com o `id` do outro na Loja Pessoal.
- **Ver o paladar de um amigo:** a app lê o `PublicProfile` dele.

## 5. Notificações

| Notificação | Quem envia |
| --- | --- |
| Pedido de amizade recebido ou aceito | **CloudKit:** `CKQuerySubscription` em `FriendRequest` com `to` = meu `id` |
| Avisos da equipa (lição nova, novidades) | **CloudKit:** `CKQuerySubscription` em `Announcement`; a equipa cria o registo no Dashboard e todos recebem |
| Mudanças nos dados pessoais | **CloudKit**, silenciosa (o SwiftData usa-a para sincronizar) |
| Lembrete diário | **Local**, agendada no aparelho (`UNUserNotificationCenter`) |
| Certificado ganho | **Local**, na hora |

O CloudKit envia push sem custo, mas só quando um registo é criado ou alterado. Não dá para enviar uma notificação a um usuário específico sem criar um registo para ele.

## 6. Custos

O CloudKit, as notificações e o login com Apple ou Google são grátis. Os únicos custos são o Apple Developer Program (99 €/ano) e o domínio `uvva.app` dos links de convite.

## 7. Dúvidas em aberto

- [ ] **Quantos vinhos entram por sync?** 1000 por dia é o máximo, ou o número depende de quantos vinhos novos existem?
- [ ] **Moderação.** Quem aprova os vinhos `pending` e com que frequência? Um vinho `pending` aparece para quem o escaneou?
- [x] **Sem iCloud.** O iCloud é obrigatório: sem sessão no iCloud não há amigos reais nem sync. A Welcome avisa e pede para entrar no iCloud nas Definições (2026-10-31).
- [ ] **Mapa não público.** Desligar o mapa público o esconde também dos amigos já aceitos?
