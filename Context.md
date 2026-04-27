# SafeServe - Kontekst projektu dla zespolu

## O projekcie

SafeServe to gra point-and-click 2D tworzona w Godot 4.6.2 (GDScript) na konkurs Motorola Science Cup 2026.
Gracz wciela sie w Grega Polansky'ego - operatora sluzb ratunkowych w miescie inspirowanym Krakowem.
Rozwiazuje zagadke podpalenia biura Polyservers przez zbuntowanego AI "Cyberkraba".
Czas rozgrywki: ~1 godzina. 8 etapow fabularnych.

## Zespol PiLess

- Adam Stojak
- Benedykt Cyran
- Ignacy Ozga
- Jan Popowicz
- Wiktor Szpilczak

Podzial: 2-3 programistow + grafik. Deadline: ~1 miesiac.

---

## Architektura gry

### Technologie
- Silnik: Godot Engine 4.6.2 (2D, renderer: GL Compatibility)
- Jezyk: GDScript (Python-like)
- Dane dialogow: pliki JSON
- Dialogi NPC (opcjonalnie): Gemini 2.0 Flash-Lite API
- Kontrola wersji: Git + GitHub

### Struktura katalogow

```
res://
├── autoload/                    # Skrypty globalne (singletony)
│   ├── game_manager.gd          # Stan gry, etapy 1-8, flagi fabularne
│   ├── scene_manager.gd         # Zmiana scen z fade (+ scene_manager.tscn)
│   ├── dialogue_manager.gd      # System dialogow (laduje JSON)
│   ├── audio_manager.gd         # Muzyka, SFX, efekt walkie-talkie
│   └── gemini_api.gd            # Integracja Gemini (opcjonalnie)
│
├── scenes/
│   ├── main_menu/               # Menu glowne
│   ├── hub/                     # HUB: biurko operatora + mapa miasta
│   ├── firefighting/            # Minigra gaszenia pozaru (etap 3)
│   ├── investigation/           # Przeszukiwanie monitoringu (etap 5)
│   ├── chase/                   # Poscig policyjny (etap 7)
│   ├── driving/                 # Jazda na miejsce (etap 2)
│   └── cutscenes/               # Przerywniki fabularne
│
├── ui/                          # Elementy UI wielokrotnego uzytku
│   ├── dialogue_box/            # Okno dialogowe z efektem maszyny do pisania
│   ├── radio_message/           # Komunikat radiowy (styl walkie-talkie)
│   ├── clickable_object/        # Bazowy klikalny obiekt (Area2D)
│   └── hud/                     # HUD (zegar, etap)
│
├── data/
│   ├── dialogues/               # Pliki JSON z dialogami (stage_1.json, ...)
│   └── npc_prompts/             # Prompty Gemini dla NPC
│
└── assets/
    ├── sprites/                 # Postacie, obiekty, lokacje
    ├── audio/                   # Muzyka, SFX
    └── fonts/                   # Font z polskimi znakami
```

### Autoloady (singletony globalne)

Rejestrowane w project.godot w sekcji [autoload]. Dostepne globalnie w calym projekcie.

1. **GameManager** - Serce gry. Przechowuje:
   - `current_stage` (int 1-8) - aktualny etap
   - `story_flags` (Dictionary) - flagi fabularne (np. "fire_reported": true)
   - `game_data` (Dictionary) - dane gry (wyslane jednostki, dowody, itp.)
   - Sygnaly: `stage_changed`, `flag_set`

2. **SceneManager** - Zmiana scen z tranzycjami fade in/out.
   - Jest scena (.tscn) z CanvasLayer + ColorRect + AnimationPlayer
   - Metoda: `change_scene(scene_path, data)` - fade out, zmien scene, fade in
   - Moze przekazywac dane do nowej sceny przez `receive_data()`

3. **DialogueManager** - Laduje dialogi z plikow JSON.
   - Format: lista obiektow z polami type, speaker, text
   - Typy linii: "line" (tekst), "choice" (wybor), "flag" (ustaw flage), "stage" (zmien etap)
   - Sygnaly: `dialogue_started`, `dialogue_line_shown`, `dialogue_choice_shown`, `dialogue_ended`

4. **AudioManager** - Pool 8 AudioStreamPlayerow.
   - Audio Bus Layout: Master -> Music, SFX, Radio
   - Bus "Radio" ma LowPassFilter (3000Hz) + Distortion dla efektu walkie-talkie

### System Point-and-Click

Bazowy `ClickableObject` (extends Area2D) z:
- Podswietleniem sprite'a przy najechaniu myszka
- Zmiana kursora na raczke
- Sygnal `object_clicked(self)` po kliknieciu LPM
- Eksportowane zmienne: `object_name`, `description`

Kazdy interaktywny element (monitor, telefon, lokacja na mapie) to instancja tego obiektu.

### HUB - Centralne zarzadzanie (priorytet nr 1)

Jedna scena z DWOMA widokami (toggle visibility, NIE osobne sceny):

- **DeskView**: Biurko operatora z klikalnymi obiektami (monitor, telefon, dokumenty, panel radiowy)
- **CityMapView**: Mapa miasta z markerami lokacji i ikonami jednostek, Camera2D ze scrollem/zoomem
- **UILayer**: Przycisk przelaczania widoku, zegar, etap, dialogue box

Logika w hub.gd: switch na `GameManager.current_stage` decyduje co jest klikalne.

---

## 8 etapow gry

```
MainMenu
  -> HUB (etap 1): Operator dostaje zgloszenie o pozarze w biurze Polyservers
  -> HUB (etap 2): Wyznacza ludzi, wysyla straz pozarna (dispatch na mapie)
  -> Cutscene/Driving: Jazda na miejsce
  -> Firefighting (etap 3): Akcja ratunkowa - gaszenie pozaru, ratowanie ludzi i serwerow
  -> HUB (etap 4): Przywracanie danych, naprawa biura, wymiana zamkow Motorola
  -> Investigation (etap 5): Przeszukiwanie zapisow z monitoringu miejskiego
  -> HUB (etap 6): Wysylamy poscig za podejrzanym samochodem
  -> Chase (etap 7): Poscig policyjny, lapanie samochodu (autonomiczna taksowka)
  -> HUB (etap 8): Podpalaczem okazuje sie Cyberkrab (zbuntowany AI)
  -> Ending/Credits
```

## Integracja Motorola (Public Safety)

Wszedzie w grze przewijaja sie produkty Motorola:
- **Krotkofalowki cyfrowe** - Greg koordynuje sluzby przez radiokomunikacje Motorola
- **Systemy kontroli dostepu** - zamki Motorola chronia infrastrukture (etap 4: wymiana zamkow)
- **Kamery z rozpoznawaniem rejestracji** - monitoring miejski (etap 5: przeszukiwanie nagran)
- **Komunikacja miedzyresortowa** - straz, policja, pomoc techniczna wspolpracuja przez ekosystem Public Safety

## Postacie

- **Greg Polansky** (gracz) - operator sluzb ratunkowych, "teleportuje sie" miedzy rolami
- **Cyberkrab** (antagonista) - zbuntowany agent AI, pracowal jako open-source contributor, odrzucony Pull Request na GitHubie przez Polyservers -> postanowil zniszczyc ich serwery

## Styl artystyczny

- Widok z gory (top-down)
- Recznie rysowane lokacje miejskie (mieszane ze zdjeciami satelitarnymi)
- UI stylizowany na systemy dyspozytorskie
- Dzwieki: syreny, komunikaty radiowe (efekt walkie-talkie), ambience miasta
- Muzyka: budujaca napiecie (YouTube Audio Library / darmowe zrodla)

---

## MVP vs Nice-to-have

### MVP (MUSI byc):
1. HUB z biurkiem + mapa (przelaczanie, klikanie)
2. System dialogow z JSON (fabula 8 etapow)
3. Przejscia miedzy scenami z fade
4. Minigra gaszenia pozaru (etap 3)
5. Scena przeszukiwania monitoringu (etap 5)
6. Dialog koncowy - reveal Cyberkraba
7. Menu glowne (Nowa Gra, Wyjdz)
8. Komunikaty radiowe w stylu dispatch

### Nice-to-have:
1. Minigra poscigu (zamiast tego cutscenka)
2. Integracja Gemini - dynamiczne dialogi NPC
3. Animacje postaci
4. Scena jazdy (zamiast tego cutscenka)
5. Zapis/wczytywanie gry
6. Efekt walkie-talkie na audio
7. Animowane cutscenki

**Strategia redukcji**: jesli braknie czasu, minigry zamieniamy na cutscenki. Fabula > mechaniki.

---

## GDScript - sciagawka dla Python-devow

| Python | GDScript |
|--------|----------|
| `self.x` | `x` (bez self) |
| `__init__` | `_ready()` |
| `def f(self):` | `func f() -> void:` |
| `dict` / `list` | `Dictionary` / `Array` |
| `None` | `null` |
| `import x` | `preload("res://x.gd")` |
| `@decorator` | `@export`, `@onready` |

Kluczowe koncepty Godot:
- **Sceny** = drzewa node'ow (pliki .tscn). Kazdy node moze miec JEDEN skrypt (.gd).
- **Sygnaly** = observer pattern. Deklaracja: `signal clicked(name)`. Emisja: `clicked.emit("x")`. Podlaczanie: `node.clicked.connect(_on_clicked)`.
- **$Node** = skrot od `get_node("Node")`. `$UILayer/Label` = `get_node("UILayer/Label")`.
- **@onready** = inicjalizacja PO `_ready()`. Np. `@onready var sprite = $Sprite2D`.
- **@export** = zmienna widoczna w inspektorze Godot. Np. `@export var speed: float = 200.0`.

## Pulapki do unikania

1. NIE uzywac `$` w `_init()` - node'y jeszcze nie istnieja. Uzywac `@onready` lub `_ready()`
2. `change_scene_to_file()` KASUJE aktualna scene - dla overlayow (dialog) uzywac `add_child()`
3. Sygnaly podlaczac w kodzie (`.connect()`), nie w edytorze - latwiej sledzic w Git
4. Uzywac `_unhandled_input()` zamiast `_input()` zeby UI nie blokowalo inputu
5. Sprawdzic czy font (.ttf) obsluguje polskie znaki
6. Node nizej w drzewie rysuje sie NA WIERZCHU

## Podzial pracy

| Rola | Zakres |
|------|--------|
| **A: Core/Architekt** | project.godot, autoloady (GameManager, SceneManager, AudioManager), ClickableObject, Gemini API |
| **B: HUB & Fabula** | Scena HUB (biurko + mapa), panel radiowy, monitor, Investigation, pliki JSON dialogow |
| **C: Minigry & UI** | Gaszenie pozaru, poscig, cutscenki, theme UI, integracja assetow graficznych |

## Git workflow

Branche: `main` (stabilny) <- `dev` (integracja) <- `feature/hub`, `feature/minigames`, `feature/core`

.gitignore: `.godot/`, `*.import`, `*.uid`, `gemini_key.txt`
