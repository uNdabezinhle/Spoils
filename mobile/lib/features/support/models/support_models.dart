class SupportMessageModel {
  const SupportMessageModel({
    required this.id,
    required this.senderType,
    required this.body,
    required this.createdAt,
  });

  final int id;
  final String senderType;
  final String body;
  final String createdAt;

  bool get isUser => senderType == 'user';
  bool get isAgent => senderType == 'agent';

  factory SupportMessageModel.fromJson(Map<String, dynamic> json) {
    return SupportMessageModel(
      id: json['id'] as int,
      senderType: json['sender_type'] as String,
      body: json['body'] as String,
      createdAt: json['created_at'] as String? ?? '',
    );
  }
}

class SupportConversationModel {
  const SupportConversationModel({
    required this.id,
    required this.subject,
    required this.status,
    required this.messages,
    this.unreadCount = 0,
  });

  final int id;
  final String subject;
  final String status;
  final List<SupportMessageModel> messages;
  final int unreadCount;

  factory SupportConversationModel.fromJson(Map<String, dynamic> json) {
    return SupportConversationModel(
      id: json['id'] as int,
      subject: json['subject'] as String? ?? 'Support',
      status: json['status'] as String? ?? 'open',
      unreadCount: json['unread_count'] as int? ?? 0,
      messages: (json['messages'] as List<dynamic>?)
              ?.map((e) => SupportMessageModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}