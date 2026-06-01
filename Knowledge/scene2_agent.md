# Scene 2 - Wóz Strażacki w drodze

## Opis Sceny (Gameplay)
Jest to sekwencja jazdy wozem strażackim na wezwanie. Akcja rozgrywa się na proceduralnie generowanej mapie Krakowa na podstawie danych z OpenStreetMap. Gracz musi kierować wozem bojowym, używać sygnałów świetlnych i dźwiękowych by wymusić pierwszeństwo na pojazdach AI (NPC) i dotrzeć w wyznaczone miejsce na czas. Po dojechaniu odpalana jest cutscenka przejścia i załadowana zostaje Scena 3.

## Główne pliki i skrypty
- `scenes/scena_2.tscn` - budowa świata i UI (GPS, radio)
- `scripts/scena_2_world.gd` - zarządzanie jazdą, kierunkowskazem celu i cięciem (cutscenką).
- `scripts/scena_2.gd` - (rozszerza radio.gd) puszczanie wiadomości audio w odpowiednim momencie.
- `scripts/map_manager.gd` - potężny proceduralny generator terenu i dróg OpenStreetMap dla trybu single-player.
- `scripts/traffic_manager.gd` - spawnowanie cywili (wózki NPC) w odpowiedniej odległości.
- `scripts/NPCcar.gd` - sztuczna inteligencja ruchu drogowego (ustępowanie drogi).
- `scenes/Car/car.gd` - logika fizyki wozu strażackiego gracza.

## Funkcje Kluczowe
- W `scena_2_world.gd`:
  - `_process(_delta)` - Monitoruje odległość (GPS label) wozu do pożaru i wymusza przejście w wideo, jeśli speed < 10 i distance < 10.
  - `play_cutscene_sequence()` - Odtwarza plik `cuscean1ver4.ogv` chowając w tym samym momencie UI i usypiając fizykę, na koniec wczytując Scenę 3.
- W `map_manager.gd`:
  - `load_chunk_from_json()` - Parsuje pliki JSON do węzłów graficznych z odpowiednimi kolizjami i warstwami Z-index (trawa, asfalt, domy).
- W `NPCcar.gd`:
  - `yield_to_emergency()` - Po aktywacji sygnału syreny (`turn_siren` z car.gd), NPC próbują zmienić offset pasa (-6.0) i zerują prędkość na kilka sekund.

## Wykorzystane Obrazy i Style
- **HUD:** Używa grafik `HUD background.svg`, ikonek przełączników `Switch on.svg`/`Switch off.svg` do sterowania kogutem i dźwiękiem. Oraz popup radiowy (Motorola).
- **Mapa (skrót M):** `Mapa krakow OSM.png` (widok z góry, synchronizuje pozycje markerów dzięki matematyce wektorowej).
- **Zasoby:** Samochody NPC używają wariacji tekstur `car1.png` - `car8.png`. Przerywnik to plik `.ogv`. Cienie domów wyliczane wielokątami 2D.

## Wskazówki dla Agenta
Mapa drogowa to czysty data-driven procedural generation. Jeżeli chcesz zmodyfikować miasto, musisz pracować na parserze OSM. Autka NPC poruszają się po tzw. "grafie połączeń dróg". Bardzo często fizyka może tu zacinać (stąd fixy z `is_polygon_convex_custom`). Zwróć uwagę, by wywołania dla samochodu gracza używały `move_and_slide()` bez zbyt wielu nakładek na delcie czasowej, inaczej fizyka opon i tarcia poprzecznego zwariuje.
