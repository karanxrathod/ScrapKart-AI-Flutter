# 📦 ScrapKart AI — Releases

This directory contains the latest production-ready APK builds for the **ScrapKart AI** ecosystem.

---

## 📱 Download APKs

| App | Version | Size | Download |
|---|---|---|---|
| **ScrapKart AI** (User App) | v1.0.0 | 58.3 MB | [`scrapkart-ai-user-app-v1.0.0.apk`](./scrapkart-ai-user-app-v1.0.0.apk) |
| **ScrapKart Collector** | v1.0.0 | 49.1 MB | [`scrapkart-collector-app-v1.0.0.apk`](./scrapkart-collector-app-v1.0.0.apk) |

---

## 📲 Installation Guide

> **Note:** These are Android APKs. You must enable **"Install from Unknown Sources"** on your device before installing.

### Step 1 — Enable Unknown Sources
Go to **Settings → Security → Install Unknown Apps** and enable it for your file manager or browser.

### Step 2 — Download the APK
Tap the download link above from your Android device, or transfer it via WhatsApp/Telegram/USB cable.

### Step 3 — Install
Tap the downloaded `.apk` file and follow the on-screen prompts.

---

## 📋 App Overview

### 🛒 ScrapKart AI — User App
The main app for households and businesses to manage scrap.

**Features:**
- 🤖 **AI Scrap Scanner** — Gemini Vision API identifies scrap type, estimates price per kg, and classifies material (works offline too via color analysis)
- 🏠 **Offline First** — Donation dashboard, NGO data, and Eco-Coin tracking work completely offline
- 📍 **Real-time Pickup Tracking** — Live GPS map tracking of collector via WebSockets
- 🔢 **OTP Verification** — Secure 4-digit OTP confirmation for completed pickups
- 🪙 **Eco-Coins & Gamification** — Earn coins for every kg sold or donated; track CO₂ saved
- 🌍 **NGO Transparency Hub** — See live progress bars for partner NGO campaigns
- 🏆 **Leaderboard** — Compete with other eco-warriors in your city
- 💬 **AI Chatbot** — Powered by Gemini 2.5 Flash for instant scrap pricing help
- 💰 **Digital Wallet** — Track earnings and transaction history

---

### 🚛 ScrapKart Collector — Collector App
Designed for scrap collectors and drivers to manage their pickup workflow.

**Features:**
- 📋 **Dashboard** — View assigned pickups and job status at a glance
- 🗺️ **Pickup Map** — Navigate to pickup locations with integrated maps
- 📡 **Real-time GPS Emission** — Broadcasts live location to the user via WebSocket
- 🔢 **OTP Verification** — Collectors must verify the OTP before marking a job complete
- 🔔 **Push Notifications** — Firebase Cloud Messaging for new job alerts
- 📊 **Earnings Tracker** — Monitor daily and weekly earnings

---

## 🔧 Technical Stack

| Layer | Technology |
|---|---|
| **User App** | Flutter 3.x, Riverpod v2, Dio, Socket.io, Firebase |
| **Collector App** | Flutter 3.x, Google Maps, Geolocator, Socket.io, FCM |
| **Backend** | Node.js + Express, MySQL, Socket.io, JWT, node-cron |
| **AI** | Google Gemini 2.5 Flash (Vision + Chat) |
| **Offline AI** | Image pixel color-analysis classifier (zero model files) |
| **Infrastructure** | Docker + docker-compose, GitHub Actions CI/CD |

---

## 🌐 Backend Setup

The backend runs on Node.js with MySQL. To start it locally:

```bash
# Option 1: With Docker (recommended)
docker compose up -d --build

# Option 2: Direct Node.js
cd backend
npm install
node server.js
```

The server runs at `http://localhost:3000`.

---

## 📁 Repository Structure

```
ScrapKart-AI-Flutter/
├── 📱 scrapkart_ai/         # User App (Flutter)
├── 🚛 scrapkart_collector/  # Collector App (Flutter)
├── ⚙️  backend/             # Node.js REST API + WebSocket Server
├── 🖥️  admin_dashboard/     # Next.js Admin Panel
├── 📦 releases/             # ← You are here (APK downloads)
├── 🐳 docker-compose.yml    # One-command deployment
└── 🔄 .github/workflows/    # CI/CD automation
```

---

## 📬 Contact

**Developer:** Karan Rathod  
**GitHub:** [@karanxrathod](https://github.com/karanxrathod)  
**Repository:** [ScrapKart-AI-Flutter](https://github.com/karanxrathod/ScrapKart-AI-Flutter)

---

*Built with ❤️ for a cleaner Nashik — and a greener planet! 🌱*
