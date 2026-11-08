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

**CELLAR-R13 · Abrir e voltar.** Tocar numa capa ou numa linha abre a nota. O `‹` volta ao Cellar na mesma posição de scroll.

## 4. Nova nota

### 4.1 Caminho principal

```
+ → [pedido de câmara, só na 1.ª vez] → Foto da frente → Foto do contrarrótulo → A ler o rótulo
  → "Have you had this wine?"
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

**CELLAR-R13c · Entradas vindas da Home.**
- "Save to Cellar" em Escolha o seu vinho (HOME-R28) guarda o vinho como Not yet.
- Avaliar um vinho em Vinhos para o seu paladar (HOME-R24) guarda o vinho como Tasted, com esse veredito.
- Nos dois casos vale a CELLAR-R13b. A entrada não tem fotos, e os dados e a leitura vêm do catálogo.

**Critérios**
- Quando o usuário toca em "Save to Cellar" na Home, então aparece no Cellar uma entrada com tag Not yet.
- Quando o usuário avalia um vinho da Home com Maybe, então aparece no Cellar uma entrada com tag Maybe e o mapa é recalculado uma única vez.

**CELLAR-R14 · O botão +.** O `+` do Cellar e o da Home (HOME-R03) abrem este mesmo fluxo.

**CELLAR-R15 · Câmara.** A primeira vez, o iOS pede acesso à câmara com o texto "UVVA photographs the front and back label to read the wine." Com acesso dado, o fluxo segue.

**CELLAR-R16 · Fotos.**
- Primeiro passo: "Photograph the front", "Fit the whole label inside the frame."
- Segundo passo: "Now the back label", "Grape, alcohol and producer are usually here."
- O topo mostra os dois passos ("01 Front", "02 Back label"), com o passo concluído marcado.

**CELLAR-R17 · Leitura.** Depois das duas fotos, "Reading your label" ("This takes a few seconds"). A leitura é feita no aparelho, sem internet e sem serviço na nuvem:
1. O texto do rótulo é lido nas duas fotos.
2. A UVVA procura o vinho no catálogo. Se o encontrar, os dados e a leitura vêm do catálogo.
3. Se não o encontrar, os dados vêm do texto lido, e o mapa do vinho é a média dos vinhos do catálogo mais parecidos (mesma casta e tipo; depois região e tipo; depois só tipo). Quando há dúvida sobre o que foi lido, abre o preenchimento à mão já preenchido, para o usuário confirmar.

O resultado preenche os dados do vinho (WineFacts) e a leitura da UVVA (UvvaReading).

**CELLAR-R18 · Já provou?** "Have you had this wine?"
- "Yes · would you drink it again" leva a "Would you drink it again?", com Yes, Maybe ou No (SHARED-R08). Depois vêm a nota livre ("Your note") e "Save note".
- "Not yet · add to cellar or find it" leva a "Add to cellar", que guarda a entrada como Want to try (ver D6 para "find it").

**CELLAR-R19 · Guardar.** "Save note" guarda a entrada Tasted no topo do Cellar e mostra "Note saved". O veredito gera uma avaliação que recalcula o mapa (SHARED-R09, QUIZ-R22).

**CELLAR-R20 · Nota livre opcional.** O veredito é obrigatório ("Required"); "Your note" é opcional ("Kept for you only"). Dá para guardar só com o veredito.

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

**CELLAR-R24 · Refazer as fotos.** Na nova nota, "Redo" apaga as duas fotos e a leitura e volta à foto da frente.

**CELLAR-R25 · Descartar.** Fechar a nova nota (`×`) antes de guardar pede confirmação: "Discard this note?", "Your photos and UVVA's reading won't be saved." "Discard" fecha sem guardar nada; "Keep editing" volta à nota.

**Critérios**
- Dado um erro de leitura, quando o usuário toca em Try again, então abre a foto da frente.
- Dada a câmara recusada, quando o usuário toca em +, então abre "The camera is off", e não o pedido do iOS.
- Dado o preenchimento à mão com o nome vazio, então Continue está inativo; com "Ponto Forte", fica ativo.
- Dadas as duas fotos tiradas, quando o usuário toca em Redo, então as fotos e a leitura são apagadas e abre a foto da frente.
- Dada uma nova nota, quando o usuário toca em × e depois em Discard, então o Cellar não muda e nenhuma avaliação é criada.

## 5. A nota guardada

**CELLAR-R26 · Conteúdo.**
- Data (ex.: "29 Aug"), nome, denominação e ano.
- "Again", com o veredito.
- A capa (fotos da frente e do verso).
- "Your note".
- Os dados: Grape, Region, Vintage, Type, Alcohol e Producer. Um dado ausente não aparece.
- "UVVA's reading": um texto, a estrutura (Body, Tannin, Acidity, Sweetness, cada um com uma palavra) e os aromas.
- Os botões Edit e Delete.

**CELLAR-R27 · Editar.** "Edit" deixa mudar todos os campos, inclusive o veredito. "Save changes" guarda as alterações; "Cancel" descarta-as. Mudar o veredito altera a avaliação desse vinho (ver D8).

**CELLAR-R28 · Apagar.** "Delete" pede confirmação: "Delete this note?", "It leaves your cellar and stops counting towards your palate map. This can't be undone." "Delete" apaga a entrada e retira a sua avaliação do mapa. "Cancel" fecha a folha e mantém a nota.

**CELLAR-R29 · Recalcular o mapa.** Para cumprir as regras CELLAR-R27 e CELLAR-R28, o mapa é recalculado: parte do mapa do último Quiz (QUIZ-R18a) e reaplica, por ordem de data, as avaliações feitas depois dele que ainda existem (ver D8).

**Critérios**
- Dada uma nota sem álcool registado, então a linha Alcohol não aparece.
- Dada uma nota editada de Yes para No, quando o usuário toca em Save changes, então o veredito guardado é No e o mapa é recalculado.
- Dada uma nota editada, quando o usuário toca em Cancel, então nada muda.
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
| D10 | Save to Cellar da Home | Sim, entra como Not yet | CELLAR-R13c |
| D11 | Avaliação na Home | Sim, entra como Tasted com o veredito | CELLAR-R13c |
| D7 | Nota livre | Opcional; o veredito é obrigatório | CELLAR-R20 |

## 8. Dúvidas em aberto

- [ ] **D2 · Vários valores num filtro.** Dentro do mesmo filtro, dá para escolher mais de um valor (por exemplo, Red e White ao mesmo tempo)?
- [ ] **D3 · Empate em Most tasted.** Com um empate, qual região aparece: a mais recente, ou a primeira por ordem alfabética?
- [ ] **D4 · Capa sem foto.** Na grade, como aparece uma entrada sem foto (preenchida à mão ou vinda da Home)?
- [ ] **D6 · "Find it".** O que faz "find it" em "Not yet · add to cellar or find it"? Mostra onde comprar?
- [ ] **D8 · Editar e apagar no mapa.** Confirma que mudar ou apagar um veredito recalcula o mapa como na CELLAR-R29? Isso obriga a guardar o mapa do último Quiz e o histórico de avaliações. Atualizar o mesmo vinho (CELLAR-R13b) também troca a avaliação antiga pela nova?
- [ ] **D12 · Como saber que é o mesmo vinho.** Nome + produtor + ano chega? E um vinho sem ano ou sem produtor (preenchido à mão)?
