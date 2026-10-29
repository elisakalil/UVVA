# UVVA · Onboarding

> Status: rascunho v0.2 · 2026-10-27 · D1–D4, D6 e D7 respondidas
> Depende de: [`_shared.md`](_shared.md), [`quiz.md`](quiz.md)
> Fonte: canvas UVVA App, telas 01 a 12 do Onboarding.

## 1. Objetivo

O Onboarding leva a pessoa da primeira abertura da app até a Home: cria a conta com o número de telefone (sem senha), pede o primeiro nome e o e-mail, abre o Quiz para desenhar o mapa do paladar e termina com um tour guiado.

O Quiz é uma feature à parte (`quiz.md`). Aqui só se define quando ele abre e o que acontece depois.

## 2. Fluxo

```
Splash
  → 01/04 Telefone ──(link)──→ Termos e Privacidade ──(I understand)──┐
  ↓                                                                   │
  → 02/04 Código  ←───────────────────────────────────────────────────┘
  → 03/04 Nome
  → 04/04 E-mail
  → Quiz (quiz.md) → Resultado → [Partilhar o mapa]
  → Tour guiado (intro + 6 passos)
  → Home
```

**Para TDD:** o fluxo é uma máquina de estados pura, sem UI:

```swift
enum OnboardingStep { case splash, phone, legal, code, name, email, quiz, tour, done }

struct OnboardingFlow {
    func next(from: OnboardingStep, state: OnboardingState) -> OnboardingStep
    func back(from: OnboardingStep) -> OnboardingStep?
}
```

As validações são funções puras e separadas: `PhoneValidator`, `CodeValidator`, `NameValidator`, `EmailValidator` e `PhoneMasker`.

**ONB-R00 · Contador.** O cadastro tem 4 passos, e o contador de cada um mostra "01 / 04" a "04 / 04".

## 3. Entrada na app

**ONB-R01 · Splash.** Toda abertura da app mostra o Splash ("UVVA", "in vino veritas").

**ONB-R02 · Para onde vai depois do Splash.**

| Situação | Vai para |
| --- | --- |
| Sem sessão | 01/04 Telefone |
| Com sessão e com mapa do paladar | Home |
| Com sessão e sem mapa (o Quiz não foi concluído) | Quiz, na Intro (QUIZ-R13a) |

**ONB-R02a · Quando a sessão começa.** A sessão só é guardada quando o usuário conclui 04/04 (E-mail). Antes disso, nada fica guardado no aparelho: se a app fechar em 02/04, 03/04 ou 04/04, o cadastro recomeça no Telefone, com os campos vazios.

**Critérios**
- Dada uma instalação nova, então depois do Splash abre o Telefone.
- Dada uma sessão ativa com mapa, então depois do Splash abre a Home, sem passar pelo Onboarding.
- Dada uma sessão ativa sem mapa, então depois do Splash abre a Intro do Quiz.
- Dado o nome preenchido em 03/04, quando a app é fechada e aberta de novo, então abre o Telefone com o campo vazio.

## 4. Passos

### 4.1 01/04 · Telefone

**ONB-R03 · Conteúdo.** "What is your phone number?" e "We send a six digit code to confirm it is you. No password to remember."

**ONB-R04 · País.** Um seletor com 6 países e o indicativo de cada um:

| País | Indicativo |
| --- | --- |
| Portugal | +351 |
| España | +34 |
| France | +33 |
| Italia | +39 |
| United Kingdom | +44 |
| Brasil | +55 |

O país escolhido aparece destacado na lista. Escolher um país fecha a lista.

**ONB-R05 · Validação.** "Send code" só fica ativo quando o número tem pelo menos 9 dígitos. Espaços e outros caracteres são ignorados na contagem.

**ONB-R06 · Termos.** O texto "By continuing you agree to the Terms and the Privacy Policy" tem dois links, que abrem a tela Legal (4.2). Tocar em "Send code" vale como aceitação dos dois documentos.

**ONB-R07 · Enviar.** "Send code" envia um código de 6 dígitos por SMS para o indicativo + número e abre 02/04.

**Critérios**
- Dado "912 345 67" (8 dígitos), então "Send code" está inativo.
- Dado "912 345 678" (9 dígitos), então "Send code" está ativo.
- Dado "912-345-678", então conta 9 dígitos e o botão está ativo.
- Dado o país France escolhido, então o indicativo mostrado é +33 e a lista fecha.

### 4.2 Termos e Privacidade

**ONB-R08 · Tela Legal.** Duas abas, Terms e Privacy. O título muda para "Terms of Use" ou "Privacy Policy". Mostra "Last updated [data]" e as seções do documento. "I understand" fecha a tela e volta ao Telefone, com o número digitado preservado.

**ONB-R08a · Texto provisório.** O texto atual de Termos e Privacidade é um mock e será reescrito depois. Ele fala em módulos pagos e pagamentos, o que não vale nesta versão (SHARED-R01). Os testes verificam a estrutura da tela (abas, título, seções), nunca o texto.

### 4.3 02/04 · Código

**ONB-R09 · Conteúdo.** "Enter the code we sent you" e "Sent to [indicativo] [número mascarado]".

**ONB-R10 · Máscara.** Todos os dígitos do número aparecem como "•", exceto os 3 últimos.

**ONB-R11 · Digitação.** O código tem 6 casas e um teclado próprio, de 0 a 9 com ⌫. Cada dígito preenche a próxima casa vazia. A partir de 6 dígitos, os toques seguintes são ignorados. ⌫ apaga o último dígito.

**ONB-R12 · Confirmar.** "Confirm" só fica ativo com os 6 dígitos preenchidos.

**ONB-R13 · Reenviar.** "Resend in m:ss" mostra uma contagem regressiva, a mais curta que o provedor de SMS permitir (valor de configuração, `resendCooldown`; 30 s até haver provedor). Ao chegar a 0:00, vira "Resend", que envia um código novo e reinicia a contagem.

**Critérios**
- Dado o número "912345678", então a máscara é "••••••678".
- Dados 5 dígitos, então "Confirm" está inativo; com o sexto, fica ativo.
- Dados 6 dígitos, quando o usuário toca em mais um, então o código continua com 6 dígitos.
- Dado o código "4821", quando o usuário toca em ⌫, então o código fica "482".
- Dado o código vazio, quando o usuário toca em ⌫, então nada muda.
- Dado `resendCooldown` = 30 s, quando passam 29 s, então aparece "Resend in 0:01" e o botão está inativo; aos 30 s, aparece "Resend" ativo.

### 4.4 03/04 · Nome

**ONB-R14 · Conteúdo.** "And what should we call you?" e "Your first name is enough."

**ONB-R15 · Validação.** O nome é válido com pelo menos 2 caracteres, ignorando espaços no início e no fim. A dica mostra "At least two letters" enquanto o nome for inválido e "Nice to meet you" quando for válido. "Continue" só fica ativo com o nome válido.

**ONB-R16 · Guardar.** Guarda-se o nome sem os espaços das pontas. É ele que aparece em "Welcome, [nome]" e no resto da app.

**Critérios**
- Dado "E", então a dica é "At least two letters" e "Continue" está inativo.
- Dado "  E  ", então o nome continua inválido.
- Dado "Elisa", então a dica é "Nice to meet you" e "Continue" está ativo.
- Dado "  Elisa ", então o nome guardado é "Elisa".

### 4.5 04/04 · E-mail

**ONB-R17 · Conteúdo.** "Where do we send your certificate?" e "Your e-mail is used for the module certificates and to recover your account." Os certificados são enviados para este e-mail automaticamente (LEARN-R22a).

**ONB-R18 · Validação.** O e-mail é válido quando tem texto, "@", texto, "." e texto, nessa ordem (`.+@.+\..+`). "Continue" só fica ativo com o e-mail válido.

**ONB-R19 · Newsletter.** Uma caixa opcional, "Send me the weekly stories from the vineyards". Começa **desmarcada**, porque pela RGPD um consentimento já marcado não vale. O valor é guardado com a conta.

**Critérios**
- Dados "elisa", "elisa@" e "elisa@uvva", então "Continue" está inativo.
- Dado "elisa@uvva.wine", então "Continue" está ativo.
- Ao abrir a tela, então a caixa da newsletter está desmarcada.
- Dada a caixa marcada, quando o usuário toca nela, então ela fica desmarcada.

### 4.6 Voltar

**ONB-R20 · Voltar preserva.** Em 02/04, 03/04 e 04/04, o botão de voltar abre o passo anterior com o valor já digitado. Voltar de 02/04 para 01/04 invalida o código enviado (ver D5).

**Critérios**
- Dado "Elisa" em 03/04, quando o usuário vai a 04/04 e volta, então 03/04 mostra "Elisa".

### 4.7 Quiz

**ONB-R21 · Abrir o Quiz.** Depois do último passo de cadastro, abre a Intro do Quiz (QUIZ-R06), com o primeiro nome guardado em ONB-R16.

**ONB-R22 · Depois do Quiz.** "Keep this map" (QUIZ-R18) abre o tour guiado. A partilha do mapa é opcional: "Not now" na folha de partilha também segue para o tour.

### 4.8 Tour guiado

**ONB-R23 · Intro.** "Your map is ready", "Welcome in, [nome]", "A short walk through where things live in UVVA." e o botão "Show me".

**ONB-R24 · Passos.** São 6 passos sobre a Home, cada um destacando uma área:

| # | Passo | Título | Área destacada |
| --- | --- | --- | --- |
| 1 | Today | A pairing drawn for your palate | Sugestão do dia |
| 2 | Your wine | Choose your wine | Escolha o seu vinho |
| 3 | Scan | Scan a label | Botão + |
| 4 | Learn | Learn the wines you love | Aba Learn |
| 5 | Cellar | Your cellar | Aba Cellar |
| 6 | Friends | Set a table | Aba Friends |

**ONB-R25 · Navegação.** O contador mostra "N of 6". "Next" avança; no passo 6, o botão diz "Start". "Back" volta um passo. Tocar num dos pontos de progresso abre esse passo.

**ONB-R26 · Fim.** "Start" fecha o tour e abre a Home. O tour é mostrado uma única vez por conta.

**Critérios**
- Dado o passo 1, então o contador mostra "1 of 6" e o botão diz "Next".
- Dado o passo 6, então o botão diz "Start".
- Dado o passo 4, quando o usuário toca no ponto 2, então abre o passo 2.
- Quando o usuário toca em "Start", então abre a Home e o tour fica marcado como visto.
- Dado o tour já visto, quando a app abre de novo, então o tour não aparece.

## 5. Conta já existente

**ONB-R27 · Entrar de novo.** Ao confirmar o código em 02/04, se o número já tem conta:

| Conta | Vai para |
| --- | --- |
| Com mapa do paladar | Home, com o Cellar, o mapa e o progresso da conta. Nome, E-mail, Quiz e tour são pulados |
| Sem mapa | Quiz, na Intro (QUIZ-R06). A conta já tem nome e e-mail, porque só existe depois de 04/04 (ONB-R02a) |

**Critérios**
- Dado um número com conta e com mapa, quando o código é confirmado, então abre a Home sem passar por Nome, E-mail, Quiz e tour.
- Dado um número com conta e sem mapa, quando o código é confirmado, então abre a Intro do Quiz, sem passar por Nome e E-mail.

## 6. Fora de escopo

- O Quiz em si: `quiz.md`.
- O texto jurídico de Termos e Privacidade.
- Planos e pagamentos (SHARED-R01).

## 7. Decisões

| # | Pergunta | Decisão (2026-10-27) | Regra |
| --- | --- | --- | --- |
| D1 | Passo 05/05 sem tela | O cadastro tem 4 passos, e o contador vai até 04 | ONB-R00 |
| D2 | Termos com pagamentos | O texto atual fica como mock, a ser refeito | ONB-R08a |
| D3 | Reenviar o código | A contagem mais curta possível, configurável | ONB-R13 |
| D4 | Newsletter marcada | Começa desmarcada | ONB-R19 |
| D6 | Conta existente | Pula para a Home só se a conta já tiver mapa | ONB-R27 |
| D7 | Sair no meio do cadastro | Recomeça no Telefone | ONB-R02a |

## 8. Dúvidas em aberto

- [ ] **D3b · Código errado.** O que acontece com um código errado: mensagem de erro, apagar as casas, limite de tentativas? Quanto tempo o código vale?
- [ ] **D5 · Mudar o número.** Voltar do Código para o Telefone e mudar o número envia um código novo e invalida o anterior?
- [ ] **D8 · País padrão.** O país inicial é Portugal sempre, ou segue a região do aparelho (por exemplo, Brasil num aparelho brasileiro)? E um país fora da lista?
- [ ] **D9 · Tour.** O tour pode ser pulado? E pode ser visto de novo depois (por exemplo, em You › Settings)?
- [ ] **D10 · Splash.** Quanto tempo o Splash fica na tela? Ele só espera o carregamento, ou tem uma duração mínima?
