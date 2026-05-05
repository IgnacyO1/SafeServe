import os
import sys

dir_path = r"c:\Users\ignac\Desktop\SafeServe\safeserve\assets\graphics"

try:
    from PIL import Image
except ImportError:
    import subprocess
    subprocess.check_call([sys.executable, "-m", "pip", "install", "Pillow"])
    from PIL import Image

bg_path = os.path.join(dir_path, "scena5_tlo_new.png")
if os.path.exists(bg_path):
    with Image.open(bg_path) as img:
        if img.size != (1920, 1080):
            img = img.resize((1920, 1080), Image.LANCZOS)
            img.save(os.path.join(dir_path, "scena5_tlo.png"))
            print(f"Resized scena5_tlo_new.png and saved to scena5_tlo.png")
        else:
            img.save(os.path.join(dir_path, "scena5_tlo.png"))
            print("scena5_tlo_new.png is already 1920x1080, saved to scena5_tlo.png")
