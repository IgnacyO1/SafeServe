# Scene 8 - Boss Fight: Cyberkrab

## Opis Sceny (Gameplay)
Ostateczna walka z głównym bossem, znanym jako CYBERKRAB. Jest to gra typu Bullet-Hell w zamkniętej, piaszczystej arenie 2560x1440. Gracz porusza się policjantem na 8 stron i strzela kulami energetycznymi do bossa. Walka podzielona jest na 6 bezwzględnych FAZ, eskalujących w stopniu trudności (teleportacja, promienie lasera, fale pocisków). Dodatkowym elementem utrudniającym i jednocześnie ułatwiającym walkę są **Tramwaje** przejeżdżające co 30 sekund na losowej wysokości (górny tor Y ≈ 814-999 lub dolny tor Y ≈ 724-892). Tramwaj blokuje ruch (jest fizyczną przeszkodą), pochłania i niszczy wrogie oraz sojusznicze pociski (funkcjonuje jako osłona), a w przypadku zderzenia z graczem zadaje 1 punkt obrażeń, trzęsie ekranem i wywołuje silny odrzut (knockback). Zderzenie z Cyberkrabem również odpycha bossa na bok. Po pierwszej fałszywej śmierci przeciwnika, następuje widowiskowa scena a la Undertale ("BUT HE REFUSED") i walka odpala ekstremalnie trudną Fazę 6 "THE UNDYING" z podkręconymi statystykami prędkości.

## Główne pliki i skrypty
- `scenes/scena_8.tscn` - ułożenie areny, ścian i podstawowych węzłów
- `scripts/scena_8.gd` - (Main Brain) maszyna stanów całej bitwy (generuje HUD z kodu, zarządza laserami i mechaniką wygranej/przegranej, odmierza czas spawnu tramwaju).
- `scripts/scena8_gracz.gd` - obsługa gracza (ruch 8 kierunkowy z inputa, strzelanie myszką, obsługa knockbacku).
- `scripts/scena8_krab.gd` - sztuczna inteligencja bossa (patrzy w stronę gracza, skacze o ściany areny, używa fali, teleportów, obsługa knockbacku).
- `scripts/scena8_pocisk_gracza.gd` / `pocisk_kraba.gd` / `pocisk_fala.gd` - logiki lecących pocisków (dodano niszczenie na kontakcie z grupą `"tramwaj"`).
- `scenes/Tram/Tram.tscn` - trójczłonowa scena tramwaju współdzielona z całą grą (dynamicznie rozszerzana o kolizje w Scenie 8).
- `scenes/Tram/TramController.gd` - zunifikowany skrypt ruchu i kolizji tramwaju (obsługuje ruch po drogach OSM oraz ruch prostoliniowy na arenie walki).

## Funkcje Kluczowe w `scena_8.gd`
- `_sprawdz_faze()` - Oblicza aktualny procent HP kraba i modyfikuje fazy. Wysyła informację tekstową na ogromny `label_info` (np. "⚠️ PROMIEŃ ZAGŁADY! ⚠️"). Wprowadza trzęsienie ekranu.
- `_zarzadzaj_laserem(delta)` / `_zarzadzaj_sweep(delta)` - State machines operujące potężnymi atakami laserowymi (rysowanymi jako precyzyjne `Line2D` wektory). Ostrzega gracza cienką, celującą w niego linią, która zaraz po tym uderza wielkim, pomarańczowo-białym pękiem promieni. Implementacja weryfikuje dystans gracza od wektora segmentu w celu przyznania obrażeń.
- `_fake_wygrana()` & `_prawdziwa_wygrana()` - Wykonuje spektakularne animacje (Time slow-motion, modyfikacja czasu gry `Engine.time_scale`, seria małych zdestrukowanych eksplozji i ekranów z czarnymi/białymi błyskami). 
- `_spawn_tram_scene8()` - Instancjuje tramwaj i inicjalizuje go na wybranym torze (górnym bądź dolnym).

## Wykorzystane Obrazy i Style
- **Tło:** `tło_walki.png` - duża mapa walki z namalowanymi za pomocą interaktywnego skryptu w pythonie (`draw_tracks_interactive.py`) torami tramwajowymi.
- **Postacie:** Przeciwnik wykorzystuje pełny spritesheet animacji ruchu i ataku (`krabkolor.png`, `laser_kolor`, `run_sprite`). Postać policjanta zbudowana z animowanych rzutów 8-kierunkowych (`policja_gora.png`, ukosy itp). Wagon tramwaju składa się z 3 segmentów graficznych (`segment1.png`, `segment2.png`, `segment3.png`).
- **Ataki:** Różowe śruby jako fale (`sruba.png`), kule lasera i dynamicznie renderowane poprzez zagnieżdżone w silniku Node Line2D kolorowe smugi świetlne w trybie Additive/Glow.

## Wskazówki dla Agenta
To najbardziej złożona scena od strony animacyjnej. Kod w 80% znajduje się w `scena_8.gd`. Wiele zniszczeń, modyfikacji HP i laserów tworzonych jest proceduralnie na stosach (stąd tyle sprawdzania `is_instance_valid()`). Jeżeli tworzysz nową broń, zaktualizuj pliki strzelania (pociski instancjują obiekty `Area2D` ze zdefiniowanym collision). Mechanika "Cyberkrab The Undying" w 6-tej fazie włącza się tylko przy wybranym zmiennym `GameConfig.crab_mode == "turbo"`. Tramwaje jeżdżą w linii prostej z lewej do prawej na torze dolnym i z prawej do lewej na torze górnym, pojawiając się zawsze za ekranem i czyszcząc się automatycznie po wyjechaniu poza obszar walki.

