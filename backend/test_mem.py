import subprocess
import time
import os
import psutil

# Test memory of current render_engine
cmd = ['python', 'backend/render_engine.py', 'backend/test_5_photos.json']
proc = subprocess.Popen(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE)

p = psutil.Process(proc.pid)
max_mem = 0
ffmpeg_max_mem = 0

while proc.poll() is None:
    try:
        children = p.children(recursive=True)
        total_mem = p.memory_info().rss
        for c in children:
            m = c.memory_info().rss
            total_mem += m
            if 'ffmpeg' in c.name().lower():
                ffmpeg_max_mem = max(ffmpeg_max_mem, m)
        max_mem = max(max_mem, total_mem)
    except Exception:
        pass
    time.sleep(0.5)

out, err = proc.communicate()
print(f"Max total memory: {max_mem / (1024*1024):.1f} MB")
print(f"Max FFmpeg memory: {ffmpeg_max_mem / (1024*1024):.1f} MB")

