# Onboarding: arquitetura de Features

O Onboarding mantém o fluxo Welcome → Name → Phone → Find friends → Contacts. Contas existentes saem após a pesquisa; a recusa de acesso à agenda termina o cadastro sem mostrar Contacts.

## Responsabilidades

| Componente | Objetivo |
| --- | --- |
| `OnboardingFactory` | Compor o módulo, os ViewModels e os casos de uso |
| `OnboardingModule` | Manter as instâncias compostas durante a vida do fluxo |
| `OnboardingCoordinator` | Aplicar transições válidas e comunicar o resultado à aplicação |
| `OnboardingFlow` | Definir as transições da máquina de estados, sem efeitos externos |
| `OnboardingDraft` | Partilhar identidade, nome e perfil entre as etapas |
| `WelcomeViewModel` | Estado de autenticação, disponibilidade de iCloud e mensagens da Welcome |
| `NameViewModel` | Edição, validação e normalização do nome |
| `PhoneViewModel` | País, dígitos, validação e estado de gravação |
| `FindFriendsViewModel` | Estado do pedido de acesso à agenda |
| `ContactsViewModel` | Carregamento, pesquisa e estado visual de pedidos e convites |
| `ContactsPresentationBuilder` | Converter contactos descobertos em modelos de apresentação |

Os ecrãs Legal e Splash não precisam de ViewModel: apresentam conteúdo e recebem ações simples.

## Casos de uso

- `SignInUseCase`: obter uma identidade autenticada; nil significa cancelamento.
- `FindExistingAccountUseCase`: procurar conta e verificar a existência de mapa.
- `CreateAccountUseCase`: persistir o perfil antes de iniciar a publicação pública em background.
- `RequestContactsAccessUseCase`: pedir acesso à agenda.
- `FindContactsOnUVVAUseCase`: normalizar telefones, procurar contas, excluir o próprio utilizador e contas sem mapa, classificar e ordenar os contactos.
- `SendFriendRequestUseCase`: enviar um pedido de amizade.

Cada caso de uso tem um contrato próprio. Os ViewModels recebem esses contratos e um contrato de Coordinator. As referências dos ViewModels ao Coordinator são fracas; o módulo mantém o Coordinator vivo sem ciclos de retenção.

## Organização

A raiz da Feature contém `Coordinator`, `DependencyInjection`, `Flow`, `Screens`, `Views`, `Contacts` e `Resources`. `Views` contém componentes visuais partilhados pelos ecrãs do cadastro. `Contacts` contém a integração com a agenda. Cada ecrã agrupa os seus `Views`, `ViewModel`, `Models`, `UseCases`, `Builders` ou `Validation`, conforme necessário.

## Integração e comportamento

O AppCoordinator solicita um módulo à Factory e recebe `OnboardingResult`. A View raiz observa o estado do Coordinator e apresenta os ViewModels do módulo. Contacts carrega a agenda no seu `.task` de entrada, incluindo quando se regressa a esse ecrã.

O rascunho continua sem persistência antes de Phone. Voltar de Name elimina a identidade autenticada; voltar de Phone preserva nome e número. A publicação pública continua a ser best effort e não impede a criação local da conta. Uma falha de gravação permanece em Phone e agora apresenta a mensagem nesse ecrã (antes era guardada num estado que apenas a Welcome mostrava). Pedidos de amizade falhados revertem o estado Requested.

Os testes de comportamento existentes foram migrados para o módulo composto. Foram acrescentados cenários de falha de gravação, preservação do rascunho e entrega única do resultado final.
