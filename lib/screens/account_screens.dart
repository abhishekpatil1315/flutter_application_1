import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../theme/app_theme.dart';
import '../theme/app_assets.dart';
import '../widgets/quest_button.dart';
import '../widgets/scenic_background.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Stack(
      fit: StackFit.expand,
      children: [
        Semantics(
          excludeSemantics: true,
          child: Image.asset(
            AppAssets.welcomeBackground,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) =>
                const ColoredBox(color: AppColors.offWhite),
          ),
        ),
        ColoredBox(color: Colors.white.withValues(alpha: 0.48)),
        SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) => SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Semantics(
                        label: 'MathQuest animal team',
                        child: Image.asset(
                          AppAssets.welcomeCharacters,
                          height: 190,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) =>
                              const Icon(
                                Icons.auto_awesome_rounded,
                                size: 88,
                                color: AppColors.gold,
                              ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'MathQuest',
                        style: Theme.of(context).textTheme.headlineLarge
                            ?.copyWith(fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Welcome to MathQuest!\nPlay, explore and grow your math skills.',
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 32),
                      QuestButton(
                        label: 'Get started',
                        onPressed: () => context.go('/access'),
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton(
                        onPressed: () => context.go('/access?mode=signin'),
                        child: const Text('Already have an account? Sign In'),
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
  );
}

class AccessScreen extends StatefulWidget {
  const AccessScreen({this.startInSignIn = false, super.key});

  final bool startInSignIn;

  @override
  State<AccessScreen> createState() => _AccessScreenState();
}

class _AccessScreenState extends State<AccessScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  late bool _isSignIn = widget.startInSignIn;
  bool _passwordVisible = false;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(_isSignIn ? 'Sign In' : 'Create Account')),
    body: ScenicBackground(
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(
            _isSignIn ? 'Welcome back!' : 'Create your parent account',
            style: Theme.of(context).textTheme.headlineSmall
                ?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _email,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              labelText: 'Parent email',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _password,
            obscureText: !_passwordVisible,
            decoration: InputDecoration(
              labelText: 'Password',
              border: const OutlineInputBorder(),
              suffixIcon: IconButton(
                tooltip: _passwordVisible ? 'Hide password' : 'Show password',
                onPressed: () =>
                    setState(() => _passwordVisible = !_passwordVisible),
                icon: Icon(
                  _passwordVisible ? Icons.visibility_off : Icons.visibility,
                ),
              ),
            ),
          ),
          if (_isSignIn)
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Password reset will be available when parent accounts are connected.',
                    ),
                  ),
                ),
                child: const Text('Forgot Password?'),
              ),
            ),
          const SizedBox(height: 20),
          QuestButton(
            label: _isSignIn ? 'Sign In' : 'Create Account',
            onPressed: () {
              if (_email.text.trim().isEmpty ||
                  !_email.text.contains('@') ||
                  _password.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Enter a valid email and password to continue.',
                    ),
                  ),
                );
                return;
              }
              if (_isSignIn) {
                context.go('/profiles');
              } else {
                context.go('/verify', extra: _email.text.trim());
              }
            },
          ),
          const SizedBox(height: 12),
          const Center(child: Text('OR')),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () => _showUnavailableProvider(context, 'Google'),
            icon: const Icon(Icons.g_mobiledata_rounded),
            label: const Text('Continue with Google'),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () => _showUnavailableProvider(context, 'Apple'),
            icon: const Icon(Icons.apple),
            label: const Text('Continue with Apple'),
          ),
          const SizedBox(height: 12),
          const Text(
            'Account and email verification are demo flows. Secure sign-in will be connected to the future backend.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => setState(() => _isSignIn = !_isSignIn),
            child: Text(
              _isSignIn
                  ? 'New to MathQuest? Create Account'
                  : 'Already registered? Sign In',
            ),
          ),
        ],
      ),
    ),
  );
}

class VerifyEmailScreen extends StatefulWidget {
  const VerifyEmailScreen({this.email, super.key});

  final String? email;

  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen> {
  final _digits = List.generate(6, (_) => TextEditingController());
  final _focusNodes = List.generate(6, (_) => FocusNode());

  @override
  void dispose() {
    for (final controller in _digits) {
      controller.dispose();
    }
    for (final focusNode in _focusNodes) {
      focusNode.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Verify email')),
    body: ScenicBackground(
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight:
                  MediaQuery.sizeOf(context).height -
                  kToolbarHeight -
                  MediaQuery.paddingOf(context).vertical,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.mark_email_read_outlined,
                  size: 72,
                  color: AppColors.skyBlue,
                ),
                const SizedBox(height: 16),
                Text(
                  'Check your inbox',
                  style: Theme.of(context).textTheme.headlineSmall
                      ?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 8),
                Text(
                  "We've sent a link or code to ${widget.email ?? 'parent@email.com'}",
                ),
                const SizedBox(height: 16),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      for (var index = 0; index < _digits.length; index++) ...[
                        if (index > 0) const SizedBox(width: 8),
                        SizedBox(
                          width: 48,
                          height: 56,
                          child: TextField(
                            controller: _digits[index],
                            focusNode: _focusNodes[index],
                            textAlign: TextAlign.center,
                            keyboardType: TextInputType.number,
                            maxLength: 1,
                            decoration: const InputDecoration(
                              counterText: '',
                              border: OutlineInputBorder(),
                            ),
                            onChanged: (value) {
                              if (value.isNotEmpty &&
                                  index < _focusNodes.length - 1) {
                                _focusNodes[index + 1].requestFocus();
                              }
                            },
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                QuestButton(
                  label: 'Verify',
                  onPressed: () {
                    if (_digits.any(
                      (controller) =>
                          !RegExp(r'^\d$').hasMatch(controller.text),
                    )) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Enter all six digits to continue.'),
                        ),
                      );
                      return;
                    }
                    context.go('/profile-setup');
                  },
                ),
                TextButton(
                  onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'A new verification code will be available when email delivery is connected.',
                      ),
                    ),
                  ),
                  child: const Text("Didn't receive it? Resend"),
                ),
                const Text(
                  'Verification is a demo flow; no email or code is sent.',
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

void _showUnavailableProvider(BuildContext context, String provider) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
        '$provider sign-in will be available when parent accounts are connected.',
      ),
    ),
  );
}
