# You: arquitetura de Features

`YouFactory` compõe a Feature a partir dos contratos de repositórios e serviços. `YouCoordinator` encaminha destinos e resultados de sessão para a aplicação. A apresentação local de sheets continua nas Views SwiftUI.

## Responsabilidades

- `YouViewModel`: seleção do separador, carregamento geral e cabeçalho.
- `ProgressViewModel`: apresentação do progresso e abertura do curso sugerido.
- `MapViewModel`: apresentação do mapa, seleção do histórico e ações de partilha/refazer.
- `SettingsViewModel`: fotografia, visibilidade e ações da conta; recebe os editores já compostos.
- `CertificatesViewModel`: lista de certificados e destinos para Learn.
- `EditNameViewModel`, `EditPhoneViewModel`, `ReminderViewModel`: rascunhos e estado de gravação de cada editor.
- Builders: conversão pura de dados em modelos de apresentação.
- `YouState`/`YouContent`: valores partilhados entre os ecrãs, sem operações ou navegação.

## Casos de uso

`LoadYouUseCase` lê os dados e preserva os fallbacks existentes de progresso/certificados. `SaveNameUseCase`, `SavePhoneUseCase`, `SavePhotoUseCase` e `SetMapPublicUseCase` executam operações específicas, reutilizando `SaveProfileUseCase` para persistência e publicação opcional. `SaveReminderUseCase` pede permissão quando necessário, persiste e só depois agenda. `SignOutUseCase` cancela notificações. `DeleteAccountUseCase` elimina primeiro os dados públicos, depois os privados e por último as notificações.

Os ViewModels recebem contratos dos casos de uso; não acedem diretamente aos repositórios. Os editores só atualizam o estado partilhado depois de a persistência ter sucesso. Assim, o cabeçalho, as definições e o nome da partilha do mapa refletem a mesma edição.

## Comportamento e validação

Os drafts dos editores são preparados em cada apresentação. Erros de gravação aparecem no editor correspondente. O editor de lembrete permanece aberto quando a gravação falha, em vez de fechar sem ter guardado. A publicação de perfil e a troca de chaves de contacto mantêm o comportamento best effort em background.

Foram executados 31 testes de You, 43 de Home e 34 de Onboarding, com sucesso. Incluem propagação de alterações entre ecrãs, erros de gravação, preservação das chaves/notificações em caso de falha e descarte de rascunhos não guardados.

## UIModels publicados e interfaces de apresentação

Os oito ViewModels de apresentação usam `ObservableObject` e `@Published public private(set) var uiModel`. Cada ecrã depende de um protocolo específico e usa uma View genérica com `@ObservedObject`. Os protocolos compostos de You e Settings usam associated types para os seus ecrãs filhos, mantendo a tipagem genérica.

`YouUIModel` contém o separador e o cabeçalho; `MapScreenUIModel` agrupa o mapa, nome e mensagem de partilha; Settings e Progress mantêm os modelos de apresentação existentes enriquecidos com textos e estado. Os editores possuem UIModels próprios com rascunhos, validação, loading e erros. Certificados são observados diretamente pelo seu ecrã. Os textos e recursos visuais foram retirados das Views; layout, estilos, foco e apresentações locais continuam nas Views.

O estado partilhado `YouState` publica `YouContent`. Os ViewModels subscrevem os valores emitidos para construir a apresentação, sem reler o valor antigo durante o `willSet` de `@Published`. As subscrições capturam os ViewModels fracamente. Settings preserva o erro e o estado de operação durante a reconstrução, e You atualiza o cabeçalho sem repor o separador selecionado.

Os bindings dos formulários passam por ações explícitas (`updateName`, `updateNational`, `selectCountry`, `pick`, `toggle`, `turnOff`, `updateTime`); as Views não podem alterar livremente o UIModel. O preview de EditName usa um mock do protocolo. Os testes incluem publicação simultânea de nome nos três ecrãs e manipulação do rascunho do lembrete através das ações.
