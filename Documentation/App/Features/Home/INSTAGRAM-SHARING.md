# Compartilhar o mapa nos Stories

O `ShareScreen` tenta abrir o editor de Stories do Instagram com a imagem renderizada em 1080 × 1920. O WhatsApp continua usando a folha nativa do iOS para compartilhar imagem e mensagem.

Configure o App ID numérico do UVVA no Meta for Developers no build setting `UVVA_META_APP_ID`, tanto em Debug quanto em Release. Ele preenche `FacebookAppID` no Info.plist. O scheme `instagram-stories` já está declarado em `LSApplicationQueriesSchemes`. Não é necessário incluir um App Secret no aplicativo.

Enquanto o App ID estiver vazio, se o Instagram não estiver instalado ou se a abertura falhar, o fluxo usa a folha nativa. Abrir o Instagram não confirma a publicação. O convite permanece aberto quando a pessoa retorna ao UVVA.

Validação em iPhone físico:

- Com App ID válido e Instagram instalado, selecionar Story e compartilhar deve abrir o editor com o mapa.
- Cancelar e voltar ao UVVA deve manter o convite aberto.
- Sem Instagram ou sem App ID, deve abrir a folha nativa.
- WhatsApp deve continuar oferecendo imagem e mensagem pela folha nativa; cancelar deve preservar o convite.

Referência: https://developers.facebook.com/docs/instagram-platform/sharing-to-stories/
