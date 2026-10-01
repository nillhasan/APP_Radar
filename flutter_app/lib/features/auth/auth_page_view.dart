import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/theme_service.dart';
import '../../services/auth/auth_service.dart';

/// Full-screen MobileAction-style Split Auth Page.
///
/// Left Side:
///  - Brand header with partner badge
///  - "Let's get started" / "Welcome back"
///  - "Fuel Your App Market Discovery with AppRadar" pill
///  - "Continue with Google"
///  - Email & Password fields with visibility toggle
///  - "Create a free account" / "Log in to AppRadar"
///  - Terms & Privacy notice
///  - Toggle between Sign up and Log in
///  - 1-Click Guest Access bypass
///
/// Right Side:
///  - Deep midnight navy container with curved left border
///  - Subtle geometric dashed pattern at top right
///  - Big cyan quote icon `66`
///  - High-impact testimonial from Zehra Türksoy (SEO & ASO Team Lead, SEM)
///  - "Trusted by" partner logos: Meta, Starbucks, Square, Tango, Grammarly
class AuthPageView extends StatefulWidget {
  final AuthService authService;
  final VoidCallback onAuthSuccess;
  final VoidCallback onBackToFrontPage;
  final bool initialIsSignUp;

  const AuthPageView({
    super.key,
    required this.authService,
    required this.onAuthSuccess,
    required this.onBackToFrontPage,
    this.initialIsSignUp = true,
  });

  @override
  State<AuthPageView> createState() => _AuthPageViewState();
}

class _AuthPageViewState extends State<AuthPageView> {
  late bool _isSignUp;
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _otpController = TextEditingController();

  bool _obscurePassword = true;
  bool _isLoading = false;
  bool _isGoogleLoading = false;
  bool _showOtpInput = false;
  String? _errorMessage;
  String? _successMessage;

  @override
  void initState() {
    super.initState();
    _isSignUp = widget.initialIsSignUp;
    if (widget.authService.isAuthenticated) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) widget.onAuthSuccess();
      });
    }
  }

  @override
  void didUpdateWidget(covariant AuthPageView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.authService.isAuthenticated) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) widget.onAuthSuccess();
      });
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  String _parseAuthError(dynamic error) {
    if (error is AuthException) {
      final msg = error.message.toLowerCase();
      if (msg.contains('email not confirmed') || (error.statusCode == '400' && msg.contains('confirmed'))) {
        return 'Email not confirmed yet. Please verify your email via the link or enter the 6-digit code below.';
      }
      if (msg.contains('rate limit') || error.statusCode == '429') {
        return 'Email rate limit reached (Supabase limit). Please wait a few minutes before trying again.';
      }
      if (msg.contains('invalid login credentials') || msg.contains('invalid_grant')) {
        return 'Invalid email or password. Please verify your credentials.';
      }
      if (msg.contains('user already registered') || msg.contains('already been registered')) {
        return 'An account with this email already exists. Please Log in.';
      }
      if (msg.contains('password should be at least')) {
        return 'Password must be at least 6 characters long.';
      }
      return error.message;
    }

    final raw = error.toString();
    final lower = raw.toLowerCase();
    if (lower.contains('email_not_confirmed') || lower.contains('email not confirmed')) {
      return 'Email not confirmed yet. Please verify your email via the link or enter the 6-digit code below.';
    }
    if (lower.contains('over_email_send_rate_limit') || lower.contains('rate limit')) {
      return 'Email rate limit reached (Supabase limit). Please wait a few minutes before trying again.';
    }
    if (lower.contains('invalid login credentials')) {
      return 'Invalid email or password. Please verify your credentials.';
    }
    if (lower.contains('user already registered')) {
      return 'An account with this email already exists. Please Log in.';
    }

    return raw
        .replaceAll(RegExp(r'^AuthApiException\([^)]*message:\s*'), '')
        .replaceAll(RegExp(r',\s*statusCode:.*$'), '')
        .replaceAll('AuthException: ', '')
        .replaceAll('Exception: ', '');
  }

  Future<void> _handlePrimarySubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });

    final email = _emailController.text.trim();
    final password = _passwordController.text;

    try {
      if (_isSignUp) {
        try {
          final res = await widget.authService.signUp(
            email: email,
            password: password,
          );
          if (res.session != null) {
            widget.onAuthSuccess();
            return;
          } else {
            setState(() {
              _showOtpInput = true;
              _successMessage = 'Confirmation email sent. Enter the 6-digit confirmation code below or click the link in your email to verify.';
            });
            return;
          }
        } catch (e) {
          if (widget.authService.isSupabaseConfigured) {
            rethrow;
          }
          // If Supabase is unconfigured or in offline/mock mode, sign in seamlessly
          widget.authService.signInDemoUser(email: email);
          widget.onAuthSuccess();
          return;
        }
      } else {
        // Sign In
        try {
          await widget.authService.signIn(
            email: email,
            password: password,
          );
          widget.onAuthSuccess();
          return;
        } catch (e) {
          if (widget.authService.isSupabaseConfigured) {
            rethrow;
          }
          // If mock/demo mode or credentials bypass
          widget.authService.signInDemoUser(email: email);
          widget.onAuthSuccess();
          return;
        }
      }
    } catch (e) {
      if (mounted) {
        final parsed = _parseAuthError(e);
        final isUnconfirmed = parsed.toLowerCase().contains('not confirmed') ||
            e.toString().toLowerCase().contains('email_not_confirmed');
        setState(() {
          _errorMessage = parsed;
          if (isUnconfirmed) {
            _showOtpInput = true;
          }
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleVerifyOtp() async {
    final email = _emailController.text.trim();
    final token = _otpController.text.trim();
    if (email.isEmpty) {
      setState(() => _errorMessage = 'Please enter your email address.');
      return;
    }
    if (token.isEmpty || token.length < 6) {
      setState(() => _errorMessage = 'Please enter the 6-digit confirmation code from your email.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      final res = await widget.authService.verifyOTP(
        email: email,
        token: token,
      );
      if (mounted) {
        if (res.session != null) {
          widget.onAuthSuccess();
        } else {
          setState(() {
            _successMessage = 'Email verified successfully! Please log in with your password.';
            _showOtpInput = false;
            _isSignUp = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _errorMessage = _parseAuthError(e));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleResendEmail() async {
    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      setState(() => _errorMessage = 'Please enter a valid email address first.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      await widget.authService.resendVerificationEmail(email: email);
      if (mounted) {
        setState(() {
          _successMessage = 'Confirmation email resent! Please check your inbox (and spam folder).';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _errorMessage = _parseAuthError(e));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() {
      _isGoogleLoading = true;
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      if (kIsWeb && widget.authService.isSupabaseConfigured) {
        // On web, signInWithOAuth initiates browser redirect to Google's OAuth portal.
        // We MUST NOT call onAuthSuccess() here, because user authentication hasn't happened yet!
        // Calling onAuthSuccess() prematurely rendered the Console for 3-5s before navigating to Google.
        await widget.authService.signInWithGoogle();
        return;
      }

      final success = await widget.authService.signInWithGoogle();
      if (success) {
        widget.onAuthSuccess();
      } else {
        // Offline / Web mock fallback
        widget.authService.signInDemoUser(
          email: 'founder@google.com',
          fullName: 'Google User',
        );
        widget.onAuthSuccess();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isGoogleLoading = false;
          _isLoading = false;
          _errorMessage = _parseAuthError(e);
        });
      }
    } finally {
      if (mounted && (!kIsWeb || !widget.authService.isSupabaseConfigured)) {
        setState(() {
          _isGoogleLoading = false;
          _isLoading = false;
        });
      }
    }
  }

  void _handleGuestBypass() {
    widget.authService.signInDemoUser(
      email: 'demo@appradar.ai',
      fullName: 'Founder Workspace',
    );
    widget.onAuthSuccess();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeService.instance.isDark;
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 1000;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0B0F19) : Colors.white,
      body: SafeArea(
        child: isDesktop
            ? Row(
                children: [
                  // Left: Form Area (52% width)
                  Expanded(
                    flex: 52,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 32),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildTopBrandHeader(isDark),
                          const SizedBox(height: 32),
                          Center(
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 440),
                              child: _buildFormCard(isDark),
                            ),
                          ),
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ),

                  // Right: Testimonial & Social Proof Container (48% width)
                  Expanded(
                    flex: 48,
                    child: _buildRightShowcasePanel(),
                  ),
                ],
              )
            : SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildTopBrandHeader(isDark),
                    const SizedBox(height: 28),
                    Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 460),
                        child: _buildFormCard(isDark),
                      ),
                    ),
                    const SizedBox(height: 36),
                    _buildMobileTestimonialCard(),
                  ],
                ),
              ),
      ),
    );
  }

  // ----------------------------------------------------
  // Top Brand Header with Partner Badge & Back Button
  // ----------------------------------------------------
  Widget _buildTopBrandHeader(bool isDark) {
    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 8,
      runSpacing: 8,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: const Color(0xFF2563EB),
                borderRadius: BorderRadius.circular(9),
              ),
              child: const Icon(Icons.radar, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 8),
            Text(
              'AppRadar',
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(width: 10),
            Container(
              height: 16,
              width: 1.2,
              color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
            ),
            const SizedBox(width: 10),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.apple,
                  size: 15,
                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                ),
                const SizedBox(width: 4),
                Text(
                  'Telemetry Partner',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                    letterSpacing: -0.2,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ],
        ),

        // Back to Front Page link
        TextButton.icon(
          onPressed: widget.onBackToFrontPage,
          icon: const Icon(Icons.arrow_back_rounded, size: 15),
          label: const Text('Front Page', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
          style: TextButton.styleFrom(
            foregroundColor: const Color(0xFF2563EB),
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          ),
        ),
      ],
    );
  }

  // ----------------------------------------------------
  // Center Form Card (MobileAction Style)
  // ----------------------------------------------------
  Widget _buildFormCard(bool isDark) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Title
          Center(
            child: Text(
              _isSignUp ? "Let's get started" : "Welcome back",
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.6,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Green Pill Badge (matches "Fuel Your UA Strategy With MobileAction")
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF064E3B).withValues(alpha: 0.6) : const Color(0xFFDCFCE7),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isDark ? const Color(0xFF059669).withValues(alpha: 0.5) : const Color(0xFF86EFAC),
                ),
              ),
              child: Text(
                _isSignUp
                    ? 'Fuel Your App Market Discovery with AppRadar'
                    : 'Access Your Live Telemetry & Growth Blueprints',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: isDark ? const Color(0xFF6EE7B7) : const Color(0xFF15803D),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Google OAuth Button
          _buildGoogleSignInButton(isDark),
          const SizedBox(height: 18),

          // "or sign up with" Divider
          Row(
            children: [
              Expanded(child: Divider(color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0))),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Text(
                  _isSignUp ? 'or sign up with' : 'or log in with',
                  style: TextStyle(
                    fontSize: 11.5,
                    color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Expanded(child: Divider(color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0))),
            ],
          ),
          const SizedBox(height: 18),

          // Error Message banner
          if (_errorMessage != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.dangerLight,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.danger.withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.error_outline, size: 16, color: AppColors.danger),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(fontSize: 12, color: AppColors.danger, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: () {
                      final email = _emailController.text.trim();
                      widget.authService.signInDemoUser(email: email.isNotEmpty ? email : 'developer@appradar.ai');
                      widget.onAuthSuccess();
                    },
                    child: const Text(
                      'Bypass and enter Console in Demo Mode →',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.danger,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
          ],

          // Success Message banner
          if (_successMessage != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.successLight,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle_outline, size: 16, color: AppColors.success),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _successMessage!,
                      style: const TextStyle(fontSize: 12, color: AppColors.success, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
          ],

          // Email Field
          Text(
            'Email',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: isDark ? const Color(0xFFE2E8F0) : const Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 6),
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            style: TextStyle(fontSize: 14, color: isDark ? Colors.white : const Color(0xFF0F172A)),
            decoration: InputDecoration(
              hintText: 'Enter your email address',
              hintStyle: TextStyle(fontSize: 13.5, color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
              filled: true,
              fillColor: isDark ? const Color(0xFF111827) : const Color(0xFFF8FAFC),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1.5),
              ),
            ),
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Please enter your email';
              if (!v.contains('@')) return 'Please enter a valid email address';
              return null;
            },
          ),
          const SizedBox(height: 16),

          // Password Field
          Text(
            'Password',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: isDark ? const Color(0xFFE2E8F0) : const Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 6),
          TextFormField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            style: TextStyle(fontSize: 14, color: isDark ? Colors.white : const Color(0xFF0F172A)),
            decoration: InputDecoration(
              hintText: _isSignUp ? 'Set a strong password' : 'Enter your password',
              hintStyle: TextStyle(fontSize: 13.5, color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
              filled: true,
              fillColor: isDark ? const Color(0xFF111827) : const Color(0xFFF8FAFC),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                  size: 19,
                  color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                ),
                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1.5),
              ),
            ),
            validator: (v) {
              if (v == null || v.length < 6) return 'Password must be at least 6 characters';
              return null;
            },
          ),

          // Optional OTP input if verification required
          if (_showOtpInput) ...[
            const SizedBox(height: 16),
            Text(
              'Confirmation Code (OTP)',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: isDark ? const Color(0xFFE2E8F0) : const Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 6),
            TextFormField(
              controller: _otpController,
              keyboardType: TextInputType.number,
              style: TextStyle(fontSize: 14, color: isDark ? Colors.white : const Color(0xFF0F172A)),
              decoration: InputDecoration(
                hintText: 'Enter 6-digit confirmation code',
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                filled: true,
                fillColor: isDark ? const Color(0xFF111827) : const Color(0xFFF8FAFC),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1)),
                ),
              ),
            ),
            const SizedBox(height: 14),
            SizedBox(
              height: 48,
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _handleVerifyOtp,
                icon: const Icon(Icons.check_circle_outline, size: 18),
                label: const Text('Verify Code & Continue', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14.5)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: _isLoading ? null : _handleResendEmail,
                  child: const Text('Resend code', style: TextStyle(fontSize: 12, color: Color(0xFF2563EB), fontWeight: FontWeight.w600)),
                ),
                TextButton(
                  onPressed: () => setState(() => _showOtpInput = false),
                  child: Text('Cancel', style: TextStyle(fontSize: 12, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B))),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Center(
              child: TextButton.icon(
                onPressed: () {
                  final email = _emailController.text.trim();
                  widget.authService.signInDemoUser(email: email.isNotEmpty ? email : 'developer@appradar.ai');
                  widget.onAuthSuccess();
                },
                icon: const Icon(Icons.flash_on_rounded, size: 15, color: Color(0xFF10B981)),
                label: const Text(
                  'Skip code verification & enter Console directly →',
                  style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: Color(0xFF10B981)),
                ),
              ),
            ),
          ] else ...[
            const SizedBox(height: 22),

            // Primary Submit Button ("Create a free account" / "Log in to AppRadar")
            SizedBox(
              height: 48,
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _handlePrimarySubmit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: isDark ? const Color(0xFF2563EB) : const Color(0xFF0F172A),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  elevation: 1,
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : Text(
                        _isSignUp ? 'Create a free account' : 'Log in to AppRadar',
                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14.5),
                      ),
              ),
            ),
          ],
          const SizedBox(height: 14),

          // Terms notice (matches screenshot)
          Center(
            child: Text(
              _isSignUp
                  ? 'By clicking sign up button, you agree to the Terms of Services and Privacy Policy'
                  : 'Protected by enterprise-grade SSL and end-to-end data telemetry encryption.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11.5,
                color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                height: 1.4,
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Toggle between Sign up and Log in
          Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                _isSignUp ? 'Already have an account? ' : "Don't have an account? ",
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                ),
              ),
              InkWell(
                onTap: () {
                  setState(() {
                    _isSignUp = !_isSignUp;
                    _errorMessage = null;
                    _successMessage = null;
                  });
                },
                child: Text(
                  _isSignUp ? 'Log in' : 'Sign up',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF2563EB),
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // 1-Click Guest Bypass for fast exploration
          Center(
            child: TextButton.icon(
              onPressed: _handleGuestBypass,
              icon: const Icon(Icons.flash_on_rounded, size: 15, color: Color(0xFFF59E0B)),
              label: const Text(
                'Explore Console as Guest (Instant 1-Click Demo) →',
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF2563EB),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ----------------------------------------------------
  // Authentic "Continue with Google" Button
  // ----------------------------------------------------
  Widget _buildGoogleSignInButton(bool isDark) {
    return SizedBox(
      height: 46,
      child: OutlinedButton(
        onPressed: _isLoading ? null : _handleGoogleSignIn,
        style: OutlinedButton.styleFrom(
          side: BorderSide(
            color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
            width: 1.2,
          ),
          backgroundColor: isDark ? const Color(0xFF111827) : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          elevation: 0,
        ),
        child: _isGoogleLoading
            ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF2563EB)),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Redirecting to Google...',
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                ],
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Google G Brand Icon
                  _buildGoogleGLogo(),
                  const SizedBox(width: 10),
                  Text(
                    'Continue with Google',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildGoogleGLogo() {
    return SizedBox(
      width: 18,
      height: 18,
      child: CustomPaint(
        painter: _GoogleLogoPainter(),
      ),
    );
  }

  // ----------------------------------------------------
  // Right Showcase Panel (MobileAction Style Navy Slate)
  // ----------------------------------------------------
  Widget _buildRightShowcasePanel() {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF0B132B), // Deep midnight navy slate
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(36),
          bottomLeft: Radius.circular(36),
        ),
      ),
      child: Stack(
        children: [
          // Top right subtle geometric dashes decoration
          Positioned(
            top: 20,
            right: 20,
            width: 140,
            height: 140,
            child: CustomPaint(
              painter: _GeometricDashesPainter(),
            ),
          ),

          // Main Testimonial & Social Proof Content
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 52, vertical: 48),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Spacer(flex: 2),

                // Large Cyan Quote Symbol (66 / “)
                Text(
                  '“',
                  style: TextStyle(
                    fontSize: 72,
                    fontWeight: FontWeight.w900,
                    color: const Color(0xFF38BDF8).withValues(alpha: 0.9),
                    height: 0.8,
                  ),
                ),
                const SizedBox(height: 16),

                // Testimonial Quote Body (from screenshot)
                const Text(
                  'Thanks to the constantly incoming new features, it has become easier for us to strengthen our strategies, and we are very pleased with the support we have received. 84% improvement in our session numbers and 78% increase in install rates display the value of this partnership.',
                  style: TextStyle(
                    fontSize: 16,
                    height: 1.6,
                    color: Color(0xFFF1F5F9),
                    fontWeight: FontWeight.w400,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 28),

                // Person Profile Row
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFF38BDF8), width: 1.5),
                        color: const Color(0xFF1E293B),
                      ),
                      child: const Center(
                        child: Text(
                          'ZT',
                          style: TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF38BDF8), fontSize: 14),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Zehra Türksoy',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'SEO & ASO Team Lead',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF94A3B8),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Company Wordmark (SEM - exactly like screenshot)
                const Text(
                  'SEM',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2.0,
                    color: Colors.white,
                  ),
                ),

                const Spacer(flex: 3),

                // "Trusted by" Section at bottom
                const Text(
                  'Trusted by',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 14),

                // Logos Row: Meta, Starbucks, Square, Tango, Grammarly
                Wrap(
                  spacing: 24,
                  runSpacing: 12,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    _buildPartnerBrand('∞ Meta'),
                    _buildPartnerBrand('★ Starbucks'),
                    _buildPartnerBrand('⊡ Square'),
                    _buildPartnerBrand('Tango'),
                    _buildPartnerBrand('G grammarly'),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPartnerBrand(String name) {
    return Text(
      name,
      style: const TextStyle(
        color: Color(0xFF94A3B8),
        fontSize: 13,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.2,
      ),
    );
  }

  // Mobile fallback for testimonial card
  Widget _buildMobileTestimonialCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Color(0xFF0B132B),
        borderRadius: BorderRadius.all(Radius.circular(20)),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '“',
            style: TextStyle(fontSize: 48, color: Color(0xFF38BDF8), height: 0.8, fontWeight: FontWeight.w900),
          ),
          SizedBox(height: 8),
          Text(
            'Thanks to the constantly incoming new features, it has become easier for us to strengthen our strategies. 84% improvement in our session numbers and 78% increase in install rates display the value of this partnership.',
            style: TextStyle(fontSize: 13.5, height: 1.5, color: Color(0xFFF1F5F9)),
          ),
          SizedBox(height: 16),
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: Color(0xFF1E293B),
                child: Text('ZT', style: TextStyle(color: Color(0xFF38BDF8), fontSize: 11, fontWeight: FontWeight.w800)),
              ),
              SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Zehra Türksoy', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13)),
                  Text('SEO & ASO Team Lead • SEM', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11)),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ----------------------------------------------------
// Custom Painters for Google G and Geometric Dashes
// ----------------------------------------------------
class _GoogleLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final radius = size.width / 2;

    final paintBlue = Paint()
      ..color = const Color(0xFF4285F4)
      ..style = PaintingStyle.fill;
    final paintGreen = Paint()
      ..color = const Color(0xFF34A853)
      ..style = PaintingStyle.fill;
    final paintYellow = Paint()
      ..color = const Color(0xFFFBBC05)
      ..style = PaintingStyle.fill;
    final paintRed = Paint()
      ..color = const Color(0xFFEA4335)
      ..style = PaintingStyle.fill;

    final rect = Rect.fromCircle(center: Offset(cx, cy), radius: radius);

    // Blue section (Right bar & top right)
    canvas.drawArc(rect, -0.4, 1.2, true, paintBlue);
    // Green section (Bottom right to bottom)
    canvas.drawArc(rect, 0.8, 1.4, true, paintGreen);
    // Yellow section (Bottom left)
    canvas.drawArc(rect, 2.2, 1.2, true, paintYellow);
    // Red section (Top left)
    canvas.drawArc(rect, 3.4, 1.4, true, paintRed);

    // Center cutout
    final cutoutPaint = Paint()..color = const Color(0xFF0B132B).withValues(alpha: 0.0);
    canvas.drawCircle(Offset(cx, cy), radius * 0.55, cutoutPaint);

    // Blue horizontal bar
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(cx - 1, cy - 2.5, radius + 1, 5),
        const Radius.circular(1),
      ),
      paintBlue,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _GeometricDashesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF38BDF8).withValues(alpha: 0.22)
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round;

    const rows = 8;
    const cols = 8;
    final dx = size.width / cols;
    final dy = size.height / rows;

    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < cols; c++) {
        final x = c * dx + dx / 2;
        final y = r * dy + dy / 2;
        // Draw small dash tilted at ~-35 degrees
        const length = 6.0;
        const angle = -math.pi / 4;
        final cosA = math.cos(angle) * length;
        final sinA = math.sin(angle) * length;

        canvas.drawLine(
          Offset(x - cosA / 2, y - sinA / 2),
          Offset(x + cosA / 2, y + sinA / 2),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
