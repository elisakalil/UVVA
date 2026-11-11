# UVVA · You

> Status: rascunho v0.2 · 2026-10-31 · conta sem e-mail nem SMS (ONBOARDING v0.5)
> Depende de: [`_shared.md`](_shared.md), [`quiz.md`](quiz.md), [`learn.md`](learn.md), [`cellar.md`](cellar.md), [`friends.md`](friends.md)
> Fonte: canvas UVVA App, artboards You e Main (a aba You dentro do telefone, a versão mais recente).

## 1. Objetivo

A aba You é o perfil do usuário. Ela mostra o que ele já aprendeu (Progress), o seu mapa do paladar e como ele mudou (Map), e a conta (Settings): dados pessoais, lembrete diário, partilha, certificados, sair e apagar a conta.

**Fundo.** A tela usa a bg2 (só as colinas), fixa, com um véu escuro leve por cima: um gradiente de `rgba(24,30,18,.35)` no topo a `.55` em baixo. Os cards de vidro fosco quadrados têm a bg1 (o fundo da Home), desfocada, como fundo próprio: ela começa no topo de cada card e rola junto com o conteúdo, sem ficar presa ao ecrã.

Pela SHARED-R01, não há planos: "Premium lifetime" no header, "Manage subscription" e o paywall estão fora de escopo.

## 2. Header

**YOU-R01 · Header.** O nome do usuário, a foto e a assinatura do paladar (a frase dominante, QUIZ-R15, em caixa alta: por exemplo "ACIDITY · FRUIT · BODY", ou "HIGH ON EVERY AXIS" num mapa plano). Não há handle: o usuário é identificado por um id interno, nunca mostrado.

**YOU-R02 · Tabs.** Três tabs: Progress, Map e Settings. A aba abre em Progress (ver D1).

**YOU-R03 · Entrada pela Home.** O card "O eixo que mudou" da Home (HOME-R17) abre a tab Map, já em "Over time".

**Critérios**
- Dado o usuário "Elisa" com Acidity, Fruit e Body como líderes (QUIZ-R14a), então o header mostra "Elisa" e "ACIDITY · FRUIT · BODY", sem nenhum "@".

## 3. Progress

> **Estado da implementação (2026-10-31).** Os números mostram 0 até existirem o Learn e o Cellar; "Specialist in" mostra o texto de vazio e sugere o primeiro curso do path. O nível (YOU-R08) fica escondido até decidir D5. O streak (D11) não entra.

**YOU-R04 · Números.** Seis números em "Your progress":

| Número | Cálculo |
| --- | --- |
| Grapes | Cursos de casta concluídos (LEARN-R02) |
| Regions | Cursos de região concluídos |
| Lessons | Lições concluídas, de qualquer curso (SHARED-R15) |
| XP | Soma do XP ganho (LEARN-R20, R21) |
| Bottles | Entradas no Cellar ([ver D2]) |
| Certificates | Certificados obtidos (LEARN-R22) |

A secção pode ser recolhida (−) e aberta (+).

**YOU-R05 · O que já sabe.** "7 grapes · 5 regions": as listas de castas e de regiões cujos cursos estão concluídos.

**YOU-R06 · Specialist in.** Um texto que resume em que o usuário é mais forte, a partir dos cursos de casta e de região concluídos (ver D3). Sem nenhum curso concluído: "Nothing to map yet. Finish your first course and this space starts filling in: the grapes you know, the regions you can place, and where you are strongest."

**YOU-R07 · A Course for You.** Mostra **What Wine Is** até à sua conclusão. Depois, sugere apenas cursos ainda não iniciados: primeiro um curso ligado à casta ou região estudada mais recentemente, depois o próximo módulo novo de The Path e, por fim, outro curso novo do catálogo. Abaixo do título, uma linha com chevron mostra o nome do curso, o número de lições e a duração. Tocar na linha abre o curso. Se não houver candidatos, a secção indica que não há novas sugestões.

**YOU-R08 · Nível.** Um nível ("Harvest · Level 3 of 3"), uma barra de progresso e uma frase ("4 curriculum lessons left to finish the curriculum."). Ver D5.

**Critérios**
- Dado um usuário novo, então os seis números são 0 e a sugestão é o módulo 1 do The path.
- Dados 2 cursos de casta e 1 de região concluídos, então Grapes = 2 e Regions = 1.
- Dadas 26 lições concluídas, 3 delas revistas, então Lessons = 26 (rever não conta duas vezes).
- Dado um curso concluído, então Certificates sobe 1.

## 4. Map

**YOU-R09 · O mapa.** "The map", com o radar, a legenda e "Your readings" (como na QUIZ-R15 e QUIZ-R16).

**YOU-R10 · Over time.** A secção aparece quando uma avaliação de vinho (Yes / No) altera o mapa depois do Quiz. A descrição indica o eixo que mais mudou na última alteração, por exemplo "Your last wine raised your tannin." (HOME-R16).

A linha do tempo mostra até seis alterações, em ordem cronológica, com a mais recente selecionada por defeito. Cada ponto corresponde a uma avaliação e mostra a sua data, com hora quando há mais de uma no mesmo dia. As avaliações do mesmo dia ocupam pontos separados. Ao escolher um ponto, as coordenadas do radar passam suavemente para a medição selecionada, com transição imediata quando a opção de reduzir movimento está ativa. O radar do histórico amplia a distância visual entre medições em até 10× por eixo, mantendo os valores guardados. A lista mostra a variação líquida por eixo, somando as subidas e descidas das alterações mostradas na linha do tempo.

**YOU-R11 · Para onde o mapa aponta.** "Where the map points": a narrativa do mapa (QUIZ-R15).

**YOU-R12 · Partilhar o mapa.** "Share my map" abre a folha "This is my wine palate", com o nome, o radar (destaques da QUIZ-R16), a assinatura (frase dominante, QUIZ-R15), "Map yours · uvva.app" e a mensagem "This is my wine palate. Map yours on UVVA and we'll find the perfect wine to drink together." O link é `uvva.app/invite/[id do usuário]`. Os formatos são os de toda partilha da app (SHARED-R20): Story ("Share to Instagram"), WhatsApp ("Send on WhatsApp") e "Save image".

**YOU-R13 · Refazer o mapa.** "Redo the map" abre o Quiz desde a Intro (QUIZ-R18a). O mapa novo só substitui o atual se o usuário tocar em "Keep this map".

**Critérios**
- Dadas oito avaliações que alteraram o mapa depois do Quiz, a linha do tempo mostra as seis mais recentes.
- Se as alterações mostradas fizeram Fruit subir 1,0 e depois descer 0,3, a lista mostra Fruit com ↑ 0,7 mesmo ao selecionar outro ponto da linha do tempo.
- Quando o usuário toca em "Redo the map" e depois sai do Quiz sem "Keep this map", então o mapa não muda.
- Dado o usuário "Elisa", então o link de partilha é `uvva.app/invite/` seguido do id dela, e não do nome.

## 5. Settings

### 5.1 Conta

**YOU-R14 · Dados.** Linhas Name, Phone number, Profile photo e "Signed in with" (Apple ou Google, só leitura), cada uma com o valor atual. Não há linha de e-mail: a conta não tem e-mail (ONBOARDING v0.5). Tocar em Name, Phone number, Profile photo ou Daily reminder abre a edição numa folha que sobe de baixo, sempre com o mesmo desenho: o fundo da aba You (as colinas com o véu escuro), cantos arredondados, a alça no topo, o título em Red Grapes caixa alta ("Your first name", "Your phone number", "Change photo", "Daily reminder") e, quando há, uma linha de texto por baixo. Não há botão de voltar nem de fechar: a folha fecha ao arrastar para baixo ou ao tocar fora dela, sem guardar. Com o teclado aberto, a folha sobe acima dele (ver D7).

**YOU-R14a · Foto de perfil.** A linha Profile photo mostra a foto atual em miniatura e abre a folha "Change photo" (título em Red Grapes, caixa alta), que sobe de baixo e fecha ao arrastar para baixo, sem botão de voltar nem de fechar: "The photo next to your name. Change it whenever you like.", a foto em grande (sem foto, a figura creme sobre o vinhedo, YOU-R01), "Choose a photo", "Remove photo" (só quando há foto) e "Save". "Choose a photo" e tocar na foto abrem a biblioteca de fotos do iOS; a foto escolhida é cortada num quadrado de 512 px e lavada nos azuis do céu do fundo da app (de `#E4E8E3`/`#4A5F63`, a névoa junto às colinas, a `#93B1B8`/`#1C2C31`, o topo do céu): a foto passa a tons de cinza e as sombras e as luzes tomam os dois azuis. O Vision separa os objetos da frente (pessoas, animais, coisas): o fundo fica no azul mais claro e cada objeto num azul mais fundo, o maior o mais fundo. Sem objetos, ou num aparelho onde o Vision não corre (o simulador), a foto toda fica no azul claro. Enquanto a foto é lida e lavada, a foto atual fica apagada com a GrapeLoop por cima. Depois a foto fica como rascunho. Nada muda até "Save": fechar a folha descarta o rascunho. "Save" só fica ativo quando o rascunho é diferente da foto guardada. Uma foto que não abre: "That photo could not be opened. Try another one." Se guardar falha: "Your changes could not be saved. Try again.", e a folha continua aberta. A foto fica só na conta do usuário (iCloud); não vai para o perfil público. Esta folha não está nos artboards (decidido em 2026-11-10).

**YOU-R15 · Validação.** Name segue a regra do Onboarding (ONB-R15). Phone number segue a ONB-R05 e pode ficar vazio; mudar ou apagar o número troca ou apaga a chave de contato (ONB-R07, ARCHITECTURE §4.4).

**YOU-R15a · Idioma.** Uma linha "Language" com English e Português (Brasil) (SHARED-R19a). A app muda de idioma assim que o usuário escolhe, sem reiniciar.

**Critérios**
- Dada uma foto vermelha, quando é escolhida, então o rascunho é azul.
- Dados dois objetos e o fundo, então o objeto maior fica no azul mais fundo e o fundo no mais claro.
- Dada uma foto escolhida e ainda não guardada, então o header continua com a foto anterior; depois de "Save", o header e a linha Profile photo mostram a nova.
- Dada uma conta com foto, quando o usuário toca em "Remove photo" e guarda, então o header volta à figura creme.
- Quando o usuário escolhe uma foto e arrasta a folha para fechar sem guardar, então a foto não muda.
- Dado o idioma English, quando o usuário escolhe Português (Brasil), então os textos passam a pt-BR sem fechar a app.
- Dada a lista de idiomas, então ela tem exatamente 2 opções.

### 5.2 Lembrete diário

**YOU-R16 · Linha.** "Daily reminder" mostra a hora escolhida, ou "Set a time" quando não há lembrete.

**YOU-R17 · Escolha.** Numa folha (YOU-R14). "Pick the moment of the day and the days of the week. Change it whenever you like." Quatro momentos:

| Momento | Hora |
| --- | --- |
| With my coffee | 08:00 |
| Around lunch | 13:00 |
| Before dinner | 19:00 |
| Late, with a glass | 22:00 |

E "Another time", com qualquer hora escolhida num seletor (D8, decidido em 2026-10-31). E os dias, de Mon a Sun.

**YOU-R18 · Guardar.** "Save" só fica ativo com um momento e pelo menos um dia escolhidos.

**YOU-R19 · Desligar.** "Turn reminders off" ("You open the app whenever you feel like it.") desativa os dias e deixa guardar sem nenhum. A linha volta a "Set a time".

**YOU-R20 · Notificação.** O lembrete é uma notificação local do iOS, na hora e nos dias escolhidos (SHARED-R02). Pedir a permissão de notificações acontece ao guardar o primeiro lembrete.

**Critérios**
- Dado o momento Before dinner e nenhum dia, então Save está inativo.
- Dados Before dinner e Mon, Wed, Fri, quando o usuário guarda, então a linha mostra "19:00" e há 3 notificações semanais agendadas às 19:00.
- Dado um lembrete ativo, quando o usuário escolhe "Turn reminders off" e guarda, então não há notificações agendadas e a linha mostra "Set a time".
- Quando o usuário guarda o primeiro lembrete, então o iOS pede permissão de notificações.

### 5.3 Partilhado com amigos

**YOU-R21 · Resumo.** "Shared with friends · What you have built in UVVA, ready to share." Três linhas:
- **My Map:** "Public" ou "Friends".
- **Tables:** o número de mesas montadas no Friends.
- **Certificates:** o número de certificados, que abre a lista (5.4).

**YOU-R22 · Mapa público.** "Make chart public" liga e desliga a visibilidade do mapa:
- **Ligado:** "Anyone with your link can see your palate map."
- **Desligado:** "Only friends you share a table with can see your map."

O valor inicial é **ligado** (Public, D9, decidido em 2026-10-31).

### 5.4 Certificados

**YOU-R23 · Lista.** "Certificates" com o contador "[obtidos]/[total]", com dois dígitos ("00/36"). Os certificados obtidos mostram a data; os que ainda não foram obtidos aparecem apagados (ver D10).

**YOU-R24 · Sem certificados.** A linha Certificates mostra "0" e não abre nada, como My Map e Tables: não há tela de estado vazio. Com pelo menos um certificado, a linha abre a lista (decidido em 2026-11-11).

**YOU-R25 · Partilhar.** Tocar num certificado obtido abre a partilha, com os formatos Story, WhatsApp e Save image (LEARN-R24, SHARED-R20).

**Critérios**
- Dados 0 certificados, então a linha Certificates mostra "0" e tocar nela não abre nada.
- Dado 1 certificado, quando o usuário toca na linha, então abre a lista.
- Dados 14 de 36 obtidos, então o contador mostra "14/36".
- Dado um certificado não obtido, quando o usuário toca nele, então nada abre.

### 5.5 Sair e apagar

**YOU-R26 · Sign out.** Pede confirmação: "Sign out of UVVA?", "Your palate map, cellar and certificates stay saved to your account." Os botões são "Sign out" e "Cancel". "Sign out" encerra a sessão e abre a Welcome (ONB-R02). Entrar de novo com a mesma conta Apple ou Google, no mesmo iCloud, recupera tudo (ONB-R27, R27a).

**YOU-R27 · Apagar a conta.** "Delete my account" pede confirmação: "Delete your account?", "This permanently removes your palate map, cellar, tables and certificates. It cannot be undone." Os botões são "Delete my account" e "Keep my account". Apagar remove todos os dados da conta (no iCloud e na base pública: perfil, chave de contato e pedidos de amizade), encerra a sessão e abre a Welcome. A mesma conta Apple ou Google pode criar uma conta nova depois. Se a base pública não responde, nada é apagado: a confirmação fecha e um card creme claro, com texto escuro, sobe no final da tela, acima da tab bar: "Your account could not be deleted", "Nothing was removed. Check your connection and try again." O card sai sozinho depois de alguns segundos ou com um toque, e "Delete my account" continua nas Settings para tentar de novo. Uma conta sem pedidos de amizade é apagada normalmente.

> **Estado da implementação (2026-10-31).** Apagar remove o perfil, os mapas e o lembrete do iCloud, o PublicProfile e a ContactKey da base pública, e cancela as notificações. Ainda falta: (1) revogar o token da Apple (exige um servidor; previsto num Cloudflare Worker antes do TestFlight, exigência da App Store para contas com Sign in with Apple); (2) apagar os FriendRequests enviados e recebidos, quando o Friends existir.

**Critérios**
- Quando o usuário toca em Sign out e depois em Cancel, então a sessão continua.
- Quando o usuário confirma Sign out, então não há sessão e abre a Welcome.
- Dada uma conta apagada, quando a mesma conta Apple entra de novo, então ela segue o cadastro como um usuário novo.
- Quando o usuário toca em "Keep my account", então nada é apagado.
- Dado que apagar falha, então nada é apagado, a sessão continua, a confirmação fecha e o card de erro aparece no final da tela.
- Dada uma conta que nunca enviou nem recebeu pedidos de amizade, quando o usuário confirma apagar, então a conta é apagada.

## 6. Fora de escopo

- Planos, "Premium lifetime", "Manage subscription" e o paywall (SHARED-R01).
- A geração dos certificados (`learn.md`) e o cálculo do mapa (`quiz.md`).

## 7. Dúvidas em aberto

- [x] **D1 · Tab inicial.** Abre em Progress. Depois de refazer o mapa, abre em Map (QUIZ-R25). Cada tab abre no topo.
- [ ] **D2 · Bottles.** Conta todas as entradas do Cellar, ou só as provadas (sem as Not yet)?
- [ ] **D3 · Specialist in.** Como se gera o texto? Ex.: "You know Burgundy best: both of its grapes and the region course are done." É um texto escrito à mão para cada combinação, ou gerado por regras (a região com mais cursos concluídos, a próxima sugerida…)?
- [x] **D4 · Sugestão de curso.** Baseada em cursos concluídos e nas ligações do catálogo, conforme YOU-R07.
- [ ] **D5 · Níveis.** Quais são os níveis (o protótipo tem "Harvest · Level 3 of 3") e como se sobe de nível: por XP, por lições do curriculum?
- [x] **D6 · Partilha do mapa.** Story, WhatsApp e Save image, como toda partilha (SHARED-R20).
- [x] **D7 · Editar dados.** Mudar o número de telefone não pede código (não há SMS). Mudar o nome não muda os links já partilhados, porque eles usam o id.
- [x] **D8 · Hora do lembrete.** Os quatro momentos e "Another time", com qualquer hora (começa em 20:00, como no protótipo).
- [x] **D9 · Mapa público por padrão.** Começa Public. Desligado, o PublicProfile continua a existir (o nome aparece aos amigos), mas sem o mapa. O que vê quem abre o link fica para o Friends.
- [ ] **D10 · Certificados ainda não obtidos.** *(Por agora a lista só mostra os obtidos, e sem nenhum a linha não abre, YOU-R24; decidir com o Learn.)* Eles aparecem na lista (apagados), ou só os obtidos? Qual é o total? Com 30 módulos, 30 castas e 10 países, seriam 70 se cada país for um curso.
- [ ] **D11 · Streak.** *(Não implementado; a decidir com o Learn.)* O artboard You tem regras de streak (dias seguidos com pelo menos uma lição, que voltam a zero quando um dia passa sem lição). O streak entra nesta versão? E onde aparece?
- [ ] **D12a · Linha Language.** Escondida nos Settings até existirem as traduções pt-BR (decidido em 2026-10-31).
- [x] **D12 · Idioma.** Inglês e português do Brasil nesta versão; 6 idiomas no futuro (SHARED-R19a, YOU-R15a).
- [ ] **D13 · Idioma inicial.** A app abre no idioma do aparelho (pt-BR se o aparelho estiver em português, senão inglês)? E um aparelho em português de Portugal?
