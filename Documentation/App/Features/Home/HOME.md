# UVVA · Home

> Status: rascunho v0.2 · 2026-10-31
> Depende de: [`SHARED.md`](../Shared/SHARED.md), [`QUIZZ.md`](../Quizz/QUIZZ.md)
> Fonte: canvas UVVA App, artboards Home e Home · Guided tour.

## 1. Objetivo

A Home é a primeira aba da app. Ela junta, numa lista fixa de cards, o que é mais útil para o usuário hoje: um vinho com prato, os amigos, a lição em andamento, o efeito do último vinho no paladar, atalhos para aprender, uma palavra do glossário e vinhos para avaliar.

Cada card decide sozinho se aparece e em que variante, a partir do seu próprio estado. Não existe um modo "primeiro uso" da Home inteira.

A Home também é dona do **tour guiado** (seção 5): uma camada por cima da Home que aparece uma única vez, depois do primeiro mapa, e mostra onde fica cada coisa. O tour não muda os cards; só os destaca.

## 2. Dados que a Home lê

| Dado | De onde vem | Usado por |
| --- | --- | --- |
| `user.firstName` | Onboarding | Header, Tour guiado |
| `palateMap` | Quiz | Sugestão do dia, Vinhos para o paladar |
| `seenTours` (por conta; o tour da Home é `"home"`) | Home | Tour guiado |
| `quizExit` (`.homeWithTour`) | Quiz (QUIZ-R25) | Tour guiado |
| `friends: [Friend]` (com `hasMap`, `compatibility`) | Friends | Card de amigos |
| `moduleProgress: [ModuleProgress]` (com `lastOpenedAt`, lição e passo atuais) | Learn | Continuar lição |
| `lastRating: Rating?` (com variação por eixo) | Cellar / Home | Eixo que mudou |
| `ratedWineIDs: Set<WineID>` | Cellar / Home | Vinhos para o paladar |
| `wineCatalog: [Wine]` | Catálogo | Sugestão do dia, Vinhos para o paladar, Escolha o seu vinho |
| `glossary: [GlossaryTerm]` | Glossário | Palavra do dia |
| `notifications: [Notification]` (com `isRead`) | Notificações | Header |
| `clock` | Aparelho | Sugestão do dia, Palavra do dia |

**Para TDD:** a montagem dos cards é uma função pura, sem UI:

```swift
HomeCardsBuilder.build(from: HomeState, now: Date, calendar: Calendar) -> [HomeCard]
```

`HomeCard` é um enum com um caso por card e variante (por exemplo `.friends(.invite)`, `.friends(.match(friend))`, `.friends(.setTable)`). Os testes montam um `HomeState` e verificam a lista que sai.

## 3. Ordem dos cards

**HOME-R01 · Ordem fixa.** Os cards aparecem sempre nesta ordem. Um card que não aparece não deixa espaço vazio; os seguintes sobem.

| # | Card | Pode não aparecer? |
| --- | --- | --- |
| 1 | Header (saudação, `+`, sino) | Não |
| 2 | Sugestão do dia (vinho e prato) | Sim |
| 3 | Amigos | Não (muda de variante) |
| 4 | Continuar lição | Sim |
| 5 | O eixo que mudou | Sim |
| 6 | Learn (A region, A grape, A lesson) | Não |
| 7 | Palavra do dia | Sim |
| 8 | Vinhos para o seu paladar | Sim |
| 9 | Escolha o seu vinho | Não |

**Critérios**
- Dado um estado em que todos os cards aparecem, quando a Home é montada, então a lista tem os 9 cards na ordem da tabela.
- Dado um estado sem lição em andamento e sem avaliações, quando a Home é montada, então "Continuar lição" e "O eixo que mudou" não estão na lista, e a ordem dos outros se mantém.

---

## 4. Regras por card

### 4.1 Header

**HOME-R02 · Saudação.** Mostra "Welcome back, [primeiro nome]".

**HOME-R03 · Botão +.** Sempre visível. Abre o fluxo de nova nota do Cellar (câmera: frente, contrarrótulo, leitura). Ver `CELLAR.md`.

**HOME-R04 · Sino.**
- O sino está sempre visível.
- Mostra um ponto quando existe pelo menos uma notificação não lida.
- Tocar no sino abre a lista de notificações.
- Uma notificação passa a lida quando o usuário a abre (toca nela). Abrir a lista não marca nada como lido.

**HOME-R05 · Scroll.** Ao rolar, o logo encolhe e a saudação desaparece. O `+` e o sino ficam visíveis.

**Critérios**
- Dadas 0 notificações não lidas, então o sino não tem ponto.
- Dadas 2 não lidas, quando o usuário abre a lista sem tocar em nenhuma, então o ponto continua.
- Dadas 2 não lidas, quando o usuário abre uma delas, então resta 1 não lida e o ponto continua.
- Dada 1 não lida, quando o usuário a abre, então o ponto some.

### 4.2 Sugestão do dia (vinho e prato)

**HOME-R06 · Escolha.** Um vinho do catálogo escolhido a partir do mapa do paladar ("Picked for your palate"), com o prato que o acompanha.

**HOME-R07 · Troca diária.** A sugestão muda todo dia (SHARED-R03) e fica a mesma durante o dia, por mais vezes que a Home seja aberta.

**HOME-R08 · Pode repetir o Cellar.** O vinho sugerido pode ser um vinho que já está no Cellar do usuário ou que ele já avaliou.

**HOME-R09 · Receita.** "See the wine & the dish" expande o card: o prato, por que combina, ingredientes, passos e como servir. "Show less" recolhe.

**HOME-R09a · Find the wine.** Abre, dentro da app (Safari em folha), uma pesquisa na internet com o produtor, o nome e o ano do vinho; sem ano, só produtor e nome. O produtor não se repete quando já está no nome (2026-10-31).

**HOME-R10 · Ausência.** O card não aparece se o catálogo não tiver nenhum vinho com prato associado.

**Critérios**
- Dado o dia 27/10, quando a Home é montada duas vezes nesse dia, então a sugestão é a mesma nas duas.
- Dados os dias 27/10 e 28/10, quando a Home é montada em cada um, então a sugestão é calculada de novo no dia 28 (pode coincidir só se a regra de escolha permitir).
- Dado que o vinho sugerido já está no Cellar, então ele continua elegível.

### 4.3 Amigos

**HOME-R11 · Três variantes, um card.** O card de amigos sempre aparece, numa das três variantes, conforme o número de amigos (SHARED-R12):

| Amigos | Variante | Texto | Ação |
| --- | --- | --- | --- |
| 0 | Convite | "Invite friends to discover their taste and find the wine you'll both love" | Abre o convite: mapa do paladar e o link `uvva.app/invite/[id do usuário]`, com Story, WhatsApp e Save image (SHARED-R20), ou "Not now" |
| 1 | Match | "X% match with [nome do amigo]" (a % vem de `match.md`) | Abre a mesa para dois com esse amigo |
| 2 ou mais | Mesa | "Set a table with your friends" | Abre Friends em modo de seleção |

**Critérios**
- Dados 0 amigos, então aparece `.friends(.invite)`.
- Dado 1 amigo, Marina, com 82% de compatibilidade, então aparece `.friends(.match)` com "82% match with Marina".
- Dados 2 amigos, então aparece `.friends(.setTable)`.
- Dados 0 amigos, quando o usuário toca no card, então abre a folha de convite com o link `uvva.app/invite/[id do usuário]`.

### 4.4 Continuar lição

**HOME-R12 · Quando aparece.** Aparece quando existe pelo menos um curso em andamento, seja um módulo do curriculum ou um curso de região ou de casta (SHARED-R16, LEARN-R01, LEARN-R02).

**HOME-R13 · Qual curso.** Se houver mais de um curso em andamento, mostra o de `lastOpenedAt` mais recente.

**HOME-R14 · Conteúdo e ação.** Mostra o curso, a lição atual e o progresso. "Continue" abre essa lição no passo onde o usuário parou (SHARED-R17).

**Critérios**
- Dado um módulo com 2 de 5 lições concluídas, então o card aparece e aponta para a lição 3, no passo guardado.
- Dado um módulo com 0 lições concluídas, mas com a lição 1 aberta e parada no passo 2, então o card aparece e aponta para a lição 1, passo 2.
- Dados os módulos A (aberto ontem) e B (aberto hoje), ambos em andamento, então o card aponta para B.
- Dado que todos os módulos iniciados estão concluídos, então o card não aparece.
- Dado que nenhum módulo foi iniciado, então o card não aparece.

### 4.5 O eixo que mudou

**HOME-R15 · Quando aparece.** Aparece a partir da primeira avaliação de um vinho (SHARED-R08) e fica até a próxima avaliação, que o substitui. Sem nenhuma avaliação, não aparece.

**HOME-R16 · Conteúdo.** Mostra o mini mapa e o eixo que mais mudou na última avaliação (SHARED-R10), por exemplo "Your last wine raised your tannin". Se for empate, mostra o primeiro eixo na ordem definida em `QUIZZ.md` (QUIZ-R02).

**HOME-R17 · Ação.** Tocar abre You › Map › Over time (YOU-R03).

**Critérios**
- Dadas 0 avaliações, então o card não aparece.
- Dada uma avaliação ontem que subiu o tanino em +0.3 e a acidez em +0.1, então o card diz que o tanino subiu.
- Dada uma nova avaliação hoje que desceu a fruta, então o card passa a falar da fruta.
- Dada uma avaliação há 30 dias e nenhuma depois, então o card continua aparecendo.

### 4.6 Learn

**HOME-R18 · Sempre visível.** Três atalhos:
- "A region" abre Learn › By region.
- "A grape" abre Learn › By grape.
- "A lesson" abre Learn › The path, no módulo em andamento; sem módulo em andamento, abre no primeiro módulo não concluído.

### 4.7 Palavra do dia

**HOME-R19 · Escolha.** Uma palavra aleatória do glossário (SHARED-R18), independente do usuário, do progresso e do paladar.

**HOME-R20 · Conteúdo.** Termo, pronúncia e definição.

**HOME-R21 · Ausência.** O card não aparece se o glossário estiver vazio.

**Critérios**
- Dado um glossário com 1 termo, então a palavra do dia é esse termo.
- Dado um gerador aleatório com semente fixa, então a palavra escolhida é sempre a mesma (o gerador é injetado para os testes).

### 4.8 Vinhos para o seu paladar

**HOME-R22 · Lista.** Mostra 3 vinhos: os 3 do catálogo com maior similaridade com o mapa do paladar (SHARED-R07), por ordem decrescente.

**HOME-R23 · Exclusão.** Vinhos já avaliados (SHARED-R11) não entram na lista. Quando um vinho é avaliado, ele sai e o próximo mais semelhante entra no lugar.

**HOME-R24 · Avaliar.** Tocar num vinho pergunta "Would you drink it again?" com Yes, Maybe ou No (SHARED-R08). A resposta recalcula o mapa (SHARED-R09), guarda o vinho no Cellar como Tasted com esse veredito (CELLAR-R13c) e mostra um aviso com os eixos que subiram ou desceram, por exemplo "Map updated · Acidity ↑ · Fruit ↑", durante 3 segundos.

**HOME-R25 · Menos de 3 elegíveis.** Se houver menos de 3 vinhos não avaliados, mostra os que houver. Com 0, o card não aparece.

**Critérios**
- Dados 10 vinhos com similaridades conhecidas e nenhum avaliado, então a lista tem os 3 maiores, em ordem decrescente.
- Dado que o vinho #1 da lista é avaliado com No, então a lista passa a ser #2, #3 e #4.
- Dado que o vinho #1 já tinha sido avaliado no Cellar, então ele não aparece na Home.
- Dada uma avaliação Yes que sobe a acidez e a fruta, então o aviso mostra "Acidity ↑ · Fruit ↑" e some depois de 3 s.
- Dado que o mapa mudou com a avaliação, então a lista é recalculada com o mapa novo.

### 4.9 Escolha o seu vinho

**HOME-R26 · Sempre visível.** Um formulário no fim da Home: direção, tipo, região e até 3 notas.

**HOME-R27 · Limite de notas.** É possível escolher no máximo 3 notas; com 3 escolhidas, as outras ficam inativas até uma ser desmarcada.

**HOME-R28 · Resultado.** "Find my wine" abre uma folha com o vinho que melhor corresponde aos filtros e ao paladar. "Another one" mostra o seguinte do mesmo tipo. "Save to Cellar" guarda o vinho no Cellar como Not yet (CELLAR-R13c) e mostra "Saved to Cellar · [vinho]".

**Critérios**
- Dadas 3 notas escolhidas, quando o usuário tenta escolher a quarta, então ela não é selecionada.
- Dados filtros sem nenhum vinho correspondente, então [a definir].

---

## 5. Tour guiado

Uma camada escura por cima da Home, com um recorte de luz sobre a área de cada passo e um cartão com o texto. A Home por baixo é a Home real da conta naquele momento (normalmente sem amigos, sem lições e sem avaliações).

**Para TDD:** o tour é uma máquina de estados pura, sem UI:

```swift
struct GuidedTour {
    var step: Int            // 0 = intro, 1...6 = passos
    mutating func next()     // no passo 6, termina
    mutating func back()     // no passo 1, volta à intro
    mutating func pick(_ step: Int)
    var isFinished: Bool
}

func shouldShowTour(quizExit: QuizExit?, seenTours: Set<String>) -> Bool
```

**HOME-R29 · Quando aparece.** O tour abre por cima da Home quando o usuário chega a ela pela saída do Quiz na entrada "primeiro mapa" (QUIZ-R25) e a conta ainda não viu o tour. Ele é mostrado uma única vez por conta. Não aparece depois de refazer o Quiz (QUIZ-R18a), nem ao entrar numa conta que já o viu (ONB-R27).

**HOME-R30 · Intro.** "Your map is ready", "Welcome in, [primeiro nome]", "A short walk through where things live in UVVA.", "A quick look around" e o botão "Show me", que abre o passo 1.

**HOME-R31 · Passos.** São 6 passos, cada um destacando uma área da Home:

| # | Passo | Título | Texto | Área destacada |
| --- | --- | --- | --- | --- |
| 1 | Today | A pairing drawn for your palate | Every day UVVA designs a full experience around your map: a wine that hits the notes you love loudest, and a recipe built to balance everything else. | Sugestão do dia (4.2) |
| 2 | Your wine | Choose your wine | Pick a direction, a type, a region and up to three notes. UVVA finds the bottle closest to your map for tonight. | Escolha o seu vinho (4.9) |
| 3 | Scan | Scan a label | Tap + and point the camera at any bottle. UVVA reads the label, classifies the wine and adds it to your cellar. Every note you save moves your map. | Botão + (HOME-R03) |
| 4 | Learn | Learn the wines you love | Get to know the region you keep coming back to, the grape behind your favourite bottle, and what to look for in the glass. Five minutes at a time. | Aba Learn |
| 5 | Cellar | Your cellar | Wines you have tasted and wines you want to try, each one measured against your map. | Aba Cellar |
| 6 | Friends | Set a table | Invite the people you drink with. UVVA reads every map at the table and suggests one bottle for all of you. | Aba Friends |

No passo 2, a Home rola até o card "Escolha o seu vinho", que fica no fim da lista, e o destaque segue a posição dele.

**HOME-R32 · Navegação.** O contador mostra "N of 6" (na intro, "Tour"). "Next" avança; no passo 6, o botão diz "Start". `‹` volta um passo; no passo 1, volta à intro. Tocar num dos 6 pontos de progresso abre esse passo. Durante o tour, a Home por baixo não responde a toques.

**HOME-R33 · Fim.** "Start" fecha o tour, mostra a Home no topo e marca o tour como visto na conta (acrescenta `"home"` a `seenTours`).

**Critérios**
- Dada a saída do Quiz na entrada "primeiro mapa" e `seenTours` sem `"home"`, então a Home abre com a intro do tour.
- Dada a saída do Quiz na entrada "refazer", então o tour não aparece.
- Dado `seenTours` com `"home"`, quando a Home abre, então o tour não aparece.
- Dada a intro, quando o usuário toca em "Show me", então abre o passo 1 e o contador mostra "1 of 6".
- Dado o passo 1, então o botão diz "Next"; quando o usuário toca em `‹`, então volta à intro.
- Dado o passo 6, então o botão diz "Start".
- Dado o passo 4, quando o usuário toca no ponto 2, então abre o passo 2.
- Quando o usuário toca em "Start", então o tour fecha, abre a Home e `seenTours` passa a ter `"home"`.

---

## 6. Fora de escopo

- Planos, paywall e limites (SHARED-R01).
- O conteúdo das notificações e o que as gera.
- O fluxo de câmera e de nota (ver `CELLAR.md`).
- O Quiz e a folha de partilha do mapa, que vêm antes do tour (ver `QUIZZ.md`).

## 7. Dúvidas em aberto

- [x] **Amigos pelos contatos.** Contam só os contatos adicionados como amigos pelo Quick add (FRI-R08).
- [ ] **Palavra do dia.** É sorteada uma vez por dia (fixa durante o dia) ou a cada abertura da Home? Pode repetir a palavra de ontem?
- [ ] **Sugestão do dia.** Entre os vinhos compatíveis, ela é aleatória ou é o mais semelhante ainda não sugerido? Pode repetir uma sugestão de dias anteriores?
- [ ] **Eixo que mudou.** Se uma avaliação não mudar nenhum eixo (por exemplo, Maybe num vinho já muito próximo do mapa), o card mostra o quê?
- [ ] **Escolha o seu vinho.** O que aparece quando nenhum vinho corresponde aos filtros? E "Another one" quando acabam os vinhos do tipo?
- [ ] **Saudação.** É sempre "Welcome back", ou "Welcome" na primeira abertura depois do Onboarding (logo depois do tour, que já diz "Welcome in")?
- [ ] **Pular o tour.** O tour pode ser pulado (por exemplo, um "Skip" na intro)? Pular conta como visto?
- [ ] **Rever o tour.** O tour pode ser visto de novo depois (por exemplo, em You › Settings)?
- [ ] **Tour interrompido.** Se a app fechar no meio do tour, ele aparece de novo na próxima abertura, ou só conta como visto ao tocar em "Start"?
- [ ] **Passo 1 sem sugestão.** Se o card "Sugestão do dia" não aparecer (HOME-R10), o passo 1 é pulado ou destaca outro card?
