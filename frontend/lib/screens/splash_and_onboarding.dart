import 'package:flutter/material.dart';
import 'auth_screens.dart';

class WelcomeOnboardingScreen extends StatelessWidget {
  const WelcomeOnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: scheme.primaryContainer,
                    child: Icon(Icons.menu_book_rounded, size: 42, color: scheme.primary),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'PDF Brain',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Your AI-powered academic study assistant grounded in your own PDF documents.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: scheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: 32),
                  const _BenefitTile(
                    icon: Icons.upload_file_outlined,
                    title: '1. Upload Your Lecture Notes & Papers',
                    subtitle: 'Extract and index text page-by-page into a private vector database.',
                  ),
                  const SizedBox(height: 14),
                  const _BenefitTile(
                    icon: Icons.psychology_outlined,
                    title: '2. Ask Natural-Language Questions',
                    subtitle: 'Search across a single PDF or combine insights across multiple documents.',
                  ),
                  const SizedBox(height: 14),
                  const _BenefitTile(
                    icon: Icons.fact_check_outlined,
                    title: '3. Verify Every Answer with Page Citations',
                    subtitle: 'View exact supporting excerpts and tap to jump directly to the cited PDF page.',
                  ),
                  const SizedBox(height: 36),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const RegisterScreen()),
                      ),
                      child: const Padding(
                        padding: EdgeInsets.symmetric(vertical: 14),
                        child: Text('Create Student Account'),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const LoginScreen()),
                      ),
                      child: const Padding(
                        padding: EdgeInsets.symmetric(vertical: 14),
                        child: Text('Sign In to Existing Account'),
                      ),
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

class _BenefitTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _BenefitTile({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: scheme.primary, size: 26),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 2),
              Text(subtitle, style: TextStyle(fontSize: 13, color: scheme.onSurfaceVariant)),
            ],
          ),
        ),
      ],
    );
  }
}