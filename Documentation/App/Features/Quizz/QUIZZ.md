# UVVA · Quiz (questionário do paladar)

> Status: rascunho v0.3 · 2026-10-31 · dúvidas D1–D8 respondidas
> Depende de: [`SHARED.md`](../Shared/SHARED.md), [`ONBOARDING.md`](../Onboarding/ONBOARDING.md), [`HOME.md`](../Home/HOME.md)
> Fonte: canvas UVVA App, artboard Quiz, telas 07 a 10.

## 1. Objetivo

O Quiz transforma oito perguntas sobre comida num **mapa do paladar**: uma intensidade para cada um dos oito eixos do vinho. O mapa é a base de tudo o que a UVVA recomenda (SHARED-R05 a R07).

O Quiz é uma feature própria, separada do Onboarding. Ele abre em dois momentos: logo depois do cadastro, para desenhar o primeiro mapa, e sempre que o usuário quiser refazer o mapa (You › Map › "Redo the map"). O Quiz não depende de nada do cadastro além do primeiro nome.

Esta feature também é dona das três funções que as outras features usam:

- o cálculo do mapa a partir das respostas;
- a similaridade entre um vinho e o mapa (SHARED-R07);
- a atualização do mapa depois de uma avaliação (SHARED-R09).

## 2. Modelo

### 2.1 Eixos

**QUIZ-R01 · Oito eixos.** O mapa tem exatamente oito eixos. Existem duas ordens:

| Ordem das perguntas | Ordem no gráfico (radar, a partir do topo, sentido horário) |
| --- | --- |
| 1 Sweetness | Floral (0°) |
| 2 Acidity | Body (45°) |
| 3 Tannin | Tannin (90°) |
| 4 Body | Spice (135°) |
| 5 Fruit | Oak (180°) |
| 6 Floral | Sweetness (225°) |
| 7 Oak | Acidity (270°) |
| 8 Spice | Fruit (315°) |

**QUIZ-R02 · Ordem canônica para desempate.** Quando dois eixos têm o mesmo valor, vale a ordem do gráfico: Floral, Body, Tannin, Spice, Oak, Sweetness, Acidity, Fruit. Esta é a ordem que a HOME-R16 e as outras features usam.

### 2.2 Escala

**QUIZ-R03 · Resposta.** Cada pergunta é respondida numa barra de 10 posições, de 0 a 9.

**QUIZ-R04 · Intensidade do eixo.** As respostas são só o ponto de partida. Ao tocar em "Draw the map", cada resposta é lida na régua dos vinhos (QUIZ-R04a), assentada entre vinhos reais (QUIZ-R04b) e mantida perto do que foi respondido (QUIZ-R04c). O mapa guardado e mostrado é o resultado, de 0 a 9 na régua; as respostas nunca aparecem na app. Depois das avaliações (QUIZ-R22), a intensidade pode ter casas decimais, mas fica sempre entre 0 e 9.

**QUIZ-R04a · A régua (2026-11-15).** Usuários e vinhos usam a mesma régua fixa de 0 a 9 (`WineRuler`, package `Core`): quanto de cada eixo um vinho tem. A régua é escrita uma vez e nunca recalculada a partir do catálogo, por isso um vinho mapeado amanhã e um mapa desenhado hoje ficam na mesma escala, com 10 mil ou 350 mil vinhos. Cada resposta r vale o valor da régua na linha r da tabela:

| Eixo | 0 | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9 |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| Floral | 1.0 | 1.5 | 2.0 | 2.5 | 3.0 | 3.5 | 4.0 | 4.5 | 5.5 | 7.0 |
| Body | 2.0 | 3.5 | 4.5 | 5.0 | 5.5 | 6.0 | 6.5 | 7.0 | 7.5 | 8.5 |
| Tannin | 0.0 | 0.5 | 1.0 | 2.0 | 4.0 | 5.0 | 6.0 | 6.5 | 7.0 | 8.5 |
| Spice | 0.5 | 1.0 | 2.0 | 2.5 | 3.0 | 3.5 | 4.0 | 5.0 | 6.0 | 7.0 |
| Oak | 0.5 | 1.0 | 1.5 | 2.0 | 2.5 | 3.0 | 3.5 | 4.5 | 5.5 | 7.0 |
| Sweetness | 1.0 | 1.0 | 1.0 | 1.0 | 1.5 | 2.0 | 3.0 | 5.0 | 7.0 | 8.5 |
| Acidity | 3.5 | 4.5 | 5.0 | 5.5 | 6.0 | 6.5 | 7.0 | 7.5 | 8.0 | 9.0 |
| Fruit | 3.0 | 4.5 | 5.0 | 5.5 | 6.0 | 6.5 | 7.0 | 7.5 | 8.0 | 9.0 |

Porquê: os vinhos ocupam uma zona pequena de cada eixo (quase todos secos, pouco florais, ácidos), por causa de como o vinho é feito. Lida à letra, "doçura 5" procuraria um vinho meio-doce que quase não existe. A régua lê "gosto bastante de floral" como "quero um vinho mais floral que a maioria". Os valores são um rascunho perto dos percentis da seed de 10.000 vinhos; a doçura é feita à mão, para quem gosta de doce só chegar a um vinho doce quando a resposta é alta. Uma nova versão da régua (`WineRuler.version`) é uma decisão, nunca um recálculo automático.

A **posição** é o caminho inverso: o valor da régua lido como a resposta que cairia ali, de 0 a 9, em linha reta entre duas respostas. Num trecho plano vale o meio: um vinho seco (doçura 1.0, respostas 0 a 3) lê 1,5, nível 2, "Dry". Assim as respostas 0 a 3 mantêm a ordem contra os outros eixos, em vez de caírem todas em 0 (o que faria da doçura o "Never" de ~40% dos usuários). Abaixo do primeiro valor lê 0 ("Bone dry"). Tudo o que a app mostra (radar, pips, palavras, textos, deltas) usa a posição; o match, as avaliações e o que se guarda usam a régua. Nas notas, tocar num pip guarda o valor da régua nessa posição.

**QUIZ-R04b · Assentar entre vinhos reais.** O mapa lido na régua é puxado para o meio dos 20 vinhos do catálogo mais parecidos com as respostas (distância em posição), cada vinho uma vez só, sejam quantas forem as colheitas, com peso maior para os mais próximos. É isto que respeita as ligações entre eixos (corpo com tanino, carvalho com corpo). Sem catálogo no aparelho, o mapa é só a leitura na régua.

**QUIZ-R04c · A alma.** Nenhum eixo fica a mais de 1,5 posição da resposta. Uma resposta ≥ 6 fica sempre ≥ 5,5 (acima do meio); uma resposta ≤ 3 fica sempre ≤ 3,5 (abaixo). Quem gosta de floral fica sempre com um mapa que pede vinhos mais florais que a maioria.

As respostas e a versão da régua ficam guardadas com o Quiz no histórico do mapa, fora da vista, para o mapa poder ser refeito se a régua mudar.

**QUIZ-R05 · Nível exibido.** Os pips de um eixo usam `round(posição)` (QUIZ-R04a), de 0 a 9, no mapa do usuário, no dos amigos e no dos vinhos. A palavra ao lado diz o que esse nível quer dizer num copo, por eixo (`AxisLevels`), a mesma para um vinho e para um mapa: um mapa em floral 8 pede um vinho muito floral; um vinho em floral 8 é um. A palavra cabe numa linha ao lado dos pips: em português, no máximo 16 caracteres (2026-11-23).

| Nível | Floral | Body | Tannin | Spice |
| --- | --- | --- | --- | --- |
| 0 | No flowers | Feather-light | No grip, like a white | No spice |
| 1 | Barely floral | Light | Barely any grip | Barely spiced |
| 2 | A faint blossom | Light to medium | A whisper of grip | A touch of pepper |
| 3 | A hint of flowers | Medium-light | Soft, like a light red | Lightly spiced |
| 4 | Lightly floral | Medium | Gentle grip | Some spice |
| 5 | Gently floral | Medium, rounded | Medium grip | Gently spicy |
| 6 | Clearly floral | Medium-full | Firm | Spicy |
| 7 | Floral | Full | Firm and drying | Clearly spicy |
| 8 | Very floral | Full and broad | Grippy | Very spicy |
| 9 | Perfumed | Mouth-filling | Powerful, mouth-drying | Peppery and bold |

| Nível | Oak | Sweetness | Acidity | Fruit |
| --- | --- | --- | --- | --- |
| 0 | Unoaked | Bone dry | Flat, very soft | Restrained, little fruit |
| 1 | Barely any oak | Dry | Soft | Subtle fruit |
| 2 | Old oak, hardly felt | Dry | Gentle | Light fruit |
| 3 | A hint of oak | Dry, a touch of sugar | Moderate | Some fruit |
| 4 | Light oak | Just off-dry | Balanced | Fruity |
| 5 | Some oak | Off-dry | Fresh | Clearly fruity |
| 6 | Noticeable oak | Medium-dry | Bright | Ripe fruit |
| 7 | Oaky, vanilla and toast | Medium-sweet | Crisp | Juicy |
| 8 | Very oaky | Sweet | Zesty | Lush fruit |
| 9 | New oak up front | Lusciously sweet | Racy, mouth-watering | Bursting with fruit |

As palavras aparecem nas leituras do resultado do Quiz, de You › Map e do perfil de um amigo, e ao lado dos pips do vinho na ficha, no Hero e na nota. As palavras genéricas de antes (None … As much as possible) ficam só para o nível sem eixo.

```swift
struct PalateMap: Equatable {
    var values: [PalateAxis: Double]   // 0...9 na régua, exatamente 8 chaves
}
```

**Critérios**
- Dadas as respostas, então o mapa lido é `WineRuler.value(of:on:)` de cada uma.
- Dada a doçura 5, então o mapa lido tem doçura ≤ 2; dada a doçura 9, ≥ 8.
- Dado um vinho com doçura 1.0, então a posição da doçura é 1,5 e a palavra é "Dry"; com doçura abaixo de 1.0, posição 0, "Bone dry".
- Dada uma doçura 1.01, então a posição fica logo acima de 1,5, sem salto.
- Dado floral 8 e os vinhos vizinhos menos florais, então o floral fica na posição ≥ 6,5.
- Dada uma resposta 6 e vizinhos baixos, então o eixo fica na posição 5,5; dada uma resposta 3 e vizinhos altos, fica em 3,5.
- Dadas 30 colheitas do mesmo vinho entre os vizinhos, então contam como um vinho.
- Sem catálogo, então o mapa é a leitura na régua.
- Dada a posição 6.4 em floral, então o nível exibido é 6, "Clearly floral".

## 3. Fluxo

```
[entrada] → Intro (How UVVA works) → Leitura 1 … Leitura 8 → Resultado (o mapa)
                                                                ├── Keep this map → Partilhar o mapa → [saída]
                                                                └── Read it again → Leitura 1
```

### 3.0 Entradas e saídas

**QUIZ-R24 · Entradas.** O Quiz abre sempre na Intro, com todas as barras vazias, por uma de duas entradas:

| Entrada | De onde vem | O usuário já tem mapa? |
| --- | --- | --- |
| Primeiro mapa | Fim do cadastro (ONB-R21), ou sessão sem mapa ao abrir a app ou ao entrar numa conta (ONB-R02, ONB-R27) | Não |
| Refazer | You › Map › "Redo the map" (YOU-R13) | Sim |

**QUIZ-R25 · Saídas.** A folha de partilha (3.4) só termina com "Not now". Partilhar ou guardar a imagem deixa o usuário na folha (2026-11-23). "Not now" leva a:

| Entrada | Vai para |
| --- | --- |
| Primeiro mapa | Home, com o tour guiado (HOME-R29) |
| Refazer | You › Map, sem o tour (QUIZ-R18a) |

**QUIZ-R26 · Sair sem concluir.** Na entrada "primeiro mapa" não existe saída: sem mapa não se usa a app (FRI-R01). Na entrada "refazer", sair antes de "Keep this map" mantém o mapa atual sem nenhuma mudança (ver D10).

**Para TDD:** a entrada é um parâmetro do Quiz, e a saída é uma função pura dela:

```swift
enum QuizEntry { case firstMap, redo }
enum QuizExit { case homeWithTour, youMap }

func exit(for entry: QuizEntry) -> QuizExit
```

**Critérios**
- Dada a entrada "primeiro mapa", quando o usuário toca em "Not now" na folha de partilha, então abre a Home com o tour guiado.
- Dada a entrada "refazer", quando o usuário toca em "Not now" na folha de partilha, então abre You › Map e o tour não aparece.
- Quando o usuário partilha ou toca em "Save image", então volta à folha de partilha e o Quiz não termina.
- Dada a entrada "refazer", quando o usuário sai do Quiz na Leitura 5, então o mapa guardado é o mesmo de antes.

### 3.1 Intro

**QUIZ-R06 · Conteúdo.** A tela "How UVVA works" mostra "Welcome, [primeiro nome]", "Discover your taste in wine" e "Answer eight questions about the food you love. We turn your answers into a taste map and use it to find wines you'll enjoy." Seguem o radar animado, os três passos, "Eight readings · two minutes" e o botão "Read my palate", que abre a Leitura 1.

| # | Passo | Texto |
| --- | --- | --- |
| 01 | Your palate | Your answers are the starting point: we read them in wine terms and settle them among real wines. That shape is your taste map. |
| 02 | Every wine | We map each wine on the same eight axes, using its grape, how it was made, time in oak, residual sugar and region. |
| 03 | The match | We compare the two maps to find the wines closest to your taste, and the recipes that go with them. |

### 3.2 Leituras (perguntas)

**QUIZ-R07 · Uma pergunta por eixo.** São 8 leituras, uma por eixo, na ordem das perguntas (QUIZ-R01). O topo mostra "Reading N · [Eixo]", o contador "N of 8" e a mesma barra de progresso das lições (`StepDots`, DesignSystem): 8 pontos unidos por uma linha, os anteriores preenchidos, o atual a brilhar, os seguintes vazios.

**QUIZ-R08 · Três versões da pergunta.** Cada eixo tem 3 perguntas alternativas, cada uma com as suas 10 respostas (uma palavra para cada posição da barra). A primeira mostrada é a versão 1.

**QUIZ-R09 · Change question.** Troca para a versão seguinte do mesmo eixo, em ciclo (1 → 2 → 3 → 1). A posição escolhida na barra se mantém; só muda a pergunta e a palavra da resposta.

**QUIZ-R10 · Responder.** Cada leitura abre com a barra vazia, sem nenhuma posição selecionada e sem palavra de resposta. Tocar numa posição seleciona-a e mostra a palavra correspondente da versão atual. Tocar noutra posição troca a seleção.

**QUIZ-R11 · Avançar.** O botão diz "Next" nas leituras 1 a 7 e "Draw the map" na leitura 8. Ele só fica ativo com uma posição selecionada.

**QUIZ-R12 · Voltar.** O "Back", numa pílula com contorno como no topo de um amigo (2026-11-23), volta à leitura anterior, com a resposta dada e a versão da pergunta preservadas. Na Leitura 1, volta à Intro.

**QUIZ-R13 · Rodapé.** Todas as leituras mostram "Answer for the food, not the bottle."

**QUIZ-R13a · Sair no meio.** As respostas só existem enquanto o Quiz está aberto. Se a app for fechada antes de "Keep this map", nada é guardado. Na entrada "primeiro mapa", a app abre de novo na Intro do Quiz, com todas as barras vazias (ONB-R02). Na entrada "refazer", o mapa atual continua e a app abre normalmente.

**Critérios**
- Dada a Leitura 1 aberta pela primeira vez, então nenhuma posição está selecionada e o botão está inativo.
- Dadas as leituras 1 a 4 respondidas, quando a app é fechada e aberta de novo, então o Quiz abre na Intro e a Leitura 1 está vazia.
- Dada a Leitura 1, então o contador mostra "1 of 8" e o eixo é Sweetness.
- Dada a posição 6 selecionada na versão 1 de Sweetness, quando o usuário toca em Change question, então aparece a versão 2, a posição 6 continua selecionada e a palavra passa a ser a da versão 2 na posição 6 ("It drips").
- Dada a versão 3, quando o usuário toca em Change question, então volta à versão 1.
- Dada a Leitura 3 com a posição 4, quando o usuário vai à Leitura 4 e volta, então a Leitura 3 mostra a posição 4.
- Dada a Leitura 8, então o botão diz "Draw the map".
- Dada uma leitura sem posição selecionada, então o botão está inativo.

### 3.3 Resultado (o mapa)

**QUIZ-R14 · Ranking.** Os eixos são ordenados por valor decrescente, com desempate pela ordem canônica (QUIZ-R02). A ordem canônica só serve para ordenar: nenhum texto escolhe um eixo empatado em vez de outro por ela (QUIZ-R14a).

**QUIZ-R14a · Empates e tom (2026-11-01).**
- **Patamares:** os eixos com o mesmo nível exibido (QUIZ-R05) formam um patamar e contam como empatados. Usar o nível, e não o valor, evita que 7.2 contra 6.8 eleja um "mais forte" que os pips não mostram.
- **Tom:** um eixo é *baixo* com nível abaixo de 5, *neutro* com nível 5 e *alto* com nível acima de 5. Vale para o mapa e para os vinhos (HOME-R10a).
- **Líderes:** os eixos do topo, em patamares inteiros, até um limite. Um patamar que não cabe inteiro fica de fora. Um mapa plano não tem líderes.
- **Formato:**
  - *plano* (baixo, neutro ou alto): os 8 eixos no mesmo nível;
  - *sete e um abaixo*: sete eixos num nível e o oitavo abaixo deles;
  - *sete e um acima*: sete eixos num nível e o oitavo acima deles;
  - *com forma*: qualquer outro.

**QUIZ-R15 · Textos gerados.**
- **Frase dominante:**
  - plano: "Quiet on every axis" (baixo), "In the middle on every axis" (neutro) ou "High on every axis" (alto);
  - sete e um abaixo, com o topo alto: "Everything but [eixo]";
  - os outros: os líderes até 3, separados por " · " (ex.: "Acidity · Fruit · Body");
  - 4 a 7 eixos empatados num topo que não é alto: "Quiet on most axes" (baixo) ou "In the middle on most axes" (neutro);
  - 4 a 6 eixos empatados num topo alto: "Everything but [os restantes]" quando sobram 1 ou 2; senão, os eixos empatados separados por " · ".
- **Legenda** (sempre seguida de "The shape of what you reach for in a glass."):
  - plano: "Quiet on all eight axes." / "In the middle on all eight axes." / "High on all eight axes.";
  - sete e um abaixo: "Even on seven axes, quietest on [eixo].";
  - sete e um acima: "[abertura], even on the other seven.";
  - com forma: "[abertura], quietest on [patamar de baixo]." Um patamar de baixo com mais de 3 eixos vira "several axes at once".
  - A abertura depende do tom do topo (2026-11-01): "Strongest on [patamar do topo]" só para um topo alto (com mais de 3 eixos, "Strongest on several axes at once"). Um topo baixo ou neutro com até 3 eixos fica "Leaning most toward [patamar do topo]"; com mais de 3, fica "Quiet on most axes" ou "In the middle on most axes".
- **Narrativa:** o que diz o topo e depois o que diz a base (tabelas no Anexo A).
  - Plano: só o texto do mapa plano do seu tom.
  - Topo: se o topo não é alto, "nada alto". Se 3 ou mais eixos empatam no topo, "a maior parte alta". Senão, o texto "alto" de cada líder (até 2) que seja alto.
  - Base: se a base não é baixa, "nada baixo". Se 3 ou mais eixos empatam na base, "a maior parte baixa". Senão, o texto "baixo" de cada eixo da base (1 ou 2).
  - Um texto "alto" nunca sai para um eixo que não é alto, nem um "baixo" para um eixo que não é baixo.

**QUIZ-R16 · Leituras.** Lista os 8 eixos na ordem do gráfico, cada um com a palavra do nível (QUIZ-R05) e 10 pips. Os líderes até 3 (QUIZ-R14a) aparecem em destaque; no gráfico, os líderes até 2. Mapa plano: nenhum destaque. O título "Where the map points" tem um botão de info (ⓘ) ao lado; tocar no título ou no botão abre uma folha, "How your map is drawn", igual à de You › Map (YOU-R11: todo o texto em Red Grapes, título de 34 pt, folha da altura do texto; 2026-11-23), que explica que o mapa vem das respostas lidas em termos de vinho e assentadas entre vinhos reais: "Your answers were the starting point. We read them in wine terms and settled them among real wines, so your map points to bottles that exist. What you lean toward stays: love floral, and your map leans to the more floral wines."

**QUIZ-R17 · O mapa se move.** O resultado mostra "This map keeps moving": o mapa é recalculado a cada avaliação de vinho (QUIZ-R22).

**QUIZ-R18 · Ações.**
- "Keep this map" guarda o mapa e abre a folha de partilha (3.4). A partir daí o usuário "tem mapa" (SHARED-R13), mesmo que feche a app na folha de partilha.
- "Read it again" descarta as respostas, sem guardar nada, e volta à Leitura 1 com todas as barras vazias.

**QUIZ-R18a · Refazer o Quiz.** O usuário pode refazer o Quiz depois de ter um mapa (entrada "refazer", QUIZ-R24). Ao tocar em "Keep this map", o mapa novo substitui o atual por completo: o histórico do mapa recomeça com o resultado do Quiz. As notas e os vereditos guardados no Cellar continuam disponíveis, e só novas avaliações contam para o mapa. No fim, o usuário volta a You › Map, sem passar pelo tour (QUIZ-R25, HOME-R29).

**Critérios**
- Dado o mapa { Sweetness 1, Acidity 4, Tannin 3, Body 3, Fruit 4, Floral 2, Oak 2, Spice 3 }, então:
  - o ranking é Acidity 4, Fruit 4, Body 3, Tannin 3, Spice 3, Floral 2, Oak 2, Sweetness 1 (os empates seguem a ordem canônica);
  - os líderes até 3 são Acidity e Fruit (Body, Tannin e Spice empatam e não cabem);
  - a frase dominante é "Acidity · Fruit";
  - a legenda começa por "Leaning most toward acidity and fruit, quietest on sweetness." (o topo, 4, é baixo);
  - a narrativa não tem texto "alto", porque o topo (4) é baixo.
- Dado o mapa { Acidity 8, Fruit 7, Body 6, Tannin 5, Spice 4, Floral 3, Oak 2, Sweetness 1 }, então a frase dominante é "Acidity · Fruit · Body" e a narrativa é o texto "alto" de Acidity, o de Fruit e o texto "baixo" de Sweetness.
- Dados todos os eixos em 3, então a frase é "Quiet on every axis", a legenda começa por "Quiet on all eight axes." e nada aparece em destaque.
- Dados todos os eixos em 5, então o mapa é plano neutro: "In the middle on every axis".
- Dados todos os eixos em 7, então a frase é "High on every axis" e a narrativa não tem texto "baixo".
- Dados sete eixos em 7 e Oak em 2, então a frase é "Everything but oak", a legenda começa por "Even on seven axes, quietest on oak." e a narrativa é "a maior parte alta" e o texto "baixo" de Oak.
- Dados sete eixos em 2 e Acidity em 7, então a frase é "Acidity", a legenda começa por "Strongest on acidity, even on the other seven.", a narrativa é o texto "alto" de Acidity e "a maior parte baixa", e só Acidity aparece em destaque.
- Dados seis eixos em 3, Spice em 2 e Fruit em 0, então a frase é "Quiet on most axes" e a legenda começa por "Quiet on most axes, quietest on fruit.", nunca "Strongest on".
- Dados seis eixos em 8, Spice em 2 e Fruit em 0, então a frase é "Everything but spice and fruit" e a legenda começa por "Strongest on several axes at once, quietest on fruit."
- Dados sete eixos em 3 e Oak em 1, então a frase é "Quiet on most axes", não "Everything but oak".
- Dados sete eixos em 2 e Acidity em 4, então a legenda começa por "Leaning most toward acidity, even on the other seven."
- Dados Acidity 7.2, Fruit 6.8 e o resto em 3, então Acidity e Fruit estão empatados (nível 7) e a frase é "Acidity · Fruit".
- Quando o usuário toca em "Read it again", então nenhum mapa é guardado e a Leitura 1 abre vazia.
- Quando o usuário toca em "Keep this map", então o mapa é guardado e `hasMap` passa a ser verdadeiro.
- Dado um mapa atual com Acidity 6.4 (depois de várias avaliações), quando o usuário refaz o Quiz, escolhe a posição 3 em Acidity e toca em "Keep this map", então Acidity vale 3.
- Dado o Quiz refeito, quando o mapa novo é guardado, então o histórico de avaliações continua com o mesmo número de registros.

### 3.4 Partilhar o mapa

A folha abre sempre depois de "Keep this map" (QUIZ-R18). Partilhar é opcional. Depois de partilhar ou guardar, o usuário volta à folha; só "Not now" leva à saída do Quiz (QUIZ-R25).

**QUIZ-R19 · Conteúdo.** Um cartão com "[primeiro nome] taste in wine is", a frase dominante, o radar e duas linhas:
- **Loves:** "[nome] drinks for […]." ("Drinks for […]." sem nome), em que […] é:
  - com líderes: "[líder1], [líder2] and [líder3], in that order", com os líderes até 3; "in that order" só quando os líderes têm níveis diferentes. Um líder só: "[eixo] above all";
  - plano: "restraint, every axis kept low" / "balance, every axis in the middle" / "everything at once, every axis turned up";
  - sete e um abaixo, com o topo alto: "everything but [eixo]";
  - 4 a 7 empatados no topo: "many things at once" (topo alto), "restraint, most axes kept low" (baixo) ou "balance, most axes in the middle" (neutro).
- **Never:**
  - base baixa com 1 ou 2 eixos: "Pour something built on [base] and the glass comes back. Politely.";
  - plano baixo, ou 3 ou mais eixos empatados numa base baixa: "Pour something loud and the glass comes back. Politely.";
  - base que não é baixa: "Pour almost anything: nothing on this map sends a glass back."

**QUIZ-R20 · Formatos.** Como em toda partilha da app (SHARED-R20): Story ("Share to Instagram"), WhatsApp ("Send on WhatsApp") e "Save image", que guarda nas fotos. "Not now" fecha. Não existe formato Link.

**QUIZ-R20a · Linguagem neutra.** Nenhum texto do Quiz ou da partilha usa pronome ou marca de gênero do usuário.

O canvas ainda mostra o formato Link e a linha Never antiga ("Pour her something built on […] and she will hand the glass back"). Valem as regras QUIZ-R19 a R20a.

**Critérios**
- Dado o mais fraco Sweetness, então a linha Never é "Pour something built on sweetness and the glass comes back. Politely."
- Dado qualquer mapa, então nenhum texto gerado contém "her", "she", "his", "he" ou "him" como palavra.

## 4. Funções usadas por outras features

### 4.1 Similaridade (SHARED-R07)

**QUIZ-R21 · Similaridade.** Cada vinho tem um perfil nos mesmos 8 eixos, na mesma régua do mapa (QUIZ-R04a). A similaridade mede a distância entre o vinho e o mapa nos 8 eixos, todos com o mesmo peso, e vai de 0 a 1:

```
distância    = √ Σ (mapa[eixo] − vinho[eixo])²
similaridade = max(0, 1 − distância / 13)
```

13 é a distância de um vinho "nada parecido": cerca de 4,6 pontos em cada eixo. É uma reta, sem topo plano: distância 1 → 92%, 2 → 85%, 3 → 77%, 4 → 69%, 5 → 62%. 100% só para um vinho igual ao mapa. Para ordenar vinhos e receitas usa-se a distância, não a percentagem. Vale também para a compatibilidade entre amigos (FRI).

Histórico: 1 − distância/12 com as respostas lidas à letra deixava o melhor vinho em ~60% (2026-11-01). 1 − (distância/8)² (2026-11-15) foi pensada para mapas longe dos vinhos; com o mapa já assentado entre vinhos reais (QUIZ-R04b), o topo plano punha o Hero e os cards em 91–99% e 10% do catálogo em 0%.

Simulação com a seed (mapas do Quiz, respostas ao acaso; medianas por usuário): melhor vinho 87% (entre 78% e 93%), 5.º 85%, 20.º 81%, vinho do meio do catálogo 51%, 90.º percentil 29%.

**Critérios**
- Dado um vinho com perfil igual ao mapa, então a similaridade é 1.
- Dado um mapa todo 3 e um vinho todo 4, então o match é 78%.
- Dado um mapa todo 3 e um vinho todo 5, então o match é 56%.
- Dado um vinho a 1 ponto em 2 eixos, então o match é 89%.
- Dado um vinho a 1, 2, 3, 4 e 5 pontos num só eixo, então o match é 92%, 85%, 77%, 69% e 62%.
- Dado um mapa todo 1 e um vinho todo 6 (mais de 13), então a similaridade é 0, nunca negativa.
- Dados dois vinhos, o mais próximo do mapa tem a maior similaridade.
- Dados dois vinhos que diferem do mapa pela mesma quantidade, um só em Acidity e outro só em Oak, então os dois têm a mesma similaridade.

### 4.2 Atualização depois de uma avaliação (SHARED-R09)

**QUIZ-R22 · Atualização.** Para cada eixo:

```
novo = clamp(atual + peso × (vinho[eixo] − atual), 0, 9)
```

| Veredito | Peso | Efeito |
| --- | --- | --- |
| Yes | +0.10 | aproxima 10% da diferença |
| Maybe | +0.03 | aproxima 3% da diferença |
| No | −0.10 | afasta 10% da diferença |

Os pesos são constantes num único lugar (`RatingWeights`), para que possam ser ajustados sem reescrever os testes de comportamento.

**QUIZ-R23 · Variação.** A atualização devolve, para cada eixo, o valor antes e depois. Um eixo "subiu" ou "desceu" quando a variação absoluta é ≥ 0.05 (o card da HOME-R16 usa isto).

**Critérios**
- Dados Acidity 2 no mapa e 8 no vinho, com Yes, então Acidity passa a 2.6.
- Dados Acidity 2 no mapa e 8 no vinho, com Maybe, então Acidity passa a 2.18.
- Dados Acidity 2 no mapa e 8 no vinho, com No, então Acidity passa a 1.4.
- Dado um eixo em 9 e uma avaliação No de um vinho com 0 nesse eixo, então o eixo passaria a 9.9 e fica em 9.
- Dado um eixo em 0 e uma avaliação No que o empurraria abaixo de 0, então ele fica em 0.
- Dado um vinho com perfil igual ao mapa, com qualquer veredito, então nenhum eixo muda e não há eixo que subiu ou desceu.

---

## 5. Fora de escopo

- O cadastro (Welcome, login com Apple ou Google, nome, telefone, encontrar amigos): ver `ONBOARDING.md`.
- O tour guiado que aparece depois do primeiro mapa: ver `HOME.md` (HOME-R29 a R33).
- O vinho e o prato sugeridos a partir do mapa. Eles não fazem parte do resultado do Quiz: são calculados e apresentados na primeira abertura da Home em cada dia (HOME-R06, HOME-R07). As garrafas e pratos fixos por eixo do protótipo não são usados.
- Como o perfil de cada vinho é calculado ("grape, how it was made, time in oak, residual sugar and region"): é um dado do catálogo.
- A evolução do mapa no tempo (You › Map › Over time): ver `YOU.md`.

## 6. Decisões

| # | Pergunta | Decisão (2026-10-27) | Regra |
| --- | --- | --- | --- |
| D1 | Precisão da escala | As respostas são o ponto de partida: lidas numa régua fixa comum a usuários e vinhos, assentadas entre vinhos reais e mantidas a ±1,5 da resposta; a app mostra a posição na régua (2026-11-15) | QUIZ-R04, R04a–c, R05 |
| D2 | Posição inicial | A barra começa vazia | QUIZ-R10 |
| D3 | Similaridade | Distância entre vinho e mapa nos 8 eixos, mesmo peso | QUIZ-R21 |
| D4 | Pesos da avaliação | Yes 10%, Maybe 3%, No −10% | QUIZ-R22 |
| D5 | Refazer o Quiz | Pode; o mapa novo substitui o atual por completo | QUIZ-R18a |
| D6 | Texto do Never | Neutro: "Pour something built on […] and the glass comes back. Politely." | QUIZ-R19, R20a |
| D7 | Sair no meio | Recomeça do início | QUIZ-R13a |
| D8 | Vinho e prato por eixo | Calculados na primeira abertura do dia, na Home | Fora de escopo, HOME-R07 |
| D9 | Empates e mapas planos | Eixos com o mesmo nível exibido empatam; nenhum texto desempata pela ordem canônica; 5 é neutro (2026-11-01) | QUIZ-R14a, R15 |
| D10 | Escala do match | 1 − distância / 13, reta, com mínimo de 0%; substitui 1 − (distância/8)², que com mapas assentados entre vinhos dava 91–99% aos próximos e 0% a 10% do catálogo (2026-11-15) | QUIZ-R21 |

## 7. Dúvidas em aberto

- [x] Onde fica o botão para refazer o Quiz: em You › Map › "Redo the map" (YOU-R13).
- [ ] **D9 · Intro ao refazer.** Na entrada "refazer", a Intro é a mesma ("Welcome, [nome]" e os três passos), ou uma versão curta que vai direto às leituras?
- [ ] **D10 · Como sair ao refazer.** O canvas não tem botão de fechar na Intro nem nas leituras. Na entrada "refazer", onde fica a saída (um ✕ no topo, o "Back" da Intro)? Pede confirmação se já houver respostas?
- [ ] **D11 · Partilha ao refazer.** Na entrada "refazer", a folha de partilha também abre depois de "Keep this map", ou o Quiz volta direto a You › Map?

---

## Anexo A · Textos por eixo

| Eixo | Alto | Baixo |
| --- | --- | --- |
| Sweetness | a little residual sugar reads as generosity to you, not as a flaw | sugar reads as a flaw to you, and dry means dry |
| Acidity | acidity is the first thing you notice, and it is what keeps a wine awake for you | sharpness tires you out; you want a rounder line through the middle |
| Tannin | you want grip, the drying pull that holds a red upright | tannin gets in the way for you; you want fruit without the scaffolding |
| Body | you want weight in the glass, something that coats and stays | you want a wine that stays light and gets out of the way |
| Fruit | ripe fruit is the point for you, not a beginner's phase to grow out of | you look past fruit for earth, salt and stone |
| Floral | perfume pulls you in before structure ever does | floral aromatics read as soap to you |
| Oak | vanilla, smoke and toast are part of the pleasure, not a cover-up | you want the grape, not the barrel |
| Spice | pepper and clove are what you go looking for | spice distracts you from the fruit |

Textos de mapa sem um topo ou uma base únicos (QUIZ-R14a, R15):

| Caso | Texto |
| --- | --- |
| Plano baixo | every axis sits low on your map: you want a quiet wine, one that whispers instead of making a point |
| Plano neutro | every axis sits in the middle: you want balance, a wine where nothing is too much or too little |
| Plano alto | every axis runs high on your map: you want a wine that does a lot at once, with nothing held back |
| A maior parte alta | most of the map runs high: you want a wine that does a lot at once, with no single axis in charge |
| A maior parte baixa | most of the map stays quiet: you want restraint more than power |
| Nada alto | nothing on the map climbs high, so no single part of a wine has to lead |
| Nada baixo | nothing on the map is truly low: you leave room for every part of a wine |

## Anexo B · Perguntas

Versão 1 de cada eixo (as versões 2 e 3 e as 10 respostas de cada uma estão no canvas, Quiz › `QUESTIONS`):

| Eixo | Pergunta (versão 1) |
| --- | --- |
| Sweetness | How much sugar do you take in your coffee? |
| Acidity | How much lemon do you squeeze over your food? |
| Tannin | How strong do you like your black tea? |
| Body | How much cream do you like in your coffee? |
| Fruit | How much fruit do you eat in a day? |
| Floral | How much do you like floral flavours, like rose or elderflower? |
| Oak | How much smoky, toasted flavour do you like? |
| Spice | How much black pepper do you add to your food? |
