import 'dart:async';

import 'package:flutter/material.dart';

import '../../../features/serial_number/models/serial_number_model.dart';
import '../../../features/serial_number/screens/serial_number_detail_screen.dart';
import '../../../shared/api/api_exception.dart';
import '../../../shared/api/backend_api.dart';
import '../../../shared/session_flags.dart';
import '../../../shared/models/product.dart';
import '../../../shared/widgets/custom_app_bar.dart';
import 'edit_product_details_screen.dart';

class ProductDetailsEntitiesScreen extends StatefulWidget {
  final Map<String, String> product;

  const ProductDetailsEntitiesScreen({Key? key, required this.product})
      : super(key: key);

  @override
  State<ProductDetailsEntitiesScreen> createState() =>
      _ProductDetailsEntitiesScreenState();
}

class _ProductDetailsEntitiesScreenState
    extends State<ProductDetailsEntitiesScreen> {
  final _api = BackendApi();
  final _searchController = TextEditingController();

  Product? _product;
  bool _isLoading = false;
  String? _errorText;

  List<SerialNumberModel> _serialNumbers = const [];
  bool _isLoadingSerials = false;
  String? _serialError;
  int _serialPage = 1;
  int _serialLastPage = 1;
  int _serialTotal = 0;
  static const int _serialPerPage = 10;
  int _serialRequestSeq = 0;
  Timer? _serialDebounce;

  int? get _productId => int.tryParse(widget.product['id'] ?? '');  
  int? get _shopProductId =>
      int.tryParse(widget.product['shop_product_id'] ?? '');
  int? get _clientId => int.tryParse(widget.product['client_id'] ?? '');

  @override
  void initState() {
    super.initState();
    _loadProduct();
    _fetchSerialNumbers();
  }

  @override
  void dispose() {
    _serialDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchSerialNumbers() async {
    final spId = _shopProductId;
    if (spId == null) return;

    final requestId = ++_serialRequestSeq;
    setState(() {
      _isLoadingSerials = true;
      _serialError = null;
    });

    try {
      final q = _searchController.text.trim();
      final resp = await _api.getSerialNumbers(
        page: _serialPage,
        perPage: _serialPerPage,
        q: q.isEmpty ? null : q,
        shopProductId: spId,
      );
      if (!mounted || requestId != _serialRequestSeq) return;

      final safeLastPage = resp.lastPage <= 0 ? 1 : resp.lastPage;
      final safePage =
          _serialPage > safeLastPage ? safeLastPage : _serialPage;
      // Enforce client-side filter in case backend ignores the param.
      final items =
          resp.data.where((m) => m.shopProductId == spId).toList();
      setState(() {
        _serialNumbers = items;
        _serialPage = safePage;
        _serialLastPage = safeLastPage;
        _serialTotal = resp.total > 0 ? resp.total : items.length;
      });
    } on ApiException catch (e) {
      if (!mounted || requestId != _serialRequestSeq) return;
      setState(() => _serialError = e.message);
    } catch (_) {
      if (!mounted || requestId != _serialRequestSeq) return;
      setState(() => _serialError = 'Failed to load serial numbers.');
    } finally {
      if (mounted && requestId == _serialRequestSeq) {
        setState(() => _isLoadingSerials = false);
      }
    }
  }

  void _onSerialSearchChanged(String _) {
    _serialDebounce?.cancel();
    _serialDebounce = Timer(const Duration(milliseconds: 400), () {
      if (!mounted) return;
      setState(() => _serialPage = 1);
      _fetchSerialNumbers();
    });
  }

  void _showEditSerialDialog(SerialNumberModel sn) {
    final snCtrl = TextEditingController(text: sn.serialnumber);
    final stCtrl = TextEditingController(text: sn.supplierType);
    showDialog(
      context: context,
      builder: (ctx) {
        var isSubmitting = false;
        return StatefulBuilder(
          builder: (ctx, setS) => AlertDialog(
            title: const Text('Edit Serial Number'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: snCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Serial Number *',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: stCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Supplier Type',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: isSubmitting ? null : () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: isSubmitting
                    ? null
                    : () async {
                        final newSn = snCtrl.text.trim();
                        if (newSn.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content:
                                    Text('Serial number is required.')),
                          );
                          return;
                        }
                        setS(() => isSubmitting = true);
                        try {
                          final payload = <String, dynamic>{};
                          if (newSn != sn.serialnumber) {
                            payload['serialnumber'] = newSn;
                          }
                          final newSt = stCtrl.text.trim();
                          if (newSt != sn.supplierType) {
                            payload['supplier_type'] = newSt;
                          }
                          if (payload.isNotEmpty) {
                            await _api.updateSerialNumber(sn.id, payload);
                          }
                          if (!mounted) return;
                          Navigator.pop(ctx);
                          _fetchSerialNumbers();
                        } on ApiException catch (e) {
                          if (!mounted) return;
                          setS(() => isSubmitting = false);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(e.message)),
                          );
                        } catch (_) {
                          if (!mounted) return;
                          setS(() => isSubmitting = false);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text(
                                    'Failed to update serial number.')),
                          );
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  foregroundColor: Colors.white,
                  elevation: 0,
                ),
                child: isSubmitting
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Save'),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _deleteSerialNumber(SerialNumberModel sn) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Serial Number'),
        content:
            Text('Delete "${sn.serialnumber}"? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              elevation: 0,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await _api.deleteSerialNumber(sn.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Serial number deleted.')),
      );
      if (_serialNumbers.length == 1 && _serialPage > 1) {
        setState(() => _serialPage--);
      }
      _fetchSerialNumbers();
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.message)));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Failed to delete serial number.')),
      );
    }
  }

  Future<void> _loadProduct() async {
    if (_productId == null) return;

    setState(() {
      _isLoading = true;
      _errorText = null;
    });

    try {
      final product = await _api.getProductById(_productId!);
      if (!mounted) return;
      setState(() {
        _product = product;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _errorText = e.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => _errorText = 'Failed to load product details.');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _deleteProduct() async {
    if (_productId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Missing product id.')),
      );
      return;
    }

    try {
      await _api.deleteProduct(_productId!);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Product deleted successfully.')),
      );
      Navigator.pop(context);
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to delete product.')),
      );
    }
  }

  String _value(String key, String fallback) {
    return widget.product[key]?.trim().isNotEmpty == true
        ? widget.product[key]!
        : fallback;
  }

  @override
  Widget build(BuildContext context) {
    final serialRows = _serialNumbers;
    final serialStart =
        _serialTotal == 0 ? 0 : ((_serialPage - 1) * _serialPerPage) + 1;
    final serialEnd = _serialTotal == 0
        ? 0
        : (_serialPage * _serialPerPage) > _serialTotal
            ? _serialTotal
            : _serialPage * _serialPerPage;

    final modelCode = _product?.modelCode ?? _value('modelCode', '');
    final supplierType = _product?.applianceType ?? _value('supplierType', '');
    final uom = _product?.unitsofmeasurement ?? _value('uom', '');
    final quantity = _value('quantity', '-');
    final poNumber = _value('poNumber', '-');
    final drNumber = _value('drNumber', '-');
    final contractDate = _product?.contractDate ?? _value('contractDate', '');
    final deliveryDate = _product?.deliveryDate ?? _value('deliveryDate', '');
    final installationDate =
        _product?.installmentDate ?? _value('installationDate', '');
    final employeeName =
        _product?.employeeId.toString() ?? _value('employeeName', '-');

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: CustomAppBar(title: 'Direct Client', showMenuButton: false),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Product Details Card ────────────────────────
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.07),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Gradient header band
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF87CEEB), Color(0xFF2563EB)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(16),
                        topRight: Radius.circular(16),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                                color: Colors.white.withOpacity(0.4),
                                width: 1.5),
                          ),
                          child: Center(
                            child: Text(
                              (_product?.modelName ??
                                          widget.product['modelName'] ??
                                          '')
                                      .isNotEmpty
                                  ? (_product?.modelName ??
                                          widget.product['modelName'] ??
                                          '')
                                      .substring(0, 1)
                                      .toUpperCase()
                                  : '?',
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _product?.modelName ??
                                    widget.product['modelName'] ??
                                    '-',
                                style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 5),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 3),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Text(
                                  'Product Details',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.white,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Info rows
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        if (_errorText != null) ...[
                          Text(
                            _errorText!,
                            style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFFB91C1C),
                                fontWeight: FontWeight.w500),
                          ),
                          const SizedBox(height: 12),
                        ],
                        _buildInfoRow(Icons.qr_code_outlined, 'Model Code',
                            modelCode.isEmpty ? '-' : modelCode),
                        const SizedBox(height: 14),
                        _buildInfoRow(Icons.local_offer_outlined,
                            'Supplier Type',
                            supplierType.isEmpty ? '-' : supplierType),
                        const SizedBox(height: 14),
                        _buildInfoRow(Icons.straighten_outlined, 'UOM',
                            uom.isEmpty ? '-' : uom),
                        const SizedBox(height: 14),
                        _buildInfoRow(
                            Icons.inventory_2_outlined, 'Quantity', quantity),
                        const SizedBox(height: 14),
                        _buildInfoRow(
                            Icons.receipt_outlined, 'PO Number', poNumber),
                        const SizedBox(height: 14),
                        _buildInfoRow(
                            Icons.description_outlined, 'DR Number', drNumber),
                        const SizedBox(height: 14),
                        _buildInfoRow(Icons.event_outlined, 'Contract Date',
                            contractDate.isEmpty ? '-' : contractDate),
                        const SizedBox(height: 14),
                        _buildInfoRow(Icons.calendar_today_outlined,
                            'Delivery Date',
                            deliveryDate.isEmpty ? '-' : deliveryDate),
                        const SizedBox(height: 14),
                        _buildInfoRow(Icons.build_outlined, 'Installation Date',
                            installationDate.isEmpty ? '-' : installationDate),
                        const SizedBox(height: 14),
                        _buildInfoRow(Icons.person_outline, 'Employee Name',
                            employeeName),
                        const SizedBox(height: 20),
                        // Pill action buttons
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          EditProductDetailsScreen(
                                        product: widget.product,
                                      ),
                                    ),
                                  ).then((_) => _loadProduct());
                                },
                                icon: const Icon(Icons.edit_outlined, size: 18),
                                label: const Text('Edit'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF2563EB),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 13),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                  elevation: 0,
                                  textStyle: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed:
                                    SessionFlags.userRole != 'Super Admin'
                                        ? null
                                        : () async {
                                            final confirmed =
                                                await showDialog<bool>(
                                              context: context,
                                              builder: (context) =>
                                                  AlertDialog(
                                                title: const Text(
                                                    'Delete Product'),
                                                content: const Text(
                                                    'Are you sure you want to delete this product? This action cannot be undone.'),
                                                actions: [
                                                  TextButton(
                                                    onPressed: () =>
                                                        Navigator.pop(
                                                            context, false),
                                                    child: const Text(
                                                        'Cancel'),
                                                  ),
                                                  ElevatedButton(
                                                    onPressed: () =>
                                                        Navigator.pop(
                                                            context, true),
                                                    style: ElevatedButton
                                                        .styleFrom(
                                                      backgroundColor:
                                                          const Color(
                                                              0xFFEF4444),
                                                      foregroundColor:
                                                          Colors.white,
                                                      elevation: 0,
                                                    ),
                                                    child: const Text(
                                                        'Delete'),
                                                  ),
                                                ],
                                              ),
                                            );
                                            if (confirmed == true) {
                                              await _deleteProduct();
                                            }
                                          },
                                icon:
                                    const Icon(Icons.delete_outline, size: 18),
                                label: const Text('Delete'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFEF4444),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 13),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                  elevation: 0,
                                  textStyle: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                const Text(
                  'Serial Number Details',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                if (_isLoadingSerials) ...[
                  const SizedBox(width: 10),
                  const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
                    child: _buildSearchField('Search'),
                  ),
                  const SizedBox(height: 10),
                  _buildTableHeader(),
                  if (_isLoadingSerials && serialRows.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 20),
                      child: Center(
                          child:
                              CircularProgressIndicator(strokeWidth: 2)),
                    )
                  else if (_serialError != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          vertical: 12, horizontal: 12),
                      child: Text(
                        _serialError!,
                        style: const TextStyle(
                            color: Color(0xFFB91C1C), fontSize: 12),
                      ),
                    )
                  else if (serialRows.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(
                          vertical: 16, horizontal: 12),
                      child: Text(
                        'No serial numbers found.',
                        style: TextStyle(
                            fontSize: 12, color: Colors.black54),
                      ),
                    )
                  else
                    ...serialRows.map((sn) => _buildTableRow(context, sn)),
                  _buildPaginationFooter(
                    start: serialStart,
                    end: serialEnd,
                    total: _serialTotal,
                    page: _serialPage,
                    lastPage: _serialLastPage,
                    onFirst: _serialPage > 1
                        ? () {
                            setState(() => _serialPage = 1);
                            _fetchSerialNumbers();
                          }
                        : null,
                    onPrev: _serialPage > 1
                        ? () {
                            setState(() => _serialPage--);
                            _fetchSerialNumbers();
                          }
                        : null,
                    onNext: _serialPage < _serialLastPage
                        ? () {
                            setState(() => _serialPage++);
                            _fetchSerialNumbers();
                          }
                        : null,
                    onLast: _serialPage < _serialLastPage
                        ? () {
                            setState(
                                () => _serialPage = _serialLastPage);
                            _fetchSerialNumbers();
                          }
                        : null,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            if (_isLoading) const LinearProgressIndicator(minHeight: 2),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: const Color(0xFF2563EB).withOpacity(0.07),
            borderRadius: BorderRadius.circular(9),
          ),
          child: Icon(icon, size: 17, color: const Color(0xFF2563EB)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[500])),
              const SizedBox(height: 2),
              Text(value,
                  style: const TextStyle(
                      fontSize: 14, color: Colors.black87, height: 1.4)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSearchField(String hint) {
    return SizedBox(
      height: 36,
      child: TextField(
        controller: _searchController,
        onChanged: _onSerialSearchChanged,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(fontSize: 12, color: Colors.grey[400]),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6),
            borderSide: const BorderSide(color: Color(0xFF87CEEB), width: 1.5),
          ),
        ),
      ),
    );
  }

  Widget _buildTableHeader() {
    return Container(
      decoration: BoxDecoration(
        border: Border.symmetric(
          horizontal: BorderSide(color: Colors.grey[200]!),
        ),
      ),
      child: Row(
        children: [
          const Expanded(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 10, horizontal: 12),
              child: Text(
                'Serial Number',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
              ),
            ),
          ),
          Container(
            width: 1,
            height: 36,
            color: Colors.grey[200],
          ),
          const SizedBox(
            width: 120,
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 10, horizontal: 8),
              child: Text(
                'Actions',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTableRow(BuildContext context, SerialNumberModel sn) {
    return Container(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey[100]!)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
              child: Text(
                sn.serialnumber,
                style:
                    const TextStyle(fontSize: 12, color: Colors.black87),
              ),
            ),
          ),
          Container(
            width: 1,
            height: 40,
            color: Colors.grey[100],
          ),
          SizedBox(
            width: 120,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                OutlinedButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => SerialNumberDetailScreen(
                        serialId: sn.id,
                        clientId: sn.clientId,
                      ),
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 5, vertical: 4),
                    side: const BorderSide(color: Color(0xFF2563EB)),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4)),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(Icons.visibility_outlined,
                          size: 13, color: Color(0xFF2563EB)),
                      SizedBox(width: 2),
                      Text('View',
                          style: TextStyle(
                              fontSize: 11,
                              color: Color(0xFF2563EB),
                              fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),

              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaginationFooter({
    required int start,
    required int end,
    required int total,
    required int page,
    required int lastPage,
    required VoidCallback? onFirst,
    required VoidCallback? onPrev,
    required VoidCallback? onNext,
    required VoidCallback? onLast,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Showing $start to $end of $total entries',
            style: TextStyle(fontSize: 11, color: Colors.grey[600]),
          ),
          Row(
            children: [
              _PaginationBtn(
                  icon: Icons.keyboard_double_arrow_left, onTap: onFirst),
              _PaginationBtn(icon: Icons.chevron_left, onTap: onPrev),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF2563EB),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '$page',
                  style: const TextStyle(
                    fontSize: 11,
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              _PaginationBtn(icon: Icons.chevron_right, onTap: onNext),
              _PaginationBtn(
                  icon: Icons.keyboard_double_arrow_right, onTap: onLast),
            ],
          ),
        ],
      ),
    );
  }
}

class _PaginationBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;

  const _PaginationBtn({Key? key, required this.icon, this.onTap})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Icon(
          icon,
          size: 16,
          color: onTap != null ? Colors.grey[700] : Colors.grey[350],
        ),
      ),
    );
  }
}
