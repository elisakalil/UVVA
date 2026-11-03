# UVVA · Learn

> Status: rascunho v0.3 · 2026-10-31 · sem envio de certificados por e-mail
> Depende de: [`_shared.md`](_shared.md)
> Fonte: canvas UVVA App, artboards Learn, Lessons e Glossário.

## 1. Objetivo

A aba Learn é onde o usuário aprende sobre vinho. Há três percursos (por região, por casta e o curriculum de 30 módulos), todos feitos de lições curtas. As lições alternam conceitos e perguntas, dão XP e, ao fim de um curso ou módulo, geram um certificado para partilhar.

Esta feature inclui o **player de lições** (artboard Lessons), que a Home e o You também abrem.

Pela SHARED-R01, não há limite diário de lições nem cursos pagos. As telas Lesson limit, "Buy the course · €9" e "Go Premium" estão fora de escopo.

## 2. Modelo

```swift
struct Course   { id; kind: .module | .region | .grape; title; lessons: [Lesson] }
struct Lesson   { id; courseId; order; title; subtitle; xp; estimatedMinutes; objectives: [String]; steps: [Step]; isReview }
enum   Step     { concept, tip, multipleChoice, selectMultiple, trueFalse, fillBlank, matchPairs, ordering, summary }
struct LessonProgress { lessonId; currentStep; completedAt?; lastOpenedAt; answers }
```

**LEARN-R01 · Módulos e cursos.** "Módulo" é uma unidade do curriculum (The path). "Curso" é uma unidade de região ou de casta. Os dois seguem as mesmas regras de progresso, XP e certificado. Daqui em diante, "curso" vale para os dois.

**LEARN-R02 · Estado de um curso.** O estado é derivado do progresso das suas lições, nunca guardado à parte:

| Estado | Condição |
| --- | --- |
| Not started | Nenhuma lição iniciada |
| In progress | Pelo menos uma lição iniciada e nem todas concluídas (SHARED-R16) |
| Done | Todas as lições concluídas (SHARED-R15) |

**Critérios**
- Dado um curso com 5 lições e nenhuma aberta, então o estado é Not started.
- Dado um curso com a lição 1 aberta no passo 2, então o estado é In progress.
- Dadas 5 de 5 lições concluídas, então o estado é Done.

## 3. A aba Learn

**LEARN-R03 · Percursos.** Três tabs no topo: By region, By grape e The path. A aba Learn abre sempre em By region. Trocar de tab não sai do ecrã.

**LEARN-R04 · Entrada pela Home.** A Home pode abrir a aba já numa tab: "A region" abre By region, "A grape" abre By grape e "A lesson" abre The path (HOME-R18).

### 3.1 By region

**LEARN-R05 · Países.** By region tem **15 países e 50 regiões**. Cada região é um curso. Os países, as regiões e as lições estão em [`../Lesson/REGION.MD`](../Lesson/REGION.MD).

**LEARN-R06 · Escolha.** Escolher um país abre a sua primeira região. Tocar numa região, no mapa ou na lista, abre essa região. Só uma região fica aberta de cada vez.

**LEARN-R07 · Região aberta.** Mostra a descrição, as castas da região e as lições do curso. O botão abre a lição certa (LEARN-R11).

**Critérios**
- Dada a lista de países, então ela tem 15 países.
- Dado um país escolhido, então abre a primeira região desse país.
- Dada uma região A aberta, quando o usuário toca na região B, então B abre e A fecha.

### 3.2 By grape

**LEARN-R08a · Castas.** By grape tem **50 castas**, cada uma um curso. As castas e as lições estão em [`../Lesson/GRAPE.MD`](../Lesson/GRAPE.MD).

**LEARN-R08 · Filtros.** All, Red, White e um filtro por país. A ordem da lista é: tintos do mais escuro ao mais claro, depois brancos do mais profundo ao mais claro.

**LEARN-R09 · Casta aberta.** Tocar numa casta abre a descrição e as lições do curso. Só uma casta fica aberta de cada vez.

**Critérios**
- Dada a lista de castas, então ela tem 50 castas.
- Dado o filtro Red, então só aparecem tintos, na ordem definida.
- Dado o filtro de um país, então só aparecem castas desse país.

### 3.3 The path (curriculum)

**LEARN-R10 · Estrutura.** The path tem **30 módulos** agrupados em 4 níveis (Essentials, Intermediate, Advanced e Expert), com filtro por nível. Os módulos, os níveis e as lições estão em [`../Lesson/PATH.MD`](../Lesson/PATH.MD).

**LEARN-R10a · Linha do módulo.** Cada módulo mostra "[N] lessons · [soma dos minutos] min · [XP] XP" (LEARN-R20) e o estado (LEARN-R02). O módulo In progress tem um ponto a pulsar.

**LEARN-R10b · Acesso.** Todos os módulos estão abertos, em qualquer ordem. Não existe estado "locked" (ver D1).

**Critérios**
- Dada a lista do The path, então ela tem 30 módulos.
- Dado um módulo de exemplo com 6 lições de 5, 5, 5, 5, 5 e 6 min, então a linha mostra "6 lessons · 31 min · 90 XP".
- Dado o módulo 1 não iniciado, então o módulo 20 também pode ser aberto.

### 3.4 Botão de um curso

**LEARN-R11 · Rótulo e destino.**

| Estado | Botão | Abre |
| --- | --- | --- |
| Not started | Go to the module | Lição 1, passo 1 |
| In progress | Continue where you left off | A primeira lição não concluída, no passo guardado (SHARED-R17) |
| Done | Review the module | Lição 1, passo 1, em modo revisão (LEARN-R19) |

**Critérios**
- Dadas as lições 1 e 2 concluídas e a 3 parada no passo 4, então o botão diz "Continue where you left off" e abre a lição 3 no passo 4.
- Dado um curso Done, então o botão diz "Review the module".

## 4. Player de lições

### 4.1 Abertura da lição

**LEARN-R12 · Capa.** Mostra o número e o título da lição, os minutos, o XP, o número de passos e "By the end you can", com os objetivos. Da lição 2 em diante, tem também "Review previous lesson", que abre a lição anterior.

**LEARN-R13 · Progresso.** O topo mostra um segmento por passo; os passos até o atual ficam preenchidos.

**LEARN-R14 · Sair e retomar.** Sair da lição a qualquer momento guarda o passo atual e as respostas dadas. Ao voltar, a lição abre nesse passo.

**Critérios**
- Dada a lição 3 parada no passo 5, quando o usuário a abre de novo, então ela começa no passo 5.

### 4.2 Passos de conteúdo

**LEARN-R15 · Concept e Tip.** Um Concept tem título, texto e, opcionalmente, uma "Key idea". Um Tip ("Uvva tip") tem só texto. Os dois têm "Continue", sempre ativo.

**LEARN-R16 · Sem glossário.** As lições não têm termos tocáveis nem folha de glossário. O glossário é acessado por um card na Home (LESSON-R16).

### 4.3 Perguntas

**LEARN-R17 · Responder e verificar.** Toda pergunta tem um botão "Check". Depois de "Check", a resposta fica bloqueada e aparece o feedback: "Correct" ou "Not quite", mais a explicação. O botão passa a ser "Continue". **Errar não impede avançar** e não obriga a repetir.

| Tipo | Como se responde | "Check" ativo quando | Está certa quando |
| --- | --- | --- | --- |
| multipleChoice | Uma opção | Há uma opção escolhida | A opção é a resposta |
| trueFalse | True ou False | Há uma escolha | A escolha é a resposta |
| selectMultiple | Várias opções | Há pelo menos uma escolhida | O conjunto escolhido é **exatamente** o conjunto correto |
| fillBlank | Uma palavra entre as opções | Há uma palavra escolhida | A palavra é a resposta |
| ordering | Arrastar os itens para a ordem certa | Sempre | A ordem é exatamente a correta |
| matchPairs | Tocar num termo e depois no par dele | (sem Check; ver LEARN-R18) | Todos os pares ligados |

**LEARN-R17a · Feedback de ordering.** Se a ordem estiver errada, a explicação começa com "Correct order: " e a ordem certa.

**LEARN-R17b · Ordem embaralhada.** Os itens de ordering e o lado direito de matchPairs aparecem embaralhados, nunca já na ordem certa. O embaralhamento usa uma semente fixa por passo, para ser o mesmo em cada abertura e previsível nos testes.

**LEARN-R18 · matchPairs.**
- Tocar num termo e depois no seu par liga os dois.
- Um par errado mostra "Not a pair. Try again." e conta como uma tentativa errada.
- Tocar num termo já ligado desfaz a ligação.
- O estado mostra "[n] of [total] matched".
- Quando todos estão ligados, o feedback é "Correct" se não houve erros, e "Not quite" se houve. A explicação diz "All [n] pairs matched on the first try." ou "All [n] pairs matched, with [k] wrong tr[y/ies]."

**Critérios**
- Dada uma selectMultiple com resposta {0, 1, 3}, quando o usuário escolhe {0, 1}, então é "Not quite".
- Dada a mesma pergunta, quando o usuário escolhe {0, 1, 3}, então é "Correct".
- Dada uma resposta errada, quando o usuário toca em "Continue", então avança para o próximo passo.
- Dada uma ordering com 4 itens, então a ordem inicial nunca é a correta.
- Dado um matchPairs de 5 pares com 1 erro, então o feedback diz "All 5 pairs matched, with 1 wrong try."
- Dada uma fillBlank sem palavra escolhida, então "Check" está inativo.

### 4.4 Resumo (fim da lição)

**LEARN-R19 · Resumo.** O último passo de toda lição é o Summary:
- **Brinde:** uma palavra entre 10 línguas, com "Means “cheers” in [língua]" na mesma cor (sem a tradução literal). As línguas são Santé (francês), Salud (espanhol), Cin cin (italiano), Saúde (português), Prost (alemão), Proost (neerlandês), Sláinte (irlandês), Yamas (grego), Kanpai (japonês) e Na zdrowie (polaco). A escolha é aleatória (o gerador é injetado nos testes).
- **Aviso:** ao abrir o Summary, um aviso "Lesson complete +[XP] XP" aparece no topo por alguns segundos. Numa revisão, só "Lesson complete".
- "What you've learned", com os pontos do resumo.
- **Botão:** "Next lesson", que mostra o título da seguinte. Na última lição do curso, o botão é "Finish module".

Chegar ao Summary marca a lição como concluída (SHARED-R15).

**LEARN-R19a · Revisão.** Uma lição já concluída pode ser feita de novo a qualquer momento. A revisão não dá XP outra vez e não muda a data de conclusão (ver D3).

**Critérios**
- Dado o brinde "Santé", então o resumo diz "Means “cheers” in French".
- Dada uma lição de 15 XP, então o aviso diz "Lesson complete +15 XP".
- Dada a lição 6 de 6, então o botão diz "Finish module".
- Dada uma lição concluída e revista, então o XP total do usuário não muda.

## 5. XP

**LEARN-R20 · XP por lição.** Toda lição vale 15 XP, incluindo a lição de revisão que fecha cada curso (LESSON-R04). O total de um curso é `15 × lições`, sem bónus (LESSON-R06).

**LEARN-R21 · Quando conta.** O XP de uma lição é somado uma única vez, quando ela é concluída pela primeira vez, e não depende do número de acertos.

**Critérios**
- Dado um curso de 5 lições, então ele vale 75 XP.
- Dada uma lição concluída com 0 acertos, então o usuário ganha os 15 XP.

## 6. Certificados

**LEARN-R22 · Quando.** Quando um curso passa a Done (todas as lições concluídas, LEARN-R02), é gerado um certificado, que abre em formato Story. Isso acontece no Summary da lição que completou o curso, qualquer que seja a sua posição (ver D2). Cada curso gera um único certificado.

**LEARN-R22a · Guardado no aparelho.** O certificado não é enviado por e-mail: a conta não tem e-mail (ONBOARDING v0.5). Guarda-se o registo (curso e data) com os dados da conta, e a imagem é desenhada sempre que o certificado é aberto, aqui ou em You › Certificates (ARCHITECTURE §2.1).

**LEARN-R23 · Conteúdo.** Data de conclusão, título, tipo (módulo, região ou casta), descrição, XP do curso e três coisas que o usuário passa a saber fazer ("What I can do now"). O certificado de região inclui o mapa da região.

**LEARN-R24 · Formatos.** Dois formatos, escolhidos nas tabs da folha de partilha:
- **Story:** imagem 9:16, para "Share to Instagram".
- **WhatsApp:** imagem 4:5, com uma mensagem já escrita, para "Send on WhatsApp".

Não existe formato Link (as telas "Certificate · Link" do canvas estão fora de escopo). "Save image" guarda nas fotos (SHARED-R20). "Not now" fecha o certificado. Os certificados ficam também em You › Certificates (ver `you.md`).

**Critérios**
- Quando o usuário conclui a última lição de um curso, então é criado 1 certificado com a data de hoje (SHARED-R02).
- Quando um certificado é criado, então ele aparece em You › Certificates, com a data de conclusão.
- Dado um curso revisto e concluído outra vez, então nenhum certificado novo é criado.
- Dado um certificado aberto, então a folha de partilha tem exatamente as tabs Story e WhatsApp.
- Dada a tab Story, então a imagem tem proporção 9:16; dada a tab WhatsApp, 4:5.

## 7. Fora de escopo

- Limite diário, Lesson limit, preço dos cursos e paywall (SHARED-R01).
- O conteúdo e as regras de escrita das lições: [`../Lesson/LESSON.md`](../Lesson/LESSON.md).
- A lista de certificados e o streak: `you.md`.

## 8. Dúvidas em aberto

- [ ] **D1 · Bloqueio do curriculum.** O canvas tem "Locked until module N−1". Com a app toda aberta, eu tirei o bloqueio. Ele era uma regra de plano (sai) ou uma regra de ensino, para seguir a ordem (fica)?
- [ ] **D2 · Lições dentro do curso.** Dentro de um curso, as lições também podem ser feitas em qualquer ordem, ou a lição N só abre depois da N−1?
- [ ] **D3 · Revisão e XP.** Rever uma lição não dá XP outra vez. Confirma? E a revisão substitui as respostas guardadas da primeira vez?
- [x] **D4 · Conteúdo dos cursos.** Definido em `Documentation/Lesson/`. Em By region, o curso é por região dentro do país.
- [ ] **D5 · Mais de um curso em andamento.** Se houver vários, a Home mostra o último aberto (HOME-R13). Na aba Learn, algum deles aparece em destaque?
- [x] **D8 · Países e regiões.** Definidos em [`../Lesson/REGION.MD`](../Lesson/REGION.MD).
- [ ] **D9 · Mensagem do WhatsApp.** A mensagem do certificado no WhatsApp leva algum link (por exemplo, para baixar a app), ou só o texto e a imagem?
- [ ] **D7 · Marcas ✓ e ✕.** O player do protótipo usa ✓ e ✕ nas opções, mas o design system diz que o estado não usa ícones de certo/errado, só cor com uma palavra. Qual vale?
