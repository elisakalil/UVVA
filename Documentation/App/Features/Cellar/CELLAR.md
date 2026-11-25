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

**CELLAR-R01b · De Not yet a provado.** Abrir uma entrada Not yet mostra o link "Rate this wine" (CELLAR-R18). Escolher o veredito na folha transforma a entrada em Tasted, com essa tag, e cria a avaliação. A entrada mantém o `createdAt` (não sobe para o topo).

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
- **Grade (padrão):** grade magazine de capas. A capa é a foto da frente do rótulo, sob o véu de 58%, com o veredito em RedGrapes branco. Toda capa mostra, sempre no canto inferior esquerdo, o nome do vinho e logo acima dele o match em grande, só "82%" (sem "match"); sem mapa, só o nome. O veredito ocupa o espaço que sobra acima, com tamanho e posição que variam de capa para capa, sem nunca cobrir o nome (2026-11-25).
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

**CELLAR-R11 · Pesquisa.** "Search your cellar" aparece ao rolar o Cellar, ou ao tocar na lupa à esquerda do + no cabeçalho, que abre a pesquisa já com o teclado (2026-11-25). A pesquisa procura no nome do vinho, na casta, na região e no produtor, sem diferenciar maiúsculas, minúsculas ou acentos. Os resultados mostram "[n] notes" e as linhas encontradas. Tocar num resultado abre a nota.

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
  → o vinho em papel → [opcional] "Rate this wine" → folha: Yes / Maybe / No (CELLAR-R18)
  → Your note → Save note            (sem veredito, entra como Want to try)
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
- Um vinho ainda não avaliado abre com o link "Rate this wine" (CELLAR-R18).
- Um vinho avaliado antes (na Home, antes desta regra, ou numa nota) abre com o link mostrando o veredito que tinha ("Your rating: Maybe"). Escolher outro na folha substitui o anterior (CELLAR-R13b). Guardada sem mexer, a nota mantém esse veredito: a entrada entra como Tasted (2026-11-14).
- Sem fotos, o topo mostra "ADD PHOTO +" (CELLAR-R24). Guardar e fechar seguem a CELLAR-R19, R20 e R25.
- Um vinho guardado com o mesmo veredito que já tinha não é avaliado outra vez: o mapa fica como está. Um veredito diferente substitui a avaliação (CELLAR-R13b).

**Critérios**
- Dado um vinho da Home nunca avaliado, quando a nota abre, então mostra "Rate this wine".
- Dado um vinho avaliado antes com Maybe, quando a nota abre, então mostra "Your rating: Maybe"; com "Save note" sem abrir a folha, a entrada fica Tasted com Maybe e o mapa não muda.
- Dado o mesmo vinho, quando o usuário responde Yes e escolhe No, então a entrada fica com No e a avaliação é substituída.

**CELLAR-R15 · Câmara.** A primeira vez, o iOS pede acesso à câmara com o texto "UVVA photographs the front and back label to read the wine." Com acesso dado, o fluxo segue.

**CELLAR-R16 · Fotos.**
- Primeiro passo: "Photograph the front", "Fit the whole label inside the frame."
- Segundo passo: "Now scan the back label", "Tap the button, then turn the bottle slowly." O contrarrótulo é escaneado (2026-11-13): o primeiro toque no disparador ("Start scanning") começa o scan; a moldura passa a pulsar, o disparador vira um quadrado de parar e o texto muda para "Turn the bottle slowly until the whole label has passed. Tap again when the count stops growing." Enquanto a garrafa gira, o texto é lido quadro a quadro, e por baixo dos passos aparece quantas linhas já estão confirmadas ("Hold the label inside the frame", depois "12 lines read"). O segundo toque ("Finish scanning") termina o scan e tira a foto que a nota guarda. A frente continua a ser uma foto: as letras grandes leem-se bem numa só. Sem câmara (simulador) ou com uma foto da galeria, o contrarrótulo é lido só da foto, como antes.
- O topo mostra os dois passos ("01 Front", "02 Back label"), com o passo concluído marcado.

**CELLAR-R16a · Foto da galeria.** Em cada um dos dois passos, ao lado do disparador, um botão abre a galeria do iOS para escolher uma foto já tirada em vez de fotografar na hora. A foto escolhida conta como a desse passo e o fluxo segue igual. O seletor é o do sistema e não pede acesso à galeria.

**CELLAR-R17 · Leitura.** Depois das duas fotos, "Reading your label" ("This takes a few seconds"). A leitura é feita no aparelho, sem internet e sem serviço na nuvem:
1. O texto do rótulo é lido nas duas fotos.
2. A UVVA procura o vinho no catálogo. Se o encontrar, os dados e a leitura vêm do catálogo, somados ao que o rótulo trouxe de novo: as castas, as notas e as harmonizações que o catálogo ainda não tinha entram depois das dele, sem repetir. A temperatura de servir e o álcool do catálogo ficam; os do rótulo só entram quando o catálogo não os tem.
3. Se não o encontrar, os dados vêm do texto lido, e o mapa do vinho é a média dos vinhos do catálogo mais parecidos (mesma casta e tipo; depois região e tipo; depois só tipo). Basta ter lido o nome: a nota abre logo, preenchida com o que foi lido, sem passar pelo preenchimento à mão.
4. O preenchimento à mão (CELLAR-R23) só aparece quando a leitura não dá para uma nota: nenhum nome lido, ou nada de onde tirar o mapa (CELLAR-R23a), e abre com o que mais tiver sido lido, se houver; ou, pela CELLAR-R21, nada lido.

O resultado preenche os dados do vinho (WineFacts) e a leitura da UVVA (UvvaReading).

**Como a leitura lê (2026-11-11).**
- O texto é lido de uma cópia da foto em tamanho cheio (até 4032 px no lado maior); a nota guarda uma cópia leve (1800 px). Reduzida antes de ler, a letra miúda do contrarrótulo ficava com poucos pixels e não era lida.
- Além de nome, produtor, ano, tipo, região, país, castas e álcool, a leitura procura no contrarrótulo as notas de prova, as harmonizações e a temperatura de servir. O modelo no aparelho (com Apple Intelligence) lê as três; sem ele, o parser ainda lê a temperatura ("Serve at 16-18°C", "Servir a 16 – 18 ºC"; só entre 4 e 22 °C). Num vinho fora do catálogo, vão para Notes, Pairings e How to serve.
- **As fontes somam-se (2026-11-13).** As harmonizações são as do catálogo mais as do rótulo, e o modelo no aparelho acrescenta mais três, a partir de tudo o que se sabe do vinho (tipo, castas, região, idade, álcool, aromas, a estrutura do mapa) e das harmonizações que ele já tem, sem as repetir. O modelo deixa de ser chamado quando o vinho já tem 10 harmonizações; as do rótulo nunca são cortadas. O mesmo vale para o preenchimento à mão (CELLAR-R23). Sem Apple Intelligence, ficam as do catálogo e do rótulo.
- Um vinho escaneado fica no catálogo do aparelho e acumula a cada nova leitura: as castas, as notas e as harmonizações novas somam-se às que ele tinha; o nome, o produtor e o mapa ficam como na primeira leitura. Os vinhos do catálogo da UVVA não são alterados: neles, a soma fica na entrada da Adega.
- **O scan do contrarrótulo (2026-11-13).** Só se lê o que aparece dentro da moldura (com 6% de folga), não a mão nem o que está atrás da garrafa. Um quadro em que menos de um terço das linhas foi lido com confiança de 0,5 ou mais está tremido (a garrafa girou rápido demais) e fica de fora. Como o rótulo é curvo, cada quadro lê um pedaço diferente de cada linha: os pedaços encaixam-se pelas palavras em comum (pelo menos 3 palavras ou 12 letras, com 70% das palavras sobrepostas iguais; uma palavra cortada na ponta do pedaço não conta contra) e cada palavra da linha é votada por todos os quadros que a leram, ficando a grafia mais lida (a mais longa, em empate). Linhas de uma ou duas palavras só se juntam palavra por palavra. Numa linha confirmada, uma palavra numa ponta lida por um só quadro foi cortada pela borda e sai. A foto final conta como mais um quadro; duas linhas do mesmo quadro nunca se juntam. Num scan (3 quadros ou mais), uma linha lida em 2 quadros ou mais fica confirmada, com confiança de pelo menos 0,5 + 0,1 por voto (0,7 com dois, 0,8 com três); uma lida num só quadro fica com 40% da confiança do OCR, abaixo do que uma medalha precisa (CELLAR-R30). A grafia que fica é a mais lida. O ruído do OCR, lido diferente a cada quadro, não junta votos.
- **O que se tira do texto (2026-11-13).** Antes do parser e do modelo saem as linhas que não falam do vinho: as que repetem a mesma coisa em várias línguas (duas barras ou mais, como os alérgenos), as de alérgenos, declaração nutricional, ingredientes, kJ/kcal e "por 100 ml" (também mal lidas, como "Beclaration"), códigos de lote e de barras (até 3 letras e 5 algarismos ou mais), restos com menos de 3 letras ou algarismos, e uma linha que outra já diz por inteiro (fica a mais longa, com a confiança da mais segura). O modelo no aparelho tem uma janela curta: recebe a frente inteira e, do contrarrótulo, as linhas mais seguras até 1.800 caracteres, na ordem do rótulo.
- **O que uma leitura pode acrescentar (2026-11-13).** Uma nota só entra se for um aroma de uma lista fixa no código: os das notas do catálogo da UVVA e aromas comuns que ele ainda não tem (Cocoa, Coffee, Tobacco…), com os adjetivos lidos como o aroma ("Spicy" é Spice, "Smoky" é Smoke, "Ripe red fruit" é Red fruit) e o plural como o singular; "Firate", "Pe", "Ripe" ou uma cor sozinha ("Red", "Black") não entram. A lista não vem dos vinhos do aparelho, para um vinho escaneado com ruído não a ensinar. O modelo é instruído a dar só nomes de coisas que cheiram ou sabem, nunca uma cor ou um adjetivo sozinho. A temperatura de servir que o modelo dá só entra se o rótulo a imprimir: os dois números numa linha que fala de temperatura (°, ºC, servir, temperatura…). Um produtor lido a uma ou duas letras de um produtor do catálogo é esse produtor, escrito como o catálogo o escreve ("CASA SANTOS LEIA" é Casa Santos Lima). O vinho que o catálogo reconhece passa pela mesma limpeza, por isso um vinho escaneado antes perde o ruído que leituras antigas lhe deixaram.
- Nas builds de debug, o fim da nota (e o preenchimento à mão) mostra "Label reading · debug": as linhas lidas em cada lado (no contrarrótulo, com a confiança de cada uma, o número de quadros do scan e quantas linhas foram tiradas), o que o parser e o modelo tiraram delas e se o catálogo reconheceu o vinho. "Export scan" partilha a leitura como a câmara a deu (as linhas da frente, da foto de trás e de cada quadro, em JSON), para a repetir num teste. Serve para ver porque um rótulo deu pouco; não aparece na app publicada.

**CELLAR-R30 · Certificação (2026-11-13).** O card com o selo, na folha do vinho (Home), na nova nota e na nota guardada, mostra o que certifica o vinho. Num vinho sem denominação reconhecida, sem menção legal com valor e sem medalha, o card não aparece.
- **Leitura.** O modelo no aparelho lê no rótulo a denominação com a sua categoria, como impressa ("Douro DOC", "Vinho Regional Lisboa"), a menção legal (Reserva, Grande Reserva, Gran Reserva, Riserva, Crianza) e as medalhas e pontuações de críticos (concurso ou crítico, medalha ou pontos, ano). Sem o modelo, o parser procura as mesmas coisas: as categorias, também por extenso ("Denominação de Origem Controlada"); as menções; e uma medalha só quando o nome de um concurso conhecido está na mesma linha ou ao lado. Uma menção só conta se estiver na lista: "Reservado" não é uma.
- **Somam-se, como as harmonizações (CELLAR-R17).** No vinho do catálogo, as medalhas lidas juntam-se às que ele tinha, sem repetir; a menção lida entra quando o catálogo não a tem, e a denominação lida entra quando ele não tem nenhuma ou quando nomeia o mesmo lugar com a categoria ("Lisboa" passa a "Vinho Regional Lisboa"). Um vinho escaneado acumula-as a cada leitura. A explicação da denominação vem do catálogo (o mesmo texto que a Home mostra) e, quando ele não a tem, de uma linha por categoria.
- **A denominação sem categoria (2026-11-13).** Quando o rótulo só diz o lugar ("Lisboa") e o catálogo escreve essa denominação sempre com a mesma categoria ("Vinho Regional Lisboa"), o vinho fica com a do catálogo e é classificado por ela. Quando o catálogo tem o mesmo lugar em categorias de níveis diferentes ("Tejo DOC" e "Vinho Regional Tejo"), não dá para saber qual é: o vinho fica sem explicação e sem nível. Só uma denominação que o catálogo escreve sem categoria nenhuma ("Napa Valley") e explica conta como protegida, como no `pack_content.py`.
- **Medalhas com prova (2026-11-13).** O catálogo não tem medalhas, por isso um concurso desconhecido continua a contar, mas só se o nome parecer de um concurso: escrito com letras (sem "@", "|"…) e com uma palavra de concurso ("Concurso", "Concours", "Awards", "Feira", "Vinhos", "Internacional", "Sélection"…). "Trophy · SENTENA COM." não conta. A medalha que o modelo no aparelho dá só entra se o nome do concurso e a medalha (ou os pontos) estiverem no texto que o OCR leu com confiança de pelo menos 0,5: o modelo organiza o texto, não acrescenta. Prémios guardados antes por leituras com ruído deixam de aparecer, e uma nota guardada com "Top X%" deixa de o mostrar quando, sem eles, o vinho já não chega ao top 10%.
- **Classificação**, sem IA. Denominação: de topo (DOCG, DOCa, Grand Cru, Premier Cru, Cru Classé, ou uma denominação que o catálogo marca como notável), protegida (DOC, AOC, DO, DAC, AVA…) ou regional (IGT, IGP, Vinho Regional…). Menção: forte (Grande Reserva e Gran Reserva em Portugal e Espanha, Riserva em Itália), com envelhecimento (Reserva e Crianza em Portugal e Espanha) ou fraca (a mesma palavra noutro país, onde a lei não a define). Reconhecimento: 4 (troféu, platina ou duplo ouro num grande concurso, ou 95+ pontos), 3 (ouro num grande concurso, ou 92–94), 2 (prata num grande concurso, ouro noutro conhecido, ou 90–91), 1 (outra medalha ou pontuação).
- **"Among the top X% of the world's wines".** É a parte estimada dos vinhos do mundo com sinais pelo menos tão fortes quanto os deste vinho nos três critérios, tomados como independentes: P(denominação) × P(menção) × P(reconhecimento). P da denominação e da menção é medida nos 10.000 vinhos do catálogo, a nossa amostra do mundo (`pack_content.py` escreve-a como código, `QualityPrevalence+Packed.swift`, a cada empacotamento, para que nenhum build a deixe de fora: topo 20%, Grande/Gran Reserva/Riserva 2,2%). O catálogo não tem medalhas, por isso P do reconhecimento é uma premissa, escrita no mesmo ficheiro: nível 4 = 0,5%, 3 = 2%, 2 = 5%, 1 = 10%. Arredondamento: abaixo de 1% é "Top 1%"; até 10%, inteiro; acima, de 5 em 5. Só aparece até 20% (2026-11-14): uma denominação de topo sozinha chega lá. Ex.: Colossal (Vinho Regional Lisboa, Grande Reserva) → Top 2%.
- **O card (2026-11-14).** Dois casos:
  - **No top 20%** ("Among the top 2% of the world's wines" / "Entre os 2% melhores vinhos do mundo"): selo, título e, por baixo, o que o põe lá ("DOCG · Grande Reserva · Gold · Decanter…"). Aberto, uma secção por motivo, com o que é e quão raro é: "O topo da Itália: regras rígidas e prova oficial antes de sair." + "Só 1 em cada 5 vinhos chega a esse nível."; "Grande Reserva" + a nota da lei + "Só 2% dos vinhos têm."; os prémios, um por linha.
  - **Fora do top 20%**: sem selo. Título sobre a denominação: protegida, "Authentic Bordeaux Supérieur" ("Bordeaux Supérieur autêntico"); regional, "Lisboa, unbound" ("Lisboa, sem amarras"). Por baixo, a denominação como escrita, a menção e o número de prémios. Aberto, o que o selo exige:
    - Selo de origem (DOC, DOP, DO, AOC, AOP, DAC, Qualitätswein, Prädikatswein): "Bordeaux Supérieur AOC, por lei exige:" **Região:** 100% das uvas locais. **Uva:** só as permitidas. **Método:** limite de produção e prova oficial. "Garante a origem, não a qualidade." (esta última não aparece num vinho do top).
    - Regional (IGT, IGP, Vinho Regional, Vin de Pays, Vino de la Tierra, Landwein): "Vinho Regional Lisboa, menos regras que um DOC:" **Região:** 85% das uvas locais. **Uva:** internacionais permitidas. **Método:** mais produção, misturas livres.
    - AVA, VQA e WO têm uma linha curta própria; uma denominação sem categoria usa a explicação do catálogo.
    - Textos curtos e diretos (2026-11-15): no top, cada motivo numa linha ("O topo da Itália, com prova oficial." + "Só 1 em cada 5 vinhos."; a menção com a regra da lei em poucas palavras + "Só 2% dos vinhos.").
  - Sem denominação, o título é a menção ou o prémio. Não há mais a secção "How UVVA estimates it".
- **Limites.** O OCR lê mal os selos redondos; só se conhecem as medalhas que estão na garrafa. Quando houver avaliações de utilizadores da UVVA em número, as premissas podem ser recalibradas.

**CELLAR-R18 · Avaliar (2026-11-14).** A avaliação abre-se numa folha própria, pelo botão fixo no pé: acima de "Save note" na nota nova, e acima de "Edit" na nota guardada (CELLAR-R26).
- O link diz "Rate this wine" ("Avaliar este vinho") enquanto não há veredito, e "Your rating: Yes · 4/5" ("Sua avaliação: Yes · 4/5") quando há; sem nota, só "Your rating: Yes". Um vinho avaliado antes mostra o veredito que mantém (CELLAR-R14a).
- A folha sobe do pé, em papel: a pergunta "Would you drink it again?" na letra desenhada, sem subtítulo; Yes, Maybe ou No (SHARED-R08); a nota ("Score") de 0 a 5; "Your note" (duas linhas pautadas, "What stood out in the glass?"); e "Save rating". Ao tocar em "Your note", a folha abre por inteiro, para o teclado não cobrir o botão. Na nota guardada, "Save rating" guarda também a nota escrita; apagada, ela sai (2026-11-14). O veredito e a nota atuais vêm marcados. "Save rating" só fica ativo com um veredito; a nota é opcional.
- **A nota de 0 a 5.** Seis pontos pequenos ligados por uma linha fina, como os eixos da intensidade: o primeiro é 0, marcados com um toque ou deslizando o dedo para o lado, e o ponto atual pulsa. Sem nota, todos ficam vazios. Ao lado, o número ("4/5", ou "–" sem nota). A nota fica na entrada do Cellar (`score`) e **não mexe no mapa do paladar**: só o veredito mexe (SHARED-R09).
- Abrir o link já é dizer que provou: não há mais o passo "Have you had this wine?".
- Na nota nova, veredito e nota só valem ao guardar (CELLAR-R19). Com veredito dado ali, a folha mostra também "Not tasted yet" ("Ainda não provei"), que tira os dois; num vinho avaliado antes esse link não aparece.
- Na nota guardada (CELLAR-R26), "Save rating" guarda na hora e recalcula o mapa pelo veredito. Se falhar, a folha fica aberta com "The rating wasn't saved. Try again.".
- **Ordem da nota nova (2026-11-14):** nome e produtor; fotos; card da certificação (CELLAR-R30); "X% match with your map"; os mapas; as frases ("High in body, like your map.", "Close to your map on every axis."); os factos; os chips (Grapes, Notes, Pairings); e a intensidade, com menos espaço entre as secções que antes. "Your note" não fica mais na página: está na folha de avaliação. No pé, fixos e sempre visíveis, com o papel a desvanecer por baixo: o botão de avaliação (contorno, fundo transparente, letra desenhada: "Rate this wine" ou "Your rating: Yes · 4/5"), que abre a folha, e "Save note" por baixo; a nota nova não tem "Find the wine".

**CELLAR-R18a · Escrever um chip (2026-11-25).** As folhas de chips (castas, notas e harmonizações na nota nova; região, denominação, castas e notas no preenchimento à mão) aceitam uma palavra escrita pelo usuário. O que se escreve não filtra as sugestões; "Add" ("Adicionar") verifica a palavra antes de a aceitar:
- **Não é um nome:** com algarismos, símbolos ou uma letra só, conta como palavra inválida (ver abaixo).
- **Está nas listas da UVVA:** as do catálogo, as do vocabulário de aromas e as palavras aceitas antes no telefone. A comparação ignora maiúsculas e acentos e também aceita o nome na língua do telefone ("goiaba" é Guava). A palavra entra escrita como a lista a escreve.
- **Quase igual a uma palavra da lista** (1 letra de diferença até 6 letras, 2 acima disso): aparece "Did you mean" ("Você quis dizer") com a palavra da lista; tocar nela adiciona-a.
- **Fora das listas:** quem decide é o modelo da Apple no telefone (iOS 26 com Apple Intelligence), que responde se é uma casta, um aroma, um prato, uma região de vinho ou uma denominação reais. Há três erros (2026-11-25):
  - **Palavra inválida** (o modelo diz que não): "This doesn’t look like a valid grape. Try another." ("Esse termo não parece ser nenhuma casta válida, tente outro."), com o nome de cada campo: aroma, prato, região de vinho, denominação.
  - **Modelo indisponível** (iOS anterior ao 26, Apple Intelligence desligado ou ainda a descarregar, iPhone sem suporte, idioma que o modelo não tem): "We couldn’t read it on this iPhone. Turn on Apple Intelligence and try again." ("Não conseguimos ler neste iPhone, ative o Apple Intelligence e tente novamente.").
  - **Erro desconhecido** (o modelo funciona mas não respondeu desta vez): "Something went wrong checking this word. Try again." ("Algo deu errado ao verificar esse termo. Tente novamente.").
  - Em builds de debug, os dois últimos mostram por baixo o motivo exato e o contexto do modelo ("iOS 26.1 · pt-PT · language supported"), que também vai para o log.
- **Aceita:** a palavra entra na nota (numa escolha única, substitui a anterior) e a folha fecha. Se só o modelo a conhecia, fica guardada no telefone e passa a aparecer primeiro nas sugestões das notas seguintes. Chega ao catálogo público com o vinho. Lá, a regra do robô é a mesma de sempre: uma casta, região ou denominação que o catálogo não conhece só entra num vinho quando dois leitores a dão.
- As listas fixas (termo legal, madeiras) só se escolhem: não têm campo de escrita.

**CELLAR-R19 · Guardar.** "Save note" é o único botão no fim da nota e está sempre ativo (2026-11-11). Guarda a entrada no topo do Cellar e mostra "Note saved": Tasted com o veredito, que gera uma avaliação e recalcula o mapa (SHARED-R09, QUIZ-R22); Want to try sem veredito (2026-11-14: a folha de avaliação dá o veredito junto com o "provei", então não existe mais "Yes" sem veredito).

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

**CELLAR-R21a · Não é um vinho.** (2026-11-25) Se houver texto, mas nada nele disser vinho, a leitura para depois do parser: não pergunta ao modelo nem procura no catálogo (que cresce com os scans), e mostra "This doesn't look like a wine", "UVVA read the label, but found no grape, no alcohol by volume and nothing else a wine label says. Photograph the bottle's labels, front and back.", sem as dicas de luz. "Try again" e "Fill in by hand" como na CELLAR-R21. Só conta o que foi lido nas fotos, nunca a leitura do modelo (`WineEvidence`):
- Basta um sinal forte: uma casta, uma palavra para vinho ("vinho", "vin", "espumante"…) ou o álcool escrito como no vinho ("13,5% vol", entre 4,5 e 23%).
- Sem sinal forte, são precisos três fracos: denominação ou região, categoria (DOC, IGP), cor ("branco"), palavra de produtor de vinho ("Quinta", "Château"), sulfitos, termo de envelhecimento, medalha.
- Cerveja, destilados, sidra, vinagre e sumo também têm "% vol" ou "tinto": com uma dessas palavras, só uma casta ou uma palavra para vinho fazem dele um vinho.

**CELLAR-R22 · Câmara recusada.** Se o usuário recusar a câmara, o `+` passa a abrir "The camera is off", "UVVA needs the camera to read labels. Turn it on in Settings, or add the wine by hand." "Open Settings" abre os Ajustes do iOS. "Fill in by hand" abre o preenchimento à mão.

**CELLAR-R23 · Preencher à mão.** (revisto em 2026-11-25) "Type the name and choose the rest from the lists. The type and one more detail draw the map."
- **Escritos:** nome, produtor, ano e álcool. O ano vai de 1900 ao ano corrente e o álcool de 4,5 a 23% vol; fora disso, o campo diz o intervalo e "Continue" fica desativado.
- **Escolhidos em listas (chips):** tipo; região, denominação, castas e notas de prova, com as palavras aceitas antes no telefone e depois os valores do próprio catálogo, os mais frequentes primeiro; nestes quatro também se pode escrever uma palavra, verificada como na CELLAR-R18a; termo legal (Reserva, Grande Reserva…); tempo em madeira (sem madeira, até 6, 6–12, 12–24, mais de 24 meses); madeiras (carvalho francês, americano…), só com tempo em madeira; prémios (concurso ou crítico da lista da CELLAR-R30, medalha ou pontos, ano opcional).
- O rótulo lido preenche o que trouxer, incluindo o tempo em madeira e as madeiras ("18 meses em barricas de carvalho francês").
- A UVVA faz a leitura a partir dos dados, e o fluxo segue no vinho em papel (CELLAR-R18). Ao guardar, o vinho vai para o catálogo público como qualquer leitura; o robô trata do resto. O tempo em madeira e as madeiras aparecem nos factos da nota ("Time in oak").

**CELLAR-R23a · Sem base, não há mapa.** (2026-11-25) O mapa de um vinho fora do catálogo só é desenhado com o tipo e pelo menos uma destas coisas que o catálogo conheça: casta, região ou denominação, nota de prova, tempo em madeira. Nunca é a média do catálogo inteiro nem a média só do tipo. Por ordem: vinhos do tipo com mais castas em comum (da região, se forem pelo menos 3), depois os da região, depois os com mais notas em comum. O tempo em madeira define o eixo Madeira (0,5 / 3 / 5 / 6,5 / 8); sozinho com o tipo, aplica-se à média do tipo.
- No preenchimento à mão, "Continue" fica desativado sem essa base, com a dica "To draw the map, choose the type and at least a grape, region, appellation, tasting note or time in oak." Se o que foi escolhido não encontra nenhum vinho do tipo, a mesma frase aparece como erro.
- Num rótulo lido, um vinho com nome mas sem base abre o preenchimento à mão com o que foi lido.
- O robô aplica a mesma regra a um vinho novo do catálogo público: sem base, espera.

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

**CELLAR-R26 · Conteúdo (2026-11-15).** A nota guardada mostra o vinho só para ler. Não há chips, nem as linhas de intensidade de deslizar (esses são da edição, CELLAR-R27). A ordem depende de a nota ter fotos.

Com fotos, de cima para baixo:
- o nome em maiúsculas desenhadas e, na linha de baixo, o produtor à esquerda e "Added 29 Aug" à direita;
- a capa, com o veredito na frente; só as fotos que a nota tem: uma sozinha ocupa a largura toda;
- o card da certificação (CELLAR-R30);
- os factos: Origin | Producer, Style | Vintage ("2023 · 3 years"), depois Grapes, Notes, Pairings e How to serve (temperatura e frase), quando há;
- só "X% match with your map", sem as frases;
- os dois mapas;
- os eixos em pontos juntos, sem título, como na folha do vinho da Home;
- "Your note", quando há.

Sem fotos, não há capa nem a imagem padrão, e o match vem primeiro:
- o nome, o produtor e "Added 29 Aug", como acima;
- "X% match with your map" e, por baixo, as frases ("High in oak and body, like your map.");
- o card da certificação;
- os factos, Pairings e How to serve;
- os eixos em pontos;
- os dois mapas;
- "Your note", quando há.

Enquanto as fotos são lidas, a nota usa a ordem com fotos só se a Adega já mostrava a miniatura dela; assim a ordem não muda quando as fotos chegam.

No pé, fixos e sempre visíveis, com o papel a desvanecer por baixo: o botão de avaliação (contorno, letra desenhada, "Rate this wine" ou "Your rating: Yes · 4/5"), que abre a folha de avaliação; e por baixo, numa linha, a lupa ("Find the wine", HOME-R09a), "Edit" e a lixeira ("Delete", CELLAR-R28), as duas em botões redondos só com ícone.

Os dados vêm da cópia guardada na entrada e, por trás, do catálogo (How to serve só existe lá).

**CELLAR-R27 · Editar (2026-11-11).** "Edit" fecha a nota e abre a nova nota (CELLAR-R18) já nesse vinho, com tudo editável: a foto, os chips, a intensidade, "Your note" e o link de avaliação ("Your rating: Yes · 4/5", ou "Rate this wine" num vinho Not yet, CELLAR-R18). "Save note" guarda por cima da mesma entrada: um veredito diferente substitui a avaliação (CELLAR-R13b, D8), e a nota fica como foi escrita, mesmo apagada. Fechar a nova nota sem guardar não muda nada.

**CELLAR-R28 · Apagar.** "Delete" pede confirmação: "Delete this note?", "It leaves your cellar and stops counting towards your palate map. This can't be undone." "Delete" apaga a entrada e retira a sua avaliação do mapa. Um vinho que só existia por causa do scan dessa nota sai também do catálogo do aparelho, com tudo o que as leituras lhe juntaram, e a leitura dele que ainda esperava para ir ao catálogo público deixa de ser enviada; assim um scan ruim não volta no próximo. Um vinho do catálogo da UVVA fica (2026-11-13). "Cancel" fecha a folha e mantém a nota.

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
