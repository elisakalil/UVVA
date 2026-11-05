# Quizz: arquitetura de Features

`QuizFactory` compõe o ViewModel com contratos de casos de uso e de navegação. O AppCoordinator fornece a entrada do quiz, o nome e o callback de saída através de `QuizCoordinator`.

- `QuizFlow`: máquina de estados pura, preservada; controla perguntas, respostas e resultado.
- `QuizViewModel`: estado de carregamento/gravação, ações do ecrã e seleção da apresentação.
- `LoadQuizQuestionsUseCase`: carrega e valida o banco completo antes de o disponibilizar.
- `SaveQuizMapUseCase`: persiste o mapa com o relógio injetado.
- `QuizCoordinator`: resolve as saídas; o primeiro quiz termina na Home com tour e não permite sair pela intro; refazer termina ou sai para You › Map.
- `QuizPresentationBuilder`: constrói os modelos da intro, leitura, resultado e partilha sem efeitos externos.

A raiz contém `Coordinator`, `DependencyInjection`, `Extensions`, `Flow`, `Screens` e `Resources`. Cada ecrã agrupa `Views`, `Models` e outros componentes necessários. Os ecrãs que apenas apresentam valores e callbacks mantêm-se sem ViewModels próprios.

Mantêm-se os textos, a troca de versões das perguntas, a opção de responder de novo sem guardar, a partilha apenas após persistência e a mensagem de erro com possibilidade de nova tentativa. Os testes existentes foram migrados para a Factory e foram acrescentadas verificações de perguntas incompletas e recuperação após falha de gravação.
