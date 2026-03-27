import 'package:flutter/material.dart';
import '../../../../shared/widgets/custom_app_bar.dart';

/// Generic content container for user-added CSR Guide items.
///
/// Displays [title] as the heading and [initialContent] as the body text.
/// Calls [onContentSaved] whenever the user saves new content, so the parent
/// can persist it in local state — ready to swap for a backend call later.
class NewContentContainerScreen extends StatefulWidget {
  final String title;
  final String initialContent;
  final void Function(String content)? onContentSaved;

  const NewContentContainerScreen({
    Key? key,
    required this.title,
    this.initialContent = '',
    this.onContentSaved,
  }) : super(key: key);

  @override
  State<NewContentContainerScreen> createState() =>
      _NewContentContainerScreenState();
}

class _NewContentContainerScreenState
    extends State<NewContentContainerScreen> {
  late String _content;

  @override
  void initState() {
    super.initState();
    _content = widget.initialContent;
  }

  void _openEditDialog() {
    final ctrl = TextEditingController(text: _content);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(
          widget.title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          maxLines: 8,
          decoration: const InputDecoration(
            hintText: 'Enter content here...',
            border: OutlineInputBorder(),
            isDense: true,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2563EB),
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              final updated = ctrl.text.trim();
              setState(() => _content = updated);
              widget.onContentSaved?.call(updated);
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: CustomAppBar(title: 'CSR Guide', showMenuButton: false),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Title row with Edit Content button ─────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 16, 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Text(
                        widget.title,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      onPressed: _openEditDialog,
                      icon: const Icon(Icons.edit, size: 15),
                      label: const Text('Edit Content'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2563EB),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                        textStyle: const TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w500),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const Divider(height: 1, color: Color(0xFFE5E7EB)),

              // ── Content area ────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                child: _content.isEmpty
                    ? const Text(
                        'No content yet. Tap "Edit Content" to add.',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.black38,
                          height: 1.6,
                        ),
                      )
                    : Text(
                        _content,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.black87,
                          height: 1.6,
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
