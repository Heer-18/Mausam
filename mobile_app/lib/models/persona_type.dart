import 'package:flutter/material.dart';

enum PersonaType {
  health,
  fitness,
  beach,
  travel,
  farm,
  commute,
  events,
  family,
  work;

  String get displayName {
    switch (this) {
      case PersonaType.health:
        return 'Health-Conscious';
      case PersonaType.fitness:
        return 'Fitness & Athlete';
      case PersonaType.beach:
        return 'Beach & Surfer';
      case PersonaType.travel:
        return 'Traveler & Explorer';
      case PersonaType.farm:
        return 'Agriculture & Farm';
      case PersonaType.commute:
        return 'Daily Commuter';
      case PersonaType.events:
        return 'Event Planner';
      case PersonaType.family:
        return 'Family & School';
      case PersonaType.work:
        return 'Outdoor Work';
    }
  }

  String get shortTitle {
    switch (this) {
      case PersonaType.health:
        return 'Health';
      case PersonaType.fitness:
        return 'Fitness';
      case PersonaType.beach:
        return 'Beach';
      case PersonaType.travel:
        return 'Travel';
      case PersonaType.farm:
        return 'Farm';
      case PersonaType.commute:
        return 'Commute';
      case PersonaType.events:
        return 'Events';
      case PersonaType.family:
        return 'Family';
      case PersonaType.work:
        return 'Work';
    }
  }

  String get subtitle {
    switch (this) {
      case PersonaType.health:
        return 'Allergy & Skin';
      case PersonaType.fitness:
        return 'Workout Planner';
      case PersonaType.beach:
        return 'Surf & Swim';
      case PersonaType.travel:
        return 'Destinations';
      case PersonaType.farm:
        return 'Crop Health';
      case PersonaType.commute:
        return 'Traffic & Alerts';
      case PersonaType.events:
        return 'Outdoor Plans';
      case PersonaType.family:
        return 'School & Safety';
      case PersonaType.work:
        return 'Safety First';
    }
  }

  IconData get icon {
    switch (this) {
      case PersonaType.health:
        return Icons.favorite_rounded;
      case PersonaType.fitness:
        return Icons.directions_run_rounded;
      case PersonaType.beach:
        return Icons.beach_access_rounded;
      case PersonaType.travel:
        return Icons.flight_rounded;
      case PersonaType.farm:
        return Icons.eco_rounded;
      case PersonaType.commute:
        return Icons.directions_car_rounded;
      case PersonaType.events:
        return Icons.calendar_month_rounded;
      case PersonaType.family:
        return Icons.people_alt_rounded;
      case PersonaType.work:
        return Icons.engineering_rounded;
    }
  }

  Color get accentColor {
    switch (this) {
      case PersonaType.health:
        return const Color(0xFFC2C1FF);
      case PersonaType.fitness:
        return const Color(0xFF8B5CF6);
      case PersonaType.beach:
        return const Color(0xFF06B6D4);
      case PersonaType.travel:
        return const Color(0xFFADC6FF);
      case PersonaType.farm:
        return const Color(0xFF10B981);
      case PersonaType.commute:
        return const Color(0xFFF59E0B);
      case PersonaType.events:
        return const Color(0xFFFFBC7C);
      case PersonaType.family:
        return const Color(0xFF38BDF8);
      case PersonaType.work:
        return const Color(0xFFFB923C);
    }
  }
}
