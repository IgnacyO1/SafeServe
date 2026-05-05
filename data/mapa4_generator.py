from PIL import Image
import json

def process_map_image(image_path, output_json_path, tile_size=64):
    img = Image.open(image_path)
    img = img.convert('RGB')
    width, height = img.size
    
    map_data = {
        "walls": [],
        "path": []
    }
    
    # Przechodzimy po wszystkich pikselach
    for y in range(height):
        for x in range(width):
            r, g, b = img.getpixel((x, y))
            
            # Przykładowa detekcja koloru niebieskiego (ściana)
            if b > 150 and r < 100 and g < 100:
                map_data["walls"].append({"x": x * tile_size, "y": y * tile_size})
                
            # Przykładowa detekcja koloru białego (ścieżka)
            elif r > 200 and g > 200 and b > 200:
                map_data["path"].append({"x": x * tile_size, "y": y * tile_size})
                
    with open(output_json_path, 'w') as f:
        json.dump(map_data, f, indent=4)
        
    print(f"Mapa przetworzona pomyślnie! Zapisano do {output_json_path}")

if __name__ == "__main__":
    # Wpisz ścieżkę do swojego obrazka
    process_map_image("scena4_map.png", "scena_4_layout.json")
