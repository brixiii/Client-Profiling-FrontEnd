import 'package:flutter/material.dart';

/// Floating pill-shaped AppBar used across all screens.
///
/// - [showMenuButton] true  → hamburger icon (opens drawer)
/// - [showMenuButton] false → back arrow (Navigator.pop)
/// - [actions] optional row of widgets on the right
class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final bool showMenuButton;
  final List<Widget> actions;

  const CustomAppBar({
    Key? key,
    required this.title,
    this.showMenuButton = false,
    this.actions = const [],
  }) : super(key: key);

  @override
  Size get preferredSize => const Size.fromHeight(68);

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
        child: Container(
          height: 52,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(32),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              // Leading button
              if (showMenuButton)
                Builder(
                  builder: (ctx) => IconButton(
                    icon: const Icon(Icons.menu, color: Colors.black87),
                    onPressed: () => Scaffold.of(ctx).openDrawer(),
                  ),
                )
              else
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.black87),
                  onPressed: () => Navigator.pop(context),
                ),

              // Title
              Expanded(
                child: Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.black87,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),

              // Trailing actions (or spacer to balance leading)
              if (actions.isNotEmpty)
                ...actions
              else
                const SizedBox(width: 48),
            ],
          ),
        ),
      ),
    );
  }
}
