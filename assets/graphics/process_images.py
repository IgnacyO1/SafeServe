import os
import sys

# Directory path
dir_path = r"c:\Users\ignac\Desktop\SafeServe\safeserve\assets\graphics"

# Rename files
files_to_rename = {
    "Gemini_Generated_Image_nsmj4dnsmj4dnsmj.png": "scena5_wrong_1.png",
    "Gemini_Generated_Image_u4xf6mu4xf6mu4xf.png": "scena5_wrong_2.png"
}

for old_name, new_name in files_to_rename.items():
    old_path = os.path.join(dir_path, old_name)
    new_path = os.path.join(dir_path, new_name)
    if os.path.exists(old_path):
        if os.path.exists(new_path):
            os.remove(new_path)
        os.rename(old_path, new_path)
        print(f"Renamed {old_name} to {new_name}")

# Resize background
try:
    from PIL import Image
except ImportError:
    import subprocess
    subprocess.check_call([sys.executable, "-m", "pip", "install", "Pillow"])
    from PIL import Image

bg_path = os.path.join(dir_path, "scena5_tlo.png")
if os.path.exists(bg_path):
    with Image.open(bg_path) as img:
        if img.size != (1920, 1080):
            img = img.resize((1920, 1080), Image.LANCZOS)
            img.save(bg_path)
            print(f"Resized scena5_tlo.png to 1920x1080")
        else:
            print("scena5_tlo.png is already 1920x1080")
