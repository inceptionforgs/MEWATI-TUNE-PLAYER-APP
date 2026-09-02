import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/song.dart';
import '../../providers/theme_provider.dart';
import '../../services/feedback_service.dart';

enum _FeedbackCategory { bug, songSuggestion, other }

extension on _FeedbackCategory {
  String get label {
    switch (this) {
      case _FeedbackCategory.bug:
        return 'Bug';
      case _FeedbackCategory.songSuggestion:
        return 'Suggest a Song';
      case _FeedbackCategory.other:
        return 'Other';
    }
  }

  String get value {
    switch (this) {
      case _FeedbackCategory.bug:
        return 'bug';
      case _FeedbackCategory.songSuggestion:
        return 'song_suggestion';
      case _FeedbackCategory.other:
        return 'other';
    }
  }
}

/// F1: lightweight in-app feedback channel. Opens either from the drawer
/// (File 19, no song context) or from a song's long-press context menu
/// (File 21, auto-filled song).
class FeedbackScreen extends StatefulWidget {
  final Song? song;

  const FeedbackScreen({Key? key, this.song}) : super(key: key);

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  final _feedbackService = FeedbackService();
  final _messageController = TextEditingController();
  _FeedbackCategory? _selectedCategory;
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final message = _messageController.text.trim();
    if (message.isEmpty) {
      setState(() => _errorMessage = 'Please enter a message before submitting.');
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      await _feedbackService.submitFeedback(
        message: message,
        category: _selectedCategory?.value,
        songId: widget.song?.id,
      );
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Thanks! We'll look into it.")),
      );
    } catch (e) {
      setState(() {
        _errorMessage = 'Could not submit right now. Please try again.';
      });
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.watch<ThemeProvider>().theme;

    return Scaffold(
      backgroundColor: t.background,
      appBar: AppBar(
        backgroundColor: t.background,
        elevation: 0,
        title: Text(
          'Feedback / Suggest a Song',
          style: TextStyle(color: t.textPrimary, fontWeight: FontWeight.w800, fontSize: 16),
        ),
        iconTheme: IconThemeData(color: t.textPrimary),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (widget.song != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: t.surface,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: t.textPrimary.withOpacity(0.12)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.music_note, color: t.accent, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'About: ${widget.song!.title}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: t.textPrimary, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],
              Text(
                'Category (optional)',
                style: TextStyle(color: t.textSecondary, fontSize: 12, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: _FeedbackCategory.values.map((cat) {
                  final selected = _selectedCategory == cat;
                  return ChoiceChip(
                    label: Text(cat.label),
                    selected: selected,
                    onSelected: (_) {
                      setState(() {
                        _selectedCategory = selected ? null : cat;
                      });
                    },
                    selectedColor: t.accent.withOpacity(0.25),
                    backgroundColor: t.surface,
                    labelStyle: TextStyle(
                      color: selected ? t.accent : t.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 18),
              Text(
                'Message',
                style: TextStyle(color: t.textSecondary, fontSize: 12, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _messageController,
                maxLines: 6,
                minLines: 4,
                style: TextStyle(color: t.textPrimary),
                decoration: InputDecoration(
                  hintText: 'Tell us what happened, or which song we should add...',
                  hintStyle: TextStyle(color: t.textSecondary),
                  filled: true,
                  fillColor: t.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              if (_errorMessage != null) ...[
                const SizedBox(height: 10),
                Text(
                  _errorMessage!,
                  style: const TextStyle(color: Colors.redAccent, fontSize: 12),
                ),
              ],
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: t.accent,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text(
                          'Submit',
                          style: TextStyle(fontWeight: FontWeight.w800, color: Colors.white),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
