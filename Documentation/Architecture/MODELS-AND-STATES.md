# Modelos, estados e propriedade dos dados

## Convenção

- `Model`: agregado de dados, sem infraestrutura de observação ou persistência implícita.
- `UIModel`: apresentação do ecrã ou componente, incluindo textos, recursos visuais e valores formatados.
- `State`: condição alternativa de apresentação, interação ou domínio.
- `Flow`: regras de transição entre etapas.
- `Draft`: dados temporários em edição.
- `Store`: implementação de armazenamento, como os repositórios SwiftData existentes no Core.

## Propriedade dos dados

Foram removidos `LearnState` e `YouState`, sem os substituir por Store, Context, Manager ou outra caixa observável.

`LearnViewModel` possui o `LearnContentModel`. O Coordinator recebe acesso de leitura por uma função e devolve resultados de progresso/conclusão através de callbacks. O proprietário aplica esses resultados e publica o UIModel. A composição mantém callbacks fracos e os publishers de navegação do Coordinator.

`YouViewModel` possui o `YouContentModel`. A Factory compõe os filhos quando necessários, com funções de leitura e callbacks fracos para resultados persistidos. Só o proprietário altera o agregado. Depois atualiza as apresentações de progresso, mapa, definições e certificados. Os rascunhos dos editores não são reinicializados por esta propagação; são preparados quando o editor abre.

Os modelos de dados são structs sem ObservableObject nem MainActor. Os ViewModels continuam na main actor porque publicam apresentação. A observação pertence ao UIModel publicado, não a um novo intermediário de dados.

## Nomes alterados

| Anterior | Atual |
| --- | --- |
| LearnContent | LearnContentModel |
| YouContent | YouContentModel |
| HomeState | HomeContentModel |
| LoadedHomeContent | HomeLoadResultModel |
| CourseCompletion | CourseCompletionResultModel |
| HeaderScroll | HeaderScrollModel |
| HomeSpotlightModel | HomeSpotlightID |
| QuizScreen | QuizViewState |
| LessonPlayerViewModel.Phase | LessonPlayerViewModel.LessonPlayerState |
| HomeCardModel.FriendsVariant | HomeCardModel.FriendsCardState |

O resultado de carregamento da Home passa a expor `model`, em vez de chamar `state` aos dados. O cartão de amigos usa `noFriends`, `hasMatch` e `hasFriends`. Tipos diferentes de cartões continuam em HomeCardModel; não são estados mutuamente exclusivos de um único cartão.

`CourseState`, `OptionState`, `ContactRowState`, `QuizStep`, `OnboardingStep`, as máquinas de fluxo e os drafts mantêm a sua responsabilidade. A refatoração não introduz estados artificiais para substituir todos os bools nem altera o desenho visual.

## Validação e limites

- Parse dos 372 ficheiros Swift atuais de Features e testes: aprovado.
- Verificação estrutural de tipos sobre cópias temporárias: módulos e corpos dos testes verificados com macros de preview/Observation/Testing excluídas ou substituídas apenas nessas cópias. As alterações dessas cópias não são aplicadas ao projeto.
- git diff --check: aprovado.
- A compilação integral e a execução dos testes continuam sem confirmação devido à restrição de acesso anteriormente definida pelo utilizador. Nenhuma nova permissão foi solicitada.

Os testes existentes foram atualizados para os nomes e contratos; foram acrescentados cenários de propriedade do perfil, preservação do rascunho durante atualizações e libertação do proprietário mesmo com um editor retido.
