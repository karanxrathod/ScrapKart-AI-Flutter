import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/text_styles.dart';
import '../../core/widgets/animated_blob_background.dart';
import '../../core/widgets/glass_card.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/auth_service.dart';
import 'auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _isLoginMode = true; // Toggle between Login and Signup

  Future<void> _handleEmailAuth() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      _showError('Please enter email and password');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final authService = ref.read(authServiceProvider);
      if (_isLoginMode) {
        await authService.signInWithEmail(
          email: email,
          password: password,
        );
      } else {
        final name = email.split('@')[0];
        await authService.signUpWithEmail(
          name: name[0].toUpperCase() + name.substring(1),
          email: email,
          password: password,
          role: 'User', // Default role from login screen
        );
      }
      if (mounted) context.go('/home');
    } catch (e) {
      _showError(e.toString().replaceAll('Exception:', '').trim());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() => _isLoading = true);
    try {
      final authService = ref.read(authServiceProvider);
      await authService.signInWithGoogle();
      if (mounted) context.go('/home');
    } catch (e) {
      _showError(e.toString().replaceAll('Exception:', '').trim());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _signInWithPhone() async {
    final phoneController = TextEditingController();
    final codeController = TextEditingController();
    String? verificationId;
    bool codeSent = false;
    bool isDialogLoading = false;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            backgroundColor: AppColors.background,
            title: Text(codeSent ? 'Enter OTP' : 'Enter Phone Number', style: AppTextStyles.headline.copyWith(fontSize: 20)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (!codeSent)
                  TextField(
                    controller: phoneController,
                    keyboardType: TextInputType.phone,
                    style: AppTextStyles.body,
                    decoration: InputDecoration(
                      hintText: '+1 234 567 8900',
                      hintStyle: AppTextStyles.body.copyWith(color: Colors.grey),
                    ),
                  )
                else
                  TextField(
                    controller: codeController,
                    keyboardType: TextInputType.number,
                    style: AppTextStyles.body,
                    decoration: InputDecoration(
                      hintText: '123456',
                      hintStyle: AppTextStyles.body.copyWith(color: Colors.grey),
                    ),
                  ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Cancel', style: AppTextStyles.body.copyWith(color: Colors.red)),
              ),
              ElevatedButton(
                onPressed: () async {
                  final authService = ref.read(authServiceProvider);
                  if (!codeSent) {
                    if (phoneController.text.isEmpty) return;
                    setDialogState(() => isDialogLoading = true);
                    await authService.verifyPhoneNumber(
                      phoneNumber: phoneController.text,
                      codeSent: (id) {
                        setDialogState(() {
                          verificationId = id;
                          codeSent = true;
                          isDialogLoading = false;
                        });
                      },
                      verificationFailed: (error) {
                        setDialogState(() => isDialogLoading = false);
                        Navigator.pop(context);
                        _showError(error);
                      },
                    );
                  } else {
                    if (codeController.text.isEmpty || verificationId == null) return;
                    setDialogState(() => isDialogLoading = true);
                    try {
                      await authService.verifyOTP(
                        verificationId: verificationId!,
                        smsCode: codeController.text,
                      );
                      if (context.mounted) {
                        Navigator.pop(context);
                        context.go('/home');
                      }
                    } catch (e) {
                      setDialogState(() => isDialogLoading = false);
                      Navigator.pop(context);
                      _showError(e.toString().replaceAll('Exception:', '').trim());
                    }
                  }
                },
                child: isDialogLoading 
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) 
                    : Text(codeSent ? 'Verify' : 'Send Code', style: AppTextStyles.button.copyWith(fontSize: 14)),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedBlobBackground(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 80.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _isLoginMode ? 'Welcome Back 👋' : 'Create Account 🎉',
                style: AppTextStyles.headline.copyWith(fontSize: 32),
              ).animate().slideX(begin: -0.2, end: 0, duration: 500.ms).fadeIn(),
              const SizedBox(height: 8),
              Text(
                _isLoginMode ? 'Login to continue' : 'Sign up to get started with ScrapKart',
                style: AppTextStyles.subtitle,
              ).animate().slideX(begin: -0.2, end: 0, duration: 500.ms, delay: 100.ms).fadeIn(delay: 100.ms),
              
              const SizedBox(height: 48),
              
              GlassCard(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    _buildTextField(
                      controller: _emailController,
                      hint: 'Email',
                      icon: Icons.email_outlined,
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _passwordController,
                      hint: 'Password',
                      icon: Icons.lock_outline,
                      isPassword: true,
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _handleEmailAuth,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 0,
                        ),
                        child: _isLoading 
                            ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : Text(
                                _isLoginMode ? 'Login' : 'Sign Up', 
                                style: AppTextStyles.button
                              ),
                      ),
                    ),
                  ],
                ),
              ).animate().slideY(begin: 0.2, end: 0, duration: 600.ms, delay: 200.ms).fadeIn(delay: 200.ms),
              
              const SizedBox(height: 32),
              
              Center(
                child: Text('Or continue with', style: AppTextStyles.body)
                    .animate().fadeIn(delay: 400.ms),
              ),
              
              const SizedBox(height: 24),
              
              // Social Login Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildSocialButton(Icons.g_mobiledata, AppColors.secondary, _signInWithGoogle),
                  const SizedBox(width: 16),
                  _buildSocialButton(Icons.phone, AppColors.tertiary, _signInWithPhone),
                ],
              ).animate().slideY(begin: 0.2, end: 0, duration: 500.ms, delay: 500.ms).fadeIn(delay: 500.ms),
              
              const SizedBox(height: 24),
              
              // Guest Access Option
              Center(
                child: TextButton.icon(
                  onPressed: () async {
                    setState(() => _isLoading = true);
                    try {
                      final authService = ref.read(authServiceProvider);
                      await authService.signInAsGuest();
                      if (context.mounted) context.go('/home');
                    } catch (e) {
                      _showError(e.toString());
                    } finally {
                      if (mounted) setState(() => _isLoading = false);
                    }
                  },
                  icon: const Icon(Icons.person_outline, color: Colors.blueAccent),
                  label: Text(
                    'Continue as Guest', 
                    style: AppTextStyles.body.copyWith(
                      color: Colors.blueAccent, 
                      fontWeight: FontWeight.bold
                    )
                  ),
                ),
              ).animate().slideY(begin: 0.2, end: 0, duration: 500.ms, delay: 550.ms).fadeIn(delay: 550.ms),

              const SizedBox(height: 40),
              
              Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _isLoginMode ? "Don't have an account? " : 'Already have an account? ', 
                      style: AppTextStyles.body
                    ),
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _isLoginMode = !_isLoginMode;
                        });
                      },
                      child: Text(
                        _isLoginMode ? 'Sign Up' : 'Login',
                        style: AppTextStyles.body.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn(delay: 600.ms),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint, 
    required IconData icon, 
    bool isPassword = false
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white, width: 2),
      ),
      child: TextField(
        controller: controller,
        obscureText: isPassword,
        style: AppTextStyles.body.copyWith(color: AppColors.textPrimary),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: AppTextStyles.body,
          prefixIcon: Icon(icon, color: AppColors.textSecondary),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
  }

  Widget _buildSocialButton(IconData icon, Color color, VoidCallback onTap) {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.5),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
      ),
      child: IconButton(
        icon: Icon(icon, size: 38, color: color),
        onPressed: onTap,
      ),
    );
  }
}
