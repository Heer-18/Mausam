import os
import uvicorn
from fastapi import FastAPI, Query, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from dotenv import load_dotenv

from .models.schemas import (
    PersonaType,
    ComprehensiveWeatherResponse,
    AdvisorChatRequest,
    AdvisorChatResponse,
    CityGeocodingResult
)
from .services.weather_service import OpenMeteoService
from .services.gemini_service import GeminiAdvisorService

load_dotenv()

app = FastAPI(
    title="Mausam AI Backend Service",
    description="High-performance meteorological ingestion, math derivation, and persona intelligence engine for Mausam app",
    version="1.0.0"
)

# Enable CORS for Flutter mobile/web/desktop clients
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

gemini_service = GeminiAdvisorService()

@app.get("/")
async def root():
    return {
        "service": "Mausam AI Backend",
        "status": "operational",
        "version": "1.0.0",
        "endpoints": ["/api/weather", "/api/advisor/chat", "/api/cities"]
    }

@app.get("/health")
async def health_check():
    return {"status": "healthy"}

@app.get("/api/weather", response_model=ComprehensiveWeatherResponse)
async def get_weather(
    lat: float = Query(..., description="Latitude of target location"),
    lon: float = Query(..., description="Longitude of target location"),
    persona: PersonaType = Query(PersonaType.HEALTH, description="Active user lifestyle persona"),
    city: str = Query("Selected Location", description="Display city name")
):
    """
    Combines live Open-Meteo feeds (Forecast, Soil, AQI, Marine),
    runs the Mathematical Derivation Engine, and returns structured Tier 1, 2, and 3 data.
    """
    try:
        response = await OpenMeteoService.fetch_weather_bundle(
            lat=lat,
            lon=lon,
            city_name=city,
            persona=persona
        )
        return response
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to fetch weather telemetry: {str(e)}")

@app.post("/api/advisor/chat", response_model=AdvisorChatResponse)
async def chat_with_advisor(request: AdvisorChatRequest):
    """
    Provides Gemini 2.5 Flash persona-tailored natural language advice
    injected with live weather parameters and fallback resilience.
    """
    try:
        persona = request.persona or PersonaType.HEALTH
        response = await gemini_service.generate_advice(
            message=request.message,
            persona=persona,
            weather_context=request.weather_context
        )
        return response
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Advisor service error: {str(e)}")

@app.get("/api/cities", response_model=list[CityGeocodingResult])
async def search_cities(
    query: str = Query(..., min_length=1, description="City name or prefix to search")
):
    """
    Searches matching locations using Open-Meteo Geocoding.
    """
    try:
        results = await OpenMeteoService.fetch_geocoding(query=query)
        return results
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Geocoding search error: {str(e)}")

if __name__ == "__main__":
    port = int(os.getenv("PORT", 8000))
    host = os.getenv("HOST", "0.0.0.0")
    uvicorn.run("backend.main:app", host=host, port=port, reload=True)
