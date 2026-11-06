# Revisão transversal de Features

Revisão de 5 de novembro de 2026, limitada a inspeção estática e ferramentas permitidas pelo ambiente. O utilizador recusou permissões adicionais e validação pela interface; não foi feita validação visual nem uma nova execução dos testes no simulador.

## Resultado da inspeção

- Foram inspecionados os contratos e mecanismos de publicação dos 18 ViewModels de produção de Home, GuidedTour, Onboarding, Quizz, You e Learn. Todos têm protocolo e UIModel publicado.
- Views de ecrãs com comportamento dependem dos contratos genéricos; componentes puramente visuais recebem valores e ações.
- A edição usa ações explícitas e contratos com UIModel de leitura. Dados de domínio, máquinas de estado e casos de uso continuam fora das Views.
- As subscrições Combine revistas capturam os ViewModels fracamente. Não foram identificados ciclos permanentes nessas subscrições; isto não substitui medição de memória em execução.
- A reconstrução de apresentação usa os valores emitidos pelos publishers, evitando a releitura prematura do estado durante willSet. Estados transitórios de Settings e a seleção de separador são preservados.
- Learn observa explicitamente os certificados na apresentação sobre toda a aplicação. Home observa explicitamente o alvo do tour para atualizar o scroll.
- A coexistência de Observation no Coordinator de Onboarding e no estado visual de scroll da Home é intencional: são objetos distintos dos ViewModels de apresentação, sem dupla observação no mesmo ViewModel.
- As cinco Features não têm ficheiros Swift soltos na raiz.

## Ajustes efetuados nesta revisão

1. GuidedTour ignora ações após terminar. Isso evita múltiplas chamadas de onFinish e impede que ações atrasadas alterem a apresentação de um tour já concluído.
2. Learn verifica a identidade do player que pediu saída depois de aguardar flush/atualização do progresso. Uma saída atrasada de um player antigo já não fecha um player aberto entretanto.
3. O cabeçalho e o botão de voltar partilhados do Onboarding passaram a receber marca, símbolo e texto de acessibilidade de OnboardingChromeUIModel.
4. Foram corrigidas referências desatualizadas na documentação da Home.

Foram acrescentados testes de regressão para conclusão única do tour e saída atrasada de uma lição. Esses novos testes não foram executados nesta revisão.

## Verificações executadas

- Parse sintático Swift: 350 ficheiros de produção e 24 ficheiros de testes, 374 no total; todos passaram.
- git diff --check: passou.
- Auditoria de contratos/publicação dos 18 ViewModels: passou.
- Inspeção das declarações de textos/imagens nas Views: os resíduos de copy partilhada encontrados foram extraídos. Composição de Text, formatação de códigos de telefone, geometria e estilos permanecem nas Views quando constituem renderização.

Parse sintático não verifica tipos, linking ou comportamento em execução. Não se deve apresentar estes resultados como uma compilação ou como testes unitários executados.

## Baseline anterior

O log anterior /tmp/uvva-final-ui.log regista 192 testes aprovados: Home 45, Onboarding 35, Quizz 25, You 33 e Learn 54. Esse resultado antecede os ajustes desta revisão e as alterações locais do utilizador; não valida o estado atual por si só.

## Organização e alterações locais

A organização local já existente da Home em View/Cards/Hero e as alterações de recursos foram preservadas. As restantes Features usam maioritariamente Views. Não foram renomeadas pastas para contrariar essa organização; o ponto importante é manter a convenção escolhida de forma explícita, sem tratar pluralização como uma regra de arquitetura.

## Limites e próximo controlo de qualidade

A revisão de código está concluída dentro do acesso permitido. Permanecem sem confirmação: compilação e execução dos novos testes, memória em execução, layout e transições completos no simulador. Quando esse acesso estiver disponível, validar cadastro, quiz inicial e refazer, tour e scroll, edição de perfil, lembretes, pesquisa de Learn, retoma de lições e partilha de certificados. Isto não exige outra etapa de desenho arquitetural.

## Atualização posterior de nomenclatura e propriedade

A revisão descrita acima antecede a decisão de remover os contentores de dados LearnState/YouState. A arquitetura atual e a verificação limitada correspondente estão em [MODELS-AND-STATES.md](MODELS-AND-STATES.md). Os ViewModels principais passaram a possuir os modelos de dados; não existem classes ModelStore em substituição.
