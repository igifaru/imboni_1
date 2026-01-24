import 'package:flutter/foundation.dart';
import '../../../../shared/services/api_client.dart';
import '../models/community_models.dart';

class MediaService {
  final ApiClient _api = apiClient;

  /// Uploads a list of attachments and returns the updated list with server URLs
  Future<List<CommunityAttachment>> uploadAttachments(List<CommunityAttachment> attachments) async {
    final List<CommunityAttachment> uploaded = [];

    for (var attachment in attachments) {
      // Skip if already uploaded (has http URL) or is metadata-only (Poll, List)
      if (attachment.path.startsWith('http') || 
          attachment.type == AttachmentType.poll || 
          attachment.type == AttachmentType.collaborativeList) {
        uploaded.add(attachment);
        continue;
      }

      // Skip invalid paths
      if (attachment.path.isEmpty) {
         uploaded.add(attachment);
         continue;
      }

      try {
        // Upload file
        // Using generic upload endpoint for now, or community specific if available
        // Assuming POST /upload returns { url: "..." }
        final response = await _api.uploadFile<Map<String, dynamic>>(
          '/upload', // Endpoint
          attachment.path,
          fieldName: 'file',
        );

        if (response.isSuccess && response.data != null) {
          final url = response.data!['url'] as String;
          
          // Return new attachment with Server URL
          uploaded.add(CommunityAttachment(
            id: attachment.id,
            type: attachment.type,
            path: url, // Server URL
            name: attachment.name,
            size: attachment.size,
            metadata: attachment.metadata,
          ));
        } else {
          debugPrint('Failed to upload ${attachment.name}: ${response.error}');
          // Keep original if failed (or throw error?)
          // For now keep original so user sees failure or basic local fallback (if supported)
          uploaded.add(attachment);
        }
      } catch (e) {
        debugPrint('Error uploading file: $e');
        uploaded.add(attachment);
      }
    }
    return uploaded;
  }
}

final mediaService = MediaService();
