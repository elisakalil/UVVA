# UVVA · Match

> Status: v0.1 · 2026-10-31
> Package `Match` (PROJECT.md). Os detalhes de cada cálculo são definidos na app.

## Usuário × vinho

Um vinho combina com o usuário quando o mapa do vinho tem valores próximos dos valores do mapa do usuário. A porcentagem de match é calculada a partir da distância euclidiana entre os dois mapas.

## Usuário × vinho × receita

O cruzamento do usuário com o vinho mais próximo produz um mapa. Esse mapa, junto com os outros dados da receita, é usado para achar a receita que harmoniza.

## Usuário × usuário

Para uma dupla ou um grupo, os mapas de todos são cruzados num só. Esse mapa é usado para achar um vinho com o mapa parecido.

## Surpreenda-me

Quando o usuário pede um vinho que o surpreenda, a app procura um vinho com o mapa parecido com o do usuário em todos os eixos menos um.

## Segmento

Cada vinho do catálogo tem um `segment`, um número que agrupa vinhos com mapas parecidos. O sync do catálogo pede ao CloudKit só os vinhos dos segmentos próximos do mapa do usuário (ARCHITECTURE §4.1). O cálculo ainda não está definido e tem de existir antes do sync do catálogo.

## Implementação atual (2026-11-15)

- **Régua única:** `WineRuler` (package `Core`). Usuários e vinhos ficam na mesma régua fixa de 0 a 9, nunca recalculada a partir do catálogo (QUIZ-R04a). Guarda-se e calcula-se na régua; mostra-se a **posição** (a resposta do Quiz que cairia ali): radar (`PalateMap.chartValues`), pips (`MapReading.level(mapa, eixo)`), textos (`MapReading`, `AxisTone(mapa, eixo)`).
- **Mapa do Quiz:** `QuizMapBuilder` (package `Match`): lê as respostas na régua, assenta-as entre os 20 vinhos mais parecidos (uma entrada por vinho, sem colheitas) e mantém cada eixo a ±1,5 posição da resposta (QUIZ-R04a–c). Vinhos novos (scan, `ProfileEstimate`, robô) entram já na régua.
- **Usuário × vinho:** `Similarity.between` (package `Match`), distância euclidiana nos 8 eixos da régua, `1 − d/13`, uma reta (QUIZ-R21). Ordenações usam `Similarity.distance`.
- **Leitura do vinho do dia:** `WineFit` lê níveis, "high" e a maior diferença pela posição.
- **Usuário × vinho × receita:** `Pairing.recipe` — o mapa cruzado é a média dos dois mapas; a receita é a mais próxima dele, só entre as feitas para o tipo do vinho (`wineTypes`), com entradas e pratos principais antes de sobremesas, petiscos e queijos.
- **Usuário × usuário:** `TableMatch` (package `Match`), proposta do [`PLANO-FRIENDS.md`](../../Plans/PLANO-FRIENDS.md) §4, a confirmar (N4):
  - `compatibility(a, b)` = `Similarity.percent`, a mesma distância do vinho.
  - `tableCompatibility(mapas)` = média de `Similarity.between` de cada par, em %. Uma mesa de dois é a compatibilidade do par.
  - `sharedAxes(mapas)`: eixos em que todos estão em ≥ 5,5 de posição e a diferença entre a maior e a menor posição é ≤ 1,5, pela média, no máximo 3.
  - `axisSpread(mapas, eixo)` pela diferença de posição máx − mín: Same ≤ 0,5 · Closest ≤ 1,5 · Some give ≤ 3 · Widest > 3. `range` também é em posição.
  - `crossed(mapas)` é a média de cada eixo na régua ("Where the table lands"); `boldest(mapas)` o valor mais alto de cada eixo.
  - `tableBottles(mapas, vinhos, receitas)`: para cada curso (Starter, Main, Dessert), a receita do curso mais próxima do mapa cruzado e o vinho, de um tipo dessa receita, mais próximo da média entre o mapa cruzado e a receita. Um vinho só entra uma vez; um curso sem receita ou sem vinho fica de fora. O eixo da garrafa é o eixo em comum em que o vinho se destaca mais (maior posição; sem eixos em comum, os 3 eixos de maior posição do mapa cruzado).
- **Melhor match (Hero da Home):** o vinho mais próximo do usuário, o topo da lista; muda quando o mapa muda, não com o dia (HOME-R07).
