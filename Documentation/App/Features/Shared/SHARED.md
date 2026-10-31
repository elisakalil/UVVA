# UVVA · Regras compartilhadas

Regras e conceitos usados por mais de uma feature. Cada feature aponta para cá pelo ID (`SHARED-Rxx`) em vez de repetir a regra.

> Status: rascunho v0.1 · 2026-10-27

---

## 1. Escopo desta versão

- **SHARED-R01 · Sem planos.** A app é 100% gratuita. Não existem plano grátis, Premium, paywall, limites diários ou mensais, nem compras avulsas. Todo conteúdo e toda ação estão disponíveis para todos os usuários.
  - Qualquer tela de limite ou paywall do canvas (Lesson limit, Notes limit, Table locked, Paywall) está **fora de escopo**.
  - Quando planos forem definidos, entram como uma feature própria (`plans.md`) e não alteram as regras abaixo.

## 2. Datas e tempo

- **SHARED-R02 · Relógio do aparelho.** Toda regra baseada em data ou hora usa o relógio e o fuso horário do aparelho.
- **SHARED-R03 · "Dia".** Um dia é o dia de calendário local, de 00:00 a 23:59 no fuso do aparelho. "Muda todo dia" significa que o valor muda na primeira vez que a feature é montada num dia novo e fica estável até o fim desse dia.
- **SHARED-R04 · Relógio injetável.** Nenhuma regra lê a data diretamente: todas recebem um `Clock` (ou `now: Date` + `Calendar`) por parâmetro, para que os testes possam fixar o dia.

**Critérios**
- Dado o aparelho em Lisboa às 23:59 e depois às 00:00 do dia seguinte, quando uma regra "diária" é avaliada nos dois instantes, então os resultados são de dias diferentes.
- Dado o fuso do aparelho alterado para São Paulo, quando a regra é avaliada, então o "dia" passa a ser o de São Paulo.

## 3. Mapa do paladar

- **SHARED-R05 · Origem.** O mapa do paladar é criado no Quiz (ver `quiz.md`) e é composto por eixos com valores numéricos. A lista de eixos e a escala são definidas em `quiz.md`.
- **SHARED-R06 · Pré-condição.** Todo usuário que chega às abas principais (Home, Learn, Cellar, Friends, You) tem um mapa do paladar. As abas não precisam tratar "sem mapa" para o próprio usuário.
- **SHARED-R07 · Similaridade.** Existe uma função única `similarity(wine, palateMap) -> Double` (0 a 1) usada por todas as features que ordenam vinhos "pelo paladar". O cálculo é definido em `quiz.md`; as outras features só dependem da ordem que ela produz.

## 4. Avaliação de vinhos

- **SHARED-R08 · Veredito.** Avaliar um vinho é responder "Would you drink it again?" com **Yes**, **Maybe** ou **No**. Não existe outro valor.
- **SHARED-R09 · Efeito no mapa.** Cada avaliação recalcula o mapa do paladar:
  - Yes aproxima o mapa do perfil do vinho.
  - Maybe aproxima pouco.
  - No afasta.
  - A intensidade exata de cada efeito é definida em `quiz.md`.
- **SHARED-R10 · Variação registrada.** Cada avaliação guarda a variação de cada eixo (`axis`, `before`, `after`) e a data. A "última avaliação" é a de data mais recente, venha ela da Home ou do Cellar.
- **SHARED-R11 · Vinho avaliado.** Um vinho é considerado "avaliado" se o usuário tem pelo menos uma avaliação dele, em qualquer lugar da app.

## 5. Amigos

- **SHARED-R12 · Quem é amigo.** Um amigo é um contato da agenda do aparelho que também usa a UVVA e foi adicionado como amigo (ver `friends.md`).
- **SHARED-R13 · Todo amigo tem mapa.** Só se usa a UVVA depois de concluir o Quiz, por isso todo amigo tem mapa do paladar. Um usuário sem o Quiz concluído não aparece como amigo nem como sugestão (FRI-R01).
- **SHARED-R13a · Match.** A compatibilidade entre mapas e a montagem das mesas são definidas em `match.md` (a escrever).

## 6. Aprendizagem

- **SHARED-R14 · Estrutura.** Um curso ou módulo tem lições ordenadas; uma lição tem passos ordenados (ver `learn.md`).
- **SHARED-R15 · Lição concluída.** Uma lição está concluída quando o usuário chega ao passo final (Summary).
- **SHARED-R16 · Módulo em andamento.** Um módulo está em andamento quando tem pelo menos uma lição iniciada (o usuário abriu o primeiro passo) e nem todas as lições estão concluídas.
- **SHARED-R17 · Ponto de retomada.** Para cada módulo guarda-se a lição e o passo onde o usuário parou, e a data da última abertura (`lastOpenedAt`).

## 7. Glossário

- **SHARED-R18 · Fonte única.** O glossário é uma lista de termos com termo, pronúncia, definição, sinônimos e a lição de origem. A Home, as lições e a busca do Learn leem da mesma lista.

## 8. Linguagem da interface

- **SHARED-R19 · Textos.** A interface fala diretamente com o usuário e não usa ponto de exclamação nem emoji (ver o README do design system UVVA).
- **SHARED-R19a · Idiomas.** A app existe em dois idiomas: **inglês** e **português do Brasil**. Os textos citados nestes arquivos estão em inglês; cada um tem a sua tradução em pt-BR. No futuro serão 6 idiomas (English, Português, Español, Français, Italiano, Deutsch), por isso nenhum texto fica escrito direto no código: todos vêm de um arquivo de strings.

## 8a. Partilha

- **SHARED-R20 · Formatos.** Toda partilha da app (mapa do paladar, convite da Home, certificados e mesas) tem os mesmos três formatos: **Story** (Instagram, imagem 9:16), **WhatsApp** (imagem 4:5 com mensagem) e **Save image** (guarda nas fotos). "Not now" fecha. Não existe formato Link.

---

## Dúvidas em aberto

- [ ] Comportamento offline em geral: as abas mostram os últimos dados guardados ou um estado de erro?
- [x] Um amigo é adicionado manualmente, com "Add" no Quick add (FRI-R08).
