import os
from PIL import Image
import random

base_dir = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
in_path = os.path.join(base_dir, "assets", "graphics", "scena4_collision.png")

try:
    img = Image.open(in_path)
    width, height = img.size
    
    valid_positions = []
    # szukamy bialych pixeli (sciezki)
    for y in range(0, height, 10):
        for x in range(0, width, 10):
            pixel = img.getpixel((x, y))
            if pixel > 200: # zakladamy grayscale
                valid_positions.append((x, y))
                
    random.shuffle(valid_positions)
    print("Znalezione pozycje na ścieżce:")
    for i in range(min(5, len(valid_positions))):
        print(f"Vector2{valid_positions[i]},")
        
    print(f"Szerokosc: {width}, Wysokosc: {height}")
except Exception as e:
    print(f"Blad: {e}")