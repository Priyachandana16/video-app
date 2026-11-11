FROM node:20-bullseye-slim

# Install system dependencies: Python3, pip, PIL, FFmpeg, fonts
RUN apt-get update && apt-get install -y --no-install-recommends \
    python3 \
    python3-pip \
    python3-pil \
    ffmpeg \
    fonts-dejavu-core \
    fonts-freefont-ttf \
    curl \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Copy dependency definitions
COPY package*.json ./

# Install npm dependencies
RUN npm install --production

# Copy backend source code
COPY . .

# Set environment variables
ENV PORT=5000
ENV NODE_ENV=production

EXPOSE 5000

# Start backend server
CMD ["node", "server.js"]

