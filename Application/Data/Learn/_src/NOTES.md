Task: write all Learn lessons as JSON. Sources go in scratchpad/src/{path,grape,region}/<moduleId>.json (DSL in build.py docstring).
Run: python3 scratchpad/build.py [files]  -> writes Data/Learn/{Path,Grapes,Region}/<moduleId>/module.json + <lessonId>.json + index.json, validates LESSON.md rules.
Module meta: path {level}; grape {color red|white, aliases[], origin, countries[], points "E G R T = n"}; region {country, countryCode, grapes[], points "S C E H = n"}.
Order: path 1..30; grape 1..50 (GRAPE.MD order); region 1..50 (REGION.MD order).
Never commit (user does).
Rules learned: matchPairs left and right must be unique (no category pairs); options unique; sm 4-5 opts 2-3 answers; mp right <=5 words. Done so far: see ls src/*/
Path (30) and Grapes (50) DONE. Region ids/order (skeleton: The place, The grapes, themes, Labels and the table, Module review):
1 region-fr-bordeaux A, 2 region-fr-burgundy A, 3 region-fr-champagne A, 4 region-fr-loire-valley B, 5 region-fr-southern-rhone B, 6 region-fr-alsace B, 7 region-fr-northern-rhone C, 8 region-fr-beaujolais C,
9 region-it-piedmont A, 10 region-it-tuscany A, 11 region-it-veneto A, 12 region-it-sicily C, 13 region-it-trentino-alto-adige C, 14 region-it-friuli-venezia-giulia C, 15 region-it-campania D,
16 region-es-rioja A, 17 region-es-jerez A, 18 region-es-ribera-del-duero D, 19 region-es-priorat D, 20 region-es-rias-baixas D,
21 region-pt-douro A, 22 region-pt-madeira B, 23 region-pt-vinho-verde C, 24 region-pt-alentejo C, 25 region-pt-dao C,
26 region-de-mosel A, 27 region-de-rheingau B, 28 region-de-pfalz C, 29 region-at-burgenland B, 30 region-at-wachau C, 31 region-hu-tokaj A, 32 region-gr-santorini C, 33 region-ge-kakheti B,
34 region-us-napa-valley B, 35 region-us-sonoma-county C, 36 region-us-willamette-valley C, 37 region-us-washington-state C,
38 region-ar-mendoza B, 39 region-ar-salta D, 40 region-ar-patagonia D, 41 region-cl-maipo-valley C, 42 region-cl-casablanca-valley D,
43 region-au-barossa-valley B, 44 region-au-margaret-river D, 45 region-au-hunter-valley D, 46 region-nz-marlborough C, 47 region-nz-hawkes-bay C, 48 region-nz-central-otago D, 49 region-za-stellenbosch C, 50 region-za-swartland D
Ordering needs >=4 items (common mistake).
