from PIL import Image
import os
import math

gif_path = "assets/Images/ogien_animacja.gif"
out_path = "assets/Images/ogien_animacja.png"

with Image.open(gif_path) as im:
    frames = []
    try:
        while True:
            # Copy the frame so we can store it
            im.seek(im.tell())
            frames.append(im.copy().convert("RGBA"))
            im.seek(im.tell() + 1)
    except EOFError:
        pass

if not frames:
    print("No frames found!")
    exit(1)

num_frames = len(frames)
width, height = frames[0].size

# Create a horizontal spritesheet
total_width = width * num_frames
max_height = height

spritesheet = Image.new("RGBA", (total_width, max_height))

for i, frame in enumerate(frames):
    spritesheet.paste(frame, (i * width, 0))

spritesheet.save(out_path)

print(f"Saved {num_frames} frames to {out_path} (size: {total_width}x{max_height})")
