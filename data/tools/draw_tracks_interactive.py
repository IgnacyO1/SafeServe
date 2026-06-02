import os
import sys
import math
import pygame
from PIL import Image, ImageDraw

def distance(p1, p2):
    return math.sqrt((p1[0] - p2[0])**2 + (p1[1] - p2[1])**2)

def main():
    # Base paths
    script_dir = os.path.dirname(os.path.abspath(__file__))
    project_root = os.path.dirname(os.path.dirname(script_dir))
    img_path = os.path.join(project_root, "assets", "graphics", "Scena8", "tło_walki.png")
    
    print("\n==================================================")
    print("      INTERACTIVE TRAM TRACK EDITOR (PYGAME)      ")
    print("==================================================")
    print(f"Loading background from: {img_path}")
    
    if not os.path.exists(img_path):
        print(f"Error: Image not found at {img_path}")
        return
        
    # Initialize Pygame
    pygame.init()
    
    # Load original image to get dimensions
    try:
        pil_img = Image.open(img_path)
        img_w, img_h = pil_img.size
    except Exception as e:
        print(f"Error reading image dimensions: {e}")
        return
        
    # Set display window size (comfortable 1600x900)
    sw, sh = 1600, 900
    screen = pygame.display.set_mode((sw, sh))
    pygame.display.set_caption("SafeServe: Tram Track Painter (RMB/MMB Drag or Arrows to Pan, Scroll to Zoom)")
    
    # Load image for Pygame display
    original_bg = pygame.image.load(img_path)
    
    # Camera settings
    zoom = 0.6  # Initial zoom to fit the image nicely
    cam_x = img_w / 2.0  # Camera look-at point in image space
    cam_y = img_h / 2.0
    
    print(f"Original image size: {img_w}x{img_h}")
    print(f"Viewport size: {sw}x{sh}")
    
    # State variables
    points = [] # List of tuples: (img_x, img_y)
    dragging = False
    drag_start = (0, 0)
    cam_start = (0, 0)
    
    print("\nInstructions:")
    print("- LEFT CLICK: Place track points. Every 2 points draw a track line.")
    print("- RIGHT CLICK / MIDDLE CLICK & DRAG: Pan the camera (move around).")
    print("- ARROW KEYS: Pan the camera.")
    print("- MOUSE SCROLL WHEEL: Zoom in/out to current mouse pointer.")
    print("- 'U' or BACKSPACE: Undo last placed point.")
    print("- 'C': Clear all points.")
    print("- 'S' or ENTER: Burn tracks into image, print coordinates, and save.")
    print("- ESCAPE: Quit without saving.")
    
    clock = pygame.time.Clock()
    running = True
    
    # Cache scaled background surface
    last_zoom = -1.0
    scaled_bg = None
    
    while running:
        # Re-scale background surface if zoom changes
        if zoom != last_zoom:
            scaled_bg = pygame.transform.scale(original_bg, (int(img_w * zoom), int(img_h * zoom)))
            last_zoom = zoom
            
        # Event handling
        for event in pygame.event.get():
            if event.type == pygame.QUIT:
                running = False
                
            elif event.type == pygame.MOUSEBUTTONDOWN:
                if event.button == 1: # Left click (place point)
                    mx, my = event.pos
                    # Map screen coordinate back to image space
                    ix = int(cam_x + (mx - sw/2) / zoom)
                    iy = int(cam_y + (my - sh/2) / zoom)
                    # Clamp to image boundaries
                    ix = max(0, min(ix, img_w - 1))
                    iy = max(0, min(iy, img_h - 1))
                    
                    points.append((ix, iy))
                    print(f"Placed Point {len(points)}: Image Coordinate ({ix}, {iy})")
                    
                elif event.button in [2, 3]: # Middle or Right click (start drag)
                    dragging = True
                    drag_start = event.pos
                    cam_start = (cam_x, cam_y)
                    
                elif event.button in [4, 5]: # Scroll Wheel (Zoom)
                    mx, my = event.pos
                    # Find image coordinate under cursor before zoom change
                    ix = cam_x + (mx - sw/2) / zoom
                    iy = cam_y + (my - sh/2) / zoom
                    
                    # Apply zoom factor
                    if event.button == 4: # Scroll Up (Zoom In)
                        zoom = min(5.0, zoom * 1.15)
                    else: # Scroll Down (Zoom Out)
                        zoom = max(0.1, zoom / 1.15)
                        
                    # Adjust camera coordinates so mouse cursor points to same image location
                    cam_x = ix - (mx - sw/2) / zoom
                    cam_y = iy - (my - sh/2) / zoom
                    
            elif event.type == pygame.MOUSEBUTTONUP:
                if event.button in [2, 3]: # Middle or Right click (end drag)
                    dragging = False
                    
            elif event.type == pygame.MOUSEMOTION:
                if dragging:
                    mx, my = event.pos
                    dx = mx - drag_start[0]
                    dy = my - drag_start[1]
                    # Pan camera relative to zoom
                    cam_x = cam_start[0] - dx / zoom
                    cam_y = cam_start[1] - dy / zoom
                    
            elif event.type == pygame.KEYDOWN:
                if event.key == pygame.K_ESCAPE:
                    print("Exited without saving.")
                    running = False
                    
                elif event.key in [pygame.K_u, pygame.K_BACKSPACE]:
                    if points:
                        removed = points.pop()
                        print(f"Removed last point: ({removed[0]}, {removed[1]})")
                        
                elif event.key == pygame.K_c:
                    points.clear()
                    print("Cleared all points.")
                    
                elif event.key in [pygame.K_s, pygame.K_RETURN]:
                    if len(points) < 2:
                        print("Error: Need at least 2 points (1 track line) to save.")
                    else:
                        print("\nSaving tracks...")
                        # Draw the tracks on the PIL image and save
                        rgba_img = pil_img.convert("RGBA")
                        overlay = Image.new("RGBA", rgba_img.size, (0, 0, 0, 0))
                        draw = ImageDraw.Draw(overlay)
                        
                        track_idx = 1
                        print("\n=== GODOT VECTOR2D COORDINATES ===")
                        for i in range(0, len(points) - 1, 2):
                            p1 = points[i]
                            p2 = points[i+1]
                            
                            # Print Godot Vector2 coordinates
                            print(f"Track {track_idx}: [Vector2{p1}, Vector2{p2}]")
                            track_idx += 1
                            
                            # Vector math for track direction and perpendiculars
                            dx = p2[0] - p1[0]
                            dy = p2[1] - p1[1]
                            dist = math.sqrt(dx*dx + dy*dy)
                            
                            if dist == 0:
                                continue
                                
                            ux = dx / dist
                            uy = dy / dist
                            px = -uy
                            py = ux
                            
                            # 1. Draw ballast path with very low opacity (RGBA)
                            draw.line([p1, p2], fill=(45, 40, 35, 15), width=50) # alpha = 15
                            
                            # 2. Draw sleepers with low opacity
                            sleeper_spacing = 50
                            num_sleepers = int(dist / sleeper_spacing)
                            for s in range(num_sleepers + 1):
                                t = s * sleeper_spacing
                                cx = p1[0] + ux * t
                                cy = p1[1] + uy * t
                                
                                sx1 = cx - px * 21
                                sy1 = cy - py * 21
                                sx2 = cx + px * 21
                                sy2 = cy + py * 21
                                
                                draw.line([(sx1, sy1), (sx2, sy2)], fill=(75, 55, 40, 25), width=8) # alpha = 25
                                draw.line([(sx1 - px * 2, sy1 - py * 2), (sx1 + px * 2, sy1 + py * 2)], fill=(25, 15, 10, 25), width=8)
                                draw.line([(sx2 - px * 2, sy2 - py * 2), (sx2 + px * 2, sy2 + py * 2)], fill=(25, 15, 10, 25), width=8)
                                
                            # 3. Draw rails (15 pixels offset on each side) with low opacity
                            rail1_p1 = (p1[0] - px * 15, p1[1] - py * 15)
                            rail1_p2 = (p2[0] - px * 15, p2[1] - py * 15)
                            
                            rail2_p1 = (p1[0] + px * 15, p1[1] + py * 15)
                            rail2_p2 = (p2[0] + px * 15, p2[1] + py * 15)
                            
                            draw.line([rail1_p1, rail1_p2], fill=(40, 40, 45, 20), width=4) # Shadow
                            draw.line([rail1_p1, rail1_p2], fill=(130, 130, 135, 35), width=2) # Rail
                            draw.line([rail1_p1, rail1_p2], fill=(220, 220, 225, 40), width=1) # Highlight
                            
                            draw.line([rail2_p1, rail2_p2], fill=(40, 40, 45, 20), width=4) # Shadow
                            draw.line([rail2_p1, rail2_p2], fill=(130, 130, 135, 35), width=2) # Rail
                            draw.line([rail2_p1, rail2_p2], fill=(220, 220, 225, 40), width=1) # Highlight
                            
                        # Composite overlay onto original image
                        final_img = Image.alpha_composite(rgba_img, overlay)
                        final_img = final_img.convert("RGB")
                        
                        try:
                            final_img.save(img_path)
                            print(f"\nSuccessfully drew tracks and saved image back to: {img_path}")
                        except Exception as e:
                            print(f"Error saving image: {e}")
                        
                        running = False
                        
        # Continuous pan with arrow keys
        keys = pygame.key.get_pressed()
        pan_speed = 15.0 / zoom
        if keys[pygame.K_LEFT]: cam_x -= pan_speed
        if keys[pygame.K_RIGHT]: cam_x += pan_speed
        if keys[pygame.K_UP]: cam_y -= pan_speed
        if keys[pygame.K_DOWN]: cam_y += pan_speed
        
        # Keep camera inside reasonable bounds
        cam_x = max(-500, min(cam_x, img_w + 500))
        cam_y = max(-500, min(cam_y, img_h + 500))
        
        # Render background
        screen.fill((20, 20, 20))
        
        # Compute screen space offset for the scaled background image
        tx = int(sw/2 - cam_x * zoom)
        ty = int(sh/2 - cam_y * zoom)
        screen.blit(scaled_bg, (tx, ty))
        
        # Draw lines and points (mapped to screen space)
        def to_screen(ix, iy):
            sx = int(sw/2 + (ix - cam_x) * zoom)
            sy = int(sh/2 + (iy - cam_y) * zoom)
            return sx, sy
            
        scaled_points = [to_screen(p[0], p[1]) for p in points]
        
        # Draw tracks lines
        for i in range(0, len(scaled_points) - 1, 2):
            pygame.draw.line(screen, (255, 100, 0), scaled_points[i], scaled_points[i+1], 4)
            pygame.draw.circle(screen, (0, 255, 0), scaled_points[i], 6)
            pygame.draw.circle(screen, (0, 255, 0), scaled_points[i+1], 6)
            
        # Draw preview line to mouse
        if len(scaled_points) % 2 != 0:
            p_start = scaled_points[-1]
            m_pos = pygame.mouse.get_pos()
            pygame.draw.circle(screen, (255, 255, 0), p_start, 6)
            pygame.draw.line(screen, (255, 255, 0), p_start, m_pos, 2)
            
        # Draw points indicators
        for idx, p in enumerate(scaled_points):
            pygame.draw.circle(screen, (255, 0, 0), p, 4)
            font = pygame.font.SysFont(None, 24)
            img_p = points[idx]
            label = font.render(f"P{idx+1} ({img_p[0]},{img_p[1]})", True, (255, 255, 255))
            screen.blit(label, (p[0] + 10, p[1] - 10))
            
        # Render viewport center cursor (crosshair helper)
        pygame.draw.line(screen, (100, 100, 100), (sw/2 - 10, sh/2), (sw/2 + 10, sh/2), 1)
        pygame.draw.line(screen, (100, 100, 100), (sw/2, sh/2 - 10), (sw/2, sh/2 + 10), 1)
        
        # HUD instructions text
        hud_font = pygame.font.SysFont(None, 22)
        instructions = [
            f"Zoom: {zoom*100:.0f}%  |  Camera: ({int(cam_x)}, {int(cam_y)})",
            "RMB/MMB Drag or Arrows: Pan",
            "Scroll Wheel: Zoom in/out to cursor",
            "Enter/S: Save & Exit  |  Backspace: Undo  |  Escape: Quit"
        ]
        for line_idx, text in enumerate(instructions):
            txt_surf = hud_font.render(text, True, (0, 255, 255))
            screen.blit(txt_surf, (15, 15 + line_idx * 20))
            
        pygame.display.flip()
        clock.tick(60)
        
    pygame.quit()
    sys.exit()

if __name__ == "__main__":
    main()
