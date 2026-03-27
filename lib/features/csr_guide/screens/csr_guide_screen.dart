import 'package:flutter/material.dart';
import '../../../shared/api/api_exception.dart';
import '../../../shared/api/backend_api.dart';
import '../../../shared/models/csr_guide_section.dart';
import '../../../shared/widgets/app_drawer.dart';
import '../../../shared/widgets/custom_app_bar.dart';
import 'csr_guide_content_screen.dart';

class CsrGuideScreen extends StatefulWidget {
  const CsrGuideScreen({Key? key}) : super(key: key);

  @override
  State<CsrGuideScreen> createState() => _CsrGuideScreenState();
}

class _CsrGuideScreenState extends State<CsrGuideScreen> {
  final _api = BackendApi();

  // Whether the full documentation list is visible
  bool _docListVisible = true;

  // Which parent section is currently expanded (null = all collapsed)
  String? _expandedSection;

  // Currently selected sub-item title (highlighted in blue)
  String? _selectedTopic;

  // Top-level parent sections from backend
  List<CsrGuideSection> _sections = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadSections();
  }

  Future<void> _loadSections() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final all = await _api.getCsrGuideSections();
      final parents = all.where((s) => s.parentId == null).toList()
        ..sort((a, b) => a.order.compareTo(b.order));
      if (mounted) {
        setState(() {
          _sections = parents;
          _isLoading = false;
        });
      }
    } on ApiException catch (e) {
      if (mounted) setState(() { _error = e.message; _isLoading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _isLoading = false; });
    }
  }

  // Returns sorted children of a parent section
  List<CsrGuideSection> _childrenOf(CsrGuideSection parent) {
    return List<CsrGuideSection>.from(parent.children)
      ..sort((a, b) => a.order.compareTo(b.order));
  }

  // Find a parent section by title (null if not found)
  CsrGuideSection? _findParent(String title) {
    try {
      return _sections.firstWhere((s) => s.title == title);
    } catch (_) {
      return null;
    }
  }

  // Navigate to content screen and reload sections on return
  void _navigateToSection(CsrGuideSection section) {
    setState(() => _selectedTopic = section.title);
    Navigator.of(context)
        .push(MaterialPageRoute(
            builder: (_) => CsrGuideContentScreen(section: section)))
        .then((_) => _loadSections());
  }

  // ── Add dialog ──────────────────────────────────────────────────────────────
  void _showAddDialog(String parentTitle) {
    final parent = _findParent(parentTitle);
    if (parent == null) return;
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Add Item',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Item name', isDense: true),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                foregroundColor: Colors.white),
            onPressed: () async {
              final text = ctrl.text.trim();
              if (text.isEmpty) return;
              Navigator.pop(context);
              try {
                await _api.createCsrGuideSection(
                  title: text,
                  order: parent.children.length + 1,
                  parentId: parent.id,
                );
                _loadSections();
              } on ApiException catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context)
                      .showSnackBar(SnackBar(content: Text(e.message)));
                }
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  // ── Edit dialog ─────────────────────────────────────────────────────────────
  void _showEditDialog(CsrGuideSection section) {
    final ctrl = TextEditingController(text: section.title);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Edit Item',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Item name', isDense: true),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                foregroundColor: Colors.white),
            onPressed: () async {
              final text = ctrl.text.trim();
              if (text.isEmpty) return;
              Navigator.pop(context);
              try {
                await _api.updateCsrGuideSection(
                    id: section.id, payload: {'title': text});
                _loadSections();
              } on ApiException catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context)
                      .showSnackBar(SnackBar(content: Text(e.message)));
                }
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  // ── Delete dialog ───────────────────────────────────────────────────────────
  void _showDeleteDialog(CsrGuideSection section) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Item',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        content: Text('Remove "${section.title}"?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () async {
              Navigator.pop(context);
              try {
                await _api.deleteCsrGuideSection(section.id);
                _loadSections();
              } on ApiException catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context)
                      .showSnackBar(SnackBar(content: Text(e.message)));
                }
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: CustomAppBar(
        title: 'CSR Guide',
        showMenuButton: true,
        actions: const [],
      ),
      drawer: const AppDrawer(currentPage: 'CSR Guide'),
      body: Container(
        color: Colors.white,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── "Documentation" bold heading ──────────────────────
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 20, 16, 8),
                child: Text(
                  'Documentation',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),

              // ── "Select Documentation" header row ─────────────────
              _buildTopRow('Select Documentation'),
              Divider(height: 1, color: Colors.grey[200]),

              // ── Loading / error / expandable sections ──────────────
              if (_isLoading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_error != null)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_error!,
                          style: const TextStyle(
                              color: Colors.red, fontSize: 13)),
                      const SizedBox(height: 8),
                      TextButton(
                          onPressed: _loadSections,
                          child: const Text('Retry')),
                    ],
                  ),
                )
              else if (_docListVisible)
                ..._sections.map((section) {
                  final isExpanded = _expandedSection == section.title;
                  final children = _childrenOf(section);

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Section row — expand/collapse + add "+" button
                      Row(
                        children: [
                          Expanded(
                            child: InkWell(
                              onTap: () => setState(() {
                                _expandedSection =
                                    isExpanded ? null : section.title;
                              }),
                              child: Padding(
                                padding:
                                    const EdgeInsets.fromLTRB(16, 14, 8, 14),
                                child: Text(
                                  section.title,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.black87,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          GestureDetector(
                            onTap: () => _showAddDialog(section.title),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 14),
                              child: const Icon(Icons.add,
                                  size: 18, color: Color(0xFF2563EB)),
                            ),
                          ),
                          GestureDetector(
                            onTap: () => setState(() {
                              _expandedSection =
                                  isExpanded ? null : section.title;
                            }),
                            child: Padding(
                              padding:
                                  const EdgeInsets.fromLTRB(4, 14, 16, 14),
                              child: Icon(
                                isExpanded
                                    ? Icons.expand_more
                                    : Icons.chevron_right,
                                size: 20,
                                color: Colors.grey[600],
                              ),
                            ),
                          ),
                        ],
                      ),

                      // Sub-items with edit/delete icons
                      if (isExpanded && children.isNotEmpty)
                        ...children.map(
                          (child) => Row(
                            children: [
                              Expanded(
                                child: InkWell(
                                  onTap: () => _navigateToSection(child),
                                  child: Padding(
                                    padding: const EdgeInsets.fromLTRB(
                                        32, 10, 8, 10),
                                    child: Text(
                                      child.title,
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight:
                                            _selectedTopic == child.title
                                                ? FontWeight.w600
                                                : FontWeight.w400,
                                        color: _selectedTopic == child.title
                                            ? const Color(0xFF2563EB)
                                            : Colors.black87,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              GestureDetector(
                                onTap: () => _showEditDialog(child),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6),
                                  child: Icon(Icons.edit_outlined,
                                      size: 15, color: Colors.grey[500]),
                                ),
                              ),
                              GestureDetector(
                                onTap: () => _showDeleteDialog(child),
                                child: const Padding(
                                  padding:
                                      EdgeInsets.only(right: 12, left: 2),
                                  child: Icon(Icons.delete_outline,
                                      size: 15, color: Colors.redAccent),
                                ),
                              ),
                            ],
                          ),
                        ),

                      Divider(height: 1, color: Colors.grey[200]),
                    ],
                  );
                }),
            ],
          ),
        ),
      ),
    );
  }

  // ── "Select Documentation" top row ─────────────────────────────────────────
  Widget _buildTopRow(String label) {
    return InkWell(
      onTap: () {
        setState(() {
          _docListVisible = !_docListVisible;
          if (!_docListVisible) _expandedSection = null;
        });
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[600],
                ),
              ),
            ),
            Icon(
              _docListVisible ? Icons.expand_more : Icons.chevron_right,
              size: 20,
              color: Colors.grey[600],
            ),
          ],
        ),
      ),
    );
  }
}