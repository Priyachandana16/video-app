#!/usr/bin/env bash
# My Invitation - Unix / Mac / Linux Startup Script

echo "========================================================"
echo "       MY INVITATION - 1-CLICK LOCALHOST RUNNER        "
echo "========================================================"
echo ""

# 1. Backend Server
echo "[1/3] Starting Backend API Server (Port 5000)..."
node backend/server.js &
BACKEND_PID=$!

# 2. Flutter Web Client
echo "[2/3] Starting Flutter Web Client (Port 8085)..."
node serve_web.js &
WEB_PID=$!

# 3. Admin Studio
echo "[3/3] Starting Admin Studio (Port 3001)..."
cd admin-dashboard && npx next dev --turbo -p 3001 &
ADMIN_PID=$!
cd ..

echo ""
echo "All 3 services are running!"
echo "  Flutter Web App : http://localhost:8085"
echo "  Admin Studio    : http://localhost:3001"
echo "  Backend API     : http://localhost:5000"
echo ""
echo "Press Ctrl+C to stop all services."

trap "kill $BACKEND_PID $WEB_PID $ADMIN_PID 2>/dev/null; exit" SIGINT SIGTERM
wait

