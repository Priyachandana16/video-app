import sys
import os
import json
import re
import math
import subprocess
import shutil
from PIL import Image, ImageDraw, ImageFont

def get_ffmpeg_path():
    candidate = os.path.join(os.path.dirname(__file__), 'node_modules', '@ffmpeg-installer', 'win32-x64', 'ffmpeg.exe')
    if os.path.exists(candidate):
        return candidate
    return 'ffmpeg'

def fit_image_to_rect(img, target_w, target_h, fit_mode='cover'):
    """Aspect-fill or fit image to target bounding box dimensions."""
    if fit_mode == 'contain':
        scale = min(target_w / float(img.width), target_h / float(img.height))
        new_w, new_h = max(1, int(img.width * scale)), max(1, int(img.height * scale))
        resized = img.resize((new_w, new_h), Image.Resampling.LANCZOS)
        bg = Image.new('RGBA', (target_w, target_h), (0, 0, 0, 0))
        offset_x = (target_w - new_w) // 2
        offset_y = (target_h - new_h) // 2
        bg.paste(resized, (offset_x, offset_y))
        return bg
    else: # cover (default)
        scale = max(target_w / float(img.width), target_h / float(img.height))
        new_w, new_h = max(1, int(img.width * scale)), max(1, int(img.height * scale))
        resized = img.resize((new_w, new_h), Image.Resampling.LANCZOS)
        left = max(0, (new_w - target_w) // 2)
        top = max(0, (new_h - target_h) // 2)
        return resized.crop((left, top, left + target_w, top + target_h))

def hex_to_rgb(hex_str, default=(255, 215, 0)):
    try:
        hex_str = hex_str.lstrip('#')
        if len(hex_str) == 6:
            return tuple(int(hex_str[i:i+2], 16) for i in (0, 2, 4))
        elif len(hex_str) == 8:
            return tuple(int(hex_str[i:i+2], 16) for i in (0, 2, 4, 6))
    except Exception:
        pass
    return default

def get_best_font(font_family, size):
    candidates = []
    fam_lower = (font_family or '').lower()
    if 'cinzel' in fam_lower:
        candidates = ["georgia.ttf", "times.ttf", "palatino.ttf", "segoeui.ttf"]
    elif 'playfair' in fam_lower:
        candidates = ["georgia.ttf", "times.ttf", "arial.ttf"]
    else:
        candidates = ["calibri.ttf", "arial.ttf", "segoeui.ttf", "georgia.ttf"]

    for fn in candidates:
        try:
            return ImageFont.truetype(fn, size)
        except Exception:
            continue
    return ImageFont.load_default()

def render_text_overlay(text, font_family, font_size, font_color, align, canvas_w, canvas_h, target_x, target_y):
    """Render antialiased text onto a transparent RGBA image at canvas coordinates."""
    img = Image.new('RGBA', (canvas_w, canvas_h), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    font = get_best_font(font_family, font_size)

    rgb = hex_to_rgb(font_color, (255, 215, 0))
    fill_color = rgb if len(rgb) == 4 else (*rgb, 255)
    shadow_color = (15, 15, 20, 220)

    # Word wrapping if text is long
    max_text_width = int(canvas_w * 0.85)
    words = text.split(' ')
    lines = []
    cur_line = []
    for w in words:
        test_line = ' '.join(cur_line + [w])
        bbox = draw.textbbox((0, 0), test_line, font=font)
        if bbox[2] - bbox[0] > max_text_width and cur_line:
            lines.append(' '.join(cur_line))
            cur_line = [w]
        else:
            cur_line.append(w)
    if cur_line:
        lines.append(' '.join(cur_line))

    line_height = int(font_size * 1.25)
    total_h = len(lines) * line_height
    start_y = target_y - (total_h // 2)

    for i, line in enumerate(lines):
        bbox = draw.textbbox((0, 0), line, font=font)
        lw = bbox[2] - bbox[0]
        if align == 'left':
            lx = target_x
        elif align == 'right':
            lx = target_x - lw
        else: # center
            lx = target_x - (lw // 2)

        ly = start_y + (i * line_height)
        # Drop shadow for readability over rich video
        for ox, oy in [(-2, -2), (2, -2), (-2, 2), (2, 2), (3, 3)]:
            draw.text((lx + ox, ly + oy), line, font=font, fill=shadow_color)
        draw.text((lx, ly), line, font=font, fill=fill_color)

    return img

def run_ffmpeg_with_progress(cmd, total_duration_sec=60.0):
    """Run FFmpeg and stream live PROGRESS: 0.XX | <step> lines to stdout."""
    print("PROGRESS: 0.40 | Assembling composition timeline...", flush=True)

    proc = subprocess.Popen(
        cmd,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        universal_newlines=True,
        bufsize=1
    )

    time_pattern = re.compile(r'time=(\d+):(\d+):(\d+\.\d+)')
    last_reported_pct = 0.40

    if proc.stderr:
        for line in proc.stderr:
            match = time_pattern.search(line)
            if match:
                hrs, mins, secs = int(match.group(1)), int(match.group(2)), float(match.group(3))
                elapsed = hrs * 3600 + mins * 60 + secs
                ratio = min(1.0, elapsed / max(1.0, total_duration_sec))
                current_pct = 0.40 + (0.55 * ratio)
                if current_pct - last_reported_pct >= 0.04 or current_pct >= 0.94:
                    last_reported_pct = current_pct
                    print(f"PROGRESS: {current_pct:.2f} | Rendering high-definition video...", flush=True)

    proc.wait()
    if proc.returncode != 0:
        err_output = proc.stderr.read() if proc.stderr else "Unknown error"
        raise RuntimeError(f"FFmpeg failed with exit code {proc.returncode}: {err_output[-400:]}")

    print("PROGRESS: 0.98 | Finalizing MP4 invitation...", flush=True)

def render_dynamic_invitation(config_path):
    print("PROGRESS: 0.05 | Initializing dynamic rendering engine...", flush=True)

    with open(config_path, 'r', encoding='utf-8') as f:
        data = json.load(f)

    project_root = os.path.abspath(os.path.join(os.path.dirname(__file__), '..'))
    templates_file = os.path.join(os.path.dirname(__file__), 'data', 'templates.json')

    # Resolve template definition
    template = data.get('template')
    if not template:
        template_id = data.get('templateId', 'tmpl_telugu_chroma_01')
        if os.path.exists(templates_file):
            try:
                with open(templates_file, 'r', encoding='utf-8') as tf:
                    t_list = json.load(tf)
                    for t in t_list:
                        if t.get('id') == template_id:
                            template = t
                            break
            except Exception as e:
                print(f"Warning: Could not read templates.json: {e}")

    if not template:
        template = {
            "id": "tmpl_telugu_chroma_01",
            "canvasWidth": 1920,
            "canvasHeight": 1080,
            "durationSeconds": 102,
            "masterVideoPath": "assets/templates/template_01_green_screen.mp4",
            "textElements": [],
            "imageElements": []
        }

    canvas_w = template.get('canvasWidth', 1920)
    canvas_h = template.get('canvasHeight', 1080)
    duration = float(template.get('durationSeconds', 60))
    master_video_rel = template.get('masterVideoPath', 'assets/templates/template_01_green_screen.mp4')
    master_video = os.path.abspath(os.path.join(project_root, master_video_rel)) if not os.path.isabs(master_video_rel) else master_video_rel

    output_video = data.get('outputVideoPath')
    if not output_video:
        output_video = os.path.join(project_root, 'backend', 'exports', f"output_{os.getpid()}.mp4")
    elif not os.path.isabs(output_video):
        output_video = os.path.abspath(os.path.join(project_root, output_video))

    os.makedirs(os.path.dirname(output_video), exist_ok=True)
    temp_dir = os.path.join(os.path.dirname(output_video), f"temp_{os.getpid()}_{int(os.path.getmtime(config_path))}")
    os.makedirs(temp_dir, exist_ok=True)

    ffmpeg_bin = get_ffmpeg_path()
    masks_dir = os.path.join(project_root, 'assets', 'masks')
    ink_mask_video = os.path.join(masks_dir, 'ink_reveal.mp4')
    brush_mask_video = os.path.join(masks_dir, 'brush_stroke.mp4')

    # Resolve user dynamic text dictionary
    user_data = data.get('userData', data)
    user_photos = data.get('photos', {})

    # Also map direct fields if sent via standard form
    direct_photo_fields = ['photo_1', 'photo_2', 'photo_3', 'photo_4', 'photo_5', 'womanPhoto', 'manPhoto', 'photo']
    for pf in direct_photo_fields:
        if data.get(pf):
            user_photos[pf] = data.get(pf)
        if data.get(f"{pf}Path"):
            user_photos[pf] = data.get(f"{pf}Path")

    # If womanPhoto/manPhoto are provided, make sure photo_1/photo_2 inherit them if missing
    if 'womanPhoto' in user_photos and 'photo_1' not in user_photos:
        user_photos['photo_1'] = user_photos['womanPhoto']
    if 'manPhoto' in user_photos and 'photo_2' not in user_photos:
        user_photos['photo_2'] = user_photos['manPhoto']

    print("PROGRESS: 0.15 | Processing and framing uploaded photographs...", flush=True)

    image_elements = template.get('imageElements', [])
    text_elements = template.get('textElements', [])

    # If template has legacy/empty textElements, construct standard dynamic set
    if not text_elements:
        text_elements = [
            {
                "id": "def_ceremony",
                "field": "ceremonyTitle",
                "defaultText": "శుభ వివాహం / Subha Vivaham",
                "x": canvas_w // 2,
                "y": 80,
                "fontSize": 44,
                "fontFamily": "Cinzel",
                "fontColor": "#FFD700",
                "textAlign": "center",
                "startTime": 2.0,
                "endTime": min(duration, 28.0),
                "fadeIn": 0.6,
                "fadeOut": 0.6
            },
            {
                "id": "def_names",
                "field": "coupleNames",
                "defaultText": f"{user_data.get('groomName', 'Sai Krishna')} & {user_data.get('brideName', 'Deepika')}",
                "x": canvas_w // 2,
                "y": canvas_h - 180,
                "fontSize": 48,
                "fontFamily": "Playfair Display",
                "fontColor": "#FFF9E6",
                "textAlign": "center",
                "startTime": 28.0,
                "endTime": min(duration, 55.0),
                "fadeIn": 0.6,
                "fadeOut": 0.6
            },
            {
                "id": "def_venue",
                "field": "venue",
                "defaultText": user_data.get('venue', 'Sri Venkateswara Kalyana Mandapam, Hyderabad'),
                "x": canvas_w // 2,
                "y": canvas_h - 180,
                "fontSize": 34,
                "fontFamily": "Playfair Display",
                "fontColor": "#FFFFFF",
                "textAlign": "center",
                "startTime": 56.0,
                "endTime": duration,
                "fadeIn": 0.6,
                "fadeOut": 0.6
            }
        ]

    # If template has empty imageElements but hasPhoto is true, create default image slot
    if not image_elements and template.get('hasPhoto', False):
        image_elements = [
            {
                "id": "def_img_1",
                "field": "photo_1",
                "x": 680,
                "y": 80,
                "width": 560,
                "height": 720,
                "fit": "cover",
                "startTime": 5.0,
                "endTime": min(duration, 25.0),
                "animationType": "ink_reveal",
                "animationDuration": 1.2
            }
        ]

    # Pre-render Image Element Assets
    prepared_images = []
    for idx, img_el in enumerate(image_elements):
        field_name = img_el.get('field', f'photo_{idx+1}')
        target_w = int(img_el.get('width', 500))
        target_h = int(img_el.get('height', 600))
        fit_mode = img_el.get('fit', 'cover')

        src_path = user_photos.get(field_name) or user_photos.get('photo')
        if not src_path or not os.path.exists(src_path):
            # Check placeholder in template or default asset
            ph = img_el.get('placeholderUrl', '')
            if ph.startswith('/'):
                ph = ph.lstrip('/')
            cand_ph = os.path.join(project_root, ph)
            if os.path.exists(cand_ph):
                src_path = cand_ph
            else:
                cand_default = os.path.join(project_root, 'assets', 'candidate_screenshot.jpg')
                if os.path.exists(cand_default):
                    src_path = cand_default

        out_prep_img = os.path.join(temp_dir, f"prep_img_{idx}.png")
        if src_path and os.path.exists(src_path):
            try:
                with Image.open(src_path).convert('RGBA') as raw_img:
                    fitted = fit_image_to_rect(raw_img, target_w, target_h, fit_mode)
                    fitted.save(out_prep_img, 'PNG')
            except Exception as e:
                print(f"Error preparing photo {field_name}: {e}")
                blank = Image.new('RGBA', (target_w, target_h), (0, 0, 0, 0))
                blank.save(out_prep_img, 'PNG')
        else:
            blank = Image.new('RGBA', (target_w, target_h), (0, 0, 0, 0))
            blank.save(out_prep_img, 'PNG')

        prepared_images.append({
            'el': img_el,
            'path': out_prep_img,
            'width': target_w,
            'height': target_h,
            'x': int(img_el.get('x', 0)),
            'y': int(img_el.get('y', 0)),
            'start': float(img_el.get('startTime', 0.0)),
            'end': float(img_el.get('endTime', duration)),
            'anim': img_el.get('animationType', 'fade'),
            'animDur': float(img_el.get('animationDuration', 1.0))
        })

    print("PROGRESS: 0.25 | Rendering custom typography & overlays...", flush=True)

    # Pre-render Text Overlays onto full-canvas transparent PNGs
    prepared_texts = []
    for idx, txt_el in enumerate(text_elements):
        field_key = txt_el.get('field', '')
        # Check user data, fallback to defaultText
        text_val = user_data.get(field_key)
        if not text_val:
            if field_key == 'coupleNames':
                text_val = f"{user_data.get('groomName', 'Sai Krishna')} & {user_data.get('brideName', 'Deepika')}"
            else:
                text_val = txt_el.get('defaultText', '')

        if not text_val:
            continue

        font_family = txt_el.get('fontFamily', 'Cinzel')
        font_size = int(txt_el.get('fontSize', 40))
        font_color = txt_el.get('fontColor', '#FFD700')
        align = txt_el.get('textAlign', 'center')
        tx = int(txt_el.get('x', canvas_w // 2))
        ty = int(txt_el.get('y', canvas_h // 2))
        start_t = float(txt_el.get('startTime', 0.0))
        end_t = float(txt_el.get('endTime', duration))
        fade_in = float(txt_el.get('fadeIn', 0.5))
        fade_out = float(txt_el.get('fadeOut', 0.5))

        out_txt_png = os.path.join(temp_dir, f"prep_txt_{idx}.png")
        text_img = render_text_overlay(str(text_val), font_family, font_size, font_color, align, canvas_w, canvas_h, tx, ty)
        text_img.save(out_txt_png, 'PNG')

        prepared_texts.append({
            'el': txt_el,
            'path': out_txt_png,
            'start': start_t,
            'end': end_t,
            'fadeIn': fade_in,
            'fadeOut': fade_out
        })

    print("PROGRESS: 0.35 | Constructing multi-track FFmpeg composition...", flush=True)

    # Build FFmpeg command and complex filter graph
    # Input 0: Master background video
    inputs = ['-i', master_video]
    filter_chains = []

    # Canvas normalization of background layer
    filter_chains.append(f"[0:v]scale={canvas_w}:{canvas_h}:force_original_aspect_ratio=decrease,pad={canvas_w}:{canvas_h}:(ow-iw)/2:(oh-ih)/2,setsar=1[v_canvas]")
    current_stream = "v_canvas"

    input_index = 1

    # Add Image inputs & filters
    for idx, pimg in enumerate(prepared_images):
        inputs.extend(['-loop', '1', '-t', str(duration), '-i', pimg['path']])
        img_idx = input_index
        input_index += 1

        anim = pimg['anim']
        st = pimg['start']
        et = pimg['end']
        w = pimg['width']
        h = pimg['height']
        x = pimg['x']
        y = pimg['y']
        anim_dur = pimg['animDur']
        fade_out = 0.5

        if anim in ['ink_reveal', 'brush_stroke']:
            mask_video = ink_mask_video if anim == 'ink_reveal' else brush_mask_video
            if os.path.exists(mask_video):
                inputs.extend(['-i', mask_video])
                mask_idx = input_index
                input_index += 1

                # Scale mask to image size, pad stop to hold last frame, alphamerge
                filter_chains.append(f"[{mask_idx}:v]scale={w}:{h},tpad=stop=-1:stop_mode=clone[mask_{idx}]")
                filter_chains.append(f"[{img_idx}:v][mask_{idx}]alphamerge,fade=t=out:st={max(0, et - fade_out)}:d={fade_out}:alpha=1[img_anim_{idx}]")
            else:
                filter_chains.append(f"[{img_idx}:v]format=rgba,fade=t=in:st={st}:d={anim_dur}:alpha=1,fade=t=out:st={max(0, et - fade_out)}:d={fade_out}:alpha=1[img_anim_{idx}]")
        elif anim == 'fade':
            filter_chains.append(f"[{img_idx}:v]format=rgba,fade=t=in:st={st}:d={anim_dur}:alpha=1,fade=t=out:st={max(0, et - fade_out)}:d={fade_out}:alpha=1[img_anim_{idx}]")
        else: # none
            filter_chains.append(f"[{img_idx}:v]format=rgba[img_anim_{idx}]")

        next_stream = f"v_img_{idx}"
        filter_chains.append(f"[{current_stream}][img_anim_{idx}]overlay={x}:{y}:enable='between(t,{st},{et})'[{next_stream}]")
        current_stream = next_stream

    # Add Text inputs & filters
    for idx, ptxt in enumerate(prepared_texts):
        inputs.extend(['-loop', '1', '-t', str(duration), '-i', ptxt['path']])
        txt_idx = input_index
        input_index += 1

        st = ptxt['start']
        et = ptxt['end']
        fi = ptxt['fadeIn']
        fo = ptxt['fadeOut']

        filter_chains.append(f"[{txt_idx}:v]format=rgba,fade=t=in:st={st}:d={fi}:alpha=1,fade=t=out:st={max(0, et - fo)}:d={fo}:alpha=1[txt_anim_{idx}]")
        next_stream = f"v_txt_{idx}"
        filter_chains.append(f"[{current_stream}][txt_anim_{idx}]overlay=0:0:enable='between(t,{st},{et})'[{next_stream}]")
        current_stream = next_stream

    filter_complex_str = ';'.join(filter_chains)

    # Assemble complete command
    cmd = [ffmpeg_bin, '-y']
    cmd.extend(inputs)
    cmd.extend([
        '-filter_complex', filter_complex_str,
        '-map', f"[{current_stream}]",
        '-map', '0:a?', # Preserve audio from original template video
        '-c:v', 'libx264',
        '-preset', 'veryfast',
        '-pix_fmt', 'yuv420p',
        '-c:a', 'aac',
        '-b:a', '192k',
        '-t', str(duration),
        output_video
    ])

    try:
        run_ffmpeg_with_progress(cmd, total_duration_sec=duration)
    finally:
        # Cleanup temp directory
        try:
            shutil.rmtree(temp_dir, ignore_errors=True)
        except Exception:
            pass

    print(f"PROGRESS: 1.00 | Rendering successfully finished: {output_video}", flush=True)
    return output_video

if __name__ == '__main__':
    if len(sys.argv) < 2:
        print("Usage: python render_engine.py <config_path>")
        sys.exit(1)

    config_file = sys.argv[1]
    try:
        render_dynamic_invitation(config_file)
        sys.exit(0)
    except Exception as err:
        print(f"RENDER_ERROR: {str(err)}", file=sys.stderr)
        sys.exit(1)
