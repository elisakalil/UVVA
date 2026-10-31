# UVVA · You

> Status: rascunho v0.2 · 2026-10-31 · conta sem e-mail nem SMS (ONBOARDING v0.5)
> Depende de: [`_shared.md`](_shared.md), [`quiz.md`](quiz.md), [`learn.md`](learn.md), [`cellar.md`](cellar.md), [`friends.md`](friends.md)
> Fonte: canvas UVVA App, artboards You e Main (a aba You dentro do telefone, a versão mais recente).

## 1. Objetivo

A aba You é o perfil do usuário. Ela mostra o que ele já aprendeu (Progress), o seu mapa do paladar e como ele mudou (Map), e a conta (Settings): dados pessoais, lembrete diário, partilha, certificados, sair e apagar a conta.

Pela SHARED-R01, não há planos: "Premium lifetime" no header, "Manage subscription" e o paywall estão fora de escopo.

## 2. Header

**YOU-R01 · Header.** O nome do usuário, a foto e a assinatura do paladar (os 3 eixos do topo, QUIZ-R14, em caixa alta, separados por " · "). Não há handle: o usuário é identificado por um id interno, nunca mostrado.

**YOU-R02 · Tabs.** Três tabs: Progress, Map e Settings. A aba abre em Progress (ver D1).

**YOU-R03 · Entrada pela Home.** O card "O eixo que mudou" da Home (HOME-R17) abre a tab Map, já em "Over time".

**Critérios**
- Dado o usuário "Elisa" com top 3 Acidity, Fruit e Body, então o header mostra "Elisa" e "ACIDITY · FRUIT · BODY", sem nenhum "@".

## 3. Progress

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

**YOU-R07 · Sugestão.** Uma sugestão de lição ou curso, com o porquê:
- **Sem cursos concluídos:** "Start here · Course", com o primeiro módulo do The path (o nome, o número de lições e os minutos vêm do próprio módulo, LEARN-R10a), e o botão "Start the course", que abre esse módulo. O conteúdo dos módulos ainda não está definido (LEARN-R10).
- **Com cursos concluídos:** "Suggested lesson", com título, nota, XP e o porquê, e o botão "Start the lesson". Ver D4.

**YOU-R08 · Nível.** Um nível ("Harvest · Level 3 of 3"), uma barra de progresso e uma frase ("4 curriculum lessons left to finish the curriculum."). Ver D5.

**Critérios**
- Dado um usuário novo, então os seis números são 0 e a sugestão é o módulo 1 do The path.
- Dados 2 cursos de casta e 1 de região concluídos, então Grapes = 2 e Regions = 1.
- Dadas 26 lições concluídas, 3 delas revistas, então Lessons = 26 (rever não conta duas vezes).
- Dado um curso concluído, então Certificates sobe 1.

## 4. Map

**YOU-R09 · O mapa.** "The map", com a data da última mudança do mapa ("Read [data]"), o radar, a legenda e "Your readings" (como na QUIZ-R15 e QUIZ-R16).

**YOU-R10 · Over time.** "See how your map has changed over the last few months." Uma foto do mapa por mês, com a data e o número de vinhos avaliados até então:

| Foto | Exemplo |
| --- | --- |
| A primeira | "First map · 0 wines rated" (o mapa do Quiz) |
| Uma por mês | "8 wines rated" (no fim de cada mês) |
| A atual | "Today · 27 wines rated" |

Escolher uma foto mostra o mapa desse momento sobre o atual e a variação de cada eixo. Os eixos que mudaram com a avaliação mais recente aparecem marcados como "New", e o topo mostra o aviso da última avaliação ("Your last wine raised your tannin."), como o card da Home (HOME-R16).

**YOU-R11 · Para onde o mapa aponta.** "Where the map points": a narrativa do mapa (QUIZ-R15).

**YOU-R12 · Partilhar o mapa.** "Share my map" abre a folha "This is my wine palate", com o nome, o radar, a assinatura, "Map yours · uvva.app" e a mensagem "This is my wine palate. Map yours on UVVA and we'll find the perfect wine to drink together." O link é `uvva.app/invite/[id do usuário]`. Os formatos são os de toda partilha da app (SHARED-R20): Story ("Share to Instagram"), WhatsApp ("Send on WhatsApp") e "Save image".

**YOU-R13 · Refazer o mapa.** "Redo the map" abre o Quiz desde a Intro (QUIZ-R18a). O mapa novo só substitui o atual se o usuário tocar em "Keep this map".

**Critérios**
- Dado um Quiz feito em 30/07 e 8 avaliações em agosto, então existem as fotos "First map · 0 wines rated" e, em 31/08, "8 wines rated".
- Dada uma foto de agosto com Fruit 5 e o mapa atual com Fruit 6, então a variação de Fruit é +1.
- Quando o usuário toca em "Redo the map" e depois sai do Quiz sem "Keep this map", então o mapa não muda.
- Dado o usuário "Elisa", então o link de partilha é `uvva.app/invite/` seguido do id dela, e não do nome.

## 5. Settings

### 5.1 Conta

**YOU-R14 · Dados.** Linhas Name, Phone number, Profile photo e "Signed in with" (Apple ou Google, só leitura), cada uma com o valor atual. Não há linha de e-mail: a conta não tem e-mail (ONBOARDING v0.5). Tocar em Name, Phone number ou Profile photo abre a edição (ver D7).

**YOU-R15 · Validação.** Name segue a regra do Onboarding (ONB-R15). Phone number segue a ONB-R05 e pode ficar vazio; mudar ou apagar o número troca ou apaga a chave de contato (ONB-R07, ARCHITECTURE §4.4).

**YOU-R15a · Idioma.** Uma linha "Language" com English e Português (Brasil) (SHARED-R19a). A app muda de idioma assim que o usuário escolhe, sem reiniciar.

**Critérios**
- Dado o idioma English, quando o usuário escolhe Português (Brasil), então os textos passam a pt-BR sem fechar a app.
- Dada a lista de idiomas, então ela tem exatamente 2 opções.

### 5.2 Lembrete diário

**YOU-R16 · Linha.** "Daily reminder" mostra a hora escolhida, ou "Set a time" quando não há lembrete.

**YOU-R17 · Escolha.** "Pick the moment of the day and the days of the week. Change it whenever you like." Quatro momentos:

| Momento | Hora |
| --- | --- |
| With my coffee | 08:00 |
| Around lunch | 13:00 |
| Before dinner | 19:00 |
| Late, with a glass | 22:00 |

E os dias, de Mon a Sun. Ver D8.

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

O valor inicial é [ver D9].

### 5.4 Certificados

**YOU-R23 · Lista.** "Certificates" com o contador "[obtidos]/[total]", com dois dígitos ("00/36"). Os certificados obtidos mostram a data; os que ainda não foram obtidos aparecem apagados (ver D10).

**YOU-R24 · Vazio.** Sem certificados: "No certificates yet", "Certificates for the lessons you complete live here. Finish one to see it, then come back whenever you like." e "Start learning", que abre a aba Learn.

**YOU-R25 · Partilhar.** Tocar num certificado obtido abre a partilha, com os formatos Story, WhatsApp e Save image (LEARN-R24, SHARED-R20).

**Critérios**
- Dados 0 certificados, então aparece o estado vazio e "Start learning" abre a aba Learn.
- Dados 14 de 36 obtidos, então o contador mostra "14/36".
- Dado um certificado não obtido, quando o usuário toca nele, então nada abre.

### 5.5 Sair e apagar

**YOU-R26 · Sign out.** Pede confirmação: "Sign out of UVVA?", "Your palate map, cellar and certificates stay saved to your account." Os botões são "Sign out" e "Cancel". "Sign out" encerra a sessão e abre a Welcome (ONB-R02). Entrar de novo com a mesma conta Apple ou Google, no mesmo iCloud, recupera tudo (ONB-R27, R27a).

**YOU-R27 · Apagar a conta.** "Delete my account" pede confirmação: "Delete your account?", "This permanently removes your palate map, cellar, tables and certificates. It cannot be undone." Os botões são "Delete my account" e "Keep my account". Apagar remove todos os dados da conta (no iCloud e na base pública: perfil, chave de contato e pedidos de amizade), encerra a sessão e abre a Welcome. A mesma conta Apple ou Google pode criar uma conta nova depois.

**Critérios**
- Quando o usuário toca em Sign out e depois em Cancel, então a sessão continua.
- Quando o usuário confirma Sign out, então não há sessão e abre a Welcome.
- Dada uma conta apagada, quando a mesma conta Apple entra de novo, então ela segue o cadastro como um usuário novo.
- Quando o usuário toca em "Keep my account", então nada é apagado.

## 6. Fora de escopo

- Planos, "Premium lifetime", "Manage subscription" e o paywall (SHARED-R01).
- A geração dos certificados (`learn.md`) e o cálculo do mapa (`quiz.md`).

## 7. Dúvidas em aberto

- [ ] **D1 · Tab inicial.** A aba You abre sempre em Progress, ou na última tab vista?
- [ ] **D2 · Bottles.** Conta todas as entradas do Cellar, ou só as provadas (sem as Not yet)?
- [ ] **D3 · Specialist in.** Como se gera o texto? Ex.: "You know Burgundy best: both of its grapes and the region course are done." É um texto escrito à mão para cada combinação, ou gerado por regras (a região com mais cursos concluídos, a próxima sugerida…)?
- [ ] **D4 · Sugestão de lição.** Com que regra se escolhe a lição sugerida? O protótipo justifica pelo Cellar e pelo mapa ("You keep coming back to Pinot Noir, and your map leans toward light, fresh reds").
- [ ] **D5 · Níveis.** Quais são os níveis (o protótipo tem "Harvest · Level 3 of 3") e como se sobe de nível: por XP, por lições do curriculum?
- [x] **D6 · Partilha do mapa.** Story, WhatsApp e Save image, como toda partilha (SHARED-R20).
- [ ] **D7 · Editar dados.** Mudar o número de telefone não pede código (não há SMS). Mudar o nome não muda os links já partilhados, porque eles usam o id.
- [ ] **D8 · Hora do lembrete.** O protótipo mostra "20:00", que não é nenhum dos quatro momentos. O usuário só escolhe entre os quatro, ou pode escolher qualquer hora?
- [ ] **D9 · Mapa público por padrão.** O mapa começa Public ou Friends? E o que vê quem abre o link de um mapa que não é público?
- [ ] **D10 · Certificados ainda não obtidos.** Eles aparecem na lista (apagados), ou só os obtidos? Qual é o total? Com 30 módulos, 30 castas e 10 países, seriam 70 se cada país for um curso.
- [ ] **D11 · Streak.** O artboard You tem regras de streak (dias seguidos com pelo menos uma lição, que voltam a zero quando um dia passa sem lição). O streak entra nesta versão? E onde aparece?
- [x] **D12 · Idioma.** Inglês e português do Brasil nesta versão; 6 idiomas no futuro (SHARED-R19a, YOU-R15a).
- [ ] **D13 · Idioma inicial.** A app abre no idioma do aparelho (pt-BR se o aparelho estiver em português, senão inglês)? E um aparelho em português de Portugal?
