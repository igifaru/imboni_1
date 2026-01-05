/// Citizen Verification Screen
import 'package:flutter/material.dart';
import '../models/pftcv_models.dart';
import '../services/pftcv_service.dart';

class VerificationScreen extends StatefulWidget {
  final Project project;
  const VerificationScreen({super.key, required this.project});

  @override
  State<VerificationScreen> createState() => _VerificationScreenState();
}

class _VerificationScreenState extends State<VerificationScreen> {
  DeliveryStatus _selectedStatus = DeliveryStatus.notStarted;
  int _completionPercent = 0;
  int _qualityRating = 3;
  final _commentController = TextEditingController();
  bool _isAnonymous = false;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submitVerification() async {
    setState(() => _isSubmitting = true);

    try {
      final result = await pftcvService.submitVerification(
        projectId: widget.project.id,
        deliveryStatus: _selectedStatus.name.toUpperCase(),
        completionPercent: _completionPercent,
        qualityRating: _qualityRating,
        comment: _commentController.text,
        isAnonymous: _isAnonymous,
      );

      if (mounted) {
        if (result != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Igenzura ryoherejwe neza!'), backgroundColor: Colors.green),
          );
          Navigator.pop(context, true);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Habaye ikibazo. Ongera ugerageze.'), backgroundColor: Colors.red),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ikosa: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Genzura Umushinga')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Project Info Header
            Card(
              color: colorScheme.primaryContainer.withAlpha(100),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(widget.project.sector.icon, size: 40, color: colorScheme.primary),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(widget.project.name, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                          Text(widget.project.projectCode, style: theme.textTheme.bodySmall),
                          if (widget.project.locationName != null) Text(widget.project.locationName!, style: theme.textTheme.bodySmall),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Delivery Status Selection
            Text('Imirimo yagezweho ite?', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: DeliveryStatus.values.map((status) {
                final isSelected = _selectedStatus == status;
                return ChoiceChip(
                  label: Text(status.label),
                  selected: isSelected,
                  onSelected: (_) => setState(() => _selectedStatus = status),
                  selectedColor: colorScheme.primaryContainer,
                );
              }).toList(),
            ),
            const SizedBox(height: 24),

            // Completion Percentage
            Text('Igipimo cy\'Imirimo yarangiye', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Slider(
                    value: _completionPercent.toDouble(),
                    min: 0,
                    max: 100,
                    divisions: 10,
                    label: '$_completionPercent%',
                    onChanged: (v) => setState(() => _completionPercent = v.round()),
                  ),
                ),
                Container(
                  width: 60,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: colorScheme.surfaceContainerHighest, borderRadius: BorderRadius.circular(8)),
                  child: Text('$_completionPercent%', textAlign: TextAlign.center, style: theme.textTheme.titleMedium),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Quality Rating
            Text('Igipimo cy\'Ubuziranenge', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                final rating = index + 1;
                return IconButton(
                  iconSize: 36,
                  icon: Icon(rating <= _qualityRating ? Icons.star : Icons.star_border, color: Colors.amber),
                  onPressed: () => setState(() => _qualityRating = rating),
                );
              }),
            ),
            Text('${_qualityRating}/5', textAlign: TextAlign.center, style: theme.textTheme.titleLarge),
            const SizedBox(height: 24),

            // Comment
            Text('Ibitekerezo (Ntibisabwa)', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            TextField(
              controller: _commentController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'Andika ibitekerezo byawe...',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 24),

            // Anonymous Toggle
            SwitchListTile(
              title: const Text('Ohereza mu ibanga'),
              subtitle: const Text('Izina ryawe ntabwo rizerekanwa'),
              value: _isAnonymous,
              onChanged: (v) => setState(() => _isAnonymous = v),
              secondary: const Icon(Icons.privacy_tip),
            ),
            const SizedBox(height: 32),

            // Submit Button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: FilledButton.icon(
                onPressed: _isSubmitting ? null : _submitVerification,
                icon: _isSubmitting
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.send),
                label: Text(_isSubmitting ? 'Birimo Koherezwa...' : 'Ohereza Igenzura'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
