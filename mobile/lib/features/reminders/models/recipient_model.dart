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

class OccasionDetailModel {
  const OccasionDetailModel({
    required this.id,
    required this.recipientId,
    required this.recipientName,
    required this.relationship,
    required this.type,
    required this.typeLabel,
    required this.date,
    required this.daysUntil,
    this.recipientNotes = '',
    this.occasionNotes = '',
    this.snoozedUntil,
    this.skippedThisYear = false,
    this.pendingAutoGift,
    this.shareWithFamily = false,
    this.surpriseModeEnabled = false,
    this.surpriseBudget,
    this.giftAnonymously = false,
    this.surpriseAddressId,
  });

  final int id;
  final int recipientId;
  final String recipientName;
  final String relationship;
  final String type;
  final String typeLabel;
  final String date;
  final int daysUntil;
  final String recipientNotes;
  final String occasionNotes;
  final String? snoozedUntil;
  final bool skippedThisYear;
  final Map<String, dynamic>? pendingAutoGift;
  final bool shareWithFamily;
  final bool surpriseModeEnabled;
  final String? surpriseBudget;
  final bool giftAnonymously;
  final int? surpriseAddressId;

  bool get hasPendingAutoGift => pendingAutoGift != null;

  factory OccasionDetailModel.fromJson(Map<String, dynamic> json) {
    return OccasionDetailModel(
      id: json['id'] as int,
      recipientId: json['recipient_id'] as int,
      recipientName: json['recipient_name'] as String,
      relationship: json['relationship'] as String? ?? '',
      type: json['type'] as String,
      typeLabel: json['type_label'] as String? ?? json['type'] as String,
      date: json['date'] as String,
      daysUntil: json['days_until'] as int? ?? 0,
      recipientNotes: json['recipient_notes'] as String? ?? '',
      occasionNotes: json['occasion_notes'] as String? ?? '',
      snoozedUntil: json['snoozed_until'] as String?,
      skippedThisYear: json['skipped_this_year'] as bool? ?? false,
      pendingAutoGift: json['pending_auto_gift'] as Map<String, dynamic>?,
      shareWithFamily: json['share_with_family'] as bool? ?? false,
      surpriseModeEnabled: json['surprise_mode_enabled'] as bool? ?? false,
      surpriseBudget: json['surprise_budget'] as String?,
      giftAnonymously: json['gift_anonymously'] as bool? ?? false,
      surpriseAddressId: json['surprise_address_id'] as int?,
    );
  }
}

class CalendarMonthModel {
  const CalendarMonthModel({
    required this.year,
    required this.month,
    required this.monthName,
    required this.daysInMonth,
    required this.events,
  });

  final int year;
  final int month;
  final String monthName;
  final int daysInMonth;
  final Map<String, List<UpcomingOccasionModel>> events;

  factory CalendarMonthModel.fromJson(Map<String, dynamic> json) {
    final raw = json['events'] as Map<String, dynamic>? ?? {};
    final events = <String, List<UpcomingOccasionModel>>{};
    raw.forEach((key, value) {
      events[key] = (value as List<dynamic>)
          .map((e) => UpcomingOccasionModel.fromJson(e as Map<String, dynamic>))
          .toList();
    });
    return CalendarMonthModel(
      year: json['year'] as int,
      month: json['month'] as int,
      monthName: json['month_name'] as String? ?? '',
      daysInMonth: json['days_in_month'] as int? ?? 30,
      events: events,
    );
  }
}

class InAppReminderModel {
  const InAppReminderModel({
    required this.id,
    required this.recipientName,
    required this.type,
    required this.typeLabel,
    required this.date,
    required this.daysUntil,
    required this.message,
    required this.shopOccasion,
  });

  final int id;
  final String recipientName;
  final String type;
  final String typeLabel;
  final String date;
  final int daysUntil;
  final String message;
  final String shopOccasion;

  factory InAppReminderModel.fromJson(Map<String, dynamic> json) {
    return InAppReminderModel(
      id: json['id'] as int,
      recipientName: json['recipient_name'] as String,
      type: json['type'] as String,
      typeLabel: json['type_label'] as String? ?? json['type'] as String,
      date: json['date'] as String,
      daysUntil: json['days_until'] as int? ?? 0,
      message: json['message'] as String? ?? '',
      shopOccasion: json['shop_occasion'] as String? ?? json['type'] as String,
    );
  }
}

class FamilyOccasionEvent {
  const FamilyOccasionEvent({
    required this.id,
    required this.recipientName,
    required this.ownerEmail,
    required this.type,
    required this.typeLabel,
    required this.date,
    required this.daysUntil,
    this.surpriseModeEnabled = false,
  });

  final int id;
  final String recipientName;
  final String ownerEmail;
  final String type;
  final String typeLabel;
  final String date;
  final int daysUntil;
  final bool surpriseModeEnabled;

  factory FamilyOccasionEvent.fromJson(Map<String, dynamic> json) {
    return FamilyOccasionEvent(
      id: json['id'] as int,
      recipientName: json['recipient_name'] as String,
      ownerEmail: json['owner_email'] as String? ?? '',
      type: json['type'] as String,
      typeLabel: json['type_label'] as String? ?? json['type'] as String,
      date: json['date'] as String,
      daysUntil: json['days_until'] as int? ?? 0,
      surpriseModeEnabled: json['surprise_mode_enabled'] as bool? ?? false,
    );
  }
}

class FamilyGroupModel {
  const FamilyGroupModel({
    required this.id,
    required this.name,
    required this.inviteCode,
    required this.isOwner,
    required this.members,
  });

  final int id;
  final String name;
  final String inviteCode;
  final bool isOwner;
  final List<FamilyMemberModel> members;

  factory FamilyGroupModel.fromJson(Map<String, dynamic> json) {
    return FamilyGroupModel(
      id: json['id'] as int,
      name: json['name'] as String,
      inviteCode: json['invite_code'] as String,
      isOwner: json['is_owner'] as bool? ?? false,
      members: (json['members'] as List<dynamic>?)
              ?.map((e) => FamilyMemberModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

class FamilyMemberModel {
  const FamilyMemberModel({
    required this.userId,
    required this.email,
    required this.displayName,
    required this.role,
  });

  final int userId;
  final String email;
  final String displayName;
  final String role;

  factory FamilyMemberModel.fromJson(Map<String, dynamic> json) {
    return FamilyMemberModel(
      userId: json['user_id'] as int,
      email: json['email'] as String,
      displayName: json['display_name'] as String? ?? json['email'] as String,
      role: json['role'] as String? ?? 'member',
    );
  }
}

class FamilyCalendarMonthModel {
  const FamilyCalendarMonthModel({
    required this.year,
    required this.month,
    required this.monthName,
    required this.daysInMonth,
    required this.events,
    required this.groupName,
  });

  final int year;
  final int month;
  final String monthName;
  final int daysInMonth;
  final Map<String, List<FamilyOccasionEvent>> events;
  final String groupName;

  factory FamilyCalendarMonthModel.fromJson(Map<String, dynamic> json) {
    final raw = json['events'] as Map<String, dynamic>? ?? {};
    final events = <String, List<FamilyOccasionEvent>>{};
    raw.forEach((key, value) {
      events[key] = (value as List<dynamic>)
          .map((e) => FamilyOccasionEvent.fromJson(e as Map<String, dynamic>))
          .toList();
    });
    return FamilyCalendarMonthModel(
      year: json['year'] as int,
      month: json['month'] as int,
      monthName: json['month_name'] as String? ?? '',
      daysInMonth: json['days_in_month'] as int? ?? 30,
      events: events,
      groupName: json['group_name'] as String? ?? '',
    );
  }
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