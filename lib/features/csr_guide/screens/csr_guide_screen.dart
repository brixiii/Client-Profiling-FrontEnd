import 'package:flutter/material.dart';
import '../../../shared/widgets/app_drawer.dart';
import '../../../shared/widgets/custom_app_bar.dart';

class CsrGuideScreen extends StatefulWidget {
  const CsrGuideScreen({Key? key}) : super(key: key);

  @override
  State<CsrGuideScreen> createState() => _CsrGuideScreenState();
}

class _CsrGuideScreenState extends State<CsrGuideScreen> {
  // Tracks whether the full documentation list is visible
  bool _docListVisible = true;

  // Tracks which section is currently expanded (null = all collapsed)
  String? _expandedSection;

  // Tracks the currently selected sub-item (highlights it in blue)
  String? _selectedTopic;

  // Documentation sections with their sub-items
  final List<Map<String, dynamic>> _docSections = [
    {
      'title': 'Company Policies',
      'subItems': [
        'Statement of Purpose',
        'Guiding Principles',
        'Communication and Customer Engagement',
        'Service Quality Policy',
        'Complaint Handling and Resolution Policy',
        'Data Privacy and Confidentiality Policy',
        'Warranty and After-Sales Support Policy',
        'Ethical Conduct and Accountability Policy',
        'Feedback and Continuous Improvement Policy',
        'Delivery and Installation Policy',
        'Refund, Replacement, and Return Policy',
        'Customer Satisfaction and Loyalty',
        'Policy Awareness and Reviews',
        'Acknowledgment',
      ],
    },
    {
      'title': 'Price List',
      'subItems': ['Spare Parts', 'Machines', 'Accessories', 'Services'],
    },
    {
      'title': 'Product Knowledge',
      'subItems': ['Product Introduction', 'Key Technical Features and Specifications'],
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: CustomAppBar(
        title: 'CSR Guide',
        showMenuButton: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.account_circle_outlined, color: Colors.black87),
            onPressed: () {},
          ),
        ],
      ),
      drawer: const AppDrawer(currentPage: 'CSR Guide'),
      body: Container(
        color: Colors.white,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // â”€â”€ "Documentation" bold heading â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
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

              // â”€â”€ "Select Documentation" header row â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
              // Down chevron = this tree is always open/visible
              _buildTopRow('Select Documentation'),
              Divider(height: 1, color: Colors.grey[200]),

              // â”€â”€ Expandable sections â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
              if (_docListVisible) ..._docSections.map((section) {
                final title = section['title'] as String;
                final subItems = section['subItems'] as List<String>;
                final isExpanded = _expandedSection == title;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Section row â€” tap to expand / collapse
                    InkWell(
                      onTap: () {
                        setState(() {
                          _expandedSection = isExpanded ? null : title;
                        });
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 14),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                title,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                            Icon(
                              isExpanded
                                  ? Icons.expand_more
                                  : Icons.chevron_right,
                              size: 20,
                              color: Colors.grey[600],
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Sub-items â€” only visible when section is expanded
                    if (isExpanded && subItems.isNotEmpty)
                      ...subItems.map(
                        (sub) => InkWell(
                          onTap: () {
                            setState(() => _selectedTopic = sub);
                            // TODO: navigate to content screen when ready
                          },
                          child: Padding(
                            padding:
                                const EdgeInsets.fromLTRB(32, 10, 16, 10),
                            child: Text(
                              sub,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: _selectedTopic == sub
                                    ? FontWeight.w600
                                    : FontWeight.w400,
                                color: _selectedTopic == sub
                                    ? const Color(0xFF2563EB)
                                    : Colors.black87,
                              ),
                            ),
                          ),
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

  // â”€â”€ "Select Documentation" top row (down arrow, non-toggling) â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
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

