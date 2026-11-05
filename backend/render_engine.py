import sys
import os
import json
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

def draw_text_with_shadow(draw, pos, text, font, fill_color, shadow_color=(200, 200, 210, 180), offset=(2, 2), anchor='mm'):
    x, y = pos
    draw.text((x + offset[0], y + offset[1]), text, font=font, fill=shadow_color, anchor=anchor)
    draw.text((x, y), text, font=font, fill=fill_color, anchor=anchor)

def render_invitation(config_path):
    with open(config_path, 'r', encoding='utf-8') as f:
        data = json.load(f)

    master_video = data.get('masterVideoPath', 'assets/templates/template_01_green_screen.mp4')
    output_video = data.get('outputVideoPath', 'backend/exports/personalized_output.mp4')
    
    woman_photo_path = data.get('womanPhotoPath') or data.get('photoPath')
    man_photo_path = data.get('manPhotoPath') or data.get('photoPath')

    bride_name = data.get('brideName', 'Deepika')
    groom_name = data.get('groomName', 'Sai Krishna')
    parents_names = data.get('parentsNames', 'Smt. Sarojini & Sri. Rama Rao')
    ceremony_title = data.get('ceremonyTitle', 'శుభ వివాహం / Subha Vivaham')
    event_date = data.get('eventDate', 'Sunday, 15 December 2026')
    muhurtham_time = data.get('muhurthamTime', 'Sumuhurtham: 10:24 AM')
    venue = data.get('venue', 'Sri Venkateswara Kalyana Mandapam, Hyderabad')
    rsvp = data.get('rsvp', 'With Best Compliments from Family & Friends')
    is_preview = data.get('previewMode', False)

    if not os.path.isabs(master_video):
        master_video = os.path.abspath(master_video)
    if not os.path.isabs(output_video):
        output_video = os.path.abspath(output_video)

    os.makedirs(os.path.dirname(output_video), exist_ok=True)
    ffmpeg_bin = get_ffmpeg_path()

    # Generate elegant fallback transparent images if user photos not provided
    temp_dir = os.path.dirname(output_video)
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

    if is_chroma:
        # Template 1: Green Screen Mandap Video (1920x892)
        # Scale photos to 1240 x 892 to fit the right green arch window (x=680..1920)
        try:
            raw_m = Image.open(man_photo_path).convert('RGB')
            fit_image_to_rect(raw_m, 1240, 892).save(prep_groom, 'PNG')
        except Exception:
            prep_groom = man_photo_path

        try:
            raw_w = Image.open(woman_photo_path).convert('RGB')
            fit_image_to_rect(raw_w, 1240, 892).save(prep_bride, 'PNG')
        except Exception:
            prep_bride = woman_photo_path

        # Colors matching the authentic sample result (Royal Burgundy / Purple + Gold)
        royal_purple = (85, 20, 65, 255)
        royal_maroon = (110, 25, 40, 255)
        sub_color = (60, 60, 70, 240)
        gold_color = (180, 130, 20, 255)

        f_large = get_best_font(52)
        f_mid = get_best_font(28)
        f_small = get_best_font(24)

        # 1. Groom Reveal Text (Left Panel x = 540, centered between dividers y=350..550)
        img_groom_txt = Image.new('RGBA', (1920, 892), (0, 0, 0, 0))
        d1 = ImageDraw.Draw(img_groom_txt)
        draw_text_with_shadow(d1, (540, 410), f"చి|| {groom_name}", f_large, royal_purple)
        draw_text_with_shadow(d1, (540, 470), "s/o", f_mid, sub_color)
        draw_text_with_shadow(d1, (540, 520), parents_names, f_small, royal_maroon)
        img_groom_txt.save(txt_groom_png, 'PNG')

        # 2. Bride Reveal Text (Left Panel x = 540, centered between dividers y=350..550)
        img_bride_txt = Image.new('RGBA', (1920, 892), (0, 0, 0, 0))
        d2 = ImageDraw.Draw(img_bride_txt)
        draw_text_with_shadow(d2, (540, 410), f"చి||ల||సౌ|| {bride_name}", f_large, royal_purple)
        draw_text_with_shadow(d2, (540, 470), "D/o", f_mid, sub_color)
        draw_text_with_shadow(d2, (540, 520), parents_names, f_small, royal_maroon)
        img_bride_txt.save(txt_bride_png, 'PNG')

        # 3. Sumuhurtham Text (Centered x = 960 between dividers y=320..580)
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

        # Compositing filter graph:
        # [0:v] Master Video keyed on bright green 0x00FF00
        # Under the arch (x=680, y=0):
        # - Groom photo active at 28.4s -> 38.5s
        # - Bride photo active at 41.2s -> 51.5s
        # On top:
        # - Groom text active at 28.4s -> 38.5s
        # - Bride text active at 41.2s -> 51.5s
        # - Sumuhurtham text active at 54.0s -> 68.0s
        # - Venue text active at 69.0s -> 85.0s
        filter_str = (
            "[1:v]scale=1240:892[groom_p];"
            "[2:v]scale=1240:892[bride_p];"
            "[0:v]chromakey=0x00ff00:0.18:0.08[ck];"
            "color=c=0x0E0E12:s=1920x892:d=102.6[canvas];"
            "[canvas][groom_p]overlay=x=680:y=0:enable='between(t,28.4,38.5)'[bg1];"
            "[bg1][bride_p]overlay=x=680:y=0:enable='between(t,41.2,51.5)':shortest=1[bg2];"
            "[bg2][ck]overlay=x=0:y=0[vid];"
            "[vid][3:v]overlay=x=0:y=0:enable='between(t,28.4,38.5)'[v_g];"
            "[v_g][4:v]overlay=x=0:y=0:enable='between(t,41.2,51.5)'[v_b];"
            "[v_b][5:v]overlay=x=0:y=0:enable='between(t,54.0,68.0)'[v_m];"
            "[v_m][6:v]overlay=x=0:y=0:enable='between(t,69.0,85.0)'[final]"
        )

        cmd = [
            ffmpeg_bin, '-y', '-loglevel', 'error', '-nostats',
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
            '-crf', '22',
            '-c:a', 'copy',
            '-shortest',
            '-movflags', '+faststart',
            output_video
        ]

    elif is_temp2:
        # Template 2: Royal Gold Mandapam (1920x864, 56s)
        try:
            raw_m = Image.open(man_photo_path).convert('RGB')
            fit_image_to_rect(raw_m, 620, 720).save(prep_groom, 'PNG')
        except Exception:
            prep_groom = man_photo_path

        try:
            raw_w = Image.open(woman_photo_path).convert('RGB')
            fit_image_to_rect(raw_w, 620, 720).save(prep_bride, 'PNG')
        except Exception:
            prep_bride = woman_photo_path

        # Dual framed photos at 16s to 38s
        filter_str = (
            "[1:v]scale=540:680[groom_p];"
            "[2:v]scale=540:680[bride_p];"
            "[0:v][groom_p]overlay=x=220:y=90:enable='between(t,16,38)'[v1];"
            "[v1][bride_p]overlay=x=1160:y=90:enable='between(t,16,38)'[final]"
        )

        cmd = [
            ffmpeg_bin, '-y', '-loglevel', 'error', '-nostats',
            '-i', master_video,
            '-loop', '1', '-i', prep_groom,
            '-loop', '1', '-i', prep_bride,
            '-filter_complex', filter_str,
            '-map', '[final]',
            '-map', '0:a:0?',
            '-c:v', 'libx264',
            '-preset', 'ultrafast',
            '-crf', '22',
            '-c:a', 'copy',
            '-shortest',
            '-movflags', '+faststart',
            output_video
        ]

    else:
        # Template 3: Divine God Ganesha Portrait (9:16 mobile, 59s)
        try:
            raw_w = Image.open(woman_photo_path).convert('RGB')
            fit_image_to_rect(raw_w, 800, 700).save(prep_bride, 'PNG')
        except Exception:
            prep_bride = woman_photo_path

        filter_str = (
            "[1:v]scale=720:640[photo_p];"
            "[0:v][photo_p]overlay=x=180:y=240:enable='between(t,12,38)'[final]"
        )

        cmd = [
            ffmpeg_bin, '-y', '-loglevel', 'error', '-nostats',
            '-i', master_video,
            '-loop', '1', '-i', prep_bride,
            '-filter_complex', filter_str,
            '-map', '[final]',
            '-map', '0:a:0?',
            '-c:v', 'libx264',
            '-preset', 'ultrafast',
            '-crf', '22',
            '-c:a', 'copy',
            '-shortest',
            '-movflags', '+faststart',
            output_video
        ]

    print("Executing render command:", " ".join(cmd[:12]), "...")
    proc = subprocess.run(cmd, stdout=subprocess.DEVNULL, stderr=subprocess.PIPE, text=True)

    if proc.returncode != 0:
        print("FFmpeg error:", proc.stderr[-800:])
        raise RuntimeError(f"FFmpeg failed: {proc.stderr[-300:]}")

    print(f"Render completed successfully: {output_video} (Size: {os.path.getsize(output_video)} bytes)")
    return output_video

if __name__ == '__main__':
    if len(sys.argv) > 1:
        render_invitation(sys.argv[1])
    else:
        print("Usage: python render_engine.py <config.json>")
