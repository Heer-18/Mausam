class AppConstants {
  static const String appName = 'Mausam';
  static const String appTagline = 'Personalized Weather & Lifestyle Intelligence';
  
  // Gemini API Key Default Fallback (loaded securely via .env or settings)
  static const String defaultGeminiApiKey = '';

  // OpenWeather API Key Default Fallback (loaded securely via .env or settings)
  static const String defaultOpenWeatherApiKey = '';

  // Default fallback if GPS is denied and no prior location chosen
  static const double fallbackLat = 28.6139; // New Delhi
  static const double fallbackLon = 77.2090;
  static const String fallbackCityName = 'New Delhi, India';

  // Open-Meteo Endpoints
  static const String forecastApiUrl = 'https://api.open-meteo.com/v1/forecast';
  static const String airQualityApiUrl = 'https://air-quality-api.open-meteo.com/v1/air-quality';
  static const String marineApiUrl = 'https://marine-api.open-meteo.com/v1/marine';
  static const String geocodingApiUrl = 'https://geocoding-api.open-meteo.com/v1/search';

  // Popular Indian Cities for instant picker
  static const List<Map<String, dynamic>> popularCities = [
    {'name': 'New Delhi', 'state': 'Delhi', 'lat': 28.6139, 'lon': 77.2090},
    {'name': 'Mumbai', 'state': 'Maharashtra', 'lat': 19.0760, 'lon': 72.8777},
    {'name': 'Bengaluru', 'state': 'Karnataka', 'lat': 12.9716, 'lon': 77.5946},
    {'name': 'Ahmedabad', 'state': 'Gujarat', 'lat': 23.0225, 'lon': 72.5714},
    {'name': 'Nadiad', 'state': 'Gujarat', 'lat': 22.6916, 'lon': 72.8634},
    {'name': 'Pune', 'state': 'Maharashtra', 'lat': 18.5204, 'lon': 73.8567},
    {'name': 'Kolkata', 'state': 'West Bengal', 'lat': 22.5726, 'lon': 88.3639},
    {'name': 'Hyderabad', 'state': 'Telangana', 'lat': 17.3850, 'lon': 78.4867},
    {'name': 'Chennai', 'state': 'Tamil Nadu', 'lat': 13.0827, 'lon': 80.2707},
    {'name': 'Surat', 'state': 'Gujarat', 'lat': 21.1702, 'lon': 72.8311},
    {'name': 'Jaipur', 'state': 'Rajasthan', 'lat': 26.9124, 'lon': 75.7873},
    {'name': 'Chandigarh', 'state': 'Punjab', 'lat': 30.7333, 'lon': 76.7794},
  ];
}
