from enum import Enum
from typing import List, Optional, Dict, Any
from pydantic import BaseModel, Field

class PersonaType(str, Enum):
    HEALTH = "health"
    FITNESS = "fitness"
    FARM = "farm"
    BEACH = "beach"
    COMMUTE = "commute"

class WeatherTelemetry(BaseModel):
    latitude: float
    longitude: float
    city_name: str
    timezone: str = "auto"
    current_temperature: float
    apparent_temperature: float
    weather_code: int
    weather_condition: str
    relative_humidity: int
    wind_speed_10m: float
    wind_direction_10m: float
    wind_direction_cardinal: str
    wind_gusts_10m: float
    surface_pressure: float
    uv_index: float
    cloud_cover: int
    precipitation: float
    rain: float
    soil_moisture_0_to_7cm: float
    evapotranspiration: float
    visibility: float
    aqi: int
    pm2_5: float
    pm10: float
    carbon_monoxide: Optional[float] = None
    nitrogen_dioxide: Optional[float] = None
    ozone: Optional[float] = None
    dust: Optional[float] = None
    alder_pollen: float = 0.0
    birch_pollen: float = 0.0
    grass_pollen: float = 0.0
    ragweed_pollen: float = 0.0
    wave_height: Optional[float] = None
    wave_period: Optional[float] = None
    wave_direction: Optional[float] = None
    wind_wave_height: Optional[float] = None
    swell_wave_height: Optional[float] = None

class DerivedScores(BaseModel):
    workout_score: int = Field(..., ge=0, le=100)
    optimal_running_window: str
    hourly_workout_scores: List[int] = []
    irrigation_advice: str
    agricultural_deficit_mm: float
    commute_hazard_rating: int = Field(..., ge=0, le=100)
    commute_condition: str
    mold_risk_level: str
    heat_index_celsius: float

class Tier1Alert(BaseModel):
    id: str
    title: str
    severity: str  # "critical", "warning", "advisory", "info"
    description: str
    icon: str
    timestamp: str

class PersonaSlotMetric(BaseModel):
    slot_index: int
    title: str
    value: str
    subtitle: str
    status: str
    icon_name: str
    color_hex: str
    progress_percentage: Optional[float] = None

class Tier2PersonaInsights(BaseModel):
    persona: PersonaType
    persona_title: str
    persona_subtitle: str
    advisory_summary: str
    action_bullet: str
    slots: List[PersonaSlotMetric]

class HourlyForecastItem(BaseModel):
    time: str
    time_label: str
    temperature: float
    precipitation_probability: int
    precipitation_mm: float
    weather_code: int
    weather_condition: str
    is_day: bool
    icon_name: str

class DailyForecastItem(BaseModel):
    date: str
    day_name: str
    temperature_max: float
    temperature_min: float
    weather_code: int
    weather_condition: str
    precipitation_sum_mm: float
    precipitation_probability_max: int
    uv_index_max: float
    sunrise: str
    sunset: str
    icon_name: str

class Tier3Baseline(BaseModel):
    hourly_forecast: List[HourlyForecastItem]
    daily_forecast: List[DailyForecastItem]

class ComprehensiveWeatherResponse(BaseModel):
    telemetry: WeatherTelemetry
    derived: DerivedScores
    tier1_alerts: List[Tier1Alert]
    tier2_insights: Tier2PersonaInsights
    tier3_baseline: Tier3Baseline

class CityGeocodingResult(BaseModel):
    id: int
    name: str
    latitude: float
    longitude: float
    country: str
    admin1: Optional[str] = None
    country_code: Optional[str] = None

class AdvisorChatRequest(BaseModel):
    message: str
    persona: Optional[PersonaType] = PersonaType.HEALTH
    weather_context: Optional[Dict[str, Any]] = None

class AdvisorChatResponse(BaseModel):
    reply: str
    persona: str
    action_items: List[str] = []
    relevant_metrics: Optional[Dict[str, Any]] = None
