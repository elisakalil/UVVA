# Plano · Cellar, nova nota pela foto do rótulo

> Status: proposta · 2026-11-08
> Spec: [`CELLAR.md`](../Features/Cellar/CELLAR.md) §4 (CELLAR-R13a a R25). Design: canvas "UVVA Telas", artboard Cellar (telas `front`, `back`, `reading`, `permission`, `error`, `denied`, `manual`, `note`, `discard`, `first`) e Main (`scanned`).
> Parte C do Cellar. As partes A (aba) e B (nota guardada) já estão feitas.

## 1. O que existe hoje

| Peça | Estado |
| --- | --- |
| `+` do Cellar | Desenhado e inativo (`CellarView`, `resources.addText` = "Scan a label") |
| `+` da Home | `Button {}` vazio (`HomeHeader`, HOME-R03) |
| `CellarRepository` | `addWantToTry` e `addTasted(_ wine:, verdict:)` só para vinhos do catálogo. Não guarda fotos nem nota |
| `CellarEntryEntity` | Já tem `photoFront` e `photoBack` (`.externalStorage`) e `note` |
| Mapa | `MapUpdate.apply` + `saveRatedMap` (avaliar), `MapRebuild` + `rewriteHistory` (refazer, CELLAR-R29) |
| Leitura da UVVA na nota | `NoteReading`, construída a partir do `Wine` do catálogo (`WineLookup`) |
| Edição da nota | `NoteView` em modo edição: título, "Would you drink it again?", capa, dados, leitura, "Your note". É quase a tela `note` (New note) do design |
| `wineKey` | Só em Python (`Scripts/pack_content.py`, `wine_key`). Não há versão em Swift |
| Câmara | Nada. Falta o `NSCameraUsageDescription` |

## 2. A leitura do rótulo, sem custo

A spec diz que a leitura é um serviço externo que precisa de internet (CELLAR-R17, §6). Mas a ARCHITECTURE §6 fixa custo zero, e qualquer API de visão ou LLM na nuvem é paga. A proposta é ler tudo no aparelho:

1. **Texto (Vision).** `RecognizeTextRequest` (iOS 18, `.accurate`, idiomas pt, en, fr, it, es e de) nas duas fotos. Devolve linhas com o texto, a caixa e a confiança. É grátis e funciona sem rede.
2. **Dados (`LabelParser`, Core).** Swift puro, testável com `swift test`. Tira das linhas:
   - o ano (`19xx` ou `20xx` plausível);
   - o álcool (`13,5 % vol`, `13.5% alc.`);
   - o tipo, por palavras-chave (tinto, red, rouge, rosso → Red; branco, blanc, bianco → White; rosé; espumante, champagne, cava, prosecco → Sparkling; porto, port, sherry, madeira → Fortified);
   - as castas, a região e o país, comparando com o vocabulário do catálogo;
   - nome e produtor como candidatos: as linhas maiores da frente.
3. **Catálogo (`LabelMatch`, Match).** Procura nos 10 000 vinhos locais pelos tokens da frente (nome e produtor, sem acentos), com bónus para o mesmo ano.
   - **Encontrado:** usa o `Wine` do catálogo. Os dados e a leitura da UVVA ficam completos.
   - **Mesmo vinho, outro ano:** usa o perfil do catálogo com o ano do rótulo. Isso dá outra `wineKey` (CELLAR-R13a).
4. **Fora do catálogo (`ProfileEstimate`, Match).** Estima o mapa de 8 eixos pela média dos vinhos do catálogo com a mesma casta e o mesmo tipo. Se não houver, usa a mesma região e o mesmo tipo; em último caso, só o tipo. Com esse perfil, a leitura da UVVA e o efeito no mapa funcionam como para um vinho do catálogo.
5. **Foundation Models (iOS 26).** Quando o modelo do aparelho está disponível, ele arruma o texto do Vision num `@Generable` (nome, produtor, ano, tipo, castas, região, país, álcool). O resultado passa pelo mesmo `LabelMatch` e pela mesma `ProfileEstimate`. Também é grátis e corre sem rede. Atrás do protocolo `LabelStructuring` (Core), com a implementação no target da app sob `if #available(iOS 26, *)`. Sem o modelo (iOS 18, aparelho sem Apple Intelligence, modelo ainda a descarregar), a app usa só o `LabelParser`.

Um vinho fora do catálogo entra na Loja Conteúdo local, marcado como escaneado. Assim, `WineLookup`, a nota guardada e o `MapRebuild` encontram-no como qualquer outro. O `ContentImporter` já protege as `wineKey` do Cellar (`upsertWines(_:protecting:)`); falta confirmar que também não apaga vinhos que não vieram do bundle. Enviar o `CatalogWine` `pending` para a base pública (ARCHITECTURE §4.3) fica para depois (§8).

**Consequência na spec:** a leitura deixa de precisar de internet. A dica "Connection" da CELLAR-R21 deixa de fazer sentido (ver decisão L1).

## 3. Onde vive o fluxo

- **Package:** `Features/Cellar`, em `Screens/NewNote`. O `+` da Home não pode importar o Cellar (APP-R06), por isso:
  - a Home ganha `onScan` (ação do `HomeViewModel`, entregue ao `AppCoordinator`);
  - o Cellar ganha `onAdd`, também entregue ao coordinator;
  - o `AppCoordinator` tem `newNote: NewNoteViewModel?` e apresenta `NewNoteView` em `fullScreenCover` sobre o `RootTabView`. É um fluxo só para os dois `+` (CELLAR-R14).
- **Plataforma fora das features e do Core** (APP-R08):
  - `LabelReading` (protocolo no Core: fotos → linhas de texto). A implementação com Vision fica no target da app (`UVVA/Services/VisionLabelReader.swift`) e é injetada pela `CellarFactory`.
  - `CameraAuthorizing` (protocolo no Core: estado e pedido). A implementação com AVFoundation fica no target da app.
- **Câmara na view:** `LabelCameraView` (`UIViewRepresentable` com `AVCaptureVideoPreviewLayer` e `AVCapturePhotoOutput`) dentro do Cellar. É só SwiftUI e AVFoundation, sem lógica.
- **Simulador:** não tem câmara. Em `#if targetEnvironment(simulator)` o obturador usa duas fotos de rótulo de exemplo (Debug), para dar para testar o fluxo inteiro e tirar capturas.

## 4. Domínio (Core e Match, `swift test`)

| Tipo | Package | Para quê |
| --- | --- | --- |
| `WineKey.make(producer:name:vintage:)` | Core | Porta da `wine_key` do Python. Teste de paridade com chaves reais do `UVVAWines.json` (CELLAR-R13a) |
| `LabelText`, `LabelLine` | Core | O que o Vision devolve: texto, caixa, confiança, frente ou verso |
| `LabelFacts` | Core | Os dados lidos: nome, produtor, ano, tipo, região, país, castas, álcool |
| `LabelParser` | Core | Linhas → `LabelFacts` (§2.2) |
| `LabelMatch` | Match | `LabelFacts` + catálogo → `Wine?`, com limiar de confiança |
| `ProfileEstimate` | Match | Castas, tipo e região → `PalateMap` (§2.4) |
| `NewNoteDraft` | Core | O vinho, o estado, o veredito, a nota e as duas fotos |
| `CellarRepository.save(_ draft:, at:)` | Core / Storage | Cria ou atualiza pela `wineKey`, com as regras da CELLAR-R13b: fotos e nota novas substituem, um campo vazio não apaga, Tasted nunca volta a Not yet, `createdAt` fica igual, `updatedAt` muda |
| `CatalogSearch.candidates(tokens:)` | Core / Storage | Candidatos do catálogo para o `LabelMatch`. Pode ser um scan em memória no actor: são 10 000 vinhos |
| `ScannedWineSaving.addScanned(_ wine:)` | Core / Storage | Põe o vinho escaneado na Loja Conteúdo local |
| `CameraAuthorizing`, `LabelReading` | Core | Protocolos da §3 |

## 5. Feature: `Screens/NewNote`

**Máquina de estados `NewNoteFlow`** (struct pura, testada sem UI):

```
checking → permission (1.ª vez) ──recusa──→ denied
        └→ front → back → reading ─┬─ found ───→ note(.asking)
                                   ├─ unsure ──→ manual (pré-preenchido, L2)
                                   └─ failed ──→ error
manual ──Continue──→ reading da mão → note(.asking)
note(.asking) ─ Yes ───→ note(.tasted)   verdict obrigatório, nota opcional → Save note
              └ Not yet → note(.notYet)  Add to cellar · Find it
Redo (front, back, note) → front, sem fotos nem leitura      (R24)
× antes de guardar → "Discard this note?"                    (R25)
error: Try again → front · Fill in by hand → manual           (R21)
denied: Open Settings · Fill in by hand                       (R22)
```

**ViewModel e use cases**

- `NewNoteViewModel` e o seu protocolo publicam um `NewNoteUIModel`.
- `CheckCameraUseCase` e `RequestCameraUseCase`.
- `ReadLabelUseCase`: reader → parser → match → estimate. Devolve `found(Wine)`, `unsure(LabelFacts)` ou `failed`.
- `ReadManualUseCase`: os campos escritos → match → estimate (CELLAR-R23).
- `SaveNewNoteUseCase`:
  - guarda o escaneado no catálogo, se for novo, e depois `cellar.save(draft)`;
  - Tasted, vinho sem avaliação: `MapUpdate.apply` + `saveRatedMap` (CELLAR-R19);
  - Tasted, vinho já avaliado: troca a avaliação antiga pela nova com o `RecalculateMap` que já existe (CELLAR-R13b, D8);
  - Not yet: só a entrada, sem avaliação (CELLAR-R20).

**Views**

| View | Tela do design | Notas |
| --- | --- | --- |
| `NewNoteCaptureView` | `front`, `back`, `reading` | Fundo de câmara, `×`, "UVVA \| NEW NOTE", título e subtítulo, passos "01 Front" e "02 Back label", obturador. Em `reading`, a segunda foto parada com "Reading your label" |
| `NewNoteMessageView` | `error`, `denied` | Fundo escuro, título, texto, dicas numeradas, botão principal e "Fill in by hand" |
| `NewNoteManualView` | `manual` | Papel. Nome, produtor, ano, região, casta e tipo. Continue só com nome (CELLAR-R23) |
| `NewNoteView` (papel) | `note` | Reaproveita as peças da `NoteView`: `NoteCover`, `NoteFacts`, `NoteReading`, `NoteVerdictPicker` e o campo "Your note". Por cima, "Have you had this wine?" (L3) |
| `NewNoteDiscardSheet` | `discard` | Mesmo padrão da `NoteDeleteSheet` |

- **Depois de guardar:** fecha a capa, muda para a aba Cellar, recarrega o Cellar e o estado da Home, e mostra o toast "Note saved" (tela `first`).
- **Textos:** todos em `NewNoteResourcesUIModel`, com chaves no `Localizable.xcstrings` do Cellar.

## 6. Integração

1. `INFOPLIST_KEY_NSCameraUsageDescription` = "UVVA photographs the front and back label to read the wine." (CELLAR-R15).
2. `CellarFactory.makeNewNote(onSaved:onClose:)` com as novas dependências: `reader`, `camera`, `catalogSearch` e `scannedWines`. O `AppCoordinator` cria-a com as implementações da app e do Storage.
3. `+` do Cellar: ativo, chama `onAdd`. `+` da Home: chama `onScan`. A ação do tour da Home (`HomeSpotlightID.scan`) continua igual.
4. "Open Settings": `UIApplication.openSettingsURLString`. "Find it": a mesma pesquisa da Home (`WineSearch.url`). Ela está no package Home, por isso passa a ficar duplicada no Cellar ou sobe para o Core (ver L4).

## 7. Testes

| Onde | Testes |
| --- | --- |
| CoreTests | `WineKey` (paridade com o Python, acentos, sem ano); `LabelParser` (ano, álcool com vírgula e com ponto, tipo em 5 línguas, castas e região pelo vocabulário, texto vazio) |
| MatchTests | `LabelMatch` (encontra com o texto com ruído, outro ano, abaixo do limiar dá `unsure`); `ProfileEstimate` (casta + tipo, recua para região e depois para tipo) |
| StorageTests | `save(draft)` e as quatro regras da R13b; `addScanned` não é apagado pelo importer |
| CellarTests | `NewNoteFlow` com cada critério da §4 da spec (R15, R20, R21, R22, R23, R24, R25); `SaveNewNote`: 1 entrada Tasted + 1 avaliação; Not yet sem avaliação; mesmo vinho com outro veredito = 1 entrada e mapa recalculado uma vez; Discard não grava nada |
| Simulador | Fluxo completo com as fotos de exemplo: encontrado, fora do catálogo, falha, à mão, Redo, Discard, câmara recusada. Capturas comparadas com o artboard |

Uma foto real só se testa no iPhone. O simulador cobre o fluxo, não a qualidade da leitura.

## 8. Ordem de trabalho

| # | Etapa | Depende de |
| --- | --- | --- |
| C1 | Domínio: `WineKey`, `LabelParser`, `LabelMatch`, `ProfileEstimate` + testes. **Feito em 2026-11-08**, com um teste contra o catálogo real | — |
| C2 | Storage: `save(draft)`, `LabelCatalogRepository` (`allWines`, `addScanned`) + testes. **Feito em 2026-11-08.** Um escaneado tem `source = scanned`, o importer nunca o apaga e passa-o a `bundle` quando o bundle o trouxer. Limite: a Loja Conteúdo não sincroniza, por isso noutro iPhone o escaneado perde o perfil estimado (a entrada do Cellar mantém os dados) | C1 (`WineKey`) |
| C3 | `NewNoteFlow` + use cases + testes, com doubles para leitor e câmara. **Feito em 2026-11-08.** Protocolos `CameraAuthorizing`, `LabelReading` e `LabelStructuring` no Core; `ScannedWine` no Match; `PrepareCamera`, `ReadLabel`, `ReadManual` e `SaveNewNote` no Cellar. O `×` só pede confirmação quando há algo a perder (fotos, leitura ou texto escrito) | C1 |
| C4 | Views da captura, mensagens, à mão e papel; previews com mocks. **Feito em 2026-11-08.** `NewNoteViewModel` + builder, `LabelCamera` (AVFoundation), `CellarPaperSheet` partilhada com o Delete, `WineSearch` movido para o Core. No simulador, o obturador desenha um rótulo do catálogo (Isole e Olena Chianti Classico 2010), por isso não são precisas fotos de exemplo. Ainda não ligado à app nem visto no ecrã | C3 |
| C5 | App: Vision, AVFoundation, Info.plist, coordinator, os dois `+`, toast. **Feito em 2026-11-08.** `VisionLabelReader`, `DeviceCamera` e `DeviceLabelStructurer` (Foundation Models, iOS 26) em `UVVA/App/Services`; `NSCameraUsageDescription`; o `AppCoordinator` abre a nova nota dos dois `+` e, ao guardar, vai para o Cellar com "Note saved" e recarrega a Home. Visto no simulador: pedido da câmara, frente, contrarrótulo, leitura encontrada no catálogo, Yes + Maybe, Save note, Discard | C2, C4 |
| C6 | Verificação no simulador e no iPhone | C5 |
| Depois | `CatalogWine` `pending` na base pública (ARCHITECTURE §4.3) | C5 |

C1 e C3 podem andar em paralelo. C2 só precisa do `WineKey`.

## 9. Decisões para a Elisa

> 2026-11-08: todas aprovadas como propostas.
> - **L1:** sem internet e sem nuvem. Primeiro o catálogo; fora dele, dados e mapa pela média dos semelhantes, com o Foundation Models a estruturar o texto.
> - **L3:** opção B, no papel da nova nota.

| # | Pergunta | Proposta |
| --- | --- | --- |
| L1 | Leitura no aparelho (Vision + catálogo, grátis, sem rede) em vez de serviço externo? | Sim. Muda a CELLAR-R17 (sem "precisa de internet"). Na CELLAR-R21, a dica 2 "Connection" troca para "Whole label: fit the label flat and inside the frame" |
| L2 | Quando a leitura não tem certeza (vinho fora do catálogo), o que aparece? | O "Fill in by hand" já preenchido com o que foi lido, para confirmar. Evita guardar um nome mal lido |
| L3 | Onde fica "Have you had this wine?" | No papel da nova nota, reaproveitando a `NoteView`. O design usa a ficha da Home em ecrã cheio, o que obrigaria a tirar o `WineDetailView` da Home para um target partilhado |
| L4 | D6, "find it" | A mesma pesquisa web do "Find wine" da Home, com o `WineSearch` movido para o Core |
| L5 | D12, o mesmo vinho | Igualdade da `wineKey` (produtor + nome + ano), como na ARCHITECTURE §2.2. Sem ano ou sem produtor, a chave fica sem essa parte |
| L6 | D8 com R13b: avaliar de novo o mesmo vinho troca a avaliação antiga? | Sim, com o recálculo da CELLAR-R29 (já feito na parte B) |
