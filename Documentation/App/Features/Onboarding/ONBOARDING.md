# UVVA · Onboarding

> Status: rascunho v0.5 · 2026-10-31 · conta com Apple ou Google, sem SMS, senha nem e-mail (custo zero)
> Depende de: [`SHARED.md`](../Shared/SHARED.md), [`QUIZZ.md`](../Quizz/QUIZZ.md), [`FRIENDS.md`](../Friends/FRIENDS.md), [`ARCHITECTURE.md`](../Architecture/ARCHITECTURE.md) §4.2 e §4.4
> Fonte: canvas UVVA Telas, artboard Onboarding, telas 00 a 06.

## 1. Objetivo

O Onboarding é a criação da conta: leva a pessoa da primeira abertura da app até ter uma sessão. Mostra o Splash e a Welcome, entra com Apple ou Google, pede o primeiro nome e, opcionalmente, o telefone, e oferece encontrar amigos nos contatos.

Não há SMS, senha nem e-mail: a conta não tem nenhum custo por usuário (ARCHITECTURE §6). Os dados da conta ficam no iCloud do usuário.

O Onboarding termina na tela Contacts, abrindo o Quiz. O Quiz é uma feature à parte (`QUIZZ.md`). O tour guiado faz parte da Home (`HOME.md`, HOME-R29 a R33).

## 2. Fluxo

| Tela | Nome no canvas | Contador |
| --- | --- | --- |
| 00 | Splash | — |
| 01 | Welcome | — |
| 02 | Terms & Privacy | — |
| 03 | Sign up · Name | 01 / 02 |
| 04 | Sign up · Phone | 02 / 02 |
| 05 | Friends · Find | — |
| 06 | Friends · Contacts | — |

```
Splash
  → Welcome ──(link)──→ Termos e Privacidade ──(I understand)──→ Welcome
  ↓ (Continue with Apple / Continue with Google)
  ├── conta já existe ──→ ver ONB-R27
  ↓ conta nova
  → Nome
  → Telefone ──(Continue / Skip for now)──→ sessão começa (ONB-R02a)
  → Find friends ──(Continue)──→ pedido de acesso aos contatos
  → Contacts ──(Next)──→ fim do Onboarding → Quiz (QUIZZ.md)
```

**Para TDD:** o fluxo é uma máquina de estados pura, sem UI:

```swift
enum OnboardingStep { case splash, welcome, legal, signIn, name, phone, findFriends, contacts, done }

struct OnboardingFlow {
    func next(from: OnboardingStep, state: OnboardingState) -> OnboardingStep
    func back(from: OnboardingStep) -> OnboardingStep?
}
```

`done` quer dizer que o Onboarding acabou; quem abre o Quiz a partir daí é o coordenador da app (ONB-R21).

As validações são funções puras e separadas: `NameValidator`, `PhoneValidator` e `PhoneNormalizer` (para o formato E.164 usado pela chave de contato, ARCHITECTURE §4.4).

**ONB-R00 · Contador.** O cadastro tem 2 passos com contador, Nome e Telefone, que mostram "01 / 02" e "02 / 02". O Splash, a Welcome, a tela Legal, Find friends e Contacts não têm contador.

## 3. Entrada na app

**ONB-R01 · Splash.** Toda abertura da app mostra o Splash: a animação dos cachos de uva sobre o fundo verde, sem texto. São 7 quadros, que trocam a cada 180 ms. Na primeira abertura, o conteúdo do bundle é copiado para o SwiftData enquanto o Splash e o Onboarding correm (ARCHITECTURE §2.2).

**ONB-R02 · Para onde vai depois do Splash.**

| Situação | Vai para |
| --- | --- |
| Sem sessão | Welcome |
| Com sessão e com mapa do paladar | Home |
| Com sessão e sem mapa (o Quiz não foi concluído) | Quiz, na Intro (QUIZ-R13a) |

**ONB-R02a · Quando a sessão começa.** A sessão é guardada quando o usuário sai do Telefone, com "Continue" ou com "Skip for now". Antes disso, nada fica guardado: se a app fechar na Welcome, no login ou no Nome, o cadastro recomeça da Welcome. Depois disso, a sessão existe e não tem mapa, por isso a app abre na Intro do Quiz (ONB-R02); Find friends e Contacts não voltam a aparecer, e os amigos passam a ser adicionados pela aba Friends.

**Critérios**
- Dada uma instalação nova, então depois do Splash abre a Welcome.
- Dada uma sessão ativa com mapa, então depois do Splash abre a Home, sem passar pelo Onboarding.
- Dada uma sessão ativa sem mapa, então depois do Splash abre a Intro do Quiz.
- Dado o nome preenchido no Nome, quando a app é fechada e aberta de novo, então abre a Welcome.
- Dado o Telefone concluído, quando a app é fechada em Find friends e aberta de novo, então abre a Intro do Quiz.

## 4. Passos

### 4.0 Welcome

**ONB-R28 · Conteúdo.** O logo UVVA e "Welcome. Let's find the wines you'll love." sobre a imagem de fundo. Por baixo, "By continuing you agree to the Terms and the Privacy Policy.", com dois links que abrem a tela Legal (4.1). O logo, o título e os botões entram com uma animação curta.

**ONB-R29 · Ações.**

| Ação | Faz |
| --- | --- |
| Continue with Apple | Sign in with Apple, do iOS |
| Continue with Google | Login com a conta Google |

Depois do login, uma conta nova segue para o Nome; uma conta que já existe segue a ONB-R27.

**ONB-R30 · Criar e entrar são o mesmo botão.** Não há "Log in" separado. A conta é reconhecida pela identidade do provedor (Apple ou Google) e pelo perfil guardado no iCloud do usuário (ONB-R27).

**ONB-R31 · Aceitação.** Tocar em qualquer um dos dois botões vale como aceitação dos Termos e da Política de Privacidade.

**ONB-R38 · Login cancelado ou falhado.** Se o usuário fechar a folha da Apple ou do Google, ou o login falhar, a app fica na Welcome, sem mensagem. Uma falha de rede mostra um aviso curto (ver D21).

**Critérios**
- Quando o usuário toca em "Continue with Apple" e conclui o login com uma conta nova, então abre o Nome.
- Quando o usuário cancela a folha do login, então continua na Welcome.
- Quando o usuário toca em "Privacy Policy", então abre a tela Legal na aba Privacy, e "I understand" volta à Welcome.

### 4.1 Termos e Privacidade

**ONB-R08 · Tela Legal.** "Legal" no topo e o botão de voltar. Duas abas, Terms e Privacy; o título muda para "Terms of Use" ou "Privacy Policy". Mostra "Last updated [data]" e as seções do documento. "I understand" e o voltar fecham a tela e voltam à Welcome.

**ONB-R08a · Texto provisório.** O texto atual é um mock e será reescrito. Ele fala em módulos pagos, pagamentos, código de confirmação e lembrete escolhido no setup, o que não vale nesta versão (SHARED-R01). O texto final tem de explicar o uso do telefone para os amigos (ARCHITECTURE §4.4). Os testes verificam a estrutura da tela (abas, título, seções), nunca o texto.

### 4.2 01 · Nome

**ONB-R14 · Conteúdo.** "And what should we call you?" e "Your first name is enough. We took it from your account; change it if you like."

**ONB-R14a · Pré-preenchido.** O campo abre com o primeiro nome que a Apple ou o Google devolveram no login. Se o provedor não devolveu nome (a Apple só o envia na primeira autorização, e o usuário pode escondê-lo), o campo abre vazio.

**ONB-R15 · Validação.** O nome é válido com pelo menos 2 caracteres, ignorando espaços no início e no fim. A dica mostra "At least two letters" enquanto o nome for inválido e "Nice to meet you" quando for válido. "Continue" só fica ativo com o nome válido.

**ONB-R16 · Guardar.** Guarda-se o nome sem os espaços das pontas. É ele que aparece em "Welcome, [nome]" e no resto da app.

**Critérios**
- Dado o login com Apple que devolveu "Elisa", então o campo abre com "Elisa" e "Continue" está ativo.
- Dado um login sem nome, então o campo abre vazio e "Continue" está inativo.
- Dado "E", então a dica é "At least two letters" e "Continue" está inativo.
- Dado "  E  ", então o nome continua inválido.
- Dado "  Elisa ", então o nome guardado é "Elisa".

### 4.3 02 · Telefone

**ONB-R03 · Conteúdo.** "What is your phone number?" e "So friends who have you in their contacts can find you here. We never send you a code or a message." Vazio, o campo mostra o exemplo "+351 912 345 678" esmaecido.

**ONB-R03a · Para que serve.** O telefone serve só para os amigos encontrarem a pessoa no Quick add (FRI-R07). Ele não é verificado, não é a conta e nunca recebe mensagens.

**ONB-R04 · Indicativo.** Não há seletor de país: o número é digitado com o indicativo, num teclado próprio de telefone (1 a 9 com as letras, "0 / +", ⌫ e uma tecla "+*#" sem ação). Os primeiros dígitos aparecem como indicativo ("+351") e o resto agrupado de 3 em 3. O campo aceita no máximo 12 dígitos (ver D8).

**ONB-R05 · Validação.** "Continue" só fica ativo quando o campo tem 12 dígitos, indicativo incluído.

**ONB-R35 · Opcional.** Enquanto o campo está vazio, aparecem "Optional. You can still add friends with your invite link." e "Skip for now". Ao digitar o primeiro dígito, esse bloco some e "Continue" aparece no lugar; ao apagar tudo, volta.

**ONB-R07 · Guardar.** "Continue" guarda o número no perfil, em E.164, e publica a chave de contato (ARCHITECTURE §4.4). "Skip for now" segue sem número e sem chave. Os dois começam a sessão (ONB-R02a) e abrem Find friends.

**ONB-R07a · Número já usado.** Se outra conta já registou a mesma chave, o número fica guardado só no perfil, sem chave, e a conta não aparece no Quick add por esse número (ver D20).

**Critérios**
- Dado o campo vazio, então aparecem "Optional…" e "Skip for now", e "Continue" não aparece.
- Dado "3" digitado, então "Skip for now" some e "Continue" aparece, inativo.
- Dado "351912345678" (12 dígitos), então "Continue" está ativo.
- Dados 12 dígitos, quando o usuário toca em mais um, então o campo continua com 12.
- Quando o usuário toca em "Skip for now", então a sessão começa sem telefone e abre Find friends.
- Dado "351912345678", quando o usuário toca em "Continue", então o perfil guarda "+351912345678" e é publicada 1 chave de contato.

### 4.4 Find friends

**ONB-R36 · Conteúdo.** "Find friends", "Add your closest friends to start comparing palates.", a ilustração de uva e "UVVA is better with friends. Add them now and, once they accept, you will see where your palates meet and what to open together." No rodapé, com um cadeado: "We will never do anything creepy like spam or auto-add your friends."

**ONB-R36a · Contatos.** "Continue" pede o acesso aos contatos do iOS. Com acesso dado, abre Contacts. Com acesso recusado, o Onboarding acaba e abre o Quiz (ONB-R21); os amigos podem ser adicionados depois pela aba Friends.

### 4.5 Contacts

**ONB-R37 · Conteúdo.** "Contacts" no topo, com o voltar, e duas listas:
- **"[n] of your contacts are on UVVA":** os contatos da agenda que têm conta e mapa (FRI-R01, FRI-R07). Cada linha tem a foto, o nome, uma frase do paladar e "Add". Tocar em "Add" envia um pedido de amizade e o botão passa a "Requested" (FRI-R08).
- **"Invite contacts who aren't on UVVA":** os outros contatos, com as iniciais, o nome e "Invite". Tocar em "Invite" abre a partilha do convite (HOME-R11, SHARED-R20) e o botão passa a "Invited".

Uma barra de A a Z permite saltar na lista. "Next" acaba o Onboarding (ONB-R21).

**Critérios**
- Dado um contato com conta e mapa, então ele aparece na primeira lista.
- Dado um contato com conta e sem mapa, então ele não aparece em nenhuma das listas (FRI-R01).
- Quando o usuário toca em "Add" num contato, então é criado 1 pedido de amizade e o botão diz "Requested".

### 4.6 Voltar

**ONB-R20 · Voltar.** No Nome, voltar abre a Welcome (e o login tem de ser feito de novo). No Telefone, voltar abre o Nome com o valor digitado. Find friends não tem voltar, porque a sessão já começou. Em Contacts, voltar abre Find friends.

### 4.7 Fim do Onboarding

**ONB-R21 · Abrir o Quiz.** "Next" em Contacts, ou o acesso aos contatos recusado em Find friends, abre a Intro do Quiz (QUIZ-R06) pela entrada "primeiro mapa" (QUIZ-R24). O que acontece depois do Quiz é definido em `QUIZZ.md` (QUIZ-R25) e o tour guiado em `HOME.md` (HOME-R29).

**Critérios**
- Quando o usuário toca em "Next" em Contacts, então abre a Intro do Quiz.

## 5. Conta já existente

**ONB-R27 · Entrar de novo.** Depois do login na Welcome, a app procura o perfil da conta no iCloud do usuário (ARCHITECTURE §4.2). Se o encontra:

| Conta | Vai para |
| --- | --- |
| Com mapa do paladar | Home, com o Cellar, o mapa e o progresso da conta. Nome, Telefone, Find friends e Quiz são pulados; o tour guiado segue a HOME-R29 (uma vez por conta) |
| Sem mapa | Quiz, na Intro (QUIZ-R06) |

**ONB-R27a · Os dados vêm do iCloud.** Os dados ficam no iCloud do aparelho, não na conta Apple ou Google. Num iPhone com outro iCloud, o mesmo login começa uma conta vazia (ver D19).

**Critérios**
- Dado um perfil com mapa no iCloud, quando o usuário entra com a mesma conta, então abre a Home sem passar por Nome, Telefone e Quiz.
- Dado um perfil sem mapa no iCloud, quando o usuário entra, então abre a Intro do Quiz.

## 6. Fora de escopo

- O Quiz e o que acontece depois dele: `QUIZZ.md`.
- O tour guiado: `HOME.md` (HOME-R29 a R33).
- Receber e aceitar pedidos de amizade: `FRIENDS.md` (FRI-R08a).
- O texto jurídico de Termos e Privacidade.
- Planos e pagamentos (SHARED-R01).

### Regras que saíram deste documento

| Regra antiga | Para onde foi | Versão |
| --- | --- | --- |
| ONB-R22 a R26 · Depois do Quiz e tour | QUIZ-R25, HOME-R30 a R33 | v0.3 |
| ONB-R19 · Newsletter | Removida | v0.4 |
| ONB-R06 · Termos no Telefone | Removida: a aceitação é na Welcome (ONB-R31) | v0.5 |
| ONB-R09 a R13 · Código por SMS | Removidas: sem SMS (custo zero) | v0.5 |
| ONB-R17, R18, R34 · E-mail | Removidas: sem e-mail na conta; os certificados ficam no aparelho (ARCHITECTURE §2.1) | v0.5 |
| ONB-R32, R33 · Senha | Removidas: o login é com Apple ou Google | v0.5 |
| ONB-R35 antiga · Apple e Google no Telefone | Os botões voltaram para a Welcome (ONB-R29); a ONB-R35 passa a ser o Telefone opcional | v0.5 |

### O que mudou no canvas desde a v0.4

- Welcome: "Get started" e "Already have an account" viram "Continue with Apple" e "Continue with Google".
- Saem as telas Código, Senha e E-mail.
- O Nome passa para antes do Telefone; o contador passa a "/ 02".
- Telefone: novo texto, sem código; "Skip for now" no lugar de Apple e Google.
- Entram Find friends e Contacts, com pedidos de amizade ("Requested").

## 7. Decisões

| # | Pergunta | Decisão | Regra |
| --- | --- | --- | --- |
| D1 | Contador | Vai até o número real de passos: "/ 02" | ONB-R00 |
| D2 | Termos com pagamentos | O texto atual fica como mock | ONB-R08a |
| D6 | Conta existente | Pula para a Home só se a conta já tiver mapa | ONB-R27 |
| D7 | Sair no meio do cadastro | Recomeça da Welcome, até a sessão começar | ONB-R02a |
| D13 | Senha | Não há senha | — |
| D18 | Como criar a conta sem custo | Apple ou Google, sem SMS nem e-mail (2026-10-31) | ONB-R29 |
| D22 | Telefone | Opcional e não verificado, só para o Quick add (2026-10-31) | ONB-R03a, R35 |

As dúvidas D3, D3b, D4, D5, D11, D14, D15, D16 e D17 da v0.4 deixaram de existir com a v0.5.

## 8. Dúvidas em aberto

- [x] **D8 · Indicativo.** Volta o seletor de país (o chip de vidro do canvas), com o país do aparelho por padrão. O número vale quando o tamanho cabe no plano do país; o prefixo de longa distância ("0") é retirado; grava-se em E.164. 42 países no `PhoneCountries` (2026-10-31).
- [x] **D10 · Splash.** No mínimo uma volta dos 7 cachos (1,26 s), e até as lojas abrirem e a sessão ser verificada. Não espera o catálogo: o import corre por trás do Onboarding (2026-10-31).
- [ ] **D12 · Apple e Google.** Se a pessoa escolher esconder o e-mail na Apple, nada muda (a conta não usa e-mail). Mas uma conta criada com Apple pode depois entrar com Google, ou são contas separadas?
- [ ] **D19 · Outro iCloud.** Com o mesmo login Google num iPhone com outro iCloud, a conta começa vazia (ONB-R27a). A app avisa? Bloqueia?
- [ ] **D20 · Número já usado.** Quando o número digitado já tem uma chave de outra conta (ONB-R07a), a app avisa o usuário, ou guarda em silêncio?
- [x] **D21 · Login sem rede.** Na Welcome, por cima do botão: "Could not reach Apple. Check your connection and try again." (provisório, 2026-10-31).
- [x] **Sem iCloud.** A Welcome diz "UVVA keeps your account in iCloud. Sign in to iCloud in Settings, then come back." e o botão fica inativo.
- [ ] **Google.** Só Sign in with Apple nesta versão; o botão Google não aparece.
- [ ] **D23 · Telefone depois.** Quem pulou o Telefone pode adicioná-lo depois em You › Settings (YOU-R14)?
