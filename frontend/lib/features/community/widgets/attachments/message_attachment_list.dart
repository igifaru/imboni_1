import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/community_models.dart';
import '../../providers/community_provider.dart';
import 'collaborative_list_view.dart';
import 'file_attachment_widget.dart';

class MessageAttachmentList extends StatelessWidget {
  final List<CommunityAttachment> attachments;
  final bool isOwnMessage;
  final String channelId;
  final String messageId;
  final String currentUserId;
  final String currentUserName;

  const MessageAttachmentList({
    super.key,
    required this.attachments,
    required this.isOwnMessage,
    required this.channelId,
    required this.messageId,
    required this.currentUserId,
    this.currentUserName = 'User',
  });

  @override
  Widget build(BuildContext context) {
    if (attachments.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: attachments.map((attachment) {
        return Padding(
          padding: const EdgeInsets.only(top: 8.0),
          child: _buildAttachmentItem(context, attachment),
        );
      }).toList(),
    );
  }

  Widget _buildAttachmentItem(BuildContext context, CommunityAttachment attachment) {
    debugPrint('[AttachmentList] Rendering ${attachment.type} ID=${attachment.id} Metadata=${attachment.metadata != null}');
    switch (attachment.type) {
      case AttachmentType.image:
        return _buildImage(context, attachment);
      case AttachmentType.video:
        return _buildVideo(context, attachment);
      case AttachmentType.document:
        return _buildDocument(context, attachment);
      case AttachmentType.poll:
        return _buildPoll(context, attachment);
      case AttachmentType.collaborativeList:
        return CollaborativeListView(
          attachment: attachment,
          currentUserId: currentUserId,
          currentUserName: currentUserName,
          onAddEntry: (data) {
             context.read<CommunityProvider>().addListEntry(
               channelId, 
               messageId, 
               attachment.id, 
               data
             );
          },
        );
    }
  }

  Widget _buildImage(BuildContext context, CommunityAttachment attachment) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 200, maxWidth: 300),
        child: _getImageProvider(attachment),
      ),
    );
  }

  Widget _getImageProvider(CommunityAttachment attachment) {
     if (kIsWeb && attachment.bytes != null) {
       return Image.memory(attachment.bytes!, fit: BoxFit.cover);
     } else if (!kIsWeb && attachment.path.isNotEmpty) {
       return Image.file(
         File(attachment.path), 
         fit: BoxFit.cover,
         errorBuilder: (_,__,___) => const SizedBox(height: 100, width: 100, child: Icon(Icons.broken_image)),
       ); 
     }
     return const SizedBox(height: 100, width: 100, child: Icon(Icons.image));
  }

  Widget _buildVideo(BuildContext context, CommunityAttachment attachment) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            color: Colors.black,
            height: 150,
            width: 250,
            child: Opacity(
              opacity: 0.6,
              // Placeholder for video thumb
              child: _getImageProvider(attachment), 
            ),
          ),
          Container(
             padding: const EdgeInsets.all(8),
             decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.5), shape: BoxShape.circle),
             child: const Icon(Icons.play_arrow, color: Colors.white, size: 32),
          ),
        ],
      ),
    );
  }

  Widget _buildDocument(BuildContext context, CommunityAttachment attachment) {
    return FileAttachmentWidget(
      attachment: attachment,
      isOwnMessage: isOwnMessage,
    );
  }

  Widget _buildPoll(BuildContext context, CommunityAttachment attachment) {
    // Simple Poll View with Interaction
    final question = attachment.metadata?['question'] ?? 'Poll';
    final options = (attachment.metadata?['options'] as List?) ?? [];
    final votes = (attachment.metadata?['votes'] as Map<String, dynamic>?) ?? {}; // userId -> index or List<int>
    
    // Calculate totals
    final voteCounts = List<int>.filled(options.length, 0);
    int totalVotes = 0;
    votes.forEach((userId, voteValue) {
      if (voteValue is int) {
        if (voteValue >= 0 && voteValue < voteCounts.length) {
          voteCounts[voteValue]++;
          totalVotes++;
        }
      } else if (voteValue is List) {
        for (var v in voteValue) {
           if (v is int && v >= 0 && v < voteCounts.length) {
             voteCounts[v]++;
             totalVotes++;
           }
        }
      }
    });

    return Container(
      width: 250,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
             const Icon(Icons.poll, size: 16, color: Colors.orange),
             const SizedBox(width: 8),
             Expanded(child: Text(question, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87))),
          ]),
          const SizedBox(height: 8),
          ...options.asMap().entries.map((entry) {
            final index = entry.key;
            final opt = entry.value;
            final text = opt['text'];
            
            final count = voteCounts[index];
            final percent = totalVotes > 0 ? count / totalVotes : 0.0;
            
            // Check if user voted for this option
            final userVote = votes[currentUserId];
            bool isSelected = false;
            if (userVote is int) {
               isSelected = userVote == index;
            } else if (userVote is List) {
               isSelected = userVote.contains(index);
            }
            
            return GestureDetector(
              onTap: () {
                final allowMultiple = (attachment.metadata?['allowMultiple'] as bool?) ?? false;
                
                dynamic newVotePayload;

                if (allowMultiple) {
                  // Handle multiple choice
                  List<int> currentVotes = [];
                  if (userVote is int) currentVotes = [userVote];
                  if (userVote is List) currentVotes = List<int>.from(userVote);

                  if (currentVotes.contains(index)) {
                     currentVotes.remove(index);
                  } else {
                     currentVotes.add(index);
                  }
                  newVotePayload = currentVotes;
                } else {
                  // Single choice (toggle)
                  if (isSelected) {
                     newVotePayload = []; // Unvote implies empty list or null? Backend handles [] as delete
                  } else {
                     newVotePayload = index;
                  }
                }
                
                // Call Provider directly
                context.read<CommunityProvider>().voteOnPoll(channelId, messageId, attachment.id, newVotePayload);
              },
              child: Container(
                margin: const EdgeInsets.only(top: 4),
                height: 36,
                decoration: BoxDecoration(
                   color: Colors.grey.withValues(alpha: 0.1),
                   borderRadius: BorderRadius.circular(4),
                   border: isSelected ? Border.all(color: Colors.orange) : null, // Highlight selection
                ),
                child: Stack(
                  children: [
                    // Background Bar
                    FractionallySizedBox(
                      widthFactor: percent == 0 ? 0.001 : percent, 
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.orange.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                    // Text
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(child: Text(text, overflow: TextOverflow.ellipsis, style: TextStyle(color: Colors.black87, fontSize: 13, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal))),
                            Text('${(percent * 100).toStringAsFixed(0)}%', style: const TextStyle(color: Colors.grey, fontSize: 11)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
          const SizedBox(height: 4),
          Text('$totalVotes votes', style: const TextStyle(color: Colors.grey, fontSize: 10)),
        ],
      ),
    );
  }
}
