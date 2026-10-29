# UVVA · Friends

> Status: rascunho v0.2 · 2026-10-27
> Depende de: [`_shared.md`](_shared.md), [`quiz.md`](quiz.md), `match.md` (a escrever)
> Fonte: canvas UVVA App, artboard Friends (telas 01 a 12 e 11 fluxos).

## 1. Objetivo

A aba Friends junta o mapa do paladar do usuário com o dos amigos. Ela mostra a compatibilidade com cada amigo e monta mesas: uma **mesa para dois**, com um amigo, e uma **mesa de grupo**, com vários. Cada mesa traz três garrafas e um menu de jantar, que podem ser partilhados.

Pela SHARED-R01, não há limites de mesas nem desbloqueio pago. As telas "Table locked" (05 e 06), "Unlock this table · €1,99" e "Go Premium" estão fora de escopo.

## 2. Modelo

```swift
struct Friend { id; name; handle; avatar; palateMap: PalateMap }    // sempre presente
struct ContactSuggestion { contactName; uvvaUserId }
struct Table { members: [Friend] /* + o usuário */; bottles: [TableBottle]; menu: [Course] }
```

**FRI-R01 · Todo amigo tem mapa.** Só se usa a UVVA depois de concluir o Quiz (ONB-R02). Um usuário que ainda não concluiu o Quiz não aparece no Quick add nem pode ser amigo. Portanto todo amigo tem mapa, compatibilidade e pode entrar numa mesa (SHARED-R13).

**Critérios**
- Dado um contato que criou conta mas ainda não concluiu o Quiz, então ele não aparece no Quick add.
- Quando esse contato conclui o Quiz, então ele passa a aparecer no Quick add.

## 3. Compatibilidade e mesas: `match.md`

Os cálculos de compatibilidade e das mesas ficam num arquivo próprio, `match.md` (a escrever). O Friends só usa o que ele devolve:

| Função (em `match.md`) | Usada em |
| --- | --- |
| `compatibility(mapaA, mapaB) -> Int` (0 a 100 %) | Lista (FRI-R04), Compatibility (FRI-R12), card da Home (HOME-R11) |
| `tableCompatibility(mapas) -> Int` | Mesa de grupo (FRI-R19) |
| `sharedAxes(mapas) -> [Axis]` (até 3) | Frases de Compatibility e da mesa de grupo |
| `axisSpread(mapas, eixo) -> Etiqueta` (Same, Closest, Some give, Widest) | Reading by reading (FRI-R19) |
| `tableBottles(mapas) -> [TableBottle]` e o menu | Open this together, The perfect table (FRI-R14, R15) |

Os testes do Friends usam versões falsas destas funções, com valores fixos. Os testes dos cálculos ficam em `match.md`.

## 4. Lista de amigos

**FRI-R04 · Lista.** Os amigos aparecem por ordem alfabética. Cada um mostra o nome, o avatar, a assinatura do paladar (os 3 eixos do topo, QUIZ-R14, em caixa alta, separados por " · ") e a compatibilidade em %. O topo mostra "[n] friends".

**FRI-R06 · Vazio.** Sem amigos, a lista mostra [ver D2].

**Critérios**
- Dados Marina, Bia e Rui, então a ordem é Bia, Marina, Rui.
- Dado um amigo com top 3 Acidity, Fruit e Body e `compatibility` = 82, então a linha mostra "ACIDITY · FRUIT · BODY" e "82%".

### 4.1 Quick add

**FRI-R07 · Sugestões.** Quick add sugere contatos da agenda do aparelho que já usam a UVVA (com o Quiz concluído, FRI-R01) e ainda não são amigos. Isso precisa de acesso aos contatos (ver D3).

**FRI-R08 · Add.** "Add" torna o contato amigo, mostra o aviso "[nome] was added to your friends." e tira-o das sugestões.

**FRI-R09 · ×.** O `×` tira a sugestão da lista sem adicionar o contato. Ela não volta a ser sugerida (ver D4).

**Critérios**
- Dado o contato Sofia, que usa a UVVA, quando o usuário toca em Add, então Sofia passa a estar na lista de amigos, sai das sugestões e aparece "Sofia Bettencourt was added to your friends."
- Dado um contato que não usa a UVVA, então ele não aparece no Quick add.
- Dado um contato já amigo, então ele não aparece no Quick add.

## 5. Um amigo

**FRI-R10 · Três tabs.** Tocar num amigo abre o perfil, com as tabs Palate, Compatibility e Table.

**FRI-R11 · Palate.** O mapa do paladar do amigo (radar e leituras, como na QUIZ-R16).

**FRI-R12 · Compatibility.**
- "[X]% of your palate map matches [nome]".
- Os dois mapas sobrepostos.
- **Frase**, a partir de `sharedAxes`: com eixos, "You both want [a], [b] and [c] in a glass." (ou "[a] and [b]", ou só "[a]"); sem eixos, "You barely overlap — you like different things."
- "Open this together": 3 garrafas, cada uma com o eixo e o porquê (FRI-R14).

**FRI-R13 · Table.** A mesa para dois com esse amigo (secção 6).

**Critérios**
- Dado `sharedAxes` = [Acidity, Fruit], então a frase é "You both want acidity and fruit in a glass."
- Dado `sharedAxes` = [Acidity, Fruit, Spice], então a frase é "You both want acidity, fruit and spice in a glass."
- Dado `sharedAxes` vazio, então a frase é "You barely overlap — you like different things."

## 6. Mesas

### 6.1 Garrafas

**FRI-R14 · Escolha das garrafas.** As garrafas e o menu de uma mesa vêm de `tableBottles` (`match.md`), a partir de todos os mapas à mesa.

### 6.2 Mesa para dois

**FRI-R15 · Menu.** "The perfect dinner for You & [nome]": três garrafas por ordem, Starter, Main e Dessert, cada uma com o prato que a acompanha. Rodapé: "Read from both palate maps · UVVA".

**FRI-R16 · Sempre aberta.** A mesa para dois existe para qualquer amigo, sem limite.

**FRI-R17 · Última mesa.** A última mesa aberta fica guardada. É ela que o card de match da Home abre (HOME-R11).

### 6.3 Mesa de grupo

**FRI-R18 · Escolher quem vem.** "Hosting tonight? · Select" entra em modo de escolha:
- Tocar num amigo escolhe-o ou desfaz a escolha.
- Com menos de 2 escolhidos, o botão diz "Pick at least two friends" e está inativo.
- Com 2 ou mais, diz "Find a bottle for these [n]" e abre a mesa.
- Há um máximo de pessoas por mesa [ver D6].

**FRI-R19 · Resultado.** A mesa de grupo mostra:
- **Compatibilidade da mesa** (`tableCompatibility`): "[X]% match across all [n] palate maps at the table".
- **Frase**, a partir de `sharedAxes` da mesa: com eixos, "You all want [a], [b] and [c] in a glass."; sem eixos, "Nothing lines up across all [n] — the menu is built on compromise."
- **"Where the table lands":** o radar com a média de cada eixo, e "The boldest reading" (o valor mais alto de cada eixo) a tracejado.
- **"Reading by reading":** começa recolhida e "Expand"/"Collapse" abre e fecha. Cada eixo tem a etiqueta de `axisSpread` (Same, Closest, Some give ou Widest), uma frase e o intervalo à mesa (do menor ao maior valor).
- "Open this together" (FRI-R14) e "The perfect table" (o menu, como na FRI-R15), com o título "The perfect dinner for The [n] of you".

**FRI-R20 · Entrada pela Home.** "Set a table with your friends", na Home, abre esta escolha (HOME-R11).

**Critérios**
- Dado o modo de escolha com 1 amigo escolhido, então o botão diz "Pick at least two friends" e está inativo.
- Dados 3 amigos escolhidos, então o botão diz "Find a bottle for these 3".
- Dado um amigo escolhido, quando o usuário toca nele de novo, então ele deixa de estar escolhido.
- Dados 4 mapas com Acidity 6, 7, 7 e 8, então o intervalo de Acidity mostrado vai de 6 a 8.
- Dada uma mesa de 4 com `sharedAxes` vazio, então a frase é "Nothing lines up across all 4 — the menu is built on compromise."

## 7. Partilhar uma mesa

**FRI-R21 · Três formatos.** Share abre as três opções de toda partilha (SHARED-R20), tanto para a mesa para dois como para a de grupo:

| Formato | Conteúdo |
| --- | --- |
| WhatsApp | Convite "You're invited to dinner" com os nomes, o menu, a mensagem "Dinner at mine? I built the menu from both our palate maps. Three courses, three bottles." e o link da mesa `uvva.app/t/[mesa]` |
| Story | Imagem 9:16, "Tonight's table", com o menu. Quem tocar abre o menu completo na UVVA |
| Save image | Guia de compras: para cada garrafa, o curso, "Ask for: …" e o prato. Fica guardado nas fotos |

**FRI-R22 · Texto do grupo.** Na mesa de grupo, o convite usa os nomes de todos, e a mensagem fala em "all our palate maps" no lugar de "both".

**Critérios**
- Dada a mesa para dois com Marina, então o convite tem "Marina & Elisa" e o link `uvva.app/t/marina-elisa`.
- Quando o usuário toca em Save image, então a imagem do guia de compras é guardada nas fotos.

## 8. Fora de escopo

- Limites de mesas, desbloqueio por €1,99 e paywall (SHARED-R01).
- O convite para a UVVA de quem ainda não tem conta (está na Home, HOME-R11).
- Os cálculos de compatibilidade, eixos em comum, etiquetas e garrafas: `match.md`.
- Como o catálogo associa um prato a cada garrafa.

## 9. Dúvidas em aberto

- [ ] **D2 · Lista vazia.** O que a aba mostra sem nenhum amigo: só o Quick add, ou também um convite para a UVVA?
- [ ] **D3 · Acesso aos contatos.** Quando se pede o acesso à agenda: ao abrir a aba Friends pela primeira vez, ou ao tocar em Quick add? E sem acesso, o que aparece?
- [ ] **D4 · Sugestão recusada.** Um contato tirado com × volta a ser sugerido algum dia? Dá para remover um amigo depois de adicionado?
- [ ] **D6 · Tamanho da mesa.** Qual é o máximo de pessoas numa mesa de grupo? O protótipo usa sempre quatro.
- [ ] **D9 · Link da mesa.** Quem recebe `uvva.app/t/[mesa]` sem ter a app vê o quê?

### Para o `match.md`

Estas dúvidas saíram daqui e ficam para quando o `match.md` for escrito:

- Fórmula da compatibilidade: a mesma distância do vinho (QUIZ-R21) ou a média das diferenças do protótipo?
- Como se escolhem as garrafas e o menu de uma mesa (mapa médio? regras por curso?).
- Limites de "perto", "alto" e das etiquetas Same, Closest, Some give e Widest, agora na escala 0–9.
- Quando um amigo refaz o Quiz, as mesas antigas com ele são recalculadas?
