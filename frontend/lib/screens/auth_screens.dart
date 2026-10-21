import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_providers.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();
    final ok = await auth.signIn(
      email: _emailCtrl.text,
      password: _passwordCtrl.text,
    );
    if (ok && mounted) {
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return Scaffold(
      appBar: AppBar(title: const Text('Sign In')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Welcome Back',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),
                  if (auth.error != null)
                    Container(
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.errorContainer,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        auth.error!,
                        style: TextStyle(color: Theme.of(context).colorScheme.onErrorContainer),
                      ),
                    ),
                  TextFormField(
                    controller: _emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Email Address',
                      prefixIcon: Icon(Icons.email_outlined),
                    ),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) return 'Email is required.';
                      if (!val.contains('@') || !val.contains('.')) return 'Enter a valid email address.';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _passwordCtrl,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                        onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                      ),
                    ),
                    validator: (val) =>
                        (val == null || val.isEmpty) ? 'Password is required.' : null,
                  ),
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: auth.isLoading ? null : _submit,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      child: auth.isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Log In'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: auth.isLoading
                        ? null
                        : () => Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(builder: (_) => const RegisterScreen()),
                            ),
                    child: const Text('Need an account? Register'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();
    final ok = await auth.signUp(
      fullName: _nameCtrl.text,
      email: _emailCtrl.text,
      password: _passwordCtrl.text,
    );
    if (ok && mounted) {
      if (auth.user == null) {
        // Email confirmation required
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Verify Your Email'),
            content: const Text(
              'Account created successfully! Please check your email inbox for the verification link or code before signing in.',
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context); // Close dialog
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                  );
                },
                child: const Text('OK'),
              ),
            ],
          ),
        );
      } else {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return Scaffold(
      appBar: AppBar(title: const Text('Create Account')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Join PDF Brain',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),
                  if (auth.error != null)
                    Container(
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.errorContainer,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        auth.error!,
                        style: TextStyle(color: Theme.of(context).colorScheme.onErrorContainer),
                      ),
                    ),
                  TextFormField(
                    controller: _nameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Full Name',
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                    validator: (val) =>
                        (val == null || val.trim().length < 2) ? 'Enter your full name.' : null,
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'University Email',
                      prefixIcon: Icon(Icons.email_outlined),
                    ),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) return 'Email is required.';
                      if (!val.contains('@') || !val.contains('.')) return 'Enter a valid email.';
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _passwordCtrl,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      labelText: 'Password (min 8 chars)',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                        onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                      ),
                    ),
                    validator: (val) => (val == null || val.length < 8)
                        ? 'Password must be at least 8 characters.'
                        : null,
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _confirmCtrl,
                    obscureText: _obscurePassword,
                    decoration: const InputDecoration(
                      labelText: 'Confirm Password',
                      prefixIcon: Icon(Icons.lock_reset_outlined),
                    ),
                    validator: (val) =>
                        val != _passwordCtrl.text ? 'Passwords do not match.' : null,
                  ),
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: auth.isLoading ? null : _submit,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      child: auth.isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Create Account'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}