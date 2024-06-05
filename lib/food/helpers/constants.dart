enum MealType {
  lunch,
  dinner,
}

extension MealTypeExtension on MealType {
  String get label {
    switch (this) {
      case MealType.lunch:
        return 'Lunch';
      case MealType.dinner:
        return 'Diner';
    }
  }
}

MealType mealTypeFromValue(String value) {
  switch (value.toLowerCase()) {
    case 'lunch':
      return MealType.lunch;
    case 'dinner':
      return MealType.dinner;
    default:
      throw ArgumentError('Invalid meal type: $value');
  }
}

enum Presence {
  none,
  tanja,
  mattanja,
  all,
}

extension PresenceExtension on Presence {
  String get value {
    switch (this) {
      case Presence.none:
        return 'niemand';
      case Presence.tanja:
        return 'Tanja';
      case Presence.mattanja:
        return 'Mattanja';
      case Presence.all:
        return 'allebei';
    }
  }

  int get count {
    switch (this) {
      case Presence.none:
        return 0;
      case Presence.tanja:
        return 1;
      case Presence.mattanja:
        return 1;
      case Presence.all:
        return 2;
    }
  }
}

extension PresenceExtensionCount on Presence {}

enum WeekDay {
  monday,
  tuesday,
  wednesday,
  thursday,
  friday,
  saturday,
  sunday,
}

extension WeekDayExtension on WeekDay {
  String get value {
    switch (this) {
      case WeekDay.monday:
        return 'maandag';
      case WeekDay.tuesday:
        return 'dinsdag';
      case WeekDay.wednesday:
        return 'woensdag';
      case WeekDay.thursday:
        return 'donderdag';
      case WeekDay.friday:
        return 'vrijdag';
      case WeekDay.saturday:
        return 'zaterdag';
      case WeekDay.sunday:
        return 'zondag';
    }
  }

  int get number {
    return index + 1;
  }
}
