# Puzzlium

Jigsaw puzzle game for iPhone and iPad. SwiftUI, Swift 6, iOS 17+, offline-first.

## Run

```sh
brew install xcodegen        # once
xcodegen generate            # creates Puzzlium.xcodeproj (not committed)
open Puzzlium.xcodeproj
```

Tests:

```sh
# Domain, engine, data (Swift Testing)
cd Packages/PuzzliumKit && xcodebuild test -scheme PuzzliumKit-Package -destination 'platform=iOS Simulator,name=iPhone 17 Pro'
# UI smoke test (home → setup → game → hint → home)
xcodebuild test -project Puzzlium.xcodeproj -scheme Puzzlium -destination 'platform=iOS Simulator,name=iPhone 17 Pro'
```

## Structure

```
App/                      Composition root (AppContainer), resources, privacy manifest
Packages/PuzzliumKit/
  PuzzliumCore            Logging, analytics contract
  PuzzliumDomain          Entities, repository protocols, use cases (no frameworks)
  PuzzliumEngine          Piece cutting, geometry, snapping, board state, rendering
  PuzzliumData            HTTP client, offline-first catalog, SwiftData, image cache
  PuzzliumDesignSystem    Tokens and reusable components
  PuzzliumFeatures        SwiftUI screens + @Observable view models
UITests/                  XCUITest smoke test
scripts/generate_strings.py   Single source for all UI strings (en, ru)
```

Dependency rule: `Features → Domain ← Data`. Engine depends on nothing.

## Key decisions

- **Board rendering.** Pieces are cut once off the main thread (`PieceImageRenderer`). Placed pieces are
  composited into one bitmap (`BoardCompositor`), so a 400-piece board draws a single image per frame.
- **Deterministic cuts.** Layout is seeded from puzzle id + piece count; saves store only the seed and the
  placed set (≈2 KB), not geometry.
- **Offline-first.** Bundled catalog with on-device art, disk-cached remote catalog refreshed in the
  background, SwiftData progress. The app works fully without network.
- **Localization.** Edit `scripts/generate_strings.py`, run it, commit both generated files.

## Next

- Backend: set `AppConfiguration.apiBaseURL`; contract is `GET v1/catalog` → `{ "puzzles": [PuzzleDTO] }`.
- Firebase: add the SDK to `PuzzliumData` only, implement `AnalyticsTracking` there, swap it in `AppContainer`.
- iCloud sync of progress (`cloudKitDatabase` in `PersistenceFactory`).
- StoreKit 2 puzzle packs.
- In-app credits screen for the bundled photos (CC BY / CC BY-SA require visible attribution).

## Photo credits

Photo puzzles (`PuzzliumData/Resources/*.jpg`) are Wikimedia Commons photos, center-cropped and
resized to 1600×1600.
The exception is `art-autumn-pattern`, an original illustration drawn for Puzzlium.

| File | Author | License | Source |
|------|--------|---------|--------|
| landmark-eiffel-tower | Tristan Nitot | CC BY-SA 3.0 | [Commons](https://commons.wikimedia.org/wiki/File:Tour_eiffel_at_sunrise_from_the_trocadero.jpg) |
| landmark-colosseum | Anil Öztas | CC BY 4.0 | [Commons](https://commons.wikimedia.org/wiki/File:Rom_(IT),_Kolosseum_--_2024_--_0610.jpg) |
| landmark-great-wall | CEphoto, Uwe Aranas | CC BY-SA 3.0 | [Commons](https://commons.wikimedia.org/wiki/File:Badaling_China_Great-Wall-of-China-01.jpg) |
| landmark-taj-mahal | Yann; edited by King of Hearts | CC BY-SA 4.0 | [Commons](https://commons.wikimedia.org/wiki/File:Taj_Mahal,_Agra,_India_edit2.jpg) |
| landmark-giza-pyramids | Ricardo Liberato | CC BY-SA 2.0 | [Commons](https://commons.wikimedia.org/wiki/File:All_Gizah_Pyramids.jpg) |
| landmark-statue-of-liberty | Jakub Hałun | CC BY-SA 4.0 | [Commons](https://commons.wikimedia.org/wiki/File:Statue_of_Liberty,_New_York_City,_20231001_1037_0857.jpg) |
| landmark-machu-picchu | Martin St-Amant (S23678) | CC BY-SA 3.0 | [Commons](https://commons.wikimedia.org/wiki/File:80_-_Machu_Picchu_-_Juin_2009_-_edit.jpg) |
| landmark-sydney-opera-house | Thomas Adams | CC BY-SA 4.0 | [Commons](https://commons.wikimedia.org/wiki/File:Sydneyoperahouse_at_night.jpg) |
| landmark-big-ben | Colin | CC BY-SA 4.0 | [Commons](https://commons.wikimedia.org/wiki/File:Big_Ben_at_sunset_-_2014-10-27_17-30.jpg) |
| landmark-saint-basils | Юрий Д.К. | CC BY 4.0 | [Commons](https://commons.wikimedia.org/wiki/File:Moscow_-_2025_-_Daytime_view_of_St._Basil%27s_Cathedral_from_Vasilyevsky_Spusk.jpg) |
| nature-northern-lights | Johannes Groll | CC0 | [Commons](https://commons.wikimedia.org/wiki/File:Lofoten,_Norway_(Unsplash).jpg) |
| nature-autumn-forest | Ermell | CC BY-SA 4.0 | [Commons](https://commons.wikimedia.org/wiki/File:Bamberg_Bruderwald_Herbst-20151102-RM-110637.jpg) |
| nature-tropical-beach | Vyacheslav Argenberg | CC BY 4.0 | [Commons](https://commons.wikimedia.org/wiki/File:Havelock_Island,_Mangrove_tree_on_the_beach,_Andaman_Islands.jpg) |
| nature-sahara-night | Sergey Pesterev | CC BY-SA 4.0 | [Commons](https://commons.wikimedia.org/wiki/File:Moonlight_in_the_Sahara.jpg) |
| nature-icelandic-waterfall | Diego Delso | CC BY-SA 4.0 | [Commons](https://commons.wikimedia.org/wiki/File:Seljalandsfoss,_Su%C3%B0urland,_Islandia,_2014-08-16,_DD_201-203_HDR.JPG) |
| nature-forest-falls | Dietmar Rabich | CC BY-SA 4.0 | [Commons](https://commons.wikimedia.org/wiki/File:Beech_Forest_(AU),_Great_Otway_National_Park,_Beauchamp_Falls_--_2019_--_1271.jpg) |
| nature-mount-fuji | Romain Guy | CC0 | [Commons](https://commons.wikimedia.org/wiki/File:Mount_Fuji_at_sunset,_March_2025.jpg) |
| nature-glacier-lagoon | Jakub Hałun | CC BY 4.0 | [Commons](https://commons.wikimedia.org/wiki/File:Fjalls%C3%A1rl%C3%B3n_glacier_lake,_Iceland,_20240719_1720_2774.jpg) |
| nature-himalayan-lake | Vyacheslav Argenberg | CC BY 4.0 | [Commons](https://commons.wikimedia.org/wiki/File:Gokyo_Ri_summit,_Gokyo_Lake,_Nepal,_Himalayas.jpg) |
| nature-tulip-fields | Tuxyso | CC BY-SA 3.0 | [Commons](https://commons.wikimedia.org/wiki/File:Tulpenfelder-Neuss-Kapellen-01-2016.jpg) |
| city-amsterdam | Basile Morin | CC BY-SA 4.0 | [Commons](https://commons.wikimedia.org/wiki/File:Canal_houses_and_Oude_Kerk_at_blue_hour_with_water_reflection_in_Damrak_Amsterdam_Netherlands.jpg) |
| city-frankfurt | Jörg Braukmann | CC BY-SA 4.0 | [Commons](https://commons.wikimedia.org/wiki/File:Frankfurt_Skyline_2022_bei_Nacht.jpg) |
| city-hong-kong | Benh LIEU SONG | CC BY-SA 4.0 | [Commons](https://commons.wikimedia.org/wiki/File:Hong_Kong_Harbour_Night_2019-06-11.jpg) |
| city-new-york | Dllu | CC BY-SA 4.0 | [Commons](https://commons.wikimedia.org/wiki/File:View_of_Empire_State_Building_from_Rockefeller_Center_New_York_City_dllu.jpg) |
| city-prague | A.Savin | FAL | [Commons](https://commons.wikimedia.org/wiki/File:Prague_07-2016_View_from_Old_Town_Hall_Tower_img3.jpg) |
| city-rio | Donatas Dabravolskas | CC BY-SA 4.0 | [Commons](https://commons.wikimedia.org/wiki/File:Contrasts_of_Rio_de_Janeiro_-_Rocinha,_Ipanema,_and_Mountains_at_Sunrise.jpg) |
| city-santorini | Giles Laurent | CC BY-SA 4.0 | [Commons](https://commons.wikimedia.org/wiki/File:1000_Three_domes_of_Oia_in_Santorini_Photo_by_Giles_Laurent.jpg) |
| city-singapore | Basile Morin | CC BY-SA 4.0 | [Commons](https://commons.wikimedia.org/wiki/File:Aerial_photographs_of_The_Fullerton_Hotel_of_Singapore_at_night.jpg) |
| city-tokyo | Basile Morin | CC BY-SA 4.0 | [Commons](https://commons.wikimedia.org/wiki/File:Buildings_with_colorful_neon_street_signs_at_blue_hour,_Shinjuku,_Tokyo.jpg) |
| city-venice | Martin Falbisoner | CC BY-SA 4.0 | [Commons](https://commons.wikimedia.org/wiki/File:Panorama_of_Canal_Grande_and_Ponte_di_Rialto,_Venice_-_September_2017.jpg) |
| art-starry-night | Vincent van Gogh | Public domain | [Commons](https://commons.wikimedia.org/wiki/File:Van_Gogh_-_Starry_Night_-_Google_Art_Project.jpg) |
| art-great-wave | After Katsushika Hokusai | Public domain | [Commons](https://commons.wikimedia.org/wiki/File:Great_Wave_off_Kanagawa2.jpg) |
| art-water-lilies | Claude Monet | Public domain | [Commons](https://commons.wikimedia.org/wiki/File:Claude_Monet_-_Water_Lilies_-_1906,_Ryerson.jpg) |
| art-the-kiss | Gustav Klimt | Public domain | [Commons](https://commons.wikimedia.org/wiki/File:The_Kiss_-_Gustav_Klimt_-_Google_Cultural_Institute.jpg) |
| art-pearl-earring | Johannes Vermeer | Public domain | [Commons](https://commons.wikimedia.org/wiki/File:1665_Girl_with_a_Pearl_Earring.jpg) |
| art-grande-jatte | Georges Seurat | Public domain | [Commons](https://commons.wikimedia.org/wiki/File:A_Sunday_on_La_Grande_Jatte,_Georges_Seurat,_1884.jpg) |
| art-hunters-snow | Pieter Brueghel the Elder | Public domain | [Commons](https://commons.wikimedia.org/wiki/File:Pieter_Bruegel_the_Elder_-_Hunters_in_the_Snow_(Winter)_-_Google_Art_Project.jpg) |
| art-sunflowers | Vincent van Gogh | Public domain | [Commons](https://commons.wikimedia.org/wiki/File:Vincent_Willem_van_Gogh_127.jpg) |
| art-moulin-galette | Pierre-Auguste Renoir | Public domain | [Commons](https://commons.wikimedia.org/wiki/File:Renoir,_Pierre-Auguste_-_Dance_at_Le_Moulin_de_la_Galette,_1876.jpg) |
| art-almond-blossom | Vincent van Gogh | Public domain | [Commons](https://commons.wikimedia.org/wiki/File:Amandelbloesem_-_s0176V1962_-_Van_Gogh_Museum.jpg) |
| art-birth-of-venus | Sandro Botticelli | Public domain | [Commons](https://commons.wikimedia.org/wiki/File:Sandro_Botticelli_-_La_nascita_di_Venere_-_Google_Art_Project_-_edited.jpg) |
| art-mona-lisa | Leonardo da Vinci | Public domain | [Commons](https://commons.wikimedia.org/wiki/File:Mona_Lisa,_by_Leonardo_da_Vinci,_from_C2RMF_retouched.jpg) |
| art-impression-sunrise | Claude Monet | Public domain | [Commons](https://commons.wikimedia.org/wiki/File:Monet_-_Impression,_Sunrise.jpg) |
| art-cafe-terrace | Vincent van Gogh | Public domain | [Commons](https://commons.wikimedia.org/wiki/File:Van_Gogh_-_Terrasse_des_Caf%C3%A9s_an_der_Place_du_Forum_in_Arles_am_Abend1.jpeg) |
| art-wanderer-fog | Caspar David Friedrich | Public domain | [Commons](https://commons.wikimedia.org/wiki/File:Caspar_David_Friedrich_-_Wanderer_above_the_sea_of_fog.jpg) |
| art-red-fuji | Katsushika Hokusai | Public domain | [Commons](https://commons.wikimedia.org/wiki/File:Red_Fuji_southern_wind_clear_morning.jpg) |
| art-woman-parasol | Claude Monet | Public domain | [Commons](https://commons.wikimedia.org/wiki/File:Claude_Monet_-_Woman_with_a_Parasol_-_Madame_Monet_and_Her_Son_-_Google_Art_Project.jpg) |
| art-fighting-temeraire | J. M. W. Turner | Public domain | [Commons](https://commons.wikimedia.org/wiki/File:The_Fighting_Temeraire,_JMW_Turner,_National_Gallery.jpg) |
| art-milkmaid | Johannes Vermeer | Public domain | [Commons](https://commons.wikimedia.org/wiki/File:Johannes_Vermeer_-_Het_melkmeisje_-_Google_Art_Project.jpg) |
| art-night-watch | Rembrandt van Rijn | Public domain | [Commons](https://commons.wikimedia.org/wiki/File:La_ronda_de_noche,_por_Rembrandt_van_Rijn.jpg) |
| art-ninth-wave | Ivan Aivazovsky | Public domain | [Commons](https://commons.wikimedia.org/wiki/File:Hovhannes_Aivazovsky_-_The_Ninth_Wave_-_Google_Art_Project.jpg) |
| art-plum-garden | Utagawa Hiroshige | Public domain | [Commons](https://commons.wikimedia.org/wiki/File:De_pruimenboomgaard_te_Kameido-Rijksmuseum_RP-P-1956-743.jpeg) |
| art-adele-bloch-bauer | Gustav Klimt | Public domain | [Commons](https://commons.wikimedia.org/wiki/File:Gustav_Klimt,_1907,_Adele_Bloch-Bauer_I,_Neue_Galerie_New_York.jpg) |
| art-boating-party | Pierre-Auguste Renoir | Public domain | [Commons](https://commons.wikimedia.org/wiki/File:Pierre-Auguste_Renoir_-_Luncheon_of_the_Boating_Party_-_Google_Art_Project.jpg) |
| art-rain-steam-speed | J. M. W. Turner | Public domain | [Commons](https://commons.wikimedia.org/wiki/File:Turner_-_Rain,_Steam_and_Speed_-_National_Gallery_file.jpg) |
| art-hay-wain | John Constable | Public domain | [Commons](https://commons.wikimedia.org/wiki/File:John_Constable_-_The_Hay_Wain_(1821).jpg) |
| art-tower-of-babel | Pieter Bruegel the Elder | Public domain | [Commons](https://commons.wikimedia.org/wiki/File:Pieter_Bruegel_the_Elder_-_The_Tower_of_Babel_(Vienna)_-_Google_Art_Project_-_edited.jpg) |
| art-view-of-delft | Johannes Vermeer | Public domain | [Commons](https://commons.wikimedia.org/wiki/File:View_of_Delft,_by_Johannes_Vermeer.jpg) |
| art-pine-forest | Ivan Shishkin | Public domain | [Commons](https://commons.wikimedia.org/wiki/File:Shishkin,_Ivan_-_Morning_in_a_Pine_Forest.jpg) |
| art-golden-autumn | Isaac Levitan | Public domain | [Commons](https://commons.wikimedia.org/wiki/File:Levitan_Zolotaya_Osen.jpg) |
| art-ballet-class | Edgar Degas | Public domain | [Commons](https://commons.wikimedia.org/wiki/File:Edgar_Degas_-_The_Ballet_Class_-_Google_Art_Project.jpg) |
| art-arnolfini | Jan van Eyck | Public domain | [Commons](https://commons.wikimedia.org/wiki/File:Van_Eyck_-_Arnolfini_Portrait.jpg) |
| art-las-meninas | Diego Velázquez | Public domain | [Commons](https://commons.wikimedia.org/wiki/File:Las_Meninas,_by_Diego_Vel%C3%A1zquez,_from_Prado_in_Google_Earth.jpg) |
| art-paris-rainy-day | Gustave Caillebotte | Public domain | [Commons](https://commons.wikimedia.org/wiki/File:Gustave_Caillebotte_-_Paris_Street%3B_Rainy_Day_-_Google_Art_Project.jpg) |
| art-bedroom-arles | Vincent van Gogh | Public domain | [Commons](https://commons.wikimedia.org/wiki/File:Vincent_van_Gogh_-_Van_Gogh%27s_Bedroom_in_Arles_-_Google_Art_Project.jpg) |
| art-sudden-shower | Utagawa Hiroshige | Public domain | [Commons](https://commons.wikimedia.org/wiki/File:Hiroshige,_Sudden_shower_over_Shin-%C5%8Chashi_bridge_and_Atake,_1857.jpg) |
| art-card-players | Paul Cézanne | Public domain | [Commons](https://commons.wikimedia.org/wiki/File:Les_Joueurs_de_cartes,_par_Paul_C%C3%A9zanne.jpg) |
| art-tiger-storm | Henri Rousseau | Public domain | [Commons](https://commons.wikimedia.org/wiki/File:Henri_Rousseau_-_Surprise!.jpg) |
| art-barge-haulers | Ilya Repin | Public domain | [Commons](https://commons.wikimedia.org/wiki/File:Ilya_Repin_-_Barge_Haulers_on_the_Volga_-_Google_Art_Project.jpg) |
| art-japanese-footbridge | Claude Monet | CC0 | [Commons](https://commons.wikimedia.org/wiki/File:Claude_Monet,_The_Japanese_Footbridge,_1899,_NGA_74796.jpg) |
