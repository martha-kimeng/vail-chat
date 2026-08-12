import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/auth_service.dart';
import '../../core/theme.dart';
import '../../core/widgets/vail_field.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _obscure = true;
  bool _loading = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _loading = true);
    try {
      await AuthService.instance.signIn(
        email: _emailCtrl.text,
        password: _passwordCtrl.text,
      );
      if (mounted) context.go('/home');
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        _showError(AuthService.messageFor(e));
      }
    } catch (_) {
      if (mounted) _showError('Something went wrong. Please try again.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _forgotPassword() async {
    final email = _emailCtrl.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      _showError('Enter your email above, then tap "Forgot password?".');
      return;
    }
    try {
      await AuthService.instance.sendPasswordReset(email: email);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Password reset email sent to $email.',
              style: GoogleFonts.inter(fontSize: 14),
            ),
            backgroundColor: const Color(0xFF2D2D2D),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) _showError(AuthService.messageFor(e));
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.inter(fontSize: 14)),
        backgroundColor: VailColors.rose,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          const VailGradientBackground(child: SizedBox.expand()),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  IconButton(
                    onPressed: () => context.go('/onboarding'),
                    icon: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: Colors.white70,
                      size: 20,
                    ),
                    padding: EdgeInsets.zero,
                  ),
                  const SizedBox(height: 32),

                  Text(
                    'Welcome\nback.',
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 38,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      height: 1.2,
                    ),
                  ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1),
                  const SizedBox(height: 10),
                  Text(
                    'Pick up where your conversations left off.',
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      color: Colors.white60,
                      height: 1.5,
                    ),
                  ).animate(delay: 100.ms).fadeIn(duration: 400.ms),

                  const SizedBox(height: 40),

                  Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                        ),
                        padding: const EdgeInsets.all(24),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            children: [
                              VailField(
                                controller: _emailCtrl,
                                label: 'EMAIL',
                                hint: 'your@email.com',
                                icon: Icons.mail_outline_rounded,
                                keyboardType: TextInputType.emailAddress,
                                validator: (v) =>
                                    (v == null || !v.contains('@'))
                                    ? 'Enter a valid email'
                                    : null,
                              ),
                              const SizedBox(height: 16),
                              VailField(
                                controller: _passwordCtrl,
                                label: 'PASSWORD',
                                hint: '••••••••',
                                icon: Icons.lock_outline_rounded,
                                obscure: _obscure,
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscure
                                        ? Icons.visibility_off_outlined
                                        : Icons.visibility_outlined,
                                    color: VailColors.inkLight,
                                    size: 20,
                                  ),
                                  onPressed: () =>
                                      setState(() => _obscure = !_obscure),
                                ),
                                validator: (v) => (v == null || v.isEmpty)
                                    ? 'Enter your password'
                                    : null,
                              ),
                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton(
                                  onPressed: _forgotPassword,
                                  child: Text(
                                    'Forgot password?',
                                    style: GoogleFonts.inter(
                                      fontSize: 13,
                                      color: VailColors.rose,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              ElevatedButton(
                                onPressed: _loading ? null : _submit,
                                child: _loading
                                    ? const SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : Text(
                                        'Sign In',
                                        style: VailTextStyles.button(context),
                                      ),
                              ),
                            ],
                          ),
                        ),
                      )
                      .animate(delay: 200.ms)
                      .fadeIn(duration: 400.ms)
                      .slideY(begin: 0.08),

                  const SizedBox(height: 24),

                  Center(
                    child: GestureDetector(
                      onTap: () => context.go('/sign-up'),
                      child: RichText(
                        text: TextSpan(
                          text: "Don't have an account? ",
                          style: GoogleFonts.inter(
                            color: Colors.white60,
                            fontSize: 14,
                          ),
                          children: [
                            TextSpan(
                              text: 'Sign up',
                              style: GoogleFonts.inter(
                                color: VailColors.rose,
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
