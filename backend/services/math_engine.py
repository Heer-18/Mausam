from typing import List, Dict, Any, Tuple

class MathEngine:
    @staticmethod
    def calculate_workout_score(temp: float, humidity: float, aqi: float, rain_prob: float) -> int:
        """
        Calculate Workout Safety Score (0–100)
        Score = 100 - (temp > 28 ? (temp - 28) * 4 : 0)
                    - (humidity > 70 ? (humidity - 70) * 0.7 : 0)
                    - (aqi > 100 ? (aqi - 100) * 0.4 : 0)
                    - (rain_prob * 0.5)
        """
        temp_penalty = (temp - 28.0) * 4.0 if temp > 28.0 else 0.0
        humidity_penalty = (humidity - 70.0) * 0.7 if humidity > 70.0 else 0.0
        aqi_penalty = (aqi - 100.0) * 0.4 if aqi > 100.0 else 0.0
        rain_penalty = rain_prob * 0.5

        raw_score = 100.0 - temp_penalty - humidity_penalty - aqi_penalty - rain_penalty
        score = max(0, min(100, int(round(raw_score))))
        return score

    @staticmethod
    def find_optimal_running_window(hourly_data: List[Dict[str, Any]]) -> Tuple[str, List[int]]:
        """
        Scan upcoming 12 hours from the hourly forecast.
        Tag contiguous hours where Score > 75 as the "Best running hours" (e.g., "6–8 AM").
        Returns (window_str, list_of_scores).
        """
        if not hourly_data:
            return "6:00 AM – 8:00 AM", []

        scores: List[int] = []
        qualifying_indices: List[int] = []

        scan_limit = min(12, len(hourly_data))
        for i in range(scan_limit):
            h = hourly_data[i]
            temp = float(h.get("temperature", 25.0))
            humidity = float(h.get("humidity", 60.0))
            aqi = float(h.get("aqi", 50.0))
            rain_prob = float(h.get("precipitation_probability", 0.0))

            sc = MathEngine.calculate_workout_score(temp, humidity, aqi, rain_prob)
            scores.append(sc)
            if sc >= 75:
                qualifying_indices.append(i)

        if not qualifying_indices:
            max_idx = scores.index(max(scores)) if scores else 0
            best_time = hourly_data[max_idx].get("time_label", "Early Morning")
            return f"Best: {best_time} (Score {scores[max_idx]})", scores

        # Group contiguous indices
        blocks: List[List[int]] = []
        current_block = [qualifying_indices[0]]

        for idx in qualifying_indices[1:]:
            if idx == current_block[-1] + 1:
                current_block.append(idx)
            else:
                blocks.append(current_block)
                current_block = [idx]
        blocks.append(current_block)

        longest_block = max(blocks, key=len)
        start_time = hourly_data[longest_block[0]].get("time_label", "6:00 AM")
        end_time = hourly_data[longest_block[-1]].get("time_label", "8:00 AM")

        if len(longest_block) == 1:
            window_str = f"Around {start_time}"
        else:
            window_str = f"{start_time} – {end_time}"

        return window_str, scores

    @staticmethod
    def calculate_mold_risk(temp: float, humidity: float) -> str:
        """
        Mold Risk Engine:
        Return "High" if humidity >= 75% and 20°C <= temp <= 32°C.
        Return "Moderate" if humidity >= 65% and 18°C <= temp <= 35°C.
        Otherwise return "Low".
        """
        if humidity >= 75.0 and (20.0 <= temp <= 32.0):
            return "High"
        elif humidity >= 65.0 and (18.0 <= temp <= 35.0):
            return "Moderate"
        else:
            return "Low"

    @staticmethod
    def calculate_irrigation_advice(
        et0: float,
        rainfall_accumulation: float,
        soil_moisture: float,
        rain_prob_max: float,
        rain_sum: float
    ) -> Tuple[str, float]:
        """
        Agricultural Deficit & Irrigation Advice:
        Compute Deficit (mm) = ET0 - Rainfall Accumulation.
        If Deficit > 3.5 mm and Soil Moisture (0–7 cm) < 0.22 m³/m³:
            "Irrigation Recommended (20–30 min cycle)"
        If Rain Probability > 60% or Rain Sum > 8 mm:
            "Hold Irrigation — Rain Predicted"
        Otherwise:
            "Soil Moisture Optimal — No Irrigation Needed"
        """
        deficit = round(et0 - rainfall_accumulation, 2)

        if rain_prob_max > 60.0 or rain_sum > 8.0:
            return "Hold Irrigation — Rain Predicted", deficit
        elif deficit > 3.5 and soil_moisture < 0.22:
            return "Irrigation Recommended (20–30 min cycle)", deficit
        else:
            return "Soil Moisture Optimal — No Irrigation Needed", deficit

    @staticmethod
    def calculate_commute_hazard(
        visibility_meters: float,
        weather_code: int,
        precipitation_rate: float,
        wind_gusts: float
    ) -> Tuple[int, str]:
        """
        Commute Hazard Rating (0–100) using visibility, fog, precipitation rate, and gusts.
        """
        hazard = 0.0

        if visibility_meters < 500:
            hazard += 40.0
        elif visibility_meters < 1000:
            hazard += 30.0
        elif visibility_meters < 2000:
            hazard += 20.0
        elif visibility_meters < 5000:
            hazard += 10.0

        if weather_code in [45, 48]:
            hazard += 25.0

        if weather_code in [95, 96, 99]:
            hazard += 35.0
        elif weather_code in [65, 67, 82]:
            hazard += 25.0
        elif weather_code in [61, 63, 80, 81]:
            hazard += 15.0

        if precipitation_rate > 15.0:
            hazard += 20.0
        elif precipitation_rate > 5.0:
            hazard += 10.0
        elif precipitation_rate > 1.0:
            hazard += 5.0

        if wind_gusts > 60.0:
            hazard += 20.0
        elif wind_gusts > 40.0:
            hazard += 10.0

        final_rating = max(0, min(100, int(round(hazard))))

        if final_rating >= 70:
            condition = "Severe Hazard — High Delay Risk"
        elif final_rating >= 40:
            condition = "Moderate Hazard — Wet Roads & Caution"
        elif final_rating >= 20:
            condition = "Minor Caution — Light Rain/Breeze"
        else:
            condition = "Clear Route — Normal Commute"

        return final_rating, condition

    @staticmethod
    def get_weather_condition_string(weather_code: int) -> Tuple[str, str]:
        """
        Returns (Condition Label, Icon Name) based on WMO Weather Code
        """
        code_map = {
            0: ("Clear Sky", "sunny"),
            1: ("Mainly Clear", "sunny"),
            2: ("Partly Cloudy", "partly_cloudy_day"),
            3: ("Overcast", "cloud"),
            45: ("Foggy", "foggy"),
            48: ("Depositing Rime Fog", "foggy"),
            51: ("Light Drizzle", "rainy_light"),
            53: ("Moderate Drizzle", "rainy_light"),
            55: ("Dense Drizzle", "rainy"),
            56: ("Light Freezing Drizzle", "ac_unit"),
            57: ("Dense Freezing Drizzle", "ac_unit"),
            61: ("Slight Rain", "rainy"),
            63: ("Moderate Rain", "rainy"),
            65: ("Heavy Rain", "thunderstorm"),
            66: ("Light Freezing Rain", "ac_unit"),
            67: ("Heavy Freezing Rain", "ac_unit"),
            71: ("Slight Snow", "weather_snowy"),
            73: ("Moderate Snow", "weather_snowy"),
            75: ("Heavy Snow", "weather_snowy"),
            77: ("Snow Grains", "weather_snowy"),
            80: ("Slight Rain Showers", "rainy"),
            81: ("Moderate Rain Showers", "rainy"),
            82: ("Violent Rain Showers", "thunderstorm"),
            85: ("Slight Snow Showers", "weather_snowy"),
            86: ("Heavy Snow Showers", "weather_snowy"),
            95: ("Thunderstorm", "thunderstorm"),
            96: ("Thunderstorm with Hail", "thunderstorm"),
            99: ("Heavy Thunderstorm with Hail", "thunderstorm"),
        }
        return code_map.get(weather_code, ("Mainly Clear", "partly_cloudy_day"))

    @staticmethod
    def wind_deg_to_cardinal(deg: float) -> str:
        dirs = ["N", "NNE", "NE", "ENE", "E", "ESE", "SE", "SSE", "S", "SSW", "SW", "WSW", "W", "WNW", "NW", "NNW"]
        ix = int((deg + 11.25) / 22.5) % 16
        return dirs[ix]
