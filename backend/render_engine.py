import sys
import os
import json
import subprocess
import cv2
import numpy as np
from PIL import Image, ImageDraw, ImageFont

def get_ffmpeg_path():
    # Check node_modules installer
    candidate = os.path.join(os.path.dirname(__file__), 'node_modules', '@ffmpeg-installer', 'win32-x64', 'ffmpeg.exe')
    if os.path.exists(candidate):
        return candidate
    return 'ffmpeg'

def render_invitation(config_path):
    with open(config_path, 'r', encoding='utf-8') as f:
        data = json.load(f)

    master_video = data.get('masterVideoPath', 'assets/wedding_template_master.mp4')
    output_video = data.get('outputVideoPath', 'assets/personalized_output.mp4')
    has_photo = data.get('hasPhoto', True)
    photo_path = data.get('photoPath')

    bride_name = data.get('brideName', 'Ananya')
    groom_name = data.get('groomName', 'Rajesh')
    couple_title = f"{groom_name}  &  {bride_name}"
    parents_names = data.get('parentsNames', 'Smt. Lakshmi & Sri. Venkat Rao')
    ceremony_title = data.get('ceremonyTitle', 'Shubh Vivaham')
    event_date = data.get('eventDate', 'Sunday, 15 December 2026')
    muhurtham_time = data.get('muhurthamTime', 'Muhurtham: 09:45 AM')
    venue = data.get('venue', 'The Grand Chola Palace, Chennai')
    rsvp = data.get('rsvp', 'With Best Compliments from Family & Friends')

    if not os.path.isabs(master_video):
        master_video = os.path.abspath(master_video)
    if not os.path.isabs(output_video):
        output_video = os.path.abspath(output_video)
    if photo_path and not os.path.isabs(photo_path):
        photo_path = os.path.abspath(photo_path)

    os.makedirs(os.path.dirname(output_video), exist_ok=True)

    cap = cv2.VideoCapture(master_video)
    if not cap.isOpened():
        print(f"ERROR: Cannot open master video at {master_video}", file=sys.stderr)
        sys.exit(1)

    fps = cap.get(cv2.CAP_PROP_FPS) or 30.0
    width = int(cap.get(cv2.CAP_PROP_FRAME_WIDTH))
    height = int(cap.get(cv2.CAP_PROP_FRAME_HEIGHT))
    total_frames = int(cap.get(cv2.CAP_PROP_FRAME_COUNT))

    # Write intermediate raw file
    raw_temp_video = output_video + ".raw.mp4"
    fourcc = cv2.VideoWriter_fourcc(*'mp4v')
    out = cv2.VideoWriter(raw_temp_video, fourcc, fps, (width, height))

    # Prepare photo overlay if enabled and photo file exists
    photo_img = None
    if has_photo and photo_path and os.path.exists(photo_path):
        try:
            raw_photo = Image.open(photo_path).convert('RGBA')
            size = min(360, width - 80)
            raw_photo = raw_photo.resize((size, size), Image.Resampling.LANCZOS)
            mask = Image.new('L', (size, size), 0)
            draw_m = ImageDraw.Draw(mask)
            draw_m.ellipse((0, 0, size, size), fill=255)
            raw_photo.putalpha(mask)
            photo_img = raw_photo
        except Exception as e:
            print(f"Warning loading photo: {e}", file=sys.stderr)

    # Fonts
    font_serif = None
    font_serif_lg = None
    font_sans = None
    font_sans_sm = None
    try:
        font_serif = ImageFont.truetype("georgia.ttf", 36)
        font_serif_lg = ImageFont.truetype("georgia.ttf", 44)
        font_sans = ImageFont.truetype("arial.ttf", 24)
        font_sans_sm = ImageFont.truetype("arial.ttf", 20)
    except Exception:
        font_serif = ImageFont.load_default()
        font_serif_lg = ImageFont.load_default()
        font_sans = ImageFont.load_default()
        font_sans_sm = ImageFont.load_default()

    processed_frames = 0
    while True:
        ret, frame = cap.read()
        if not ret:
            break

        t = processed_frames / fps

        # Convert to PIL Image for typography
        frame_rgb = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
        pil_img = Image.fromarray(frame_rgb)
        draw = ImageDraw.Draw(pil_img)

        # 0.0 - 3.0s: Master Video with subtle ceremonial introduction
        if 0.5 <= t < 3.0:
            fade = min(1.0, (t - 0.5) / 0.5) if t < 1.0 else (min(1.0, (3.0 - t) / 0.5) if t > 2.5 else 1.0)
            gold_color = (int(245 * fade), int(184 * fade), int(46 * fade))
            champ_color = (int(246 * fade), int(217 * fade), int(139 * fade))
            draw.text((width // 2, height // 2 - 40), "Cordially Invites You To", fill=champ_color, font=font_sans, anchor='mm')
            draw.text((width // 2, height // 2 + 10), ceremony_title, fill=gold_color, font=font_serif_lg, anchor='mm')

        # 3.0 - 6.5s: Couple Names & Auspicious Blessing
        elif 3.0 <= t < 6.5:
            fade = min(1.0, (t - 3.0) / 0.5) if t < 3.5 else (min(1.0, (6.5 - t) / 0.5) if t > 6.0 else 1.0)
            gold_color = (int(245 * fade), int(184 * fade), int(46 * fade))
            champ_color = (int(246 * fade), int(217 * fade), int(139 * fade))
            draw.text((width // 2, height // 2 - 60), ceremony_title, fill=champ_color, font=font_sans, anchor='mm')
            draw.text((width // 2, height // 2), couple_title, fill=gold_color, font=font_serif_lg, anchor='mm')
            if rsvp:
                draw.text((width // 2, height // 2 + 60), rsvp, fill=(int(200 * fade), int(190 * fade), int(180 * fade)), font=font_sans_sm, anchor='mm')

        # 6.5 - 9.5s: Couple Photo OR Elegant Traditional Blessing (Without Photo)
        elif 6.5 <= t < 9.5:
            fade = min(1.0, (t - 6.5) / 0.5) if t < 7.0 else (min(1.0, (9.5 - t) / 0.5) if t > 9.0 else 1.0)
            gold_color = (int(245 * fade), int(184 * fade), int(46 * fade))
            champ_color = (int(246 * fade), int(217 * fade), int(139 * fade))

            if has_photo and photo_img:
                # WITH PHOTO LAYOUT: circular gold halo framed couple photo
                px = (width - photo_img.width) // 2
                py = (height - photo_img.height) // 2 - 50
                draw.ellipse((px - 8, py - 8, px + photo_img.width + 8, py + photo_img.height + 8), outline=gold_color, width=3)
                pil_img.paste(photo_img, (px, py), photo_img)
                draw.text((width // 2, height // 2 + 190), couple_title, fill=gold_color, font=font_serif, anchor='mm')
                draw.text((width // 2, height // 2 + 230), "United in Love & Harmony", fill=(246, 217, 139), font=font_sans_sm, anchor='mm')
            else:
                # WITHOUT PHOTO LAYOUT: elegant ceremonial family blessing (no empty photo frame!)
                # Auspicious decorative lines
                draw.line([(width // 2 - 120, height // 2 - 90), (width // 2 + 120, height // 2 - 90)], fill=gold_color, width=2)
                draw.text((width // 2, height // 2 - 60), "With Divine Blessings of Elders", fill=champ_color, font=font_sans, anchor='mm')
                if parents_names:
                    draw.text((width // 2, height // 2 - 15), parents_names, fill=gold_color, font=font_serif, anchor='mm')
                draw.text((width // 2, height // 2 + 35), "Cordially Request the Honour of Your Presence", fill=champ_color, font=font_sans_sm, anchor='mm')
                draw.text((width // 2, height // 2 + 75), "At the Celebrations of", fill=champ_color, font=font_sans_sm, anchor='mm')
                draw.text((width // 2, height // 2 + 115), couple_title, fill=gold_color, font=font_serif_lg, anchor='mm')
                draw.line([(width // 2 - 120, height // 2 + 155), (width // 2 + 120, height // 2 + 155)], fill=gold_color, width=2)

        # 9.5 - 12.0s: Event Muhurtham, Date, Venue & Blessing
        elif 9.5 <= t <= 12.0:
            fade = min(1.0, (t - 9.5) / 0.5) if t < 10.0 else (min(1.0, (12.0 - t) / 0.5) if t > 11.5 else 1.0)
            gold_color = (int(245 * fade), int(184 * fade), int(46 * fade))
            champ_color = (int(246 * fade), int(217 * fade), int(139 * fade))
            draw.text((width // 2, height // 2 - 70), event_date, fill=gold_color, font=font_serif, anchor='mm')
            draw.text((width // 2, height // 2 - 20), muhurtham_time, fill=champ_color, font=font_sans, anchor='mm')
            draw.text((width // 2, height // 2 + 30), venue, fill=(240, 240, 240), font=font_sans, anchor='mm')
            draw.text((width // 2, height // 2 + 80), "Kindly Grace The Occasion", fill=champ_color, font=font_sans_sm, anchor='mm')

        # Convert back to BGR and write frame
        out_frame = cv2.cvtColor(np.array(pil_img), cv2.COLOR_RGB2BGR)
        out.write(out_frame)
        processed_frames += 1

    cap.release()
    out.release()

    # Transcode raw output to genuine H.264 (yuv420p + faststart) for full web and mobile compatibility
    ffmpeg_bin = get_ffmpeg_path()
    cmd = [
        ffmpeg_bin, '-y',
        '-i', raw_temp_video,
        '-c:v', 'libx264',
        '-preset', 'fast',
        '-crf', '22',
        '-pix_fmt', 'yuv420p',
        '-movflags', '+faststart',
        output_video
    ]
    try:
        subprocess.run(cmd, check=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
        if os.path.exists(raw_temp_video):
            os.remove(raw_temp_video)
        print(f"SUCCESS: Rendered and encoded {processed_frames} frames to H.264 at {output_video}")
    except Exception as e:
        print(f"FFmpeg transcode warning: {e}, falling back to raw file", file=sys.stderr)
        if os.path.exists(raw_temp_video):
            os.replace(raw_temp_video, output_video)

if __name__ == '__main__':
    if len(sys.argv) < 2:
        print("Usage: python render_engine.py <config.json>")
        sys.exit(1)
    render_invitation(sys.argv[1])
