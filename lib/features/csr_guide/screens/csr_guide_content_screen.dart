import 'package:flutter/material.dart';
import '../../../shared/api/api_exception.dart';
import '../../../shared/api/backend_api.dart';
import '../../../shared/models/csr_guide_content.dart';
import '../../../shared/models/csr_guide_section.dart';
import '../../../shared/session_flags.dart';
import '../../../shared/widgets/custom_app_bar.dart';

// ── Content display screen ──────────────────────────────────────────────────
// Matches the UI of all original static CSR guide screens:
// white card · section title · blue "Edit Content" button · content paragraphs

class CsrGuideContentScreen extends StatefulWidget {
  final CsrGuideSection section;

  const CsrGuideContentScreen({Key? key, required this.section})
      : super(key: key);

  @override
  State<CsrGuideContentScreen> createState() => _CsrGuideContentScreenState();
}

class _CsrGuideContentScreenState extends State<CsrGuideContentScreen> {
  final _api = BackendApi();
  List<CsrGuideContent> _items = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadContent();
  }

  Future<void> _loadContent() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final items = await _api.getContentsForSection(widget.section.id);
      if (mounted) setState(() { _items = items; _isLoading = false; });
    } on ApiException catch (e) {
      if (mounted) setState(() { _error = e.message; _isLoading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _isLoading = false; });
    }
  }

  Future<void> _openEditScreen() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _EditContentScreen(
          section: widget.section,
          initialItems: _items,
          onSaved: (_) => _loadContent(),
        ),
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
              // ── Title row with "Edit Content" button ──────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 16, 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Text(
                        widget.section.title,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    if (SessionFlags.userRole == 'Super Admin') ...[  
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      onPressed: _openEditScreen,
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
                  ],
                ),
              ),

              const Divider(height: 1, color: Color(0xFFE5E7EB)),

              // ── Content paragraphs ────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _error != null
                        ? Text(_error!,
                            style: const TextStyle(
                                color: Colors.red, fontSize: 13))
                        : _items.isEmpty
                    ? const Text(
                        'No content yet. Tap "Edit Content" to add.',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.black38,
                          height: 1.6,
                        ),
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: List.generate(_items.length, (i) {
                          return Padding(
                            padding: EdgeInsets.only(
                                bottom: i < _items.length - 1 ? 16 : 0),
                            child: Text(
                              _items[i].content,
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.black87,
                                height: 1.7,
                              ),
                            ),
                          );
                        }),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Edit screen (pushed from "Edit Content" button) ─────────────────────────

class _EditContentScreen extends StatefulWidget {
  final CsrGuideSection section;
  final List<CsrGuideContent> initialItems;
  final void Function(List<CsrGuideContent>) onSaved;

  const _EditContentScreen({
    required this.section,
    required this.initialItems,
    required this.onSaved,
  });

  @override
  State<_EditContentScreen> createState() => _EditContentScreenState();
}

class _EditContentScreenState extends State<_EditContentScreen> {
  final _api = BackendApi();
  late List<CsrGuideContent> _items;
  final List<TextEditingController> _controllers = [];
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _items = List.from(widget.initialItems);
    _rebuildControllers();
  }

  void _rebuildControllers() {
    for (final c in _controllers) {
      c.dispose();
    }
    _controllers
      ..clear()
      ..addAll(_items.map((c) => TextEditingController(text: c.content)));
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _addParagraph() {
    setState(() {
      _items.add(
          CsrGuideContent(id: 0, sectionId: widget.section.id, content: ''));
      _controllers.add(TextEditingController());
    });
  }

  void _removeParagraph(int i) {
    final item = _items[i];
    if (item.id != 0) {
      _api.deleteCsrGuideContent(item.id);
    }
    setState(() {
      _items.removeAt(i);
      _controllers[i].dispose();
      _controllers.removeAt(i);
    });
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final saved = <CsrGuideContent>[];
      for (int i = 0; i < _items.length; i++) {
        final text = _controllers[i].text.trim();
        if (text.isEmpty) continue;
        if (_items[i].id == 0) {
          await _api.createCsrGuideContent(
              sectionId: widget.section.id, content: text);
        } else if (text != _items[i].content) {
          await _api.updateCsrGuideContent(id: _items[i].id, content: text);
        }
        saved.add(CsrGuideContent(
            id: _items[i].id, sectionId: widget.section.id, content: text));
      }
      if (mounted) {
        widget.onSaved(saved);
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Saved successfully.')),
        );
      }
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.message)));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: CustomAppBar(
        title: 'CSR Guide',
        showMenuButton: false,
        actions: [
          if (_saving)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Color(0xFF2563EB)),
              ),
            )
          else ...[
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel',
                  style: TextStyle(color: Colors.black54)),
            ),
            TextButton(
              onPressed: _save,
              child: const Text('Save',
                  style: TextStyle(
                      color: Color(0xFF2563EB),
                      fontWeight: FontWeight.bold)),
            ),
          ],
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Edit: ${widget.section.title}',
                style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87),
              ),
              const SizedBox(height: 16),
              ...List.generate(_items.length, (i) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _controllers[i],
                            maxLines: null,
                            keyboardType: TextInputType.multiline,
                            style:
                                const TextStyle(fontSize: 14, height: 1.6),
                            decoration: InputDecoration(
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(6)),
                              contentPadding: const EdgeInsets.all(10),
                              hintText: 'Paragraph ${i + 1}',
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.remove_circle_outline,
                              color: Colors.red, size: 20),
                          onPressed: () => _removeParagraph(i),
                        ),
                      ],
                    ),
                  )),
              TextButton.icon(
                onPressed: _addParagraph,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add paragraph'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
