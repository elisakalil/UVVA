# UVVA · Home

> Status: rascunho v0.1 · 2026-10-27
> Depende de: [`_shared.md`](_shared.md)

## 1. Objetivo

A Home é a primeira aba da app. Ela junta, numa lista fixa de cards, o que é mais útil para o usuário hoje: um vinho com prato, os amigos, a lição em andamento, o efeito do último vinho no paladar, atalhos para aprender, uma palavra do glossário e vinhos para avaliar.

Cada card decide sozinho se aparece e em que variante, a partir do seu próprio estado. Não existe um modo "primeiro uso" da Home inteira.

## 2. Dados que a Home lê

| Dado | De onde vem | Usado por |
| --- | --- | --- |
| `user.firstName` | Onboarding | Header |
| `palateMap` | Quiz | Sugestão do dia, Vinhos para o paladar |
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

**HOME-R03 · Botão +.** Sempre visível. Abre o fluxo de nova nota do Cellar (câmera: frente, contrarrótulo, leitura). Ver `cellar.md`.

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

**HOME-R10 · Ausência.** O card não aparece se o catálogo não tiver nenhum vinho com prato associado.

**Critérios**
- Dado o dia 27/10, quando a Home é montada duas vezes nesse dia, então a sugestão é a mesma nas duas.
- Dados os dias 27/10 e 28/10, quando a Home é montada em cada um, então a sugestão é calculada de novo no dia 28 (pode coincidir só se a regra de escolha permitir).
- Dado que o vinho sugerido já está no Cellar, então ele continua elegível.

### 4.3 Amigos

**HOME-R11 · Três variantes, um card.** O card de amigos sempre aparece, numa das três variantes, conforme o número de amigos (SHARED-R12):

| Amigos | Variante | Texto | Ação |
| --- | --- | --- | --- |
| 0 | Convite | "Invite friends to discover their taste and find the wine you'll both love" | Abre o convite: mapa do paladar e o link `uvva.app/invite/[nome]`, com Story, WhatsApp e Save image (SHARED-R20), ou "Not now" |
| 1 | Match | "X% match with [nome do amigo]" (a % vem de `match.md`) | Abre a mesa para dois com esse amigo |
| 2 ou mais | Mesa | "Set a table with your friends" | Abre Friends em modo de seleção |

**Critérios**
- Dados 0 amigos, então aparece `.friends(.invite)`.
- Dado 1 amigo, Marina, com 82% de compatibilidade, então aparece `.friends(.match)` com "82% match with Marina".
- Dados 2 amigos, então aparece `.friends(.setTable)`.
- Dados 0 amigos, quando o usuário toca no card, então abre a folha de convite com o link `uvva.app/invite/[nome do usuário]`.

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

**HOME-R16 · Conteúdo.** Mostra o mini mapa e o eixo que mais mudou na última avaliação (SHARED-R10), por exemplo "Your last wine raised your tannin". Se for empate, mostra o primeiro eixo na ordem definida em `quiz.md`.

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

## 5. Fora de escopo

- Planos, paywall e limites (SHARED-R01).
- O conteúdo das notificações e o que as gera.
- O fluxo de câmera e de nota (ver `cellar.md`).

## 6. Dúvidas em aberto

- [x] **Amigos pelos contatos.** Contam só os contatos adicionados como amigos pelo Quick add (FRI-R08).
- [ ] **Palavra do dia.** É sorteada uma vez por dia (fixa durante o dia) ou a cada abertura da Home? Pode repetir a palavra de ontem?
- [ ] **Sugestão do dia.** Entre os vinhos compatíveis, ela é aleatória ou é o mais semelhante ainda não sugerido? Pode repetir uma sugestão de dias anteriores?
- [ ] **Eixo que mudou.** Se uma avaliação não mudar nenhum eixo (por exemplo, Maybe num vinho já muito próximo do mapa), o card mostra o quê?
- [ ] **Escolha o seu vinho.** O que aparece quando nenhum vinho corresponde aos filtros? E "Another one" quando acabam os vinhos do tipo?
- [ ] **Saudação.** É sempre "Welcome back", ou "Welcome" na primeira abertura depois do Onboarding?
