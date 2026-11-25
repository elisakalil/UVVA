# UVVA · Carta de vinhos

> Status: v0.1 · 2026-11-23
> Depende de: [`HOME.md`](HOME.md) (HOME-R03), [`CELLAR.md`](../Cellar/CELLAR.md) (nova nota), [`MATCH.md`](../Shared/MATCH.md)
> Fonte: canvas UVVA Telas, artboard **WineList** (01 Scan · Wine list, 02 Tonight, 03 Order this, 04 Ask for it).

## 1. Objetivo

A pessoa está no restaurante, com a carta de vinhos na mão, e não sabe o que pedir. A UVVA lê a carta pela câmera, cruza cada vinho com o mapa do paladar (o seu e o dos amigos à mesa), com o prato e com o orçamento, e devolve o vinho para pedir, com a frase pronta para o garçom.

Tudo corre no telefone: Vision para o texto, o catálogo local para os vinhos. Sem rede e sem custo.

## 2. Regras

**WINELIST-R01 · Dois modos no scan.** O `+` da Home abre o scan com um seletor no topo, em vidro: **Label** (o fluxo da nova nota, CELLAR-R16) e **Wine list**. O seletor só aparece enquanto a câmera aparece e fica parado enquanto uma foto é lida; no rótulo, só troca antes da foto da frente. O `+` da Adega e o "Add to cellar" continuam a abrir só o rótulo.

**WINELIST-R02 · Câmera.** Pede a câmera como a nova nota (CELLAR-R15). Com a câmera desligada, diz "The camera is off" e leva aos Ajustes. Também aceita uma foto da galeria.

**WINELIST-R03 · Páginas.** Cada foto é uma página. As páginas somam-se: a mesma linha lida duas vezes é um vinho só. O painel de vidro mostra "N wines found", quantos já combinam com o paladar (match ≥ 80%) e "Use this list". Uma página sem vinhos diz para tentar mais perto; uma que falha diz para tentar de novo, e as páginas anteriores ficam.

**WINELIST-R04 · Ler a carta** (`WineListParser`, Core). Os textos lidos voltam a juntar-se em linhas pela altura; uma carta em duas colunas lê a da esquerda e depois a da direita.
- **Preço:** os números no fim da linha ("42 €", "R$ 1.250,00", "7 / 28"); com copo e garrafa, vale o maior. Um ano nunca é preço ("Crasto 2021"). A moeda é o símbolo mais escrito na carta.
- **Secções:** uma linha só com palavras de tipo ("Tintos", "Red wines", "Espumantes") abre uma secção e dá o tipo aos vinhos dela.
- **Vinho:** cada linha com preço. As linhas sem preço à volta são a casta, a região, o produtor: cada secção vota, pelo primeiro vinho, se vêm depois do nome (nome com preço, detalhe por baixo) ou antes (nome sozinho, detalhe com o preço).
- Sem preços na carta, o vinho é a linha de letra maior e as menores são o detalhe.

**WINELIST-R05 · Reconhecer o vinho** (`WineListIdentifier`, Match). As palavras da linha são lidas como um rótulo (`LabelParser`) e procuradas no catálogo (`LabelMatch`, só com confiança). Sem par no catálogo, o vinho é feito do que a carta diz (casta, região, tipo da secção), com o mapa estimado dos vinhos mais parecidos (`ProfileEstimate`), e aparece como "Read from the list". Uma linha que não diz nada do vinho fica de fora.

**WINELIST-R06 · What's on the table?** Três perguntas, todas opcionais:
- **The dish:** Fish, Seafood, Chicken, Pork, Red meat, Game, Vegetables, Cheese, Dessert (`MenuDish`), os grupos das receitas do catálogo (`mainIngredient`). Vários de uma vez.
- **A bottle, up to:** dois limites tirados dos preços da própria carta (a um terço e a dois terços, arredondados para cima: de 5 em 5 até 100, de 10 até 300, de 50 acima) e "No limit", que é o padrão. Sem dois preços, a pergunta não aparece.
- **Who's drinking:** "You" sempre, e os amigos (os mais recentes primeiro). Sem amigos, a pergunta não aparece.

**WINELIST-R07 · Order this** (`WineListRanking`, Match). Os mapas à mesa cruzam-se num só (`TableMatch.crossed`). Cada vinho tem o match com esse mapa (`Similarity`); com pratos, 55% paladar e 45% prato. O prato é a média, por prato escolhido, da proximidade às 3 receitas mais próximas desse prato feitas para o tipo do vinho; um vinho de um tipo que nenhuma receita do prato pede fica com 70% dessa nota. Os vinhos dentro do orçamento vêm primeiro, do maior match para o menor; depois os de fora, marcados "Over budget" (sem nenhum dentro, diz isso). Empates: o do catálogo antes do estimado, depois o mais barato.
- O primeiro é grande: "Order this", o match, a casta e o lugar, o nome como a carta escreve, preço e lugar na carta, e o porquê (eixos altos em comum com o paladar, ou o eixo mais longe; e "Made for / Holds up to / Not the obvious match for" o prato, a partir de 78% e 65%).
- Os outros vêm por baixo, menores: o segundo é "Same feel, less money" (mesmo tipo, mais barato) ou "Close second"; o terceiro "Something different" (outro tipo) ou "Also on the list".
- Tocar num vinho abre a frase para o garçom desse vinho.
- O match mostrado é o da noite (paladar e prato); a nota na Adega mostra só o do paladar.

**WINELIST-R08 · Say it or show it.** A frase para pedir o vinho como a carta o escreve, em letras grandes para mostrar, na língua do restaurante (English ou Português; começa na do telefone); o que pedir se acabou (o tipo e os dois eixos mais altos, "por volta de" o preço arredondado a 5); e onde está na carta. "It's on the table · add to Cellar" fecha o scan e abre a nova nota em papel com esse vinho (CELLAR-R14a).

## 3. Testes

- `CoreTests/WineListParserTests` (WINELIST-R04)
- `MatchTests/WineListRankingTests` (WINELIST-R05, R07)
