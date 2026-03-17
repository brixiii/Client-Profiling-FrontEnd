import 'package:flutter/material.dart';
import '../widgets/washing_loader.dart';

/// Sample screen that demonstrates the [WashingLoader] widget.
///
/// Navigate to this screen from anywhere with:
///   Navigator.push(context, MaterialPageRoute(
///     builder: (_) => const PreloaderScreen(),
///   ));
///
/// Or set it as the initial route in main.dart:
///   home: const PreloaderScreen(),
class PreloaderScreen extends StatelessWidget {
  const PreloaderScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Dark background so the white machine body stands out.
      backgroundColor: const Color(0xFF37474F),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            // Change `scale` to resize the whole loader proportionally.
            WashingLoader(scale: 1.5),
            SizedBox(height: 32),
            Text(
              'Loading…',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 16,
                letterSpacing: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
