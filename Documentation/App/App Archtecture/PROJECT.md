# UVVA · Arquitetura da app

> Status: v0.1 · 2026-10-31
> Backend (CloudKit e SwiftData): [`ARCHITECTURE.md`](../../Architecture/ARCHITECTURE.md). Match de vinho, usuário e receita: [`MATCH.md`](../Features/Shared/MATCH.md).

## 1. Stack

- **SwiftUI**, iOS 18 ou mais recente
- **Swift 6**, com concorrência estrita
- **MVVM**
- **Modularizada com Swift Package Manager** (secção 4)
- **Testes com Swift Testing** (`@Test`, `#expect`), um teste por critério de aceitação, com o ID da regra no nome (`HOME_R07_sameDay_sameSuggestion`)

## 2. Orientação ao modelo

O padrão principal é a orientação ao modelo: **toda tela e todo componente tem um `UIModel`** que guarda os dados e os estados que ele mostra. A View só desenha o `UIModel`; não calcula nada.

| Peça | Responsabilidade |
| --- | --- |
| `UIModel` | Os dados e estados prontos para desenhar (textos, listas, ativo/inativo, carregando, vazio, erro). Struct, sem lógica |
| `ViewModel` | Lê os dados, aplica as regras e produz o `UIModel`. Recebe as ações da View |
| `View` | Desenha o `UIModel` e envia as ações ao `ViewModel` |

```swift
struct ProgressUIModel {
    var grapes: Int
    var regions: Int
    var lessons: Int
    var state: State
}

@Observable final class ProgressViewModel {
    private(set) var model: ProgressUIModel
    func onAppear() { … }
}

struct ProgressView: View {
    @State var viewModel: ProgressViewModel
    var body: some View { … }   // usa só viewModel.model
}
```

Um componente reutilizável recebe o seu `UIModel` pronto e não tem `ViewModel`:

```swift
struct WineCardUIModel { var name: String; var origin: String; var verdict: String? }
struct WineCard: View { var model: WineCardUIModel }
```

## 3. Regras

**APP-R01 · Uma entidade por arquivo.** Toda struct, class, enum ou protocol fica num arquivo próprio, com o mesmo nome (`ProgressUIModel.swift`, `Verdict.swift`). Nenhum arquivo junta vários enums ou structs.

**APP-R02 · Design system.** Um componente usado fora da sua feature vai para `DesignSystem/`. Um componente usado só dentro de uma feature fica na feature.

**APP-R03 · Uma pasta por feature.** As features são Home, Onboarding, Quizz, You, Friends, Cellar e Learn.

**APP-R04 · Uma pasta por tela.** Dentro de cada feature, `Screens/` tem uma pasta por tela. Tudo o que é só de uma tela (View, ViewModel, UIModel, componentes dela) fica na pasta dessa tela. O que é partilhado entre as telas da feature fica na raiz da feature.

## 4. Módulos (SPM)

**APP-R05 · Packages locais.** A app é dividida em três packages locais do Swift Package Manager: `Core`, `DesignSystem` e `Features`. O target da app só monta os packages e a navegação entre eles.

| Package | Módulo | O que tem | Depende de |
| --- | --- | --- | --- |
| `Core` | `Core` | As entidades partilhadas (`PalateAxis`, `PalateMap`, `Verdict`, `Wine`…) e os protocolos dos serviços. Só Foundation | — |
| `Core` | `Match` | O algoritmo de match: usuário × vinho, vinho × receita, usuário × usuário (`Shared/MATCH.md`) | `Core` |
| `Core` | `Storage` | Os modelos SwiftData das duas lojas, o import do conteúdo do bundle e o acesso ao CloudKit (`ARCHITECTURE.md`) | `Core`, `Match` |
| `DesignSystem` | `DesignSystem` | Tokens, fontes, a foto de fundo e os componentes reutilizados (APP-R02) | — |
| `Features` | `Features` | Só reúne as features: `import Features` dá acesso a todas (`@_exported import`). É o único módulo de feature que o target da app importa | as features |
| `Features/Home`, `Features/Onboarding`, `Features/Quizz`, `Features/You`, `Features/Friends`, `Features/Cellar`, `Features/Learn` | um por feature | Cada feature tem a sua pasta e o seu próprio `Package.swift`, com as suas telas | `Core` (módulos `Core` e `Match`), `DesignSystem` |

Uma feature nova entra em `Packages/Features/Package.swift` (dependência e target `Features`) e em `Features.swift`; o projeto do Xcode não muda (ver secção 6 para os testes).

`DesignSystem` e `Core` não são features, mas precisam ser packages: um package de feature não consegue importar código que está no target da app.

**APP-R08 · Domínio sem plataforma.** `Core` e `Match` usam só Swift e Foundation: nada de SwiftUI, SwiftData, CloudKit ou UIKit. Assim os testes correm com `swift test` e o código pode ser reaproveitado noutra plataforma (Android). As features nunca importam `Storage`: recebem os protocolos de `Core`, e o target da app injeta as implementações.

**APP-R09 · `PalateAxis`.** O eixo do mapa chama-se `PalateAxis`, e não `Axis`, porque o SwiftUI já tem um tipo `Axis`.

**APP-R06 · Features não se importam.** Um package de feature nunca importa outro. Quando uma feature abre outra (por exemplo, a Home abre You › Map), ela pede a rota ao target da app, que faz a navegação.

**APP-R07 · Testes por package.** Cada package tem os seus testes. O `Match` e o `Core` não dependem de UI, por isso os testes deles correm com `swift test`, sem simulador.

## 5. Pastas

```
Application/
├── UVVA.xcworkspace        Abrir sempre este (secção 6)
├── UVVA.xcodeproj          Target da app
├── UVVA/
│   ├── App/                Entrada e navegação entre features
│   ├── Resources/Content/  Conteúdo do bundle, gerado a partir de Data/
│   └── Assets.xcassets     Ícone da app e cor de destaque
├── Data/                   Fonte editável do conteúdo (vinhos, receitas, lições)
└── Packages/
    ├── Core/               Package com os módulos Core, Match e Storage
    │   ├── Sources/{Core,Match,Storage}/
    │   └── Tests/{CoreTests,MatchTests,StorageTests}/
    ├── DesignSystem/       Inclui as fontes e a foto de fundo (Resources/)
    └── Features/
        ├── Package.swift   Reúne as features num só módulo
        ├── Sources/Features/Features.swift
        ├── Home/           Cada feature com o seu Package.swift
        ├── Onboarding/
        ├── Quizz/
        ├── You/
        ├── Friends/
        ├── Cellar/
        └── Learn/
```

Exemplo de um package de feature:

```
Features/You/
├── Package.swift
├── Tests/
└── Sources/You/
    ├── YouViewModel.swift      partilhado pelas telas de You
    ├── YouTab.swift
    └── Screens/
        ├── Progress/
        │   ├── ProgressView.swift
        │   ├── ProgressViewModel.swift
        │   └── ProgressUIModel.swift
        ├── Map/
        │   ├── MapView.swift
        │   ├── MapViewModel.swift
        │   └── MapUIModel.swift
        └── Settings/
            ├── SettingsView.swift
            ├── SettingsViewModel.swift
            └── SettingsUIModel.swift
```

## 6. Abrir, correr e testar

- Abrir **`Application/UVVA.xcworkspace`**, e não o `.xcodeproj`. O workspace junta o projeto e os packages, e é ele que deixa o scheme **UVVA** correr os testes de todos os packages com ⌘U.
- O projeto só conhece os três packages (`Core`, `DesignSystem`, `Features`). Uma feature nova entra em `Features/Package.swift` e `Features.swift`. Para o ⌘U do scheme UVVA correr os testes dela, entra também no workspace (`contents.xcworkspacedata`, como `Packages/Features/<Nome>`) e nos *Testables* do scheme: o Xcode só encontra os test targets de packages que estão na raiz do workspace.
- Depois de mudar algo em `Application/Data`, correr `python3 Application/Scripts/pack_content.py` para gerar de novo o conteúdo do bundle. Os arquivos gerados em `UVVA/Resources/Content/` nunca se editam à mão.
- Pelo terminal:
  - `swift test` dentro de `Packages/Core` corre os testes de `Core`, `Match` e `Storage` (sem simulador, APP-R07).
- **Modo de demonstração (só Debug).** Com o argumento `-UVVADemoAccount` (Xcode › Edit Scheme › Run › Arguments), a app usa uma conta Apple falsa ("Elisa"), assume o iCloud ligado e mostra dois contatos como estando na UVVA. Serve para percorrer o Onboarding no simulador sem Apple ID. Nunca entra num build de Release.
- **O que é da plataforma fica no target da app:** Sign in with Apple (`App/Account`), o modo de demonstração (`App/Debug`) e o coordenador. Os packages recebem protocolos de `Core` (`Authenticating`, `ProfileRepository`, `SocialService`, `CloudAccountStatus`).
  - `xcodebuild -workspace UVVA.xcworkspace -scheme UVVA -destination 'platform=iOS Simulator,name=iPhone 17 Pro' test` para tudo.
