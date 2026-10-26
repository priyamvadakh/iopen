import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../app/theme.dart';
import '../data/content.dart';
import '../widgets/common.dart';
import '../widgets/glass_nav_bar.dart';
import '../widgets/globe.dart';

/// Tab scaffold with the floating glass navigation pill. The body extends
/// behind the pill, and the pill's height is added to the bottom padding so
/// screens can keep their last item clear of it.
class TabShell extends StatelessWidget {
  const TabShell({super.key, required this.shell});

  final StatefulNavigationShell shell;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: shell,
      bottomNavigationBar: GlassNavBar(
        currentIndex: shell.currentIndex,
        onTap: (i) =>
            shell.goBranch(i, initialLocation: i == shell.currentIndex),
      ),
    );
  }
}

class SessionsScreen extends StatelessWidget {
  const SessionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AquaBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                const SizedBox(height: 12),
                Text('My Sessions', style: AppText.section),
                const Spacer(),
                SizedBox(
                  height: 260,
                  width: 280,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Positioned.fill(
                        left: 10,
                        right: 10,
                        top: 30,
                        child: Container(
                          decoration: BoxDecoration(
                            color: AppColors.tealTint,
                            borderRadius: BorderRadius.circular(120),
                          ),
                        ),
                      ),
                      Positioned(
                        left: 50,
                        right: 50,
                        top: 0,
                        bottom: 0,
                        child: ClipRRect(
                          borderRadius: const BorderRadius.vertical(
                            bottom: Radius.circular(90),
                            top: Radius.circular(24),
                          ),
                          child: const Photo(
                            'traveler',
                            icon: Icons.backpack_outlined,
                            alignment: Alignment.topCenter,
                          ),
                        ),
                      ),
                      const Positioned(
                        left: 0,
                        top: 20,
                        child: Icon(
                          Icons.auto_awesome,
                          color: AppColors.teal,
                          size: 30,
                        ),
                      ),
                      Positioned(
                        right: -6,
                        top: 70,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.place,
                                size: 14,
                                color: AppColors.teal,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Active Remote Guiding',
                                style: AppText.small.copyWith(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.ink,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),
                Text('No sessions yet', style: AppText.title),
                const SizedBox(height: 6),
                Text('Book a guide to start exploring.', style: AppText.body),
                const SizedBox(height: 24),
                GlossyButton(
                  onPressed: () => context.push('/explore'),
                  child: const Text('Find a guide'),
                ),
                const Spacer(flex: 2),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class MapScreen extends StatelessWidget {
  const MapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AquaBackground(
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Guides worldwide', style: AppText.display),
                    const SizedBox(height: 4),
                    Text(
                      '$totalGuidesOnline online now · drag the globe',
                      style: AppText.body,
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Globe(onCityTap: (c) => context.push('/city/${c.id}')),
              ),
              SizedBox(
                height: 44,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: cities.length,
                  separatorBuilder: (context, _) => const SizedBox(width: 8),
                  itemBuilder: (context, i) => ChoicePill(
                    label: '${cities[i].name} · ${cities[i].guidesOnline}',
                    icon: Icons.place_outlined,
                    selected: false,
                    onTap: () => context.push('/city/${cities[i].id}'),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

class WalletScreen extends StatelessWidget {
  const WalletScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AquaBackground(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            children: [
              Text('Wallet', style: AppText.display),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.teal,
                  borderRadius: BorderRadius.circular(AppRadius.card),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Balance',
                      style: AppText.small.copyWith(color: AppColors.tealTint),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'AED 50.00',
                      style: AppText.display.copyWith(color: Colors.white),
                    ),
                    const SizedBox(height: 16),
                    OutlinedButton.icon(
                      onPressed: () => showComingSoon(context, 'Top up'),
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Top up'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.teal,
                        backgroundColor: Colors.white,
                        side: BorderSide.none,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.button),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              Text('Recent activity', style: AppText.section),
              const SizedBox(height: 24),
              const Icon(
                Icons.receipt_long_outlined,
                size: 36,
                color: AppColors.muted,
              ),
              const SizedBox(height: 8),
              Text(
                'No payments yet.',
                style: AppText.body,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    Widget tile(IconData icon, String label) => ListTile(
      leading: Icon(icon, color: AppColors.teal),
      title: Text(label, style: AppText.label),
      trailing: const Icon(Icons.chevron_right, color: AppColors.muted),
      onTap: () => showComingSoon(context, label),
    );

    return Scaffold(
      body: AquaBackground(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.symmetric(vertical: 12),
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: AppColors.tealTint,
                      child: Text(
                        'P',
                        style: AppText.title.copyWith(color: AppColors.teal),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Priya', style: AppText.title),
                        Text('Traveller since 2026', style: AppText.small),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              tile(Icons.credit_card, 'Payment methods'),
              tile(Icons.bookmark_border, 'Saved places'),
              tile(Icons.translate, 'Language'),
              tile(Icons.notifications_none, 'Notifications'),
              tile(Icons.help_outline, 'Help & support'),
            ],
          ),
        ),
      ),
    );
  }
}
