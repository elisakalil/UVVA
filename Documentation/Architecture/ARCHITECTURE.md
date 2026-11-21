# UVVA · Backend

## 1. Visão geral

```
  Aparelho (SwiftData)                          CloudKit
  ┌──────────────────────────┐                  ┌──────────────────────────────┐
  │ Loja "Pessoal"           │ ◄── sync auto ──►│ Base privada (iCloud do user)│
  │ Loja "Conteúdo"          │ ◄── sync app ────│ Base pública (todos)         │
  └──────────────────────────┘ ── leituras ────►└──────────────▲───────────────┘
                                                               │ 1×/dia
                                                  Robô (GitHub Actions)
```

Não há servidor próprio nem equipa a operar. O catálogo de vinhos vive na base pública e cresce com o uso: cada rótulo lido é uma contribuição, e um robô diário conta as contribuições e publica o catálogo (4.1, 4.3, 4.6).

## 2. SwiftData: duas lojas

| Loja | Conteúdo | Sincroniza |
| --- | --- | --- |
| **Pessoal** | Perfil, mapa, avaliações, Cellar, progresso, certificados, amigos, lembrete | Sozinha, com a base privada (SwiftData + CloudKit) |
| **Conteúdo** | vinhos, receitas, lições, glossário, perguntas do Quiz, leituras por enviar | Vinhos: pela app, a partir da base pública (4.1). O resto: do bundle |

As duas lojas ficam no mesmo `ModelContainer` (`AppStore.makeContainer`, package `Storage`), com duas `ModelConfiguration`: `Application Support/Content/Content.store` e `Application Support/Personal/Personal.store`. Os modelos SwiftData levam o sufixo `Entity` (`PalateMapEntity`, `WineEntity`) para não colidirem com os tipos de domínio do `Core`. Não há relações entre elas: o Pessoal aponta para um vinho pela `wineKey`.

### 2.1 Loja Pessoal

| Tabela | Campos |
| --- | --- |
| `Profile` | id, authProvider, authUserID, firstName, phone?, photo?, mapIsPublic, seenTours, language |
| `PalateMap` | values, createdAt, history |
| `Rating` | wineKey, verdict, date |
| `CellarEntry` | wineKey, dados do vinho, status, verdict, note, photoFront, photoBack, createdAt, updatedAt |
| `LessonProgress` | lessonId, currentStep, answers, completedAt, lastOpenedAt |
| `Certificate` | courseId, date |
| `Friend` | friendID, name, values, addedAt (cache do `PublicProfile`) |
| `DeclinedRequest` | userID, declinedAt |
| `DismissedSuggestion` | userID, dismissedAt |
| `LastTable` | friendIDs, openedAt |
| `Reminder` | hour, minute, moment?, weekdays |

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

O "antes" de uma mudança é a entrada anterior; a variação de cada eixo é a diferença entre as duas (HOME-R16).

- **Refazer o Quiz** cria um `PalateMap` novo: `values` e `createdAt` novos, e `history` recomeça só com o Quiz (QUIZ-R18a).
- **Avaliar um vinho** muda `values` e acrescenta uma entrada a `history`.
- **Editar ou apagar uma avaliação** (CELLAR-R29) recalcula `values` e `history` a partir da primeira entrada, reaplicando as `Rating` que ainda existem.

**`Rating`** fica numa tabela própria, só com o vinho, o veredito e a data, por dois motivos:
- **Sync:** se dois aparelhos avaliarem sem rede, o CloudKit fica com a última versão do `PalateMap` e perderia entradas do `history`. As `Rating` são registos separados e nunca se perdem, então a app reconstrói o `history` a partir delas depois do sync (4.2).
- **Refazer o Quiz:** o `history` recomeça, mas as avaliações continuam a contar como "vinho avaliado" na Home e no Cellar (SHARED-R11).

**`Friend`**
- `friendID`: o `id` do amigo. Com ele, a app lê o `PublicProfile` do amigo (nome, foto e mapa).
- `name` e `values` são uma cópia do `PublicProfile`, atualizada a cada refresh, para a aba abrir sem rede. A amizade em si está na base pública (4.4).
- `DeclinedRequest`: pedidos recusados, só nesta conta, para quem enviou não ser avisado (FRI-R08a). `DismissedSuggestion`: sugestões tiradas do Quick add com `×` (FRI-R09). `LastTable`: quem estava na última mesa (FRI-R17); a mesa é recalculada ao abrir.
- Limites do SwiftData com CloudKit: sem `@Attribute(.unique)` (a app evita duplicados), todos os campos opcionais ou com valor padrão, fotos em `.externalStorage`.
- O `UserDefaults` guarda só o que é do aparelho: data do último sync, versão do conteúdo, vista do Cellar.

### 2.2 Loja Conteúdo

| Tabela | Chave | Origem |
| --- | --- | --- |
| `Wine` | wineKey | A base pública (4.1); `source`: `catalog`, `scanned` (lido aqui e ainda fora do catálogo) ou `bundle` (o catálogo das versões antigas, até o primeiro snapshot) |
| `PendingContribution` | wineKey | Leituras de rótulo por enviar à base pública (4.3) |
| `CatalogState` | — | Onde está a cópia do catálogo: última mudança recebida, último pedido, versão e `prevalence` do snapshot |
| `Recipe` | id | Bundle |
| `Module`, `Lesson` | id | Bundle |
| `GlossaryTerm` | id | Bundle |
| `QuizQuestion` | axis + version | Bundle |

Receitas, lições, glossário e perguntas vêm no bundle e só mudam com uma versão nova da app. **Os vinhos não vêm no bundle**: vêm da base pública, para nunca ficarem desatualizados.

- **De onde vem o bundle.** `Application/Data` é a fonte editável. O script `Application/Scripts/pack_content.py` valida-a e escreve `UVVA/Resources/Content/` (`recipes`, `learn`, `glossary`, `quiz` e `manifest.json`), que vai para dentro da app. Os vinhos (`Data/UVVAWines.json`) são a semente do catálogo público: o script valida-os e, com `--seed`, entrega-os ao robô (4.6).
- **Quando importa.** O `manifest.version` é um hash do conteúdo. A app importa quando ele é diferente do `content.version` guardado no `UserDefaults`, e só grava a versão nova no fim do import.
- **Como importa.** Um `ContentImporter` (package `Storage`) corre fora da main thread, pela ordem perguntas e glossário, receitas, lições, e substitui-os. Os vinhos escreve-os o `CatalogWriter` (4.1).
- **Onde fica.** `Application Support/Content/Content.store`, fora do backup do iPhone (a loja reconstrói-se a partir do bundle e da base pública; as leituras ainda por enviar perdem-se com ela).

**`wineKey`:** o identificador único de um vinho, igual ao campo `id` do `UVVAWines.json` e ao `recordName` do `CatalogWine`. É um slug de produtor, nome e ano, nesta ordem: minúsculas, sem acentos, e cada sequência de caracteres que não seja letra ou número vira um `-` (`isole-e-olena-chianti-classico-2010`). Sem limite de tamanho.
- **Vinho sem ano** (não vintage): o ano fica de fora da chave (`osborne-pedro-ximenez-1827-sweet-sherry-sherry`) e a app não mostra o ano.
- **Dois vinhos com o mesmo produtor, nome e ano** são vinhos diferentes com nome incompleto: o nome passa a incluir o que os distingue no rótulo, normalmente a denominação (`e-guigal-hermitage-white-2007` e `e-guigal-cotes-du-rhone-white-2007`). A chave nunca leva sufixos como `-2`.
- A mesma função calcula a chave no `pack_content.py`, na app (`WineKey`) e no robô, para que o mesmo vinho tenha sempre a mesma chave. O robô recusa uma contribuição cuja chave não é a do seu produtor, nome e ano.

## 3. CloudKit: tabelas

### 3.1 Base privada

As tabelas da Loja Pessoal (2.1), criadas e sincronizadas pelo SwiftData. Ficam no iCloud do usuário, sem custo para a UVVA.

### 3.2 Base pública

| Tabela | recordName | Campos | Quem escreve |
| --- | --- | --- | --- |
| `CatalogWine` | wineKey | `data` (o vinho em JSON, `CatalogWineData`), `status` (`active` ou `removed`), `tokens` (palavras do nome e do produtor) | Só o robô |
| `CatalogSnapshot` | `current` | `version`, `builtAt`, `wineCount`, `prevalence` (Top X%), `wines` (asset: o catálogo inteiro, JSON zlib), `state` (asset: o estado do robô) | Só o robô |
| `WineContribution` | SHA-256(wineKey + id do usuário) | `wineKey`, `contributor` (id do usuário), `data` (o vinho como o rótulo o mostrou) | O usuário que leu; só ele e o robô a leem |
| `PublicProfile` | id do usuário | firstName, avatar, values (vazio se o mapa não é público) | O dono |
| `ContactKey` | SHA-256(telefone E.164 + sal) | userID | O dono |
| `FriendRequest` | `<id de>-<id para>` | from, to, status (`pending`, só informativo) | Quem envia (só o criador altera ou apaga) |
| `SharedWine` | `<id de>-<id para>-<wineKey>` | from, fromName, to, wineID, wineName, sentAt, snapshot (o vinho em JSON, `SharedWineSnapshot`) | Quem envia (só o criador altera ou apaga); FRIENDS FRI-R11b |
| `Announcement` | id | title, body, date | A Elisa (Dashboard) |

- `recordName` igual à chave impede duplicados sem servidor: criar um registo que já existe falha.
- Os nomes das tabelas e dos campos do catálogo estão em `CatalogSchema` (Core), partilhado pela app e pelo robô.
- Índices e permissões no Dashboard: secção 4.6.
- Na base pública só o criador de um registo o pode alterar. Por isso ninguém muda o `FriendRequest` do outro: a amizade são dois pedidos, um em cada sentido (4.4).

## 4. Sincronização

### 4.1 Vinhos: o catálogo público no aparelho

A base pública tem o catálogo inteiro. O aparelho guarda uma cópia (`CatalogSync`, package `Storage`), para o scan, a Home, a mesa dos amigos e o Top X% funcionarem sem rede.

1. **Primeira vez.** A app descarrega o `CatalogSnapshot` (o catálogo inteiro num ficheiro, ~3 MB) enquanto o usuário faz o Onboarding e o Quiz. As abas esperam por ele; sem rede, a app mostra o erro e "tentar de novo".
2. **Depois, no máximo uma vez por dia** (a cada abertura): a app pede os `CatalogWine` com `modificationDate` depois da última mudança que recebeu. Entram os vinhos novos e os enriquecidos; os `removed` saem do aparelho. Não bloqueia nada: corre por trás.
3. **Top X%.** O snapshot traz a `prevalence` medida no catálogo; a app passa a usá-la (`QualityPrevalence.current`). Até lá, usa a do `pack_content.py` (`QualityPrevalence.packed`).
4. **Aparelho cheio.** Acima de 50 000 vinhos (`CatalogSchema.deviceCap`), saem os mais longe do paladar do usuário.
5. **Rótulo que o aparelho não tem.** O scan (e a entrada manual) pergunta à base pública pelos `tokens` do nome e do produtor; o vinho encontrado fica no aparelho.

**Um vinho nunca sai do aparelho** se está no Cellar ou numa avaliação, nem se foi lido aqui e ainda não está no catálogo.

**Atualização da app.** Quem já tinha os 10 000 vinhos do bundle continua a usá-los; o primeiro snapshot substitui-os por trás.

### 4.2 Dados pessoais

O SwiftData sincroniza a Loja Pessoal com a base privada sozinho: grava no aparelho, sobe quando há rede, e recebe as mudanças de outros aparelhos com o mesmo iCloud.

- **Telefone novo:** depois do login, a app procura o `Profile` na base privada. Se existe, os dados descem e o usuário entra direto.
- **Conflitos:** o CloudKit fica com a última versão de cada registo. As `Rating` nunca se perdem, porque só são acrescentadas. Depois de receber `Rating` de outro aparelho, a app reconstrói `values` e `history` do `PalateMap` a partir delas.

### 4.3 Vinhos escaneados: cada leitura é uma contribuição

1. O usuário lê um rótulo (ou escreve o vinho) e guarda a nota.
2. `CatalogStore.addScanned` guarda o vinho no aparelho e põe na fila (`PendingContribution`) o que foi lido: um vinho fora do catálogo com todas as leituras daqui somadas, ou um vinho do catálogo com o que o rótulo acrescentou. **Só os dados do vinho**: nunca fotos, nota pessoal ou veredito.
3. A app envia a fila como `WineContribution` do usuário quando as abas abrem e depois de cada nota. Sem iCloud ou sem rede, espera pela próxima vez. Os vinhos escaneados antes desta versão entram na fila uma vez.
4. O robô (4.6) conta as contribuições, sem ninguém a aprovar:
   - **Vinho novo:** entra no catálogo quando **2 usuários diferentes** (contados pelo `creatorUserRecordID` do CloudKit, que ninguém falsifica) leram a mesma `wineKey`. O mapa é estimado pelos vinhos mais parecidos, como a app faz (`ProfileEstimate`). Sem tipo conhecido, espera.
   - **Vinho do catálogo:** ganha uma uva, um pairing, um aroma ou um prémio quando 2 usuários o leram; e um dado que não tinha (álcool, temperatura, menção) quando 2 concordam. O que a semente diz nunca é substituído.
   - **Regras contra abuso:** chave igual ao produtor + nome + ano, textos e listas com tamanho máximo, ano entre 1900 e o próximo, álcool entre 3 e 25%, sem links nem endereços, e no máximo 100 contribuições por usuário por dia.
   - Um vinho promovido fica, mesmo que quem o leu apague a conta.
5. No dia seguinte, o vinho chega a todos pelo sync (4.1).

### 4.4 Amigos e mapa público

- **Mapa público:** a cada mudança do `PalateMap`, a app atualiza o seu `PublicProfile`.
- **Quick add:** a app calcula a chave de cada telefone da agenda e pede esses `ContactKey` ao CloudKit de uma vez. Os que existem são contatos na UVVA.
- **Pedido de amizade:** "Add" cria o `FriendRequest` `A-B`. Dois usuários são amigos quando existem `A-B` e `B-A` (`Friendship`, Core):
  - **Aceitar** é criar o pedido de volta, `B-A`. Se os dois pediram, já são amigos (FRI-R08b).
  - **Recusar** grava um `DeclinedRequest` só na conta de quem recusa; `A-B` fica, e A continua a ver "Requested".
  - **Cancelar** (D11) ou **remover um amigo** (D4) é apagar o próprio pedido. Quem foi removido vê, no refresh seguinte, um pedido seu sem par a um amigo da cache, e apaga-o também.
  - A cada refresh, a app lê os pedidos com `to` = eu e `from` = eu, aplica o `Friendship`, lê os `PublicProfile` dos amigos e grava a cache `Friend`.
- **Ver o paladar de um amigo:** a app lê o `PublicProfile` dele.
- **Mapa privado (YOU-R22):** com "Make chart public" desligado, o `PublicProfile` continua a existir (nome e `hasMap`), mas sem o mapa.

### 4.5 Sair e apagar a conta

- **Sign out:** os dados ficam no iCloud. Uma flag local (`session.signedOut`) leva a app à Welcome até o próximo login.
- **Apagar a conta (YOU-R27):** primeiro a base pública (`PublicProfile`, `ContactKey` e as `WineContribution` do usuário), depois a Loja Pessoal (Profile, mapas, lembrete), as leituras por enviar e as notificações locais. Se a base pública falhar, nada é apagado e o usuário tenta de novo. Os vinhos que já entraram no catálogo ficam: não têm dados de ninguém.
- **Apagar a conta** apaga também os `FriendRequest` enviados. Os recebidos são de quem os enviou e não podem ser apagados; sem `PublicProfile`, ficam fora de todas as listas.
- **Falta antes do TestFlight:** revogar o token do Sign in with Apple (a App Store exige; precisa de um servidor com a chave privada, previsto num Cloudflare Worker).

### 4.6 O robô do catálogo

`Application/Robot` (package Swift, usa `Core` e `Match`) corre todos os dias às 04:17 UTC no GitHub Actions (`.github/workflows/catalog-robot.yml`), também quando `Data/UVVAWines.json` ou o próprio robô mudam no `main`, ou à mão (*Run workflow*, com *dry run* para só ver o que faria). Corre uma vez por ambiente do CloudKit (`development` e `production`). Se falhar, o GitHub envia um e-mail; o snapshot anterior continua a valer e a corrida seguinte refaz o que faltou.

Cada corrida:

1. Valida a semente (`pack_content.py --seed`) e corre os testes do robô.
2. Lê o seu estado (o asset `state` do snapshot) e as `WineContribution` mudadas desde a última corrida, e depois todas as dos mesmos vinhos.
3. Aplica as regras de 4.3 e monta o catálogo: a semente, enriquecida, mais os vinhos que os usuários deram a conhecer.
4. Escreve só os `CatalogWine` que mudaram (e marca `removed` os que saíram), mede a `prevalence` e publica o `CatalogSnapshot`.

**Configurar uma vez** (o único trabalho manual; depois não há nada a cuidar):

1. **Chave.** Gerar a chave e a parte pública:
   `openssl ecparam -name prime256v1 -genkey -noout -out eckey.pem` e `openssl ec -in eckey.pem -pubout`.
   No CloudKit Console › `iCloud.app.uvva` › *Tokens & Keys* › *Server-to-Server Keys*, criar uma chave em **Development** e outra em **Production** com a parte pública. Cada uma dá um *Key ID*.
2. **Segredos no GitHub** (Settings › Secrets and variables › Actions): `CLOUDKIT_DEVELOPMENT_KEY_ID`, `CLOUDKIT_DEVELOPMENT_PRIVATE_KEY` (o conteúdo de `eckey.pem`) e os dois `CLOUDKIT_PRODUCTION_…`. Um ambiente sem segredos é saltado.
3. **Tabelas** (Schema › Record Types, em Development). Uma chave de servidor não cria tabelas, então o robô precisa delas antes da primeira corrida:
   - `CatalogWine`: `data` (String), `status` (String), `tokens` (String List).
   - `CatalogSnapshot`: `version` (String), `builtAt` (Date/Time), `wineCount` (Int(64)), `prevalence` (String), `wines` (Asset), `state` (Asset).
   - A `WineContribution` nasce com a primeira nota guardada num build de Debug com iCloud.
   - `SharedWine` (enviar um vinho a um amigo, FRIENDS FRI-R11b): `from`, `fromName`, `to`, `wineID`, `wineName`, `snapshot` (String), `sentAt` (Date/Time). Ainda por fazer: ver a nota "Falta no CloudKit" no FRIENDS.md.
4. **Índices** (Schema › Indexes), *queryable*: `recordName` e `modificationDate` em `CatalogWine` e `WineContribution`; `CatalogWine.status`, `CatalogWine.tokens`; `WineContribution.wineKey`, `WineContribution.contributor`. Sem o de `modificationDate`, o robô para com «Field '___modTime' is not marked queryable». Depois disso, *Run workflow* publica os 10 000 vinhos em Development.
   - `SharedWine` (FRIENDS FRI-R11b) nasce com o primeiro vinho enviado num build de Debug com iCloud; precisa de `recordName`, `to` e `from` *queryable* e `sentAt` *sortable*. Sem o de `to`, nem a lista "Sent to you" nem a subscrição das notificações funcionam.
5. **Permissões** (Schema › Security Roles): em `CatalogWine` e `CatalogSnapshot`, `_icloud` só lê (sem *create*); um papel `Robot` com *create* e *write* nas duas, dado ao usuário dono da chave. Em `WineContribution`, `_world` sem nada, `_icloud` *create*, `_creator` *read* e *write*, e `Robot` *read*. Em `SharedWine`, `_icloud` *create* e *read* (quem recebe lê o registo de quem enviou), `_creator` *write*.
6. **Deploy Schema Changes** para Production, e correr o workflow outra vez para publicar em Production. Só então um build de TestFlight ou da App Store tem catálogo.

## 5. Notificações

| Notificação | Quem envia |
| --- | --- |
| Pedido de amizade recebido ou aceito | **CloudKit:** `CKQuerySubscription` em `FriendRequest` com `to` = meu `id` |
| Vinho enviado por um amigo | **CloudKit:** `CKQuerySubscription` `shared-wines-<id>` em `SharedWine` com `to` = meu `id`, criada quando o usuário passa a ter um amigo; o texto é `SHARED_WINE_ALERT` (Localizable da app) com `fromName` e `wineName`; tocar abre o vinho na aba Friends (FRIENDS FRI-R11c) |
| Avisos da UVVA (lição nova, novidades) | **CloudKit:** `CKQuerySubscription` em `Announcement`; a Elisa cria o registo no Dashboard e todos recebem |
| Mudanças nos dados pessoais | **CloudKit**, silenciosa (o SwiftData usa-a para sincronizar) |
| Lembrete diário | **Local**, agendada no aparelho (`UNUserNotificationCenter`) |
| Certificado ganho | **Local**, na hora |

O CloudKit envia push sem custo, mas só quando um registo é criado ou alterado. Não dá para enviar uma notificação a um usuário específico sem criar um registo para ele.

## 6. Custos

O CloudKit, as notificações, o login com Apple ou Google e o robô (GitHub Actions num repositório público) são grátis. Os únicos custos são o Apple Developer Program (99 €/ano) e o domínio `uvva.app` dos links de convite.

## 7. Dúvidas em aberto

- [x] **Quantos vinhos entram por sync?** Todos os que mudaram desde o último; o aparelho guarda até 50 000 (2026-11-13).
- [x] **Moderação.** Ninguém aprova: um vinho entra quando 2 usuários o leram, com regras automáticas contra abuso (4.3). Quem o leu vê-o logo no aparelho (2026-11-13).
- [x] **Sem iCloud.** O iCloud é obrigatório: sem sessão no iCloud não há amigos reais nem sync. A Welcome avisa e pede para entrar no iCloud nas Definições (2026-10-31).
- [ ] **Mapa não público.** Desligar o mapa público o esconde também dos amigos já aceitos?
