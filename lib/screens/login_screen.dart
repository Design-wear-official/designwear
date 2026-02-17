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

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _showOtpField = false;
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _phoneController.dispose();
    _otpController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _sendOtp() async {
    if (_phoneController.text.length != 10) {
      setState(() => _error = 'Please enter a valid 10-digit phone number');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      await context.read<AuthService>().sendOtp(_phoneController.text);

      if (mounted) {
        setState(() {
          _showOtpField = true;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('OTP sent to your phone!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted && !_showOtpField) {
        // Only stop loading if we didn't switch to OTP view (error case)
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _verifyOtp() async {
    if (_otpController.text.length != 6) {
      setState(() => _error = 'Please enter a valid 6-digit OTP');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      await context.read<AuthService>().loginWithPhone(_otpController.text);

      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      setState(() => _error = 'Invalid OTP. Please try again.');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
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
    await context.read<AuthService>().loginAsGuest();
    if (mounted) {
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.gold,
          labelColor: Colors.black,
          unselectedLabelColor: Colors.grey,
          labelStyle: GoogleFonts.outfit(fontWeight: FontWeight.bold),
          unselectedLabelStyle: GoogleFonts.outfit(),
          tabs: const [
            Tab(text: 'Phone'),
            Tab(text: 'Email'),
          ],
        ),
      ),
      body: SafeArea(
        child: TabBarView(
          controller: _tabController,
          children: [_buildPhoneLogin(), _buildEmailLogin()],
        ),
      ),
    );
  }

  Widget _buildPhoneLogin() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          Text(
            _showOtpField ? 'VERIFY OTP' : 'WELCOME BACK',
            style: GoogleFonts.outfit(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _showOtpField
                ? 'Enter the 6-digit code sent to +91 ${_phoneController.text}'
                : 'Sign in with your phone number to continue',
            style: GoogleFonts.outfit(fontSize: 14, color: Colors.grey[600]),
          ),
          const SizedBox(height: 40),
          if (!_showOtpField) ...[
            _buildLabel('PHONE NUMBER'),
            const SizedBox(height: 8),
            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              maxLength: 10,
              decoration: _buildInputDecoration(
                hint: 'Enter your phone number',
                prefix: '+91  ',
              ),
            ),
          ] else ...[
            _buildLabel('OTP CODE'),
            const SizedBox(height: 8),
            TextField(
              controller: _otpController,
              keyboardType: TextInputType.number,
              maxLength: 6,
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                fontSize: 24,
                letterSpacing: 16,
                fontWeight: FontWeight.w600,
              ),
              decoration: _buildInputDecoration(hint: '• • • • • •'),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => setState(() => _showOtpField = false),
              child: Text(
                'Change phone number',
                style: GoogleFonts.outfit(color: AppColors.gold),
              ),
            ),
          ],
          if (_error != null) _buildErrorBox(),
          const SizedBox(height: 32),
          _buildActionButton(
            onPressed: _isLoading
                ? null
                : (_showOtpField ? _verifyOtp : _sendOtp),
            text: _showOtpField ? 'VERIFY & LOGIN' : 'SEND OTP',
          ),
          const SizedBox(height: 24),
          _buildGuestButton(),
        ],
      ),
    );
  }

  Widget _buildEmailLogin() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          Text(
            'SIGN IN',
            style: GoogleFonts.outfit(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Use your email and password to login',
            style: GoogleFonts.outfit(fontSize: 14, color: Colors.grey[600]),
          ),
          const SizedBox(height: 40),
          _buildLabel('EMAIL ADDRESS'),
          const SizedBox(height: 8),
          TextField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: _buildInputDecoration(hint: 'Enter your email'),
          ),
          const SizedBox(height: 16),
          _buildLabel('PASSWORD'),
          const SizedBox(height: 8),
          TextField(
            controller: _passwordController,
            obscureText: true,
            decoration: _buildInputDecoration(hint: 'Enter your password'),
          ),
          if (_error != null) _buildErrorBox(),
          const SizedBox(height: 32),
          _buildActionButton(
            onPressed: _isLoading ? null : _loginWithEmail,
            text: 'LOGIN',
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
                style: GoogleFonts.outfit(color: AppColors.gold),
              ),
            ),
          ),
          const SizedBox(height: 16),
          _buildGuestButton(),
        ],
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: GoogleFonts.outfit(
        fontWeight: FontWeight.bold,
        fontSize: 12,
        letterSpacing: 0.5,
      ),
    );
  }

  InputDecoration _buildInputDecoration({
    required String hint,
    String? prefix,
  }) {
    return InputDecoration(
      hintText: hint,
      prefixText: prefix,
      prefixStyle: prefix != null
          ? GoogleFonts.outfit(
              color: Colors.black87,
              fontWeight: FontWeight.w600,
            )
          : null,
      counterText: '',
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(0),
        borderSide: BorderSide(color: Colors.grey[300]!),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(0),
        borderSide: BorderSide(color: Colors.grey[300]!),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(0),
        borderSide: const BorderSide(color: Colors.black, width: 1.5),
      ),
    );
  }

  Widget _buildErrorBox() {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red[50],
        borderRadius: BorderRadius.circular(0),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: Colors.red[700]),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _error!,
              style: GoogleFonts.outfit(color: Colors.red[700], fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required VoidCallback? onPressed,
    required String text,
  }) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(0)),
          elevation: 0,
        ),
        child: _isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation(Colors.white),
                ),
              )
            : Text(
                text,
                style: GoogleFonts.outfit(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  letterSpacing: 1,
                ),
              ),
      ),
    );
  }

  Widget _buildGuestButton() {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: _loginAsGuest,
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 18),
          side: BorderSide(color: Colors.grey[300]!),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(0)),
        ),
        child: Text(
          'CONTINUE AS GUEST',
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.bold,
            color: Colors.grey[700],
            fontSize: 14,
            letterSpacing: 1,
          ),
        ),
      ),
    );
  }
}
