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

## Implementação atual (2026-10-31)

- **Usuário × vinho:** `Similarity.between` (package `Match`), distância euclidiana nos 8 eixos (QUIZ-R21).
- **Usuário × vinho × receita:** `Pairing.recipe` — o mapa cruzado é a média dos dois mapas; a receita é a mais próxima dele, só entre as feitas para o tipo do vinho (`wineTypes`), com entradas e pratos principais antes de sobremesas, petiscos e queijos.
- **Sugestão do dia:** um dos 30 vinhos mais próximos do usuário, escolhido pelo dia do calendário (o mesmo durante o dia, HOME-R07).
