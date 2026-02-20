import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';
import '../../services/auth_service.dart';
import '../../config/theme.dart';
import 'signup_screen.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _identityController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _showPasswordField = false;

  static const _bgColor = Color(0xFF1A1A2E);
  static const _cardColor = Color(0xFF2A2A3E);
  static const _hintColor = Color(0xFF6B6B7B);

  @override
  void dispose() {
    _identityController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  bool get _isEmail => _identityController.text.contains('@');

  void _onContinue() {
    if (!_showPasswordField) {
      if (_identityController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter your phone number or email')),
        );
        return;
      }
      setState(() => _showPasswordField = true);
      return;
    }

    if (!_formKey.currentState!.validate()) return;

    final identity = _identityController.text.trim();
    if (_isEmail) {
      ref.read(authProvider.notifier).signInWithEmail(
            email: identity,
            password: _passwordController.text,
          );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Phone sign-in coming soon')),
      );
    }
  }

  void _forgotPassword() async {
    final identity = _identityController.text.trim();
    if (identity.isEmpty || !identity.contains('@')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter your email above, then tap Forgot Password')),
      );
      return;
    }
    try {
      final authService = AuthService();
      await authService.sendPasswordResetEmail(identity);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Password reset email sent to $identity')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    ref.listen<AuthState>(authProvider, (previous, next) {
      if (next.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.error!), backgroundColor: Colors.red),
        );
        ref.read(authProvider.notifier).clearError();
      }
    });

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: _bgColor,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 24),
                  Center(child: _buildLogo()),
                  const SizedBox(height: 40),

                  const Text(
                    'Login to your\nAccount',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 12),

                  Text(
                    "What's your phone number or email?",
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.grey[400],
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  const SizedBox(height: 24),

                  TextFormField(
                    controller: _identityController,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: _showPasswordField ? TextInputAction.next : TextInputAction.done,
                    onFieldSubmitted: (_) {
                      if (!_showPasswordField) _onContinue();
                    },
                    onChanged: (_) {
                      if (_showPasswordField) setState(() {});
                    },
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                    decoration: InputDecoration(
                      hintText: 'Enter phone number or email',
                      hintStyle: const TextStyle(color: _hintColor, fontSize: 15),
                      filled: true,
                      fillColor: _cardColor,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFF4A4A5E), width: 1.5),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFF4A4A5E), width: 1.5),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: AppTheme.brandGreen, width: 2),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
                    ),
                  ),

                  if (_showPasswordField) ...[
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => _onContinue(),
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                      autofocus: true,
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Please enter your password';
                        if (v.length < 6) return 'Password must be at least 6 characters';
                        return null;
                      },
                      decoration: InputDecoration(
                        hintText: 'Password',
                        hintStyle: const TextStyle(color: _hintColor, fontSize: 15),
                        prefixIcon: const Icon(Icons.lock_outline, color: _hintColor, size: 22),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                            color: _hintColor,
                          ),
                          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                        ),
                        filled: true,
                        fillColor: _cardColor,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFF4A4A5E), width: 1.5),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFF4A4A5E), width: 1.5),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: AppTheme.brandGreen, width: 2),
                        ),
                        errorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Colors.redAccent, width: 1),
                        ),
                        focusedErrorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),

                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: authState.isLoading ? null : _onContinue,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: Colors.black54,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      child: authState.isLoading
                          ? const SizedBox(
                              width: 22, height: 22,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Text('Continue', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
                    ),
                  ),
                  const SizedBox(height: 28),

                  _buildOrDivider(),
                  const SizedBox(height: 20),

                  _buildSocialButton(
                    label: 'Continue with Google',
                    icon: _buildGoogleIcon(),
                  ),
                  const SizedBox(height: 12),
                  _buildSocialButton(
                    label: 'Continue with Apple',
                    icon: const Icon(Icons.apple, color: Colors.white, size: 22),
                  ),
                  const SizedBox(height: 32),

                  Center(
                    child: GestureDetector(
                      onTap: _forgotPassword,
                      child: Text(
                        'Forgot Password',
                        style: TextStyle(
                          color: AppTheme.brandGreen,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        "Don't have an account?  ",
                        style: TextStyle(color: Color(0xFF8E8E9E), fontSize: 14),
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => const SignupScreen()));
                        },
                        child: Text(
                          'Sign up',
                          style: TextStyle(
                            color: AppTheme.brandGreen,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Column(
      children: [
        RichText(
          text: const TextSpan(
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, letterSpacing: -0.5),
            children: [
              TextSpan(text: 'onth', style: TextStyle(color: Colors.white)),
              TextSpan(text: 'e', style: TextStyle(color: Color(0xFF4CAF50))),
              TextSpan(text: 'way', style: TextStyle(color: Colors.white)),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Container(
          width: 60,
          height: 3,
          decoration: BoxDecoration(
            color: AppTheme.brandGreen,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ],
    );
  }

  Widget _buildOrDivider() {
    return Row(
      children: [
        Expanded(child: Container(height: 1, color: const Color(0xFF3A3A4E))),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Text('or', style: TextStyle(color: Color(0xFF6B6B7B), fontSize: 14, fontWeight: FontWeight.w400)),
        ),
        Expanded(child: Container(height: 1, color: const Color(0xFF3A3A4E))),
      ],
    );
  }

  Widget _buildSocialButton({required String label, required Widget icon}) {
    return GestureDetector(
      onTap: () {
        final provider = label.contains('Google') ? 'Google' : 'Apple';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$provider sign-in coming soon'), duration: const Duration(seconds: 2)),
        );
      },
      child: Container(
        width: double.infinity,
        height: 56,
        decoration: BoxDecoration(
          color: _cardColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            icon,
            const SizedBox(width: 12),
            Text(label, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }

  Widget _buildGoogleIcon() {
    return Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
      ),
      child: const Center(
        child: Text('G', style: TextStyle(color: Color(0xFF4285F4), fontSize: 15, fontWeight: FontWeight.w700)),
      ),
    );
  }
}
