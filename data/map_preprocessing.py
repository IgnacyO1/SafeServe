import json
import math
import os

# --- KONFIGURACJA ---
INPUT_FILE = "krakow-SW.geojson"  # Twoja nazwa pliku
OUTPUT_DIR = "map_chunks"           # Folder wyjściowy (wrzuć go potem do Godota)
CHUNK_SIZE_METERS = 200.0           # Rozmiar chunka w metrach
SCALE = 1.0                         # 1 metr w świecie = 1 jednostka w Godocie

def latlon_to_meters(lat, lon, ref_lat, ref_lon):
    # Prosta aproksymacja Mercatora dla małych obszarów
    x = (lon - ref_lon) * (math.cos(math.radians(ref_lat)) * 111320.0)
    y = (lat - ref_lat) * 110540.0
    return x * SCALE, -y * SCALE # Odwracamy Y, bo w Godocie dół to plus

def process_map():
    if not os.path.exists(OUTPUT_DIR):
        os.makedirs(OUTPUT_DIR)

    with open(INPUT_FILE, 'r', encoding='utf-8') as f:
        data = json.load(f)

    # 1. Znajdź punkt odniesienia (lewy dolny róg lub środek)
    # Dla uproszczenia bierzemy pierwszy punkt z brzegu jako (0,0)
    first_feat = data['features'][0]['geometry']['coordinates']
    while isinstance(first_feat[0], list): first_feat = first_feat[0]
    ref_lon, ref_lat = first_feat

    chunks = {} # Słownik na dane: {(cx, cy): [features]}

    for feature in data['features']:
        geom = feature['geometry']
        ftype = geom['type']
        coords = geom['coordinates']

        # Wyciągamy wszystkie punkty obiektu, by sprawdzić zasięg (Bounding Box)
        all_pts = []
        if ftype == "Point": all_pts = [coords]
        elif ftype == "LineString": all_pts = coords
        elif ftype == "Polygon": all_pts = coords[0]
        elif ftype == "MultiPolygon": all_pts = coords[0][0]

        if not all_pts: continue

        # Przeliczamy punkty na metry i sprawdzamy, do których chunków obiekt należy
        m_pts = [latlon_to_meters(p[1], p[0], ref_lat, ref_lon) for p in all_pts]
        
        # Znajdujemy granice obiektu w jednostkach chunków
        c_xs = [int(p[0] // CHUNK_SIZE_METERS) for p in m_pts]
        c_ys = [int(p[1] // CHUNK_SIZE_METERS) for p in m_pts]
        
        for cx in range(min(c_xs), max(c_xs) + 1):
            for cy in range(min(c_ys), max(c_ys) + 1):
                chunk_id = (cx, cy)
                if chunk_id not in chunks: chunks[chunk_id] = []
                
                # Dodajemy obiekt do chunka (z przeliczonymi współrzędnymi)
                new_feature = {
                    "type": feature.get("properties", {}).get("building") or feature.get("properties", {}).get("highway") or "object",
                    "geometry": m_pts,
                    "props": feature.get("properties", {})
                }
                chunks[chunk_id].append(new_feature)

    # 2. Zapisz pliki
    for (cx, cy), features in chunks.items():
        filename = f"chunk_{cx}_{cy}.json"
        with open(os.path.join(OUTPUT_DIR, filename), 'w') as f:
            json.dump(features, f)
    
    # 3. Zapisz metadane (żeby Godot wiedział gdzie jest (0,0) i jaka skala)
    meta = {"ref_lat": ref_lat, "ref_lon": ref_lon, "chunk_size": CHUNK_SIZE_METERS}
    with open(os.path.join(OUTPUT_DIR, "metadata.json"), 'w') as f:
        json.dump(meta, f)

    print(f"Gotowe! Wygenerowano {len(chunks)} chunków.")

if __name__ == "__main__":
    process_map()