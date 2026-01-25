import 'dart:typed_data';
import 'package:flutter/material.dart';
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

enum AttachmentType { image, video, document, poll, collaborativeList }

class CommunityAttachment {
  final String id;
  final AttachmentType type;
  final String path; // Local path or URL
  final String name;
  final int size;
  final Uint8List? bytes; // For web or unsaved uploads
  final Map<String, dynamic>? metadata; // Extra data (e.g. for Polls)

  const CommunityAttachment({
    required this.id,
    required this.type,
    required this.path,
    required this.name,
    required this.size,
    this.bytes,
    this.metadata,
  });

  factory CommunityAttachment.fromJson(Map<String, dynamic> json) {
    return CommunityAttachment(
      id: json['id'] as String,
      type: AttachmentType.values.firstWhere(
        (e) => e.toString() == 'AttachmentType.${json['type']}', 
        orElse: () => AttachmentType.document
      ),
      path: json['url'] ?? json['path'] ?? '',
      name: json['name'] ?? 'Attachment',
      size: json['size'] ?? 0,
      metadata: json['metadata'],
    );
  }
}

class ListEntry {
  final String userId;
  final String userName; // Denormalized for ease
  final Map<String, String> data; // key: column name, value: cell value
  final DateTime timestamp;

  const ListEntry({
    required this.userId,
    required this.userName,
    required this.data,
    required this.timestamp,
  });

  factory ListEntry.fromJson(Map<String, dynamic> json) {
    return ListEntry(
      userId: json['userId'] ?? 'unknown',
      userName: json['userName'] ?? 'User',
      data: Map<String, String>.from(json['data'] ?? {}),
      timestamp: json['timestamp'] != null 
          ? DateTime.tryParse(json['timestamp']) ?? DateTime.now() 
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
    'userId': userId,
    'userName': userName,
    'data': data,
    'timestamp': timestamp.toIso8601String(),
  };
}

class CollaborativeList {
  final String title;
  final List<String> columns;
  final List<ListEntry> entries;

  const CollaborativeList({
    required this.title,
    required this.columns,
    this.entries = const [],
  });

  factory CollaborativeList.fromJson(Map<String, dynamic> json) {
    return CollaborativeList(
      title: json['title'] ?? 'Untitled List',
      columns: List<String>.from(json['columns'] ?? ['Column 1']),
      entries: (json['entries'] as List?)
          ?.map((e) => ListEntry.fromJson(e))
          .toList() ?? [],
    );
  }
  
  Map<String, dynamic> toJson() => {
    'title': title,
    'columns': columns,
    'entries': entries.map((e) => e.toJson()).toList(),
  };
}

class PollOption {
  final String id;
  final String text;
  final int voteCount;
  final bool userVoted;

  const PollOption({
    required this.id,
    required this.text,
    this.voteCount = 0,
    this.userVoted = false,
  });

  factory PollOption.fromJson(Map<String, dynamic> json) {
    return PollOption(
      id: json['id'],
      text: json['text'],
      voteCount: json['voteCount'] ?? 0,
      userVoted: json['userVoted'] ?? false,
    );
  }
}

class Poll {
  final String question;
  final List<PollOption> options;
  final bool allowMultiple;
  final DateTime? expiresAt;
  final int totalVotes;

  const Poll({
    required this.question,
    required this.options,
    this.allowMultiple = false,
    this.expiresAt,
    this.totalVotes = 0,
  });

  factory Poll.fromJson(Map<String, dynamic> json) {
    return Poll(
      question: json['question'],
      options: (json['options'] as List).map((e) => PollOption.fromJson(e)).toList(),
      allowMultiple: json['allowMultiple'] ?? false,
      expiresAt: json['expiresAt'] != null ? DateTime.parse(json['expiresAt']) : null,
      totalVotes: json['totalVotes'] ?? 0,
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
  final List<CommunityAttachment> attachments;
  final List<MessageReaction> reactions;
  final String? replyToId;
  final ReplyMessage? replyTo;
  final bool isPinned;

  const ChannelMessage({
    required this.id,
    required this.content,
    required this.channelId,
    required this.authorId,
    this.author,
    this.isOfficial = false,
    required this.createdAt,
    this.attachments = const [],
    this.reactions = const [],
    this.replyToId,
    this.replyTo,
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
      attachments: (json['attachments'] as List<dynamic>?)
          ?.map((e) {
            try {
              return CommunityAttachment.fromJson(e);
            } catch (_) {
              return null;
            }
          })
          .where((e) => e != null)
          .cast<CommunityAttachment>()
          .toList() ?? [],
      reactions: (json['reactions'] as List<dynamic>?)
          ?.map((e) => MessageReaction.fromJson(e))
          .toList() ?? [],
      replyToId: json['replyToId'] as String?,
      replyTo: json['replyTo'] != null ? ReplyMessage.fromJson(json['replyTo']) : null,
      isPinned: json['isPinned'] as bool? ?? false,
    );
  }
  
  // Create a copyWith method for optimistic updates
  ChannelMessage copyWith({
    List<MessageReaction>? reactions,
    bool? isPinned,
    String? content,
    List<CommunityAttachment>? attachments,
  }) {
    return ChannelMessage(
      id: id,
      content: content ?? this.content,
      channelId: channelId,
      authorId: authorId,
      author: author,
      isOfficial: isOfficial,
      createdAt: createdAt,
      attachments: attachments ?? this.attachments,
      reactions: reactions ?? this.reactions,
      isPinned: isPinned ?? this.isPinned,
      replyToId: replyToId,
      replyTo: replyTo,
    );
  }
}

class ReplyMessage {
  final String id;
  final String content;
  final String authorName;
  final String? authorId;

  const ReplyMessage({
    required this.id,
    required this.content,
    required this.authorName,
    this.authorId,
  });

  factory ReplyMessage.fromJson(Map<String, dynamic> json) {
    return ReplyMessage(
      id: json['id'] as String,
      content: json['content'] as String,
      authorName: json['author']?['name'] as String? ?? 'Unknown',
      authorId: json['author']?['id'] as String?,
    );
  }
}
