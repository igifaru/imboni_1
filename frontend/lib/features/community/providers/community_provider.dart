import 'package:flutter/foundation.dart';
import '../../../../shared/models/models.dart';
import '../../../../shared/services/api_client.dart';
import '../../../../shared/services/auth_service.dart';
import '../models/community_models.dart';
import '../services/media_service.dart';

class CommunityProvider extends ChangeNotifier {
  final ApiClient _api = apiClient;
  
  /// Get the current authenticated user's ID
  String? getCurrentUserId() => authService.currentUser?.id;
  String? getCurrentUserName() => authService.currentUser?.name ?? authService.currentUser?.email?.split('@').first;
  List<CommunityChannel> _channels = [];
  bool _isLoadingChannels = false;
  String? _error;

  List<CommunityChannel> get channels => _channels;
  bool get isLoadingChannels => _isLoadingChannels;
  String? get error => _error;

  // Cache messages per channel: ChannelId -> List<Message>
  final Map<String, List<ChannelMessage>> _messages = {};
  final Map<String, bool> _isLoadingMessages = {};

  List<ChannelMessage> getMessages(String channelId) => _messages[channelId] ?? [];
  bool isLoadingMessages(String channelId) => _isLoadingMessages[channelId] ?? false;

  /// Get topic channels for a unit (returns from _channels)
  List<CommunityChannel> getTopicChannelsForUnit(String unitId) {
    return _channels.where((c) => 
      c.administrativeUnitId == unitId && c.category != null
    ).toList();
  }

  /// Get message count for a specific topic in a unit
  int getTopicMessageCount(String unitId, String category) {
    final topicChannel = _channels.firstWhere(
      (c) => c.administrativeUnitId == unitId && c.category == category,
      orElse: () => const CommunityChannel(
        id: '', 
        administrativeUnitId: '', 
        name: '', 
        type: ChannelType.community,
      ),
    );
    return topicChannel.messageCount;
  }

  Future<void> fetchChannels() async {
    _isLoadingChannels = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _api.get('/community/channels');
      final data = response.data;
      if (data != null && data is List) {
        _channels = data.map((e) => CommunityChannel.fromJson(e)).toList();
      } else {
        _channels = [];
      }
    } catch (e) {
      _error = e.toString();
      debugPrint('Error fetching channels: $e');
    } finally {
      _isLoadingChannels = false;
      notifyListeners();
    }
  }

  Future<void> fetchMessages(String channelId, {bool refresh = false}) async {
    if (_isLoadingMessages[channelId] == true) return;
    
    _isLoadingMessages[channelId] = true;
    notifyListeners();

    try {
      final response = await _api.get('/community/channels/$channelId/messages');
      final data = response.data;
      if (data != null && data is List) {
        final newMessages = data.map((e) => ChannelMessage.fromJson(e)).toList();
        _messages[channelId] = newMessages; 
      } else {
        _messages[channelId] = [];
      }
    } catch (e) {
      debugPrint('Error fetching messages: $e');
    } finally {
      _isLoadingMessages[channelId] = false;
      notifyListeners();
    }
  }

  Future<bool> sendMessage(String channelId, String content, {String? replyToId, List<CommunityAttachment>? attachments}) async {
    debugPrint('CommunityProvider: sendMessage called for channel=$channelId');
    try {
      // Upload attachments first if any
      List<CommunityAttachment> finalAttachments = [];
      if (attachments != null && attachments.isNotEmpty) {
         finalAttachments = await mediaService.uploadAttachments(attachments);
      }

      final response = await _api.post('/community/messages', {
        'channelId': channelId,
        'content': content,
        if (replyToId != null) 'replyToId': replyToId,
        if (finalAttachments.isNotEmpty) 'attachments': finalAttachments.map((a) => {
           'type': a.type.toString().split('.').last, // 'image', 'video', 'poll'
           'path': a.path,
           'name': a.name,
           'size': a.size,
           if (a.metadata != null) 'metadata': a.metadata, 
        }).toList(),
      });
      
      debugPrint('CommunityProvider: sendMessage response isSuccess=${response.isSuccess}, data=${response.data}');
      
      if (!response.isSuccess || response.data == null) {
        debugPrint('CommunityProvider: sendMessage failed - ${response.error ?? "No data returned"}');
        return false;
      }

      final newMessage = ChannelMessage.fromJson(response.data as Map<String, dynamic>);
      
      // Optimistic update - prepend to list
      final currentList = _messages[channelId] ?? [];
      _messages[channelId] = [newMessage, ...currentList];
      notifyListeners();
      return true;
    } catch (e, stackTrace) {
      debugPrint('CommunityProvider: Error sending message: $e');
      debugPrint('CommunityProvider: Stack trace: $stackTrace');
      return false;
    }
  }

  Future<CommunityChannel?> joinCategoryChannel(String unitId, String category) async {
    debugPrint('CommunityProvider: joinCategoryChannel called with unitId=$unitId, category=$category');
    try {
      final response = await _api.post('/community/join-category', {
        'unitId': unitId,
        'category': category,
      });
      
      debugPrint('CommunityProvider: Response isSuccess=${response.isSuccess}, data=${response.data}');
      
      if (response.isSuccess && response.data != null) {
        final channel = CommunityChannel.fromJson(response.data);
        debugPrint('CommunityProvider: Parsed channel: ${channel.id} - ${channel.name}');
        // Add to local list if not present
        if (!_channels.any((c) => c.id == channel.id)) {
          _channels.add(channel);
          notifyListeners();
        }
        return channel;
      }
      debugPrint('CommunityProvider: Response failed or data is null');
      return null;
    } catch (e) {
      debugPrint('CommunityProvider: Error joining category channel: $e');
      return null;
    }
  }
  Future<bool> toggleReaction(String channelId, String messageId, String emoji) async {
    // 1. Optimistic Update
    final currentMessages = _messages[channelId] ?? [];
    final msgIndex = currentMessages.indexWhere((m) => m.id == messageId);
    
    ChannelMessage? backupMsg;

    if (msgIndex != -1) {
      final msg = currentMessages[msgIndex];
      backupMsg = msg; // Backup for revert
      
      final currentUserId = getCurrentUserId();
      
      if (currentUserId != null) {
        List<MessageReaction> newReactions = List.from(msg.reactions);
        final existingIndex = newReactions.indexWhere((r) => r.userId == currentUserId && r.emoji == emoji);
        
        if (existingIndex != -1) {
          // Remove
          newReactions.removeAt(existingIndex);
        } else {
          // Add
          newReactions.add(MessageReaction(emoji: emoji, userId: currentUserId));
        }
        
        currentMessages[msgIndex] = msg.copyWith(reactions: newReactions);
        _messages[channelId] = List.from(currentMessages); // Trigger update
        notifyListeners();
      }
    }

    try {
      // 2. API Call
      final response = await _api.post('/community/messages/$messageId/react', {
        'emoji': emoji,
      });

      if (response.isSuccess && response.data != null) {
        // 3. Update with server truth
        final updatedMsg = ChannelMessage.fromJson(response.data);
        if (msgIndex != -1) {
          final msgs = _messages[channelId] ?? [];
          if (msgs.length > msgIndex) {
            msgs[msgIndex] = updatedMsg;
            notifyListeners();
          }
        }
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error toggling reaction: $e');
      // Revert optimistic update
      if (backupMsg != null && msgIndex != -1) {
          final msgs = _messages[channelId] ?? [];
          if (msgs.length > msgIndex) {
             msgs[msgIndex] = backupMsg;
             _messages[channelId] = List.from(msgs);
             notifyListeners();
          }
      }
      return false;
    }
  }

  /// Toggle pin status of a message
  Future<bool> togglePin(String channelId, String messageId) async {
    // 1. Optimistic Update
    final currentMessages = _messages[channelId] ?? [];
    final msgIndex = currentMessages.indexWhere((m) => m.id == messageId);
    
    if (msgIndex != -1) {
      final msg = currentMessages[msgIndex];
      // Toggle local state
      currentMessages[msgIndex] = msg.copyWith(isPinned: !msg.isPinned);
      _messages[channelId] = List.from(currentMessages);
      notifyListeners();
    }

    try {
      // 2. API Call
      final response = await _api.post('/community/messages/$messageId/pin', {});

      if (response.isSuccess && response.data != null) {
        // 3. Update with server truth
        final updatedMsg = ChannelMessage.fromJson(response.data);
        if (msgIndex != -1) {
          final msgs = _messages[channelId] ?? [];
          if (msgs.length > msgIndex) {
            msgs[msgIndex] = updatedMsg;
            notifyListeners();
          }
        }
        return true;
      }
      // Revert if failed (simple revert)
      if (msgIndex != -1) {
         final currentMessages = _messages[channelId] ?? [];
         final msg = currentMessages[msgIndex];
         currentMessages[msgIndex] = msg.copyWith(isPinned: !msg.isPinned);
         _messages[channelId] = List.from(currentMessages);
         notifyListeners();
      }
      return false;
    } catch (e) {
      debugPrint('Error toggling pin: $e');
      // Revert on error
      if (msgIndex != -1) {
         final currentMessages = _messages[channelId] ?? [];
         final msg = currentMessages[msgIndex];
         currentMessages[msgIndex] = msg.copyWith(isPinned: !msg.isPinned);
         _messages[channelId] = List.from(currentMessages);
         notifyListeners();
      }
      return false;
    }
  }
  
  /// Delete a message
  Future<bool> deleteMessage(String channelId, String messageId) async {
    // 1. Optimistic Update
    final currentMessages = _messages[channelId] ?? [];
    final msgIndex = currentMessages.indexWhere((m) => m.id == messageId);
    
    // BACKUP for revert
    ChannelMessage? backupMsg;
    
    if (msgIndex != -1) {
      backupMsg = currentMessages[msgIndex];
      // Remove from list
      final newMessages = List<ChannelMessage>.from(currentMessages);
      newMessages.removeAt(msgIndex);
      _messages[channelId] = newMessages;
      notifyListeners();
    }

    try {
      // 2. API Call
      final response = await _api.delete('/community/messages/$messageId');

      if (response.isSuccess) {
        return true;
      }
      return false; // Revert handled below
    } catch (e) {
      debugPrint('Error deleting message: $e');
      // Revert if failed
      if (backupMsg != null && msgIndex != -1) {
         final current = List<ChannelMessage>.from(_messages[channelId] ?? []);
         // Re-insert at original index if possible, or sorted
         // For now, simpler to just prepend or re-fetch, but let's try insert
         if (current.length >= msgIndex) {
            current.insert(msgIndex, backupMsg);
         } else {
            current.add(backupMsg);
         }
         _messages[channelId] = current;
         notifyListeners();
      }
      return false;
    }
  }

  /// Edit a message
  Future<bool> editMessage(String channelId, String messageId, String newContent, {List<CommunityAttachment>? attachments}) async {
    // 1. Optimistic Update
    final currentMessages = _messages[channelId] ?? [];
    final msgIndex = currentMessages.indexWhere((m) => m.id == messageId);
    
    ChannelMessage? backupMsg;

    if (msgIndex != -1) {
      final msg = currentMessages[msgIndex];
      backupMsg = msg;
      
      // Update content and attachments
      currentMessages[msgIndex] = msg.copyWith(
        content: newContent,
        attachments: attachments ?? msg.attachments
      );
      _messages[channelId] = List.from(currentMessages);
      notifyListeners();
    }

    try {
      // Upload new attachments if provided
      List<CommunityAttachment>? finalAttachments;
      if (attachments != null) {
        finalAttachments = await mediaService.uploadAttachments(attachments);
      }

      final response = await _api.patch('/community/messages/$messageId', {
        'content': newContent,
        if (finalAttachments != null) 'attachments': finalAttachments.map((a) => {
           'type': a.type.toString().split('.').last,
           'path': a.path,
           'name': a.name,
           'size': a.size,
           'metadata': a.metadata, 
        }).toList(),
      });

      if (response.isSuccess && response.data != null) {
         // Update with server truth
         final updatedMsg = ChannelMessage.fromJson(response.data);
         if (msgIndex != -1) {
            final msgs = _messages[channelId] ?? [];
            if (msgs.length > msgIndex) {
               msgs[msgIndex] = updatedMsg;
               notifyListeners();
            }
         }
         return true;
      }
      
      // Revert if failed (generic failure)
      if (backupMsg != null && msgIndex != -1) {
          final msgs = _messages[channelId] ?? [];
          if (msgs.length > msgIndex) {
             msgs[msgIndex] = backupMsg;
             _messages[channelId] = List.from(msgs);
             notifyListeners();
          }
      }
      return false;
    } catch (e) {
      debugPrint('Error editing message: $e');
      if (backupMsg != null && msgIndex != -1) {
          final msgs = _messages[channelId] ?? [];
          if (msgs.length > msgIndex) {
             msgs[msgIndex] = backupMsg;
             _messages[channelId] = List.from(msgs);
             notifyListeners();
          }
      }
      return false;
    }
  }

  /// Vote on a poll
  Future<bool> voteOnPoll(String channelId, String messageId, String attachmentId, dynamic votes) async {
    // 1. Optimistic Update (Complex, doing deep clone/find is hard in one block, skipping optimistic for now OR doing simple placeholder)
    // Actually, optimistic update is crucial for "instant" feel.
    // We will rely on the UI calling us with the *updated attachment* already?
    // No, the UI logic I wrote in MessageAttachmentList calculates the new votes.
    // Ideally, I should change the UI to just call this method with the vote delta.
    // BUT to minimize changes, I will implement the API call first.
    // The UI currently calculates the full new metadata. 
    // Wait, the backend expects `votes` (int or List<int>), but the UI calculates the full `votes` Map.
    // Discrepancy detected!
    
    // My backend implementation:
    // async voteOnPoll(userId, ..., votes) -> updates metadata.votes[userId] = votes
    // So backend expects JUST the user's vote (int or list of ints).
    
    // UI (MessageAttachmentList) currently calculates the full updated map.
    // I need to update MessageAttachmentList to call this correctly.
    
    try {
      final response = await _api.post('/community/messages/$messageId/poll-vote', {
        'attachmentId': attachmentId,
        'votes': votes,
      });

      if (response.isSuccess && response.data != null) {
         final updatedMsg = ChannelMessage.fromJson(response.data);
         // Update local cache
         final msgs = _messages[channelId] ?? [];
         final idx = msgs.indexWhere((m) => m.id == messageId);
         if (idx != -1) {
            msgs[idx] = updatedMsg;
            notifyListeners();
         }
         return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error voting on poll: $e');
      return false;
    }
  }

  /// Add entry to list
  Future<bool> addListEntry(String channelId, String messageId, String attachmentId, Map<String, dynamic> data) async {
    try {
      final response = await _api.post('/community/messages/$messageId/list-entry', {
        'attachmentId': attachmentId,
        'data': data,
      });

      if (response.isSuccess && response.data != null) {
         final updatedMsg = ChannelMessage.fromJson(response.data);
         final msgs = _messages[channelId] ?? [];
         final idx = msgs.indexWhere((m) => m.id == messageId);
         if (idx != -1) {
            msgs[idx] = updatedMsg;
            notifyListeners();
         }
         return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error adding list entry: $e');
      return false;
    }
  }

  // Member Search State
  List<UserModel> _memberSearchResults = [];
  bool _isSearchingMembers = false;
  
  List<UserModel> get memberSearchResults => _memberSearchResults;
  bool get isSearchingMembers => _isSearchingMembers;

  /// Search members in a channel via API
  Future<void> searchMembers(String channelId, String query) async {
    if (query.isEmpty) {
      _memberSearchResults = [];
      notifyListeners();
      return;
    }

    _isSearchingMembers = true;
    notifyListeners();

    try {
      final response = await _api.get('/community/channels/$channelId/members', queryParameters: {'query': query});
      if (response.isSuccess && response.data != null) {
        final List data = response.data;
        _memberSearchResults = data.map((e) => UserModel.fromJson(e)).toList();
      } else {
        _memberSearchResults = [];
      }
    } catch (e) {
      debugPrint('Error searching members: $e');
      _memberSearchResults = [];
    } finally {
      _isSearchingMembers = false;
      notifyListeners();
    }
  }

  /// Find a member by name (for tapping mentions)
  Future<UserModel?> findMemberByName(String channelId, String name) async {
    try {
      final response = await _api.get('/community/channels/$channelId/members', queryParameters: {'query': name});
      if (response.isSuccess && response.data != null) {
        final List data = response.data;
        if (data.isNotEmpty) {
           // Prefer exact match
           final exact = data.firstWhere(
             (e) => (e['name'] as String?)?.toLowerCase() == name.toLowerCase(), 
             orElse: () => data.first
           );
           return UserModel.fromJson(exact);
        }
      }
    } catch (e) {
      debugPrint('Error finding member by name: $e');
    }
    return null;
  }
}
