# Receitas: "why" reescrito (2026-10-31)

203 receitas de `Application/Data/UVVARecipes.json` citavam um vinho, uma casta ou uma região no `why`, e algumas contradiziam o próprio `wineTypes` (por exemplo, um Riesling numa receita marcada só como `Red`). A Home mostra o `why` ao lado de qualquer vinho do tipo indicado, por isso:

- o `why` passou a descrever o estilo ("an off-dry Riesling" → "an off-dry white");
- o `wineTypes` passou a ser só o tipo desse estilo.

Reveja e ajuste à mão o que não soar bem; depois corra `python3 Application/Scripts/pack_content.py`.

| Receita | Tipos (antes → depois) | Antes | Depois |
| --- | --- | --- | --- |
| `watermelon-and-feta-salad-with-aleppo-pepper-and-mint` | [White] -> [Rosé] | Red fruit meets red fruit; the Aleppo pepper's warmth asks for a rosé with a little spice behind it. | Red fruit meets red fruit; the Aleppo pepper's warmth asks for a rosé with a little spice behind it. |
| `poached-white-peaches-with-elderflower-and-almond-crumble` | [Sparkling, White] -> [Sparkling] | Elderflower and white peach echo a floral, sweet Moscato; its sweetness stays above the fruit's. | Elderflower and white peach echo a floral, sweet sparkling wine; its sweetness stays above the fruit's. |
| `crab-salad-with-grapefruit-and-tarragon` | [White] -> [White] | Grapefruit and tarragon lift sweet crab toward a floral, high-acid Riesling. | Grapefruit and tarragon lift sweet crab toward a floral, high-acid white. |
| `thai-style-prawn-salad-with-green-mango-and-chilli` | [White] -> [White] | The chilli heat and sweet-sour dressing call for an off-dry Riesling with bright acidity. | The chilli heat and sweet-sour dressing call for an off-dry white with bright acidity. |
| `lobster-with-tarragon-butter-and-new-potatoes` | [White] -> [White] | Rich lobster and butter need a creamy, oaked Chardonnay. | Rich lobster and butter need a creamy, oaked white. |
| `trout-with-almonds-brown-butter-and-horseradish` | [White] -> [White] | Horseradish gives a peppery bite that a spicy Grüner Veltliner loves. | Horseradish gives a peppery bite that a spicy white loves. |
| `grilled-prawns-with-romesco` | [White] -> [Rosé] | Roasted pepper and almond sauce match a fruity, dry rosé. | Roasted pepper and almond sauce match a fruity, dry rosé. |
| `bouillabaisse-style-fish-stew-with-rouille` | [Rosé, White] -> [Rosé] | Saffron, fennel and tomato are the classic match for a Provençal rosé. | Saffron, fennel and tomato are the classic match for a rosé. |
| `salmon-tartare-with-watermelon-radish-and-shiso` | [White] -> [Rosé] | Shiso's minty, floral note pairs with the red-fruit side of a pale rosé. | Shiso's minty, floral note pairs with the red-fruit side of a pale rosé. |
| `squid-a-la-plancha-with-black-olive-and-orange` | [White] -> [Rosé] | Orange and olive bring the sun-dried fruit side of a southern French rosé. | Orange and olive bring the sun-dried fruit side of a rosé. |
| `seared-tuna-with-soy-shiitake-and-sansho-pepper` | [Red] -> [Red] | Umami-rich tuna and mushrooms stand up to a light Pinot Noir. | Umami-rich tuna and mushrooms stand up to a light red. |
| `salmon-with-red-wine-butter-and-mushrooms` | [Red] -> [Red] | Red wine sauce and mushrooms make salmon a natural partner for Pinot Noir. | Red wine sauce and mushrooms make salmon a natural partner for a light red. |
| `cedar-planked-salmon-with-maple-and-mustard` | [White] -> [Red] | Smoke from the plank and a sweet glaze suit a Pinot Noir with some oak. | Smoke from the plank and a sweet glaze suit a red with some oak. |
| `monkfish-wrapped-in-prosciutto-with-juniper-and-lentils` | [White, Red] -> [Red] | Cured ham and earthy lentils give enough savoury depth for an oaked Pinot. | Cured ham and earthy lentils give enough savoury depth for an oaked red. |
| `lobster-salad-with-mango-and-lime` | [White, Rosé] -> [White] | Tropical fruit and sweet lobster want a floral, dry Muscat. | Tropical fruit and sweet lobster want a floral, dry white. |
| `scallops-with-cauliflower-raisins-and-curry-oil` | [White, Rosé] -> [White] | Mild curry spice and raisins match a fragrant, dry Muscat. | Mild curry spice and raisins match a fragrant, dry white. |
| `thai-red-curry-with-prawns-and-pineapple` | [Rosé] -> [White] | Chilli heat and pineapple need an aromatic, slightly sweet Gewürztraminer. | Chilli heat and pineapple need an aromatic, slightly sweet white. |
| `duck-fat-fried-fish-with-lychee-and-chilli-salsa` | [White, Rosé] -> [White] | Lychee's perfume mirrors Gewürztraminer; the chilli wants its sweetness. | Lychee's perfume mirrors an aromatic white; the chilli wants its sweetness. |
| `langoustines-with-lemon-verbena-butter` | [White] -> [White] | Sweet langoustines and verbena match the perfume of a Riesling. | Sweet langoustines and verbena match the perfume of an aromatic white. |
| `scallops-with-jerusalem-artichoke-brown-butter-and-sage` | [White] -> [White] | Brown butter and nutty artichoke match a toasty, oaked Chardonnay. | Brown butter and nutty artichoke match a toasty, oaked white. |
| `grilled-red-mullet-with-tapenade-and-fennel-seed` | [White] -> [Rosé] | Olive and tomato call for a dry Provençal rosé. | Olive and tomato call for a dry rosé. |
| `scallops-with-pork-belly-and-apple-puree` | [Red] -> [White] | Sweet apple, rich pork and scallop suit an off-dry Riesling. | Sweet apple, rich pork and scallop suit an off-dry white. |
| `prawn-and-pomelo-salad-with-lime-leaf` | [White, Sparkling] -> [White] | Floral lime leaf and juicy pomelo suit an aromatic Muscat. | Floral lime leaf and juicy pomelo suit an aromatic white. |
| `asparagus-and-smoked-trout-with-soft-egg` | [White] -> [White] | Asparagus, egg and smoke suit a peppery Grüner Veltliner. | Asparagus, egg and smoke suit a peppery white. |
| `warm-goat-s-cheese-with-beetroot-and-caraway` | [White] -> [White] | Tangy goat's cheese loves a lean, high-acid Sauvignon; caraway adds a savoury lift. | Tangy goat's cheese loves a lean, high-acid white; caraway adds a savoury lift. |
| `chicken-liver-pate-with-allspice-and-cherries` | [Red] -> [Red] | Allspice and cherry pull rich liver toward a bright, light Pinot Noir. | Allspice and cherry pull rich liver toward a bright, light red. |
| `tomato-bruschetta-with-wild-fennel` | [White] -> [Red] | Ripe tomato needs a high-acid Sangiovese; fennel seed adds its herbal edge. | Ripe tomato needs a high-acid red; fennel seed adds its herbal edge. |
| `gazpacho-with-smoked-paprika-oil` | [White, Red] -> [Rosé] | Cold tomato and pepper soup with a smoky oil wants a dry, savoury rosé. | Cold tomato and pepper soup with a smoky oil wants a dry, savoury rosé. |
| `melon-and-jamon-with-mint-and-espelette-pepper` | [Rosé] -> [Rosé] | Sweet melon and salty ham suit a fruity rosé; Espelette adds gentle warmth. | Sweet melon and salty ham suit a fruity rosé; Espelette adds gentle warmth. |
| `melon-and-cucumber-salad-with-rose-water` | [White, Sparkling] -> [White] | Rose water echoes the perfume of a dry Muscat. | Rose water echoes the perfume of a dry white. |
| `carrot-ginger-and-coconut-soup-with-lime-leaf` | [White] -> [White] | Ginger and lime leaf need an aromatic, off-dry Gewürztraminer. | Ginger and lime leaf need an aromatic, off-dry white. |
| `prawn-summer-rolls-with-peanut-chilli-dip` | [White, Rosé] -> [White] | Herbs, chilli and sweet peanut sauce suit an off-dry Riesling. | Herbs, chilli and sweet peanut sauce suit an off-dry white. |
| `mushroom-pate-with-smoked-garlic` | [Red] -> [Red] | Smoked garlic adds the toasty depth an oaked Pinot Noir likes. | Smoked garlic adds the toasty depth an oaked red likes. |
| `grilled-halloumi-with-peach-and-za-atar` | [Red, White] -> [Rosé] | Salty cheese and juicy peach suit a fruity rosé; za'atar adds herbal spice. | Salty cheese and juicy peach suit a fruity rosé; za'atar adds herbal spice. |
| `chilled-cucumber-soup-with-green-apple-and-elderflower` | [Rosé, White] -> [White] | Elderflower and apple make it fragrant enough for a floral Riesling. | Elderflower and apple make it fragrant enough for a floral white. |
| `tuscan-bean-soup-with-cavolo-nero-and-fennel-seed` | [Red] -> [Red] | Beans and bitter greens want a savoury, high-acid Sangiovese. | Beans and bitter greens want a savoury, high-acid red. |
| `tuscan-chicken-liver-crostini-with-juniper` | [Red] -> [Red] | Juniper and rich liver suit a spicy, fresh Sangiovese. | Juniper and rich liver suit a spicy, fresh red. |
| `tomato-tarte-fine-with-anchovies-and-herbes-de-provence` | [Rosé] -> [Rosé] | Tomato, olive oil and herbs are the classic for a Provençal rosé. | Tomato, olive oil and herbs are the classic for a rosé. |
| `grilled-peach-mozzarella-and-lavender` | [White] -> [White] | Lavender gives the peach a floral note that a dry Muscat echoes. | Lavender gives the peach a floral note that a dry white echoes. |
| `duck-spring-rolls-with-five-spice-and-plum-sauce` | [Red] -> [White] | Five spice and sweet plum suit an aromatic, off-dry Gewürztraminer. | Five spice and sweet plum suit an aromatic, off-dry white. |
| `fresh-goat-s-cheese-with-radishes-and-nigella-seeds` | [White, Rosé] -> [White] | Tangy goat's cheese and peppery radish want a lean, crisp Sauvignon. | Tangy goat's cheese and peppery radish want a lean, crisp white. |
| `sweetcorn-veloute-with-smoked-butter` | [White] -> [White] | Sweet corn and smoky butter mirror a buttery, oaked Chardonnay. | Sweet corn and smoky butter mirror a buttery, oaked white. |
| `mushroom-and-gruyere-tart-with-juniper` | [Red] -> [Red] | Earthy mushrooms and a hint of juniper suit a light, high-acid Pinot. | Earthy mushrooms and a hint of juniper suit a light, high-acid red. |
| `white-asparagus-with-ham-and-wild-garlic` | [Red] -> [White] | Wild garlic's pungency matches a peppery, fresh Grüner. | Wild garlic's pungency matches a peppery, fresh white. |
| `courgette-and-mint-fritters-with-sumac-yoghurt` | [Red] -> [Rosé] | Fried fritters and tangy sumac suit a crisp, fruity rosé. | Fried fritters and tangy sumac suit a crisp, fruity rosé. |
| `pappa-al-pomodoro-with-black-pepper-and-pecorino` | [Rosé, White] -> [Red] | Tomato, bread and pepper suit a spicy, high-acid Sangiovese. | Tomato, bread and pepper suit a spicy, high-acid red. |
| `pear-fennel-and-elderflower-salad-with-pecorino` | [White, Rosé] -> [White] | Elderflower and pear echo the perfume of a dry Muscat or Torrontés. | Elderflower and pear echo the perfume of a dry, aromatic white. |
| `peach-and-burrata-with-rose-and-pistachio` | [White] -> [White] | Rose water and ripe peach mirror a floral, fruit-rich Muscat. | Rose water and ripe peach mirror a floral, fruit-rich white. |
| `chicken-and-almond-pastilla-triangles-with-orange-blossom` | [Red, White] -> [White] | Orange blossom, cinnamon and sweet almond suit an aromatic, dry Muscat. | Orange blossom, cinnamon and sweet almond suit an aromatic, dry white. |
| `carrot-and-orange-soup-with-coriander-seed-and-orange-blossom` | [White] -> [White] | Coriander seed and orange blossom make the soup floral enough for a Muscat. | Coriander seed and orange blossom make the soup floral enough for a white. |
| `prawn-and-lychee-salad-with-jasmine-tea-dressing` | [White] -> [White] | Jasmine and lychee reach the perfume of a floral, dry Muscat. | Jasmine and lychee reach the perfume of a floral, dry white. |
| `spiced-pumpkin-samosas-with-cardamom-and-mango-chutney` | [Rosé] -> [White] | Cardamom and sweet chutney suit a perfumed, spicy Gewürztraminer. | Cardamom and sweet chutney suit a perfumed, spicy white. |
| `roast-carrot-dip-with-rose-harissa` | [White, Rosé] -> [White] | Rose harissa's floral heat is made for an aromatic Gewürztraminer. | Rose harissa's floral heat is made for an aromatic white. |
| `onion-and-munster-tart-with-cumin` | [Red, White] -> [White] | Pungent Munster and cumin are a classic Alsace match for Gewürztraminer. | Pungent Munster and cumin are a classic match for an aromatic white. |
| `duck-and-lychee-salad-with-star-anise` | [Red] -> [White] | Lychee and star anise bring out the spice and perfume of Gewürztraminer. | Lychee and star anise bring out the spice and perfume of an aromatic white. |
| `green-papaya-salad-with-tamarind-and-chilli` | [Sparkling] -> [White] | Tamarind's sweet sourness and chilli heat want an off-dry, racy Riesling. | Tamarind's sweet sourness and chilli heat want an off-dry, racy white. |
| `pork-larb-with-lemongrass-and-mint` | [Red] -> [White] | Lime, chilli and herbs need an off-dry Riesling with bright acidity. | Lime, chilli and herbs need an off-dry white with bright acidity. |
| `smoked-trout-with-star-anise-pickled-pear` | [Red, White] -> [White] | Sweet pickled pear and smoky fish suit an off-dry, high-acid Riesling. | Sweet pickled pear and smoky fish suit an off-dry, high-acid white. |
| `watermelon-gazpacho-with-chilli-and-lemongrass` | [White, Sparkling] -> [White] | Sweet watermelon and chilli heat call for an off-dry Riesling. | Sweet watermelon and chilli heat call for an off-dry white. |
| `smoked-duck-breast-with-blackberries-and-hazelnuts` | [Red] -> [Red] | Smoky duck and dark berries suit a Pinot Noir with some oak. | Smoky duck and dark berries suit a red with some oak. |
| `grilled-quail-with-pomegranate-molasses` | [White, Red] -> [Red] | Sweet-sour pomegranate and charred quail suit a juicy, oaked Pinot. | Sweet-sour pomegranate and charred quail suit a juicy, oaked red. |
| `beetroot-tarte-tatin-with-goat-s-cheese-and-smoked-salt` | [White] -> [Red] | Sweet, earthy beetroot and smoke suit an oaked Pinot Noir. | Sweet, earthy beetroot and smoke suit an oaked red. |
| `fennel-sausage-crostini-with-chilli` | [Red] -> [Red] | Fennel and chilli pick up the spice of a fresh Sangiovese. | Fennel and chilli pick up the spice of a fresh red. |
| `beef-tartare-with-violet-mustard` | [Red] -> [Red] | Violet mustard gives raw beef a floral note that a Touriga Nacional echoes. | Violet mustard gives raw beef a floral note that a red echoes. |
| `carne-cruda-with-lemon-and-dried-rose` | [Red] -> [Red] | Raw beef and a hint of rose meet Nebbiolo's floral perfume and grip. | Raw beef and a hint of rose meet the floral perfume and grip of a firm red. |
| `beef-and-porcini-agnolotti-with-sage-butter` | [Red] -> [Red] | Roast meat, porcini and sage suit the tannin and lift of a Nebbiolo. | Roast meat, porcini and sage suit the tannin and lift of a firm red. |
| `beef-empanadas-with-cumin-and-raisins` | [Red] -> [Red] | Spiced beef and raisins match the ripe dark fruit of a Malbec. | Spiced beef and raisins match the ripe dark fruit of a red. |
| `provoleta-with-plum-jam-and-oregano` | [Red] -> [Red] | Melted cheese and dark fruit suit a ripe, plush Malbec. | Melted cheese and dark fruit suit a ripe, plush red. |
| `panzanella-with-celery-leaf` | [White] -> [Red] | Tomato and vinegar-soaked bread want a high-acid Sangiovese. | Tomato and vinegar-soaked bread want a high-acid red. |
| `beetroot-and-blackberry-salad-with-goat-s-curd` | [White] -> [Red] | Blackberries pull earthy beetroot toward the red fruit of a Pinot Noir. | Blackberries pull earthy beetroot toward the red fruit of a light red. |
| `salade-nicoise-with-herbes-de-provence` | [White] -> [Rosé] | Tuna, olives and herbs are the classic for a Provençal rosé. | Tuna, olives and herbs are the classic for a rosé. |
| `egg-and-chive-salad-with-radish-and-white-pepper` | [White] -> [White] | Egg, radish and white pepper suit a peppery, fresh Grüner. | Egg, radish and white pepper suit a peppery, fresh white. |
| `chicken-satay-with-galangal-and-peanut` | [Red] -> [White] | Galangal and sweet peanut sauce suit a spicy, perfumed Gewürztraminer. | Galangal and sweet peanut sauce suit a spicy, perfumed white. |
| `fig-and-goat-s-cheese-salad-with-lavender-honey` | [White] -> [White] | Lavender and figs match the floral, fruit-rich side of a Muscat. | Lavender and figs match the floral, fruit-rich side of a white. |
| `beef-cheeks-braised-in-nebbiolo-with-dried-rose` | [Red] -> [Red] | Wine-braised beef and a whisper of rose meet Nebbiolo's tannin, acidity and perfume. | Wine-braised beef and a whisper of rose meet the tannin, acidity and perfume of a firm red. |
| `tajarin-with-veal-ragu-and-violet` | [Red] -> [Red] | A meat ragù with a floral edge suits the perfume and grip of Barolo. | A meat ragù with a floral edge suits the perfume and grip of a firm red. |
| `roast-leg-of-lamb-with-anchovy-rosemary-and-lemon` | [Red] -> [Red] | Fatty lamb, lemon and herbs need the acidity and firm tannin of a Nebbiolo. | Fatty lamb, lemon and herbs need the acidity and firm tannin of a structured red. |
| `grilled-flank-steak-with-chimichurri` | [Red] -> [Red] | Charred beef and herby chimichurri are the classic for a Malbec. | Charred beef and herby chimichurri are the classic for a red. |
| `asado-style-beef-ribs-with-salsa-criolla` | [Red] -> [Red] | Fatty grilled ribs need the ripe fruit and soft tannin of a Malbec. | Fatty grilled ribs need the ripe fruit and soft tannin of a red. |
| `venison-with-beetroot-and-violet-mustard` | [Red] -> [Red] | Violet and earthy beetroot meet the floral side of a Touriga Nacional. | Violet and earthy beetroot meet the floral side of a red. |
| `portuguese-beef-with-red-wine-bay-and-clove` | [Red] -> [Red] | Bay, clove and wine-braised beef suit a perfumed Douro red. | Bay, clove and wine-braised beef suit a perfumed, structured red. |
| `entrecote-bordelaise` | [Red] -> [Red] | A red wine and marrow sauce is the classic for a structured Bordeaux. | A red wine and marrow sauce is the classic for a structured, oaked red. |
| `lamb-with-flageolet-beans-and-rosemary` | [Red] -> [Red] | Lamb and herbs suit a classic, oaked Bordeaux blend. | Lamb and herbs suit a classic, oaked red blend. |
| `sweet-and-sour-sicilian-beef-with-cocoa` | [Red] -> [Red] | Sweet-sour sauce and ripe fruit match a soft, fruity Nero d'Avola. | Sweet-sour sauce and ripe fruit match a soft, fruity red. |
| `pigeon-with-blackberries-and-cocoa` | [Red] -> [Red] | Gamey pigeon and dark fruit suit an oaked, fruit-driven Pinot. | Gamey pigeon and dark fruit suit an oaked, fruit-driven red. |
| `osso-buco-with-gremolata-and-fennel-pollen` | [Red] -> [Red] | Tomato-braised veal and citrus gremolata suit a high-acid Sangiovese. | Tomato-braised veal and citrus gremolata suit a high-acid red. |
| `wild-boar-pappardelle-with-tomato-and-rosemary` | [Red] -> [Red] | Gamey boar and tomato want a high-acid, savoury Chianti. | Gamey boar and tomato want a high-acid, savoury red. |
| `chicken-with-apricots-cinnamon-and-rose` | [White] -> [White] | Rose and apricot reach the perfume and spice of a Gewürztraminer. | Rose and apricot reach the perfume and spice of a white. |
| `butter-chicken-with-fenugreek` | [Red] -> [White] | Creamy, gently spiced sauce suits a perfumed Gewürztraminer. | Creamy, gently spiced sauce suits a perfumed white. |
| `sticky-chicken-wings-with-tamarind-and-chilli` | [White] -> [White] | Sweet-sour tamarind and chilli heat want an off-dry Riesling. | Sweet-sour tamarind and chilli heat want an off-dry white. |
| `teriyaki-chicken-with-pickled-ginger` | [White, Red] -> [White] | Sweet soy glaze and sharp ginger suit an off-dry, high-acid Riesling. | Sweet soy glaze and sharp ginger suit an off-dry, high-acid white. |
| `chicken-souvlaki-with-sumac-and-tzatziki` | [Red] -> [Rosé] | Grilled chicken and tangy sumac suit a fresh, fruity rosé. | Grilled chicken and tangy sumac suit a fresh, fruity rosé. |
| `provencal-chicken-with-olives-fennel-and-pastis` | [Red] -> [Rosé] | Fennel, olive and pastis are a natural match for a Provençal rosé. | Fennel, olive and pastis are a natural match for a rosé. |
| `coq-au-vin-with-smoked-garlic` | [Red] -> [Red] | Wine-braised chicken and mushrooms are the classic for Pinot Noir. | Wine-braised chicken and mushrooms are the classic for a light, earthy red. |
| `guinea-fowl-with-prunes-and-armagnac` | [Red, White] -> [Red] | Prunes and gamey fowl suit a light, earthy Pinot Noir. | Prunes and gamey fowl suit a light, earthy red. |
| `duck-breast-with-figs-and-balsamic` | [Red] -> [Red] | Ripe figs and balsamic suit an oaked, fruit-driven Pinot. | Ripe figs and balsamic suit an oaked, fruit-driven red. |
| `chicken-cacciatore-with-rosemary-and-olives` | [Red] -> [Red] | Tomato, rosemary and olives want a high-acid Sangiovese. | Tomato, rosemary and olives want a high-acid red. |
| `chicken-diavola-with-chilli-and-fennel` | [White, Red] -> [Red] | Chilli and fennel seed pick up the spice of a fresh Sangiovese. | Chilli and fennel seed pick up the spice of a fresh red. |
| `chicken-with-orange-blossom-almonds-and-couscous` | [White, Red] -> [White] | Orange blossom and almond suit a dry, floral Muscat. | Orange blossom and almond suit a dry, floral white. |
| `chicken-with-riesling-tarragon-and-grapes` | [Red] -> [White] | Riesling in the sauce and fresh grapes make an obvious match. | White wine in the sauce and fresh grapes make an obvious match for an aromatic white. |
| `chicken-schnitzel-with-horseradish-potato-salad` | [Red, White] -> [White] | Crisp schnitzel and horseradish suit a peppery Grüner Veltliner. | Crisp schnitzel and horseradish suit a peppery white. |
| `kung-pao-chicken-with-sichuan-pepper` | [White] -> [White] | Numbing pepper and sweet-sour sauce want an off-dry Riesling. | Numbing pepper and sweet-sour sauce want an off-dry white. |
| `roast-quail-with-lychee-and-ginger` | [White] -> [White] | Lychee and ginger echo the perfume of a dry Muscat. | Lychee and ginger echo the perfume of a dry white. |
| `chicken-biryani-with-rose-water-and-saffron` | [White] -> [White] | Rose, saffron and warm spice suit an aromatic Gewürztraminer. | Rose, saffron and warm spice suit an aromatic white. |
| `chicken-paella-with-saffron-and-peppers` | [Red] -> [Rosé] | Saffron and sweet peppers are a classic for a Spanish rosé. | Saffron and sweet peppers are a classic for a rosé. |
| `duck-breast-with-celeriac-and-coffee-jus` | [Red] -> [Red] | Coffee in the jus echoes the toast of a structured Bordeaux. | Coffee in the jus echoes the toast of a structured red. |
| `pork-belly-with-apple-and-star-anise-glaze` | [Red] -> [White] | A sweet-spiced glaze and rich pork want an off-dry Riesling. | A sweet-spiced glaze and rich pork want an off-dry white. |
| `char-siu-pork-with-five-spice` | [Red] -> [White] | Sweet, spiced roast pork suits an off-dry, aromatic Riesling. | Sweet, spiced roast pork suits an off-dry, aromatic white. |
| `pork-and-lychee-stir-fry-with-ginger` | [Red] -> [White] | Lychee and ginger suit the perfume of Gewürztraminer. | Lychee and ginger suit the perfume of an aromatic white. |
| `schweinsbraten-with-caraway-and-dark-beer` | [Red] -> [White] | Caraway and crisp pork crackling suit a peppery Grüner Veltliner. | Caraway and crisp pork crackling suit a peppery white. |
| `pork-secreto-with-orange-and-thyme` | [Red] -> [Rosé] | Juicy Iberian pork and orange suit a fruity rosé. | Juicy Iberian pork and orange suit a fruity rosé. |
| `porchetta-with-fennel-pollen-and-chilli` | [Red] -> [Red] | Fennel and chilli are the classic for a fresh, spicy Sangiovese. | Fennel and chilli are the classic for a fresh, spicy red. |
| `roast-pork-loin-with-cherries-and-thyme` | [Red] -> [Red] | Sour cherries lift pork toward a bright Pinot Noir. | Sour cherries lift pork toward a bright red. |
| `banh-mi-with-lemongrass-pork` | [White, Red] -> [White] | Lemongrass, chilli and pickles suit an off-dry Riesling. | Lemongrass, chilli and pickles suit an off-dry white. |
| `tomato-and-burrata-pizza-with-wild-fennel` | [White, Rosé] -> [Red] | Tomato and fennel seed suit a bright, savoury Sangiovese. | Tomato and fennel seed suit a bright, savoury red. |
| `polenta-with-porcini-ragu-and-black-pepper` | [Red] -> [Red] | Porcini, tomato and pepper suit a spicy, fresh Sangiovese. | Porcini, tomato and pepper suit a spicy, fresh red. |
| `sweet-potato-and-chickpea-curry-with-cardamom` | [Red] -> [White] | Coconut, cardamom and sweet potato suit a perfumed Gewürztraminer. | Coconut, cardamom and sweet potato suit a perfumed white. |
| `thai-red-curry-with-tofu-and-lychee` | [White, Rosé] -> [White] | Lychee and curry spice reach the perfume of Gewürztraminer. | Lychee and curry spice reach the perfume of an aromatic white. |
| `pad-thai-with-tofu-and-tamarind` | [White] -> [White] | Sweet-sour tamarind sauce wants an off-dry Riesling. | Sweet-sour tamarind sauce wants an off-dry white. |
| `sichuan-fish-fragrant-aubergine` | [Rosé, White] -> [White] | Sweet, sour and numbing heat suit an off-dry Riesling. | Sweet, sour and numbing heat suit an off-dry white. |
| `ratatouille-with-herbes-de-provence` | [Rosé] -> [Rosé] | Sun-ripe vegetables and herbs are a natural for Provençal rosé. | Sun-ripe vegetables and herbs are a natural for a rosé. |
| `shakshuka-with-feta-and-cumin` | [White, Rosé] -> [Rosé] | Eggs in spiced tomato suit a fresh, fruity rosé. | Eggs in spiced tomato suit a fresh, fruity rosé. |
| `beetroot-risotto-with-goat-s-cheese-and-horseradish` | [White, Rosé] -> [Red] | Earthy beetroot suits a light Pinot; horseradish adds bite. | Earthy beetroot suits a light red; horseradish adds bite. |
| `mushroom-bourguignon-with-cloves` | [Red] -> [Red] | Wine-braised mushrooms are made for a light Pinot Noir. | Wine-braised mushrooms are made for a light, earthy red. |
| `wild-mushroom-and-chestnut-pie-with-smoked-salt` | [Red] -> [Red] | Earthy mushrooms and smoke suit an oaked Pinot Noir. | Earthy mushrooms and smoke suit an oaked red. |
| `carrot-and-apricot-tagine-with-orange-blossom` | [White] -> [White] | Orange blossom and apricot echo a floral, fruity Muscat. | Orange blossom and apricot echo a floral, fruity white. |
| `arctic-char-with-lentils-and-pumpkin-seed-oil` | [White] -> [White] | Toasty seed oil and earthy lentils suit a peppery Grüner. | Toasty seed oil and earthy lentils suit a peppery white. |
| `mackerel-with-rose-harissa-and-chickpeas` | [White] -> [Rosé] | Floral heat and oily fish suit a fresh, fruity rosé. | Floral heat and oily fish suit a fresh, fruity rosé. |
| `thai-steamed-fish-with-lime-chilli-and-lemongrass` | [White, Rosé] -> [White] | Lime, chilli and garlic want an off-dry, high-acid Riesling. | Lime, chilli and garlic want an off-dry, high-acid white. |
| `fish-curry-with-coconut-and-curry-leaves` | [White, Rosé] -> [White] | Curry leaves and coconut suit a perfumed Gewürztraminer. | Curry leaves and coconut suit a perfumed white. |
| `tuna-steak-with-lentils-and-juniper` | [White] -> [Red] | Meaty tuna and earthy lentils suit a light Pinot Noir. | Meaty tuna and earthy lentils suit a light red. |
| `pissaladiere-with-anchovy-and-oregano` | [White] -> [Rosé] | Sweet onion, anchovy and olive are a classic for Provençal rosé. | Sweet onion, anchovy and olive are a classic for a rosé. |
| `pan-con-tomate-with-jamon-and-smoked-paprika` | [White] -> [Rosé] | Tomato, ham and smoky paprika suit a dry Spanish rosé. | Tomato, ham and smoky paprika suit a dry rosé. |
| `socca-with-rosemary-and-black-pepper` | [White, Rosé] -> [Rosé] | Crisp chickpea pancake with herbs suits a fresh rosé. | Crisp chickpea pancake with herbs suits a fresh rosé. |
| `grilled-pitta-with-tzatziki-and-sumac` | [White] -> [Rosé] | Garlic yoghurt and tangy sumac suit a crisp rosé. | Garlic yoghurt and tangy sumac suit a crisp rosé. |
| `halloumi-fries-with-za-atar-and-rose-honey` | [White, Rosé] -> [White] | Rose-scented honey and salty cheese suit a floral Muscat. | Rose-scented honey and salty cheese suit a floral white. |
| `onion-bhajis-with-nigella-and-mango-chutney` | [Rosé, White] -> [White] | Spiced fritters and sweet chutney suit an aromatic Gewürztraminer. | Spiced fritters and sweet chutney suit an aromatic white. |
| `vegetable-pakoras-with-tamarind-chutney` | [White] -> [White] | Spiced batter and sweet-sour chutney suit a perfumed Gewürztraminer. | Spiced batter and sweet-sour chutney suit a perfumed white. |
| `thai-fish-cakes-with-lime-leaf-and-cucumber-relish` | [White, Rosé] -> [White] | Lime leaf and sweet-sour relish suit an off-dry Riesling. | Lime leaf and sweet-sour relish suit an off-dry white. |
| `pork-gyoza-with-yuzu-dipping-sauce` | [Red] -> [White] | Juicy dumplings and citrus suit an off-dry, high-acid Riesling. | Juicy dumplings and citrus suit an off-dry, high-acid white. |
| `mushroom-arancini-with-smoked-scamorza` | [Red] -> [Red] | Earthy mushroom and smoky cheese suit a light, earthy Pinot. | Earthy mushroom and smoky cheese suit a light, earthy red. |
| `saffron-arancini-with-ragu` | [Red] -> [Red] | Meaty filling and tomato suit a savoury Sangiovese. | Meaty filling and tomato suit a savoury red. |
| `finocchiona-with-grissini` | [Red, Rosé] -> [Red] | Fennel salami suits a spicy, fresh Sangiovese. | Fennel salami suits a spicy, fresh red. |
| `choripan-with-smoked-paprika-chimichurri` | [Red] -> [Red] | Grilled sausage and herbs are a natural for Malbec. | Grilled sausage and herbs are a natural for a red. |
| `venison-sausage-rolls-with-cranberry` | [Red] -> [Red] | Gamey sausage and tart cranberry suit an oaked Pinot. | Gamey sausage and tart cranberry suit an oaked red. |
| `crottin-de-chavignol-with-celery-and-celery-salt` | [White] -> [White] | Tangy goat's cheese is the classic for a lean Sauvignon Blanc. | Tangy goat's cheese is the classic for a lean white. |
| `munster-with-cumin-and-warm-potatoes` | [White] -> [White] | Pungent Munster and cumin are the classic for Gewürztraminer. | Pungent Munster and cumin are the classic for an aromatic white. |
| `epoisses-with-gingerbread` | [White, Rosé] -> [White] | Rich washed-rind cheese and spiced gingerbread suit an aromatic Gewürztraminer. | Rich washed-rind cheese and spiced gingerbread suit an aromatic white. |
| `taleggio-with-crystallised-ginger-and-walnuts` | [White] -> [White] | Ginger and creamy washed-rind cheese suit a perfumed Gewürztraminer. | Ginger and creamy washed-rind cheese suit a perfumed white. |
| `baked-camembert-with-apricot-and-rosemary` | [Rosé] -> [White] | Creamy cheese and sweet apricot suit an off-dry Riesling. | Creamy cheese and sweet apricot suit an off-dry white. |
| `aged-mimolette-with-walnuts-and-coffee` | [Red] -> [Red] | Nutty aged cheese and coffee echo the toast of a Bordeaux. | Nutty aged cheese and coffee echo the toast of a red. |
| `aged-provolone-with-black-cherry-jam` | [Red] -> [Red] | Sharp provolone and dark cherry match a ripe, plush Malbec. | Sharp provolone and dark cherry match a ripe, plush red. |
| `pecorino-toscano-with-chestnut-honey-and-walnuts` | [Red] -> [Red] | Bitter-sweet chestnut honey and pecorino suit a savoury Sangiovese. | Bitter-sweet chestnut honey and pecorino suit a savoury red. |
| `castelmagno-with-honey-and-dried-rose` | [Red] -> [Red] | Crumbly aged cheese and rose meet Nebbiolo's grip and perfume. | Crumbly aged cheese and rose meet the grip and perfume of a firm red. |
| `baked-feta-with-tomatoes-and-oregano` | [White] -> [Rosé] | Salty feta and sweet tomatoes suit a fresh, fruity rosé. | Salty feta and sweet tomatoes suit a fresh, fruity rosé. |
| `labneh-with-za-atar-and-olive-oil` | [White] -> [Rosé] | Tangy labneh and herbs suit a crisp, dry rosé. | Tangy labneh and herbs suit a crisp, dry rosé. |
| `roquefort-with-honeycomb-and-walnuts` | [White, Rosé] -> [White] | Salty blue cheese and honey are the classic for Sauternes. | Salty blue cheese and honey are the classic for a sweet white. |
| `stilton-with-crystallised-ginger` | [White, Rosé] -> [Fortified] | Stilton and ginger suit a rich, sweet Port. | Stilton and ginger suit a rich, sweet fortified wine. |
| `stilton-with-walnuts-and-port-soaked-figs` | [White] -> [Fortified] | Port-soaked figs build a bridge to a sweet, fortified red. | Figs soaked in fortified wine build a bridge to a sweet, fortified red. |
| `valdeon-with-dates-and-orange-zest` | [White, Rosé] -> [Fortified] | Strong blue cheese and dates match a dense, sweet sherry. | Strong blue cheese and dates match a dense, sweet fortified wine. |
| `fourme-d-ambert-with-peaches-and-lavender` | [White, Sparkling] -> [Sparkling] | Mild blue and lavender-scented peach suit a sweet, floral Moscato. | Mild blue and lavender-scented peach suit a sweet, floral sparkling wine. |
| `cambozola-with-grapes-and-celery` | [White, Rosé] -> [White] | Mild, creamy blue and grapes suit an off-dry Riesling. | Mild, creamy blue and grapes suit an off-dry white. |
| `brie-with-cranberries-and-thyme` | [White] -> [Red] | Soft brie and tart cranberry suit a light Pinot Noir. | Soft brie and tart cranberry suit a light red. |
| `chocolate-fondant-with-cherries-and-star-anise` | [Red, Fortified] -> [Fortified] | Molten chocolate needs a sweet, rich Port; star anise follows its spice. | Molten chocolate needs a sweet, rich fortified wine; star anise follows its spice. |
| `black-forest-trifle-with-cardamom-cream` | [White] -> [Fortified] | Cherry and chocolate suit a ruby Port; cardamom lifts the cream. | Cherry and chocolate suit a ruby fortified wine; cardamom lifts the cream. |
| `plum-crumble-with-ground-ginger` | [White, Rosé] -> [Fortified] | Baked plums and warm ginger suit a sweet, fruity Port. | Baked plums and warm ginger suit a sweet, fruity fortified wine. |
| `chocolate-and-chestnut-torte-with-clove` | [Fortified, Red] -> [Fortified] | Earthy chestnut and chocolate suit a rich Madeira or Port. | Earthy chestnut and chocolate suit a rich, sweet fortified wine. |
| `fig-and-walnut-tart-with-port-glaze` | [White] -> [Fortified] | Port in the glaze echoes the wine itself. | The fortified wine in the glaze echoes the one in the glass. |
| `mince-pies-with-allspice` | [White, Rosé] -> [Fortified] | Dried fruit and warm spice are the classic for a tawny Port. | Dried fruit and warm spice are the classic for a tawny fortified wine. |
| `chocolate-mousse-with-smoked-salt` | [Red, Fortified] -> [Fortified] | Smoky salt and dark chocolate suit a sweet, powerful Port. | Smoky salt and dark chocolate suit a sweet, powerful fortified wine. |
| `cherry-frangipane-tart-with-tonka-bean` | [White] -> [Fortified] | Tonka's vanilla-almond warmth and cherry suit a sweet Port. | Tonka's vanilla-almond warmth and cherry suit a sweet fortified wine. |
| `red-wine-poached-pears-with-cinnamon-and-chocolate` | [White, Rosé] -> [Fortified] | Wine-poached pears and chocolate suit a ruby Port. | Wine-poached pears and chocolate suit a ruby fortified wine. |
| `cherry-brownies-with-cocoa-nibs` | [Fortified, Red] -> [Fortified] | Fudgy chocolate and cherry suit a rich, sweet Port. | Fudgy chocolate and cherry suit a rich, sweet fortified wine. |
| `creme-brulee-with-cardamom` | [White, Rosé] -> [White] | Rich custard and caramel are the classic for Sauternes; cardamom adds lift. | Rich custard and caramel are the classic for a sweet white; cardamom adds lift. |
| `pear-tarte-tatin-with-ginger` | [White, Rosé] -> [White] | Caramelised pear and ginger suit a sweet, golden Sauternes. | Caramelised pear and ginger suit a sweet, golden white. |
| `roast-apricots-with-honey-and-vanilla` | [White, Rosé] -> [White] | Honeyed apricots echo the flavours of Sauternes. | Honeyed apricots echo the flavours of a sweet white. |
| `honey-and-almond-cake-with-orange-blossom` | [White] -> [White] | Honeyed almond cake suits a sweet, golden Sauternes. | Honeyed almond cake suits a sweet, golden white. |
| `peach-melba-with-rose` | [White, Sparkling] -> [Sparkling] | Peach and rose echo the floral sweetness of Moscato. | Peach and rose echo the floral sweetness of sparkling wine. |
| `strawberries-with-lavender-sabayon` | [Sparkling, White] -> [Sparkling] | Lavender and strawberry suit a floral, sweet Moscato. | Lavender and strawberry suit a floral, sweet sparkling wine. |
| `apricot-and-orange-blossom-galette` | [White, Rosé] -> [White] | Apricot and orange blossom echo the perfume of a sweet Muscat. | Apricot and orange blossom echo the perfume of a sweet white. |
| `lychee-and-rose-panna-cotta` | [White, Sparkling] -> [Sparkling] | Lychee and rose reach the floral perfume of Moscato. | Lychee and rose reach the floral perfume of sparkling wine. |
| `jasmine-tea-panna-cotta-with-peaches` | [Sparkling, White, Rosé] -> [Sparkling] | Jasmine and peach suit a floral, sweet Moscato. | Jasmine and peach suit a floral, sweet sparkling wine. |
| `white-peach-and-lemon-verbena-granita` | [Sparkling, White] -> [Sparkling] | Peach and verbena suit a light, floral Moscato. | Peach and verbena suit a light, floral sparkling wine. |
| `melon-with-honey-and-lemon-balm` | [Sparkling, Rosé] -> [Sparkling] | Sweet melon and lemon balm suit a floral Moscato. | Sweet melon and lemon balm suit a floral sparkling wine. |
| `pear-and-chamomile-tart` | [White, Rosé] -> [Sparkling] | Chamomile and pear suit a floral, sweet Moscato. | Chamomile and pear suit a floral, sweet sparkling wine. |
| `orange-blossom-madeleines` | [White, Rosé] -> [Sparkling] | Light, floral madeleines suit a sweet, sparkling Moscato. | Light, floral madeleines suit a sweet sparkling wine. |
| `raspberry-and-rose-eton-mess` | [White] -> [Sparkling] | Rose and raspberry suit a floral, sweet Moscato. | Rose and raspberry suit a floral, sweet sparkling wine. |
| `vanilla-ice-cream-with-px-soaked-raisins-and-cinnamon` | [White] -> [Fortified] | A classic Andalusian dessert built around Pedro Ximénez. | A classic Andalusian dessert, built for a dense, sweet fortified wine. |
| `coffee-and-walnut-cake` | [White] -> [Fortified] | Coffee and walnut suit a dense, sweet sherry. | Coffee and walnut suit a dense, sweet fortified wine. |
| `chocolate-and-hazelnut-tart-with-tonka-bean` | [Fortified, Red] -> [Fortified] | Rich chocolate and toasted nuts suit a dense, sweet sherry. | Rich chocolate and toasted nuts suit a dense, sweet fortified wine. |
| `turron-semifreddo-with-cinnamon` | [White] -> [Fortified] | Honeyed nougat and cinnamon suit a sweet, dense sherry. | Honeyed nougat and cinnamon suit a sweet, dense fortified wine. |
| `apple-strudel-with-raisins-and-cinnamon` | [White] -> [White] | Apple and cinnamon suit an off-dry Riesling with bright acidity. | Apple and cinnamon suit an off-dry white with bright acidity. |
| `green-apple-and-lime-sorbet` | [Sparkling, Rosé, White] -> [White] | Crisp apple and lime mirror an off-dry Riesling. | Crisp apple and lime mirror an off-dry white. |
| `plum-kuchen-with-cardamom` | [White, Rosé] -> [White] | Tart plums and cardamom suit an off-dry, fruity Riesling. | Tart plums and cardamom suit an off-dry, fruity white. |
| `rhubarb-and-ginger-crumble` | [White, Rosé] -> [White] | Tart rhubarb and ginger suit an off-dry Riesling. | Tart rhubarb and ginger suit an off-dry white. |
| `pear-and-elderflower-jelly` | [Sparkling, White, Rosé] -> [White] | Pear and elderflower echo a floral, off-dry Riesling. | Pear and elderflower echo a floral, off-dry white. |
| `apricot-dumplings-with-buttered-crumbs-and-vanilla` | [White, Rosé] -> [White] | Apricot and vanilla suit an off-dry Austrian Riesling. | Apricot and vanilla suit an off-dry white. |
| `lemon-drizzle-cake-with-lemongrass` | [White, Rosé] -> [White] | Zesty lemon and lemongrass suit an off-dry, racy Riesling. | Zesty lemon and lemongrass suit an off-dry, racy white. |
| `peach-and-passion-fruit-pavlova-with-lime-leaf` | [White] -> [White] | Juicy peach and tart passion fruit suit an off-dry Riesling. | Juicy peach and tart passion fruit suit an off-dry white. |
| `apple-tarte-fine-with-lemon-thyme` | [White, Rosé] -> [White] | A thin apple tart suits a sweet, racy Riesling. | A thin apple tart suits a sweet, racy white. |
| `lychee-and-crystallised-ginger-sorbet` | [White, Rosé, Sparkling] -> [White] | Lychee and ginger echo the perfume and spice of Gewürztraminer. | Lychee and ginger echo the perfume and spice of an aromatic white. |
| `rose-and-pistachio-baklava` | [White, Rosé, Sparkling] -> [White] | Rose syrup and pistachio suit an aromatic, sweet Gewürztraminer. | Rose syrup and pistachio suit an aromatic, sweet white. |
| `mango-panna-cotta-with-cardamom` | [White, Rosé] -> [White] | Mango and cardamom suit a perfumed, sweet Gewürztraminer. | Mango and cardamom suit a perfumed, sweet white. |
