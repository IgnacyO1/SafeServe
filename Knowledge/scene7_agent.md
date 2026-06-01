# Scene 7 - Pościg Policyjny

## Opis Sceny (Gameplay)
Jest to izometryczny/Top-Down pościg autostradowy za podejrzanym samochodem ("Cyberkrab") ulicami miasta na podstawie otwartej mapy krakowa (OSM). Gracz steruje radiowozem (pojazdem, z sygnałami świetlnymi i dźwiękowymi), zmagając się z fizyką jazy i nocną porą ("night_mode" przygaszone kolory). Ścigany uciekinier (NPC) porusza się po sztywno przypisanej ścieżce na drogach z mechanizmem "rubber-bandingu" (zwalnia jeśli gracz zbytnio w tył, przyspiesza gdy za blisko). Cel misji to zmniejszyć dystans poniżej 7m przy jego małej prędkości, lub dotrzeć do momentu, w którym oponent dojeżdża na koniec swojej trasy. Zakończenie inicjuje cutscenkę i przejście do Sceny 8 (Boss Fight).

Istnieje też wersja sieciowa (Multiplayer) na dedykowanym serwerze (ENet na porcie 10567), gdzie pościg odbywa się z wieloma graczami naraz.

## Główne pliki i skrypty
- **Single-player:**
  - `scenes/scena_7.tscn` / `scripts/scena_7.gd` (Inicjalizacja)
  - `scripts/scena_7_world.gd` (Kontrola świata i weryfikacja złapania celu)
  - `scripts/traffic_manager_for_police.gd` (Menadżer ruchu drogowego, spawnowanie przeciwnika)
  - `scripts/map_manager_for_police.gd` (Generator/Renderer Mapy OSM)
  - `scripts/uciekinier.gd` (Zachowanie uciekającego Cyberkraba i nawigacja)
- **Multi-player:** (podobne pliki z przyrostkiem `_multiplayer`)

## Funkcje Kluczowe
- `_process(_delta)` (w `scena_7_world.gd`) - Główny monitor odległości. Aktualizuje "strzałkę" wskazującą cel, wpisuje metry do ekranowego UI, decyduje o przerwaniu jazdy na rzecz cutscenki gdy dystans spada.
- `_physics_process(delta)` (w `uciekinier.gd`) - Obsługuje podążanie po tablicy punktów (pathfollowing). Implementuje rubber-banding zależny od dystansu do gracza (zyskuje speed + 250 w bliskim zwarciu).
- `load_chunk_from_json(c_id)` (w map_managerze) - Dynamiczne doczytywanie jsonowych paczek mapy OpenStreetMap (drogi, budynki, cienie, zieleń) tworząc świat proceduralnie.

## Wykorzystane Obrazy i Style
- **HUD:** Ikony `Switch off.svg`, `Switch on.svg`, `Siren icon.svg`, krótka wiadomość radiowa `Krótkofalówka dymek.png` z twarzą bohatera.
- **Świat:** Proceduralne tła i chodniki generowane z wektorów + powtarzalne tekstury asfaltu i trawy. Wszystko ocieniane programowo na granatowy, zimny odcień (noc).
- **Zasoby:** Wideo zakończenia to `spin.ogv`.

## Wskazówki dla Agenta
Mapa OSM ładuje się chunkami dynamicznie wokół pozycji gracza (radius loading). Jeżeli zechcesz ingerować w fizykę jazdy radiowozu (plik `police.gd`), pamiętaj, że samochód posiada osobne obliczenia tarcia poprzecznego oraz podział na tereny trawiaste (grass) i asfalt, a to wszystko zoptymalizowane w `move_and_slide()`. System uciekiniera opiera się na sztucznym pompowaniu prędkości: gdy zmieniasz parametry bossa, upewnij się, że "gracz" ma matematyczne szanse go dogonić w najszybszym fragmencie autostrady!
