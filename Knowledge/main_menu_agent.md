# Main Menu

## Opis Sceny (Gameplay)
Ekran startowy gry. Posiada tło, tytuł oraz 4 przyciski: "Nowa Gra", "Kontynuuj", "Ustawienia", "Wyjście". Po kliknięciu nowej gry lub kontynuacji pojawia się specjalny ekran ładowania z "fałszywym" paskiem postępu i losowo zmieniającymi się poradami dla gracza (tips), mającymi uprzyjemnić proces ładowania. Po "załadowaniu" gra przechodzi płynnie do pierwszej sceny lub ostatnio zapisanej sceny.

## Główne pliki i skrypty
- `scenes/main_menu.tscn` - główna struktura sceny
- `scripts/main_menu.gd` - obsługa kliknięć oraz animacji ekranu ładowania
- `scripts/game_config.gd` - singleton (Autoload) do zapisu/odczytu postępu gracza i trybów (np. `crab_mode`).

## Funkcje w `main_menu.gd`
- `_on_button_pressed()` - Obsługa "Nowa Gra", która odpala ekran ładowania w kierunku `scena_1.tscn`.
- `_uruchom_loading_screen(scene_path)` - Tworzy dynamiczny overlay `CanvasLayer` z tłem, paskiem i napisem "Tip".
- `_proces_ladowania(scene_path)` - Coroutine realizujący animację ładowania. Posiada randomowe zacinanie i opóźnienia symulujące odczyt danych. Na koniec przełącza na wybraną scenę.
- `_on_button_2_pressed()` - Czyta ostatni stan z `GameConfig` i próbuje kontynuować od zapisanej sceny.
- `_on_button_3_pressed()` - Przejście do ustawień (`ustawienia.tscn`).

## Wykorzystane Obrazy i Style
- **Tło:** `loading_background.png` (widok straży w tle).
- **Czcionki i tekst:** Surowy design, outline wokół tekstów porad (czarny outline, biały tekst).
- W ustawieniach dostępne jest tło `ustawieniabg.jpg`.

## Wskazówki dla Agenta
Jeżeli potrzebujesz zmodyfikować to, od jakiej sceny zaczyna się gra na starcie, powinieneś zmienić argument wywołania ładowania w `_on_button_pressed()`. Postępy zapisują się przez autoload `GameConfig.save_level()`, z którego Main Menu korzysta do przycisku "Kontynuuj".
