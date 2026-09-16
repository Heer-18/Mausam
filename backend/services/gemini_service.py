import os
from typing import Dict, Any, Optional, List
from dotenv import load_dotenv
try:
    from backend.models.schemas import PersonaType, AdvisorChatResponse
except ImportError:
    try:
        from ..models.schemas import PersonaType, AdvisorChatResponse
    except (ImportError, ValueError):
        from models.schemas import PersonaType, AdvisorChatResponse

load_dotenv()

class GeminiAdvisorService:
    def __init__(self):
        self.api_key = os.getenv("GEMINI_API_KEY") or os.getenv("VITE_GEMINI_API_KEY") or ""
        self.client = None
        self._init_client()

    def _init_client(self):
        if not self.api_key:
            return
        try:
            from google import genai
            self.client = genai.Client(api_key=self.api_key)
        except Exception as e:
            print(f"Failed to initialize google-genai client: {e}")
            self.client = None

    async def generate_advice(
        self,
        message: str,
        persona: PersonaType,
        weather_context: Optional[Dict[str, Any]] = None
    ) -> AdvisorChatResponse:
        """
        Generates empathetic, persona-tailored advice (2-3 concise sentences)
        with live meteorological context injection.
        """
        ctx = weather_context or {}
        location = ctx.get("city_name", "Selected Location")
        temp = ctx.get("temperature", 28.0)
        humidity = ctx.get("humidity", 65)
        aqi = ctx.get("aqi", 42)
        rain_prob = ctx.get("rain_probability", 10)
        wind_speed = ctx.get("wind_speed", 12.0)
        uv_index = ctx.get("uv_index", 5.0)
        soil_moisture = ctx.get("soil_moisture", 0.24)
        wave_height = ctx.get("wave_height", 1.2)

        # Attempt Gemini 2.5 Flash call
        if self.client and self.api_key:
            try:
                system_instruction = (
                    f"You are Mausam AdvisorAI, an expert hyper-local meteorological and lifestyle intelligence assistant. "
                    f"Live Context: Location: {location}, Active Persona: {persona.value}, Temperature: {temp}°C, "
                    f"Humidity: {humidity}%, AQI: {aqi}, Rain Probability: {rain_prob}%, Wind: {wind_speed} km/h, "
                    f"UV Index: {uv_index}, Soil Moisture: {soil_moisture} m³/m³, Wave Height: {wave_height}m. "
                    f"STRICT RULES: Respond in exactly 2–3 concise, empathetic, and actionable sentences tailored directly to the {persona.value} persona. "
                    f"Use relevant emojis (🏃, 🌾, 🌊, 🚗, ☀️, ☔) where helpful. Focus on practical safety, timing, or planning decisions."
                )

                prompt = f"User asks: {message}"

                response = self.client.models.generate_content(
                    model='gemini-3.6-flash',
                    contents=prompt,
                    config={
                        'system_instruction': system_instruction,
                        'temperature': 0.4,
                    }
                )

                if response and response.text:
                    reply_text = response.text.strip()
                    return AdvisorChatResponse(
                        reply=reply_text,
                        persona=persona,
                        offline_fallback_used=False,
                        action_items=self._extract_action_items(reply_text, persona)
                    )
            except Exception as e:
                print(f"Gemini API call failed, falling back to rule-based engine: {e}")

        # Fallback to deterministic rule-based engine
        return self._offline_rule_based_advice(message, persona, ctx)

    def _offline_rule_based_advice(
        self,
        message: str,
        persona: PersonaType,
        ctx: Dict[str, Any]
    ) -> AdvisorChatResponse:
        temp = ctx.get("temperature", 28.0)
        humidity = ctx.get("humidity", 65)
        aqi = ctx.get("aqi", 42)
        rain_prob = ctx.get("rain_probability", 10)
        uv_index = ctx.get("uv_index", 5.0)
        soil_m = ctx.get("soil_moisture", 0.24)
        wave_h = ctx.get("wave_height", 1.2)

        msg_lower = message.lower()

        if persona == PersonaType.FITNESS or "run" in msg_lower or "workout" in msg_lower:
            if temp > 30 or humidity > 75:
                reply = f"🏃 Outdoor conditions are warm ({int(temp)}°C, {humidity}% humidity). The best window for running is early morning between 6:00 AM – 7:30 AM when temperatures are cooler. Keep your hydration at 500ml/hour."
            else:
                reply = f"🏃 Conditions are prime for training right now with moderate temp ({int(temp)}°C) and clean air (AQI {aqi}). The optimal workout window is available this morning with zero rain risk."
            actions = ["Hydrate with electrolytes", "Plan run before 8:00 AM", "Wear light reflective gear"]

        elif persona == PersonaType.FARM or "water" in msg_lower or "crop" in msg_lower or "soil" in msg_lower:
            if rain_prob > 50:
                reply = f"🌱 Rain probability is high today ({rain_prob}%). Hold scheduled irrigation cycles as natural precipitation will replenish soil moisture ({soil_m:.2f} m³/m³)."
            elif soil_m < 0.22:
                reply = f"🌱 Soil moisture at root depth is currently low ({soil_m:.2f} m³/m³). Recommended to run a 25-minute micro-irrigation cycle during early morning or late evening."
            else:
                reply = f"🌱 Soil moisture is in the optimal range ({soil_m:.2f} m³/m³) and ET deficit is manageable. No immediate irrigation required today."
            actions = ["Monitor soil saturation", "Hold chemical spraying if wind > 15 km/h", "Protect open seedling beds"]

        elif persona == PersonaType.BEACH or "surf" in msg_lower or "swim" in msg_lower:
            reply = f"🌊 Current wave height is {wave_h:.1f}m with favorable offshore winds. UV Index is {int(uv_index)} (High), so reapply waterproof SPF 50+ sunscreen every 90 minutes."
            actions = ["Apply SPF 50+ sunscreen", "Check local beach flag warnings", "Watch afternoon gust shifts"]

        elif persona == PersonaType.COMMUTE or "traffic" in msg_lower or "drive" in msg_lower:
            if rain_prob > 50:
                reply = f"🚗 Rain is forecasted with potential wet road slickness. Allow an extra 10–15 minutes for your commute and maintain safe following distance."
            else:
                reply = f"🚗 Road visibility is excellent (>8 km) and weather conditions are completely clear for transit. Standard commute times expected along major corridors."
            actions = ["Maintain safe braking distance", "Keep headlight beam on low in rain", "Monitor live traffic updates"]

        elif persona == PersonaType.HEALTH or "allergy" in msg_lower or "skin" in msg_lower or "aqi" in msg_lower:
            reply = f"🌿 AQI is currently {aqi} ({'Good' if aqi <= 50 else 'Moderate'}). UV Index is {int(uv_index)}, requiring a hat and sunglasses if outdoors during peak midday hours."
            actions = ["Wear SPF 30+ protection", "Air purifier recommended if AQI > 100", "Hydrate frequently"]

        else:
            reply = f"🌤️ Current temperature is {int(temp)}°C with {humidity}% humidity and AQI {aqi}. Overall conditions are favorable for daily routines—stay hydrated and enjoy your day!"
            actions = ["Check 24-hour forecast trends", "Dress in comfortable layers", "Carry sunglasses"]

        return AdvisorChatResponse(
            reply=reply,
            persona=persona,
            offline_fallback_used=True,
            action_items=actions
        )

    def _extract_action_items(self, reply: str, persona: PersonaType) -> List[str]:
        defaults = {
            PersonaType.HEALTH: ["Wear SPF 30+ sunscreen", "Stay hydrated", "Check afternoon pollen updates"],
            PersonaType.FITNESS: ["Optimal training window early morning", "Drink 500ml water/hour", "Dynamic warm-up recommended"],
            PersonaType.FARM: ["Check soil moisture probes", "Hold spray if wind > 15km/h", "Plan evening drip cycle"],
            PersonaType.BEACH: ["Reapply SPF 50+", "Observe lifeguard flags", "Stay hydrated under sun"],
            PersonaType.COMMUTE: ["Clear route expected", "Check tyre pressure", "Maintain normal cruising speed"],
            PersonaType.TRAVEL: ["Pack light layers", "Keep digital flight alerts active", "Carry compact umbrella"],
            PersonaType.EVENTS: ["Secure shade canopy anchors", "Setup water stations", "Monitor radar overlay"],
            PersonaType.FAMILY: ["Apply child-safe sunscreen", "Pack full water bottles", "Safe for outdoor playtime"],
            PersonaType.WORK: ["10-min rest every 50 mins", "Mandatory hydration break", "Wear high-vis safety gear"]
        }
        return defaults.get(persona, ["Stay updated with Mausam live alerts", "Dress appropriately for conditions"])
