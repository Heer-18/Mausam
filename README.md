# 🌦️ Mausam — Personalized AI Weather & Lifestyle Intelligence

A modern, high-performance meteorological intelligence platform featuring hyper-local weather forecasting, persona-based lifestyle insights (Fitness, Agriculture, Commute, Beach, Outdoor Work, Family), interactive weather radar maps, and Gemini AI natural language meteorological assistance.

🌐 **Live Web App**: [https://heer-18.github.io/Mausam/](https://heer-18.github.io/Mausam/)

---

## ✨ Key Features

- **🎯 Persona-Tailored Intelligence**: 8+ specialized lifestyles (Health, Fitness & Running, Agriculture & Farming, Beach & Surfing, Daily Commute, Travel, Event Planning, Outdoor Work).
- **🧮 Mathematical Derivation Engine**:
  - Workout Safety Score & Optimal Running Hour Window
  - Soil Moisture, Evapotranspiration & Agricultural Deficit
  - Mold & Fungal Risk Indices
  - Commute Hazard & Road Traction Ratings
- **🗺️ Interactive Weather Map**: Live tile overlays, precipitation radar, and animated wind currents.
- **🤖 Mausam AdvisorAI**: Powered by Google Gemini 2.5 Flash for natural language weather advice and safety recommendations.
- **⚡ Offline-First Architecture**: Intelligent local caching with mathematical fallback engines.

---

## 🏗️ Architecture

- **Frontend**: Flutter (Web, Android, iOS, Windows)
- **Backend API**: Python FastAPI + Open-Meteo Weather APIs (Forecast, Marine, Air Quality, Geocoding)
- **AI Engine**: Google Gemini Flash API (`google-genai` / `google_generative_ai`)

---

## 🚀 Running Locally

### 1. Clone & Setup
```bash
git clone https://github.com/Heer-18/Mausam.git
cd Mausam
```

### 2. Configure Environment Keys
Copy the template files and insert your Gemini API Key:
```bash
# In project root
copy .env.example .env

# In mobile_app folder
cd mobile_app
copy .env.example .env
cd ..
```

### 3. Start the Backend API (Terminal 1)
```bash
pip install fastapi uvicorn httpx python-dotenv google-genai
uvicorn backend.main:app --reload --port 8000
```

### 4. Start Flutter App (Terminal 2)
```bash
cd mobile_app
flutter pub get
flutter run -d chrome    # For Web
# or
flutter run -d windows   # For Windows Desktop
```

---

## 🧪 Testing

```bash
cd mobile_app
flutter test
```
