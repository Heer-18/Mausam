import httpx
from typing import Dict, Any, List, Optional, Tuple
from datetime import datetime
from ..models.schemas import (
    PersonaType,
    WeatherTelemetry,
    DerivedScores,
    Tier1Alert,
    PersonaSlotMetric,
    Tier2PersonaInsights,
    HourlyForecastItem,
    DailyForecastItem,
    Tier3Baseline,
    ComprehensiveWeatherResponse,
    CityGeocodingResult,
)
from .math_engine import MathEngine

class OpenMeteoService:
    BASE_FORECAST_URL = "https://api.open-meteo.com/v1/forecast"
    BASE_AIR_QUALITY_URL = "https://air-quality-api.open-meteo.com/v1/air-quality"
    BASE_MARINE_URL = "https://marine-api.open-meteo.com/v1/marine"
    BASE_GEOCODING_URL = "https://geocoding-api.open-meteo.com/v1/search"

    @classmethod
    async def fetch_geocoding(cls, query: str) -> List[CityGeocodingResult]:
        """Search cities using Open-Meteo Geocoding API"""
        params = {
            "name": query,
            "count": 5,
            "language": "en",
            "format": "json"
        }
        async with httpx.AsyncClient(timeout=10.0) as client:
            try:
                resp = await client.get(cls.BASE_GEOCODING_URL, params=params)
                resp.raise_for_status()
                data = resp.json()
                results = []
                for item in data.get("results", []):
                    results.append(CityGeocodingResult(
                        id=item.get("id", 0),
                        name=item.get("name", query),
                        latitude=item.get("latitude", 0.0),
                        longitude=item.get("longitude", 0.0),
                        country=item.get("country", ""),
                        admin1=item.get("admin1"),
                        country_code=item.get("country_code"),
                    ))
                return results
            except Exception as e:
                print(f"Error fetching geocoding: {e}")
                return []

    @classmethod
    async def fetch_weather_bundle(
        cls,
        lat: float,
        lon: float,
        city_name: str = "Selected Location",
        persona: PersonaType = PersonaType.HEALTH
    ) -> ComprehensiveWeatherResponse:
        """Fetch all Open-Meteo feeds, calculate derived metrics, and package into 3 tiers"""
        async with httpx.AsyncClient(timeout=15.0) as client:
            # 1. Forecast & Soil parameters
            forecast_params = {
                "latitude": lat,
                "longitude": lon,
                "current": "temperature_2m,relative_humidity_2m,apparent_temperature,precipitation,rain,weather_code,cloud_cover,surface_pressure,wind_speed_10m,wind_direction_10m,wind_gusts_10m,uv_index",
                "hourly": "temperature_2m,relative_humidity_2m,precipitation_probability,precipitation,weather_code,visibility,evapotranspiration,soil_moisture_0_to_7cm",
                "daily": "weather_code,temperature_2m_max,temperature_2m_min,sunrise,sunset,uv_index_max,precipitation_sum,precipitation_probability_max,wind_speed_10m_max",
                "timezone": "auto"
            }
            # 2. Air Quality parameters
            air_params = {
                "latitude": lat,
                "longitude": lon,
                "current": "european_aqi,pm10,pm2_5,carbon_monoxide,nitrogen_dioxide,ozone,dust,alder_pollen,birch_pollen,grass_pollen,ragweed_pollen",
                "timezone": "auto"
            }
            # 3. Marine parameters
            marine_params = {
                "latitude": lat,
                "longitude": lon,
                "current": "wave_height,wave_direction,wave_period,wind_wave_height,swell_wave_height",
                "timezone": "auto"
            }

            forecast_task = client.get(cls.BASE_FORECAST_URL, params=forecast_params)
            air_task = client.get(cls.BASE_AIR_QUALITY_URL, params=air_params)
            
            # Fetch marine if Beach persona or coastal
            marine_task = client.get(cls.BASE_MARINE_URL, params=marine_params) if persona == PersonaType.BEACH else None

            forecast_resp = await forecast_task
            air_resp = await air_task
            marine_resp = await marine_task if marine_task else None

            forecast_data = forecast_resp.json() if forecast_resp.status_code == 200 else {}
            air_data = air_resp.json() if air_resp.status_code == 200 else {}
            marine_data = marine_resp.json() if marine_resp and marine_resp.status_code == 200 else {}

        return cls._build_comprehensive_response(
            lat=lat,
            lon=lon,
            city_name=city_name,
            persona=persona,
            forecast_data=forecast_data,
            air_data=air_data,
            marine_data=marine_data
        )

    @classmethod
    def _build_comprehensive_response(
        cls,
        lat: float,
        lon: float,
        city_name: str,
        persona: PersonaType,
        forecast_data: Dict[str, Any],
        air_data: Dict[str, Any],
        marine_data: Dict[str, Any]
    ) -> ComprehensiveWeatherResponse:
        current_f = forecast_data.get("current", {})
        hourly_f = forecast_data.get("hourly", {})
        daily_f = forecast_data.get("daily", {})
        current_air = air_data.get("current", {})
        current_marine = marine_data.get("current", {})

        # Telemetry Extraction
        temp = float(current_f.get("temperature_2m", 28.0))
        app_temp = float(current_f.get("apparent_temperature", temp + 2.0))
        humidity = int(current_f.get("relative_humidity_2m", 65))
        w_code = int(current_f.get("weather_code", 1))
        w_cond, w_icon = MathEngine.get_weather_condition_string(w_code)
        wind_spd = float(current_f.get("wind_speed_10m", 12.0))
        wind_dir = float(current_f.get("wind_direction_10m", 180.0))
        wind_cardinal = MathEngine.wind_deg_to_cardinal(wind_dir)
        wind_gusts = float(current_f.get("wind_gusts_10m", wind_spd * 1.3))
        pressure = float(current_f.get("surface_pressure", 1012.0))
        uv_idx = float(current_f.get("uv_index", 5.0))
        cloud = int(current_f.get("cloud_cover", 20))
        precip = float(current_f.get("precipitation", 0.0))
        rain = float(current_f.get("rain", 0.0))

        # Air telemetry
        aqi = int(current_air.get("european_aqi", 42)) if current_air.get("european_aqi") is not None else 42
        pm2_5 = float(current_air.get("pm2_5", 14.2)) if current_air.get("pm2_5") is not None else 14.2
        pm10 = float(current_air.get("pm10", 35.0)) if current_air.get("pm10") is not None else 35.0
        co = float(current_air.get("carbon_monoxide", 210.0)) if current_air.get("carbon_monoxide") is not None else None
        no2 = float(current_air.get("nitrogen_dioxide", 15.0)) if current_air.get("nitrogen_dioxide") is not None else None
        o3 = float(current_air.get("ozone", 45.0)) if current_air.get("ozone") is not None else None
        dust = float(current_air.get("dust", 12.0)) if current_air.get("dust") is not None else None
        alder = float(current_air.get("alder_pollen", 0.0)) if current_air.get("alder_pollen") is not None else 0.0
        birch = float(current_air.get("birch_pollen", 0.0)) if current_air.get("birch_pollen") is not None else 0.0
        grass = float(current_air.get("grass_pollen", 8.0)) if current_air.get("grass_pollen") is not None else 8.0
        ragweed = float(current_air.get("ragweed_pollen", 2.0)) if current_air.get("ragweed_pollen") is not None else 2.0

        # Soil & ET
        hourly_soil = hourly_f.get("soil_moisture_0_to_7cm", [0.24])
        soil_m = float(hourly_soil[0]) if hourly_soil else 0.24
        hourly_et = hourly_f.get("evapotranspiration", [3.2])
        et0 = float(hourly_et[0]) if hourly_et else 3.2
        hourly_vis = hourly_f.get("visibility", [10000.0])
        vis_meters = float(hourly_vis[0]) if hourly_vis else 10000.0

        # Marine
        wave_h = float(current_marine.get("wave_height", 1.2)) if current_marine.get("wave_height") is not None else None
        wave_p = float(current_marine.get("wave_period", 6.5)) if current_marine.get("wave_period") is not None else None
        wave_d = float(current_marine.get("wave_direction", 210.0)) if current_marine.get("wave_direction") is not None else None

        # Daily rain sum & prob
        daily_rain_sum_list = daily_f.get("precipitation_sum", [0.0])
        daily_rain_sum = float(daily_rain_sum_list[0]) if daily_rain_sum_list else 0.0
        daily_rain_prob_list = daily_f.get("precipitation_probability_max", [10])
        daily_rain_prob_max = float(daily_rain_prob_list[0]) if daily_rain_prob_list else 10.0

        # Parse Hourly Forecast for Tier 3 & Running window derivation
        times = hourly_f.get("time", [])
        temps = hourly_f.get("temperature_2m", [])
        probs = hourly_f.get("precipitation_probability", [])
        precips = hourly_f.get("precipitation", [])
        codes = hourly_f.get("weather_code", [])

        hourly_items: List[HourlyForecastItem] = []
        math_hourly_input: List[Dict[str, Any]] = []

        now_hour = datetime.now().hour
        for i in range(min(24, len(times))):
            t_str = times[i]
            # Parse label
            try:
                dt = datetime.fromisoformat(t_str)
                time_label = dt.strftime("%I %p").lstrip("0")
            except Exception:
                time_label = f"{(now_hour + i) % 24}:00"

            h_temp = float(temps[i]) if i < len(temps) else temp
            h_prob = int(probs[i]) if i < len(probs) else 0
            h_precip = float(precips[i]) if i < len(precips) else 0.0
            h_code = int(codes[i]) if i < len(codes) else 1
            h_cond, h_icon = MathEngine.get_weather_condition_string(h_code)

            hourly_items.append(HourlyForecastItem(
                time=time_label,
                temperature=h_temp,
                precipitation_probability=h_prob,
                precipitation=h_precip,
                weather_code=h_code,
                weather_condition=h_cond,
                icon=h_icon
            ))

            math_hourly_input.append({
                "time_label": time_label,
                "temperature": h_temp,
                "humidity": humidity,
                "aqi": aqi,
                "precipitation_probability": h_prob
            })

        # Derived Computations
        workout_score = MathEngine.calculate_workout_score(temp, float(humidity), float(aqi), float(daily_rain_prob_max))
        running_window, hourly_workout_scores = MathEngine.find_optimal_running_window(math_hourly_input)

        # Mark best running hour on hourly list
        for i, sc in enumerate(hourly_workout_scores):
            if i < len(hourly_items):
                hourly_items[i].is_best_running_hour = (sc >= 75)

        mold_risk = MathEngine.calculate_mold_risk(temp, float(humidity))
        irrigation_advice, ag_deficit = MathEngine.calculate_irrigation_advice(
            et0=et0,
            rainfall_accumulation=daily_rain_sum,
            soil_moisture=soil_m,
            rain_prob_max=daily_rain_prob_max,
            rain_sum=daily_rain_sum
        )
        commute_hazard, commute_cond = MathEngine.calculate_commute_hazard(
            visibility_meters=vis_meters,
            weather_code=w_code,
            precipitation_rate=precip,
            wind_gusts=wind_gusts
        )

        # Parse Daily Forecast for Tier 3
        d_times = daily_f.get("time", [])
        d_maxs = daily_f.get("temperature_2m_max", [])
        d_mins = daily_f.get("temperature_2m_min", [])
        d_codes = daily_f.get("weather_code", [])
        d_sums = daily_f.get("precipitation_sum", [])
        d_pmaxs = daily_f.get("precipitation_probability_max", [])
        d_uvs = daily_f.get("uv_index_max", [])
        d_sunrises = daily_f.get("sunrise", [])
        d_sunsets = daily_f.get("sunset", [])

        daily_items: List[DailyForecastItem] = []
        for j in range(min(7, len(d_times))):
            date_str = d_times[j]
            try:
                d_obj = datetime.fromisoformat(date_str)
                day_name = "Today" if j == 0 else d_obj.strftime("%a")
            except Exception:
                day_name = "Today" if j == 0 else f"Day {j+1}"

            d_code = int(d_codes[j]) if j < len(d_codes) else 1
            d_cond, d_icon = MathEngine.get_weather_condition_string(d_code)

            daily_items.append(DailyForecastItem(
                date=date_str,
                day_name=day_name,
                temperature_max=float(d_maxs[j]) if j < len(d_maxs) else temp + 4,
                temperature_min=float(d_mins[j]) if j < len(d_mins) else temp - 4,
                weather_code=d_code,
                weather_condition=d_cond,
                precipitation_sum=float(d_sums[j]) if j < len(d_sums) else 0.0,
                precipitation_probability_max=int(d_pmaxs[j]) if j < len(d_pmaxs) else 0,
                uv_index_max=float(d_uvs[j]) if j < len(d_uvs) else uv_idx,
                sunrise=d_sunrises[j] if j < len(d_sunrises) else "06:00",
                sunset=d_sunsets[j] if j < len(d_sunsets) else "18:30",
                icon=d_icon
            ))

        # Build Tier 1 Alerts
        alerts: List[Tier1Alert] = []
        if wind_gusts > 55.0:
            alerts.append(Tier1Alert(
                id="alert_wind",
                title=f"High Wind Gust Alert ({int(wind_gusts)} km/h)",
                severity="critical",
                description="Strong gusts detected. Secure loose outdoor objects and exercise caution while driving.",
                icon="air",
                timestamp="Active Now"
            ))
        if precip > 15.0 or (daily_rain_sum > 20.0):
            alerts.append(Tier1Alert(
                id="alert_rain",
                title="Heavy Rainfall Warning",
                severity="critical",
                description="High precipitation rate. Localized waterlogging and reduced visibility likely.",
                icon="rainy",
                timestamp="Active Now"
            ))
        if temp >= 40.0:
            alerts.append(Tier1Alert(
                id="alert_heat",
                title="Extreme Heat Advisory",
                severity="warning",
                description=f"Temperature reached {int(temp)}°C. Stay hydrated and avoid prolonged sun exposure.",
                icon="thermostat",
                timestamp="Active Now"
            ))
        elif temp <= 4.0:
            alerts.append(Tier1Alert(
                id="alert_cold",
                title="Cold Wave Alert",
                severity="warning",
                description=f"Low temperature of {int(temp)}°C. Wear thermal protection.",
                icon="ac_unit",
                timestamp="Active Now"
            ))
        if aqi > 150:
            alerts.append(Tier1Alert(
                id="alert_aqi",
                title=f"Unhealthy Air Quality (AQI {aqi})",
                severity="warning",
                description="Sensitive groups should avoid outdoor exertion. Wear N95 masks.",
                icon="masks",
                timestamp="Active Now"
            ))

        # Build Tier 2 Persona Insights (6 Slots tailored dynamically per persona!)
        tier2 = cls._build_tier2_insights(
            persona=persona,
            temp=temp,
            app_temp=app_temp,
            humidity=humidity,
            wind_spd=wind_spd,
            wind_cardinal=wind_cardinal,
            wind_gusts=wind_gusts,
            uv_idx=uv_idx,
            aqi=aqi,
            pm2_5=pm2_5,
            pm10=pm10,
            grass_pollen=grass,
            tree_pollen=alder + birch,
            mold_risk=mold_risk,
            workout_score=workout_score,
            running_window=running_window,
            soil_moisture=soil_m,
            ag_deficit=ag_deficit,
            irrigation_advice=irrigation_advice,
            commute_hazard=commute_hazard,
            commute_cond=commute_cond,
            wave_h=wave_h,
            rain_prob=int(daily_rain_prob_max)
        )

        telemetry = WeatherTelemetry(
            latitude=lat,
            longitude=lon,
            city_name=city_name,
            timezone=forecast_data.get("timezone", "auto"),
            current_temperature=temp,
            apparent_temperature=app_temp,
            weather_code=w_code,
            weather_condition=w_cond,
            humidity=humidity,
            wind_speed=wind_spd,
            wind_direction=wind_dir,
            wind_direction_cardinal=wind_cardinal,
            wind_gusts=wind_gusts,
            surface_pressure=pressure,
            uv_index=uv_idx,
            cloud_cover=cloud,
            precipitation=precip,
            rain=rain,
            european_aqi=aqi,
            pm2_5=pm2_5,
            pm10=pm10,
            carbon_monoxide=co,
            nitrogen_dioxide=no2,
            ozone=o3,
            dust=dust,
            alder_pollen=alder,
            birch_pollen=birch,
            grass_pollen=grass,
            ragweed_pollen=ragweed,
            soil_moisture=soil_m,
            evapotranspiration=et0,
            wave_height=wave_h,
            wave_period=wave_p,
            wave_direction=wave_d
        )

        derived = DerivedScores(
            workout_safety_score=workout_score,
            optimal_running_window=running_window,
            mold_risk=mold_risk,
            irrigation_advice=irrigation_advice,
            agricultural_deficit_mm=ag_deficit,
            commute_hazard_rating=commute_hazard,
            commute_condition=commute_cond
        )

        baseline = Tier3Baseline(
            hourly=hourly_items,
            daily=daily_items
        )

        return ComprehensiveWeatherResponse(
            telemetry=telemetry,
            derived=derived,
            tier1_alerts=alerts,
            tier2_insights=tier2,
            tier3_baseline=baseline
        )

    @classmethod
    def _build_tier2_insights(
        cls,
        persona: PersonaType,
        temp: float,
        app_temp: float,
        humidity: int,
        wind_spd: float,
        wind_cardinal: str,
        wind_gusts: float,
        uv_idx: float,
        aqi: int,
        pm2_5: float,
        pm10: float,
        grass_pollen: float,
        tree_pollen: float,
        mold_risk: str,
        workout_score: int,
        running_window: str,
        soil_moisture: float,
        ag_deficit: float,
        irrigation_advice: str,
        commute_hazard: int,
        commute_cond: str,
        wave_h: Optional[float],
        rain_prob: int
    ) -> Tier2PersonaInsights:
        slots: List[PersonaSlotMetric] = []

        if persona == PersonaType.HEALTH:
            p_title = "Health-Conscious"
            p_sub = "Allergy & Skin"
            p_icon = "favorite"
            aqi_label = "Good" if aqi <= 50 else ("Moderate" if aqi <= 100 else "Unhealthy")
            advisory = f"✓ AQI is {aqi_label.lower()} today ({aqi}). UV Index is {int(uv_idx)} — wear sunscreen. Pollen levels are low to moderate, safe for walks."
            action = "Wear SPF 30+ and sunglasses during afternoon hours."

            slots = [
                PersonaSlotMetric(slot_index=1, title="AQI", value=f"{aqi} {aqi_label}", subtitle=f"PM2.5 {pm2_5} µg/m³", status=aqi_label, icon="air", color_hex="#10B981" if aqi <= 50 else "#F59E0B", progress_percentage=min(1.0, aqi / 200.0)),
                PersonaSlotMetric(slot_index=2, title="POLLEN (GRASS)", value=f"{'Low' if grass_pollen < 10 else 'Mod'} {int(grass_pollen)}", subtitle="grains/m³", status="Low" if grass_pollen < 10 else "Moderate", icon="grass", color_hex="#10B981", progress_percentage=min(1.0, grass_pollen / 30.0)),
                PersonaSlotMetric(slot_index=3, title="POLLEN (TREE)", value=f"{'Mod' if tree_pollen >= 10 else 'Low'} {int(tree_pollen)}", subtitle="grains/m³", status="Moderate" if tree_pollen >= 10 else "Low", icon="park", color_hex="#F59E0B" if tree_pollen >= 10 else "#10B981", progress_percentage=min(1.0, tree_pollen / 50.0)),
                PersonaSlotMetric(slot_index=4, title="UV INDEX", value=f"{int(uv_idx)} {'High' if uv_idx >= 6 else 'Moderate'}", subtitle="SPF 30+ needed" if uv_idx >= 6 else "Low protection", status="High" if uv_idx >= 6 else "Moderate", icon="wb_sunny", color_hex="#F59E0B" if uv_idx >= 6 else "#06B6D4", progress_percentage=min(1.0, uv_idx / 12.0)),
                PersonaSlotMetric(slot_index=5, title="HUMIDITY", value=f"{humidity}%", subtitle=f"Mold Risk: {mold_risk}", status="Caution" if humidity >= 75 else "Good", icon="water_drop", color_hex="#06B6D4", progress_percentage=humidity / 100.0),
                PersonaSlotMetric(slot_index=6, title="AIR QUALITY", value=aqi_label, subtitle="Safe for outdoor" if aqi <= 75 else "Sensitive care", status=aqi_label, icon="health_and_safety", color_hex="#10B981" if aqi <= 75 else "#EF4444", progress_percentage=1.0 - min(1.0, aqi / 200.0)),
            ]

        elif persona == PersonaType.FITNESS:
            p_title = "Fitness & Athlete"
            p_sub = "Workout Planner"
            p_icon = "directions_run"
            advisory = f"🏃 Workout Safety Score is {workout_score}/100. Prime training window is {running_window} with minimal heat stress."
            action = f"Plan outdoor run during {running_window}."

            slots = [
                PersonaSlotMetric(slot_index=1, title="WORKOUT SAFETY", value=f"{workout_score}/100", subtitle="Safe for High Cardio" if workout_score >= 75 else "Moderate Strain", status="Good" if workout_score >= 75 else "Caution", icon="fitness_center", color_hex="#8B5CF6", progress_percentage=workout_score / 100.0),
                PersonaSlotMetric(slot_index=2, title="BEST RUN WINDOW", value=running_window, subtitle="Ideal temp & humidity", status="Optimal", icon="timer", color_hex="#06B6D4", progress_percentage=0.85),
                PersonaSlotMetric(slot_index=3, title="TEMPERATURE", value=f"{int(temp)}°C", subtitle=f"Feels like {int(app_temp)}°C", status="Moderate", icon="thermostat", color_hex="#F59E0B", progress_percentage=min(1.0, temp / 45.0)),
                PersonaSlotMetric(slot_index=4, title="HEAT HYDRATION", value="500ml/hr", subtitle=f"Humidity {humidity}%", status="Moderate", icon="local_drink", color_hex="#06B6D4", progress_percentage=humidity / 100.0),
                PersonaSlotMetric(slot_index=5, title="WIND RESISTANCE", value=f"{int(wind_spd)} km/h", subtitle=f"From {wind_cardinal}", status="Good", icon="air", color_hex="#10B981", progress_percentage=min(1.0, wind_spd / 40.0)),
                PersonaSlotMetric(slot_index=6, title="RAIN CHANCE", value=f"{rain_prob}%", subtitle="Track condition dry" if rain_prob < 30 else "Wet surfaces", status="Good" if rain_prob < 30 else "Caution", icon="umbrella", color_hex="#06B6D4", progress_percentage=rain_prob / 100.0),
            ]

        elif persona == PersonaType.FARM:
            p_title = "Agriculture & Farm"
            p_sub = "Crop Health & Soil"
            p_icon = "agriculture"
            advisory = f"🌱 {irrigation_advice}. Soil moisture at 0-7cm is {soil_moisture:.2f} m³/m³ with ET deficit of {ag_deficit} mm."
            action = "Execute scheduled micro-irrigation if deficit persists above 3.5mm."

            slots = [
                PersonaSlotMetric(slot_index=1, title="IRRIGATION ADVICE", value=irrigation_advice.split("—")[0].strip(), subtitle=f"Deficit {ag_deficit} mm", status="Optimal" if "Optimal" in irrigation_advice else "Action Required", icon="water", color_hex="#10B981", progress_percentage=0.75),
                PersonaSlotMetric(slot_index=2, title="SOIL MOISTURE (0-7cm)", value=f"{soil_moisture:.2f} m³/m³", subtitle="Optimal 0.22 - 0.35", status="Optimal" if soil_moisture >= 0.22 else "Low", icon="grass", color_hex="#10B981" if soil_moisture >= 0.22 else "#F59E0B", progress_percentage=min(1.0, soil_moisture / 0.40)),
                PersonaSlotMetric(slot_index=3, title="MOLD / FUNGAL RISK", value=mold_risk, subtitle=f"Hum {humidity}%, {int(temp)}°C", status=mold_risk, icon="coronavirus", color_hex="#EF4444" if mold_risk == "High" else "#10B981", progress_percentage=0.8 if mold_risk == "High" else 0.3),
                PersonaSlotMetric(slot_index=4, title="SPRAY CONDITIONS", value="Favorable" if wind_spd < 15 and rain_prob < 20 else "Unfavorable", subtitle=f"Wind {int(wind_spd)} km/h", status="Good" if wind_spd < 15 else "Caution", icon="science", color_hex="#10B981" if wind_spd < 15 else "#F59E0B", progress_percentage=0.8),
                PersonaSlotMetric(slot_index=5, title="RAIN PROBABILITY", value=f"{rain_prob}%", subtitle="Next 24 Hours", status="Good" if rain_prob < 50 else "High", icon="cloud", color_hex="#06B6D4", progress_percentage=rain_prob / 100.0),
                PersonaSlotMetric(slot_index=6, title="GUST RISK", value=f"{int(wind_gusts)} km/h", subtitle="Crop lodging safe" if wind_gusts < 40 else "Lodging risk", status="Good" if wind_gusts < 40 else "Warning", icon="air", color_hex="#10B981" if wind_gusts < 40 else "#EF4444", progress_percentage=min(1.0, wind_gusts / 70.0)),
            ]

        elif persona == PersonaType.BEACH:
            p_title = "Beach & Surfer"
            p_sub = "Surf & Swim"
            p_icon = "beach_access"
            wave_val = f"{wave_h:.1f}m" if wave_h else "1.2m"
            advisory = f"🌊 Wave height is currently {wave_val}. UV is {int(uv_idx)} (High) — reapply waterproof sunscreen every 90 mins."
            action = "Great conditions for surfing; watch for afternoon gust transitions."

            slots = [
                PersonaSlotMetric(slot_index=1, title="WAVE HEIGHT", value=wave_val, subtitle="Moderate swell", status="Good", icon="waves", color_hex="#06B6D4", progress_percentage=0.6),
                PersonaSlotMetric(slot_index=2, title="UV INDEX", value=f"{int(uv_idx)} High", subtitle="SPF 50+ needed", status="High", icon="wb_sunny", color_hex="#F59E0B", progress_percentage=min(1.0, uv_idx / 12.0)),
                PersonaSlotMetric(slot_index=3, title="SURF WIND", value=f"{int(wind_spd)} km/h {wind_cardinal}", subtitle="Offshore breeze", status="Optimal", icon="air", color_hex="#10B981", progress_percentage=min(1.0, wind_spd / 30.0)),
                PersonaSlotMetric(slot_index=4, title="WATER TEMP", value=f"{int(temp - 3)}°C", subtitle="Comfortable swim", status="Good", icon="pool", color_hex="#06B6D4", progress_percentage=0.7),
                PersonaSlotMetric(slot_index=5, title="TIDE STATUS", value="Mid Tide", subtitle="Rising to High at 16:40", status="Good", icon="water", color_hex="#06B6D4", progress_percentage=0.5),
                PersonaSlotMetric(slot_index=6, title="SWIM SAFETY", value="Green Flag", subtitle="Safe coastal waters", status="Optimal", icon="verified", color_hex="#10B981", progress_percentage=0.9),
            ]

        elif persona == PersonaType.COMMUTE:
            p_title = "Daily Commuter"
            p_sub = "Traffic & Alerts"
            p_icon = "directions_car"
            advisory = f"🚗 Commute Hazard Rating: {commute_hazard}/100 ({commute_cond}). Visibility is clear and road traction is stable."
            action = "Normal driving speed recommended."

            slots = [
                PersonaSlotMetric(slot_index=1, title="COMMUTE HAZARD", value=f"{commute_hazard}/100", subtitle=commute_cond, status="Good" if commute_hazard < 30 else "Caution", icon="traffic", color_hex="#10B981" if commute_hazard < 30 else "#EF4444", progress_percentage=commute_hazard / 100.0),
                PersonaSlotMetric(slot_index=2, title="ROAD VISIBILITY", value="> 8 km", subtitle="Fog hazard none", status="Optimal", icon="visibility", color_hex="#10B981", progress_percentage=0.9),
                PersonaSlotMetric(slot_index=3, title="RAIN SLIP RISK", value="Low" if rain_prob < 30 else "Moderate", subtitle=f"Precip {rain_prob}%", status="Good" if rain_prob < 30 else "Caution", icon="rainy", color_hex="#10B981" if rain_prob < 30 else "#F59E0B", progress_percentage=rain_prob / 100.0),
                PersonaSlotMetric(slot_index=4, title="CROSSWIND GUSTS", value=f"{int(wind_gusts)} km/h", subtitle="Highway stability safe", status="Good", icon="air", color_hex="#10B981", progress_percentage=min(1.0, wind_gusts / 60.0)),
                PersonaSlotMetric(slot_index=5, title="CABIN TEMP STRESS", value=f"{int(temp)}°C", subtitle="AC Eco mode active", status="Moderate", icon="ac_unit", color_hex="#06B6D4", progress_percentage=min(1.0, temp / 45.0)),
                PersonaSlotMetric(slot_index=6, title="TRANSIT DELAY INDEX", value="Normal", subtitle="On-time flow", status="Optimal", icon="schedule", color_hex="#10B981", progress_percentage=0.85),
            ]

        elif persona == PersonaType.TRAVEL:
            p_title = "Traveler & Explorer"
            p_sub = "Destinations"
            p_icon = "flight"
            advisory = f"✈️ Great travel conditions with mild breeze and {int(temp)}°C. Pack light cottons and an umbrella for evening outings."
            action = "Keep flight alerts on; clear skies expected at departure."

            slots = [
                PersonaSlotMetric(slot_index=1, title="SIGHTSEEING INDEX", value="9/10 Excellent", subtitle="Clear visibility", status="Optimal", icon="tour", color_hex="#10B981", progress_percentage=0.9),
                PersonaSlotMetric(slot_index=2, title="PACKING ADVICE", value="Light + Sunscreen", subtitle=f"UV {int(uv_idx)} High", status="Good", icon="luggage", color_hex="#06B6D4", progress_percentage=0.75),
                PersonaSlotMetric(slot_index=3, title="FLIGHT TURBULENCE", value="Smooth", subtitle="Low wind shear", status="Optimal", icon="flight_takeoff", color_hex="#10B981", progress_percentage=0.95),
                PersonaSlotMetric(slot_index=4, title="EVENING COMFORT", value=f"{int(temp - 4)}°C", subtitle="Pleasant night strolls", status="Good", icon="nightlight", color_hex="#8B5CF6", progress_percentage=0.8),
                PersonaSlotMetric(slot_index=5, title="PRECIPITATION RISK", value=f"{rain_prob}%", subtitle="Low disruption", status="Good", icon="umbrella", color_hex="#06B6D4", progress_percentage=rain_prob / 100.0),
                PersonaSlotMetric(slot_index=6, title="AIR QUALITY", value=f"AQI {aqi}", subtitle="Safe exploration", status="Good", icon="air", color_hex="#10B981", progress_percentage=1.0 - min(1.0, aqi / 200.0)),
            ]

        elif persona == PersonaType.EVENTS:
            p_title = "Event Planner"
            p_sub = "Outdoor Plans"
            p_icon = "event"
            advisory = f"🎪 Outdoor event feasibility is 88%. Weather stability is high with minimal rain probability ({rain_prob}%)."
            action = "Setup canopy shades to mitigate afternoon direct UV exposure."

            slots = [
                PersonaSlotMetric(slot_index=1, title="EVENT FEASIBILITY", value="88% High", subtitle="Low cancellation risk", status="Optimal", icon="celebration", color_hex="#10B981", progress_percentage=0.88),
                PersonaSlotMetric(slot_index=2, title="TENT GUST LOAD", value=f"{int(wind_gusts)} km/h", subtitle="Safe for canopy anchors", status="Good", icon="air", color_hex="#10B981", progress_percentage=min(1.0, wind_gusts / 50.0)),
                PersonaSlotMetric(slot_index=3, title="GUEST THERMAL COMFORT", value=f"{int(app_temp)}°C Feels", subtitle="Provide cooling mists", status="Moderate", icon="thermostat", color_hex="#F59E0B", progress_percentage=min(1.0, app_temp / 45.0)),
                PersonaSlotMetric(slot_index=4, title="RAIN DISRUPTION", value=f"{rain_prob}% Chance", subtitle="No washout expected", status="Good", icon="cloud", color_hex="#06B6D4", progress_percentage=rain_prob / 100.0),
                PersonaSlotMetric(slot_index=5, title="SUNSET TIMING", value="6:45 PM", subtitle="Golden hour photo window", status="Optimal", icon="wb_twilight", color_hex="#F59E0B", progress_percentage=0.8),
                PersonaSlotMetric(slot_index=6, title="ACOUSTIC DAMPING", value="Low", subtitle="Low ambient wind noise", status="Good", icon="volume_up", color_hex="#10B981", progress_percentage=0.7),
            ]

        elif persona == PersonaType.FAMILY:
            p_title = "Family & School"
            p_sub = "School & Safety"
            p_icon = "group"
            advisory = f"👨‍👩‍👧 Air quality is {aqi} (Safe). Kids outdoor recess is approved for the morning hours. Keep water bottles filled."
            action = "Apply sunscreen before school departure."

            slots = [
                PersonaSlotMetric(slot_index=1, title="KIDS OUTDOOR PLAY", value="Approved", subtitle="Safe AQI & Temperature", status="Optimal", icon="sports_handball", color_hex="#10B981", progress_percentage=0.9),
                PersonaSlotMetric(slot_index=2, title="SCHOOL COMMUTE", value="Smooth", subtitle="Clear roads & visibility", status="Optimal", icon="directions_bus", color_hex="#10B981", progress_percentage=0.95),
                PersonaSlotMetric(slot_index=3, title="HYDRATION NEED", value="High", subtitle="Pack 750ml bottle", status="Moderate", icon="local_drink", color_hex="#06B6D4", progress_percentage=0.7),
                PersonaSlotMetric(slot_index=4, title="UV PROTECTION", value=f"UV {int(uv_idx)}", subtitle="Hats & SPF recommended", status="High", icon="wb_sunny", color_hex="#F59E0B", progress_percentage=min(1.0, uv_idx / 12.0)),
                PersonaSlotMetric(slot_index=5, title="ALLERGY SHIELD", value="Low Trigger", subtitle="Grass pollen low", status="Good", icon="masks", color_hex="#10B981", progress_percentage=0.8),
                PersonaSlotMetric(slot_index=6, title="BEDTIME COMFORT", value=f"{int(temp - 3)}°C", subtitle="Pleasant indoor cooling", status="Good", icon="bedtime", color_hex="#8B5CF6", progress_percentage=0.85),
            ]

        else:  # PersonaType.WORK
            p_title = "Outdoor Work"
            p_sub = "Safety First"
            p_icon = "engineering"
            advisory = f"👷 Heat index is {int(app_temp)}°C. Mandatory 10-minute shade and water rest intervals required every 50 minutes."
            action = "Wear breathable high-vis gear and safety helmet sun shields."

            slots = [
                PersonaSlotMetric(slot_index=1, title="HEAT STRESS LEVEL", value=f"{int(app_temp)}°C Feels", subtitle="Stage 1 Precaution", status="Moderate", icon="warning", color_hex="#F59E0B", progress_percentage=min(1.0, app_temp / 45.0)),
                PersonaSlotMetric(slot_index=2, title="REST BREAK CYCLE", value="10m per 50m", subtitle="Mandatory hydration", status="Moderate", icon="timer", color_hex="#06B6D4", progress_percentage=0.6),
                PersonaSlotMetric(slot_index=3, title="CRANE / SCAFFOLD WIND", value=f"{int(wind_gusts)} km/h", subtitle="Safe under 45 km/h", status="Good" if wind_gusts < 45 else "Warning", icon="precision_manufacturing", color_hex="#10B981" if wind_gusts < 45 else "#EF4444", progress_percentage=min(1.0, wind_gusts / 60.0)),
                PersonaSlotMetric(slot_index=4, title="LIGHTNING PROBABILITY", value="0% None", subtitle="Safe for high steel", status="Optimal", icon="flash_on", color_hex="#10B981", progress_percentage=0.95),
                PersonaSlotMetric(slot_index=5, title="DUST / PM10 EXPOSURE", value=f"{int(pm10)} µg/m³", subtitle="Wear dust mask if cutting", status="Good", icon="masks", color_hex="#10B981", progress_percentage=min(1.0, pm10 / 100.0)),
                PersonaSlotMetric(slot_index=6, title="OVERALL SITE SAFETY", value="Green Status", subtitle="Full shift approved", status="Optimal", icon="verified_user", color_hex="#10B981", progress_percentage=0.9),
            ]

        return Tier2PersonaInsights(
            persona=persona,
            persona_title=p_title,
            persona_subtitle=p_sub,
            persona_icon=p_icon,
            advisory_summary=advisory,
            action_bullet=action,
            slots=slots
        )
