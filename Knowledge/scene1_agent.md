# Scene 1 - Dyspozytornia

## Opis Sceny (Gameplay)
To jest główne centrum dyspozytorskie. Gracz ma przed sobą mapę miasta (Krakowa) z dynamicznie generowanymi zgłoszeniami (wypadki, pożary, przestępstwa) i jednostkami służb (policja, straż pożarna, karetki). Celem jest dopasowanie odpowiedniej jednostki do zgłoszenia. Poprawne połączenie (np. straż pożarna do pożaru) wysyła jednostkę, a po zlikwidowaniu wszystkich podstawowych zgłoszeń, pojawia się specjalne zdarzenie główne (pożar serwerowni), które po odsłuchaniu cutscenki przenosi do Sceny 2.

## Główne pliki i skrypty
- `scenes/scena_1.tscn` - główna struktura sceny
- `scripts/scena_1.gd` - logika wyboru jednostek i zgłoszeń
- `scripts/MapContainer.gd` - zarządzanie klikaniem i rysowaniem na mapie
- `scripts/MapEvent.gd` - pojedynczy event na mapie
- `scripts/modal_button.gd` - logika przycisków w modalach
- `scripts/radio.gd` & `scripts/radio_popup.gd` - wiadomości radiowe

## Funkcje w `scena_1.gd`
- `_ready()` - Inicjuje UI, ładuje mapę, spawnuje początkowe jednostki i zdarzenia.
- `generate_description(event)` - Tworzy tekstowy opis w panelu w zależności od typu zdarzenia (np. wiek poszkodowanego, ID budynku).
- `message(event)` - Obsługuje kliknięcie na marker. Aktywuje górny (zdarzenie) lub dolny (jednostka) panel informacyjny.
- `_send_unit()` - Waliduje dopasowanie (np. Fire rescue -> Fire). Zwraca sukces (Success modal) lub błąd (Fail modal).
- `_main_event()` - Aktywuje końcowy etap sceny (wielki pożar w PolyServers). 

## Wykorzystane Obrazy i Style
- **Tło / UI:** `HUD nowy.svg`, `pasekwindows.png`, `oknowindows.png`
- **Mapa:** `Mapa Krakow OSM.png`
- **Markery na mapie:** `ogien.png`, `police.svg`, `fire_truck.svg`, `ambulance.svg`, `zlodziej.svg`
- **Ikony strzałek:** `Arrow_icon_... .svg` dla wskazania zdarzenia poza ekranem.
- Styl UI to połączenie okienek w stylu starszych Windowsów i nowoczesnego wektorowego designu.

## Wskazówki dla Agenta
Zwróć uwagę na to, że po udanym połączeniu wszystkich jednostek odpalana jest funkcja `_main_event()`, w której pojawia się pożar. Dopiero kliknięcie odsłuchania komunikatu radiowego (`pozar_w_polyservers.wav`) uwalnia gracza i pozwala przejść do Sceny 2 (realizowane przez przycisk powiązany ze skryptem `modal_button.gd`). Cały stan zapisywany jest na starcie do pliku JSON.
