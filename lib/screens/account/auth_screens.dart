import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../presentation/styles/styles.dart' show AppColors;
import '../../presentation/widgets/designwear_logo.dart';
import '../../services/auth/auth_service.dart';
import '../../theme/app_theme.dart' show AppThemeColors;

class _AuthScaffold extends StatelessWidget {
  const _AuthScaffold({required this.title, required this.children});
  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(),
    body: Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Align(
                alignment: Alignment.centerLeft,
                child: DesignWearLogo(size: 64),
              ),
              const SizedBox(height: 20),
              Text(title, style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 24),
              ...children,
            ],
          ),
        ),
      ),
    ),
  );
}

/// "Continue with Google", shown only when Google sign-in is set up (API on and
/// a Firebase project configured for this platform).
class _GoogleButton extends StatefulWidget {
  const _GoogleButton();
  @override
  State<_GoogleButton> createState() => _GoogleButtonState();
}

class _GoogleButtonState extends State<_GoogleButton> {
  bool _busy = false;
  String? _error;

  Future<void> _go() async {
    final auth = context.read<AuthService>();
    final navigator = Navigator.of(context);
    setState(() {
      _busy = true;
      _error = null;
    });
    final error = await auth.signInWithGoogle();
    if (!mounted) return;
    if (error == null && auth.isSignedIn) {
      navigator.pop(true);
      return;
    }
    setState(() {
      _busy = false;
      _error = error; // null when the person simply closed the Google window
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!context.read<AuthService>().googleAvailable) {
      return const SizedBox.shrink();
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 16),
        Row(
          children: [
            const Expanded(child: Divider()),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text('or', style: TextStyle(color: context.muted)),
            ),
            const Expanded(child: Divider()),
          ],
        ),
        const SizedBox(height: 16),
        OutlinedButton.icon(
          onPressed: _busy ? null : _go,
          icon: Container(
            width: 22,
            height: 22,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: AppColors.marigold,
              shape: BoxShape.circle,
            ),
            child: const Text(
              'G',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 13,
                color: AppColors.marigoldInk,
              ),
            ),
          ),
          label: Text(_busy ? 'Opening Google…' : 'Continue with Google'),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 14),
            side: const BorderSide(color: AppColors.marigold, width: 1.5),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              _error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
      ],
    );
  }
}

InputDecoration _dec(String label) => InputDecoration(
  labelText: label,
  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
);

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  String? _error;
  bool _busy = false;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    final error = await context.read<AuthService>().signIn(
      _email.text,
      _password.text,
    );
    if (!mounted) return;
    if (error == null) {
      Navigator.of(context).pop(true);
    } else {
      setState(() {
        _busy = false;
        _error = error;
      });
    }
  }

  @override
  Widget build(BuildContext context) => _AuthScaffold(
    title: 'Sign in',
    children: [
      TextField(
        controller: _email,
        keyboardType: TextInputType.emailAddress,
        autofillHints: const [AutofillHints.email],
        decoration: _dec('Email'),
      ),
      const SizedBox(height: 16),
      TextField(
        controller: _password,
        obscureText: true,
        onSubmitted: (_) => _submit(),
        decoration: _dec('Password'),
      ),
      if (_error != null)
        Padding(
          padding: const EdgeInsets.only(top: 12),
          child: Text(
            _error!,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ),
      const SizedBox(height: 24),
      FilledButton(
        onPressed: _busy ? null : _submit,
        child: const Text('Sign in'),
      ),
      const _GoogleButton(),
      TextButton(
        onPressed: () => Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const ForgotPasswordScreen())),
        child: const Text('Forgot password?'),
      ),
      TextButton(
        onPressed: () => Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const RegisterScreen()),
        ),
        child: const Text('Create an account'),
      ),
    ],
  );
}

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  String? _error;
  bool _busy = false;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    final error = await context.read<AuthService>().register(
      _name.text,
      _email.text,
      _password.text,
    );
    if (!mounted) return;
    if (error == null) {
      Navigator.of(context).pop(true);
    } else {
      setState(() {
        _busy = false;
        _error = error;
      });
    }
  }

  @override
  Widget build(BuildContext context) => _AuthScaffold(
    title: 'Create account',
    children: [
      TextField(controller: _name, decoration: _dec('Full name')),
      const SizedBox(height: 16),
      TextField(
        controller: _email,
        keyboardType: TextInputType.emailAddress,
        decoration: _dec('Email'),
      ),
      const SizedBox(height: 16),
      TextField(
        controller: _password,
        obscureText: true,
        decoration: _dec('Password (8+ characters)'),
      ),
      if (_error != null)
        Padding(
          padding: const EdgeInsets.only(top: 12),
          child: Text(
            _error!,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ),
      const SizedBox(height: 24),
      FilledButton(
        onPressed: _busy ? null : _submit,
        child: const Text('Create account'),
      ),
      const _GoogleButton(),
      const SizedBox(height: 12),
      if (!context.read<AuthService>().isRemote)
        const Text(
          'Accounts are stored on this device only.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 12),
        ),
    ],
  );
}

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});
  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _email = TextEditingController();
  final _code = TextEditingController();
  final _password = TextEditingController();
  String? _error;
  bool _codeSent = false;
  bool _done = false;

  @override
  void dispose() {
    _email.dispose();
    _code.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final auth = context.read<AuthService>();
    String? error;
    if (!auth.isRemote) {
      error = await auth.resetPassword(_email.text, _password.text);
      _done = error == null;
    } else if (!_codeSent) {
      error = await auth.requestPasswordReset(_email.text);
      _codeSent = error == null;
    } else {
      error = await auth.confirmPasswordReset(
        _email.text,
        _code.text.trim(),
        _password.text,
      );
      _done = error == null;
    }
    if (mounted) setState(() => _error = error);
  }

  @override
  Widget build(BuildContext context) {
    final remote = context.read<AuthService>().isRemote;
    return _AuthScaffold(
      title: 'Reset password',
      children: _done
          ? [
              const Text('Password updated. You can sign in with it now.'),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Back to sign in'),
              ),
            ]
          : [
              Text(
                remote
                    ? (_codeSent
                          ? 'If that email has an account, we sent a 6-digit code. Enter it with a new password.'
                          : "Enter your email and we'll send you a code.")
                    : 'Email codes need the server, which is not connected. '
                          'You can set a new password for an account on this device.',
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _email,
                enabled: !_codeSent,
                keyboardType: TextInputType.emailAddress,
                decoration: _dec('Email'),
              ),
              if (!remote || _codeSent) ...[
                if (remote) ...[
                  const SizedBox(height: 16),
                  TextField(
                    controller: _code,
                    keyboardType: TextInputType.number,
                    decoration: _dec('6-digit code'),
                  ),
                ],
                const SizedBox(height: 16),
                TextField(
                  controller: _password,
                  obscureText: true,
                  decoration: _dec('New password (8+ characters)'),
                ),
              ],
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(
                    _error!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _submit,
                child: Text(
                  remote && !_codeSent ? 'Send code' : 'Set new password',
                ),
              ),
            ],
    );
  }
}

/// Pushes the login screen and returns whether the user is now signed in.
Future<bool> requireSignIn(BuildContext context) async {
  final auth = context.read<AuthService>();
  if (auth.isSignedIn) return true;
  await Navigator.of(context)
      .push<bool>(MaterialPageRoute(builder: (_) => const LoginScreen()));
  return auth.isSignedIn;
}
