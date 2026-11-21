# UVVA · Friends

> Status: rascunho v0.3 · 2026-10-31 · amigos por pedido de amizade; Quick add pelos contatos sem SMS (ARCHITECTURE §4.4)
> Depende de: [`_shared.md`](_shared.md), [`quiz.md`](quiz.md), `match.md` (a escrever)
> Fonte: canvas UVVA App, artboard Friends (telas 01 a 12 e 11 fluxos).

## 1. Objetivo

A aba Friends junta o mapa do paladar do usuário com o dos amigos. Ela mostra a compatibilidade com cada amigo e monta mesas: uma **mesa para dois**, com um amigo, e uma **mesa de grupo**, com vários. Cada mesa traz três garrafas e um menu de jantar, que podem ser partilhados.

Pela SHARED-R01, não há limites de mesas nem desbloqueio pago. As telas "Table locked" (05 e 06), "Unlock this table · €1,99" e "Go Premium" estão fora de escopo.

## 2. Modelo

```swift
struct Friend { id; name; avatar; palateMap: PalateMap }    // sempre presente
struct ContactSuggestion { contactName; uvvaUserId }
struct Table { members: [Friend] /* + o usuário */; bottles: [TableBottle]; menu: [Course] }
```

**FRI-R01 · Todo amigo tem mapa.** Só se usa a UVVA depois de concluir o Quiz (ONB-R02). Um usuário que ainda não concluiu o Quiz não aparece no Quick add nem pode ser amigo. Portanto todo amigo tem mapa, compatibilidade e pode entrar numa mesa (SHARED-R13).

**Critérios**
- Dado um contato que criou conta mas ainda não concluiu o Quiz, então ele não aparece no Quick add.
- Quando esse contato conclui o Quiz, então ele passa a aparecer no Quick add.

## 3. Compatibilidade e mesas: `match.md`

Os cálculos de compatibilidade e das mesas ficam num arquivo próprio, `match.md` (a escrever). O Friends só usa o que ele devolve:

| Função (em `match.md`) | Usada em |
| --- | --- |
| `compatibility(mapaA, mapaB) -> Int` (0 a 100 %) | Lista (FRI-R04), Compatibility (FRI-R12), card da Home (HOME-R11) |
| `tableCompatibility(mapas) -> Int` | Mesa de grupo (FRI-R19) |
| `sharedAxes(mapas) -> [Axis]` (até 3) | Frases de Compatibility e da mesa de grupo |
| `axisSpread(mapas, eixo) -> Etiqueta` (Same, Closest, Some give, Widest) | Reading by reading (FRI-R19) |
| `tableBottles(mapas) -> [TableBottle]` e o menu | Open this together, The perfect table (FRI-R14, R15) |

Os testes do Friends usam versões falsas destas funções, com valores fixos. Os testes dos cálculos ficam em `match.md`.

## 4. Lista de amigos

**FRI-R04 · Lista.** O topo mostra "Your Friends" e o botão da mesa (FRI-R18), sem subtítulo. Por baixo vêm o Quick add (uma faixa horizontal), os pedidos recebidos e os amigos. Os amigos aparecem por ordem alfabética. Cada um mostra o nome, o avatar, a assinatura do paladar (a frase dominante da QUIZ-R15 em caixa alta, por exemplo "ACIDITY · FRUIT · BODY"), a compatibilidade em % e `›`. "[n] friends" fica só para o VoiceOver.

**FRI-R04a · Search by name.** Ao rolar a lista aparece "Search by name", como no Cellar. A busca mostra só os amigos cujo nome contém o texto, sem diferença de maiúsculas nem acentos; sem nenhum, "No friend by that name." Entrar no modo de escolha (FRI-R18) limpa a busca.

**FRI-R04b · Adicionados e convidados.** No fim da lista, por baixo dos amigos, aparecem esbatidos quem o usuário adicionou e quem convidou, ainda sem amizade. Cada linha mostra o avatar, o nome e, no lugar da assinatura, "ADDED" (pedido enviado, ainda sem resposta, FRI-R08) ou "INVITED" (contato convidado pela lista de contatos, ONB-R37a, que ainda não está na UVVA). Primeiro os adicionados, depois os convidados, cada grupo por ordem alfabética. Um adicionado usa o nome da agenda quando o Quick add o conhece; senão, o primeiro nome da conta. As linhas não abrem nada (ainda não há paladar para ver), não entram na busca nem na escolha de quem vem (FRI-R18). Um adicionado sai quando o pedido é aceite ou retirado; um convidado sai quando entra na UVVA (reconhecido pela chave de contato, como no Quick add) e passa a ser sugestão, pedido ou amigo. Os convites ficam guardados no aparelho. Sem amigos (FRI-R06), as linhas aparecem acima de "Find out what your friends like to drink".

**Critérios**
- Dado que o usuário tocou em Sofia no Quick add, então "Sofia Reis · ADDED" aparece esbatida no fim da lista e Sofia não está entre os amigos.
- Dado que o usuário convidou Carla pela lista de contatos, então "Carla Souza · INVITED" aparece depois dos adicionados; quando Carla cria conta, a linha some.

**FRI-R06 · Vazio.** Sem amigos nem pedidos:
- O topo é o mesmo ("Your Friends" e o botão da mesa, esbatido e inativo, FRI-R06a), mas o subtítulo passa a "Add the people you drink with. Once they accept, you will see where your palates meet and what to open together." em vez de "Hosting tonight?…".
- **Quick add** aparece só se há contatos que já usam a UVVA: só o título e a faixa de cartões, sem subtítulo. Sem sugestões (ou sem acesso aos contatos), a secção não aparece.
- Por baixo, as uvas gravadas, "Find out what your friends like to drink" em RedGrapes e o botão principal "Invite friends". Ele abre a lista de contatos do Onboarding (ONB-R37: quem está na UVVA, com Add, e quem convidar, com Invite), que fecha com `‹` ou "Done"; ao fechar, a aba lê os amigos de novo.
- Se o iOS ainda não perguntou pelos contatos, o botão pergunta primeiro e só abre a lista com o acesso dado. Recusado, o botão passa a "Open Settings", com a frase de acesso recusado por baixo.

**FRI-R06a · Mesa inativa.** Com menos de 2 amigos, o botão da mesa está esbatido e não responde; o VoiceOver diz "Add at least two friends to set a table."

**Critérios**
- Dados Marina, Bia e Rui, então a ordem é Bia, Marina, Rui.
- Dado um amigo com Acidity, Fruit e Body como líderes (QUIZ-R14a) e `compatibility` = 82, então a linha mostra "ACIDITY · FRUIT · BODY" e "82%".

### 4.1 Quick add

**FRI-R07 · Sugestões.** Cada sugestão é um cartão com o avatar, um `+` e o nome. Quick add sugere contatos da agenda do aparelho que já usam a UVVA (com o Quiz concluído, FRI-R01) e ainda não são amigos. Um contato é reconhecido pelo telefone que a pessoa digitou no cadastro (ONB-R07), comparado por uma chave de contato sem que os números da agenda saiam do aparelho (ARCHITECTURE §4.4). Quem pulou o Telefone no cadastro não aparece no Quick add, mas pode ser adicionado pelo link ou pelo QR de convite.

**FRI-R07a · Acesso aos contatos.** O acesso é pedido em Find friends, no Onboarding (ONB-R36a). Se foi recusado, o Quick add mostra o pedido de novo; se o iOS já não deixa pedir, mostra um botão para os Ajustes. O link e o QR de convite funcionam sem acesso.

**FRI-R07b · Ninguém para adicionar.** Com amigos e com o acesso dado, mas sem nenhum contato para sugerir, o Quick add dá lugar a o card bege padrão da app (como o banner do Cellar), perto da lista, com "Invite your friends and find out what they like to drink." na fonte normal, escura. Tocar no card abre a lista de contatos do Onboarding, como o "Invite friends" da FRI-R06. Durante a escolha de quem vem, o card dá lugar ao pedido da mesa (FRI-R18).

**FRI-R08 · Add envia um pedido.** Tocar no cartão envia um pedido de amizade ao contato. O `+` passa a `✓`, o cartão esbate-se ("Requested" no VoiceOver) e a sugestão fica na lista com esse estado até o pedido ser respondido. Enquanto o pedido não for aceite, o contato não aparece na lista de amigos, e nenhum dos dois vê o paladar do outro.

**FRI-R08a · Receber um pedido.** Quem recebe um pedido vê-o na aba Friends (e numa notificação, ver D10), com o nome, a foto e a assinatura do paladar de quem o enviou, e dois botões:
- **Accept:** os dois passam a ser amigos, e aparece "[nome] is now your friend." Os dois veem o paladar um do outro e podem montar mesas (secção 6).
- **Decline:** o pedido some, sem aviso a quem o enviou.

**FRI-R08b · Os dois enviaram.** Se A envia um pedido a B e B envia um pedido a A, os dois passam a ser amigos sem precisar de aceitar.

**FRI-R09 · Not now.** "Not now", ao manter o cartão premido (ou nas ações do VoiceOver), tira a sugestão da lista sem enviar pedido. Ela não volta a ser sugerida (ver D4).

**Critérios**
- Dado o contato Sofia, que usa a UVVA, quando o usuário toca no cartão dela, então o `+` passa a `✓` e Sofia ainda não está na lista de amigos.
- Dado um pedido de Marina, quando o usuário toca em Accept, então Marina passa a estar na lista de amigos dos dois e aparece "Marina Alves is now your friend."
- Dado um pedido de Marina, quando o usuário toca em Decline, então o pedido some e Marina não é avisada.
- Dado um pedido de A para B e outro de B para A, então A e B passam a ser amigos.
- Dado um contato que não usa a UVVA, então ele não aparece no Quick add.
- Dado um contato que usa a UVVA mas pulou o Telefone, então ele não aparece no Quick add.
- Dado um contato já amigo, então ele não aparece no Quick add.

## 5. Um amigo

**FRI-R10 · Duas tabs.** Tocar num amigo abre o perfil, na tab Map. No topo, "Back" numa cápsula com contorno fino (o mesmo desenho do "Expand" da mesa de grupo) e, à direita, `+` para escanear um vinho (FRI-R12a), como o `+` da Cellar; por baixo, ao centro, o avatar, o nome e a assinatura, e as tabs Map e Compatibility. Tudo isso fica fixo, como no You: só a página da tab rola, e cada tab abre no seu topo. "Remove friend" fica no fim da tab Map (D4), a meio entre o último cartão e o fundo do ecrã.

**FRI-R11 · Map.** Dois cartões de vidro fosco, os mesmos da Home, com o título em RedGrapes:
- **"[Nome] Map"** (o primeiro nome, por exemplo "Beatriz Map"): o mapa do paladar do amigo em pequeno, a frase curta e as leituras (como na QUIZ-R16).
- **"Picks for [nome]":** o mesmo cartão de "Wines for your palate" da Home. As 3 garrafas do catálogo mais próximas do mapa do amigo, cada uma com o nome e o produtor e, por baixo, só a leitura forte do mapa dele em que mais se destaca e a intensidade do vinho nela ("High acidity", "Full body", "Medium fruit"), num texto mais leve que o da Home, e `›`. Tocar numa garrafa abre o **Friend Wine** (FRI-R11a). Sem garrafas, o cartão não aparece.

**FRI-R11a · Friend Wine.** A ficha de um vinho visto pelo mapa do amigo. É uma tela do Friends, diferente do Wine Detail da Home (HOME-R28a), montada com os mesmos componentes do app (o corpo da ficha do CoreUI e os botões do DesignSystem). Tudo o que compara é lido no mapa do amigo, não no do usuário: "[X]% match with [nome]'s map", "High in [a] and [b], like [nome]'s map." (e as outras frases da HOME-R10b, com o nome dele), "More [eixo] than [nome] usually drinks." e os dois mapas, "This wine and [nome]", com a legenda "[nome]'s map". Ao pé, "Find the wine" e "Send to [nome]" (FRI-R11b).

**FRI-R11b · Send to [nome].** O botão do pé da Friend Wine (um vinho do Map do amigo ou um escaneado, FRI-R12a) envia o vinho ao amigo pela base pública (um registo `SharedWine` por quem envia, amigo e vinho; enviar outra vez só o põe no topo). Enquanto envia, "Sending…"; depois, "Sent to [nome]", inativo. Se falhar, "It did not send. Try again." por cima, e o botão volta a "Send to [nome]". O registo leva o vinho como quem enviou o viu, para o amigo cujo catálogo não o tem (um rótulo acabado de ler). Apagar a conta (YOU-R27) apaga os vinhos que ela enviou.

**FRI-R11c · Vinhos recebidos.** O amigo é avisado por uma notificação push: "[nome] sent you a wine: [vinho]". Ela vem de uma subscrição da base pública aos vinhos enviados ao usuário, criada quando ele passa a ter um amigo, que é também quando a app pede para mandar notificações. Tocar nela abre a aba Friends e o vinho em ecrã inteiro, por cima do que estava aberto. Na aba, "Sent to you" fica entre os pedidos e os amigos: cada vinho com "[nome] sent you a wine", o nome do vinho e `›`, do mais recente ao mais antigo, e abre o mesmo ecrã inteiro. Esse ecrã é a Friend Wine lida no mapa do próprio usuário, como na Home ("match with your map", "This wine and you"), com `‹` e "[NOME] SENT YOU THIS WINE" no topo e, ao pé, "Find the wine" e "Add to cellar" ("In your cellar" se já está na adega); "Add to cellar" fecha o ecrã e abre a nota nova da adega (CELLAR-R14a). O vinho vem do catálogo do telemóvel e, se ele não o tem, de como quem enviou o viu.

> **Falta no CloudKit (2026-11-20).** Enviar um vinho a um amigo (FRI-R11b, R11c) e o aviso "[nome] sent you a wine" no sino da Home (HOME-R04a) só funcionam depois de configurar a tabela `SharedWine` no CloudKit Console (`iCloud.app.uvva`, base pública). Sem isso, o envio falha e nem a lista "Sent to you" nem a push aparecem. Passos, também em ARCHITECTURE §4, "Configurar uma vez":
> - [ ] **Tabela** `SharedWine` em Development, com `from`, `fromName`, `to`, `wineID`, `wineName`, `snapshot` (String) e `sentAt` (Date/Time). Ou nasce sozinha com o primeiro vinho enviado num build de Debug com iCloud.
> - [ ] **Índices:** `recordName`, `to` e `from` *queryable*; `sentAt` *sortable*.
> - [ ] **Permissões:** `_icloud` *create* e *read*; `_creator` *write*.
> - [ ] **Deploy Schema Changes** para Production, antes do TestFlight.

**FRI-R12 · Compatibility.**
Por esta ordem, com bastante espaço entre as partes e o título de cada uma em RedGrapes:
- "[X]%" em grande e fino e, alinhados à direita dele, "of your palate map matches [nome]" e a frase:
- **Frase**, a partir de `sharedAxes`: com eixos, "You both want [a], [b] and [c] in a glass." (ou "[a] and [b]", ou só "[a]"); sem eixos, "You barely overlap — you like different things."
- **Reading by reading**, num cartão de vidro com o título em RedGrapes: primeiro os dois mapas sobrepostos (o do usuário a cheio, o do amigo tracejado, e o que os dois têm em comum preenchido); depois, para cada eixo, o nome e a distância entre os dois (Same, Close, Apart ou Opposed, `axisSpread` dos dois mapas), e por baixo as duas leituras em dez pontos, como no Map: "YOU" e o primeiro nome do amigo, o dele um pouco mais esbatido.
- **Open this together:** o mesmo cartão de "Picks for [nome]" (FRI-R11): 3 garrafas, cada uma com o nome e o produtor e, por baixo, só o eixo (FRI-R14) e a intensidade do vinho nele, e `›`. Tocar numa garrafa abre o Friend Wine lido nos dois mapas, como um vinho escaneado (FRI-R12a), com "Send to [nome]" ao pé.
- **Set the perfect dinner** (FRI-R13a), cujo botão abre a mesa numa sheet (FRI-R13, R15a).

**FRI-R12a · Scan a wine.** O `+` do topo do amigo abre a câmara e a leitura do rótulo da nota nova da adega (CELLAR-R16, R17, R21, R23), só para identificar o vinho: nada é guardado na adega. Lido o vinho, a câmara fecha e o vinho abre no Friend Wine, lido nos dois mapas: o match com o meio dos dois mapas (`crossed`), "match with your two maps", as frases da HOME-R10b com "your two maps" e "than you two usually drink", "This wine and you two" e, por baixo do produtor, o match de cada um ("YOU 68%", "MARINA 81%").

**FRI-R13 · Set a table.** "Set the perfect dinner" (FRI-R13a) abre a mesa para dois com esse amigo (secção 6) numa sheet: o menu, como fazer cada prato e os botões de partilha (FRI-R15a). Pôr a mesa guarda-a como a última mesa (FRI-R17). O cartão de match da Home (HOME-R11) abre o amigo na Compatibility, com a sheet da mesa já aberta.

**FRI-R13a · Set the perfect dinner.** Uma secção da Compatibility, "Set the perfect dinner", com "Choose how the evening goes. The dishes follow your choices; the bottles, both your maps." e escolhas em chips:
- **Courses:** Starter, Main, Cheese, Dessert, em ordem de serviço. Por omissão Starter, Main e Dessert; pelo menos um fica sempre escolhido.
- **On the table:** Anything, Vegetarian, Vegan, Pasta, Risotto, Fish, Seafood, Poultry, Meat ou Pork.
  - Vegetarian (receitas `vegetarian` ou `vegan`) e Vegan (receitas `vegan`) valem para todos os pratos. Um prato sem receita que caiba fica fora da mesa (Vegan não tem queijo).
  - As outras escolhas dizem de que é feito o prato principal; sem Main, o Starter. Os outros pratos ficam com as suas receitas, para um jantar de massa não ser massa três vezes. Se nenhuma receita desse prato couber, ele fica com as outras.
  - Fish é o ingrediente principal `fish`; Seafood, `shellfish`; Poultry, `poultry`; Meat, `red meat` ou `game`; Pork, `pork`.
  - As receitas não têm um campo de massa nem de arroz: Pasta é uma receita cuja base (ingrediente `base`) é uma massa (pasta, linguine, pappardelle, lasagne, gnocchi, noodles…); Risotto, uma cuja base é arroz de risoto ou de paella (arborio, carnaroli, bomba…).
- **When:** "In season · [estação]" (as receitas da estação de hoje, no hemisfério norte) e "No rush" ou "Under 45 min" (pratos de até 45 minutos).
- O botão "Set the perfect dinner" monta a mesa com essas escolhas: os pratos vêm só das receitas que cabem, e as garrafas continuam a vir dos dois mapas (FRI-R14). Se a estação ou o tempo deixarem um prato sem receita, esse prato esquece primeiro a estação, depois o tempo; o que vai à mesa nunca se perde. Mudar as escolhas depois de posta a mesa troca o botão para "Set it again". "Open this together" mostra as garrafas da última mesa montada.

**Critérios**
- Dado `sharedAxes` = [Acidity, Fruit], então a frase é "You both want acidity and fruit in a glass."
- Dado `sharedAxes` = [Acidity, Fruit, Spice], então a frase é "You both want acidity, fruit and spice in a glass."
- Dado `sharedAxes` vazio, então a frase é "You barely overlap — you like different things."

## 6. Mesas

### 6.1 Garrafas

**FRI-R14 · Escolha das garrafas.** As garrafas e o menu de uma mesa vêm de `tableBottles` (`match.md`), a partir de todos os mapas à mesa.

### 6.2 Mesa para dois

**FRI-R15 · Menu.** "The perfect dinner for You & [nome]": uma garrafa por prato escolhido (FRI-R13a), por ordem de serviço, cada uma com o prato que a acompanha. Rodapé: "Read from both palate maps · UVVA".

**FRI-R15a · Sheet da mesa.** A mesa para dois abre numa sheet a 70% do ecrã (puxada, vai até cima), com o fundo das colinas do amigo. Por ordem:
- **The perfect table:** o título, sem subtítulo, e o cartão do menu (FRI-R15).
- **Share this table:** um botão logo abaixo do cartão do menu. Abre o ecrã de partilha por cima da sheet, no convite de WhatsApp, com a Story e Save image (FRI-R21).
- **How to make it:** sem cartão, os pratos separados por uma linha fina. Cada um com o prato e a garrafa ("MAIN · CHIANTI CLASSICO, ISOLE E OLENA"), o nome da receita, porque funciona, "Serves 4 · 40 min", "You'll need" (os ingredientes com quantidade) e "Method" (os passos numerados). É a receita como a Home a escreve (HOME-R09, `Pairing.dish`).
Fechar a sheet volta à Compatibility com as escolhas como estavam; tocar outra vez no botão reabre a mesma mesa, ou monta outra se as escolhas mudaram.

**FRI-R16 · Sempre aberta.** A mesa para dois existe para qualquer amigo, sem limite.

**FRI-R17 · Última mesa.** A última mesa aberta fica guardada. É ela que o card de match da Home abre (HOME-R11).

### 6.3 Mesa de grupo

**FRI-R18 · Escolher quem vem.** O botão da mesa (as três figuras, ao lado de "Your Friends") entra em modo de escolha, e tocar nele outra vez sai. Durante a escolha, o botão da mesa fica azul (ícone e contorno) e "Pick who’s coming. We’ll set the perfect table: the bottles and the dinner everyone will love." (em RedGrapes, no mesmo azul) aparece com um fade no lugar do Quick add ou do card de convite da FRI-R07b, que somem. Os pedidos somem; a barra de abas dá lugar ao botão da mesa, e cada amigo mostra um círculo à esquerda em vez da compatibilidade:
- Tocar num amigo escolhe-o ou desfaz a escolha.
- Com menos de 2 escolhidos, o botão diz "Pick at least two friends" e está inativo.
- Com 2 ou mais, diz "Find a bottle for these [n]" e abre a mesa.
- Há um máximo de pessoas por mesa [ver D6].

**FRI-R19 · Resultado.** A mesa de grupo mostra:
- **Compatibilidade da mesa** (`tableCompatibility`): "[X]% match across all [n] palate maps at the table".
- **Frase**, a partir de `sharedAxes` da mesa: com eixos, "You all want [a], [b] and [c] in a glass."; sem eixos, "Nothing lines up across all [n] — the menu is built on compromise."
- **"Where the table lands":** o radar com a média de cada eixo, preenchido e em linha cheia, e "The boldest reading" (o valor mais alto de cada eixo) a tracejado.
- **"Reading by reading":** começa recolhida e "Expand"/"Collapse" abre e fecha. Cada eixo tem a etiqueta de `axisSpread` (Same, Closest, Some give ou Widest), uma frase e o intervalo à mesa (do menor ao maior valor).
- "Open this together" (FRI-R14) e "The perfect table" (o menu, como na FRI-R15), com o título "The perfect dinner for The [n] of you".

**FRI-R20 · Entrada pela Home.** "Set a table with your friends", na Home, abre esta escolha (HOME-R11).

**Critérios**
- Dado o modo de escolha com 1 amigo escolhido, então o botão diz "Pick at least two friends" e está inativo.
- Dados 3 amigos escolhidos, então o botão diz "Find a bottle for these 3".
- Dado um amigo escolhido, quando o usuário toca nele de novo, então ele deixa de estar escolhido.
- Dados 4 mapas com Acidity 6, 7, 7 e 8, então o intervalo de Acidity mostrado vai de 6 a 8.
- Dada uma mesa de 4 com `sharedAxes` vazio, então a frase é "Nothing lines up across all 4 — the menu is built on compromise."

## 7. Partilhar uma mesa

**FRI-R21 · Três formatos.** Por baixo do menu ficam três botões, WhatsApp e Instagram em contorno e Save image cheio, tanto na mesa para dois como na de grupo. Cada um abre a partilha da app (SHARED-R20) já nesse formato (Instagram e Save image no Story, onde fica "Save image"):

| Formato | Conteúdo |
| --- | --- |
| WhatsApp | Convite "You're invited to dinner" com os nomes, o menu, a mensagem "Dinner at mine? I built the menu from both our palate maps. Three courses, three bottles." e o link da mesa `uvva.app/t/[mesa]` |
| Story | Imagem 9:16, "Tonight's table", com o menu. Quem tocar abre o menu completo na UVVA |
| Save image | Guia de compras: para cada garrafa, o curso, "Ask for: …" e o prato. Fica guardado nas fotos |

**FRI-R22 · Texto do grupo.** Na mesa de grupo, o convite usa os nomes de todos, e a mensagem fala em "all our palate maps" no lugar de "both".

**Critérios**
- Dada a mesa para dois com Marina, então o convite tem "Marina & Elisa" e o link `uvva.app/t/marina-elisa`.
- Quando o usuário toca em Save image, então a imagem do guia de compras é guardada nas fotos.

## 8. Fora de escopo

- Limites de mesas, desbloqueio por €1,99 e paywall (SHARED-R01).
- O convite para a UVVA de quem ainda não tem conta (está na Home, HOME-R11).
- Os cálculos de compatibilidade, eixos em comum, etiquetas e garrafas: `match.md`.
- Como o catálogo associa um prato a cada garrafa.

## 9. Dúvidas em aberto

- [x] **D2 · Lista vazia.** Sem amigos, a aba convida a adicionar amigos pela lista de contatos do Onboarding, que também convida quem não está na UVVA (FRI-R06).
- [x] **D3 · Acesso aos contatos.** Pedido em Find friends, no Onboarding; sem acesso, o Quick add volta a pedir (FRI-R07a).
- [ ] **D4 · Sugestão recusada.** Um contato tirado com × volta a ser sugerido algum dia? Dá para remover um amigo depois de adicionado? Remover avisa o outro?
- [ ] **D10 · Notificação do pedido.** Os vinhos enviados já chegam por push (FRI-R11c, subscrição CloudKit). Os pedidos de amizade aparecem também no sino da Home (HOME-R04a), sem push. Falta decidir se também devem chegar por push.
- [ ] **D11 · Pedido sem resposta.** Um pedido que ninguém responde expira? Quem enviou pode cancelá-lo?
- [ ] **D6 · Tamanho da mesa.** Qual é o máximo de pessoas numa mesa de grupo? O protótipo usa sempre quatro.
- [ ] **D9 · Link da mesa.** Quem recebe `uvva.app/t/[mesa]` sem ter a app vê o quê?

### Para o `match.md`

Estas dúvidas saíram daqui e ficam para quando o `match.md` for escrito:

- Fórmula da compatibilidade: a mesma distância do vinho (QUIZ-R21) ou a média das diferenças do protótipo?
- Como se escolhem as garrafas e o menu de uma mesa (mapa médio? regras por curso?).
- Limites de "perto", "alto" e das etiquetas Same, Closest, Some give e Widest, agora na escala 0–9.
- Quando um amigo refaz o Quiz, as mesas antigas com ele são recalculadas?
