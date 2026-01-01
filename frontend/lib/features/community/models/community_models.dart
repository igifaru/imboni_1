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

class MessageReaction {
  final String emoji;
  final String userId;
  final UserModel? user; // Added user details

  const MessageReaction({
    required this.emoji,
    required this.userId,
    this.user,
  });

  factory MessageReaction.fromJson(Map<String, dynamic> json) {
    return MessageReaction(
      emoji: json['emoji'] as String,
      userId: json['userId'] as String,
      user: json['user'] != null ? UserModel.fromJson(json['user']) : null,
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
  final List<MessageReaction> reactions;
  final String? replyToId;
  final bool isPinned;

  const ChannelMessage({
    required this.id,
    required this.content,
    required this.channelId,
    required this.authorId,
    this.author,
    this.isOfficial = false,
    required this.createdAt,
    this.attachments,
    this.reactions = const [],
    this.replyToId,
    this.isPinned = false,
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
      reactions: (json['reactions'] as List<dynamic>?)
          ?.map((e) => MessageReaction.fromJson(e))
          .toList() ?? [],
      replyToId: json['replyToId'] as String?,
      isPinned: json['isPinned'] as bool? ?? false,
    );
  }
  
  // Create a copyWith method for optimistic updates
  ChannelMessage copyWith({
    List<MessageReaction>? reactions,
  }) {
    return ChannelMessage(
      id: id,
      content: content,
      channelId: channelId,
      authorId: authorId,
      author: author,
      isOfficial: isOfficial,
      createdAt: createdAt,
      attachments: attachments,
      reactions: reactions ?? this.reactions,
      replyToId: replyToId,
      isPinned: isPinned,
    );
  }
}
