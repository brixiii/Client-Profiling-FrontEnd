import 'dart:math' show max;
import 'package:flutter/material.dart';
import '../../../theme/colors.dart';
import '../../../shared/widgets/custom_text_field.dart';
import '../../../shared/widgets/animated_fade_slide.dart';
import '../../../shared/api/backend_api.dart';
import '../../../shared/session_flags.dart';
import '../../../shared/api/api_exception.dart';
import '../../reset_password/screens/reset_password_screen.dart';
import '../../dashboard/screens/dashboard_screen.dart';
import '../../preloader/widgets/washing_loader.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _api = BackendApi();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  Future<void> _handleLogin() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _isLoading = true);
    try {
      final user = await _api.login(
        identifier: _usernameController.text.trim(),
        password: _passwordController.text,
      );
      SessionFlags.userRole = user.role;

      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => const DashboardScreen(),
          transitionDuration: const Duration(milliseconds: 450),
          transitionsBuilder: (_, anim, __, child) => FadeTransition(
            opacity: CurvedAnimation(parent: anim, curve: Curves.easeIn),
            child: child,
          ),
        ),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to login. Please try again.')),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    // Responsive values
    final titleFontSize = (screenWidth * 0.10).clamp(26.0, 44.0);
    final topPadding = max(36.0, screenHeight * 0.07);
    final cardPadding = screenWidth < 400 ? 20.0 : 28.0;

    return Stack(
      children: [
        Scaffold(
          backgroundColor: Color.fromARGB(255, 247, 236, 236),
          body: Stack(
            children: [
              // Full-screen background image
              Positioned.fill(
                child: Image.asset(
                  'web/icons/vpdlogo.png',
                  fit: BoxFit.cover,
                ),
              ),
              // Semi-transparent dark overlay for readability
              Positioned.fill(
                child: Container(
                  color: Colors.black.withOpacity(0.55),
                ),
              ),
              // Main content
              SafeArea(
                child: SingleChildScrollView(
                  child: SizedBox(
                    height: screenHeight - MediaQuery.of(context).padding.top,
                    child: Column(
                      children: [
                        // "Client Profiling" title at the top — slides down + fades in
                        AnimatedFadeSlide(
                          beginOffset: const Offset(0.0, -0.10),
                          duration: const Duration(milliseconds: 500),
                          child: Column(
                            children: [
                              Padding(
                                padding: EdgeInsets.only(
                                    top: topPadding, bottom: 4.0),
                                child: Text(
                                  'Client Profiling',
                                  style: TextStyle(
                                    fontSize: titleFontSize,
                                    fontWeight: FontWeight.w800,
                                    fontStyle: FontStyle.italic,
                                    color: Colors.white,
                                    letterSpacing: 0.5,
                                    shadows: const [
                                      Shadow(
                                        color: Colors.black54,
                                        blurRadius: 8,
                                        offset: Offset(2, 3),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const Padding(
                                padding: EdgeInsets.only(bottom: 8.0),
                                child: Text(
                                  'Manage. Track. Grow.',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.white70,
                                    fontWeight: FontWeight.w400,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Login card — slides up + fades in with a slight delay
                        Expanded(
                          child: AnimatedFadeSlide(
                            delay: const Duration(milliseconds: 220),
                            beginOffset: const Offset(0.0, 0.08),
                            duration: const Duration(milliseconds: 460),
                            child: Center(
                              child: SingleChildScrollView(
                                child: ConstrainedBox(
                                  constraints:
                                      const BoxConstraints(maxWidth: 480),
                                  child: Container(
                                    margin: const EdgeInsets.symmetric(
                                        horizontal: 20),
                                    padding: EdgeInsets.all(cardPadding),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.93),
                                      borderRadius: BorderRadius.circular(28),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.22),
                                          blurRadius: 24,
                                          offset: const Offset(0, 8),
                                        ),
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.08),
                                          blurRadius: 4,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Form(
                                      key: _formKey,
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          // Welcome text
                                          const Text(
                                            'Welcome',
                                            style: TextStyle(
                                              fontSize: 26,
                                              fontWeight: FontWeight.w700,
                                              color: AppColors.textPrimary,
                                              letterSpacing: -0.3,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          const Text(
                                            'Sign in to your account',
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: AppColors.textSecondary,
                                              fontWeight: FontWeight.w400,
                                            ),
                                          ),
                                          const SizedBox(height: 28),

                                          // Username field
                                          CustomTextField(
                                            hintText:
                                                'Username/Email',
                                            icon: Icons.person_outline,
                                            controller: _usernameController,
                                            validator: (value) {
                                              if (value?.isEmpty ?? true) {
                                                return 'This field is required';
                                              }
                                              return null;
                                            },
                                          ),

                                          // Password field
                                          CustomTextField(
                                            hintText: 'Password',
                                            icon: Icons.lock_outline,
                                            isPassword: true,
                                            controller: _passwordController,
                                            validator: (value) {
                                              if (value?.isEmpty ?? true) {
                                                return 'Password is required';
                                              }
                                              return null;
                                            },
                                          ),

                                          // Forgot password link
                                          Align(
                                            alignment: Alignment.centerRight,
                                            child: GestureDetector(
                                              onTap: () {
                                                Navigator.of(context).push(
                                                  MaterialPageRoute(
                                                    builder: (context) =>
                                                        const ResetPasswordScreen(),
                                                  ),
                                                );
                                              },
                                              child: const Text(
                                                'Forgot Password?',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: AppColors.link,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(height: 28),

                                          // Sign in button with gradient
                                          SizedBox(
                                            width: double.infinity,
                                            child: Container(
                                              decoration: BoxDecoration(
                                                gradient: LinearGradient(
                                                  colors: [
                                                    AppColors.secondary,
                                                    AppColors.secondary
                                                        .withOpacity(0.85),
                                                  ],
                                                  begin: Alignment.topLeft,
                                                  end: Alignment.bottomRight,
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(24),
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: AppColors.secondary
                                                        .withOpacity(0.3),
                                                    blurRadius: 12,
                                                    offset: const Offset(0, 4),
                                                  ),
                                                ],
                                              ),
                                              child: Material(
                                                color: Colors.transparent,
                                                child: InkWell(
                                                  onTap: _isLoading
                                                      ? null
                                                      : _handleLogin,
                                                  borderRadius:
                                                      BorderRadius.circular(24),
                                                  child: const Padding(
                                                    padding:
                                                        EdgeInsets.symmetric(
                                                      vertical: 16,
                                                      horizontal: 24,
                                                    ),
                                                    child: Row(
                                                      mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .center,
                                                      children: [
                                                        Text(
                                                          'Sign In',
                                                          style: TextStyle(
                                                            fontSize: 16,
                                                            fontWeight:
                                                                FontWeight.w700,
                                                            color: Colors.white,
                                                            letterSpacing: 0.5,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        // Loading overlay — sits on top of the whole screen
        if (_isLoading)
          Container(
            color: Colors.black54,
            child: const Center(
              child: WashingLoader(scale: 1.2),
            ),
          ),
      ],
    );
  }
}
