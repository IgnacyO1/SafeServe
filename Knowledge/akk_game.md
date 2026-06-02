# SafeServe — Kompletny Opis Gry (Przeznaczony do Generowania Grafik AI)

> **Cel tego dokumentu:** Opisać grę SafeServe w taki sposób, aby generatorowi obrazów (Midjourney, DALL-E, Imagen, Stable Diffusion) można było podać fragment tego pliku jako kontekst i uzyskać grafikę w DOKŁADNIE TAKIM SAMYM stylu wizualnym co reszta gry. Każda scena ma osobne sekcje opisujące: akcję, atmosferę, używane kolory, proporcje, styl i gotowe szablony promptów. Nie wolno mieszać stylów między scenami — każda ma swoją paletę i nastrój, ale wszystkie dzielą JEDEN wspólny "fundament" artystyczny opisany poniżej.

---

## 🎨 GLOBALNY KANON WIZUALNY (czytaj PRZED każdym promptem)

To sekcja OBOWIĄZKOWA — każda grafika do gry SafeServe musi trzymać się tych reguł BEZ WYJĄTKU.

### Silnik i Perspektywa

- **Silnik gry:** Godot 4.x, 2D.
- **Perspektywa MAPY i JAZDY:** Czyste top-down (widok z zenitu, 90° w dół). Brak perspektywy izometrycznej w scenach jazdy po mieście.
- **Perspektywa AKCJI WEWNĄTRZ BUDYNKU (Scena 3) i BOSS FIGHT (Scena 8):** Pseudo-izometryczny rzut 2/3 — leciutki kąt, ale nadal bardzo bliski top-down. Ściany mają minimalną "grubość" widoczną od góry.
- **Rozdzielczość i proporcje:** Gra celuje w 1920×1080 (16:9). Elementy UI i sprite'y muszą być czytelne w tej rozdzielczości.

### Styl Artystyczny — "Retro-Modern Ops"

Gra ma JEDEN styl artystyczny łączący dwa podejścia w zależności od sceny:

| Element | Styl |
|---|---|
| Pojazdy (Sprite'y) | Clean 2D Vector Art — grube, wyraźne obrysowania, płaskie wypełnienia, zero realizmu. |
| Postacie (Sprite'y) | Pixel Art 32×32 lub 48×48 px (styl 16/32-bit), sprite-sheet z animacją chodu w 8 kierunkach. |
| Tła map (Top-Down) | Flat Vector Map — styl mapy OSM zrenderowanej jako gra (asfalt ciemnoszary, trawa ciemnozielona, budynki szarobeżowe z jasnym obrysem). |
| Wnętrza budynków | Top-down floor plan w stylu retro RPG — podłogi jako jednolite tekstury, ściany jako grube ciemne linie. |
| UI / HUD | Dwa rejestry: (1) stary Windows 98/XP — szare okna, przyciski z wypukłym efektem; (2) Motorola Corporate — granatowe tło `#15053d`, akcenty błękitne `#008bc2`. |
| Efekty (ogień, laser) | Particle art + additive glow — jaskrawe, nasycone kolory, efekt świecenia (glow/bloom). |

### Paleta Kolorów Globalnych

```
ASFALT:          #2a2a2e (ciemnoszary)
TRAWA:           #1e3a1e (ciemnozielona)
BUDYNKI (mapa):  #3d3d42 (wypełnienie) + #6a6a78 (obrys)
NIEBO (noc):     #0a0a1a (prawie czarny granat)
AKCENT OGNIA:    #ff6600 (pomarańcz) + #ffcc00 (żółty) + #ff2200 (czerwony)
POLICJA UI:      #15053d (tło) + #008bc2 (akcent) + #ffffff (tekst)
RADIOWOZY:       #1a1a8c (granat) + #cccccc (srebrny) + #ff2200 (kogut czerwony) + #0044ff (kogut niebieski)
WÓZ STRAŻACKI:  #cc2200 (ciemnoczerwony) + #ffdd00 (żółty reflektor) + #888888 (srebrny chrom)
GRACZ (strażak): #cc2200 (kurtka) + #ffdd00 (żółty odblask) + #1a1a1a (spodnie) + #ff4400 (hełm)
GRACZ (policjant): #1a1a8c (mundur granatowy) + #cccccc (srebrna odznaka) + #f5d5a0 (twarz)
BOSS (Cyberkrab): #00ccff (elektryczny błękit) + #00ff88 (zielony neon) + #660099 (ciemny fiolet) + #ff00cc (różowy neon)
```

### Czego NIGDY nie robić (Anty-wzorce)

- ❌ NIE GENEROWAĆ realistycznych, fotograficznych grafik — gra jest stylizowana.
- ❌ NIE MIESZAĆ palety policynej (`#15053d`) z paletą ognia. Każda scena ma swój nastrój.
- ❌ NIE UŻYWAĆ gradientów tęczowych — gradienty tylko w ogniu i efektach świetlnych laserów.
- ❌ NIE DODAWAĆ cieni rzucanych przez postacie na podłogę w trybie top-down map/jazdy (brak rzuconych cieni na płaskiej mapie!). Cienie budynków są generowane proceduralnie przez silnik i są ciemnym wielokątem po południowo-wschodniej stronie budynku.
- ❌ NIE RYSOWAĆ postaci z widoczną twarzą w scenach top-down — widzimy je wyłącznie z góry.
- ❌ Tło sprite'ów (postacie, pojazdy, ikony UI) ZAWSZE transparentne (PNG z alpha).

---

## 📋 PEŁNA MAPA PRZEBIEGU GRY

```
[Main Menu]
    ↓ "Nowa Gra"
[Scena 1: Dyspozytornia] — zarządzanie i strategia, mapa Krakowa
    ↓ Main Event: Wielki pożar w PolyServers
[Scena 2: Wóz Strażacki w drodze] — jazda top-down po OSM Krakowie
    ↓ Dotarcie na miejsce → cutscenka
[Scena 3: Płonący Budynek] — akcja wewnątrz, 5 faz, limit czasu
    ↓ Ewakuacja → cutscenka
[Scena 4: Powrót wozu do bazy] — krótka jazda powrotna
    ↓ Cutscenka: komisariat → policja przejmuje sprawę
[Scena 5: Monitoring Policyjny] — interfejs CCTV, odczyt tablic rejestracyjnych
    ↓ Identyfikacja KR4B2137 → wysłanie patrolu
[Scena 6: Dojazd Policji] — szybki dojazd radiowozu
    ↓ Dotarcie na ul. Zawiłą
[Scena 7: Pościg Autostradowy] — top-down pościg po nocnym Krakowie
    ↓ Schwytanie → cutscenka
[Scena 8: Boss Fight — Cyberkrab] — bullet-hell w zamkniętej arenie
    ↓ Pokonanie Cyberkraba → finał / napisy końcowe
```

---

## 🖥️ SCENA 0: MAIN MENU

### Co widzi gracz

Ekran startowy gry. Pełnoekranowe tło (1920×1080) przedstawiające wozy strażackie lub ratownicze w akcji (widok dynamiczny, nie top-down). Na tle nałożony półprzezroczysty czarny gradient. Na środku duże logo **"SafeServe"** i cztery przyciski: `Nowa Gra`, `Kontynuuj`, `Ustawienia`, `Wyjście`.

Po kliknięciu Nowej Gry lub Kontynuuj pojawia się **ekran ładowania** — sztuczny (fałszywy) pasek postępu z losowo zmieniającymi się "poradami dla gracza" (tips). Pasek ładowania zapełnia się nierówno, czasem "zacina", co symuluje prawdziwe ładowanie.

### Atmosfera

Profesjonalna, poważna, lekko dramatyczna. Intro do gry o służbach ratunkowych.

### Elementy Wizualne

- **Tło:** `loading_background.png` — widok strażaków/wozów, ciemny klimat nocnej akcji.
- **Czcionka:** Bold, mocna, czytelna. Biały tekst z czarnym outline.
- **Przyciski:** Prostokątne, styl windows-retro z lekkim wypukłym efektem (`StyleBoxFlat`). Hover zmienia kolor na jaśniejszy odcień.
- **Ekran ustawień:** Tło `ustawieniabg.jpg` (inne od głównego menu).

### Prompt Bazowy dla Grafik Menu

> `"2D video game main menu background, emergency services theme, fire trucks and police cars in action, dark dramatic night scene, flat vector art style, bold colors, cinematic composition, no UI elements, game art, 16:9 aspect ratio"`

---

## 🗺️ SCENA 1: DYSPOZYTORNIA

### Co widzi gracz

Centrum zarządzania kryzysowego. Gracz jest operatorem/dyspozytorem służb mundurowych w Krakowie. Widok to **interfejs komputerowy** naśladujący stary system Windows (okna, paski tytułowe, przyciski) nakładający się na **cyfrową mapę Krakowa** (OpenStreetMap, widok top-down z góry, ulice Krakowa widoczne jako linie dróg na ciemnoszarym tle).

### Przebieg Sceny (beat by beat)

1. **Start:** Na ekranie pojawia się mapa Krakowa z markerami zdarzeń (wypadki, pożary, przestępstwa) i markerami jednostek (policja, straż, karetki). Każdy marker to kolorowa ikona wektorowa.
2. **Dopasowywanie:** Gracz klika na marker zdarzenia → pojawia się okno-modal (styl Windows) z opisem zdarzenia. Następnie klika na odpowiednią jednostkę → jeśli dopasowanie jest poprawne (pożar → straż, wypadek → karetka, przestępstwo → policja), jednostka "wyjeżdża" (animacja zniknięcia), pojawia się okno sukcesu.
3. **Fałszywe dopasowanie:** Jeśli gracz wyśle złą jednostkę (np. karetkę do pożaru), pojawia się okno "BŁĄD WYSYŁKI" z komunikatem radiowym.
4. **Main Event:** Po obsłużeniu wszystkich zdarzeń bazowych, pojawia się SPECJALNY alert — **WIELKI POŻAR W SERWEROWNI POLYSERVERS**. Gra odgrywa plik `pozar_w_polyservers.wav` (komunikat radiowy). Gracz klika przycisk "Wyślij Straż Pożarną" → przejście do Sceny 2.

### Atmosfera

Stresujący back-office służb ratunkowych. Chłodna, niebiesko-szara paleta (ekran komputerowy). Klimat lat 90/2000 — okna "Windowsopodobne", trochę retro, trochę komputerowe.

### Elementy Wizualne

| Element | Opis wizualny |
|---|---|
| Mapa Krakowa | `Mapa Krakow OSM.png` — ciemnoszare ulice na ciemnym tle, widok z góry, czytelne nazwy ulic |
| UI (okna) | Styl Windows XP/98: szare paski tytułowe, przyciski z efektem wypukłości, białe tło dialogów |
| Marker pożaru | `ogien.png` — ikona płomienia, pomarańczowy/żółty, wektorowy, 32–48px |
| Marker policji | `police.svg` — niebieska tarcza/gwiazdka policyjna, wektorowa, 32px |
| Marker straży | `fire_truck.svg` — czerwona ciężarówka, top-down, wektorowa |
| Marker karetki | `ambulance.svg` — biała karetka z czerwonym krzyżem, top-down, wektorowa |
| Marker złodzieja | `zlodziej.svg` — ciemna postać z workiem, stylizowana ikona |
| Strzałki (off-screen) | `Arrow_icon_...svg` — wielkie trójkątne strzałki wskazujące zdarzenia poza ekranem |
| HUD | `HUD nowy.svg`, `pasekwindows.png`, `oknowindows.png` |

### Kluczowe Reguły Wizualne Sceny 1

- Mapa jest PŁASKIM widokiem, żadnych 3D, żadnej perspektywy.
- Markery muszą być BARDZO czytelne na ciemnym tle mapy — jaskrawe kolory, grube obrysowania.
- UI okna mają styl retrofuturystyczny: połączenie starych Windowsów (szarości, wypukłe przyciski) z nowoczesnymi vektorowymi ikonami.

### Prompt Bazowy dla Grafik Sceny 1

**Dla markerów na mapie:**
> `"2D game map marker icon, top-down view, [OPIS np. fire truck / ambulance / police badge / robber silhouette], flat clean vector art, thick outline, vibrant color, transparent background, 48x48 game icon, emergency dispatch game asset"`

**Dla tła mapy:**
> `"Top-down city map in game art style, OpenStreetMap inspired, Krakow Poland street layout, dark asphalt roads, dark green parks, grey buildings, flat 2D, clean vector lines, no shadows, game background, 1920x1080"`

---

## 🚒 SCENA 2: WÓZ STRAŻACKI W DRODZE

### Co widzi gracz

Kamera patrzy z góry (top-down, 90°) na wóz strażacki jadący ulicami **proceduralnie generowanego Krakowa** opartego na danych OSM. Miasto otacza pojazd ze wszystkich stron — widać drogi, budynki, trawniki, skrzyżowania, chodniki. Pojazdy NPC (samochody osobowe) poruszają się po jezdni w obu kierunkach.

### Przebieg Sceny (beat by beat)

1. **Start:** Wóz strażacki gracza stoi na drodze blisko punktu `(-2356, 44164)` na mapie świata gry. W HUD widoczny: pasek GPS/odległości do celu, przełącznik koguta (sygnały świetlne), przełącznik syreny (sygnał dźwiękowy), mapa minimapa w rogu, komunikator radiowy.
2. **Jazda:** Gracz jedzie po ulicach. W HUD widać strzałkę kompasową wskazującą azymut do celu pożaru. Samochody NPC blokują drogę. Gracz włącza kogut + syrenę → NPC zjeżdżają na pobocze.
3. **Cel:** Dotrzeć do punktu pożaru `(-62668, 73086)`. Gdy GPS pokazuje < 10 metrów i prędkość < 10, automatycznie odpala się cutscenka.
4. **Cutscenka:** Plik wideo `cuscean1ver4.ogv` — animowany przerywnik (zatrzymanie wozu przy budynku w ogniu). Po cutscence → Scena 3.

### Atmosfera

Dynamiczna, szybka, napięta. Dzień lub wczesny wieczór. Ulice Krakowa w stylu "realistycznej mapy gry" — neutralna, szarobrązowa paleta miasta z jasnym asfaltem i ciemną zielenią parków.

### Elementy Wizualne

| Element | Opis wizualny |
|---|---|
| Wóz Strażacki (gracz) | Czerwony (`#cc2200`), top-down sprite, grube obrysowania, widoczne żółte reflektory z przodu, szczegóły kabiny, kogut na dachu (migający niebieski/czerwony) |
| Samochody NPC | Warianty `car1.png`–`car8.png` — różnokolorowe samochody osobowe, top-down, flat vector, 40–50px szerokości |
| Asfalt drogi | Ciemnoszary `#2a2a2e`, linie pasów w kolorze żółtym lub białym |
| Chodniki | Jaśniejszy szary `#555566`, 8–12px pasy wzdłuż jezdni |
| Budynki | Bryły prostokątne `#3d3d42` z wypełnieniem i jasnym obrysem `#6a6a78`, cień po stronie wschodniej (ciemny wielokąt) |
| Trawa/Parki | `#1e3a1e`, gładkie wypełnienie, brak tekstury traw |
| HUD | `HUD background.svg`, przełączniki `Switch on.svg`/`Switch off.svg`, `Siren icon.svg` |
| Mini-mapa | Mapa OSM Krakowa w pomniejszeniu z markerem pozycji gracza i celu |

### Kluczowe Reguły Wizualne Sceny 2

- Widok jest CZYSTO top-down — brak perspektywy. Dachy aut są płaskie, budynki to prostokąty z cieniem.
- Wóz strażacki jest WYRAŹNIE inny od aut NPC — większy, czerwony, z wyróżniającymi się kogutami.
- Kogut na wozie (animacja): naprzemiennie błyska czerwony i niebieski kolor — 2-klatkowa animacja sprite.
- Samochody NPC mają różne kolory, ale wszystkie trzymają styl flat vector (brak cieniowania Phonga/3D shading).

### Prompt Bazowy dla Grafik Sceny 2

**Wóz strażacki (sprite top-down):**
> `"2D video game sprite, top-down perspective overhead view, fire truck emergency vehicle, red color #cc2200, flat clean vector art style, thick distinct black outlines, yellow headlights, roof-mounted emergency lights, bold vibrant colors, transparent background, no cast shadows, highly readable at small scale, game asset"`

**Samochód NPC (sprite top-down):**
> `"2D video game sprite, top-down perspective overhead view, generic civilian car [KOLOR np. blue / white / grey], flat vector art style, thick outlines, simple readable shape, transparent background, traffic car game asset, no cast shadows"`

**Tło mapy (miasto):**
> `"2D top-down video game map background, city street top view, dark grey asphalt roads, green parks, grey rectangular buildings with outlines, flat colors, orthographic view, procedural city OSM style, no UI, retro-modern indie game style, 1920x1080"`

---

## 🔥 SCENA 3: PŁONĄCY BUDYNEK (Główna Akcja Strażacka)

### Co widzi gracz

Wnętrze płonącego budynku — widok z góry lekko "pseudo-izometryczny" (styl retro RPG floor plan). Gracz steruje strażakiem-bohaterem. Budynek to wielopokojowa mapa z ścianami, drzwiami, korytarzami. Na mapie pojawiają się płomienie (sprite'y ognia z animacją). Lewy dolny róg ekranu zajmuje **minimapa** budynku (widok szkicowy z góry).

### Przebieg Sceny — 5 FAZ

#### FAZA 1: DRZWI
- **Co się dzieje:** Gracz podchodzi do drzwi blokujących wejście do budynku. Drzwi mają "HP" (pasek zdrowia widoczny nad nimi).
- **Sterowanie:** Spam klawisza `E` → animacja rąbania siekierą. Każde uderzenie trzęsie kamerą (efekt shake). Drzwi pękają, po wyzerowaniu HP znikają (fade out).
- **Grafika:** Drzwi w ścianie z widocznym animowanym efektem pęknięć. Siekiera (`siekira_scena4.png`) unosi się i opada (animacja 2-klatkowa). Iskry/drzazgi jako particle effect.

#### FAZA 2: POŻARY
- **Co się dzieje:** Z różnych miejsc w budynku zaczyna pojawiać się ogień. Na ekranie może być jednocześnie kilka–kilkanaście obszarów płomieni.
- **Sterowanie:** Lewy klik myszy na ogień → strażak kieruje wąż/gaśnicę → animacja gaszenia (biały efekt gaszenia + efekt pary). Ogień stopniowo słabnie i znika.
- **Grafika:** Płomień (`ogien.tscn`) — animowany sprite 3–4 klatki, nasycony pomarańcz/żółty/czerwony, efekt glow. Gdy gaszony: niebieski/biały efekt piany/pary.
- **Minimapa:** Czerwone kropki (`Dot.png`) na minimapie oznaczają aktywne pożary. Kropka gracza to niebieska/zielona kropka.

#### FAZA 3: BABCIA (NPC)
- **Co się dzieje:** Wszystkie pożary zgaszone. Gracz musi znaleźć starszą kobietę (Babcia) uwięzioną gdzieś w budynku. Minimapa pokazuje wykrzyknik (`scena4_wykrzyknik.png`) w miejscu NPC.
- **Sterowanie:** Podejść do NPC → spam `E` → animacja podnoszenia/ratowania. Babcia znika z mapy po podniesieniu.
- **Grafika Babci:** Sprite top-down starsza kobieta, prosta pixel art postać, szara/beżowa, widoczna z góry.

#### FAZA 4: CZARNA SKRZYNKA
- **Co się dzieje:** Po uratowaniu Babci, pojawia się nowy marker — czarna skrzynka lotnicza ukryta w budynku.
- **Sterowanie:** Podejść do markera → spam `E` → podniesienie skrzynki.
- **Grafika skrzynki:** Ikona 2D, czarny/pomarańczowy prostopadłościan, styl UI icon, czytelna na ciemnym tle.

#### FAZA 5: KONIEC / EWAKUACJA
- **Co się dzieje:** Czas ucieka (timer odlicza od ok. 5 minut do zera). Gracz musi dotrzeć do punktu ewakuacyjnego (zielony okrąg/strzałka na mapie).
- **Grafika:** Zielony migający obszar ewakuacyjny. Jeśli timer dojdzie do 0 — ekran czerwony, game over.

### Atmosfera

Duszna, napięta, niebezpieczna. Wnętrze budynku jest CIEMNE — oświetlone tylko przez płomienie i latarkę strażaka. Paleta ciemnych szarości/brązów przebijana intensywnym pomarańczem ognia. Dynamiczny gradient dymu.

### Elementy Wizualne

| Element | Opis wizualny |
|---|---|
| Podłogi budynku | Ciemnobrązowe kafle lub betonowa szarość `#2c2c2c`, retro RPG floor plan |
| Ściany | Grube ciemne linie `#111111`, wypełnienie `#1a1a1a` |
| Drzwi (zamknięte) | Brązowe prostokąty z metalową klamką, grubszy obrys, pasek HP nad nimi |
| Ogień (sprite) | Animowane 3–4 klatki: pomarańcz `#ff6600` → żółty `#ffcc00` → czerwony `#ff2200`, efekt glow/additive |
| Strażak (gracz) | Pixel art top-down: kurtka `#cc2200`, żółty odblask `#ffdd00`, hełm `#ff4400`, widoczny z góry |
| Babcia (NPC) | Pixel art top-down: szara sylwetka, mała postać |
| Czarna skrzynka | UI icon: czarny prostokąt z pomarańczowym paskiem, transparent bg |
| Siekiera (HUD) | `siekira_scena4.png` — 2D sprite, cartoon, cel-shaded, transparent bg |
| Minimapa | Schemat budynku (`safeservemap.png`) w lewym dolnym rogu, 200×200px |
| Dyspenser czasu | Timer w górnej części ekranu, czerwony gdy mało czasu |

### Kluczowe Reguły Wizualne Sceny 3

- Wnętrze MUSI być CIEMNE — ogień jest JEDYNYM źródłem dynamicznego jasnego światła.
- Sprite strażaka i ogień muszą być wyraźnie odróżnialne na ciemnym tle (grube jasne obrysowania).
- Minimapa to uproszczony, schematyczny widok budynku — nie fotorealistyczny plan.
- Efekt gaszenia (piana/para) kontrastuje z ogniem: zimny niebieski/biały vs ciepły pomarańcz.

### Prompt Bazowy dla Grafik Sceny 3

**Ogień (animowany sprite):**
> `"2D video game animated fire sprite, top-down view, bright orange #ff6600 and yellow #ffcc00 flames, 3-frame animation, glow effect, additive blending compatible, transparent background, retro indie game asset, vibrant saturated fire"`

**Strażak (sprite top-down):**
> `"2D pixel art sprite, top-down perspective, firefighter character in full gear, red jacket #cc2200, yellow reflective stripes #ffdd00, orange helmet #ff4400, dark pants, viewed from directly above, 48x48 pixels, transparent background, retro game character"`

**Wnętrze budynku (tło):**
> `"2D top-down video game map background, interior of a burning building, dark floor plan, thick dark walls, rooms and corridors, dark atmosphere, emergency lighting only, retro RPG dungeon style meets modern emergency, flat colors, no perspective, 1920x1080"`

**Czarna skrzynka (ikona UI):**
> `"2D game inventory icon, flight recorder black box, black rectangular device with orange stripe, cartoon vector style, cel-shaded, clean icon, transparent background, emergency equipment, simple and punchy"`

---

## 🚒 SCENA 4: POWRÓT WOZU DO BAZY

### Co widzi gracz

Identyczne środowisko jak Scena 2 (top-down miasto Kraków z OSM), ale tym razem wóz strażacki jedzie z powrotem do bazy. To krótka scena przejściowa.

### Przebieg Sceny

1. Gracz jedzie wozem strażackim z powrotem do punktu startowego `(-2356, 44164)`.
2. Po zderzeniu/dotarciu do celu: automatyczna cutscenka.
3. Cutscenka pokazuje: komisariat → scena z policjantem → policja przejmuje sprawę Cyberkraba.
4. Przejście do Sceny 5.

### Atmosfera

Przejściowa, spokojniejsza. Wieczór lub noc — miasto zaczyna ciemnieć (foreshadow nocnego pościgu).

### Reguły Wizualne

- Identyczne zasoby jak Scena 2 (wóz strażacki, miasto OSM).
- Brak nowych elementów graficznych — to scena reużytkowania assetów.
- Cutscenka to plik `.ogv` — animowany przerywnik filmowy.

---

## 🖥️ SCENA 5: MONITORING POLICYJNY I ROZPOZNANIE

### Co widzi gracz

Wchodzimy do **zupełnie innego świata wizualnego** — interfejsu komputerowego policji / CCTV. Ekran jest podzielony na dwie części:

- **LEWA STRONA:** Odtwarzacz wideo (nagranie z kamery monitoringu parkingu) z suwakiem (timeline) do scrubowania.
- **PRAWA STRONA:** Panel "bazy danych" z polem tekstowym do wpisania numeru rejestracyjnego + przycisk "SZUKAJ" + wyniki.

### Przebieg Sceny (beat by beat)

1. **Start:** Interfejs pojawia się — ciemnoniebieski, policyjny, korporacyjny (styl Motorola).
2. **Analiza wideo:** Gracz suwakiem przewija nagranie. Na nagraniu widoczne są auta na parkingu. Nad autami nakładki YOLO z etykietami tablicy rejestracyjnej. Szukany samochód ma tablicę `KR4B2137`.
3. **Wpisywanie:** Gracz wpisuje `KR4B2137` do pola tekstowego → klik SZUKAJ.
4. **Sukces:** Pojawia się mapa Krakowa z **czerwoną migającą kropką** oznaczającą lokalizację podejrzanego pojazdu. Przycisk "WYŚLIJ PATROL" staje się aktywny.
5. **Błędna tablica:** Komunikat "FAŁSZYWY ALARM" + opóźnienie "Patrol w drodze" (zanim gra sprawdzi wynik).
6. **Wyślij Patrol:** Klik → przejście do Sceny 7.

### Atmosfera

Zimna, korporacyjna, techniczna. Ciemnoniebieska paleta policyjnej bazy danych. Styl Motorola Solutions — profesjonalny, nowoczesny, ale z lekko "rządowym" charakterem.

### Elementy Wizualne

| Element | Opis wizualny |
|---|---|
| Tło UI | Ciemnoniebieski `#15053d`, prawie czarny granat |
| Akcenty / Ramki | Błękitny `#008bc2`, obwódki paneli |
| Tekst | Biały `#ffffff` na ciemnym tle |
| Przyciski | `StyleBoxFlat` — płaskie, błękitne, biały tekst, brak wypukłości (w odróżnieniu od sceny 1) |
| Odtwarzacz Wideo | Ciemna ramka, timeline / suwak pod spodem, proporcje 16:9 |
| Panel bazy danych | Panel z polem `LineEdit` (pole tekstowe) i przyciskiem SZUKAJ |
| Mapa (po sukcesie) | `Mapa krakow OSM.png` z czerwoną migającą kropką (animacja 2-klatkowa: widoczna / niewidoczna) |
| Okno Windowsowe | `oknowindows.png`, `pasekwindows.png` — elementy retro UI nad właściwym interfejsem |

### Kluczowe Reguły Wizualne Sceny 5

- CIEMNO-NIEBIESKA paleta `#15053d` to DOMINANTA tej sceny. Nie wolno dodawać ciepłych kolorów.
- Przyciski są PŁASKIE (flat), nie wypukłe — to inny rejestr niż okna Windows ze sceny 1.
- Czerwona migająca kropka na mapie musi WYRAŹNIE odróżniać się od reszty mapy — wysoki kontrast.
- Wideo w odtwarzaczu to nagranie z kamery CCTV — stylizacja na low-res, ziarnista jakość (opcjonalnie szum wideo).

### Prompt Bazowy dla Grafik Sceny 5

**UI Interface policji:**
> `"2D game UI design, police surveillance computer interface, dark navy blue background #15053d, blue accent lines #008bc2, white text, flat modern buttons, CCTV monitor panel on left, database panel on right, Motorola corporate identity style, dark tech aesthetic, no gradients except subtle"`

**Mapa z czerwoną kropką:**
> `"2D top-down city map UI element, Krakow Poland OSM style, dark road lines on dark background, single large red pulsing circle marker indicating vehicle location, police dispatch UI, flat vector, 1920x1080"`

---

## 🚔 SCENA 6: DOJAZD POLICJI (SCENA PRZEJŚCIOWA)

### Co widzi gracz

Krótka scena jazdy radiowozu — identyczne środowisko co Scena 2 i 4 (top-down miasto OSM Kraków), ale teraz gracz steruje **radiowozem policyjnym** zamiast wozem strażackim. Cel: dotrzeć na ulicę Zawiłą `(-40671, 98832)`.

### Atmosfera

**NOWA paleta — NOCA!** To pierwsze zderzenie z nocną wersją mapy. Miasto przygaszone na granatowo-czarne odcienie (tryb `night_mode` w silniku). Ulice ciemniejsze, budynki prawie czarne, jedynie latarnie rzucają małe kręgi żółtego światła.

### Elementy Wizualne

| Element | Opis wizualny |
|---|---|
| Radiowóz (gracz) | Granatowy `#1a1a8c`, biały/srebrny napis "POLICJA", kogut niebieski/czerwony na dachu, top-down sprite |
| Asfalt (noc) | `#1a1a22` — prawie czarny, ciemniejszy niż w dzień |
| Budynki (noc) | `#1a1a28` z delikatnym żółtym świeceniem okien |
| Trawa (noc) | `#0a1a0a` — prawie czarna zieleń |
| Latarnie | Małe kręgi żółto-pomarańczowego światła `#ffdd88` z efektem glow |
| Kogut radiowozu | Naprzemiennie niebieski `#0044ff` i czerwony `#ff2200` (miganie 2-klatkowe) |

### Kluczowe Reguły Wizualne Sceny 6

- To NOCNA wersja świata z Sceny 2. Te same zasoby, ale POCIEMNIAŁE o ~60%.
- Radiowóz jest WYRAŹNIE granatowy, nie czarny i nie niebieskoszary.
- Kogut radiowozu wygląda INACZEJ niż kogut wozu strażackiego — radiowóz ma kogut "policyjny" bardziej niebieski.

### Prompt Bazowy dla Grafik Sceny 6

**Radiowóz policyjny (sprite top-down):**
> `"2D video game sprite, top-down perspective overhead view, police car, dark navy blue #1a1a8c body, white POLICJA lettering, roof mounted blue and red emergency lights, flat clean vector art style, thick distinct black outlines, transparent background, night scene compatible, bold colors"`

---

## 🏎️ SCENA 7: POŚCIG AUTOSTRADOWY

### Co widzi gracz

**Nocny top-down pościg** po ulicach Krakowa. Gracz steruje radiowozem. Na mapie widoczny jest "uciekinier" — samochód Cyberkraba (podejrzany pojazd) poruszający się po z góry określonej trasie z gumową elastycznością prędkości (rubber-banding).

### Przebieg Sceny (beat by beat)

1. **Start:** Gracz w radiowozie, uciekinier widoczny dalej na drodze.
2. **Pościg:** Gracz jedzie za uciekinierem. Uciekinier przyspiesza jeśli gracz jest za blisko, zwalnia jeśli za daleko (rubber-banding).
3. **HUD:** Wyświetlana odległość do uciekiniera w metrach, strzałka wskazująca kierunek celu, wskaźnik prędkości.
4. **Ruch drogowy:** Inne auta NPC na jezdni utrudniają pościg. Gracz musi omijać.
5. **Wygrana:** Gdy odległość < 7 metrów przy małej prędkości uciekiniera → zatrzymanie → cutscenka złapania.
6. **Cutscenka:** Plik `spin.ogv` — animowany przerywnik złapania. Przejście do Sceny 8.

### Atmosfera

**Nocna, dynamiczna, neonowa.** Najciemniejsza mapa w grze. Miasto w nocy z punktowymi źródłami światła. Ścigany samochód ma charakterystyczne neonowe akcenty — foreshadow Cyberkraba.

### Elementy Wizualne

| Element | Opis wizualny |
|---|---|
| Radiowóz (gracz) | Identyczny jak Scena 6 — granatowy, kogut niebieski/czerwony |
| Uciekinier (Cyberkrab car) | Ciemny samochód z NEONOWYMI akcentami — elektryczny błękit `#00ccff` lub zielony neon `#00ff88` na obrysie/kołach. To "auta przyszłości" na tle zwykłych aut NPC. |
| Noc (mapa) | Identyczna jak Scena 6 — ciemnogranatowa, latarnie, prawie czarne ulice |
| Strzałka HUD | `Arrow_icon.svg` — kierunek do uciekiniera, duża, czytelna |
| Krotkofalówka | `Krótkofalówka dymek.png` — dymek z twarzą policjanta i komunikatem radiowym |
| HUD nocny | Niebieskawe odcienie, `Switch on.svg`, `Siren icon.svg` |

### Kluczowe Reguły Wizualne Sceny 7

- NEONOWE akcenty Cyberkraba są KLUCZOWE — ten samochód musi wyglądać jak NIE-STĄD na tle zwykłych aut NPC.
- Noc jest ciemna, ale CZYTELNA — pojazdy muszą być widoczne.
- Radiowóz gracza świeci kogutami — niebieski/czerwony blask pada na asfalt wokół niego.
- Multiplayer: istnieje wersja sieciowa (wielograczowa) tej sceny — może być kilka radiowozów naraz.

### Prompt Bazowy dla Grafik Sceny 7

**Samochód uciekiniera (Cyberkrab car):**
> `"2D video game sprite, top-down perspective, futuristic criminal getaway car, dark body with electric blue #00ccff neon glow accents on edges and wheels, cyberpunk style, flat vector art with glow effects, thick outlines, transparent background, night scene, distinctive criminal vehicle"`

---

## 🦀 SCENA 8: BOSS FIGHT — CYBERKRAB

### Co widzi gracz

**ZUPEŁNIE INNA SCENA** — arena walki w stylu bullet-hell. Gra zmienia tryb z topdown mapy-jazdy na **zręcznościową arenę walki** na ekranie 2560×1440 (lub 1920×1080). Gracz steruje policjantem, który walczy z gigantycznym bossem — **CYBERKRABEM**.

### Przebieg Sceny — 6 FAZ

#### FAZY 1–4: Eskalacja trudności

| Faza | HP% Kraba | Co się dzieje |
|---|---|---|
| Faza 1 | 100%–75% | Krab strzela podstawowymi falami pocisków, porusza się po arenie |
| Faza 2 | 75%–50% | Krab dodaje teleportację — teleportuje się w losowe miejsce areny |
| Faza 3 | 50%–25% | Krab aktywuje LASER ZAGŁADY — celuje cienką linią, po chwili uderza szeroką wiązką |
| Faza 4 | 25%–0% | Wszystkie ataki naraz, szybsze tempo, fale pocisków + laser + teleportacja |

#### FAZA 5: FAŁSZYWA ŚMIERĆ ("BUT HE REFUSED")

- **Co się dzieje:** Krab "umiera" — animacja śmierci, gracz myśli że wygrał.
- **Twist:** Ekran bieleje, napis gigantycznym fontem: `"BUT HE REFUSED"` (nawiązanie do Undertale).
- **Wizualnie:** Biały flash → czarny ekran → Krab wraca wzmocniony. To moment dramatyczny.

#### FAZA 6: "CYBERKRAB THE UNDYING" (tryb TURBO)

- **Co się dzieje:** Faza 6 jest dostępna tylko gdy `GameConfig.crab_mode == "turbo"`. Krab ma podkręcone statystyki — szybszy, silniejszy laser.
- **Atak SWEEP:** Laser obraca się w szerokim łuku 180°, wymiatając arenę.
- Wizualne komunikaty HUD: `"⚠️ PROMIEŃ ZAGŁADY! ⚠️"`.

#### FINAŁ: PRAWDZIWA WYGRANA

- **Animacja eksplozji:** Seria małych eksplozji po całym krabie.
- **Slow-motion:** `Engine.time_scale` spada — wszystko zwalnia dramatycznie.
- **Białe/czarne błyski:** Ekran pulsuje między bielą a czernią.
- **Koniec:** Napisy / credits.

### Atmosfera

**Cyberpunkowy, neonowy, klaustrofobiczny, intensywny.** Arena to piaszczyste zamknięte pole z neonowymi akcentami. Krab świeci elektrycznym błękitem i zielonym neonem. Pociski Kraba są różowe (`#ff00cc`). Policjant to jedyna "realistyczna" postać na tle cyberpunkowego chaosu.

### CYBERKRAB — Opis Bohatera

**To kluczowy asset gry — musi być na 100% spójny we wszystkich grafikach.**

- **Rodzaj:** Gigantyczny mechaniczny krab — hybryda organiczna i technologiczna.
- **Rozmiar:** ~300–400px na ekranie 1920×1080 (zajmuje ok. 20% szerokości ekranu).
- **Kolor:** Ciemny fiolet `#660099` jako baza, elektryczny błękit `#00ccff` jako świecące szczeliny/oczy/mechanizmy, zielony neon `#00ff88` jako akcenty drugorzędne.
- **Kształt:** Klasyczny krab (ciało owalne, 8 nóg, 2 szczypce), ale mechaniczny — metalowe stawy, widoczne kable, diody LED.
- **Oczy:** Świecące, duże, elektryczny błękit.
- **Animacja:** Sprite-sheet z animacjami: IDLE (kołyszący się), RUN (bieg 8 kierunków), ATTACK (laser z oczami/szczypiec), DEATH.
- **Laser:** Rysowany jako `Line2D` w silniku — cienka faza celowania (czerwona `#ff4444`), gruba faza uderzenia (pomarańczowo-biały `#ff9900` + `#ffffff` core).

### Elementy Wizualne

| Element | Opis wizualny |
|---|---|
| Arena (tło) | `tło_walki.png` — piaszczysty lub kamienisty teren, zamknięta arena, ciemna atmosfera, neonowe ogrodzenie/ściany |
| Cyberkrab (boss) | Sprite-sheet: `krabkolor.png` — mechaniczny krab, fiolet + błękit + zielony neon |
| Policjant (gracz) | Sprite-sheet 8 kierunków: `policja_gora.png` itp. — pixel art policjant w mundurze granatowym |
| Pociski Kraba | `pocisk_fala.png`, `sruba.png` — różowe/fioletowe śruby energetyczne, glow effect |
| Pociski Gracza | Niebieskie/białe kule energii, proste kółka z glow |
| Laser (Line2D) | Cienka czerwona linia celująca → gruba pomarańczowo-biała wiązka z efektem additive glow |
| HUD | Pasek HP Kraba (długi, czerwony, na górze), życia gracza (ikony serduszek lub tarcz), komunikaty faz (wielki tekst centralny) |
| Eksplozje | Particle burst: pomarańcz + żółty + biały + dym `#555555` |

### Kluczowe Reguły Wizualne Sceny 8

- **Cyberkrab jest IKONĄ gry** — jego wygląd musi być ABSOLUTNIE SPÓJNY. Fiolet + błękit + zielony neon. Mechaniczny krab. BEZ WYJĄTKÓW.
- Arena jest **zamknięta** — widać ściany/bariery ze wszystkich stron. Gracz nie może uciec.
- Laser Kraba musi być WYRÓŻNIONY spośród pocisków — to linia, nie kula.
- Pociski Kraba (śruby fale) są RÓŻOWE `#ff00cc` — kontrastują z niebieskim policjantem.
- Policjant jest MAŁY w stosunku do Kraba — Krab dominuje wizualnie na ekranie.
- Efekty eksplozji mają ADDITIVE blending — nakładają się na siebie, tworząc jasne obszary.

### Prompt Bazowy dla Grafik Sceny 8

**Cyberkrab (boss sprite):**
> `"2D video game boss character sprite, giant mechanical cyberpunk crab monster, dark purple #660099 body, electric blue #00ccff glowing joints and eyes, green neon #00ff88 accent lights, metallic shell with cables and LED panels, large threatening silhouette, flat 2D art with glow effects, thick outlines, transparent background, bullet hell game boss"`

**Arena (tło walki):**
> `"2D top-down video game arena background, enclosed combat arena, sandy/stone ground texture, neon-lit boundary walls, cyberpunk industrial aesthetic, dark atmosphere, localized neon light sources electric blue and green, flat 2D, 2560x1440 or 1920x1080, no characters"`

**Pociski kraba (śruby):**
> `"2D game projectile sprite, pink magenta #ff00cc energy bolt screw shape, glowing neon effect, additive blending compatible, small 16x16 or 24x24 pixels, transparent background, bullet hell projectile asset"`

**Policjant (gracz, sprite top-down):**
> `"2D pixel art sprite sheet, top-down perspective, police officer character, dark navy blue uniform #1a1a8c, silver badge #cccccc, facing 8 directions walk animation, 48x48 pixels per frame, transparent background, retro game character sprite"`

---

## 🔧 SZYBKIE REFERENCJE — TABELA PROMPTÓW

Użyj tej tabeli jako "menu" przy generowaniu grafik. Skopiuj odpowiedni prompt i wstaw `[OPIS]` według potrzeby.

| Asset | Gotowy Prompt Bazowy |
|---|---|
| Dowolny sprite top-down | `"2D video game sprite, top-down perspective, [OPIS], flat clean vector art style, thick distinct outlines, bold vibrant colors, transparent background, simulation game asset, no cast shadows, highly readable at small scale"` |
| Ikona UI (przedmiot) | `"2D game inventory icon of a [OPIS], cartoon vector style, cel-shaded, vibrant colors, UI element, transparent background, isolated, simple and punchy"` |
| Tło mapy top-down | `"2D top-down video game map background, [OPIS scenerii], flat colors, orthographic view, clear walkable areas, distinct non-walkable walls, retro-modern indie game style, dark atmosphere with localized bright light sources"` |
| UI Panel (policja) | `"2D game UI panel, police corporate style, dark navy #15053d background, blue #008bc2 accent borders, white text, flat modern design, Motorola corporate identity"` |
| Efekt eksplozji | `"2D game explosion effect, orange #ff6600 and yellow #ffcc00 burst, additive blending glow, transparent background, particle art style, 64x64 pixels"` |
| Cyberkrab (jakikolwiek) | `"2D [TYP] of CYBERKRAB, mechanical cyberpunk crab boss, dark purple #660099 body, electric blue #00ccff glowing eyes and joints, green neon #00ff88 accents, [DODATKOWY OPIS], transparent background, glow effects"` |

---

## ✅ CHECKLIST PRZED WYGENEROWANIEM GRAFIKI

Zanim wyślesz prompt do AI, sprawdź:

- [ ] Czy asset jest **sprite'em postaci/pojazdu**? → Koniecznie dodaj `transparent background` i `top-down perspective`.
- [ ] Czy to **tło/arena**? → Dodaj `1920x1080` lub `2560x1440` i `no characters`.
- [ ] Czy to **ikona UI**? → Dodaj `simple and punchy, isolated, transparent background`.
- [ ] Czy to **Cyberkrab lub jego atak**? → ZAWSZE użyj palety: fiolet `#660099` + błękit `#00ccff` + zielony neon `#00ff88`. NIE ZMIENIAJ.
- [ ] Czy scena jest **nocna** (Sceny 6, 7)? → Dodaj `night scene, dark atmosphere, neon lights only`.
- [ ] Czy scena jest **wnętrzem** (Scena 3)? → Dodaj `interior floor plan, dark rooms, fire lighting only`.
- [ ] Czy to UI **policji/monitoringu** (Scena 5)? → DOMINUJE `#15053d` — nie mieszaj z ciepłymi kolorami.
- [ ] Czy styl to **pixel art** czy **vector**? (Postacie → pixel art 32–48px; pojazdy → clean vector).
