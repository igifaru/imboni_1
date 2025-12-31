import 'package:imboni/shared/models/models.dart';

enum ChannelType {
  official,
  community,
}

enum ChannelRole {
  member,
  moderator,
}

class CommunityChannel {
  final String id;
  final String administrativeUnitId;
  final String name;
  final ChannelType type;
  final String? category;
  final AdministrativeUnitSummary? unit;
  final int messageCount;
  final int memberCount;

  const CommunityChannel({
    required this.id,
    required this.administrativeUnitId,
    required this.name,
    required this.type,
    this.category,
    this.unit,
    this.messageCount = 0,
    this.memberCount = 0,
  });

  factory CommunityChannel.fromJson(Map<String, dynamic> json) {
    return CommunityChannel(
      id: json['id'] as String,
      administrativeUnitId: json['administrativeUnitId'] as String,
      name: json['name'] as String,
      type: json['type'] == 'OFFICIAL' ? ChannelType.official : ChannelType.community,
      category: json['category'] as String?,
      unit: json['administrativeUnit'] != null ? AdministrativeUnitSummary.fromJson(json['administrativeUnit']) : null,
      messageCount: json['_count']?['messages'] ?? 0,
      memberCount: json['_count']?['memberships'] ?? 0,
    );
  }
}

class AdministrativeUnitSummary {
  final String name;
  final String level;

  const AdministrativeUnitSummary({required this.name, required this.level});

  factory AdministrativeUnitSummary.fromJson(Map<String, dynamic> json) {
    return AdministrativeUnitSummary(
      name: json['name'] as String,
      level: json['level'] as String,
    );
  }
}

class ChannelMessage {
  final String id;
  final String content;
  final String channelId;
  final String authorId;
  final UserModel? author;
  final bool isOfficial;
  final DateTime createdAt;
  final dynamic attachments;

  const ChannelMessage({
    required this.id,
    required this.content,
    required this.channelId,
    required this.authorId,
    this.author,
    this.isOfficial = false,
    required this.createdAt,
    this.attachments,
  });

  factory ChannelMessage.fromJson(Map<String, dynamic> json) {
    return ChannelMessage(
      id: json['id'] as String,
      content: json['content'] as String,
      channelId: json['channelId'] as String,
      authorId: json['authorId'] as String,
      author: json['author'] != null ? UserModel.fromJson(json['author']) : null,
      isOfficial: json['isOfficial'] as bool? ?? false,
      createdAt: DateTime.parse(json['createdAt'] as String),
      attachments: json['attachments'],
    );
  }
}
