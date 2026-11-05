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
