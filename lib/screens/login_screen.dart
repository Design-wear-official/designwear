import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../styles/app_colors.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _loginWithEmail() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      setState(() => _error = 'Please enter email and password');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      await context.read<AuthService>().signInWithEmail(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );
      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loginAsGuest() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      await context.read<AuthService>().loginAsGuest();
      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loginWithGoogle() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      await context.read<AuthService>().signInWithGoogle();
      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Welcome Back',
                style: GoogleFonts.poppins(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Sign in to continue to Design Wear',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: AppColors.gray600,
                ),
              ),
              const SizedBox(height: 40),

              _buildTextField(
                controller: _emailController,
                label: 'Email Address',
                hint: 'Enter your email',
                icon: Icons.email,
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _passwordController,
                label: 'Password',
                hint: 'Enter your password',
                icon: Icons.lock,
                obscureText: true,
              ),

              if (_error != null) ...[
                const SizedBox(height: 16),
                _buildErrorBox(),
              ],

              const SizedBox(height: 32),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _loginWithEmail,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.purple,
                    foregroundColor: AppColors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation(AppColors.white),
                          ),
                        )
                      : Text(
                          'Sign In',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 16),

              Center(
                child: TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const RegisterScreen(),
                      ),
                    );
                  },
                  child: Text(
                    "Don't have an account? Sign Up",
                    style: GoogleFonts.poppins(
                      color: AppColors.purple,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: _isLoading ? null : _loginAsGuest,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: BorderSide(color: AppColors.gray300),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Continue as Guest',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _isLoading ? null : _loginWithGoogle,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: BorderSide(color: AppColors.gray300),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(
                    Icons.g_mobiledata_rounded,
                    size: 28,
                    color: Color(0xFF4285F4),
                  ),
                  label: Text(
                    'Sign in with Google',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    bool obscureText = false,
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 14),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, color: AppColors.gray500),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.gray300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.gray300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.purple, width: 2),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildErrorBox() {
    // Shorten overly long technical messages for cleaner display
    String msg = _error!;
    if (msg.startsWith('Exception: ')) msg = msg.substring(11);
    if (msg.length > 120) msg = '${msg.substring(0, 117)}...';

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.errorLight,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: AppColors.errorDark),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              msg,
              style: GoogleFonts.poppins(
                color: AppColors.errorDark,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
