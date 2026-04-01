import 'package:flutter/material.dart';
import '../models/service_type_model.dart';
import '../screens/service_type_detail_screen.dart';

class ServiceTypeCard extends StatelessWidget {
  final ServiceTypeModel item;

  const ServiceTypeCard({Key? key, required this.item}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ServiceTypeDetailScreen(item: item),
          ),
        );
      },
      child: Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFFE8F0FE),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.build_outlined,
                color: Color(0xFF2563EB), size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              item.setypename,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ),
          const Icon(Icons.chevron_right, color: Colors.black38),
        ],
      ),
    ));
  }
}
