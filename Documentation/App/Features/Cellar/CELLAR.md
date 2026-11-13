# UVVA · Cellar

> Status: rascunho v0.2 · 2026-10-27 · D1, D5, D9, D10 e D11 respondidas
> Depende de: [`_shared.md`](_shared.md), [`quiz.md`](quiz.md)
> Fonte: canvas UVVA App, artboard Cellar (telas 01 a 09 e 13 fluxos).

## 1. Objetivo

O Cellar é o caderno de provas do usuário. Ele guarda os vinhos que o usuário provou, com o veredito e a nota, e os vinhos que quer provar. Um vinho entra no Cellar fotografando o rótulo (a UVVA lê o rótulo) ou preenchendo à mão.

Cada vinho provado e avaliado move o mapa do paladar (SHARED-R09). Pela SHARED-R01, não há limite de notas; a tela "Notes limit" está fora de escopo.

## 2. Modelo

```swift
struct CellarEntry {
    id
    wine: WineFacts            // nome (obrigatório), produtor, região, país, casta, ano, tipo, álcool, denominação
    status: .tasted | .wantToTry
    verdict: Verdict?          // .yes | .maybe | .no — só quando status == .tasted
    noteText: String?          // "Your note"
    photos: (front, back)?     // ausentes quando preenchido à mão
    reading: UvvaReading?      // texto, estrutura (body, tannin, acidity, sweetness) e aromas
    createdAt, updatedAt
}
```

**CELLAR-R01 · Dois tipos de entrada.** "Tasted" é um vinho já provado: tem veredito e conta para o mapa. "Want to try" ainda não foi provado: não tem veredito e não conta para o mapa.

**CELLAR-R01a · Tag.** Toda entrada tem exatamente uma tag, derivada do estado e do veredito:

| Tag | Condição |
| --- | --- |
| Yes | Tasted, veredito Yes |
| Maybe | Tasted, veredito Maybe |
| No | Tasted, veredito No |
| Not yet | Want to try |

**CELLAR-R01b · De Not yet a provado.** Abrir uma entrada Not yet mostra "Have you had this wine?". Responder Yes e escolher o veredito transforma a entrada em Tasted, com essa tag, e cria a avaliação. A entrada mantém o `createdAt` (não sobe para o topo).

**CELLAR-R02 · Ordem.** As entradas aparecem da mais recente para a mais antiga, por `createdAt`. Uma entrada nova entra no topo.

**Critérios**
- Dada uma entrada Tasted, então ela tem veredito.
- Dada uma entrada Want to try, então ela não tem veredito e não gera avaliação.
- Dadas entradas criadas em 01/10 e 15/10, então a de 15/10 aparece primeiro.
- Dada uma entrada Tasted com veredito Maybe, então a tag é Maybe.
- Dada uma entrada Not yet, quando o usuário responde Yes e escolhe No, então a entrada passa a Tasted, a tag passa a No e é criada 1 avaliação No.

## 3. A aba Cellar

### 3.1 Header e números

**CELLAR-R03 · Header.** "UVVA | Cellar", o título "Your Cellar" e o botão `+`. Ao rolar, o header ganha véu e blur (até 160 px).

**CELLAR-R04 · Números.** Três números no topo:

| Número | Cálculo |
| --- | --- |
| Cellar | Total de entradas |
| Regions | Número de regiões diferentes entre as entradas |
| Most tasted | A região com mais entradas; "—" se não houver nenhuma |

**Critérios**
- Dadas 3 entradas do Douro e 1 do Dão, então os números são 4, 2 e Douro.
- Dado o Cellar vazio, então os números são 0, 0 e "—".
- Dado um empate entre Douro e Dão, então Most tasted é [ver D3].

### 3.2 Vazio

**CELLAR-R05 · Estado vazio.** Sem entradas, mostra a ilustração de uva, "Your cellar is empty" e "Tap + to photograph your first bottle and add it to your cellar." Os filtros aparecem inativos.

### 3.3 Grade e lista

**CELLAR-R06 · Duas vistas.**
- **Grade (padrão):** grade magazine de capas. A capa é a foto da frente do rótulo, sob o véu de 58%, com o veredito em RedGrapes branco.
- **Lista:** cada linha tem o nome, o ano, a origem, o veredito e um chevron.

**CELLAR-R07 · Vista guardada.** A escolha entre grade e lista fica guardada e é a vista com que o Cellar abre da próxima vez.

**CELLAR-R08 · Entrada sem foto.** Uma entrada preenchida à mão não tem foto. Na grade, ela aparece com [ver D4].

**CELLAR-R09 · Want to try.** Uma entrada Want to try aparece com a tag "Not yet" no lugar do veredito, tanto na grade como na lista.

**Critérios**
- Dada a primeira abertura, então a vista é a grade.
- Dada a vista lista escolhida, quando o Cellar é fechado e aberto de novo, então abre em lista.

### 3.4 Filtros

**CELLAR-R10 · Filtros.** Cinco filtros: Tag (CELLAR-R01a), Type, Grape, Region e Producer. Cada um mostra os valores que existem nas entradas do usuário; Tag mostra sempre os quatro valores. Se um filtro aceitar vários valores, uma entrada aparece se tiver qualquer um deles (OU) (ver D2). Filtros diferentes combinam-se: uma entrada aparece se satisfaz todos (E).

**Critérios**
- Dados Type = Red e Region = Douro, então só aparecem tintos do Douro.
- Dados Tag = Not yet e Region = Douro, então aparecem só as entradas Not yet do Douro.
- Dado o Cellar sem nenhum vinho do Alentejo, então Alentejo não aparece como opção de Region.

### 3.5 Pesquisa

**CELLAR-R11 · Pesquisa.** "Search your cellar" aparece ao rolar o Cellar. A pesquisa procura no nome do vinho, na casta, na região e no produtor, sem diferenciar maiúsculas, minúsculas ou acentos. Os resultados mostram "[n] notes" e as linhas encontradas. Tocar num resultado abre a nota.

**CELLAR-R12 · Sem resultados.** Sem resultados, mostra o estado vazio da pesquisa. "Cancel" fecha a pesquisa e volta ao Cellar.

**Critérios**
- Dado o vinho "Ponto Forte" da casta Syrah, quando o usuário procura "syrah", então ele aparece.
- Dada uma entrada da região "Dão", quando o usuário procura "dao", então ela aparece.
- Dada uma pesquisa sem resultados, quando o usuário toca em Cancel, então volta ao Cellar sem filtro de pesquisa.

### 3.6 Abrir uma nota

**CELLAR-R13 · Abrir e voltar.** Tocar numa capa ou numa linha abre a nota numa folha sobre o Cellar, sem barra, logo nem título. Arrastar a folha para baixo fecha-a, e o Cellar fica na mesma posição de scroll.

## 4. Nova nota

### 4.1 Caminho principal

```
+ → [pedido de câmara, só na 1.ª vez] → Foto da frente → Foto do contrarrótulo → A ler o rótulo
  → "Have you had this wine?"            ("Rate it again?" num vinho da Home avaliado antes, CELLAR-R14a)
       ├─ Yes · would you drink it again → "Would you drink it again?" Yes / Maybe / No → Your note → Save note
       └─ Not yet · add to cellar or find it → Add to cellar
```

**CELLAR-R13a · O mesmo vinho.** Dois vinhos são o mesmo quando têm o mesmo nome, produtor e ano, ignorando maiúsculas, minúsculas e acentos (ver D12). Cada vinho tem no máximo uma entrada no Cellar.

**CELLAR-R13b · Atualizar em vez de duplicar.** Quando um fluxo vai guardar um vinho que já está no Cellar, ele atualiza a entrada existente em vez de criar outra:
- As fotos, a leitura e a nota novas substituem as anteriores (um campo vazio no fluxo novo não apaga o que existia).
- Um veredito novo substitui o anterior e a tag muda.
- Uma entrada Tasted não volta a Not yet.
- `updatedAt` muda; `createdAt` fica igual.

**Critérios**
- Dado "Ponto Forte, Ravasqueira, 2024" no Cellar com Maybe, quando o usuário fotografa o mesmo vinho e escolhe Yes, então o Cellar continua com 1 entrada desse vinho, agora com tag Yes.
- Dado "Ponto Forte 2024" e "Ponto Forte 2023", então são 2 vinhos diferentes.
- Dada uma entrada Tasted, quando o mesmo vinho é guardado com "Not yet · Add to cellar", então a entrada continua Tasted.

**CELLAR-R13c · Entradas vindas da Home (2026-11-10).**
- "Add to cellar" no card do melhor match abre a nota nova já no vinho (CELLAR-R14a).
- "Add to cellar" na folha do vinho (HOME-R24) abre a nota nova (CELLAR-R14a); a entrada é a que essa nota guardar.
- Em todos vale a CELLAR-R13b. A entrada não tem fotos, e os dados e a leitura vêm do catálogo.

**Critérios**
- Quando o usuário toca em "Add to cellar" no card do melhor match, então a nota abre com esse vinho. A entrada aparece no Cellar ao tocar em "Save note".
- Quando o usuário toca em "Add to cellar" na folha de um vinho da Home, responde Yes e Maybe na nota e a guarda, então aparece no Cellar uma entrada com tag Maybe e o mapa é recalculado uma única vez.

**CELLAR-R14 · O botão +.** O `+` do Cellar e o da Home (HOME-R03) abrem este mesmo fluxo. A nota aparece como uma folha sobre a aba de origem e volta a essa aba ao fechar ou guardar. Nenhum passo tem barra, logo, título nem botão de fechar: a folha fecha-se arrastando para baixo (CELLAR-R25).

**CELLAR-R14a · Vinho vindo da Home (2026-11-12).** "Add to cellar" no card do melhor match ou na folha do vinho da Home (HOME-R24) abre este fluxo já no vinho em papel (CELLAR-R18), sem câmara nem fotos, com o vinho do catálogo. A folha não avalia: a nota é o único lugar onde um vinho é avaliado.
- Um vinho ainda não avaliado abre com "Have you had this wine?" (CELLAR-R18).
- Um vinho avaliado antes (na Home, antes desta regra, ou numa nota) abre com "Rate it again?" ("Quer avaliar novamente?"), com Yes e No. Yes leva a "Would you drink it again?" e o veredito novo substitui o anterior (CELLAR-R13b). No mantém o veredito que o vinho tinha e a pergunta some. Guardada sem resposta, a nota também mantém esse veredito: a entrada entra como Tasted.
- Sem fotos, o topo mostra "ADD PHOTO +" (CELLAR-R24). Guardar e fechar seguem a CELLAR-R19, R20 e R25.
- Um vinho guardado com o mesmo veredito que já tinha não é avaliado outra vez: o mapa fica como está. Um veredito diferente substitui a avaliação (CELLAR-R13b).

**Critérios**
- Dado um vinho da Home nunca avaliado, quando a nota abre, então pergunta "Have you had this wine?".
- Dado um vinho avaliado antes com Maybe, quando a nota abre, então pergunta "Rate it again?"; com No e "Save note", a entrada fica Tasted com Maybe e o mapa não muda.
- Dado o mesmo vinho, quando o usuário responde Yes e escolhe No, então a entrada fica com No e a avaliação é substituída.

**CELLAR-R15 · Câmara.** A primeira vez, o iOS pede acesso à câmara com o texto "UVVA photographs the front and back label to read the wine." Com acesso dado, o fluxo segue.

**CELLAR-R16 · Fotos.**
- Primeiro passo: "Photograph the front", "Fit the whole label inside the frame."
- Segundo passo: "Now the back label", "Grape, alcohol and producer are usually here."
- O topo mostra os dois passos ("01 Front", "02 Back label"), com o passo concluído marcado.

**CELLAR-R16a · Foto da galeria.** Em cada um dos dois passos, ao lado do disparador, um botão abre a galeria do iOS para escolher uma foto já tirada em vez de fotografar na hora. A foto escolhida conta como a desse passo e o fluxo segue igual. O seletor é o do sistema e não pede acesso à galeria.

**CELLAR-R17 · Leitura.** Depois das duas fotos, "Reading your label" ("This takes a few seconds"). A leitura é feita no aparelho, sem internet e sem serviço na nuvem:
1. O texto do rótulo é lido nas duas fotos.
2. A UVVA procura o vinho no catálogo. Se o encontrar, os dados e a leitura vêm do catálogo.
3. Se não o encontrar, os dados vêm do texto lido, e o mapa do vinho é a média dos vinhos do catálogo mais parecidos (mesma casta e tipo; depois região e tipo; depois só tipo). Basta ter lido o nome: a nota abre logo, preenchida com o que foi lido, sem passar pelo preenchimento à mão.
4. O preenchimento à mão (CELLAR-R23) só aparece quando a leitura não dá para uma nota: nenhum nome lido (abre com o que mais tiver sido lido, se houver) ou, pela CELLAR-R21, nada lido.

O resultado preenche os dados do vinho (WineFacts) e a leitura da UVVA (UvvaReading).

**Como a leitura lê (2026-11-11).**
- O texto é lido de uma cópia da foto em tamanho cheio (até 4032 px no lado maior); a nota guarda uma cópia leve (1800 px). Reduzida antes de ler, a letra miúda do contrarrótulo ficava com poucos pixels e não era lida.
- Além de nome, produtor, ano, tipo, região, país, castas e álcool, a leitura procura no contrarrótulo as notas de prova, as harmonizações e a temperatura de servir. O modelo no aparelho (com Apple Intelligence) lê as três; sem ele, o parser ainda lê a temperatura ("Serve at 16-18°C", "Servir a 16 – 18 ºC"; só entre 4 e 22 °C). Num vinho fora do catálogo, vão para Notes, Pairings e How to serve.
- Nas builds de debug, o fim da nota (e o preenchimento à mão) mostra "Label reading · debug": as linhas lidas em cada lado, o que o parser e o modelo tiraram delas e se o catálogo reconheceu o vinho. Serve para ver porque um rótulo deu pouco; não aparece na app publicada.

**CELLAR-R18 · Já provou?** "Have you had this wine?" (num vinho da Home avaliado antes, "Rate it again?", CELLAR-R14a)
- "Yes · would you drink it again" leva a "Would you drink it again?", com Yes, Maybe ou No (SHARED-R08). Depois vêm a nota livre ("Your note") e "Save note". Escolhido o veredito, o botão fica marcado um instante, a pergunta some no lugar (fade, sem se mexer) e depois o conteúdo de cima desce e ocupa o espaço dela; "Save note" fica onde estava (2026-11-11).
- "Not yet · add to cellar or find it" leva a "Add to cellar", que guarda a entrada como Want to try (ver D6 para "find it").

**CELLAR-R19 · Guardar.** "Save note" é o único botão no fim da nota e está sempre ativo (2026-11-11). Guarda a entrada no topo do Cellar e mostra "Note saved": Tasted com o veredito, que gera uma avaliação e recalcula o mapa (SHARED-R09, QUIZ-R22); Want to try com Not yet ou sem resposta a "Have you had this wine?". Com Yes e sem veredito, não guarda e diz "Choose whether you would drink it again."; a frase sai quando o veredito é escolhido.

**CELLAR-R20 · Nota livre opcional.** O veredito é obrigatório ("Required"); "Your note" é opcional ("What stood out in the glass?"). A nota não é só para o usuário: poderá ser mostrada a outras pessoas no futuro, por isso o texto de ajuda não promete privacidade (2026-11-11). Dá para guardar só com o veredito.

**Critérios**
- Dado um acesso à câmara nunca pedido, quando o usuário toca em +, então aparece o pedido do iOS.
- Dado o acesso já dado, quando o usuário toca em +, então abre direto a foto da frente.
- Dada uma leitura concluída, quando o usuário escolhe Yes e depois Maybe e guarda, então é criada 1 entrada Tasted com veredito Maybe, no topo, e 1 avaliação Maybe.
- Dada uma leitura concluída, quando o usuário escolhe Not yet e Add to cellar, então é criada 1 entrada Want to try e nenhuma avaliação.

### 4.2 Desvios

**CELLAR-R21 · Rótulo não lido.** Se a leitura falhar, mostra "We couldn't read your label", "Check these two things and try again." e duas dicas:
1. **Light:** "Move somewhere brighter and keep the label out of shadow."
2. **Whole label:** "Fit the whole label inside the frame, flat and in focus."

"Try again" volta à foto da frente. "Fill in by hand" abre o preenchimento à mão.

**CELLAR-R22 · Câmara recusada.** Se o usuário recusar a câmara, o `+` passa a abrir "The camera is off", "UVVA needs the camera to read labels. Turn it on in Settings, or add the wine by hand." "Open Settings" abre os Ajustes do iOS. "Fill in by hand" abre o preenchimento à mão.

**CELLAR-R23 · Preencher à mão.** "Add what you can read on the label. Only the name is needed." Os campos são nome, produtor, ano, região, casta e tipo (Red, White, …). Só o nome é obrigatório: "Continue" fica ativo assim que há um nome. A UVVA faz a leitura a partir dos dados escritos, e o fluxo segue em "Have you had this wine?".

**CELLAR-R24 · A foto da nota (2026-11-11).** O topo da nova nota mostra a foto da frente do rótulo. Sem foto (um vinho vindo da Home, ou preenchido à mão), mostra a imagem de fundo da Home com "ADD PHOTO +". Tocar na foto, ou na imagem, abre a câmara para uma foto nova, com a galeria ao lado; a foto nova substitui a do topo e o resto da nota (leitura, respostas e nota) fica como estava. Não há "Redo": substitui o botão que apagava as fotos e a leitura.

**CELLAR-R25 · Descartar.** Arrastar a folha da nova nota para baixo, em qualquer passo antes de guardar, fecha-a sem guardar nada e sem pedir confirmação. Enquanto a nota está a ser guardada, a folha não se fecha.

**Critérios**
- Dado um erro de leitura, quando o usuário toca em Try again, então abre a foto da frente.
- Dada a câmara recusada, quando o usuário toca em +, então abre "The camera is off", e não o pedido do iOS.
- Dado o preenchimento à mão com o nome vazio, então Continue está inativo; com "Ponto Forte", fica ativo.
- Dada uma nota com foto, quando o usuário toca na foto e tira outra, então a nota mostra a foto nova e mantém o vinho, as respostas e a nota escrita.
- Dado um vinho vindo da Home, então o topo da nota mostra a imagem de fundo com "ADD PHOTO +".
- Dada uma nova nota, quando o usuário arrasta a folha para baixo, então o Cellar não muda e nenhuma avaliação é criada.
- Dado um rótulo fora do catálogo com o nome lido, então abre a nota com esse nome, sem o preenchimento à mão.
- Dado um rótulo em que só se leu a casta, então abre o preenchimento à mão com a casta preenchida e Continue inativo.
- Dado o passo da foto da frente, quando o usuário escolhe uma foto da galeria, então abre o passo do contrarrótulo.

## 5. A nota guardada

**CELLAR-R26 · Conteúdo (2026-11-11).** A nota guardada mostra o vinho com o desenho da folha do vinho da Home (HOME-R28a), só para ler. É o mesmo componente: não há chips, nem as linhas de intensidade de deslizar, nem a pergunta "Would you drink it again?" (esses são da edição, CELLAR-R27). De cima para baixo:
- o nome em maiúsculas desenhadas, o produtor e "Added 29 Aug";
- a capa (fotos da frente e do verso), com o veredito na frente, e "Your note", quando há;
- o match com o mapa e as duas frases (HOME-R10b), quando há mapa;
- os factos: Origin | Vintage ("2023 · 3 years"), Style | Grape & notes;
- "Find the wine" (HOME-R09a), Pairings e How to serve (temperatura e frase), quando há;
- os eixos em pontos e os dois mapas;
- os botões Edit e Delete.

Os dados vêm da cópia guardada na entrada e, por trás, do catálogo (How to serve só existe lá).

**CELLAR-R27 · Editar (2026-11-11).** "Edit" fecha a nota e abre a nova nota (CELLAR-R18) já nesse vinho, com tudo editável: a foto, os chips, a intensidade, "Your note" e a pergunta ("Would you drink it again?" com o veredito marcado; num vinho Not yet, "Have you had this wine?"). "Save note" guarda por cima da mesma entrada: um veredito diferente substitui a avaliação (CELLAR-R13b, D8), e a nota fica como foi escrita, mesmo apagada. Fechar a nova nota sem guardar não muda nada.

**CELLAR-R28 · Apagar.** "Delete" pede confirmação: "Delete this note?", "It leaves your cellar and stops counting towards your palate map. This can't be undone." "Delete" apaga a entrada e retira a sua avaliação do mapa. "Cancel" fecha a folha e mantém a nota.

**CELLAR-R29 · Recalcular o mapa.** Para cumprir as regras CELLAR-R27 e CELLAR-R28, o mapa é recalculado: parte do mapa do último Quiz (QUIZ-R18a) e reaplica, por ordem de data, as avaliações feitas depois dele que ainda existem (ver D8).

**Critérios**
- Dado um vinho do catálogo com temperatura de servir, então a nota guardada mostra How to serve com a temperatura.
- Dada uma nota guardada, quando o usuário toca em Edit, então abre a nova nota nesse vinho com o veredito e a nota preenchidos.
- Dada uma nota editada de Yes para No, quando o usuário toca em Save note, então o veredito guardado é No e o mapa é recalculado.
- Dada uma nota aberta para editar, quando o usuário fecha a nova nota sem guardar, então nada muda.
- Dada uma nota com avaliação Yes, quando o usuário a apaga, então ela sai do Cellar e o mapa fica igual ao que seria sem essa avaliação.
- Dado o pedido de apagar, quando o usuário toca em Cancel, então a nota continua.

## 6. Fora de escopo

- O limite de notas e o paywall (SHARED-R01).
- Os detalhes técnicos da leitura do rótulo (ver `Plans/PLANO-CELLAR-NOVA-NOTA.md`); aqui só entram o sucesso, a falha e os dados devolvidos.

## 7. Decisões

| # | Pergunta | Decisão (2026-10-27) | Regra |
| --- | --- | --- | --- |
| D1 | O que é Tag | Yes, Maybe, No e Not yet | CELLAR-R01a |
| D5 | Not yet passa a provado | Sim, ao responder Yes e dar o veredito | CELLAR-R01b |
| D9 | O mesmo vinho duas vezes | Atualiza a entrada existente | CELLAR-R13a, R13b |
| D10 | Add to cellar do melhor match | Abre a nota nova no vinho | CELLAR-R13c, R14a |
| D11 | Add to cellar da folha do vinho (2026-11-10) | Abre a nota nova no vinho; entra o que a nota guardar | CELLAR-R13c, R14a |
| D7 | Nota livre | Opcional; o veredito é obrigatório | CELLAR-R20 |

## 8. Dúvidas em aberto

- [ ] **D2 · Vários valores num filtro.** Dentro do mesmo filtro, dá para escolher mais de um valor (por exemplo, Red e White ao mesmo tempo)?
- [ ] **D3 · Empate em Most tasted.** Com um empate, qual região aparece: a mais recente, ou a primeira por ordem alfabética?
- [ ] **D4 · Capa sem foto.** Na grade, como aparece uma entrada sem foto (preenchida à mão ou vinda da Home)?
- [ ] **D6 · "Find it".** O que faz "find it" em "Not yet · add to cellar or find it"? Mostra onde comprar?
- [ ] **D8 · Editar e apagar no mapa.** Confirma que mudar ou apagar um veredito recalcula o mapa como na CELLAR-R29? Isso obriga a guardar o mapa do último Quiz e o histórico de avaliações. Atualizar o mesmo vinho (CELLAR-R13b) também troca a avaliação antiga pela nova?
- [ ] **D12 · Como saber que é o mesmo vinho.** Nome + produtor + ano chega? E um vinho sem ano ou sem produtor (preenchido à mão)?
