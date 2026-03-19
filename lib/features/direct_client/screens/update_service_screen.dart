import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../../../shared/widgets/custom_app_bar.dart';

class UpdateServiceScreen extends StatefulWidget {
  final Map<String, String> service;
  final String shopName;

  const UpdateServiceScreen({
    Key? key,
    required this.service,
    required this.shopName,
  }) : super(key: key);

  @override
  State<UpdateServiceScreen> createState() => _UpdateServiceScreenState();
}

class _UpdateServiceScreenState extends State<UpdateServiceScreen> {
  final TextEditingController _fileController = TextEditingController();
  final TextEditingController _reportNoController = TextEditingController();
  final TextEditingController _serviceDateController = TextEditingController();

  // Serial numbers — each entry is a controller
  final List<TextEditingController> _serialControllers = [];

  // Spare parts — each entry is {controller, qty}
  final List<Map<String, dynamic>> _spareParts = [];

  // Technicians — list of selected values
  final List<String?> _selectedTechnicians = [];

  String? _selectedSerialNumber;
  String? _selectedServiceType;

  final List<String> _serialNumberOptions = [
    'Select Shop Type',
    '503KWEQWEJ44 (Bulla Crave)',
  ];
  final List<String> _serviceTypeOptions = [
    'Select Service Type',
    'Delivery & Installation',
    'Check Up',
    'Repair',
  ];
  final List<String> _technicianOptions = [
    'glendavaleroso25@gmail.com',
    'nurwedatuoto@gmail.com',
    'joejeetbibbigan@gmail.com',
  ];

  @override
  void initState() {
    super.initState();
    _fileController.text = '';
    _reportNoController.text = widget.service['controlNumber'] ?? '';
    _serviceDateController.text = widget.service['serviceDate'] ?? '07/08/2025';

    final st = widget.service['serviceType'] ?? '';
    if (_serviceTypeOptions.contains(st)) _selectedServiceType = st;

    // Seed one serial number entry
    _serialControllers.add(TextEditingController(
        text: widget.service['serialNumber'] ?? '503KWEQWEJ44 (Bulla Crave)'));

    // Seed one spare part entry
    _spareParts.add({
      'controller': TextEditingController(
          text: widget.service['spareParts'] ??
              '593QWEKOEJOIAI241 (Bulla Crave)'),
      'qty': 1,
    });

    // Seed one technician
    _selectedTechnicians.add(_technicianOptions.first);
  }

  @override
  void dispose() {
    _fileController.dispose();
    _reportNoController.dispose();
    _serviceDateController.dispose();
    for (final c in _serialControllers) {
      c.dispose();
    }
    for (final p in _spareParts) {
      (p['controller'] as TextEditingController).dispose();
    }
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        _serviceDateController.text =
            '${picked.month.toString().padLeft(2, '0')}/${picked.day.toString().padLeft(2, '0')}/${picked.year}';
      });
    }
  }

  void _addSerialNumber() {
    setState(() => _serialControllers.add(TextEditingController()));
  }

  void _removeSerialNumber(int index) {
    setState(() {
      _serialControllers[index].dispose();
      _serialControllers.removeAt(index);
    });
  }

  void _addSparePart() {
    setState(() => _spareParts.add({
          'controller': TextEditingController(),
          'qty': 1,
        }));
  }

  void _removeSparePart(int index) {
    setState(() {
      (_spareParts[index]['controller'] as TextEditingController).dispose();
      _spareParts.removeAt(index);
    });
  }

  void _incrementQty(int index) {
    setState(() => _spareParts[index]['qty']++);
  }

  void _decrementQty(int index) {
    if (_spareParts[index]['qty'] > 1) {
      setState(() => _spareParts[index]['qty']--);
    }
  }

  void _addTechnician() {
    setState(() => _selectedTechnicians.add(_technicianOptions.first));
  }

  void _removeTechnician(int index) {
    setState(() => _selectedTechnicians.removeAt(index));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: CustomAppBar(title: 'Direct Client', showMenuButton: false),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Shop name
                  Text(
                    widget.shopName,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // File field
                  _buildLabel(
                      'File (Optional - Leave blank to keep current)'),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
                        child: _buildTextField(
                          controller: _fileController,
                          hint: 'sample file(PDF ONLY)',
                        ),
                      ),
                      const SizedBox(width: 8),
                      _iconBox(
                        icon: Icons.folder_open,
                        color: Colors.grey[200]!,
                        iconColor: Colors.black87,
                        onTap: () async {
                          final result = await FilePicker.platform.pickFiles(
                            type: FileType.custom,
                            allowedExtensions: ['pdf'],
                          );
                          if (result != null && result.files.isNotEmpty) {
                            setState(() {
                              _fileController.text = result.files.single.name;
                            });
                          }
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Serial Numbers
                  _buildLabel('Serial Number'),
                  const SizedBox(height: 6),
                  ...List.generate(_serialControllers.length, (i) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Expanded(
                            child: _buildTextField(
                              controller: _serialControllers[i],
                              hint: '503KWEQWEJ44 (Bulla Crave)',
                            ),
                          ),
                          const SizedBox(width: 8),
                          _iconBox(
                            icon: Icons.add,
                            color: Colors.grey[200]!,
                            iconColor: Colors.black87,
                            onTap: _addSerialNumber,
                          ),
                          const SizedBox(width: 6),
                          _iconBox(
                            icon: Icons.delete,
                            color: const Color(0xFFEF4444),
                            iconColor: Colors.white,
                            onTap: () => _removeSerialNumber(i),
                          ),
                        ],
                      ),
                    );
                  }),
                  const SizedBox(height: 4),

                  // Select Serial Number dropdown
                  _buildLabel('Select Serial Number'),
                  const SizedBox(height: 6),
                  _buildDropdown(
                    value: _selectedSerialNumber,
                    items: _serialNumberOptions,
                    hint: 'Select Shop Type',
                    onChanged: (v) =>
                        setState(() => _selectedSerialNumber = v),
                  ),
                  const SizedBox(height: 12),

                  // + Add Part button (right-aligned)
                  Align(
                    alignment: Alignment.centerRight,
                    child: OutlinedButton(
                      onPressed: _addSparePart,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.black87,
                        side: BorderSide(color: Colors.grey[400]!),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        '+ Add Part',
                        style: TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Spare Parts list
                  _buildLabel('Spare Parts'),
                  const SizedBox(height: 6),
                  ...List.generate(_spareParts.length, (i) {
                    final qty = _spareParts[i]['qty'] as int;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Expanded(
                            child: _buildTextField(
                              controller: _spareParts[i]['controller']
                                  as TextEditingController,
                              hint: '593QWEKOEJOIAI241 (Bulla Crave)',
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Qty stepper
                          Container(
                            height: 46,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              border: Border.all(color: Colors.grey[300]!),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                InkWell(
                                  onTap: () => _decrementQty(i),
                                  child: const Padding(
                                    padding:
                                        EdgeInsets.symmetric(horizontal: 8),
                                    child: Icon(Icons.remove, size: 16),
                                  ),
                                ),
                                Text('$qty',
                                    style: const TextStyle(
                                        fontSize: 13,
                                        color: Colors.black87,
                                        fontWeight: FontWeight.w600)),
                                InkWell(
                                  onTap: () => _incrementQty(i),
                                  child: const Padding(
                                    padding:
                                        EdgeInsets.symmetric(horizontal: 8),
                                    child: Icon(Icons.add, size: 16),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 6),
                          _iconBox(
                            icon: Icons.delete,
                            color: const Color(0xFFEF4444),
                            iconColor: Colors.white,
                            onTap: () => _removeSparePart(i),
                          ),
                        ],
                      ),
                    );
                  }),
                  const SizedBox(height: 16),

                  // Service Order Report No.
                  _buildLabel('Service Order Report No.'),
                  const SizedBox(height: 6),
                  _buildTextField(
                    controller: _reportNoController,
                    hint: 'No sample',
                  ),
                  const SizedBox(height: 16),

                  // Service Date
                  _buildLabel('Service Date'),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _serviceDateController,
                    readOnly: true,
                    style: const TextStyle(
                        fontSize: 14, color: Colors.black87),
                    decoration: InputDecoration(
                      hintText: 'MM/DD/YYYY',
                      hintStyle: TextStyle(
                          color: Colors.grey[400], fontSize: 14),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 14),
                      suffixIcon: Icon(Icons.calendar_month,
                          color: Colors.grey[600]),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(
                            color: Color(0xFF2563EB), width: 1.5),
                      ),
                    ),
                    onTap: _pickDate,
                  ),
                  const SizedBox(height: 16),

                  // Service Type dropdown
                  _buildLabel('Service Type'),
                  const SizedBox(height: 6),
                  _buildDropdown(
                    value: _selectedServiceType,
                    items: _serviceTypeOptions,
                    hint: 'Select Service Type',
                    onChanged: (v) =>
                        setState(() => _selectedServiceType = v),
                  ),
                  const SizedBox(height: 16),

                  // Technicians list
                  _buildLabel('Technician'),
                  const SizedBox(height: 6),
                  ...List.generate(_selectedTechnicians.length, (i) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Expanded(
                            child: _buildDropdown(
                              value: _selectedTechnicians[i],
                              items: _technicianOptions,
                              hint: 'Select Technician',
                              onChanged: (v) => setState(
                                  () => _selectedTechnicians[i] = v),
                            ),
                          ),
                          const SizedBox(width: 8),
                          _iconBox(
                            icon: i == _selectedTechnicians.length - 1
                                ? Icons.add
                                : Icons.remove,
                            color: Colors.grey[200]!,
                            iconColor: Colors.black87,
                            onTap: i == _selectedTechnicians.length - 1
                                ? _addTechnician
                                : () => _removeTechnician(i),
                          ),
                        ],
                      ),
                    );
                  }),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),

          // Save Changes button pinned at bottom
          Container(
            width: double.infinity,
            color: const Color(0xFFF5F7FA),
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            child: ElevatedButton(
              onPressed: () async {
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Save Changes'),
                    content: const Text(
                        'Are you sure you want to save these changes?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Cancel'),
                      ),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(context, true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFFC300),
                          foregroundColor: Colors.black,
                          elevation: 0,
                        ),
                        child: const Text('Confirm'),
                      ),
                    ],
                  ),
                );
                if (confirmed == true) {
                  // TODO: save service data
                  Navigator.pop(context);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFC300),
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 0,
              ),
              child: const Text(
                'Save Changes',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: Colors.black87,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    String hint = '',
  }) {
    return TextField(
      controller: controller,
      style: const TextStyle(fontSize: 14, color: Colors.black87),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
        filled: true,
        fillColor: Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1.5),
        ),
      ),
    );
  }

  Widget _buildDropdown({
    required String? value,
    required List<String> items,
    required String hint,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          hint: Text(hint,
              style: TextStyle(color: Colors.grey[400], fontSize: 14)),
          items: items
              .map((item) => DropdownMenuItem(
                    value: item,
                    child: Text(item,
                        style: const TextStyle(
                            fontSize: 14, color: Colors.black87)),
                  ))
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _iconBox({
    required IconData icon,
    required Color color,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(8),
          border: color == Colors.grey[200]
              ? Border.all(color: Colors.grey[300]!)
              : null,
        ),
        child: Icon(icon, color: iconColor, size: 20),
      ),
    );
  }
}
 