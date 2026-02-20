import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';
import '../../config/theme.dart';
import 'signup_screen.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _signIn() {
    print('[LOGIN] _signIn called');
    if (_formKey.currentState!.validate()) {
      print('[LOGIN] form valid, calling signInWithEmail');
      ref.read(authProvider.notifier).signInWithEmail(
            email: _emailController.text.trim(),
            password: _passwordController.text,
          );
    } else {
      print('[LOGIN] form validation failed');
    }
  }

  void _quickFill(String role) {
    setState(() {
      if (role == 'customer') {
        _emailController.text = 'customer@otw.com';
      } else {
        _emailController.text = 'hero@otw.com';
      }
      _passwordController.text = 'test123';
    });
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    print('[LOGIN] build: isLoading=${authState.isLoading}, isInitialized=${authState.isInitialized}, isAuthenticated=${authState.isAuthenticated}, error=${authState.error}');

    ref.listen<AuthState>(authProvider, (previous, next) {
      if (next.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.error!), backgroundColor: Colors.red),
        );
        ref.read(authProvider.notifier).clearError();
      }
    });

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF5F5F5),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 80),

                  // Logo
                  Center(child: _buildLogo()),

                  const SizedBox(height: 12),

                  // Tagline
                  const Text(
                    'Roadside Assistance, Fast',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 15,
                      color: Color(0xFF9E9E9E),
                      fontWeight: FontWeight.w400,
                    ),
                  ),

                  const SizedBox(height: 48),

                  // Email field
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    decoration: InputDecoration(
                      hintText: 'Email Address',
                      prefixIcon: Icon(Icons.mail_outline, color: Colors.grey[500]),
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Please enter your email';
                      if (!v.contains('@')) return 'Please enter a valid email';
                      return null;
                    },
                  ),

                  const SizedBox(height: 16),

                  // Password field with visibility toggle
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => _signIn(),
                    decoration: InputDecoration(
                      hintText: 'Password',
                      prefixIcon: Icon(Icons.lock_outline, color: Colors.grey[500]),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                          color: Colors.grey[500],
                        ),
                        onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                      ),
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Please enter your password';
                      if (v.length < 6) return 'Password must be at least 6 characters';
                      return null;
                    },
                  ),

                  const SizedBox(height: 24),

                  // Sign In button
                  SizedBox(
                    height: 52,
                    child: ElevatedButton(
                      onPressed: authState.isLoading ? null : _signIn,
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                      ),
                      child: authState.isLoading
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'Sign In',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                            ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Quick Login section
                  const Text(
                    'Quick Login (for testing)',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      color: Color(0xFF9E9E9E),
                      fontStyle: FontStyle.italic,
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Customer / Hero quick fill buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _QuickLoginButton(
                        label: 'Customer',
                        icon: Icons.person,
                        onTap: authState.isLoading ? null : () => _quickFill('customer'),
                      ),
                      const SizedBox(width: 16),
                      _QuickLoginButton(
                        label: 'Hero',
                        icon: Icons.verified_user,
                        onTap: authState.isLoading ? null : () => _quickFill('hero'),
                      ),
                    ],
                  ),

                  const SizedBox(height: 32),

                  // Bottom text
                  const Text(
                    "Need help on the road? We've got you covered.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      color: Color(0xFF9E9E9E),
                    ),
                  ),

                  const SizedBox(height: 48),
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
            style: TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
            ),
            children: [
              TextSpan(text: 'onth', style: TextStyle(color: Color(0xFF1A1A1A))),
              TextSpan(text: 'e', style: TextStyle(color: Color(0xFF4CAF50))),
              TextSpan(text: 'way', style: TextStyle(color: Color(0xFF1A1A1A))),
            ],
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'On Demand Roadside Assistance',
          style: TextStyle(
            fontSize: 13,
            color: Color(0xFF1A1A1A),
            fontWeight: FontWeight.w500,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }
}

class _QuickLoginButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback? onTap;

  const _QuickLoginButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minWidth: 140),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFE8F5E9),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: AppTheme.brandGreen),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppTheme.brandGreen,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
