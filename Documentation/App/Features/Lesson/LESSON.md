# UVVA · Lessons

> Status: rascunho v0.2 · 2026-10-30
> Depende de: [`../Learn/LEARN.md`](../Learn/LEARN.md) (player, progresso, XP e certificados)
> Visual: UVVA Telas (artboard Lessons) e UVVA Design System. Links no `UVVA.MD`.

## 1. Objetivo

Este documento define **como as lições são escritas**: a estrutura de um módulo e de uma lição, as 6 etapas de cada lição, as regras de cada tipo de passo, o XP, a quantidade de lições por módulo e o tom dos textos.

O comportamento do player (Check, feedback, retomar, Summary, certificado) está no [`LEARN.md`](../Learn/LEARN.md), secção 4. Este documento não o repete.

**LESSON-R00 · Protótipo.** O conteúdo das lições, módulos, castas e regiões que aparece nos artefatos de design serve só para visualizar a interface e **não é válido**. O conteúdo vem só destes documentos.

## 2. Hierarquia

```
Aba Learn
└── Tab (The path · By grape · By region)
    └── Módulo (30 · 50 · 50)
        └── Lição (quantidade pela complexidade, a última é a revisão)
            └── 6 etapas
```

| Tab | Arquivo | Módulos | Critério de escolha |
| --- | --- | --- | --- |
| The path | [`PATH.MD`](PATH.MD) | 30 | Os programas do WSET, do Level 1 ao Level 4 Diploma |
| By grape | [`GRAPE.MD`](GRAPE.MD) | 50 | Relevância da casta na comunidade do vinho, da enologia e da gastronomia |
| By region | [`REGION.MD`](REGION.MD) | 50 | As regiões mais importantes e relevantes do mundo do vinho, em 15 países |

## 3. Módulos

**LESSON-R01 · Três tipos de módulo.** Todo módulo tem um `kind`: `path`, `grape` ou `region`. Os três seguem as mesmas regras de lição, XP, progresso e certificado. No `LEARN.md` eles são chamados de "curso" (LEARN-R01).

**LESSON-R02 · Identificadores.**

| Tipo | `moduleId` | Exemplo de lição |
| --- | --- | --- |
| path | `path-<NN>` | `path-01-l03` |
| grape | `grape-<slug>` | `grape-pinot-noir-l02` |
| region | `region-<país ISO>-<slug>` | `region-pt-douro-l04` |

**LESSON-R03 · Quantidade de lições pela complexidade.** Assuntos mais complexos têm mais lições. Cada módulo tem uma complexidade de A a D, que define o número de lições:

| Complexidade | The path | By grape | By region |
| --- | --- | --- | --- |
| A · Alta | 8 | 7 | 7 |
| B · Média | 7 | 6 | 6 |
| C · Moderada | 6 | 5 | 5 |
| D · Base | 5 | 4 | 4 |

O número inclui a lição de revisão.

**LESSON-R03a · Pontuação de castas e regiões.** Em By grape e By region, a complexidade não é escolhida à mão: ela sai de uma pontuação. Cada módulo recebe 0, 1 ou 2 pontos em quatro critérios, e a soma (0 a 8) dá a complexidade.

| Soma | Complexidade |
| --- | --- |
| 7 ou 8 | A |
| 5 ou 6 | B |
| 3 ou 4 | C |
| 0 a 2 | D |

**Critérios de uma casta**

| Critério | 0 | 1 | 2 |
| --- | --- | --- | --- |
| **E · Estilos** | Um estilo | Dois ou três estilos | Muitos estilos (seco a doce, espumante, fortificado, rosé) |
| **G · Geografia** | Uma região de referência | Duas ou três regiões de referência | Quatro ou mais, ou expressões distintas em vários continentes |
| **R · Referência** | Nenhum vinho de referência mundial | Um vinho ou denominação de referência | Vários vinhos icónicos ou classificações |
| **T · Técnica** | Nada de específico a explicar | Um ponto técnico próprio (sinónimo, cruzamento, um método) | Vários (química do aroma, viticultura difícil, métodos ou envelhecimento próprios) |

**Critérios de uma região**

| Critério | 0 | 1 | 2 |
| --- | --- | --- | --- |
| **S · Sub-regiões** | Uma área sem divisões relevantes | Algumas sub-regiões ou denominações | Muitas, com hierarquia entre elas |
| **C · Classificação** | Sem sistema próprio | Um sistema próprio simples | Um sistema próprio que precisa de lição (crus, Prädikat, envelhecimento, puttonyos) |
| **E · Estilos** | Um estilo | Dois ou três estilos | Muitos estilos (tinto, branco, doce, espumante, fortificado) |
| **H · Peso** | Relevância local | Relevância internacional | Referência mundial, histórica ou de mercado |

A pontuação de cada módulo aparece na coluna "Pontos" de `GRAPE.MD` e `REGION.MD`, no formato `E G R T = soma` ou `S C E H = soma`.

**LESSON-R03b · Complexidade em The path.** Em The path, a complexidade segue a extensão do programa de referência (WSET) para aquele tema: quantos tópicos o programa pede e com que profundidade.

**LESSON-R04 · Revisão no fim.** **Todo módulo termina com uma lição de revisão** (`isReview: true`), com o título "Module review". Ela revê o módulo inteiro (LESSON-R10).

**LESSON-R05 · Esqueleto dos módulos de casta e de região.** As lições seguem uma ordem fixa. Os "temas próprios" listados em `GRAPE.MD` e `REGION.MD` são as lições do meio, e o seu número é sempre `lições − 4`.

| Posição | By grape | By region |
| --- | --- | --- |
| 1 | **Meet [casta]**: origem, família, como reconhecê-la no copo | **The place**: geografia, clima, solo, história |
| 2 | **Where it grows**: o clima que pede, a vinha, as regiões onde brilha | **The grapes**: castas principais e o que cada uma dá |
| Meio | Temas próprios (0 a 3) | Temas próprios (0 a 3) |
| Penúltima | **At the table**: estilos, serviço, envelhecimento, comida e garrafas de referência | **Labels and the table**: como ler o rótulo da região, estilos, comida |
| Última | **Module review** | **Module review** |

Os módulos de The path não têm esqueleto fixo. Os títulos das lições estão em `PATH.MD`.

## 4. XP e duração

**LESSON-R06 · XP.** **Toda lição vale 15 XP**, incluindo a revisão. O XP de um módulo é `15 × número de lições`, sem bónus.

**Critérios**
- Dado um módulo de 6 lições, então ele vale 90 XP.
- Dada uma lição de revisão, então ela vale 15 XP.

**LESSON-R07 · Duração.** `estimatedMinutes` é 3 em todas as lições.

## 5. A lição: 6 etapas

**LESSON-R08 · Campos.** `title`, `subtitle`, `xp`, `estimatedMinutes`, `objectives`, `steps` e `isReview`.
- **title:** curto, até 5 palavras, com maiúscula só na primeira palavra e nos nomes próprios ("From grape to glass").
- **subtitle:** uma frase que diz o ângulo da lição ("Where the colour comes from").
- **objectives:** exatamente 3. Cada um completa a frase "By the end you can" e começa com verbo ("Explain why…", "Recognise…", "Read…").

A capa da lição ("By the end you can") não conta como etapa.

**LESSON-R09 · As 6 etapas.** Toda lição tem **exatamente 6 etapas**, sempre nesta ordem:

| Etapa | Tipo de passo | Função |
| --- | --- | --- |
| 1 | `concept` | **O quê.** Apresenta a ideia central da lição. |
| 2 | `concept` | **Porquê.** Explica o mecanismo por trás da ideia, com pelo menos um dado concreto. |
| 3 | Pergunta | Verifica as etapas 1 e 2. |
| 4 | `concept` ou `tip` | **Na prática.** Leva a ideia para o copo, o rótulo, a vinha ou a mesa. |
| 5 | Pergunta | Verifica a etapa 4 ou junta tudo o que a lição ensinou. |
| 6 | `summary` | Fecha a lição com 3 pontos que correspondem aos objetivos. |

- As perguntas das etapas 3 e 5 são de tipos diferentes.
- Toda pergunta avalia algo que já foi ensinado na lição ou numa lição anterior do mesmo módulo. Não há pegadinhas.
- No máximo 1 `tip` por lição, e só na etapa 4.

**LESSON-R10 · As 6 etapas da revisão.** A lição de revisão troca os conceitos por perguntas:

| Etapa | Tipo de passo | Função |
| --- | --- | --- |
| 1 a 5 | Pergunta | Cada pergunta cobre lições diferentes do módulo. Juntas, as 5 cobrem todas as ideias principais. Pelo menos 3 tipos diferentes. |
| 6 | `summary` | 3 a 4 pontos com o essencial do módulo inteiro. |

**Critérios**
- Dada uma lição normal, então ela tem 6 passos: `concept`, `concept`, pergunta, `concept` ou `tip`, pergunta, `summary`.
- Dada uma lição de revisão, então os passos 1 a 5 são perguntas e o 6 é o `summary`.
- Dado um módulo, então a sua última lição tem `isReview: true`.

## 6. Regras por tipo de passo

| Tipo | Campos | Regras de escrita |
| --- | --- | --- |
| `concept` | `title`, `body`, `highlight?` | `body` até ~80 palavras. `highlight` ("Key idea") até ~12 palavras, uma fórmula ou ideia que se possa lembrar. Um conceito por passo. |
| `tip` | `body` | "Uvva tip". Um atalho prático, um erro comum ou uma ligação com o dia a dia. Nunca conteúdo essencial para as perguntas. |
| `multipleChoice` | `prompt`, `options`, `answer`, `explanation` | 4 opções, uma certa. As erradas são plausíveis, nunca absurdas. |
| `trueFalse` | `prompt`, `answer`, `explanation` | Uma afirmação só, sem "always/never" que tornem óbvia a resposta. |
| `fillBlank` | `prompt`, `options`, `answer`, `explanation` | Um único `____` no `prompt`. 4 opções, todas da mesma categoria gramatical. |
| `selectMultiple` | `prompt`, `options`, `answers`, `explanation` | 4 a 5 opções, 2 ou 3 certas. |
| `ordering` | `prompt`, `items`, `explanation` | 4 a 6 itens, guardados **na ordem certa** (o player embaralha, LEARN-R17b). Só para sequências reais (processo, escala, tempo). |
| `matchPairs` | `prompt`, `pairs`, `explanation?` | 4 a 5 pares. Lado direito curto (até 5 palavras). |
| `summary` | `title`, `points` | Ver LESSON-R09 e LESSON-R10. |

**LESSON-R11 · Explicação.** Toda pergunta tem `explanation` (em `matchPairs` é opcional). A explicação diz por que a resposta certa está certa e por que a errada mais tentadora está errada. Ela é lida por quem acertou e por quem errou, por isso nunca começa com "Correct" nem com "Wrong".

## 7. Tom e voz

**LESSON-R12 · Língua.** As lições são escritas em **inglês britânico** (colour, recognise, flavour), como a interface.

**LESSON-R13 · Voz.** Informal e próxima, falando com o usuário por "you", como uma conversa com alguém que entende muito de vinho e gosta de explicar. Ao mesmo tempo, séria: é um curso com conteúdo de valor, não um passatempo.
- Contrações são bem-vindas (you'll, it's, don't).
- Frases curtas e diretas. Um parágrafo, uma ideia.
- Nada de entusiasmo vazio: sem "Great job", "Let's dive in", "Amazing", "Fun fact".

**LESSON-R14 · Profundidade.** As lições não ficam na superfície. Com só 6 etapas, cada frase tem de ensinar alguma coisa.
- Explicam o **porquê**, o mecanismo por trás do facto (por que a casca dá cor, por que a altitude preserva a acidez).
- Usam **números concretos**: percentagens de álcool, gramas de açúcar, altitudes, datas, tempos mínimos de estágio.
- Usam **nomes reais**: lugares, leis, denominações, castas. Produtores só quando fazem parte da história (por exemplo, o Julgamento de Paris), nunca como recomendação comercial.
- Distinguem o que é **regra legal**, o que é **costume** e o que é **opinião**.
- Não simplificam a ponto de ficar errado. Se uma regra tem uma exceção importante, a exceção aparece.
- Não supõem conhecimento que o módulo, ou os módulos de base de The path, ainda não deram.

**LESSON-R15 · Proibido nos textos.**
- **Emojis**, em qualquer campo.
- **Travessões** (— e –). Usar ponto, vírgula, dois pontos ou parênteses. O hífen em palavras compostas é permitido (late-ripening, off-dry).
- **Intervalos com traço.** Escrever "11 to 14.5%", não "11–14.5%".
- **Pontos de exclamação** (regra de voz do app, ver `UVVA.MD`).
- Jargão sem explicação na primeira vez que aparece.
- A marca **WSET** e os nomes dos seus cursos. O WSET é a referência para montar o curriculum, mas o UVVA não é um curso certificado pelo WSET.

**Exemplo**

| Evitar | Preferir |
| --- | --- |
| False! The colour is in the skin — not the pulp. | Not true. The colour is in the skin, not the pulp, so black grapes pressed gently give a white juice. Champagne does exactly that with Pinot Noir. |
| Most still wines sit between 11–14.5% alcohol. | Most still wines sit between 11 and 14.5% alcohol. |

## 8. O que as lições não têm

**LESSON-R16 · Sem glossário.** As lições não têm termos tocáveis nem folha de glossário. O glossário é acessado por um card na Home. Termos novos são explicados no próprio texto da lição.

**LESSON-R17 · Visual.** Este documento não define o visual das lições. O fundo, as imagens, as cores, a tipografia e os componentes vêm do design: consultar o artboard Lessons em *UVVA Telas* e o *UVVA Design System*.

## 9. Formato de dados

Cada módulo é um arquivo JSON. Exemplo resumido:

```json
{
  "id": "grape-pinot-noir",
  "kind": "grape",
  "title": "Pinot Noir",
  "description": "Thin skin, high acid and a talent for showing where it was grown.",
  "lessons": [
    {
      "id": "grape-pinot-noir-l01",
      "order": 1,
      "title": "Meet Pinot Noir",
      "subtitle": "Why the palest red is the hardest to grow",
      "xp": 15,
      "estimatedMinutes": 3,
      "isReview": false,
      "objectives": ["Explain why Pinot Noir is pale", "Recognise its typical aromas", "Name its home region"],
      "steps": [
        { "type": "concept", "title": "…", "body": "…", "highlight": "…" },
        { "type": "concept", "title": "…", "body": "…" },
        { "type": "multipleChoice", "prompt": "…", "options": ["…", "…", "…", "…"], "answer": 2, "explanation": "…" },
        { "type": "tip", "body": "…" },
        { "type": "trueFalse", "prompt": "…", "answer": false, "explanation": "…" },
        { "type": "summary", "title": "What you learned", "points": ["…", "…", "…"] }
      ]
    }
  ]
}
```

## 10. Checklist de revisão de uma lição

- [ ] 15 XP, 3 min, 3 objetivos.
- [ ] Exatamente 6 etapas, na ordem de LESSON-R09 (ou de LESSON-R10, se for revisão).
- [ ] Perguntas de tipos diferentes, todas com explicação, todas sobre algo já ensinado.
- [ ] Nenhum emoji, travessão, intervalo com traço, ponto de exclamação ou menção ao WSET.
- [ ] Inglês britânico, "you", frases curtas.
- [ ] A etapa 2 explica um porquê e traz pelo menos um dado concreto.
- [ ] Factos verificados (datas, números, leis).
- [ ] O Summary corresponde aos objetivos.
- [ ] O módulo termina com a revisão.
