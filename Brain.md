# SafeServe - Brain.md (Kompendium Wiedzy i Architektura Projektu)

Jesteś asystentem AI pracującym nad projektem **SafeServe**. Ten dokument to nasza główna baza wiedzy (Brain), "wizytówka" projektu, przewodnik po architekturze i stylach. Opieraj się wyłącznie na nim, aby zrozumieć kontekst gry, unikać błędów projektowych i zachować spójność wizualną oraz mechaniczną. Ignoruj stary plik `Context.md`. 

Plik ten został zoptymalizowany, aby dostarczyć maksimum merytorycznej wiedzy w skondensowanej formie (~250-300 linii).

---

## 1. Opis Projektu i Główne Założenia

**SafeServe** to hybrydowa gra akcji i symulatora zarządzania kryzysowego (Serious Game) osadzona w realiach top-down 2D. Gracz wciela się w operatora służb ratunkowych i bohatera akcji. Rozgrywka płynnie przechodzi pomiędzy różnymi gatunkami:
1. **Zarządzanie i Strategia** (dyspozytornia, parowanie jednostek ratunkowych do zagrożeń na mapie miejskiej).
2. **Nawigacja i Pościg** (jazda wozem strażackim/radiowozem po generowanym mieście opartym o dane mapowe).
3. **Akcja / Arcade** (eksploracja płonącego budynku, gaszenie pożarów, rąbanie drzwi siekierą, ucieczka przed czasem).
4. **Rozwiązywanie zagadek** (analiza kamer monitoringu, odczytywanie tablic rejestracyjnych).
5. **Boss Fight** (zręcznościowa walka na zamkniętej arenie z bossami, takimi jak "Cyberkrab").

---

## 2. Styl Graficzny i Generowanie Zasobów (Prompty AI)

Gra łączy realistyczne dane przestrzenne (mapy OSM, Kraków) ze stylizowanymi grafikami 2D. Jeśli jako agent będziesz proszony o wygenerowanie nowych zasobów wizualnych (np. przez DALL-E/Midjourney/Imagen), bezwzględnie trzymaj się poniższych wytycznych i promptów bazowych.

**Główny kierunek artystyczny (Art Direction):**
*   **Kąt kamery:** Top-Down (widok z lotu ptaka z pełnego zenitu) dla map i jazdy, lub lekkie 2/3 (rzut pseudo-izometryczny) dla akcji w budynkach i walk z bossami.
*   **Styl:** Clean 2D Vector Art połączony z nowoczesnym Pixel Artem (16-bit / 32-bit era), nasycone i ostre kolory (pomarańcze ognia, neony policyjne), czytelne zarysy bez zbędnego realizmu (czytelność ponad detale).

**Szablony Promptów do generowania grafik (AI Image Prompts):**

*   **Dla Postaci, Przeciwników i Pojazdów (Sprite'y):**
    > "2D video game sprite, top-down perspective, [OPIS POSTACI np. police car with flashing lights / cyberpunk crab monster], flat clean vector art style, thick distinct outlines, bold vibrant colors, transparent background, simulation game asset, no cast shadows on floor, highly readable at small scale."
*   **Dla Przedmiotów i Ikon UI (np. Siekiera, Czarna Skrzynka, Markery GPS):**
    > "2D game inventory icon of a [OPIS PRZEDMIOTU np. fire axe / black flight recorder box], cartoon vector style, cel-shaded, vibrant colors, UI element, transparent background, isolated, simple and punchy."
*   **Dla Tła, Aren i Map (np. Wnętrze płonącego budynku, Arena walki):**
    > "2D top-down video game map background, [OPIS SCENERII np. office floor plan / cyberpunk neon street intersection], flat colors, orthographic view, clear walkable areas, distinct non-walkable walls, retro-modern indie game style, dark atmosphere with localized bright light sources."

**Kluczowe zasady spójności:** Wszystkie zasoby muszą mieć przezroczyste tło (zazwyczaj usuwane skryptem w Pythonie lub wprost generowane). Zawsze pytaj gracza/twórcę, czy chce by nowa grafika była pixel-artem czy wektorem, zależnie od tego z czym aktualnie pracujemy na danej scenie.

---

## 3. Architektura Techniczna i Wzorce Godot 4.x

Gra została zbudowana na silniku **Godot 4.x** przy użyciu **GDScript**. Pracując z kodem, stosuj poniższe standardy i wzorce, które zostały wypracowane w projekcie:

1.  **Język i Nazewnictwo:** 
    *   Wszystkie nazwy zmiennych, funkcji i węzłów stosują polskie nazewnictwo (np. `gracz`, `krab`, `drzwi_hp`, `zgaszono_ogien`).
    *   Używaj stylu `snake_case` dla zmiennych/funkcji oraz `PascalCase` dla nazw Klas i Węzłów (Nodes).
2.  **Odporność na błędy (Crash Prevention):**
    *   Dynamicznie tworzone i niszczone obiekty (jak pożary, przeciwnicy pociski) wymagają stałych weryfikacji. 
    *   Zawsze używaj `if is_instance_valid(obiekt):` przed modyfikacją lub odczytem pozycji obiektu w `_process(delta)`.
3.  **Maszyny Stanów (State Machines):**
    *   Logika scen nie używa złożonych węzłów do stanów. Opiera się na prostych zmiennych typu String (np. `var faza = "DRZWI" | "POZARY" | "BABCIA"`).
    *   Funkcja `_process(delta)` działa jako główny dyrygent (router), wykonując bloki kodu warunkowane obecną `fazą`.
4.  **UI i Animacje (Tweens):**
    *   Unikamy węzła `AnimationPlayer` do prostych efektów interfejsu.
    *   Stosujemy `create_tween()` w locie (np. fade-in/fade-out robiony poprzez płynną zmianę `modulate:a` lub `color:a` w `ColorRect`).
    *   Przykładowy wzorzec fade: 
        ```gdscript
        var tw = create_tween()
        tw.tween_property(fade_rect, "color:a", 1.0, 1.0)
        await tw.finished
        ```
5.  **Przejścia między scenami i Cutscenki:**
    *   Wideo obsługiwane jest przez klasę `VideoStreamPlayer` ładującą format `.ogv`.
    *   Filmy są zawsze ukrywane za "czarnym ekranem" (ColorRect na CanvasLayer z warstwą `layer = 100+`), który jest łagodnie rozjaśniany po rozpoczęciu odtwarzania wideo.

---

## 4. Struktura Katalogów i Zarządzanie Danymi

Wszelkie zasoby muszą trafiać w odpowiednie, predefiniowane miejsca w katalogu głównym projektu (`c:\Users\ignac\Desktop\SafeServe\SafeServe`):

*   **`scenes/`**: Węzły główne w formacie `.tscn`. Każda scena gry to osobny plik (od `scena_1.tscn` do `scena_8.tscn`). Znajdują się tu też instancjonowane prefaby (np. `pocisk.tscn`, `ogien.tscn`, `uciekinier.tscn`).
*   **`scripts/`**: Skrypty logiki (`.gd`). Główny skrypt sceny nosi dokładnie taką samą nazwę jak scena (np. `scena_8.tscn` -> `scena_8.gd`).
*   **`assets/`**: Repozytorium multimediów:
	*   `graphics/`: Sprite'y, spritesheety, tła map (OSM), ikony ui, modele postaci.
	*   `Videos/`: Pliki z cutscenkami (`.ogv`), np. `cuscean1ver4.ogv`, `zawila.ogv`.
	*   `Images/`: Podstawowe assety UI (np. kropki `Dot.png`).
	*   `Fonts/` i `Sounds/`: Czcionki i efekty dźwiękowe.
*   **`data/`**: Surowe zbiory danych, skrypty pre-processingowe (np. `krakow-SW.geojson`, skrypty w Pythonie jak `map_preprocessing.py`, `mapa4_generator.py` służące do proceduralnego generowania terenów dla gier).

---

## 5. Przewodnik po Scenach (Scene by Scene Flow)

Poniżej znajduje się architektura przejść i celów dla całego kręgosłupa gry.

### Scena 1: Dyspozytornia
*   **Gameplay:** Gracz dopasowuje markery na mapie do jednostek (Wypadek -> Karetka, Ogień -> Straż, Przestępstwo -> Policja). Posiada "Main Event" uruchamiający kolejny etap.
*   **Kluczowe pliki:** `scena_1.gd`, `MapContainer.gd`, `MapEvent.gd`.

### Scena 2: Wóz Strażacki w drodze
*   **Gameplay:** Dojazd Strażą Pożarną w widoku z lotu ptaka do współrzędnych pożaru `(-62668, 73086)` z punktu `(-2356, 44164)`. Strzałka wskazuje azymut.
*   **Kluczowe pliki:** `scena_2.gd`, `map_manager.gd`.

### Scena 3: Płonący Budynek (Główna akcja strażacka)
*   **Gameplay:** Oparty na rygorystycznych limitach czasowych (3 minuty) i 5 fazach (`DRZWI`, `POZARY`, `BABCIA`, `SKRZYNKA`, `KONIEC`). Zastosowano mechaniki klikania (spamowanie E dla rąbania drzwi i podnoszenia NPC) oraz lewy klik dla gaszenia pojawiających się pożarów. Gra posiada dynamiczną minimapę aktualizującą pozycje.
*   **Kluczowe pliki:** `scena_3.gd`, `gracz.gd`, `ogien.gd`.

### Scena 4: Powrót wozu do bazy
*   **Gameplay:** Powrót straży do punktu startowego `(-2356, 44164)`. Sekwencja cutscen (komisariat -> policja) wyzwala się po zderzeniu z celem.
*   **Kluczowe pliki:** `scena_4.gd`.

### Scena 5: Monitoring Policyjny i Rozpoznanie
*   **Gameplay:** Interfejs śledczy. Gracz ogląda wideo z suwakiem i musi wpisać poszukiwany numer rejestracyjny "KR4B2137", gdyż nagranie to film z parkingu z nałożonym YOLO gdzie etykiety to nr rejestracyjne, a podejrzany samochód Cyberkraba ma właśnie taki numer. Sukces lokalizuje uciekiniera na mapie OSM i pozwala wysłać policyjny patrol w pościg.
*   **Kluczowe pliki:** `scena_5.gd`.

### Scena 6: Pościg (Dojazd na miejsce)
*   **Gameplay:** Szybki dojazd Policji na ulicę Zawiłą `(-40671, 98832)`.
*   **Kluczowe pliki:** `scena_6.gd`.

### Scena 7: Pościg Autostradowy za uciekinierem
*   **Gameplay:** Dynamiczne podążanie za pędzącym AI ("Uciekinier"). Zwycięstwo następuje po zbliżeniu się do celu na dystans mniejszy niż 7 metrów w momencie jego zwalniania.
*   **Kluczowe pliki:** `scena_7.gd`, `uciekinier.gd`, `traffic_manager_for_police.gd`.

### Scena 8: Boss Fight - Cyberkrab
*   **Gameplay:** Arena Bullet-Hell na jednym ekranie (1920x1080). Mechanika One-Hit-Kill dla gracza. Boss ("Cyberkrab") posiada system ucieczki i teleportacji, reaguje agresją na procent własnego HP (Fazy 1 do 4). Po pokonaniu następuje widowiskowa sekwencja eksplozji z wykorzystaniem manipulacji czasu (`Engine.time_scale`).
*   **Kluczowe pliki:** `scena_8.gd`, `gracz_scena8.gd`, `krab.gd`.

---

## 6. Procedury dla Agentów (Jak pracować z kodem)

*   **Zawsze weryfikuj pozycje plików w `_ready()`:** Ścieżki do obrazów i filmów często były twardo kodowane (tzw. hardcoded paths typu `res://assets/...`). Przy dodawaniu nowych plików zawsze upewnij się, że ich lokalizacja w systemie plików zgadza się ze stringiem w GDScript.
*   **Projektuj systemy jako odporne (Fail-Safe):** Ze względu na szybkie iterowanie przy tym projekcie, dodawaj zabezpieczenia przed crashami. Zawsze weryfikuj `if not node:` przed wykonaniem funkcji.
*   **Konsultuj Zmiany Fazy:** Ponieważ gra opiera się na prostych ciągach logicznych (`faza="DRZWI"` -> `faza="POZARY"`), ingerencja w jedną ze scen wymaga dogłębnej weryfikacji tego w jaki sposób następuje zmiana pętli (zazwyczaj wyzwalana po wyczerpaniu licznika lub HP obiektu).
*   **Tworząc UI, trzymaj warstwy wysoko:** Wszelkie CanvasLayery służące jako przysłony (Fade out), minimapy lub etykiety HUD (Heads-Up Display) powinny zawsze mieć parametr z-index lub właściwość warstwy na poziomie wyższym niż 50 (`layer = 100`), aby nie przykryły ich grafiki wektorowe ani cutsceny.
