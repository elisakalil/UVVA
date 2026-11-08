# Plano · Friends

> Status: partes A a E feitas · 2026-11-08
> Spec: [`FRIENDS.md`](../Features/Friends/FRIENDS.md) v0.3 (FRI-R01 a R22). Backend: [`ARCHITECTURE.md`](../../Architecture/ARCHITECTURE.md) §3.2, §4.4, §5. Cálculos: [`MATCH.md`](../Features/Shared/MATCH.md). Design: canvas UVVA App, artboard Friends (telas 01 a 12).
> A aba é feita em 5 partes (A a E). Push, link/QR de convite e foto do amigo ficam para depois (§9).

## 1. O que existe hoje

| Peça | Estado |
| --- | --- |
| Aba | `AppTab.friends` existe; o `RootTabView` mostra `TabPlaceholder` |
| `Friend` (Core) | `id`, `name`, `compatibility`. Sem mapa nem avatar |
| `SocialService` | `publishContactKey`, `accounts(forPhones:)`, `sendFriendRequest(from:to:)`, `publish(_:)`, `removeContactKey`, `deleteAccount`. Não lê pedidos, não aceita, não lê perfis por id |
| `CloudKitSocialService` | Grava `FriendRequest` `<de>-<para>` com `status = pending`. Nenhum código lê esses registos |
| `PublicProfile` | `id`, `firstName`, `map?`, `hasMap`. Sem foto. Publicado pelo `AppCoordinator` a cada mudança do mapa |
| Onboarding › Contacts | `FindContactsOnUVVAUseCase` e `SendFriendRequestUseCase`. Os pedidos já são enviados ("Requested") |
| Contatos | `ContactsProviding`, `DeviceContact`, `DeviceContacts` vivem **dentro do Onboarding**. O Friends não os pode importar (APP-R06) |
| Loja Pessoal | Não há `FriendEntity` nem `FriendsStore` (a ARCHITECTURE §2.1 prevê `Friend`) |
| Home | `HomeContentModel.friends` existe, mas o `LoadHomeUseCase` passa sempre `[]`. O `FriendsCard` só abre o convite (`.noFriends`) |
| Match | `Similarity.percent` (usuário × vinho) e `Pairing.crossed/recipe`. Nada para mesas, eixos em comum ou etiquetas |
| Partilha | `ShareScreen`, `ShareFormat`, `InstagramStorySharing`, `ActivityShareSheet` (DesignSystem), usados pelo mapa e certificados |

## 2. Problema do backend: quem pode escrever no `FriendRequest`

Na base pública do CloudKit, o papel por omissão é *World: read · Authenticated: create · Creator: write*. Só quem **criou** um registo pode alterá-lo. A ARCHITECTURE diz que quem recebe muda o `status` para `accepted`, mas isso falha: o registo é de quem enviou.

**Proposta: amizade = dois pedidos, um em cada sentido.** Ninguém altera o registo do outro.

| Situação | Registos na base pública |
| --- | --- |
| A pediu B (FRI-R08) | `A-B` |
| B aceitou (FRI-R08a) | `A-B` e `B-A` (B cria o seu) |
| Os dois pediram (FRI-R08b) | `A-B` e `B-A`: amigos sem aceitar, pela mesma regra |
| B recusou | Só `A-B`. B guarda a recusa na Loja Pessoal (`DeclinedRequest`); A continua a ver "Requested" e não é avisado |
| A cancela o pedido (D11) | A apaga `A-B` |
| A remove B (D4) | A apaga `A-B`. Sem par, deixam de ser amigos nos dois lados |

Assim o `status` deixa de ser necessário (fica `pending`/`accepted` só para leitura no Dashboard), e a FRI-R08b sai de graça. Quem enviou descobre a aceitação ao ler `FriendRequest` com `to = eu` e encontrar o `B-A`.

**Dashboard:** índices *queryable* em `FriendRequest.to` (já previsto), `FriendRequest.from` e `recordName`. Atualizar a ARCHITECTURE §2.1, §3.2 e §4.4 com esta regra.

**Privacidade (ver decisão N2):** o `PublicProfile` é legível por qualquer conta autenticada que saiba o `id`. A FRI-R08 ("ninguém vê o paladar antes de aceitar") é cumprida pela app, não pelo CloudKit. Sem servidor não há como fechar isto.

## 3. Domínio (Core, Match, Storage · `swift test`)

| Tipo | Package | Para quê |
| --- | --- | --- |
| `Friend` (alterado) | Core | `id`, `name`, `map: PalateMap`, `addedAt`. A `compatibility` deixa de ser guardada: é calculada com o mapa do usuário. A foto fica para a N3 |
| `FriendRequestRecord` | Core | `from`, `to`, `createdAt`: o que o CloudKit devolve |
| `Friendship` | Core | Função pura: pedidos (enviados e recebidos), recusas locais, sugestões tiradas → `friends`, `incoming`, `outgoing` (§2). É o centro dos testes da FRI-R08 a R09 |
| `ContactsProviding`, `DeviceContact`, `ContactsAccess` | Core | Movidos do Onboarding. `ContactsAccess`: `.notDetermined`, `.granted`, `.denied` (para o botão dos Ajustes, FRI-R07a) |
| `SocialService` (novos métodos) | Core / Storage | `friendRequests(to:)`, `friendRequests(from:)`, `profiles(ids:)`, `deleteFriendRequest(from:to:)`. `deleteAccount` passa a apagar também os pedidos (ARCHITECTURE §4.5) |
| `FriendsRepository` | Core | `friends()`, `replaceFriends(_:)` (cache), `declinedRequests()`, `decline(_:)`, `dismissedSuggestions()`, `dismissSuggestion(_:)`, `lastTable()`, `saveLastTable(_:)` |
| `FriendEntity`, `DeclinedRequestEntity`, `DismissedSuggestionEntity`, `LastTableEntity` | Storage | Loja Pessoal, regras do CloudKit (tudo com padrão, sem `.unique`). `FriendEntity` guarda nome e mapa (JSON) como cache, para a aba abrir sem rede |
| `FriendsStore` | Storage | `@ModelActor`, implementa `FriendsRepository`. Feito em `AppStores.make` |
| `DeviceContacts` | target da app | Implementação com `Contacts` (sai do Onboarding para `UVVA/App/Services/`) |
| `TableMatch` | Match | `compatibility`, `tableCompatibility`, `sharedAxes`, `axisSpread`, `tableBottles` (§4) |
| `TableBottle`, `TableCourse`, `AxisSpread`, `Table` | Core | Resultado das mesas: garrafa, curso (Starter, Main, Dessert), prato, eixo, porquê |

O Onboarding passa a receber `ContactsProviding` do Core; o seu comportamento não muda.

## 4. Cálculos da mesa (`TableMatch`, Match)

Proposta de valores, a confirmar (decisão N4) e a escrever no `MATCH.md`:

- **`compatibility(a, b)`** = `Similarity.percent(a, b)`, a mesma distância do vinho (QUIZ-R21). Um só critério na app.
- **`tableCompatibility(mapas)`** = média de `Similarity.between` de cada par, em %.
- **`sharedAxes(mapas)`**: eixos em que todos estão em ≥ 5,5 e a diferença entre o maior e o menor valor é ≤ 1,5; ordenados pela média, no máximo 3.
- **`axisSpread(mapas, eixo)`** pela diferença máx − mín: **Same** ≤ 0,5 · **Closest** ≤ 1,5 · **Some give** ≤ 3 · **Widest** > 3.
- **`tableBottles(mapas)`**: o mapa cruzado é a média de todos (`Pairing.crossed` generalizado). Para cada curso (Starter, Main, Dessert), a receita do curso mais próxima do mapa cruzado e o vinho mais próximo do mapa cruzado entre os tipos dessa receita, sem repetir vinhos. O eixo de cada garrafa é o eixo em comum em que ela é mais alta (ou o eixo mais alto do mapa cruzado, se não houver eixos em comum); o porquê vem das frases de leitura que o Match já tem (`Reading`).

Testes no `MatchTests`: os critérios da FRI-R19 (intervalo 6 a 8, frase sem eixos), pares simétricos, mesa de 2 = compatibilidade do par, garrafas distintas e sempre 3 quando o catálogo tem vinhos dos três tipos.

## 5. Feature `Friends` (Features package)

Novo target `Friends` (dependências `common` + `match`) e `FriendsTests`, no padrão do Cellar e do You: `ObservableObject` com `@Published private(set) var uiModel`, protocolo por ecrã, builders puros, use cases, `Preview/` com mocks, `Resources/Localizable.xcstrings`.

```
Friends/
  DependencyInjection/Factory/FriendsFactory(+Protocol).swift
  UseCases/ RefreshFriendsUseCase, FindQuickAddUseCase, SendRequestUseCase, AcceptRequestUseCase,
            DeclineRequestUseCase, DismissSuggestionUseCase, CancelRequestUseCase, BuildTableUseCase
  Screens/
    FriendsList/      lista, pedidos recebidos, Quick add, vazio, modo de escolha (FRI-R04 a R09, R18)
    FriendProfile/    tabs Palate · Compatibility · Table (FRI-R10 a R13, R15 a R17)
    GroupTable/       resultado da mesa de grupo (FRI-R19)
    TableShare/       WhatsApp · Story · Save image (FRI-R21, R22)
  Preview/
```

**Atualização dos dados.** Sem push (até a parte F), a aba chama `RefreshFriendsUseCase` ao aparecer e no *pull to refresh*, no máximo uma vez a cada 30 s. Ele lê os pedidos nos dois sentidos, aplica `Friendship`, lê os `PublicProfile` dos amigos e grava a cache. Enquanto lê, a lista mostra a cache.

**Navegação.** O `AppCoordinator` ganha `friends: FriendsViewModel?`, feito em `prepareTabs`. A Home não importa o Friends (APP-R06): ela pede rotas ao coordinator (`openFriendsTable(lastTable)`, `openFriendsSelection`), que muda para a aba e chama o view model.

## 6. Partes

### A · Domínio e backend · feita (2026-11-08)

Feito como descrito, com estes ajustes: o `Friendship` devolve também `lapsed` (pedidos meus a quem me removeu, para os apagar); a Home calcula a compatibilidade do card com `TableMatch.compatibility` (`FriendsCardState.hasMatch(name:compatibility:)`); o `DemoSocial` tem Marina (amiga), Bia (pedido recebido) e Rui (pedido enviado). Falta no Dashboard: índices *queryable* em `FriendRequest.from` e `recordName`. Remover um amigo (parte B) apaga o próprio pedido **e** grava um `DeclinedRequest`, para o pedido que sobra do outro lado não aparecer como pedido recebido.

1. Mover `ContactsProviding`/`DeviceContact` para o Core e `DeviceContacts` para o target da app; ajustar Onboarding e `DemoMode`.
2. `FriendRequestRecord`, `Friendship` e testes (enviado, aceite, os dois pediram, recusado, cancelado, removido).
3. Novos métodos do `SocialService` no `CloudKitSocialService` e no stub do `DemoMode` (com pedidos e amigos falsos para o simulador).
4. Entidades, `FriendsStore`, `FriendsRepository` e testes de Storage.
5. `TableMatch` e testes. Atualizar `MATCH.md` e ARCHITECTURE.

### B · A aba: lista, pedidos e Quick add · feita (2026-11-08)

Feito como descrito. Target `Friends` (`FriendsFactory`, `FriendsViewModel`, `FriendsPresentationBuilder`, use cases em `UseCases/`), ligado no `AppCoordinator` e no `RootTabView` (sai o `TabPlaceholder`). Detalhes:
- O tab lê o perfil e o mapa a cada abertura; a base pública no máximo a cada 30 s (`refreshInterval`), e sempre no *pull to refresh*.
- Add, Accept, Requested (cancela, D11) e `×` mudam o ecrã logo e voltam atrás se o CloudKit recusar.
- Quick add usa o nome da agenda; deixa de fora amigos, quem já pediu (aparece em "Requests") e os tirados com `×`.
- Vazio (D2): "Your table is empty" + "Invite friends", que abre o `ShareScreen` com o `PalateShareCard` e o link `uvva.app/invite/<id>`.
- Home: o `LoadHomeUseCase` lê os amigos do `FriendsRepository`; o card com amigos abre a aba Friends (até as partes C e D darem a última mesa e o modo de escolha).
- Avatar: o `Avatar` sem foto (N3).

1. Target `Friends`, `FriendsFactory`, ligação no `RootTabView`/`AppCoordinator` (sai o `TabPlaceholder`; `backdropFrame` passa a incluir `.friends`).
2. Lista (FRI-R04): ordem alfabética, assinatura do paladar em caixa alta, %, "[n] friends".
3. Pedidos recebidos no topo (FRI-R08a): Accept → "[nome] is now your friend."; Decline silencioso.
4. Quick add (FRI-R07 a R09): contatos com conta **e mapa**, sem amigos, sem pedidos já enviados (mostram "Requested") e sem os tirados com `×`. Estados de acesso: pedir de novo / botão dos Ajustes.
5. Vazio (FRI-R06, decisão D2).
6. Home: o `LoadHomeUseCase` lê `FriendsRepository` e calcula a compatibilidade; o `FriendsCard` com 1 amigo abre a última mesa, com 2+ abre a escolha (HOME-R11).

### C · Um amigo e a mesa para dois · feita (2026-11-08)

Feito como descrito. `Screens/FriendProfile` (`FriendProfileViewModel`, builder, três tabs) abre em `fullScreenCover` ao tocar num amigo. Detalhes:
- Palate: `PalateMapChart` e as leituras, com a linha passada para o DesignSystem (`PalateReadingLine`, também usada pelo You).
- Compatibility: os dois mapas com o `comparison` do `PalateMapChart` (o do usuário por baixo); "Open this together" com eixo e porquê ("Where your maps meet: …" num eixo em comum, "Leans on …" fora deles).
- Table: o menu Starter/Main/Dessert de `TableMatch.tableBottles` sobre o catálogo do aparelho (`BuildTableUseCase`, fora da main thread). Abrir a tab Table guarda a última mesa (FRI-R17).
- Home: o card com 1 amigo abre a última mesa (ou a do único amigo) na tab Table; com 2+, a aba Friends (até a parte D).
- Remover (D4): no menu `…` do perfil, com confirmação. Apaga o próprio pedido, grava um `DeclinedRequest` e tira o amigo da cache e da última mesa.
- Os textos e as garrafas partilhados entre a mesa para dois e a de grupo ficam em `Shared/` (`TableBottleUIModel`, `TableBottlesBuilder`, `TableResourcesUIModel`).
- **Ver no simulador:** em Debug, o argumento `-UVVADemoAccount` troca o CloudKit pelo `DemoSocial` (`AppStores.makeSocial`): Marina amiga, pedido da Bia, pedido ao Rui. Os mapas do demo têm 0 nos eixos que não definem, por isso as compatibilidades saem baixas.

1. Perfil com três tabs (FRI-R10).
2. Palate (FRI-R11), reaproveitando o radar e as leituras do You/Quiz (`PalateRadar`, `PalateMapChart`).
3. Compatibility (FRI-R12): %, mapas sobrepostos, frase de `sharedAxes`, "Open this together".
4. Table (FRI-R13, R15): menu Starter/Main/Dessert, rodapé. Guardar a última mesa (FRI-R17).

### D · Mesa de grupo · feita (2026-11-08)

Feito como descrito: modo de escolha na lista (máximo 5 amigos, D6), `Screens/GroupTable` (match, frase, "Where the table lands" com `PalateMapChart(outline:)` para a leitura mais alta, "Reading by reading" recolhida, garrafas e menu), a última mesa de grupo guardada e reaberta pela Home, e "Set a table with your friends" a abrir a escolha. Falta ver no simulador o caminho da Home para a escolha (só testado no código).

1. Modo de escolha na lista (FRI-R18): botão inativo com < 2, "Find a bottle for these [n]", máximo (D6).
2. Resultado (FRI-R19): compatibilidade da mesa, frase, "Where the table lands" (média + "The boldest reading" a tracejado — o `PalateRadar` precisa de uma segunda série tracejada, no DesignSystem), "Reading by reading" recolhida, garrafas e menu.
3. "Set a table with your friends" da Home abre esta escolha (FRI-R20).

### E · Partilhar uma mesa · feita (2026-11-08)

"Share" no fim da tab Table e da mesa de grupo (inativo até as garrafas chegarem) abre o `ShareScreen` com o `TableShareCard`: Story "Tonight's table" com o menu, WhatsApp "You're invited to dinner" com o menu compacto e a mensagem completa (nomes, menu, "Dinner at mine?…", link), e Save image com o guia de compras ("What to buy": curso, "Ask for: produtor nome ano", prato). O `ShareScreen` ganhou `savedCard` (opcional) para o Save image guardar uma imagem diferente da Story. Link `https://uvva.app/t/<amigos>-<usuário>` sem acentos (D9: sem página ainda). A descrição de Fotos (`NSPhotoLibraryAddUsageDescription`) passou a falar também do menu.

1. Três formatos com o `ShareScreen` (FRI-R21): convite WhatsApp, Story "Tonight's table", guia de compras em Save image.
2. Texto do grupo (FRI-R22). Link `uvva.app/t/[mesa]` só como texto até a D9.

## 7. Testes (`FriendsTests` e Core)

Um teste por critério da spec, com `TableMatch` falso de valores fixos, como pede a FRI §3:
- Ordem Bia, Marina, Rui; linha com "ACIDITY · FRUIT · BODY" e "82%".
- Add → "Requested" e fora da lista; Accept → amigo e mensagem; Decline → some, sem registo no CloudKit; os dois pediram → amigos.
- Contato sem Quiz fora do Quick add; aparece quando o `PublicProfile.hasMap` passa a verdadeiro.
- Frases de `sharedAxes` com 0, 1, 2 e 3 eixos (dois e grupo).
- Modo de escolha: 1 escolhido inativo, 3 → "Find a bottle for these 3", tocar de novo desfaz.
- Convite com "Marina & Elisa" e `uvva.app/t/marina-elisa`.

## 8. Decisões

Da spec (com proposta):

| | Pergunta | Proposta |
| --- | --- | --- |
| **D2** | Lista vazia | Quick add + um card "Invite friends" com o link `uvva.app/invite/<id>` (o mesmo da Home) |
| **D4** | `×` volta? Remover amigo? | `×` é definitivo (guardado na Loja Pessoal). Remover existe, no perfil do amigo, sem aviso (§2) |
| **D6** | Máximo da mesa | 6 pessoas (o usuário + 5) |
| **D10** | Notificação e lugar do pedido | Secção "Requests" no topo da lista agora; push na parte F |
| **D11** | Pedido expira? Cancelar? | Não expira. Tocar em "Requested" cancela (apaga o registo) |
| **D9** | Link da mesa sem app | Fica para quando houver página em `uvva.app`; até lá, o link vai só no texto |

Novas:

| | Pergunta | Proposta |
| --- | --- | --- |
| **N1** | Amizade por dois registos em vez de mudar o `status` (§2) | Sim |
| **N2** | O mapa no `PublicProfile` é legível por quem souber o `id` | Aceitar e documentar; o Quick add do Onboarding já mostra uma frase do paladar antes do pedido |
| **N3** | Foto do amigo | Por agora o `Avatar` sem foto; foto como `CKAsset` no `PublicProfile` na parte F |
| **N4** | Limites do `TableMatch` (§4) | Os valores da §4 |
| **N5** | Mapa privado (YOU-R22) esconde também dos amigos? | Sim: sem mapa público, o amigo aparece com "Map hidden" e não entra em mesas. Contradiz a FRI-R01 e precisa de regra na spec |

## 9. Depois

- **F · Push:** `CKQuerySubscription` em `FriendRequest` com `to` = meu `id` (entitlement `aps-environment`, `registerForRemoteNotifications`).
- **Link e QR de convite:** `uvva.app/invite/<id>` como Universal Link (precisa do `apple-app-site-association` no domínio); abrir envia o pedido.
- Foto no `PublicProfile` (N3).
- Recalcular mesas guardadas quando um amigo refaz o Quiz (pergunta do `MATCH.md`): a última mesa guarda só os ids e é recalculada ao abrir.
