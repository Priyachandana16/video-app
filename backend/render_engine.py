import sys
import os
import json
import re
import subprocess
from PIL import Image, ImageDraw, ImageFont

def get_ffmpeg_path():
    candidate = os.path.join(os.path.dirname(__file__), 'node_modules', '@ffmpeg-installer', 'win32-x64', 'ffmpeg.exe')
    if os.path.exists(candidate):
        return candidate
    return 'ffmpeg'

def fit_image_to_rect(img, target_w, target_h):
    """Aspect-fill and center crop image to target dimensions."""
    scale = max(target_w / img.width, target_h / img.height)
    new_w, new_h = int(img.width * scale), int(img.height * scale)
    resized = img.resize((new_w, new_h), Image.Resampling.LANCZOS)
    left = (new_w - target_w) // 2
    top = (new_h - target_h) // 2
    return resized.crop((left, top, left + target_w, top + target_h))

def get_best_font(size):
    for fn in ["georgia.ttf", "arial.ttf", "calibri.ttf", "segoeui.ttf"]:
        try:
            return ImageFont.truetype(fn, size)
        except:
            continue
    return ImageFont.load_default()

def draw_text_with_shadow(draw, pos, text, font, fill_color, shadow_color=(20, 20, 30, 200), offset=(2, 2), anchor='mm'):
    x, y = pos
    draw.text((x + offset[0], y + offset[1]), text, font=font, fill=shadow_color, anchor=anchor)
    draw.text((x, y), text, font=font, fill=fill_color, anchor=anchor)

def run_ffmpeg_with_progress(cmd, total_duration_sec=60.0):
    """Run FFmpeg and stream live PROGRESS: 0.XX | <step> lines to stdout."""
    print("PROGRESS: 0.45 | Creating invitation scenes...", flush=True)
    
    # We pipe stderr because FFmpeg prints stats to stderr by default
    proc = subprocess.Popen(
        cmd,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        universal_newlines=True,
        bufsize=1
    )

    time_pattern = re.compile(r'time=(\d+):(\d+):(\d+\.\d+)')
    last_reported_pct = 0.45

    # Read stderr line-by-line in real time
    if proc.stderr:
        for line in proc.stderr:
            match = time_pattern.search(line)
            if match:
                hrs, mins, secs = int(match.group(1)), int(match.group(2)), float(match.group(3))
                elapsed = hrs * 3600 + mins * 60 + secs
                ratio = min(1.0, elapsed / max(1.0, total_duration_sec))
                current_pct = 0.45 + (0.50 * ratio)
                if current_pct - last_reported_pct >= 0.04 or current_pct >= 0.94:
                    last_reported_pct = current_pct
                    print(f"PROGRESS: {current_pct:.2f} | Rendering your invitation video...", flush=True)

    proc.wait()
    if proc.returncode != 0:
        err_output = proc.stderr.read() if proc.stderr else "Unknown error"
        raise RuntimeError(f"FFmpeg failed with exit code {proc.returncode}: {err_output[-400:]}")

    print("PROGRESS: 0.98 | Finalizing video...", flush=True)

def render_invitation(config_path):
    print("PROGRESS: 0.10 | Preparing your invitation...", flush=True)
    with open(config_path, 'r', encoding='utf-8') as f:
        data = json.load(f)

    master_video = data.get('masterVideoPath', 'assets/templates/template_01_green_screen.mp4')
    output_video = data.get('outputVideoPath', 'backend/exports/personalized_output.mp4')
    
    woman_photo_path = data.get('womanPhotoPath') or data.get('photoPath')
    man_photo_path = data.get('manPhotoPath') or data.get('photoPath')

    photo_placement = str(data.get('photoPlacement', 'center')).lower()
    photo_scale = float(data.get('photoScale', 1.0))
    photo_offset_x = float(data.get('photoOffsetX', 0.0))
    photo_offset_y = float(data.get('photoOffsetY', 0.0))

    bride_name = data.get('brideName', 'Deepika')
    groom_name = data.get('groomName', 'Sai Krishna')
    parents_names = data.get('parentsNames', 'Smt. Sarojini & Sri. Rama Rao')
    ceremony_title = data.get('ceremonyTitle', 'శుభ వివాహం / Subha Vivaham')
    event_date = data.get('eventDate', 'Sunday, 15 December 2026')
    muhurtham_time = data.get('muhurthamTime', 'Sumuhurtham: 10:24 AM')
    venue = data.get('venue', 'Sri Venkateswara Kalyana Mandapam, Hyderabad')
    rsvp = data.get('rsvp', 'With Best Compliments from Family & Friends')

    if not os.path.isabs(master_video):
        master_video = os.path.abspath(master_video)
    if not os.path.isabs(output_video):
        output_video = os.path.abspath(output_video)

    os.makedirs(os.path.dirname(output_video), exist_ok=True)
    ffmpeg_bin = get_ffmpeg_path()
    temp_dir = os.path.dirname(output_video)

    print("PROGRESS: 0.20 | Preparing and framing uploaded photos...", flush=True)

    # Prepare user photos
    prep_groom = os.path.join(temp_dir, f"prep_groom_{os.path.basename(output_video)}.png")
    prep_bride = os.path.join(temp_dir, f"prep_bride_{os.path.basename(output_video)}.png")

    if not woman_photo_path or not os.path.exists(woman_photo_path):
        blank_w = Image.new('RGBA', (1240, 892), (0, 0, 0, 0))
        blank_w.save(prep_bride, 'PNG')
        woman_photo_path = prep_bride
    if not man_photo_path or not os.path.exists(man_photo_path):
        blank_m = Image.new('RGBA', (1240, 892), (0, 0, 0, 0))
        blank_m.save(prep_groom, 'PNG')
        man_photo_path = prep_groom

    txt_groom_png = os.path.join(temp_dir, f"txt_groom_{os.path.basename(output_video)}.png")
    txt_bride_png = os.path.join(temp_dir, f"txt_bride_{os.path.basename(output_video)}.png")
    txt_muhurtham_png = os.path.join(temp_dir, f"txt_muhurtham_{os.path.basename(output_video)}.png")
    txt_venue_png = os.path.join(temp_dir, f"txt_venue_{os.path.basename(output_video)}.png")

    master_lower = os.path.basename(master_video).lower()
    is_chroma = "green_screen" in master_lower or "01" in master_lower
    is_temp2 = "royal_gold" in master_lower or "02" in master_lower or "5.mp4" in master_lower
    is_temp3 = "divine_god" in master_lower or "03" in master_lower or "god" in master_lower

    print("PROGRESS: 0.35 | Processing wedding details & typography...", flush=True)

    # Color Palette
    royal_purple = (85, 20, 65, 255)
    royal_maroon = (110, 25, 40, 255)
    sub_color = (60, 60, 70, 240)
    gold_color = (180, 130, 20, 255)

    f_large = get_best_font(52)
    f_mid = get_best_font(28)
    f_small = get_best_font(24)

    total_duration = 102.6

    if is_chroma:
        total_duration = 102.6
        # Base arch dimensions: 1240 x 892 at base x=680, y=0
        base_w = 1240
        base_h = 892
        base_x = 680
        base_y = 0

        if 'left' in photo_placement:
            base_x = 610
        elif 'right' in photo_placement:
            base_x = 750
        elif 'full' in photo_placement:
            base_x = 640
            base_w = 1280

        target_w = max(400, int(base_w * photo_scale))
        target_h = max(300, int(base_h * photo_scale))

        try:
            raw_m = Image.open(man_photo_path).convert('RGB')
            fit_image_to_rect(raw_m, target_w, target_h).save(prep_groom, 'PNG')
        except Exception:
            prep_groom = man_photo_path

        try:
            raw_w = Image.open(woman_photo_path).convert('RGB')
            fit_image_to_rect(raw_w, target_w, target_h).save(prep_bride, 'PNG')
        except Exception:
            prep_bride = woman_photo_path

        pos_x = int(base_x + photo_offset_x + (base_w - target_w) // 2)
        pos_y = int(base_y + photo_offset_y + (base_h - target_h) // 2)

        # 1. Groom Reveal Text (Left Panel x = 540)
        img_groom_txt = Image.new('RGBA', (1920, 892), (0, 0, 0, 0))
        d1 = ImageDraw.Draw(img_groom_txt)
        draw_text_with_shadow(d1, (540, 410), f"చి|| {groom_name}", f_large, royal_purple)
        draw_text_with_shadow(d1, (540, 470), "s/o", f_mid, sub_color)
        draw_text_with_shadow(d1, (540, 520), parents_names, f_small, royal_maroon)
        img_groom_txt.save(txt_groom_png, 'PNG')

        # 2. Bride Reveal Text (Left Panel x = 540)
        img_bride_txt = Image.new('RGBA', (1920, 892), (0, 0, 0, 0))
        d2 = ImageDraw.Draw(img_bride_txt)
        draw_text_with_shadow(d2, (540, 410), f"చి||ల||సౌ|| {bride_name}", f_large, royal_purple)
        draw_text_with_shadow(d2, (540, 470), "D/o", f_mid, sub_color)
        draw_text_with_shadow(d2, (540, 520), parents_names, f_small, royal_maroon)
        img_bride_txt.save(txt_bride_png, 'PNG')

        # 3. Sumuhurtham Text (Centered x = 960)
        img_muh_txt = Image.new('RGBA', (1920, 892), (0, 0, 0, 0))
        d3 = ImageDraw.Draw(img_muh_txt)
        draw_text_with_shadow(d3, (960, 350), "సుముహూర్తం / Sumuhurtham", f_large, royal_purple)
        draw_text_with_shadow(d3, (960, 430), event_date, f_mid, royal_maroon)
        draw_text_with_shadow(d3, (960, 500), muhurtham_time, f_large, gold_color)
        img_muh_txt.save(txt_muhurtham_png, 'PNG')

        # 4. Venue & Reception Text (Centered x = 960)
        img_ven_txt = Image.new('RGBA', (1920, 892), (0, 0, 0, 0))
        d4 = ImageDraw.Draw(img_ven_txt)
        draw_text_with_shadow(d4, (960, 360), "కళ్యాణ వేదిక & విందు / Venue", f_large, royal_purple)
        draw_text_with_shadow(d4, (960, 440), venue, f_mid, royal_maroon)
        draw_text_with_shadow(d4, (960, 510), rsvp, f_small, sub_color)
        img_ven_txt.save(txt_venue_png, 'PNG')

        filter_str = (
            f"[1:v]scale={target_w}:{target_h}[groom_p];"
            f"[2:v]scale={target_w}:{target_h}[bride_p];"
            "[0:v]chromakey=0x00ff00:0.18:0.08[ck];"
            "color=c=0x0E0E12:s=1920x892:d=102.6[canvas];"
            f"[canvas][groom_p]overlay=x={pos_x}:y={pos_y}:enable='between(t,28.4,38.5)'[bg1];"
            f"[bg1][bride_p]overlay=x={pos_x}:y={pos_y}:enable='between(t,41.2,51.5)':shortest=1[bg2];"
            "[bg2][ck]overlay=x=0:y=0[vid];"
            "[vid][3:v]overlay=x=0:y=0:enable='between(t,28.4,38.5)'[v_g];"
            "[v_g][4:v]overlay=x=0:y=0:enable='between(t,41.2,51.5)'[v_b];"
            "[v_b][5:v]overlay=x=0:y=0:enable='between(t,54.0,68.0)'[v_m];"
            "[v_m][6:v]overlay=x=0:y=0:enable='between(t,69.0,85.0)'[final]"
        )

        cmd = [
            ffmpeg_bin, '-y',
            '-i', master_video,
            '-loop', '1', '-i', prep_groom,
            '-loop', '1', '-i', prep_bride,
            '-loop', '1', '-i', txt_groom_png,
            '-loop', '1', '-i', txt_bride_png,
            '-loop', '1', '-i', txt_muhurtham_png,
            '-loop', '1', '-i', txt_venue_png,
            '-filter_complex', filter_str,
            '-map', '[final]',
            '-map', '0:a:0?',
            '-c:v', 'libx264',
            '-preset', 'ultrafast',
            '-threads', '4',
            '-crf', '22',
            '-c:a', 'copy',
            '-shortest',
            '-movflags', '+faststart',
            output_video
        ]

    elif is_temp2:
        total_duration = 56.0
        target_w = int(540 * photo_scale)
        target_h = int(680 * photo_scale)

        try:
            raw_m = Image.open(man_photo_path).convert('RGB')
            fit_image_to_rect(raw_m, target_w, target_h).save(prep_groom, 'PNG')
        except Exception:
            prep_groom = man_photo_path

        try:
            raw_w = Image.open(woman_photo_path).convert('RGB')
            fit_image_to_rect(raw_w, target_w, target_h).save(prep_bride, 'PNG')
        except Exception:
            prep_bride = woman_photo_path

        gx = int(220 + photo_offset_x)
        gy = int(90 + photo_offset_y)
        bx = int(1160 + photo_offset_x)
        by = int(90 + photo_offset_y)

        # Couple text overlay for Template 2
        img_names = Image.new('RGBA', (1920, 864), (0, 0, 0, 0))
        d_n = ImageDraw.Draw(img_names)
        draw_text_with_shadow(d_n, (490, 800), f"చి|| {groom_name}", f_mid, gold_color)
        draw_text_with_shadow(d_n, (1430, 800), f"చి||ల||సౌ|| {bride_name}", f_mid, gold_color)
        img_names.save(txt_groom_png, 'PNG')

        # Muhurtham & Venue text overlay for Template 2
        img_event = Image.new('RGBA', (1920, 864), (0, 0, 0, 0))
        d_e = ImageDraw.Draw(img_event)
        draw_text_with_shadow(d_e, (960, 360), ceremony_title, f_large, gold_color)
        draw_text_with_shadow(d_e, (960, 440), f"{event_date} • {muhurtham_time}", f_mid, (255, 240, 200, 255))
        draw_text_with_shadow(d_e, (960, 520), venue, f_small, (220, 220, 230, 240))
        img_event.save(txt_venue_png, 'PNG')

        filter_str = (
            f"[1:v]scale={target_w}:{target_h}[groom_p];"
            f"[2:v]scale={target_w}:{target_h}[bride_p];"
            f"[0:v][groom_p]overlay=x={gx}:y={gy}:enable='between(t,16,38)'[v1];"
            f"[v1][bride_p]overlay=x={bx}:y={by}:enable='between(t,16,38)'[v2];"
            "[v2][3:v]overlay=x=0:y=0:enable='between(t,16,38)'[v3];"
            "[v3][4:v]overlay=x=0:y=0:enable='between(t,38,55)'[final]"
        )

        cmd = [
            ffmpeg_bin, '-y',
            '-i', master_video,
            '-loop', '1', '-i', prep_groom,
            '-loop', '1', '-i', prep_bride,
            '-loop', '1', '-i', txt_groom_png,
            '-loop', '1', '-i', txt_venue_png,
            '-filter_complex', filter_str,
            '-map', '[final]',
            '-map', '0:a:0?',
            '-c:v', 'libx264',
            '-preset', 'ultrafast',
            '-threads', '4',
            '-crf', '22',
            '-c:a', 'copy',
            '-shortest',
            '-movflags', '+faststart',
            output_video
        ]

    else:
        # Template 3 & Occasion Portrait templates (9:16 mobile)
        total_duration = 59.0
        target_w = int(720 * photo_scale)
        target_h = int(640 * photo_scale)

        try:
            raw_w = Image.open(woman_photo_path).convert('RGB')
            fit_image_to_rect(raw_w, target_w, target_h).save(prep_bride, 'PNG')
        except Exception:
            prep_bride = woman_photo_path

        px = int(180 + photo_offset_x)
        py = int(240 + photo_offset_y)

        # Portrait text overlay
        img_port = Image.new('RGBA', (1080, 1920), (0, 0, 0, 0))
        d_p = ImageDraw.Draw(img_port)
        draw_text_with_shadow(d_p, (540, 940), f"{groom_name} & {bride_name}", f_large, gold_color)
        draw_text_with_shadow(d_p, (540, 1020), f"{event_date} • {muhurtham_time}", f_mid, (255, 245, 220, 255))
        draw_text_with_shadow(d_p, (540, 1100), venue, f_small, (220, 220, 230, 230))
        img_port.save(txt_muhurtham_png, 'PNG')

        filter_str = (
            f"[1:v]scale={target_w}:{target_h}[photo_p];"
            f"[0:v][photo_p]overlay=x={px}:y={py}:enable='between(t,12,38)'[v1];"
            "[v1][2:v]overlay=x=0:y=0:enable='between(t,12,50)'[final]"
        )

        cmd = [
            ffmpeg_bin, '-y',
            '-i', master_video,
            '-loop', '1', '-i', prep_bride,
            '-loop', '1', '-i', txt_muhurtham_png,
            '-filter_complex', filter_str,
            '-map', '[final]',
            '-map', '0:a:0?',
            '-c:v', 'libx264',
            '-preset', 'ultrafast',
            '-threads', '4',
            '-crf', '22',
            '-c:a', 'copy',
            '-shortest',
            '-movflags', '+faststart',
            output_video
        ]

    print("PROGRESS: 0.45 | Creating invitation scenes...", flush=True)
    run_ffmpeg_with_progress(cmd, total_duration_sec=total_duration)

    print(f"PROGRESS: 1.00 | Video ready!", flush=True)
    return output_video

if __name__ == '__main__':
    if len(sys.argv) > 1:
        render_invitation(sys.argv[1])
    else:
        print("Usage: python render_engine.py <config.json>")
