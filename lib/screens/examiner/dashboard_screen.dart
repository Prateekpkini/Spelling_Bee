import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:spelling_bee/providers/auth_provider.dart';
import 'package:spelling_bee/widgets/glass_scaffold.dart';
import 'package:spelling_bee/widgets/glass_container.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GlassScaffold(
      appBar: AppBar(
        title: const Text('Examiner Console', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'Sign Out',
            onPressed: () async {
              await ref.read(authNotifierProvider.notifier).signOut();
              if (context.mounted) context.go('/login');
            },
          ),
        ],
      ),
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 800),
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome Banner
              GlassContainer(
                padding: const EdgeInsets.all(32),
                child: Row(
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        image: DecorationImage(
                          image: AssetImage('assets/images/logo.png'),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    const SizedBox(width: 24),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Everest Spelling Bee',
                            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'OPEN CHAMPIONSHIP',
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                  color: const Color(0xFFFFD700),
                                  letterSpacing: 2,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),

              Text(
                'Quick Actions',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 20),

              // Action grid (Responsive: 1 col on mobile, 2 cols on desktop)
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final isDesktop = constraints.maxWidth > 800;
                    if (isDesktop) {
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: _ActionCard(
                              icon: Icons.person_add_rounded,
                              title: 'Register Student',
                              subtitle: 'Add a new student and generate their game link',
                              onTap: () => context.go('/register'),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _ActionCard(
                              icon: Icons.people_alt_rounded,
                              title: 'My Students',
                              subtitle: 'View your students and regenerate game links',
                              onTap: () => context.go('/my_students'),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _ActionCard(
                              icon: Icons.leaderboard_rounded,
                              title: 'Leaderboard',
                              subtitle: 'View results, rankings, and export data',
                              onTap: () => context.go('/leaderboard'),
                            ),
                          ),
                        ],
                      );
                    }
                    return ListView(
                      children: [
                        _ActionCard(
                          icon: Icons.person_add_rounded,
                          title: 'Register Student',
                          subtitle: 'Add a new student and generate their game link',
                          onTap: () => context.go('/register'),
                        ),
                        const SizedBox(height: 16),
                        _ActionCard(
                          icon: Icons.people_alt_rounded,
                          title: 'My Students',
                          subtitle: 'View your students and regenerate game links',
                          onTap: () => context.go('/my_students'),
                        ),
                        const SizedBox(height: 16),
                        _ActionCard(
                          icon: Icons.leaderboard_rounded,
                          title: 'Leaderboard',
                          subtitle: 'View results, rankings, and export data',
                          onTap: () => context.go('/leaderboard'),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          hoverColor: Colors.white.withOpacity(0.05),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFD700).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(Icons.arrow_forward_rounded, color: Color(0xFFFFD700), size: 28),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Icon(icon, color: Colors.white, size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        title,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.white70,
                      ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
