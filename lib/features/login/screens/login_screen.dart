import 'package:flutter/material.dart';
import '../../../theme/colors.dart';
import '../../../shared/widgets/custom_text_field.dart';
import '../../reset_password/screens/reset_password_screen.dart';
import '../../dashboard/screens/dashboard_screen.dart';
import '../../preloader/widgets/washing_loader.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  Future<void> _handleLogin() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _isLoading = true);
    // Simulate network / auth delay — replace with your real auth call here.
    await Future.delayed(const Duration(seconds: 3));
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const DashboardScreen()),
    );
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

    return Stack(
      children: [
        Scaffold(
          backgroundColor: AppColors.background,
          body: SafeArea(
        child: SingleChildScrollView(
          child: SizedBox(
            height: screenHeight - MediaQuery.of(context).padding.top,
            child: Column(
              children: [
                // Title
                const Padding(
                  padding: EdgeInsets.only(top: 12.0),
                  child: Text(
                    'Client Profiling',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                      letterSpacing: -0.5,
                    ),
                  ),
                ),

                // Logo
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 28.0),
                  child: Image.asset(
                    'web/icons/vpdlogo.png',
                    height: 100,
                    width: 100,
                    fit: BoxFit.contain,
                  ),
                ),

                // Login card
                Expanded(
                  child: Center(
                    child: SingleChildScrollView(
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 20),
                        padding: const EdgeInsets.all(32),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(28),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.08),
                              blurRadius: 16,
                              offset: const Offset(0, 8),
                            ),
                            BoxShadow(
                              color: Colors.black.withOpacity(0.04),
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
                                hintText: 'Username/Phone no./Email',
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
                                      AppColors.secondary.withOpacity(0.85),
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(24),
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
                                    onTap: _isLoading ? null : _handleLogin,
                                    borderRadius: BorderRadius.circular(24),
                                    child: const Padding(
                                      padding: EdgeInsets.symmetric(
                                        vertical: 16,
                                        horizontal: 24,
                                      ),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            'Sign In',
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w700,
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

                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
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
