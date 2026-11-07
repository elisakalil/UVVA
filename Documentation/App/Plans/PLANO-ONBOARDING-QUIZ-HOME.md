# UVVA · Plano: Onboarding, Quiz e Home com tour

> Status: v0.1 · 2026-10-31 · proposta para revisão
> Base: `UVVA.MD`, `ARCHITECTURE.md`, `PROJECT.md`, `ONBOARDING.md`, `QUIZZ.md`, `HOME.md`, `SHARED.md`, `MATCH.md`, canvas UVVA Telas (Onboarding, Quiz, HomeTour, Glossário) e Design System (README, tokens).

## 0. Decisões já tomadas (2026-10-31)

| Tema | Decisão |
| --- | --- |
| Login | Só **Sign in with Apple** nesta entrega. Google entra depois, atrás do mesmo protocolo `AuthProvider` |
| IDs | Bundle ID **`app.uvva`**, container **`iCloud.app.uvva`** (o projeto hoje usa `app.uvva.UVVA2`) |
| Telefone (D8) | **Seletor de país**, padrão pelo locale do aparelho, validação pelo tamanho de cada país, gravado em E.164 |
| Plataforma | Só iOS agora, mas o código tem de deixar a porta aberta para Android (secção 9) |
| iCloud | **Obrigatório**: sem iCloud não há amigos reais. Sem sessão, a Welcome avisa e pede para entrar no iCloud nas Definições |
| Idioma do conteúdo | Vinhos, receitas, lições, glossário e perguntas do Quiz **só em inglês** por agora. A interface continua em String Catalog (en + pt-BR, SHARED-R19a) |
| Algoritmo | O `ALGORITMO.md` é o `MATCH.md` (referências corrigidas) |

## 1. O que já existe

- Projeto Xcode (`objectVersion 77`, pastas sincronizadas), iOS 18, Swift 5, team `39AJ27VU38`.
- Um target único com `Features/Home` (cards, `HomeCardsBuilder` com testes), `Shared/DesignSystem` (tokens, vidro, tab bar) e `Shared/Domain` (`Axis`, `PalateMap`, `Similarity`), tudo com mocks.
- Conteúdo em `Application/Data`:

| Arquivo | Conteúdo | Tamanho |
| --- | --- | --- |
| `UVVAWines.json` | 10 000 vinhos, mapa de 8 eixos, nota, uvas, tipo, serviço | 9,3 MB |
| `UVVARecipes.json` | 500 receitas, mapa, `twist`, sabor, ingredientes, passos | 1,1 MB |
| `Learn/{Path,Grapes,Region}` | 130 módulos, 1012 arquivos (index, module, lições com 9 tipos de passo) | 4,9 MB |

**Falta no bundle** (existe só no canvas):
- **Glossário**: 40 termos em `Glossario.dc.html` (`[term, lesson, definition, pronunciation, aka]`).
- **Perguntas do Quiz**: 8 eixos × 3 versões × 10 respostas em `Quiz.dc.html` (`QUESTIONS`).

Vou extraí-los para `Application/Data/Glossary/glossary.json` e `Application/Data/Quiz/questions.json`, para que tudo o que vai para a Loja Conteúdo saia da mesma pasta.

**Dados dos vinhos, corrigidos em 2026-10-31**
- **Um só identificador.** A `wineKey` é o `id` do `UVVAWines.json`: slug de produtor, nome e ano, sem limite de tamanho (regra na ARCHITECTURE §2.2). Os `id` antigos eram cortados aos 60 caracteres (466 vinhos perdiam o ano ou parte do nome) e foram recalculados.
- **Vinhos sem ano.** 4195 vinhos não têm ano: a chave fica sem ano e a app não mostra o ano (nem o espaço dele) nesses vinhos.
- **Nomes repetidos.** 2 pares tinham o mesmo produtor, nome e ano, mas são vinhos diferentes, de denominações diferentes. O nome passou a incluir a denominação: E. Guigal *Hermitage White* e *Côtes-du-Rhône White* 2007; Collovray et Terrier *Saint-Véran Vieilles Vignes* e *Pouilly-Fuissé Vieilles Vignes* 2012.
- `segment` não existe nos vinhos. O cálculo vai para o `MATCH.md` (secção Segmento). Não bloqueia esta entrega: só o sync do catálogo o usa.
- O `UVVAWines.json` vem do `Data/vinhos.json`, mas o script que o gera não está no repositório. Se ele for gerado de novo, esse script tem de usar a mesma regra de `id`.

## 2. Estrutura do projeto

Segue `PROJECT.md` (SPM local, MVVM com `UIModel`, uma entidade por arquivo), com uma mudança proposta: **separar `Core` em dois**, para o domínio não depender de SwiftData nem CloudKit (secção 9).

```
Application/
├── UVVA.xcodeproj
├── UVVA/                         Target da app: entrada, coordenador, rotas
│   ├── App/                      UVVAApp, AppCoordinator, AppRoute, RootTabView
│   └── Resources/
│       ├── Fonts/  Assets.xcassets  Localizable.xcstrings
│       └── Content/              GERADO por Scripts/pack_content.py (não editar)
│           ├── manifest.json     { version, counts, sha256 }
│           ├── wines.json  recipes.json  learn.json  glossary.json  quiz.json
├── Data/                         Fonte editável do conteúdo (já existe)
├── Scripts/pack_content.py       Valida e empacota Data/ → Resources/Content/
└── Packages/
    ├── Core/          Domínio puro, só Foundation: Axis, PalateMap, Verdict, MapChange,
    │                  Wine/Recipe/Lesson como structs, protocolos dos serviços
    ├── Storage/       SwiftData (@Model das duas lojas), ContentImporter, CloudKit   ← novo
    ├── Match/         Similaridade, atualização por avaliação, vinho × receita
    ├── DesignSystem/  Tokens, FrostedCard, TabBar, GrapeSheet, Radar, Progress…
    └── Features/
        ├── Onboarding/
        ├── Quizz/
        └── Home/
```

| Package | Depende de | Porta para Android? |
| --- | --- | --- |
| `Core`, `Match` | — / `Core` | Sim, Swift puro |
| `Storage` | `Core` | Não (SwiftData, CloudKit) — é a peça trocada |
| `DesignSystem`, `Features/*` | `Core`, `DesignSystem`, `Match` | Não (SwiftUI) |

As features nunca importam `Storage`: recebem protocolos de `Core` (`ProfileRepository`, `ContentRepository`, `AuthProvider`, `SocialService`). O target da app monta as implementações reais e injeta-as.

O código atual migra assim: `Shared/DesignSystem` → `DesignSystem`, `Shared/Domain` → `Core` + `Match`, `Features/Home` → `Features/Home`, `Mocks` → pasta `Preview` de cada package.

**Ajustes do projeto**
- Bundle ID `app.uvva`, testes `app.uvva.tests`.
- Capabilities: Sign in with Apple, iCloud (CloudKit, `iCloud.app.uvva`), Push Notifications, Background Modes › Remote notifications (o SwiftData usa push silencioso para sincronizar).
- Swift 6 com concorrência estrita nos packages novos.
- Mínimo iOS 18 (SwiftData com `#Index` e `#Unique` precisa dele).

## 3. Conteúdo: do bundle para o SwiftData

### 3.1 Empacotar (no Mac, antes do build)

`Scripts/pack_content.py` lê `Application/Data`, valida e escreve `UVVA/Resources/Content/`:

- **wines.json**: os vinhos, com a `wineKey` conferida (o script recalcula-a e falha se não bater com o `id`) e o mapa como objeto (`{"floral": 6.2, …}`) em vez da lista de objetos de uma chave.
- **recipes.json**: igual, com o mapa como objeto.
- **learn.json**: os 130 módulos com as lições dentro, num só arquivo. Evita levar 1012 arquivos (vários com o mesmo nome, `module.json`, `index.json`) e a pasta `_src` para dentro da app.
- **glossary.json**, **quiz.json**: extraídos do canvas.
- **manifest.json**: `version` (um hash dos arquivos empacotados: muda sozinho quando o conteúdo muda, sem ninguém ter de o subir à mão), contagens e o hash de cada arquivo.

O script falha se um eixo faltar, sair de 0…9, se houver chaves repetidas ou se um passo de lição não tiver os campos do seu tipo. Correr o script é um passo manual sempre que `Data/` muda (documentado no README do Scripts).

### 3.2 Importar (no aparelho)

Na primeira abertura, e sempre que `manifest.version` for diferente da versão guardada no `UserDefaults` (`content.version`), o `ContentImporter` (um `@ModelActor`, fora da main thread) copia o conteúdo para a Loja Conteúdo enquanto o Splash e o Onboarding correm (ONB-R01).

| Ordem | O quê | Porquê nesta ordem |
| --- | --- | --- |
| 1 | `QuizQuestion` (24), `GlossaryTerm` (40) | O Quiz não pode esperar (responde à D10: o Splash não espera por nada) |
| 2 | `Recipe` (500) | A Home precisa |
| 3 | `Module`, `Lesson` | Learn |
| 4 | `Wine` (10 000), em lotes de 500 com `save()` por lote | É o mais pesado; o Onboarding + Quiz levam minutos, o import leva poucos segundos |

- Receitas, lições, glossário e perguntas: apaga e insere de novo (só mudam com versão nova da app).
- Vinhos: *upsert* pela `wineKey`. Nunca apaga um vinho que veio do sync da base pública nem um que esteja no Cellar ou numa avaliação (ARCHITECTURE §4.1).
- A versão só é gravada no fim. Se a app fechar a meio, o import recomeça do zero na abertura seguinte.
- O estado (`ContentStatus`: `importing(etapa)` / `ready`) é observável. Se a Home abrir antes de os vinhos estarem prontos, mostra a GrapeSheet.

### 3.3 Onde ficam os arquivos

| Loja | Arquivo | `cloudKitDatabase` | Backup do iPhone |
| --- | --- | --- | --- |
| Conteúdo | `Application Support/Content.store` | `.none` | Excluído (regenerável) |
| Pessoal | `Application Support/Personal.store` | `.private("iCloud.app.uvva")` | Sim |

As duas num só `ModelContainer`, com duas `ModelConfiguration`, cada uma com o seu `Schema`. Sem relações entre lojas (o Pessoal aponta para o vinho pela `wineKey`).

### 3.4 Modelos da Loja Conteúdo

| `@Model` | Campos | Índices |
| --- | --- | --- |
| `WineEntity` | wineKey (o `id` do JSON), name, producer, vintage?, origin, region, country, grapes, type, alcohol, servingMin/Max, pairings, classification, findIt, note, os 8 eixos como `Double` separados, segment?, source (`bundle`/`catalog`) | `#Unique(wineKey)`, `#Index` em type, region, country, segment |
| `RecipeEntity` | id, title, why, course, mainIngredient, cuisine, season, diet, allergens, wineTypes, os 8 eixos, servings, prep/cook, difficulty; `twist`, `flavor`, `ingredients`, `steps` como `Codable` | `#Unique(id)`, `#Index` em course |
| `ModuleEntity` | id, kind (path/grape/region), order, title, description, xp, minutes, complexity, meta (`Codable`: level, color, country…), `lessons` (cascade) | `#Index` em kind+order |
| `LessonEntity` | id, moduleId, order, title, subtitle, xp, minutes, isReview, objectives, `stepsData` (JSON dos passos, decodificado só ao abrir a lição) | `#Index` em moduleId |
| `GlossaryTermEntity` | id, term, pronunciation, definition, aka, lessonRef | — |
| `QuizQuestionEntity` | axis, version (1…3), prompt, answers (10) | `#Unique(axis, version)` |

Os modelos SwiftData levam o sufixo `Entity`, para não colidirem com os tipos de domínio do `Core` (`Wine`, `GlossaryTerm`). O `GlossaryTermEntity.lesson` guarda o número de lição que o canvas usa, que ainda não corresponde a nenhum id de `Data/Learn`.

Os eixos ficam em colunas próprias (e não num dicionário) para o SwiftData poder filtrar e ordenar vinhos por eixo sem carregar os 10 000.

### 3.5 Modelos da Loja Pessoal (nesta entrega)

Regras do SwiftData + CloudKit: sem `#Unique`, todos os campos opcionais ou com padrão, a app evita duplicados.

| `@Model` | Campos |
| --- | --- |
| `Profile` | id, authProvider, authUserID, firstName, phone?, phoneCountry?, photo? (external storage), mapIsPublic, seenTours, language, createdAt |
| `PalateMapRecord` | values (`[String: Double]`), createdAt, history (`[MapChange]`) |
| `ReminderEntity` | hour, minute, moment?, weekdays (vazio = desligado). As notificações locais são do aparelho: ao entrar numa conta já existente, a app volta a agendá-las |

`Rating`, `CellarEntry`, `LessonProgress` e o resto entram com as suas features. A Home já lê "sem avaliações, sem amigos, sem lições" corretamente com listas vazias.

## 4. Sessão e rotas

O `AppCoordinator` (target da app) decide para onde vai depois do Splash (ONB-R02):

```
sem Profile                → Welcome
Profile e sem mapa         → Quiz, entrada .firstMap
Profile e com mapa         → Tabs (Home)
"Sign out" ativo            → Welcome
```

- **Sign out (YOU-R26).** Os dados ficam; uma flag `session.signedOut` (UserDefaults) manda a app para a Welcome até o próximo login, que encontra a conta (ONB-R27).
- **Apagar a conta (YOU-R27).** Primeiro a base pública (PublicProfile e ContactKey); só depois o iCloud (Profile, mapas, lembrete) e as notificações. Se a base pública falhar, nada local é apagado e aparece um aviso. Falta revogar o token da Apple (Cloudflare Worker, antes do TestFlight) e apagar os FriendRequests (com o Friends).

- **Antes do Telefone** (ONB-R02a) nada vai para o SwiftData: nome e identidade ficam num `OnboardingDraft` em memória.
- **Nome da Apple só chega uma vez.** A Apple devolve o nome só na primeira autorização. Se a app fechar entre o login e o Telefone, o cadastro recomeça e o nome perdia-se. Guardo o nome devolvido no Keychain, pela `authUserID`, até o `Profile` ser criado.
- **Credencial revogada.** A cada abertura, `ASAuthorizationAppleIDProvider.getCredentialState`. Se estiver revogada, a sessão termina e volta à Welcome.
- **Conta já existente (ONB-R27).** Num aparelho novo, o SwiftData ainda não terá descido o `Profile` logo depois do login. Depois do login, a app consulta a base privada diretamente (o registo `CD_Profile` na zona do SwiftData) com um limite de ~8 s, mostrando a GrapeSheet. Se o encontra, espera o primeiro import do SwiftData e segue a ONB-R27. Se não, é conta nova.

## 5. Onboarding (package `Features/Onboarding`)

| Peça | Tipo | Testes |
| --- | --- | --- |
| `OnboardingFlow` | Máquina de estados pura (`next`, `back`) | Todos os critérios de fluxo e voltar (ONB-R02, R20, R21, R36a) |
| `NameValidator` | Pura | ONB-R15, R16 |
| `PhoneNormalizer`, `PhoneValidator` | Puras, com tabela de países | E.164, tamanho por país, contatos sem indicativo |
| `AppleAuthProvider` | `AuthProvider` com `ASAuthorizationController` | Mock nos testes |
| `SocialService` | Protocolo: publicar `ContactKey`, procurar contatos, enviar `FriendRequest` | Mock; implementação CloudKit no `Storage` |

**Telas** (uma pasta por tela, APP-R04): `Splash` (7 quadros de 180 ms), `Welcome`, `Legal` (Terms / Privacy, texto mock), `Name` (01 / 02), `Phone` (02 / 02, seletor de país + teclado próprio), `FindFriends`, `Contacts` (duas listas, barra A–Z, Add → Requested, Invite → Invited).

**Telefone com seletor de país**: uso a biblioteca `PhoneNumberKit` (MIT, metadados do libphonenumber). Ela valida o tamanho real de cada país e, sobretudo, normaliza os números da agenda, que quase sempre estão sem indicativo. Sem isso o Quick add falha para a maioria dos contatos.

**Contatos**: iOS 18 tem acesso limitado aos contatos (`.limited`); trato-o como acesso dado, com só os contatos escolhidos.

**Privacidade da chave de contato.** Para o Quick add, cada telefone é publicado como um código (hash), e não como número. Mas quem souber um número pode calcular o código e ver se ele está na UVVA, e um programa pode testar todos os números de um país. O que fica exposto é só "este número usa a UVVA" (nunca o nome ou o mapa de quem não é amigo). É o mesmo que acontece no WhatsApp ou no Telegram; a Política de Privacidade só precisa de dizer que quem adiciona o telefone pode ser encontrado por quem tem esse número.

## 6. Quiz (package `Features/Quizz`)

| Peça | Tipo | Regras |
| --- | --- | --- |
| `QuizFlow` | Máquina de estados: intro, leitura 1…8, resultado; respostas e versão por eixo | QUIZ-R07 a R13a, R18 |
| `QuizExit` | `exit(for: QuizEntry)` | QUIZ-R24, R25 |
| `PalateMapBuilder` | Respostas → `PalateMap` | QUIZ-R04 |
| `MapReading` | Ranking, patamares, líderes, formato do mapa, frases, níveis | QUIZ-R05, R14 a R16, Anexo A |
| `ShareCardRenderer` | `ImageRenderer` em 9:16 e 4:5 | QUIZ-R19, R20, SHARED-R20 |

**Telas**: `Intro` (radar animado), `Reading` (barra de 10 posições, Change question), `Result`, `ShareSheet`.

**"Keep this map"** grava o `PalateMapRecord` com `history = [MapChange(.quiz)]`. Na entrada `.redo`, substitui o mapa atual (QUIZ-R18a).

**Partilha**:
- *Save image*: permissão só de adicionar fotos.
- *WhatsApp*: folha de partilha do iOS com a imagem 4:5 e a mensagem.
- *Story*: o Instagram exige um **Meta App ID** no `instagram-stories://share`. Até termos um, o Story usa a folha de partilha do iOS.

### 6.1 Padrões adotados no Quiz (dúvidas em aberto do QUIZZ.md)

| Dúvida | Padrão até decisão |
| --- | --- |
| D9 · Intro ao refazer | A mesma Intro, com um `‹` que sai sem mudar o mapa |
| D10 · Sair ao refazer | Só pelo `‹` da Intro, sem confirmação; nas leituras o `‹` volta uma leitura |
| D11 · Partilha ao refazer | A folha de partilha abre também ao refazer |
| `‹` no resultado | Volta à leitura 8 com as respostas (o "Read it again" é que apaga tudo) |
| Sem nome (antes da M3) | "Your taste in wine is" e "Drinks for…" |
| Story no Instagram | Pela folha de partilha do iOS, até haver um Meta App ID |

## 7. Home e tour (package `Features/Home`)

**Dados reais.** Um `HomeRepository` monta o `HomeState` a partir das lojas: nome e mapa (Pessoal); catálogo, receitas e glossário (Conteúdo). Amigos, cursos, avaliações e notificações chegam vazios até as suas features existirem. O `HomeCardsBuilder` e os cards atuais ficam.

**Não carregar 10 000 vinhos na Home.** As regras que precisam de "os mais semelhantes" (HOME-R06, R22) usam o package `Match` sobre uma pré-seleção feita no SwiftData (por exemplo, eixos dominantes do usuário dentro de ±2), e só depois ordenam por similaridade. O teste garante o mesmo resultado que ordenar o catálogo inteiro.

**Sugestão do dia** (HOME-R06, R07, MATCH.md), implementada assim até o `MATCH.md` definir o cálculo exato:
1. Os 30 vinhos com maior similaridade.
2. Um deles, sorteado com semente = dia local (fixo durante o dia, SHARED-R03).
3. Mapa do cruzamento = média do mapa do usuário e do vinho; a receita é a de menor distância a esse mapa, filtrada por `wineTypes` compatível com o tipo do vinho, com entradas e pratos principais antes de sobremesas, petiscos e queijos.

**Dados das receitas, corrigidos em 2026-10-31.** 203 receitas citavam um vinho, uma casta ou uma região no `why`, e algumas contradiziam o `wineTypes`. O `why` passou a descrever o estilo e o `wineTypes` passou a ser esse tipo. Lista completa, para revisão: [`RECEITAS-WHY-REESCRITAS.md`](RECEITAS-WHY-REESCRITAS.md).

**"Find the wine"** (cartão do dia) abre, dentro da app, uma pesquisa na internet com produtor, nome e ano (quando existe).

**Ainda não ligado na Home:** "Find my wine" (HOME-R26 a R28), os atalhos do Learn com módulos reais (HOME-R18), o sino e as notificações. Dependem de Cellar, Learn e notificações.

**Tour guiado** (HOME-R29 a R33):
- `GuidedTour` (estado puro: intro, passos 1…6, `next`, `back`, `pick`) e `shouldShowTour(quizExit:seenTours:)`, com testes de todos os critérios.
- Cada área destacada publica a sua moldura com `anchorPreference` (`TourTarget`: sugestão do dia, escolha o seu vinho, botão +, abas Learn, Cellar e Friends). A camada escura desenha o recorte a partir dessas molduras.
- No passo 2, `ScrollViewReader` rola até "Escolha o seu vinho" e o recorte segue.
- Durante o tour a Home não recebe toques. "Start" acrescenta `"home"` a `seenTours`.

**Dúvidas abertas da HOME que resolvo com um padrão, salvo indicação em contrário**:

| Dúvida | Padrão |
| --- | --- |
| Tour interrompido | Aparece de novo na abertura seguinte; só conta como visto em "Start" (implementado) |
| Pular o tour | Sem "Skip" |
| Passo 1 sem sugestão do dia | Destaca o card de amigos |
| Palavra do dia | Fixa durante o dia (semente = dia) (implementado) |
| Saudação depois do tour | "Welcome back" sempre |

## 8. Textos e idiomas

- String Catalog (`Localizable.xcstrings`) por package, em **en** e **pt-BR** (SHARED-R19a), criado à medida que cada tela é feita (os textos de um package usam `bundle: .module`). Escrevo as traduções em pt-BR e você revê.
- Perguntas do Quiz, textos por eixo (Anexo A), vinhos, receitas, lições e glossário ficam só em inglês por agora (decidido em 2026-10-31).

## 9. Android no futuro

**O que não passa para Android:** o CloudKit. A base privada só existe em aparelhos Apple. A base pública tem uma API web (CloudKit Web Services), mas o login nela é com Apple ID pela web: dá para ler o catálogo, não para ter os amigos e os mapas de quem usa Android.

**Então sim: com Android, os dados sociais (perfil público, amigos, pedidos, chaves de contato) precisam de um backend fora do CloudKit.** Alternativas sem servidor próprio e com plano gratuito: Firebase (Firestore + Auth com Apple e Google) ou Supabase (Postgres + Auth). O conteúdo (vinhos, receitas, lições) continua em JSON no bundle, igual nas duas plataformas.

**Swift no Android:** é possível. O Swift tem um SDK oficial para Android (grupo de trabalho Android do swift.org) e o Skip (skip.tools) converte SwiftUI em Jetpack Compose. Não há SwiftUI nem SwiftData nativos no Android, por isso o que se aproveita direto é o código Swift puro.

**O que este plano faz agora para não fechar a porta:**
1. `Core` e `Match` em Swift puro, sem SwiftUI, SwiftData nem CloudKit: compilam para Android sem mudanças.
2. Toda a rede passa por protocolos (`AuthProvider`, `SocialService`, `CatalogSyncService`). Trocar CloudKit por Firebase é escrever outra implementação, sem tocar nas features.
3. **O `Profile.id` passa a ser um UUID criado no cadastro**, em vez do `userRecordID` do CloudKit. Ele também sincroniza entre aparelhos pela base privada, mas não depende da Apple e pode ser levado para outro backend sem mudar links de convite nem amizades. **Isto muda o ARCHITECTURE §2.1 e precisa da sua aprovação.**
4. `authProvider` + `authUserID` (o `sub` da Apple ou do Google) continuam no perfil: são o que outro backend usaria para reconhecer a mesma pessoa.

**iCloud obrigatório** (decidido): sem sessão no iCloud, a Welcome avisa e pede para entrar nas Definições. Se um dia o backend for Firebase/Supabase, esta regra é revista.

## 10. Ordem de execução

Cada etapa termina com testes a passar e a app a abrir no simulador. Não faço commits.

| # | Etapa | Entrega |
| --- | --- | --- |
| M0 | Infra | **Feito em 2026-10-31.** Packages `Core`, `Match`, `DesignSystem` e `Features/Home`; código migrado (um tipo por arquivo); Swift 6; workspace `UVVA.xcworkspace` com o scheme UVVA a correr os 29 testes; capabilities e bundle ID `app.uvva` (feitos no Xcode pela Elisa) |
| M1 | Conteúdo | **Feito em 2026-10-31.** Package `Storage` (modelos `WineEntity`, `RecipeEntity`, `ModuleEntity`, `LessonEntity`, `GlossaryTermEntity`, `QuizQuestionEntity`), `Scripts/pack_content.py`, glossário e perguntas em `Data/Glossary` e `Data/Quiz`, `ContentImporter` e `ContentLoader` no arranque. 10 testes, um deles importa o conteúdo real. Import completo: ~3,3 s no simulador |
| M2 | Quiz | **Feito em 2026-10-31.** Package `Quizz` (Intro, Leitura, Resultado, Partilha), `MapUpdate` no `Match` (QUIZ-R22, R23), loja Pessoal com `PalateMapEntity`, `AppCoordinator` (sem mapa → Quiz, com mapa → abas). 29 testes no Quizz; 82 no total |
| M3 | Onboarding | **Feito em 2026-10-31.** Package `Onboarding` (Splash, Welcome, Legal, Nome, Telefone com seletor de país, Find friends, Contacts), Sign in with Apple com o nome guardado no Keychain, `ProfileEntity` com id UUID, `CloudKitSocialService` (chave de contato, perfil público, pedidos de amizade), rotas da ONB-R02. 126 testes no total |
| M4 | Home | **Feito em 2026-10-31.** `HomeViewModel` com dados reais (`CatalogStore`: os 33 vinhos mais próximos entre 10 000, receitas, glossário), sugestão do dia com a receita (`Pairing` no `Match`), convite com o link, tour guiado com recorte de luz (`SpotlightAnchors` no DesignSystem). 147 testes no total |
| M4b | You | **Feito em 2026-10-31.** Package `Features/You`: Progress (números a 0 até existirem Learn e Cellar; primeiro curso do path), Map (leitura, "Over time" com `MapEvolution` no `Match`, partilha, refazer → volta a You › Map), Settings (nome, telefone, foto, lembrete com 4 momentos + qualquer hora, mapa público, Sign out, Delete). `ReminderStore` e `LocalReminderScheduler`. Linha Language escondida até haver pt-BR. 21 testes no You; 181 no total. Testado no simulador em modo demo |
| M5 | Ligação | `AppCoordinator` com as rotas da ONB-R02, build no TestFlight |

## 11. O que fazer na Apple

Não há nada a fazer antes de eu começar. O código da M0 a M2 (packages, conteúdo, Quiz) não precisa de nada da Apple. Só a M3 (Sign in with Apple e iCloud) precisa de 2 passos no Xcode, que eu peço quando chegar lá.

**O que é o container iCloud.** É o "armário" da UVVA dentro do iCloud: o espaço onde ficam as duas bases do CloudKit (a privada de cada usuário e a pública dos amigos e do catálogo). Tem um nome, `iCloud.app.uvva`, e esse nome não pode ser apagado nem trocado depois de criado, por isso escolhemos já o definitivo.

**Antes da M3 (no Xcode, ~5 minutos):**
1. Xcode › Settings › Accounts: a sua Apple ID tem de aparecer com o team pago (o nome do team, não "Personal Team"). O team `39AJ27VU38` do projeto deve ser esse.
2. Eu mudo o bundle ID para `app.uvva` e adiciono as capabilities no projeto. Depois, no Xcode, no target UVVA › Signing & Capabilities: deixar "Automatically manage signing" ligado; na secção iCloud, carregar no `+` dos containers e criar `iCloud.app.uvva`. O Xcode regista o App ID e o container na sua conta sozinho.
3. No simulador (ou no iPhone de testes): entrar com uma Apple ID em Definições, para o login e o iCloud funcionarem.

**Antes do primeiro TestFlight (M5), eu guio passo a passo quando chegarmos lá:**
4. App Store Connect › Apps › `+`: criar a app "UVVA" com o bundle ID `app.uvva`.
5. CloudKit Console: *Deploy Schema to Production*, para as tabelas que o desenvolvimento criou existirem também na versão pública.
6. Um link público para a Política de Privacidade (a Apple exige) e o questionário de privacidade do App Store Connect.
7. Product › Archive no Xcode e enviar para o TestFlight.

**Para mais tarde:** um Meta App ID (grátis) para o Story do Instagram e o domínio `uvva.app` para os links de convite.

## 12. Decisões pendentes

- Nenhuma: UUID e `Core`/`Storage` aprovados.
