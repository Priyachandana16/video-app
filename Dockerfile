FROM node:22-bookworm-slim

# Install system dependencies: Python3, PIL, FFmpeg, fonts
RUN apt-get update && apt-get install -y --no-install-recommends \
    python3 \
    python-is-python3 \
    python3-pil \
    ffmpeg \
    fonts-dejavu-core \
    fonts-freefont-ttf \
    fonts-noto-core \
    curl \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Copy backend dependencies
COPY backend/package*.json ./

# Install npm dependencies
RUN npm install --production

# Copy backend files and root assets
COPY backend/ ./
COPY assets/ ./assets/

ENV PORT=5000
ENV NODE_ENV=production
ENV PYTHONIOENCODING=utf-8
ENV LANG=C.UTF-8
ENV LC_ALL=C.UTF-8

EXPOSE 5000

CMD ["node", "server.js"]
