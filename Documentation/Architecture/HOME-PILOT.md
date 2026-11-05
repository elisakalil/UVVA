# Home: piloto de arquitetura de Features

A Home mantém SwiftUI e Observation, com responsabilidades separadas:

- `HomeFactory`: compõe os casos de uso e o ViewModel a partir dos contratos dos repositórios.
- `LoadHomeUseCase`: lê os dados e prepara vinhos com harmonização e progresso dos cursos. Retorna `LoadedHomeContent`, sem modificar estado visual.
- `AddWineToCellarUseCase`: grava um vinho no Cellar.
- `HomeViewModel`: gere carregamento, publica apresentação e encaminha ações.
- `HomeCardsBuilder`: constrói os cartões de apresentação de forma pura.
- `HomeCoordinatorProtocol`: contrato de navegação da Home.
- `HomeCoordinator`: encaminha destinos para a aplicação através de callbacks, sem importar outras Features.

O `AppCoordinator` cria a Home através da factory e mantém a navegação entre funcionalidades. Os contratos dos casos de uso são internos à Feature; o contrato de navegação e a factory são públicos para composição pela aplicação.

## Convenções para as próximas Features

Organizar por ecrã, com `Views`, `ViewModel`, `Models` e `UseCases`; manter a composição em `DependencyInjection/Factory` e a coordenação de fluxo em `Coordinator`. Cada função deve expressar um objetivo e delegar detalhes a componentes coesos. Extensões, por si só, não dividem responsabilidades.

Não é necessário criar um ViewModel por componente visual. Componentes puramente visuais continuam a receber valores e ações. Regras de domínio partilhadas permanecem no Core/Match; casos de uso específicos ficam na Feature.

## Comportamento preservado

Mantêm-se a seleção diária, a harmonização em background, os cursos iniciados, os cartões vazios de funcionalidades futuras, o carregamento partilhado entre chamadas concorrentes e a marcação de vinhos guardados após sucesso. Falhas opcionais de progresso continuam a produzir os mesmos valores de fallback. A alteração não introduz uma nova política de erros ou de tarefas em background.

## Organização dos auxiliares do ecrã

- `Builders/HomeCardsBuilder`: composição dos cartões de apresentação.
- `Helpers/WineSearch`: construção da pesquisa e URL do vinho, sem executar navegação ou pedidos de rede.
- `Extensions/PalateRadar+PalateMap`: adaptação do modelo de domínio para o radar.
- `Views/Shapes/ArgentinaOutline`: forma gráfica usada na interface.
- `Views/Modifiers/SpotlightModifier`: comportamento visual de destaque para o tour.

A raiz de `Screens/Home` contém apenas pastas. Estes auxiliares permanecem locais ao ecrã enquanto não existir necessidade de partilha.

O GuidedTour está organizado em `Rules/GuidedTour`, `Models/TourStep`, `Models/HomeSpotlightModel`, `Views` e `ViewModel`, uniformizando os nomes das pastas.

## UIModel e protocolo de apresentação

A Home usa agora `HomeViewModelProtocol: ObservableObject`, `@Published public private(set) var uiModel` e `HomeView<ViewModel: HomeViewModelProtocol>` com `@ObservedObject`. O protocolo expõe apenas a apresentação de leitura e as ações consumidas pela View. `prepare()` continua disponível no ViewModel concreto para a preparação pela aplicação.

`HomeUIModel` reúne conteúdo opcional, loading, link e mensagem de convite, chaves dos vinhos guardados e recursos visuais. O antigo agregado de cartões/mapa chama-se `HomeContentUIModel`. `HomeResourcesUIModel` centraliza textos localizados, opções e identificadores de ícones, sendo passado explicitamente aos componentes. `DailySuggestionUIModel`, `PalateMatchUIModel` e `WineFactsUIModel` encapsulam apresentação derivada dos dados dos componentes.

As Views mantêm layout, animação, foco, expansão e posição do scroll. Componentes puramente visuais continuam a receber valores, sem ganhar ViewModels artificiais. A gravação no Cellar continua com o mesmo comportamento: esta refatoração não liga o botão visual que já era um placeholder.

O preview da Home usa um mock do protocolo sem dependências de dados. Os testes verificam também a emissão de alterações do UIModel para loading, conteúdo e vinhos guardados. O GuidedTour também usa um UIModel publicado, conforme descrito abaixo.

## GuidedTour observável

O tour foi migrado para `GuidedTourViewModelProtocol: ObservableObject`, com `GuidedTourUIModel` publicado e Views genéricas com `@ObservedObject`. O UIModel reúne etapa, alvo/fallback, contador, títulos, introdução, acessibilidade e ícone de voltar. `GuidedTour` continua a definir as transições e `TourStep` os conteúdos das etapas.

A Home usa um observador explícito do UIModel do tour para encaminhar mudanças do alvo ao conteúdo e manter o scroll sincronizado. A overlay observa o mesmo ViewModel diretamente. O preview usa um mock do protocolo e o teste adicional verifica alvos, retrocesso e publicação da conclusão.
