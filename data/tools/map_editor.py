import pygame
import json
import os
import math
import tkinter as tk
from tkinter import simpledialog, messagebox, filedialog

# Ukrywamy główne okno tkintera, użyjemy go tylko do prostych dialogów textowych (popupów)
root = tk.Tk()
root.withdraw()

pygame.init()
pygame.font.init()

# Ustawienia okna
WIDTH, HEIGHT = 1280, 720
PANEL_WIDTH = 350
MAP_WIDTH = WIDTH - PANEL_WIDTH
FPS = 60

screen = pygame.display.set_mode((WIDTH, HEIGHT))
pygame.display.set_caption("Smart Map Chunk Editor")
clock = pygame.time.Clock()
font = pygame.font.SysFont("segoeui", 16)
font_bold = pygame.font.SysFont("segoeui", 18, bold=True)
font_small = pygame.font.SysFont("segoeui", 12)

# Kolory
COLOR_BG = (25, 25, 30)
COLOR_PANEL = (40, 40, 45)
COLOR_TEXT = (230, 230, 230)
COLOR_TEXT_DIM = (150, 150, 150)
COLOR_BTN = (60, 60, 70)
COLOR_BTN_HOVER = (90, 90, 100)
COLOR_SELECTED = (255, 50, 50)

# Kolory dla typów (wg tagów props)
COLORS_TYPE = {
    "water": (50, 150, 255),
    "highway": (150, 150, 150),
    "railway": (255, 150, 50),
    "building": (100, 100, 100),
    "natural": (50, 200, 50),
    "default": (200, 200, 200)
}

# Stan aplikacji
DATA_DIR = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "data", "map_chunks"))
chunks_data = {}  # filepath -> list of elements
elements = []     # Lista wszystkich elementów ze wszystkich załadowanych chunków
selected_element = None

cam_x, cam_y = 0.0, 0.0
zoom = 1.0
dragging = False
drag_start = (0, 0)
cam_start = (0, 0)

# UI Elements
buttons = []

class Button:
    def __init__(self, x, y, w, h, text, action):
        self.rect = pygame.Rect(x, y, w, h)
        self.text = text
        self.action = action
        self.hovered = False

    def draw(self, surface):
        color = COLOR_BTN_HOVER if self.hovered else COLOR_BTN
        pygame.draw.rect(surface, color, self.rect, border_radius=5)
        text_surf = font.render(self.text, True, COLOR_TEXT)
        text_rect = text_surf.get_rect(center=self.rect.center)
        surface.blit(text_surf, text_rect)

def get_element_color(props):
    if "water" in props or props.get("natural") == "water": return COLORS_TYPE["water"]
    if "highway" in props: return COLORS_TYPE["highway"]
    if "railway" in props: return COLORS_TYPE["railway"]
    if "building" in props: return COLORS_TYPE["building"]
    if "natural" in props: return COLORS_TYPE["natural"]
    return COLORS_TYPE["default"]

def load_single_file(filepath):
    global elements, chunks_data, selected_element
    try:
        with open(filepath, 'r', encoding='utf-8') as f:
            data = json.load(f)
            chunks_data[filepath] = data
            
            # Zabezpieczenie przed słownikiem
            if isinstance(data, dict):
                if 'elements' in data:
                    items = data['elements']
                elif 'features' in data:
                    items = data['features']
                else:
                    items = [data]
            else:
                items = data
                
            for obj in items:
                if isinstance(obj, dict):
                    elements.append({
                        'filepath': filepath,
                        'data': obj
                    })
        center_camera_on_elements()
        selected_element = None
    except Exception as e:
        print(f"Błąd ładowania {filepath}: {e}")
        messagebox.showerror("Błąd", f"Nie udało się wczytać pliku:\n{e}")

def action_load_file():
    filepath = filedialog.askopenfilename(
        title="Wybierz plik chunk",
        initialdir=DATA_DIR,
        filetypes=[("JSON files", "*.json"), ("All files", "*.*")]
    )
    if filepath:
        load_single_file(filepath)

def save_data():
    if not chunks_data:
        messagebox.showinfo("Zapis", "Brak wczytanych danych do zapisania.")
        return
    for filepath, data in chunks_data.items():
        try:
            with open(filepath, 'w', encoding='utf-8') as f:
                json.dump(data, f)
        except Exception as e:
            print(f"Błąd zapisu {filepath}: {e}")
            messagebox.showerror("Błąd", f"Nie udało się zapisać pliku: {filepath}")
            return
    messagebox.showinfo("Zapis", "Zapisano zmiany pomyślnie!")

def center_camera_on_elements():
    global cam_x, cam_y, zoom
    if not elements: return
    
    # Znajdź bounding box
    min_x, max_x = float('inf'), float('-inf')
    min_y, max_y = float('inf'), float('-inf')
    
    for el in elements:
        geom = el['data'].get('geometry', [])
        for pt in geom:
            if pt[0] < min_x: min_x = pt[0]
            if pt[0] > max_x: max_x = pt[0]
            if pt[1] < min_y: min_y = pt[1]
            if pt[1] > max_y: max_y = pt[1]
            
    if min_x == float('inf'): return
    
    cx = (min_x + max_x) / 2
    cy = (min_y + max_y) / 2
    cam_x = cx
    cam_y = cy
    
    w = max_x - min_x
    h = max_y - min_y
    if w > 0 and h > 0:
        zoom_x = (MAP_WIDTH - 100) / w
        zoom_y = (HEIGHT - 100) / h
        zoom = min(zoom_x, zoom_y)

def world_to_screen(wx, wy):
    sx = (wx - cam_x) * zoom + MAP_WIDTH / 2
    sy = (wy - cam_y) * zoom + HEIGHT / 2
    return int(sx), int(sy)

def screen_to_world(sx, sy):
    wx = (sx - MAP_WIDTH / 2) / zoom + cam_x
    wy = (sy - HEIGHT / 2) / zoom + cam_y
    return wx, wy

def dist_segment_point(a, b, p):
    # Dystans punktu P od odcinka AB
    px, py = p
    ax, ay = a
    bx, by = b
    
    l2 = (bx - ax)**2 + (by - ay)**2
    if l2 == 0:
        return math.hypot(px - ax, py - ay)
        
    t = max(0, min(1, ((px - ax) * (bx - ax) + (py - ay) * (by - ay)) / l2))
    proj_x = ax + t * (bx - ax)
    proj_y = ay + t * (by - ay)
    return math.hypot(px - proj_x, py - proj_y)

def get_element_at(sx, sy):
    wx, wy = screen_to_world(sx, sy)
    threshold = max(5.0 / zoom, 2.0) # threshold in world units
    
    best_dist = float('inf')
    best_el = None
    
    for el in elements:
        geom = el['data'].get('geometry', [])
        if not geom or len(geom) < 2: continue
        
        for i in range(len(geom) - 1):
            d = dist_segment_point(geom[i], geom[i+1], (wx, wy))
            if d < threshold and d < best_dist:
                best_dist = d
                best_el = el
                
    return best_el

# AKCJE PRZYCISKÓW
def action_save():
    save_data()

def action_toggle_oneway():
    if not selected_element: return
    props = selected_element['data'].setdefault('props', {})
    if props.get('oneway') == 'yes':
        props['oneway'] = 'no'
    else:
        props['oneway'] = 'yes'

def action_toggle_tracks():
    if not selected_element: return
    props = selected_element['data'].setdefault('props', {})
    tracks = props.get('tracks', '1')
    if tracks == '1':
        props['tracks'] = '2'
    else:
        props['tracks'] = '1'

def action_edit_prop():
    if not selected_element: return
    key = simpledialog.askstring("Edytuj", "Podaj klucz właściwości (np. highway, maxspeed):")
    if not key: return
    props = selected_element['data'].setdefault('props', {})
    val = simpledialog.askstring("Edytuj", f"Podaj nową wartość dla '{key}':\n(zostaw puste by usunąć)", initialvalue=props.get(key, ""))
    if val == "":
        if key in props: del props[key]
    elif val is not None:
        props[key] = val

def build_buttons():
    buttons.clear()
    bx = MAP_WIDTH + 20
    by = HEIGHT - 240
    
    buttons.append(Button(bx, by, PANEL_WIDTH - 40, 30, "+ Dodaj / Edytuj Właściwość", action_edit_prop))
    by += 40
    buttons.append(Button(bx, by, PANEL_WIDTH - 40, 30, "Przełącz jednokierunkowość (oneway)", action_toggle_oneway))
    by += 40
    buttons.append(Button(bx, by, PANEL_WIDTH - 40, 30, "Przełącz liczbę torów (tracks 1/2)", action_toggle_tracks))
    by += 60
    buttons.append(Button(bx, by, PANEL_WIDTH - 40, 40, "WCZYTAJ POJEDYNCZY PLIK", action_load_file))
    by += 50
    buttons.append(Button(bx, by, PANEL_WIDTH - 40, 40, "ZAPISZ ZMIANY", action_save))


def draw_map():
    pygame.draw.rect(screen, COLOR_BG, (0, 0, MAP_WIDTH, HEIGHT))
    
    # Rysowanie elementów
    for el in elements:
        geom = el['data'].get('geometry', [])
        if not geom or len(geom) < 2: continue
        
        pts = [world_to_screen(p[0], p[1]) for p in geom]
        props = el['data'].get('props', {})
        
        color = COLOR_SELECTED if el == selected_element else get_element_color(props)
        thickness = 3 if el == selected_element else 1
        
        pygame.draw.lines(screen, color, False, pts, thickness)
        
        # Rysuj kropki na wierzchołkach jeśli wybrany
        if el == selected_element:
            for pt in pts:
                pygame.draw.circle(screen, (255, 255, 255), pt, 3)
                
    # Rysowanie Etykiet dla większych widoków (tylko na ekranie)
    if zoom > 0.5:
        for el in elements:
            geom = el['data'].get('geometry', [])
            if not geom or len(geom) < 2: continue
            
            # Punkt środkowy segmentu
            mid_idx = len(geom) // 2
            p1 = world_to_screen(geom[mid_idx-1][0], geom[mid_idx-1][1])
            p2 = world_to_screen(geom[mid_idx][0], geom[mid_idx][1])
            cx, cy = (p1[0] + p2[0])//2, (p1[1] + p2[1])//2
            
            if 0 <= cx <= MAP_WIDTH and 0 <= cy <= HEIGHT:
                props = el['data'].get('props', {})
                label_txt = props.get('highway') or props.get('railway') or props.get('natural') or el['data'].get('type', 'obiekt')
                if el == selected_element:
                    label_txt = f"[{label_txt}]"
                lbl = font_small.render(str(label_txt), True, (200, 200, 200))
                lbl_rect = lbl.get_rect(center=(cx, cy - 10))
                pygame.draw.rect(screen, (0,0,0, 128), lbl_rect.inflate(4, 4), border_radius=2)
                screen.blit(lbl, lbl_rect)

def draw_panel():
    pygame.draw.rect(screen, COLOR_PANEL, (MAP_WIDTH, 0, PANEL_WIDTH, HEIGHT))
    pygame.draw.line(screen, (20, 20, 25), (MAP_WIDTH, 0), (MAP_WIDTH, HEIGHT), 2)
    
    x = MAP_WIDTH + 20
    y = 20
    
    title = font_bold.render("Właściwości Elementu", True, COLOR_TEXT)
    screen.blit(title, (x, y))
    y += 40
    
    if selected_element:
        data = selected_element['data']
        props = data.get('props', {})
        
        txt = font.render(f"Typ: {data.get('type', 'N/A')}", True, COLOR_TEXT_DIM)
        screen.blit(txt, (x, y))
        y += 25
        
        y += 10
        pygame.draw.line(screen, COLOR_TEXT_DIM, (x, y), (WIDTH - 20, y))
        y += 15
        
        for k, v in props.items():
            key_txt = font.render(f"{k}:", True, COLOR_TEXT_DIM)
            val_txt = font_bold.render(f"{v}", True, COLOR_TEXT)
            screen.blit(key_txt, (x, y))
            screen.blit(val_txt, (x + 100, y))
            y += 25
            
        y += 20
    else:
        txt = font.render("Wybierz element klikając na mapie.", True, COLOR_TEXT_DIM)
        screen.blit(txt, (x, y))
        
    for b in buttons:
        b.draw(screen)

def main():
    global cam_x, cam_y, zoom, dragging, drag_start, cam_start, selected_element
    
    build_buttons()
    
    running = True
    while running:
        clock.tick(FPS)
        mx, my = pygame.mouse.get_pos()
        
        # Update buttons hover
        for b in buttons:
            b.hovered = b.rect.collidepoint(mx, my)

        for event in pygame.event.get():
            if event.type == pygame.QUIT:
                running = False
                
            elif event.type == pygame.MOUSEBUTTONDOWN:
                if event.button == 1: # Left click
                    if mx < MAP_WIDTH:
                        selected_element = get_element_at(mx, my)
                    else:
                        for b in buttons:
                            if b.hovered:
                                b.action()
                elif event.button == 2 or event.button == 3: # Middle/Right click - Panning
                    if mx < MAP_WIDTH:
                        dragging = True
                        drag_start = (mx, my)
                        cam_start = (cam_x, cam_y)
                elif event.button == 4: # Scroll Up - Zoom In
                    if mx < MAP_WIDTH:
                        wx, wy = screen_to_world(mx, my)
                        zoom *= 1.2
                        cam_x = wx - (mx - MAP_WIDTH/2) / zoom
                        cam_y = wy - (my - HEIGHT/2) / zoom
                elif event.button == 5: # Scroll Down - Zoom Out
                    if mx < MAP_WIDTH:
                        wx, wy = screen_to_world(mx, my)
                        zoom /= 1.2
                        cam_x = wx - (mx - MAP_WIDTH/2) / zoom
                        cam_y = wy - (my - HEIGHT/2) / zoom
                        
            elif event.type == pygame.MOUSEBUTTONUP:
                if event.button == 2 or event.button == 3:
                    dragging = False
                    
            elif event.type == pygame.MOUSEMOTION:
                if dragging:
                    dx = mx - drag_start[0]
                    dy = my - drag_start[1]
                    cam_x = cam_start[0] - dx / zoom
                    cam_y = cam_start[1] - dy / zoom
                    
            elif event.type == pygame.KEYDOWN:
                if event.key == pygame.K_r:
                    center_camera_on_elements()

        draw_map()
        draw_panel()
        pygame.display.flip()

    pygame.quit()

if __name__ == "__main__":
    main()
