import os
import math
import subprocess
import shutil
from PIL import Image, ImageDraw, ImageFilter

def get_ffmpeg_path():
    candidate = os.path.join(os.path.dirname(__file__), 'node_modules', '@ffmpeg-installer', 'win32-x64', 'ffmpeg.exe')
    if os.path.exists(candidate):
        return candidate
    return 'ffmpeg'

def generate_ink_reveal_mask(output_mp4, width=1280, height=720, fps=30, duration_sec=2.0):
    total_frames = int(fps * duration_sec)
    temp_dir = os.path.join(os.path.dirname(__file__), 'temp_ink_frames')
    os.makedirs(temp_dir, exist_ok=True)
    
    max_radius = math.hypot(width / 2, height / 2) * 1.2
    
    for f in range(total_frames):
        progress = f / float(total_frames - 1)
        # Non-linear organic acceleration
        t = progress ** 1.3
        current_radius = max_radius * t
        
        img = Image.new('L', (width, height), 0)
        draw = ImageDraw.Draw(img)
        
        cx, cy = width / 2.0, height / 2.0
        
        # Draw organic polygon
        num_points = 180
        points = []
        for i in range(num_points):
            angle = (2.0 * math.pi * i) / num_points
            noise = (
                0.18 * math.sin(4 * angle) +
                0.12 * math.cos(7 * angle + 0.5) +
                0.08 * math.sin(11 * angle + 1.2) +
                0.05 * math.cos(17 * angle + 2.1)
            )
            r = current_radius * (1.0 + noise)
            px = cx + r * math.cos(angle)
            py = cy + r * math.sin(angle)
            points.append((px, py))
            
        if current_radius > 2:
            draw.polygon(points, fill=255)
            # Add some dynamic droplets around edges for ink splatter feel
            for s in range(12):
                sa = (s * 31.0) % (2.0 * math.pi)
                sr = current_radius * (1.08 + 0.12 * math.sin(s * 3.7))
                sx = cx + sr * math.cos(sa)
                sy = cy + sr * math.sin(sa)
                s_size = max(2, int(current_radius * 0.04 * (1.0 - progress)))
                draw.ellipse([sx - s_size, sy - s_size, sx + s_size, sy + s_size], fill=255)
                
        # Feather the mask slightly for smooth anti-aliased edge
        blurred = img.filter(ImageFilter.GaussianBlur(radius=6))
        blurred.save(os.path.join(temp_dir, f"frame_{f:04d}.png"))
        
    # Compile to MP4
    ffmpeg_bin = get_ffmpeg_path()
    input_pattern = os.path.join(temp_dir, "frame_%04d.png")
    cmd = [
        ffmpeg_bin, '-y',
        '-framerate', str(fps),
        '-i', input_pattern,
        '-c:v', 'libx264',
        '-pix_fmt', 'yuv420p',
        output_mp4
    ]
    subprocess.run(cmd, check=True)
    shutil.rmtree(temp_dir, ignore_errors=True)
    print(f"Generated Ink Reveal mask: {output_mp4}")

def generate_brush_stroke_mask(output_mp4, width=1280, height=720, fps=30, duration_sec=2.0):
    total_frames = int(fps * duration_sec)
    temp_dir = os.path.join(os.path.dirname(__file__), 'temp_brush_frames')
    os.makedirs(temp_dir, exist_ok=True)
    
    for f in range(total_frames):
        progress = f / float(total_frames - 1)
        t = progress ** 1.1
        
        img = Image.new('L', (width, height), 0)
        draw = ImageDraw.Draw(img)
        
        # Diagonal wipe with rough brush bristle lines
        wipe_pos = (width + height * 0.5 + 200) * t - 100
        
        for y in range(0, height, 4):
            # Vary bristle leading edge
            bristle_jitter = 40.0 * math.sin(y * 0.1) + 25.0 * math.cos(y * 0.23) + 15.0 * math.sin(y * 0.47)
            lead_x = wipe_pos - (y * 0.35) + bristle_jitter
            if lead_x > 0:
                draw.rectangle([0, y, min(width, lead_x), y + 4], fill=255)
                # Bristle trailing gradient
                fade_w = 30
                for fw in range(fade_w):
                    fx = lead_x + fw
                    if 0 <= fx < width:
                        alpha = int(255 * (1.0 - (fw / float(fade_w))))
                        draw.point((fx, y), fill=alpha)
                        draw.point((fx, y + 1), fill=alpha)
                        draw.point((fx, y + 2), fill=alpha)
                        draw.point((fx, y + 3), fill=alpha)
                        
        blurred = img.filter(ImageFilter.GaussianBlur(radius=4))
        blurred.save(os.path.join(temp_dir, f"frame_{f:04d}.png"))
        
    ffmpeg_bin = get_ffmpeg_path()
    input_pattern = os.path.join(temp_dir, "frame_%04d.png")
    cmd = [
        ffmpeg_bin, '-y',
        '-framerate', str(fps),
        '-i', input_pattern,
        '-c:v', 'libx264',
        '-pix_fmt', 'yuv420p',
        output_mp4
    ]
    subprocess.run(cmd, check=True)
    shutil.rmtree(temp_dir, ignore_errors=True)
    print(f"Generated Brush Stroke mask: {output_mp4}")

if __name__ == '__main__':
    project_root = os.path.abspath(os.path.join(os.path.dirname(__file__), '..'))
    masks_dir = os.path.join(project_root, 'assets', 'masks')
    os.makedirs(masks_dir, exist_ok=True)
    
    ink_path = os.path.join(masks_dir, 'ink_reveal.mp4')
    brush_path = os.path.join(masks_dir, 'brush_stroke.mp4')
    
    generate_ink_reveal_mask(ink_path)
    generate_brush_stroke_mask(brush_path)
    print("All reveal masks created successfully!")

