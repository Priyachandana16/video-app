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

def render_text_image(text, font_family, font_size, font_color, align, max_box_w=1600):
    """Render antialiased text onto a tightly-bounded RGBA image, returning (img, w, h)."""
    font = get_best_font(font_family, font_size)
    dummy_img = Image.new('RGBA', (1, 1), (0, 0, 0, 0))
    dummy_draw = ImageDraw.Draw(dummy_img)

    rgb = hex_to_rgb(font_color, (255, 215, 0))
    fill_color = rgb if len(rgb) == 4 else (*rgb, 255)
    shadow_color = (15, 15, 20, 220)

    # Word wrapping
    words = text.split(' ')
    lines = []
    cur_line = []
    for w in words:
        test_line = ' '.join(cur_line + [w])
        bbox = dummy_draw.textbbox((0, 0), test_line, font=font)
        if bbox[2] - bbox[0] > max_box_w and cur_line:
            lines.append(' '.join(cur_line))
            cur_line = [w]
        else:
            cur_line.append(w)
    if cur_line:
        lines.append(' '.join(cur_line))

    line_height = int(font_size * 1.3)
    measured_widths = [dummy_draw.textbbox((0, 0), l, font=font)[2] - dummy_draw.textbbox((0, 0), l, font=font)[0] for l in lines]
    max_w = max(measured_widths) if measured_widths else 100
    total_w = max_w + 30
    total_h = len(lines) * line_height + 20

    img = Image.new('RGBA', (total_w, total_h), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)

    for i, line in enumerate(lines):
        lw = measured_widths[i]
        if align == 'left':
            lx = 10
        elif align == 'right':
            lx = total_w - 10 - lw
        else: # center
            lx = (total_w - lw) // 2

        ly = 10 + (i * line_height)
        for ox, oy in [(-2, -2), (2, -2), (-2, 2), (2, 2), (3, 3)]:
            draw.text((lx + ox, ly + oy), line, font=font, fill=shadow_color)
        draw.text((lx, ly), line, font=font, fill=fill_color)

    return img, total_w, total_h

def run_ffmpeg_with_progress(cmd, total_duration_sec=60.0):
    """Run FFmpeg and stream live PROGRESS: 0.XX | <step> lines to stdout."""
    print("PROGRESS: 0.38 | Launching accelerated video compositor...", flush=True)

    proc = subprocess.Popen(
        cmd,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        universal_newlines=True,
        bufsize=1
    )

    time_pattern = re.compile(r'time=(\d+):(\d+):(\d+\.\d+)')
    last_reported_pct = 0.40

    err_lines = []
    if proc.stderr:
        for line in proc.stderr:
            err_lines.append(line.strip())
            match = time_pattern.search(line)
            if match:
                hrs, mins, secs = int(match.group(1)), int(match.group(2)), float(match.group(3))
                elapsed = hrs * 3600 + mins * 60 + secs
                ratio = min(1.0, elapsed / max(1.0, total_duration_sec))
                current_pct = 0.40 + (0.55 * ratio)
                if current_pct - last_reported_pct >= 0.04 or current_pct >= 0.94:
                    last_reported_pct = current_pct
                    print(f"PROGRESS: {current_pct:.2f} | Rendering high-definition invitation video...", flush=True)

    proc.wait()
    if proc.returncode != 0:
        err_msg = "\n".join(err_lines[-15:]) if err_lines else "Unknown FFmpeg error"
        raise RuntimeError(f"FFmpeg failed with exit code {proc.returncode}: {err_msg}")

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
    duration = float(template.get('durationSeconds', 102))
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

    # Map direct fields if sent via standard form
    direct_photo_fields = ['photo_1', 'photo_2', 'photo_3', 'photo_4', 'photo_5', 'womanPhoto', 'manPhoto', 'photo']
    for pf in direct_photo_fields:
        if data.get(pf):
            user_photos[pf] = data.get(pf)
        if data.get(f"{pf}Path"):
            user_photos[pf] = data.get(f"{pf}Path")

    if 'womanPhoto' in user_photos and 'photo_1' not in user_photos:
        user_photos['photo_1'] = user_photos['womanPhoto']
    if 'manPhoto' in user_photos and 'photo_2' not in user_photos:
        user_photos['photo_2'] = user_photos['manPhoto']

    print("PROGRESS: 0.15 | Processing and framing uploaded photographs...", flush=True)

    image_elements = template.get('imageElements', [])
    text_elements = template.get('textElements', [])

    # Filter chains & inputs
    inputs = ['-i', master_video]
    filter_chains = []
    filter_chains.append(f"[0:v]scale={canvas_w}:{canvas_h}:force_original_aspect_ratio=decrease,pad={canvas_w}:{canvas_h}:(ow-iw)/2:(oh-ih)/2,setsar=1[v_canvas]")
    current_stream = "v_canvas"
    input_idx = 1

    # 1. Image Elements
    for idx, img_el in enumerate(image_elements):
        field_name = img_el.get('field', f'photo_{idx+1}')
        target_w = int(img_el.get('width', 500))
        target_h = int(img_el.get('height', 600))
        fit_mode = img_el.get('fit', 'cover')
        st = float(img_el.get('startTime', 0))
        et = float(img_el.get('endTime', duration))
        dur = max(0.5, et - st)
        anim = img_el.get('animationType', 'fade')
        anim_dur = min(dur, float(img_el.get('animationDuration', 1.5)))
        x = int(img_el.get('x', 0))
        y = int(img_el.get('y', 0))
        fade_out = 0.5

        src_path = user_photos.get(field_name) or user_photos.get('photo')
        if not src_path or not os.path.exists(src_path):
            ph = img_el.get('placeholderUrl', '').lstrip('/')
            cand_ph = os.path.join(project_root, ph)
            if os.path.exists(cand_ph):
                src_path = cand_ph
            else:
                cand_default = os.path.join(project_root, 'assets', 'candidate_logo1.png')
                if os.path.exists(cand_default):
                    src_path = cand_default

        out_img_path = os.path.join(temp_dir, f"prep_img_{idx}.png")
        if src_path and os.path.exists(src_path):
            try:
                with Image.open(src_path).convert('RGBA') as raw_img:
                    fitted = fit_image_to_rect(raw_img, target_w, target_h, fit_mode)
                    fitted.save(out_img_path, 'PNG')
            except Exception as e:
                print(f"Error preparing photo {field_name}: {e}")
                Image.new('RGBA', (target_w, target_h), (0, 0, 0, 0)).save(out_img_path, 'PNG')
        else:
            Image.new('RGBA', (target_w, target_h), (0, 0, 0, 0)).save(out_img_path, 'PNG')

        # Add image input (strictly loops for dur seconds)
        inputs.extend(['-loop', '1', '-t', f"{dur:.2f}", '-i', out_img_path])
        img_input_id = input_idx
        input_idx += 1

        mask_video = ink_mask_video if anim == 'ink_reveal' else brush_mask_video
        if anim in ['ink_reveal', 'brush_stroke'] and os.path.exists(mask_video):
            # Mask input strictly runs for dur seconds
            inputs.extend(['-t', f"{dur:.2f}", '-i', mask_video])
            mask_input_id = input_idx
            input_idx += 1

            pts_factor = anim_dur / 2.0
            pad_dur = max(0.0, dur - anim_dur)
            filter_chains.append(
                f"[{mask_input_id}:v]scale={target_w}:{target_h},setpts={pts_factor:.3f}*PTS,tpad=stop_mode=clone:stop_duration={pad_dur:.2f},trim=duration={dur:.2f}[mask_p_{idx}]"
            )
            filter_chains.append(
                f"[{img_input_id}:v][mask_p_{idx}]alphamerge,fade=t=out:st={max(0, dur - fade_out):.2f}:d={fade_out:.2f}:alpha=1,setpts=PTS-STARTPTS+{st:.2f}/TB[img_timed_{idx}]"
            )
        else:
            filter_chains.append(
                f"[{img_input_id}:v]format=rgba,fade=t=in:st=0:d={anim_dur:.2f}:alpha=1,fade=t=out:st={max(0, dur - fade_out):.2f}:d={fade_out:.2f}:alpha=1,setpts=PTS-STARTPTS+{st:.2f}/TB[img_timed_{idx}]"
            )

        next_stream = f"v_img_{idx}"
        filter_chains.append(f"[{current_stream}][img_timed_{idx}]overlay={x}:{y}:enable='between(t,{st:.2f},{et:.2f})'[{next_stream}]")
        current_stream = next_stream

    print("PROGRESS: 0.25 | Rendering custom typography & overlays...", flush=True)

    # 2. Text Elements
    for idx, txt_el in enumerate(text_elements):
        field_key = txt_el.get('field', '')
        text_val = user_data.get(field_key)
        if not text_val:
            if field_key == 'coupleNames':
                text_val = f"{user_data.get('groomName', 'Sai Krishna')} & {user_data.get('brideName', 'Deepika')}"
            else:
                text_val = txt_el.get('defaultText', '')

        if not text_val:
            continue

        st = float(txt_el.get('startTime', 0))
        et = float(txt_el.get('endTime', duration))
        dur = max(0.5, et - st)
        fi = float(txt_el.get('fadeIn', 0.5))
        fo = float(txt_el.get('fadeOut', 0.5))
        cx = int(txt_el.get('x', canvas_w // 2))
        cy = int(txt_el.get('y', canvas_h // 2))

        txt_img, bw, bh = render_text_image(
            str(text_val),
            txt_el.get('fontFamily', 'Cinzel'),
            int(txt_el.get('fontSize', 40)),
            txt_el.get('fontColor', '#FFD700'),
            txt_el.get('textAlign', 'center')
        )
        out_txt_path = os.path.join(temp_dir, f"prep_txt_{idx}.png")
        txt_img.save(out_txt_path, 'PNG')

        align = txt_el.get('textAlign', 'center')
        if align == 'left':
            ox = cx
        elif align == 'right':
            ox = cx - bw
        else:
            ox = cx - (bw // 2)
        oy = cy - (bh // 2)

        inputs.extend(['-loop', '1', '-t', f"{dur:.2f}", '-i', out_txt_path])
        txt_input_id = input_idx
        input_idx += 1

        filter_chains.append(
            f"[{txt_input_id}:v]format=rgba,fade=t=in:st=0:d={fi:.2f}:alpha=1,fade=t=out:st={max(0, dur - fo):.2f}:d={fo:.2f}:alpha=1,setpts=PTS-STARTPTS+{st:.2f}/TB[txt_timed_{idx}]"
        )
        next_stream = f"v_txt_{idx}"
        filter_chains.append(f"[{current_stream}][txt_timed_{idx}]overlay={ox}:{oy}:enable='between(t,{st:.2f},{et:.2f})'[{next_stream}]")
        current_stream = next_stream

    filter_complex = ';'.join(filter_chains)

    cmd = [
        ffmpeg_bin, '-y',
        *inputs,
        '-filter_complex', filter_complex,
        '-map', f"[{current_stream}]",
        '-map', '0:a?',
        '-c:v', 'libx264',
        '-preset', 'ultrafast',
        '-threads', '0',
        '-pix_fmt', 'yuv420p',
        '-c:a', 'aac',
        '-b:a', '192k',
        '-t', str(duration),
        output_video
    ]

    try:
        run_ffmpeg_with_progress(cmd, total_duration_sec=duration)
    finally:
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
