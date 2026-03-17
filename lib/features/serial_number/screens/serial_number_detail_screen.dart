import 'package:flutter/material.dart';
import '../models/serial_number_model.dart';
import '../../../shared/widgets/custom_app_bar.dart';
import 'edit_serial_number_screen.dart';

class SerialNumberDetailScreen extends StatefulWidget {
  final SerialNumberModel item;

  const SerialNumberDetailScreen({Key? key, required this.item})
      : super(key: key);

  @override
  State<SerialNumberDetailScreen> createState() =>
      _SerialNumberDetailScreenState();
}

class _SerialNumberDetailScreenState extends State<SerialNumberDetailScreen> {
  late SerialNumberModel _item;

  @override
  void initState() {
    super.initState();
    _item = widget.item;
  }

  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        title: const Text('Delete Serial Number',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
        content: Text(
            'Delete all serial data for "${_item.clientName}"?',
            style: const TextStyle(fontSize: 14)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel',
                style: TextStyle(color: Colors.black54)),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              Navigator.of(context).pop();
            },
            child: const Text('Delete',
                style: TextStyle(color: Color(0xFFEF5350))),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: CustomAppBar(title: 'Inventory', showMenuButton: false),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  const Text(
                    'Serial Number',
                    style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: Colors.black87),
                  ),
                  const SizedBox(height: 20),

                  // Client info rows
                  _InfoRow(label: 'Client Name', value: _item.clientName),
                  const SizedBox(height: 12),
                  _InfoRow(label: 'Client Type', value: _item.clientType),
                  const SizedBox(height: 12),
                  _InfoRow(label: 'Date Created', value: _item.dateCreated),
                  const SizedBox(height: 24),

                  // Serial Numbers section
                  const Text(
                    'Serial Numbers',
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87),
                  ),
                  const SizedBox(height: 12),

                  // Serial codes list with checkboxes
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(
                          color: const Color(0xFFDDDDDD), width: 1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Column(
                      children: List.generate(_item.serialCodes.length, (i) {
                        final isLast = i == _item.serialCodes.length - 1;
                        return Column(
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 10),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      _item.serialCodes[i],
                                      style: const TextStyle(
                                          fontSize: 16,
                                          color: Colors.black87),
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: () async {
                                      final updated = await Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (_) => EditSerialNumberScreen(
                                            item: _item,
                                            editIndex: i,
                                          ),
                                        ),
                                      );
                                      if (updated != null && updated is SerialNumberModel) {
                                        setState(() => _item = updated);
                                      }
                                    },
                                    child: const Icon(
                                      Icons.edit_square,
                                      size: 26,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (!isLast)
                              const Divider(
                                  height: 1,
                                  thickness: 1,
                                  color: Color(0xFFEEEEEE)),
                          ],
                        );
                      }),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Bottom buttons
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              children: [
                // View Client button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: OutlinedButton(
                    onPressed: () {},
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(
                          color: Color(0xFFCCCCCC), width: 1.5),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text(
                      'View Client',
                      style: TextStyle(
                          color: Colors.black87,
                          fontSize: 15,
                          fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                // Delete button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _confirmDelete,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFEF5350),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text(
                      'Delete',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Info row ────────────────────────────────────────────────────────────────

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 12,
                color: Colors.black45,
                fontWeight: FontWeight.w500)),
        const SizedBox(height: 3),
        Text(value,
            style: const TextStyle(
                fontSize: 15,
                color: Colors.black87,
                fontWeight: FontWeight.w500)),
      ],
    );
  }
}
