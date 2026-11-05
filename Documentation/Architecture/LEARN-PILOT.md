# Learn: arquitetura de Features

A Feature mantém as três listas, pesquisa, filtros, retoma das lições e certificados. A composição passa por `LearnFactory`, chamada pelo AppCoordinator.

## Responsabilidades

- `LearnViewModel`: estado das listas, filtros, pesquisa e ações do ecrã.
- `LearnListPresentationBuilder` e `LearnSearchPresentationBuilder`: cálculo puro das listas e resultados. As extensões do ViewModel apenas expõem os resultados e encaminham ações.
- `LearnCoordinator`: pilha dos players, transições entre lições e apresentação de certificados. Aguarda a gravação antes de mudar de lição.
- `LessonPlayerFactory`: construção do player com os contratos e callbacks necessários.
- `LessonPlayerViewModel`: estado e interação da lição. Mantém a fila de gravações e `flush`, delegando persistência ao contrato de caso de uso.
- `CertificatePresentationBuilder`: formatação dos dados do certificado.
- `LearnState`/`LearnContent`: dados partilhados entre a lista e o fluxo de lições, sem operações ou navegação.

## Casos de uso

`LoadLearnUseCase` carrega cursos, progresso, certificados e nome, preservando dados anteriores quando as leituras falham. `LoadLessonUseCase` obtém uma lição. `SaveLessonProgressUseCase` persiste o progresso e `RefreshProgressUseCase` atualiza a leitura. `CompleteCourseUseCase` verifica a conclusão e persiste um novo certificado antes de o disponibilizar. `LoadCertificateSkillsUseCase` obtém os pontos do resumo da lição de revisão.

Os ViewModels e o Coordinator recebem contratos; apenas as Factories conhecem as implementações concretas. Os callbacks do player capturam o Coordinator fracamente para evitar ciclos de retenção.

## Organização

A raiz contém `Coordinator`, `DependencyInjection`, `State`, `Screens` e `Resources`. O ViewModel das listas e as suas extensões ficam em `Screens/Learn/ViewModel`. Builders e casos de uso pertencem ao ecrã respetivo. A extensão de partilha de certificados fica em `Screens/Certificates/Extensions`.

## Validação

Os testes existentes continuam a cobrir pesquisa, filtros, retoma, gravação de respostas, revisão sem XP extra, atribuição de certificados e regresso à lição anterior. Foram acrescentados cenários de falha de recarregamento, falha ao atribuir certificado e tentativa de abrir uma lição inexistente.

## UIModels e protocolos observáveis

Learn e o player usam agora `ObservableObject`, `@Published private(set) uiModel` e protocolos próprios. As Views são genéricas e usam `@ObservedObject`; o protocolo de Learn expõe o player através de um associated type, sem fixar a implementação concreta na View.

`LearnUIModel` agrupa listas, filtros, região, pesquisa, estado de apresentação do player, certificado e recursos. `LessonPlayerUIModel` agrupa capa, cabeçalho, passo, footer, certificado e estados visuais. O ViewModel do player preserva a lógica e a fila de gravações, publicando uma apresentação atualizada quando mudam fase, respostas ou certificado. Os modelos específicos de cada passo continuam a ser valores.

`LearnResourcesUIModel` centraliza os textos e identificadores visuais dos componentes. As Views mantêm layout, scroll, gestos e animações. Os bindings de pesquisa passam por `updateQuery`.

`LearnState` publica dados e o Coordinator expõe publishers de players e certificados. As subscrições fracas no ViewModel publicam a apresentação correspondente. A reconstrução de listas usa o valor emitido, evitando reler o valor anterior de `@Published`; os campos das listas são publicados em conjunto. O modifier de certificados observa explicitamente o ViewModel, para continuar a funcionar quando invocado a partir de You.

O preview de Learn usa mocks dos protocolos sem repositórios. Os testes adicionais verificam publicação de pesquisa/filtros/navegação e de seleção/feedback do player. Foram validados 54 testes de Learn e a regressão de Home, Onboarding e You.
