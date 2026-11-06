# Learn: arquitetura de Features

A Feature mantém as três listas, pesquisa, filtros, retoma das lições e certificados. A composição passa por `LearnFactory`, chamada pelo AppCoordinator.

## Responsabilidades

- `LearnViewModel`: estado das listas, filtros, pesquisa e ações do ecrã.
- `LearnListPresentationBuilder` e `LearnSearchPresentationBuilder`: cálculo puro das listas e resultados. As extensões do ViewModel apenas expõem os resultados e encaminham ações.
- `LearnCoordinator`: pilha dos players, transições entre lições e apresentação de certificados. Todas as saídas passam por `persistDeparture`, que aguarda a gravação antes de dispensar ou trocar o player.
- `LessonPlayerFactory`: construção do player com os contratos e callbacks necessários.
- `LessonPlayerViewModel`: estado em memória e interação da lição. `saveOnExit` captura o passo exibido e as respostas confirmadas e delega a gravação ao caso de uso numa tarefa em background. Não grava durante o avanço entre passos.
- `CertificatePresentationBuilder`: formatação dos dados do certificado.
- `LearnContentModel`: agregado de dados de cursos, progresso, certificados e nome, possuído pelo `LearnViewModel`.

## Casos de uso

`LoadLearnUseCase` carrega cursos, progresso, certificados e nome, preservando dados anteriores quando as leituras falham. `LoadLessonUseCase` obtém uma lição. `SaveLessonProgressUseCase` persiste o progresso e `RefreshProgressUseCase` atualiza a leitura. `CompleteCourseUseCase` verifica a conclusão e persiste um novo certificado antes de o disponibilizar. `LoadCertificateSkillsUseCase` obtém os pontos do resumo da lição de revisão.

Os ViewModels e o Coordinator recebem contratos; apenas as Factories conhecem as implementações concretas. Os callbacks do player capturam o Coordinator fracamente para evitar ciclos de retenção.

## Organização

A raiz contém `Coordinator`, `DependencyInjection`, `State`, `Screens` e `Resources`. O ViewModel das listas e as suas extensões ficam em `Screens/Learn/ViewModel`. Builders e casos de uso pertencem ao ecrã respetivo. A extensão de partilha de certificados fica em `Screens/Certificates/Extensions`.

## Validação

Os testes existentes continuam a cobrir pesquisa, filtros, retoma, gravação de respostas, revisão sem XP extra, atribuição de certificados e regresso à lição anterior. Foram acrescentados cenários de falha de recarregamento, falha ao atribuir certificado e tentativa de abrir uma lição inexistente.

## UIModels e protocolos observáveis

Learn e o player usam agora `ObservableObject`, `@Published private(set) uiModel` e protocolos próprios. As Views são genéricas e usam `@ObservedObject`; o protocolo de Learn expõe o player através de um associated type, sem fixar a implementação concreta na View.

`LearnUIModel` agrupa listas, filtros, região, pesquisa, estado de apresentação do player, certificado e recursos. `LessonPlayerUIModel` agrupa capa, cabeçalho, passo, footer, certificado e estados visuais. O ViewModel do player preserva a lógica e o estado em memória, publicando uma apresentação atualizada quando mudam fase, respostas ou certificado. Os modelos específicos de cada passo continuam a ser valores.

`LearnResourcesUIModel` centraliza os textos e identificadores visuais dos componentes. As Views mantêm layout, scroll, gestos e animações. Os bindings de pesquisa passam por `updateQuery`.

`LearnViewModel` possui o `LearnContentModel`. O Coordinator recebe uma função de leitura e comunica resultados de progresso/conclusão por callbacks fracos ao proprietário. Só o ViewModel altera o agregado e publica a apresentação. O Coordinator continua a publicar players e certificados de navegação; os campos das listas são publicados em conjunto. O modifier de certificados observa explicitamente o ViewModel, para continuar a funcionar quando invocado a partir de You.

O preview de Learn usa mocks dos protocolos sem repositórios. Os testes adicionais verificam publicação de pesquisa/filtros/navegação e de seleção/feedback do player. Foram validados 54 testes de Learn e a regressão de Home, Onboarding e You.

## Persistência e retomada

Cada módulo tem um `ModuleProgressEntity` no banco pessoal. Seu campo `state` contém a quantidade de lições concluídas em sequência: zero abre a lição 1; um abre a lição 2; dois abre a lição 3. Quando `state` é igual ao total, o módulo está concluído e não existe próxima lição. Uma revisão explícita de lição concluída não incrementa nem reduz o state.

`LearningStore.snapshot(for:)` lê o state do módulo e os detalhes das lições na mesma fila serial de background. Home, cards de sugestão, listas de Learn e abertura consomem esse snapshot. `CourseRules` apenas apresenta o state: não percorre conclusões ou datas para decidir a próxima lição. Um pedido para abrir uma lição futura também resolve para `state + 1`.

Chegar ao Summary solicita imediatamente o checkpoint. `LearningStore.save(_:in:)` grava a conclusão da lição e incrementa o state em uma única transação. A interface mostra loading enquanto aguarda. Repetir uma conclusão é idempotente; concluir uma lição fora de sequência é rejeitado e revertido. Sair no meio ou ir para background salva o passo e as respostas sem incrementar state.

O player só é criado depois de carregar o snapshot persistido e o conteúdo. Falha de leitura mostra erro sem fallback para cache. Falha de gravação mantém o player para nova tentativa. A fila cria e utiliza exclusivamente o `ModelContext`, fora da main thread, sem actor de progresso. `currentStep = -1` representa a capa; os passos começam em zero.

A criação inicial de cada registro executa uma migração única dos dados antigos: somente o prefixo de lições comprovadamente concluídas define o state inicial. Depois de criado, o campo persistido é a única fonte do cursor. A exclusão da conta remove também esses registros.

O teste integrado usa Home, Learn e o banco real: A REGION → concluir 1 e 2 → sair no meio da 3 → atualização automática da Home → retomar 3 pelo card da região, pelo Continue e por uma nova instância do store. Há testes para uma atualização da Home durante uma leitura antiga, conclusão concorrente repetida, rollback da transação, migração, state zero e conclusão final.
