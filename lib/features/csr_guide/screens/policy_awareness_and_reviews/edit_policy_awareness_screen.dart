import 'package:flutter/material.dart';
import '../../../../shared/widgets/custom_app_bar.dart';

class EditPolicyAwarenessScreen extends StatefulWidget {
  final List<Map<String, dynamic>> entries;

  const EditPolicyAwarenessScreen({Key? key, required this.entries})
      : super(key: key);

  @override
  State<EditPolicyAwarenessScreen> createState() =>
      _EditPolicyAwarenessScreenState();
}

class _EditPolicyAwarenessScreenState
    extends State<EditPolicyAwarenessScreen> {
  final _formKey = GlobalKey<FormState>();

  // Each entry has a title controller + list of paragraph controllers
  late List<TextEditingController> _titleControllers;
  late List<List<TextEditingController>> _paragraphControllers;

  @override
  void initState() {
    super.initState();
    final initial = widget.entries.isNotEmpty
        ? widget.entries
        : [
            {
              'title': '',
              'paragraphs': ['']
            }
          ];
    _titleControllers =
        initial.map((e) => TextEditingController(text: e['title'] as String)).toList();
    _paragraphControllers = initial.map((e) {
      final paras = e['paragraphs'] as List<dynamic>;
      return paras.map((p) => TextEditingController(text: p as String)).toList();
    }).toList();
  }

  @override
  void dispose() {
    for (final c in _titleControllers) { c.dispose(); }
    for (final list in _paragraphControllers) {
      for (final c in list) { c.dispose(); }
    }
    super.dispose();
  }

  void _addEntry() {
    setState(() {
      _titleControllers.add(TextEditingController());
      _paragraphControllers.add([TextEditingController()]);
    });
  }

  void _removeEntry(int index) {
    if (_titleControllers.length == 1) return;
    setState(() {
      _titleControllers[index].dispose();
      for (final c in _paragraphControllers[index]) { c.dispose(); }
      _titleControllers.removeAt(index);
      _paragraphControllers.removeAt(index);
    });
  }

  void _addParagraph(int entryIndex) {
    setState(() => _paragraphControllers[entryIndex].add(TextEditingController()));
  }

  void _removeParagraph(int entryIndex, int paraIndex) {
    if (_paragraphControllers[entryIndex].length == 1) return;
    setState(() {
      _paragraphControllers[entryIndex][paraIndex].dispose();
      _paragraphControllers[entryIndex].removeAt(paraIndex);
    });
  }

  void _saveChanges() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final updated = List.generate(_titleControllers.length, (i) => {
      'title': _titleControllers[i].text.trim(),
      'paragraphs': _paragraphControllers[i]
          .map((c) => c.text.trim())
          .toList(),
    });
    Navigator.of(context).pop<List<Map<String, dynamic>>>(updated);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: CustomAppBar(title: 'CSR Guide', showMenuButton: false),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Edit Policy Awareness and Reviews',
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87),
                ),
                const SizedBox(height: 20),

                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 8,
                          offset: const Offset(0, 2))
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (int i = 0; i < _titleControllers.length; i++) ...[
                        // ── Section title row ──────────────────────
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _FieldLabel('Section ${i + 1} — Title'),
                            if (_titleControllers.length > 1)
                              IconButton(
                                icon: const Icon(Icons.remove_circle_outline,
                                    color: Colors.red, size: 20),
                                onPressed: () => _removeEntry(i),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                              ),
                          ],
                        ),
                        TextFormField(
                          controller: _titleControllers[i],
                          validator: (v) =>
                              (v == null || v.trim().isEmpty) ? 'Required' : null,
                          decoration:
                              _inputDecoration('Enter section title...'),
                        ),
                        const SizedBox(height: 16),

                        // ── Paragraphs ─────────────────────────────
                        for (int j = 0;
                            j < _paragraphControllers[i].length;
                            j++) ...[
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _FieldLabel('Paragraph ${j + 1}'),
                              if (_paragraphControllers[i].length > 1)
                                IconButton(
                                  icon: const Icon(
                                      Icons.remove_circle_outline,
                                      color: Colors.red,
                                      size: 18),
                                  onPressed: () => _removeParagraph(i, j),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                ),
                            ],
                          ),
                          TextFormField(
                            controller: _paragraphControllers[i][j],
                            maxLines: 4,
                            validator: (v) =>
                                (v == null || v.trim().isEmpty)
                                    ? 'Required'
                                    : null,
                            decoration:
                                _inputDecoration('Enter paragraph...'),
                          ),
                          const SizedBox(height: 10),
                        ],

                        TextButton.icon(
                          onPressed: () => _addParagraph(i),
                          icon: const Icon(Icons.add, size: 16),
                          label: const Text('Add Paragraph'),
                          style: TextButton.styleFrom(
                              foregroundColor: const Color(0xFF2563EB)),
                        ),

                        if (i < _titleControllers.length - 1)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 12),
                            child: Divider(color: Color(0xFFE5E7EB)),
                          ),
                      ],
                      const SizedBox(height: 8),
                      TextButton.icon(
                        onPressed: _addEntry,
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('Add Section'),
                        style: TextButton.styleFrom(
                            foregroundColor: const Color(0xFF2563EB)),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _saveChanges,
                     style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2563EB),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('Save Changes',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w600)),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(text,
          style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.black87)),
    );
  }
}

InputDecoration _inputDecoration(String hint) {
  return InputDecoration(
    hintText: hint,
    hintStyle: TextStyle(color: Colors.grey[400], fontSize: 13),
    contentPadding:
        const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFFD1D5DB))),
    enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFFD1D5DB))),
    focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1.5)),
    errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Colors.red)),
    focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Colors.red, width: 1.5)),
  );
}
