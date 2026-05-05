from PIL import Image

def generate_collision_map(input_path, output_path):
    try:
        img = Image.open(input_path).convert('RGB')
    except FileNotFoundError:
        print(f"Nie znaleziono pliku: {input_path}")
        return
        
    width, height = img.size
    out_img = Image.new('L', (width, height), color=0) # Czarny jako tło (ściany)
    pixels_out = out_img.load()
    
    for y in range(height):
        for x in range(width):
            r, g, b = img.getpixel((x, y))
            
            # Jeśli piksel jest jasny (podłoga/ścieżka), malujemy na biało (255)
            if r > 180 and g > 180 and b > 180:
                pixels_out[x, y] = 255
            # Jeśli piksel to inna ścieżka (możesz tu dostosować kolory, np. żółto/szare)
            # Na ten moment wszystko co nie jest jasne traktujemy jako ścianę (zostaje czarne)
            
    out_img.save(output_path)
    print(f"Wygenerowano mapę kolizji: {output_path}")

if __name__ == "__main__":
    import os
    base_dir = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    in_path = os.path.join(base_dir, "assets", "graphics", "scena4_map.png")
    out_path = os.path.join(base_dir, "assets", "graphics", "scena4_collision.png")
    generate_collision_map(in_path, out_path)
