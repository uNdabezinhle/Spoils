class OccasionModel {
  const OccasionModel({
    this.id,
    required this.type,
    required this.date,
    this.reminderDaysBefore = 14,
    this.notes = '',
    this.isActive = true,
  });

  final int? id;
  final String type;
  final String date;
  final int reminderDaysBefore;
  final String notes;
  final bool isActive;

  String get typeLabel {
    switch (type) {
      case 'birthday':
        return 'Birthday';
      case 'anniversary':
        return 'Anniversary';
      case 'just_because':
        return 'Just Because';
      default:
        return 'Other';
    }
  }

  factory OccasionModel.fromJson(Map<String, dynamic> json) {
    return OccasionModel(
      id: json['id'] as int?,
      type: json['type'] as String,
      date: json['date'] as String,
      reminderDaysBefore: json['reminder_days_before'] as int? ?? 14,
      notes: json['notes'] as String? ?? '',
      isActive: json['is_active'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
        if (id != null) 'id': id,
        'type': type,
        'date': date,
        'reminder_days_before': reminderDaysBefore,
        'notes': notes,
        'is_active': isActive,
      };
}

class RecipientModel {
  const RecipientModel({
    this.id,
    required this.name,
    required this.relationship,
    this.notes = '',
    this.popiaConsent = false,
    this.occasions = const [],
  });

  final int? id;
  final String name;
  final String relationship;
  final String notes;
  final bool popiaConsent;
  final List<OccasionModel> occasions;

  factory RecipientModel.fromJson(Map<String, dynamic> json) {
    return RecipientModel(
      id: json['id'] as int?,
      name: json['name'] as String,
      relationship: json['relationship'] as String? ?? '',
      notes: json['notes'] as String? ?? '',
      popiaConsent: json['popia_consent'] as bool? ?? false,
      occasions: (json['occasions'] as List<dynamic>?)
              ?.map((e) => OccasionModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() => {
        if (id != null) 'id': id,
        'name': name,
        'relationship': relationship,
        'notes': notes,
        'popia_consent': popiaConsent,
        'occasions': occasions.map((o) => o.toJson()).toList(),
      };
}

class UpcomingOccasionModel {
  const UpcomingOccasionModel({
    required this.id,
    required this.recipientId,
    required this.recipientName,
    required this.relationship,
    required this.type,
    required this.typeLabel,
    required this.date,
    required this.reminderDaysBefore,
    required this.daysUntil,
  });

  final int id;
  final int recipientId;
  final String recipientName;
  final String relationship;
  final String type;
  final String typeLabel;
  final String date;
  final int reminderDaysBefore;
  final int daysUntil;

  factory UpcomingOccasionModel.fromJson(Map<String, dynamic> json) {
    return UpcomingOccasionModel(
      id: json['id'] as int,
      recipientId: json['recipient_id'] as int,
      recipientName: json['recipient_name'] as String,
      relationship: json['relationship'] as String? ?? '',
      type: json['type'] as String,
      typeLabel: json['type_label'] as String? ?? json['type'] as String,
      date: json['date'] as String,
      reminderDaysBefore: json['reminder_days_before'] as int? ?? 14,
      daysUntil: json['days_until'] as int? ?? 0,
    );
  }
}