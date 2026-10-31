# UVVA

O **UVVA** é um app de enologia: serve para aprender sobre vinho, descobrir o próprio paladar, guardar as garrafas que se provam e montar a mesa com os amigos.

> **Importante:** o UVVA é o app desenhado nos três artefatos abaixo. Eles são a fonte de verdade de telas, fluxos, features, lógica e visual. **Sempre que uma nova feature for pedida, consulte estes artefatos antes de implementar** — para ver as telas envolvidas, os textos, as regras de negócio e os componentes/tokens que devem ser usados.

| Artefato | O que contém | Link |
| --- | --- | --- |
| **UVVA Telas** | Canvas com todas as telas do app: abas, fluxos, conteúdo para redes sociais | https://claude.ai/artifact/PTn5HAAHL3Qf14aTg7p4BG |
| **UVVA Simulador** | O app navegável dentro de um telemóvel (protótipo interativo), mais o glossário e as lições que ele abre | https://claude.ai/artifact/4nmqXf9HwpWTwCczZXBjZZ |
| **UVVA Design System** | Tokens (cor, tipografia, espaçamento, raios, sombras), fontes, ícones, assets e componentes (`window.UVVA`) | https://claude.ai/artifact/BNyqWgdwCQkHFTxa15yAbN |

## Como consultar

- **Telas / lógica de uma feature** → *UVVA Telas*. Cada artboard é um arquivo `project/<Nome>.dc.html`; o índice está em `project/canvas.json`.
- **Comportamento e navegação** → *UVVA Simulador* (`project/Main.dc.html`), que mostra como as telas se ligam e reagem.
- **Visual, componentes e regras de UI** → *UVVA Design System*, começando por `project/README.md`, depois `project/api/tokens.md` e `project/api/components/<Comp>.md`.

Use a ação `read` do Artifact tool com o link acima (e `path` para um arquivo específico).

## Features

### Abas principais (tab bar)

Cada aba tem um `.MD` próprio com as regras de negócio em `Documentation/<Feature>/` — consulte-o antes de implementar ou alterar a feature.

- **Home** — Boas-vindas personalizadas, "Word of the day" (termo do glossário com pronúncia), vinhos recomendados para o paladar ("Wines for your palate"), "Find my wine" (diz o que apetece hoje e o app sugere), detalhe de vinho com "The map of this wine" / "This wine and you" (match com o mapa de paladar), "Set the table" e convite de amigos. Regras de negócio: [`Documentation/Home/HOME.md`](Documentation/Home/HOME.md).
- **Learn** — Cursos e lições de vinho (castas, regiões, como provar). Partilha do que se aprendeu (link, WhatsApp, Instagram story). Regras de negócio: [`Documentation/Learn/LEARN.md`](Documentation/Learn/LEARN.md).
- **Cellar** — O caderno de provas: garrafas guardadas com foto do rótulo do próprio utilizador, veredito **Yes / Maybe / No**, vista em grade (magazine) ou lista, filtros por Tag, Type, Grape, Region e Producer, estado vazio. Regras de negócio: [`Documentation/Cellar/CELLAR.md`](Documentation/Cellar/CELLAR.md).
- **Friends** — Mesas a partir dos mapas de paladar: "Tables for two" (com um amigo) e "Group table". Gera o "Perfect dinner": menu de três pratos com três vinhos (Starter / Main / Dessert), "Shopping guide" ("Ask for: …"), partilha para stories e convite por link. Regras de negócio: [`Documentation/Friends/FRIENDS.md`](Documentation/Friends/FRIENDS.md).
- **You** — Perfil: progresso, certificados de módulo (com partilha), Daily reminder (hora e dias da semana), definições e sign out. Regras de negócio: [`Documentation/You/YOU.md`](Documentation/You/YOU.md).

### Fluxos

- **Onboarding** — Splash, Welcome com login pela Apple ou pelo Google (sem SMS, senha nem e-mail), nome, telefone opcional para os amigos encontrarem a pessoa, termos, encontrar amigos nos contatos, questionário de paladar → **Palate map** ("Your map is ready", "Your readings"), partilha do mapa e tour rápido pelo app. Regras de negócio: [`Documentation/Onboarding/ONBOARDING.md`](Documentation/Onboarding/ONBOARDING.md); arquitetura: [`Documentation/Architecture/ARCHITECTURE.md`](Documentation/Architecture/ARCHITECTURE.md).
- **Lessons** — O player das lições: conceitos, perguntas com opções (respostas corretas/erradas), Uvva tips e Summary com brinde em várias línguas (Santé, Saúde, Kanpai…). Regras de escrita, tom, XP e o conteúdo de cada tab do Learn: [`Documentation/Lesson/`](Documentation/Lesson/LESSON.md) (`LESSON.md`, `PATH.MD`, `GRAPE.MD`, `REGION.MD`).
- **Glossário** — Pesquisa de termos de vinho, acessada por um card na Home. Não aparece dentro das lições.

## Identidade em resumo

- Interface em inglês, voz direta e calma, frases curtas, sem emoji nem pontos de exclamação.
- Material base: vidro fosco (`FrostedCard`), tab bar flutuante de vidro.
- Fontes: **WhiteGrape** (logótipo e termos de vinho), **RedGrapes** (cartazes, vereditos, brindes, sempre caixa alta), **Helvetica Neue** (interface).
- Loading é a **GrapeSheet** (folha com nomes de castas a descer), sem spinner.

Detalhes completos e valores exatos estão sempre no *UVVA Design System* — não invente valores; leia-os de lá.
