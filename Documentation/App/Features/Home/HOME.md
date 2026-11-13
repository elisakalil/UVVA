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
| `palateMap` | Quiz | Melhor match, Vinhos para o paladar |
| `seenTours` (por conta; o tour da Home é `"home"`) | Home | Tour guiado |
| `quizExit` (`.homeWithTour`) | Quiz (QUIZ-R25) | Tour guiado |
| `friends: [Friend]` (com `hasMap`, `compatibility`) | Friends | Card de amigos |
| `moduleProgress: [ModuleProgress]` (com `lastOpenedAt`, lição e passo atuais) | Learn | Continuar lição |
| `lastRating: Rating?` (com variação por eixo) | Cellar / Home | Eixo que mudou |
| `ratedWineIDs: Set<WineID>` | Cellar / Home | Vinhos para o paladar |
| `wineCatalog: [Wine]` | Catálogo | Melhor match, Vinhos para o paladar, Escolha o seu vinho |
| `glossary: [GlossaryTerm]` | Glossário | Palavra do dia |
| `notifications: [Notification]` (com `isRead`) | Notificações | Header |
| `clock` | Aparelho | Palavra do dia |

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
| 2 | Melhor match (vinho e prato) | Sim |
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

### 4.2 Melhor match (vinho e prato)

**HOME-R06 · Escolha.** Um vinho do catálogo escolhido a partir do mapa do paladar, com o prato que o acompanha. O card abre direto no nome do vinho, sem título por cima (2026-11-10).

**HOME-R07 · Topo do match (2026-11-09).** O card mostra o vinho no topo da lista de match: o vinho com prato mais próximo do mapa (SHARED-R07). Não segue o dia: fica o mesmo enquanto o mapa for o mesmo e muda quando o mapa muda, numa avaliação (a nota do Cellar, CELLAR-R19, QUIZ-R22) ou num Quiz refeito (QUIZ-R18a). Só o vinho do topo recebe o prato; se nenhuma receita servir ao tipo dele, o lugar passa ao seguinte. Vinhos igualmente próximos seguem a ordem da chave do vinho, para o topo ser o mesmo em todas as leituras. Substitui a troca diária.

**HOME-R08 · Pode repetir o Cellar.** Substituída pela HOME-R08a (2026-11-12): o melhor match já não sugere um vinho que está no Cellar.

**HOME-R08a · Só vinhos novos (2026-11-12).** Os cards que sugerem vinhos (o melhor match, "A wine for each strong trait" e "Choose yourself") só sugerem vinhos novos: vinhos que não estão no Cellar do usuário, provados ou Not yet. Um vinho avaliado que não está no Cellar (avaliado na Home antes da HOME-R24 atual) continua novo.
- **Uma lista só:** o catálogo é ordenado pelo mapa (SHARED-R07) e os vinhos do Cellar saem dessa lista antes de o prato ser escolhido; os três cards leem a mesma lista. O prato vai para o primeiro vinho novo a que uma receita sirva (HOME-R07).
- **Um vinho entra no Cellar:** sai dos três cards sem ranking novo e sem cortina, porque o mapa não mexeu (HOME-R23). Se era o melhor match, o vinho novo seguinte com receita passa a ser o melhor match, com o seu prato. Depois de uma nota nova, a Home é lida toda de novo (HOME-R10c).
- **Um vinho sai do Cellar** (a nota apagada, CELLAR-R29): volta a ser novo, e o catálogo é ordenado de novo para ele voltar ao lugar dele; sem cortina, se o mapa não mexeu.
- **Sem travar a app:** o ranking dos vinhos do catálogo e as receitas são lidos na fila do catálogo, fora da main thread; tirar os vinhos do Cellar, escolher o prato, montar os cards e a busca de "Find my wine" correm em tarefas em segundo plano. A main thread só publica o resultado, e a Home mostra o que já tinha até lá.

**Critérios**
- Dado o melhor match A, quando A vai para o Cellar, então o card mostra o vinho novo seguinte com prato, e A não aparece em "Choose yourself".
- Dado um vinho no Cellar como Not yet, então ele não aparece em nenhum dos três cards.
- Dado um vinho do Cellar cuja nota é apagada, quando a Home volta a aparecer, então ele pode voltar a ser sugerido.
- Dada uma Home aberta, quando um vinho entra no Cellar, então o catálogo não é ordenado de novo.

**HOME-R09 · Receita.** "See the wine & the dish" expande o card: o prato, por que combina, ingredientes, passos e como servir. "Show less" recolhe.

**HOME-R09a · Find the wine.** Abre, dentro da app (Safari em folha), uma pesquisa na internet com o produtor, o nome e o ano do vinho; sem ano, só produtor e nome. O produtor não se repete quando já está no nome (2026-10-31).

**HOME-R10 · Ausência.** O card não aparece se o catálogo não tiver nenhum vinho com prato associado. Não há match mínimo: com o mapa longe de todos os vinhos, o topo aparece na mesma, com a sua % (2026-11-09).

**HOME-R10c · Só o que segue o mapa (2026-11-10).** Quando o mapa muda, a Home não é lida toda de novo: lê só o que segue o mapa (o mapa, as avaliações, as chaves do Cellar e o ranking do catálogo) e refaz os cards sobre isso.
- **Quando:** numa nota editada ou apagada no Cellar (CELLAR-R29), na próxima vez que a Home aparece, uma vez só, por mais notas que tenham mudado.
- **Depois de uma nota nova (2026-11-12):** a Home é lida toda de novo, não só o que segue o mapa, porque o match de cada vinho e "A wine for each strong trait" mudam com a avaliação. Durante a leitura, todos os cards mostram a cortina de uvinhas descrita em **Loading**, cada um com o seu tamanho e cantos, e não respondem a toques; os cards novos chegam com o fim das cortinas. Quando a nota veio do "Add to cellar" do melhor match, a Home também volta ao topo, numa rolagem suave, e o card recolhe quando ela chega lá (as duas coisas ao mesmo tempo faziam os cards saltar), tudo sob a cortina, para o melhor match novo aparecer ali; vinda da folha do vinho ou do Cellar, a Home fica onde estava (2026-11-12).
- **Antes de ler o catálogo:** a Home compara o mapa, os vinhos avaliados, a última avaliação e as chaves do Cellar com os que tem. Se nada mudou (uma nota que só mudou o texto), não há loading nem ranking. Se só o Cellar mudou, não há loading: um vinho que entrou no Cellar sai das sugestões sem ranking novo, e um que saiu dele obriga a ordenar o catálogo de novo (HOME-R08a).
- **Loading:** o card do melhor match e "Wines for your palate" mostram uma cortina de uvinhas, em vários tamanhos e opacidades, que escorre devagar de cima para baixo. O card mantém o tamanho (o do melhor match recolhe, se estava aberto), o conteúdo some por baixo da cortina e não responde a toques. Com Reduce Motion, as uvas ficam paradas.
- **Fim:** os cards novos e o fim do loading chegam juntos; a cortina sai num fade lento (1,4 s) enquanto o conteúdo novo aparece. A cortina fica pelo menos 1,8 s, para ser vista a correr e não como um piscar.
- Os outros cards não mostram loading; os que usam o mapa (amigos, o eixo que mudou, "Choose your wine") são refeitos em silêncio.

**HOME-R10a · Por que foi escolhido (2026-11-01).** O card lê o vinho contra o mapa com a mesma leitura para todos os textos (`WineFit`), para que eles nunca se contradigam. "Alto" é nível acima de 5, no mapa e no vinho; 5 é neutro (QUIZ-R14a).
- **Eixos mostrados:** os 3 eixos mais fortes do mapa. Entre eixos empatados no mapa, vão os que o vinho tem mais altos (nunca a ordem canônica).
- **Eixos em comum:** até 2 eixos altos no mapa e no vinho, na mesma ordem.
- **Frase:**
  - 2 em comum: "Your map likes [a] and [b], and this wine is high on both.";
  - 1 em comum: "Your map likes [a], and this wine is high on it.";
  - nenhum, sem eixo alto no mapa nem no vinho: "Nothing runs high on your map, and nothing runs high on this wine.";
  - nenhum nos outros casos: sem frase.

**HOME-R10b · With your palate (2026-11-01).** O match em % (QUIZ-R21) e duas linhas:
- **Em comum:**
  - "High in [a] and [b], like your map." / "High in [a], like your map.";
  - sem eixo alto no mapa: "Bolder than your map, which has no high axis." se o vinho tem algum eixo alto, ou então "Quiet on every axis, like your map.";
  - mapa com um eixo alto só, que o vinho não tem: "Not high in [eixo], the strongest axis on your map.";
  - mapa com vários eixos altos, nenhum no vinho: "Different from the strongest axes on your map."
- **Diferença:** o eixo de maior distância entre vinho e mapa, se for de pelo menos 1.8: "More [eixo] than you usually drink." ou "Less [eixo] than you usually drink."; senão, "Close to your map on every axis."
- Todos os textos estão no catálogo de strings da Home.

**Critérios**
- Dado o mesmo mapa, quando a Home é montada nos dias 27/10 e 28/10, então o vinho do card é o mesmo nos dois.
- Dado o vinho A no topo, quando o usuário guarda uma nota que avalia um vinho e o mapa passa a estar mais perto do vinho B, então o card mostra B sem a Home ser reaberta.
- Dados dois vinhos igualmente próximos do mapa, então o card mostra sempre o mesmo dos dois.
- Dado um mapa a 40% do vinho mais próximo, então o card aparece com esse vinho.
- Dada uma nota cujo veredito mudou no Cellar, quando a Home volta a aparecer, então só o melhor match e "Wines for your palate" mostram a cortina, e o resto da Home não é lido.
- Dadas três notas editadas no Cellar, quando a Home volta a aparecer, então o que segue o mapa é lido uma vez.
- Dada uma nota que só mudou o texto, quando a Home volta a aparecer, então não há cortina e o catálogo não é ordenado de novo.
- Dado um mapa todo em 3 e um vinho alto em Fruit (8) e Acidity (7), então os eixos mostrados são Fruit e Acidity primeiro, a frase do card não aparece e a linha em comum é "Bolder than your map, which has no high axis."
- Dado um mapa com sete eixos em 2 e Acidity em 7, e um vinho alto em Floral, então o card nunca diz que o mapa gosta de Floral, e a linha em comum é "Not high in acidity, the strongest axis on your map."
- Dado um mapa com sete eixos em 7 e Oak em 2, e um vinho com Fruit 8 e Acidity 7, então a frase é "Your map likes fruit and acidity, and this wine is high on both."
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

**HOME-R22 · Lista.** Mostra uma sugestão para cada eixo do mapa com valor alto (≥ 7) ou baixo (≤ 4) que tenha um vinho elegível no catálogo. O vinho precisa estar na mesma faixa naquele eixo. Quando o mapa está abaixo de 4, o vinho também precisa estar abaixo de 4. A menor distância no eixo tem prioridade, seguida pela similaridade geral (SHARED-R07). As linhas seguem a ordem canônica dos eixos e um vinho pode aparecer em mais de um eixo. Cada linha mostra nome e produtor e o ícone com o nível do eixo, sem safra nem frase sobre o encaixe (2026-11-10). O card não tem título de seção: o título fica dentro do card, em Red Grapes, e diz o que a lista é: "A wine for each strong trait of your map" (2026-11-10).

**HOME-R23 · Exclusão (2026-11-10).** Vinhos que estão no Cellar, provados ou não, ficam fora da seleção (HOME-R08a, que vale para os três cards que sugerem vinhos). Quando um vinho vai para o Cellar, os eixos que ele representava passam a usar os próximos vinhos elegíveis, quando houver; a lista é refeita sem cortina (HOME-R10c), porque o mapa não mexeu. Um vinho avaliado que não foi para o Cellar continua na lista. Substitui a exclusão por avaliação.

**HOME-R24 · Detalhes (2026-11-12).** Tocar num vinho abre a folha do vinho (HOME-R28a). A folha não avalia: no rodapé, fixos, ficam "Find the wine" (HOME-R09a) e, logo abaixo, "Add to cellar".
- **Add to cellar** fecha a folha e abre a nota nova do Cellar já no vinho em papel, a mesma que aparece depois de ler um rótulo (CELLAR-R14a). É na nota que o usuário diz se já provou o vinho e o avalia; o vinho só entra no Cellar, e o mapa só muda, quando a nota é guardada. Fechar a nota sem guardar não guarda nada;
- um vinho avaliado antes leva o veredito que tem: a nota pergunta "Rate it again?" em vez de "Have you had this wine?" (CELLAR-R14a);
- um vinho que já está no Cellar mostra o botão como "In your cellar", inativo;
- não há aviso no topo da Home sobre o mapa: depois de guardar a nota, a Home é lida de novo sob a cortina (HOME-R10c).

Substitui a pergunta da folha ("Have you had this wine?" e "Would you drink it again?"), que avaliava o vinho e mexia o mapa na hora, e o aviso "Map updated · Acidity ↑ · Fruit ↑" que ela mostrava (2026-11-12). Avaliar passou a acontecer num lugar só, a nota do Cellar.

**HOME-R25 · Ausência.** O card aparece quando pelo menos um eixo encontra uma sugestão elegível.

**Critérios**
- Dado um mapa com floral 7 e tanino 4, então as sugestões de floral alto e tanino baixo têm, respectivamente, floral ≥ 7 e tanino ≤ 4.
- Dado um eixo alto sem vinhos elegíveis naquela faixa, então a lista omite esse eixo.
- Dado que o vinho #1 já tinha sido avaliado no Cellar, então ele não aparece na Home.
- Dada uma nota nova guardada com um veredito que muda o mapa, então a lista é recalculada com o mapa novo.
- Dada a folha de um vinho, então o rodapé mostra "Find the wine" e "Add to cellar", sem pergunta.

### 4.9 Escolha o seu vinho

**HOME-R26 · Sempre visível.** Um formulário no fim da Home com direção, tipo, região, harmonização opcional e até 3 notas. A harmonização usa as categorias de pratos registradas no catálogo. Tocar novamente no prato selecionado limpa esse filtro.

A direção é a primeira escolha do formulário. **Para o meu paladar** vem selecionada e prioriza os mapas mais parecidos. **Me surpreenda** prioriza perfis diferentes que ainda tenham pelo menos metade dos eixos próximos do mapa da pessoa. Ambas as direções respeitam os filtros do formulário.

**HOME-R27 · Limite de notas.** É possível escolher no máximo 3 notas; com 3 escolhidas, as outras ficam inativas até uma ser desmarcada.

**HOME-R28 · Resultado.** "Find my wine" abre a folha do vinho (HOME-R28a) com o vinho novo (HOME-R08a) que melhor corresponde aos filtros e ao paladar. A busca corre em segundo plano, e um segundo toque enquanto ela corre não começa outra. "Show another ›" mostra o seguinte do mesmo tipo. O vinho vai para o Cellar, e é avaliado, pela nota que "Add to cellar" abre (HOME-R24).

**HOME-R28a · Folha do vinho (2026-11-07).** A mesma folha serve a "Vinhos para o seu paladar" e a "Escolha o seu vinho" (tela "Beberia outra vez?" no design). Papel creme, tinta escura, cantos de 28. Abre quase até ao topo, com a Home escurecida atrás. Mostra, de cima para baixo:
- o nome do vinho em maiúsculas desenhadas, menor quanto mais longo;
- por baixo, o produtor; num resultado do formulário, "Your pick · [produtor]";
- num resultado, "2 of 5 red wines for your choices" e "Show another ›", que mostra o seguinte e volta ao primeiro no fim;
- o match (HOME-R10b), sem título; em "Surprise me", a distância ("away from your map");
- os factos, sem título, em duas colunas onde há par: Origin | Vintage ("2023 · 3 years", ou "Non-vintage"); Style | Grape & notes; Pairings. Os que o vinho não tem ficam fora;
- How to serve: a temperatura de servir ("8–10 °C") e, por baixo, a frase sobre como servir; aparece com uma das duas. Não há campo "Serve at" (2026-11-11);
- a lista dos eixos do vinho em pontos, como no card do melhor match (2026-11-11);
- os dois mapas, com a legenda This wine, Your map e In common;
- no rodapé, fixos, "Find the wine" (HOME-R09a) e "Add to cellar" (HOME-R24) (2026-11-12).

**Critérios**
- Dadas 3 notas escolhidas, quando o usuário tenta escolher a quarta, então ela não é selecionada.
- Dados filtros sem nenhum vinho correspondente, a folha informa que nenhum vinho combina e orienta a mudar um filtro.

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
| 1 | Today | A pairing drawn for your palate | Every day UVVA designs a full experience around your map: a wine that hits the notes you love loudest, and a recipe built to balance everything else. | Melhor match (4.2) |
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
- [x] **Sugestão do dia.** Deixou de ser diária: é o vinho no topo da lista de match e repete-se enquanto o mapa não mudar (HOME-R07, 2026-11-09).
- [ ] **Eixo que mudou.** Se uma avaliação não mudar nenhum eixo (por exemplo, Maybe num vinho já muito próximo do mapa), o card mostra o quê?
- [ ] **Escolha o seu vinho.** O que aparece quando nenhum vinho corresponde aos filtros? E "Another one" quando acabam os vinhos do tipo?
- [ ] **Saudação.** É sempre "Welcome back", ou "Welcome" na primeira abertura depois do Onboarding (logo depois do tour, que já diz "Welcome in")?
- [ ] **Pular o tour.** O tour pode ser pulado (por exemplo, um "Skip" na intro)? Pular conta como visto?
- [ ] **Rever o tour.** O tour pode ser visto de novo depois (por exemplo, em You › Settings)?
- [ ] **Tour interrompido.** Se a app fechar no meio do tour, ele aparece de novo na próxima abertura, ou só conta como visto ao tocar em "Start"?
- [ ] **Passo 1 sem sugestão.** Se o card "Melhor match" não aparecer (HOME-R10), o passo 1 é pulado ou destaca outro card?
