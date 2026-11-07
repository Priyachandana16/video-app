# My Invitation - Localhost Setup & Sharing Guide

This guide explains how to run the complete **My Invitation** ecosystem on your computer (`localhost`).

---

## ⚡ Quick 1-Click Launch (Windows)

You do **not** need to install Flutter or Android Studio. The web client is pre-compiled and ready to run.

### Prerequisites (Only Need 2 Tools)
1. **Node.js** (v18 or higher): [Download Node.js](https://nodejs.org/)
2. **Python** (v3.10 or higher): [Download Python](https://www.python.org/) *(Make sure to check "Add python.exe to PATH" during installation)*

---

### Step 1: Install Dependencies (First time only)
Double-click:
```text
install_dependencies.bat
```
*(This automatically installs backend packages, admin packages, and Python Pillow for the video rendering engine).*

---

### Step 2: Start All Services
Double-click:
```text
start_all.bat
```
This script automatically starts all 3 servers in their own windows and opens your browser:
* 🌐 **Flutter Web App**: [http://localhost:8085](http://localhost:8085)
* 🛠️ **Admin Studio**: [http://localhost:3001](http://localhost:3001)
* ⚙️ **Backend API**: [http://localhost:5000](http://localhost:5000)

To stop all servers at any time, double-click `stop_all.bat`.

---

## 🍎 Mac / Linux Users

1. Open Terminal in the project root:
   ```bash
   cd backend && npm install && cd ..
   cd admin-dashboard && npm install && cd ..
   pip3 install Pillow
   ```
2. Make script executable and run:
   ```bash
   chmod +x start_all.sh
   ./start_all.sh
   ```
3. Open in your browser:
   * [http://localhost:8085](http://localhost:8085)
   * [http://localhost:3001](http://localhost:3001)

---

## 📱 How to Access from Another Device on the Same Wi-Fi
If you want to open the invitation app on a phone or another laptop connected to the same Wi-Fi router:
1. Find your computer's local IP address (e.g., `192.168.29.211`).
2. Open on the phone's browser:
   * `http://<YOUR_IP>:8085` (Flutter Web App)
   * `http://<YOUR_IP>:3001` (Admin Studio)

