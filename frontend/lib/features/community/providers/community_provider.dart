import 'package:flutter/foundation.dart';
import '../../../../shared/services/api_client.dart';
import '../models/community_models.dart';

class CommunityProvider extends ChangeNotifier {
  final ApiClient _api = apiClient;
  
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

  Future<bool> sendMessage(String channelId, String content) async {
    try {
      final response = await _api.post('/community/messages', {
        'channelId': channelId,
        'content': content,
      });
      
      final newMessage = ChannelMessage.fromJson(response.data);
      
      // Optimistic update
      final currentList = _messages[channelId] ?? [];
      _messages[channelId] = [newMessage, ...currentList]; // Prepend
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error sending message: $e');
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
}
