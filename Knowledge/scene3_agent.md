# Scene 3 - Płonący Budynek

## Opis Sceny (Gameplay)
Akcja toczy się we wnętrzu płonącego budynku, gracz porusza się bohaterem i musi ugasić pożar w ograniczonym czasie (ok. 5 minut). Scena podzielona jest na 5 faz: 
1. **DRZWI** - gracz musi rozrąbać drzwi siekierą (klikanie 'E').
2. **POŻARY** - masowe pojawianie się pożarów wokół, klikanie lewym przyciskiem myszy by gasić ogień.
3. **BABCIA** - poszukiwanie NPC "Babcia" i interakcja z nią.
4. **SKRZYNKA** - odnalezienie czarnej skrzynki lotniczej.
5. **KONIEC** - ucieczka do punktu ewakuacyjnego przed upływem czasu.
Mechanika opiera się na prostym `State Machine` przypisanym do zmiennej `faza`.

## Główne pliki i skrypty
- `scenes/scena_3.tscn` - budowa mapy i ustawienie gracza
- `scripts/scena_3.gd` - główna maszyna stanów, timer i HUD 
- `scripts/gracz.gd` - (w folderze scripts) obsługa ruchu i interakcji strażaka
- `scripts/ogien.gd` - logika wygaszania płomienia
- `scenes/ogien.tscn` - prefab pojedynczego pożaru

## Funkcje w `scena_3.gd`
- `_process(delta)` - Główne serce mechaniki. Odlicza czas do zera. Zależnie od zmiennej `faza` pozwala na rąbanie drzwi lub tworzy z czasem nowe obszary pożaru (w phase POŻARY).
- `_rabniecie_drzwi_tick()` - Zmniejsza "HP" drzwi, włącza trzęsienie kamery. Po wyzerowaniu otwiera drogę (fade in/out, usunięcie przeszkód).
- `zgaszono_ogien(ogien)` - Reaguje na informację od poszczególnych prefabów ognia. Gdy gasną wszystkie ognie w liście, przechodzi do fazy BABCIA.
- `_odswiez_minimape()` - Dynamicznie pozycjonuje kropki pożarów, gracza i celów na teksturze HUD-a na podstawie fizycznej wielkości mapy `(8192, 4096)`.
- `_odtworz_cutscenke()` - Na końcu uruchamia plik wideo OGV i MP3 z efektami dźwiękowymi, po czym przechodzi na Scenę 5.

## Wykorzystane Obrazy i Style
- **Minimapa:** Zamknięty budynek (`safeservemap (1).png`), Otwarty (`scena4_mapa_otwarte.png`).
- **Narzędzia i Markery:** `siekira_scena4.png`, kropki minimapy `Dot.png` oraz `scena4_wykrzyknik.png`.
- **Inne:** Grafiki płomieni z prefaba, tła oraz postać Babci.
- Wszystko toczy się w widoku izometrycznym / pseudo top-down z systemem "fade-in, fade-out" dla przejść pomiędzy fazami.

## Wskazówki dla Agenta
Zwróć uwagę na zmienną `faza`. Modyfikując logikę misji musisz pamiętać o poprawnym zaktualizowaniu stringów (np. `faza = "POZARY"`). Pozycje do spawnów ognisk pożaru są sztywno przypisane do tablicy wektorów w skrypcie. Skrypt również w locie generuje obiekty Area2D z CollisionShape dla Babci i Czarnej Skrzynki w ściśle określonych koordynatach. Pamiętaj o używaniu `is_instance_valid()`, bo pożary i NPC mogą być nagle niszczone przez gracza!
