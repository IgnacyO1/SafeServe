# Scene 5 - Monitoring Policyjny i Rozpoznanie

## Opis Sceny (Gameplay)
Jest to interfejs "wewnątrzkomputerowy" służb mundurowych (CCTV). Widzimy ekran monitoringu z suwakiem wideo po lewej oraz panel bazy danych po prawej stronie. Gracz musi przeanalizować nagranie wideo, by odczytać numer tablicy rejestracyjnej (szukany to `KR4B2137`), a następnie wpisać go w pole tekstowe. Skrypt analizuje, czy tablica zgadza się w pełni lub jest podobna (podpowiadając alternatywy). Zlokalizowanie poprawnego pojazdu pozwala zobaczyć go na mapie Krakowa i wysłać patrol policyjny (co uruchomi przejście do Sceny 7). Puste i złe wciskanie skutkuje komunikatem "FAŁSZYWY ALARM".

## Główne pliki i skrypty
- `scenes/scena_5.tscn` - układ elementów bazowych
- `scripts/scena_5.gd` - logika wpisywania, walidacji tekstu i odpalania patrolu. W 100% zarządza kodem tworzącym UI.

## Funkcje w `scena_5.gd`
- `_build_ui()` & `_build_map_ui()` - Programowo tworzy całe drzewo węzłów UI: tła, panele, split containery, wejścia tekstowe i przyciski w stylu Motorola Corporate Identity (Ciemnoniebieski z akcentami).
- `_setup_video()` - Ustawia odtwarzacz wideo ładując plik `output.ogv` o odpowiednich proporcjach (np. 16:9).
- `_on_timeline_changed(value)` - Pozwala graczowi swobodnie nawigować (skrobać) suwakiem wideo po nagraniu.
- `_on_search_pressed()` - Wykonuje sprawdzenie tablicy na podstawie zdefiniowanego słownika `plates`. Algorytm liczy pseudo-edycyjny dystans (w funkcji `_oblicz_roznice`), by dawać wskazówki przy drobnych literówkach.
- `_on_dispatch_pressed()` - Finał sceny: jeśli wyszukano KR4B2137 ładuje Scenę 7. Jeśli wpisano co innego - pokazuje opóźnienie "Patrol w drodze" po czym daje status fałszywego alarmu.

## Wykorzystane Obrazy i Style
- **Tło UI:** Wygenerowane z kodu odcienie `Color("#15053d")`, krawędzie `Color("#008bc2")` (styl Motoroli).
- **Przyciski:** Programowo robione płaskie obiekty (StyleBoxFlat).
- **Mapa:** W przypadku sukcesu pojawia się `Mapa krakow OSM.png` z czerwoną migającą kropką poszukiwanego wozu.
- **Inne:** `oknowindows.png`, `pasekwindows.png`.
- **Wideo:** `output.ogv`

## Wskazówki dla Agenta
Całe UI tej sceny budowane jest DRZEWEM Z KODU (nie z poziomu edytora graficznego Godot), co zapobiega crashom i rozjeżdżaniu się UI na innych rozdzielczościach. Jeżeli chcesz zmienić pozycję lub kolor przycisków, musisz ingerować w GDScript (np. `_style_button`). To stąd pochodzi mechanika przechodzenia między monitoringiem a pościgiem w Scenie 7!
