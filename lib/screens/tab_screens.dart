import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../app/theme.dart';
import '../data/user_store.dart';
import '../data/content.dart';
import '../app/onboarding_state.dart';
import '../widgets/common.dart';
import '../widgets/globe.dart';
import '../widgets/help_sheet.dart';
import '../widgets/liquid_glass_nav.dart';

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
      bottomNavigationBar: Builder(
        builder: (context) {
          final bottom = MediaQuery.paddingOf(context).bottom;
          return Padding(
            padding: EdgeInsets.fromLTRB(
              16,
              0,
              16,
              bottom > 0 ? bottom - 10 : 10,
            ),
            child: LiquidGlassNav(
              selectedIndex: shell.currentIndex,
              onChanged: (i) =>
                  shell.goBranch(i, initialLocation: i == shell.currentIndex),
            ),
          );
        },
      ),
    );
  }
}

class SessionsScreen extends StatelessWidget {
  const SessionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: UserStore.instance.sessions,
      builder: (context, sessions, _) => sessions.isEmpty
          ? _emptyState(context)
          : _SessionList(sessions: sessions),
    );
  }

  Widget _emptyState(BuildContext context) {
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
                            color: AppColors.surface,
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
                  expand: false,
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

class _SessionList extends StatelessWidget {
  const _SessionList({required this.sessions});

  final List<BookedSession> sessions;

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;
    return Scaffold(
      body: AquaBackground(
        child: SafeArea(
          bottom: false,
          child: ListView(
            padding: EdgeInsets.fromLTRB(20, 12, 20, bottom + 20),
            children: [
              Text('My Sessions', style: AppText.display),
              const SizedBox(height: 4),
              Text(
                'We’ll notify you when your Guide goes live.',
                style: AppText.body,
              ),
              const SizedBox(height: 16),
              for (final s in sessions) ...[
                _SessionTile(session: s),
                const SizedBox(height: 12),
              ],
              TextButton.icon(
                onPressed: () => context.push('/explore'),
                icon: const Icon(Icons.add),
                label: const Text('Book another guide'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SessionTile extends StatelessWidget {
  const _SessionTile({required this.session});

  final BookedSession session;

  @override
  Widget build(BuildContext context) {
    final guide = session.guide;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  width: 52,
                  height: 52,
                  child: Photo(session.area.image, icon: session.kind.icon),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      session.kind.placeTitle(session.area.name),
                      style: AppText.label,
                    ),
                    Text(
                      '${session.checks.length} checks · AED '
                      '${Pricing.base} after they join',
                      style: AppText.small,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.tealTint,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                GuideAvatar(guide, size: 32, online: true),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '${guide.name} joins in ~${guide.joinMinutes} min',
                    style: AppText.small.copyWith(
                      color: AppColors.ink,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.teal,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: Text('Free to cancel until then', style: AppText.small),
              ),
              TextButton(
                onPressed: () {
                  UserStore.instance.cancelSession(session);
                  ScaffoldMessenger.of(context)
                    ..hideCurrentSnackBar()
                    ..showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Request cancelled. You weren’t charged.',
                        ),
                      ),
                    );
                },
                child: const Text('Cancel'),
              ),
            ],
          ),
        ],
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
                        backgroundColor: AppColors.surface,
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
              Icon(
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
      trailing: Icon(Icons.chevron_right, color: AppColors.muted),
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
              // Sets the whole app's theme (was the 🌙 / ☀️ switch on Home).
              SwitchListTile(
                secondary: const Icon(
                  Icons.dark_mode_outlined,
                  color: AppColors.teal,
                ),
                title: Text('Dark mode', style: AppText.label),
                value: !globeLight.value,
                onChanged: (on) => globeLight.value = !on,
              ),
              ListTile(
                leading: const Icon(Icons.help_outline, color: AppColors.teal),
                title: Text('Help & support', style: AppText.label),
                trailing: Icon(Icons.chevron_right, color: AppColors.muted),
                onTap: () => showHelpSheet(context),
              ),
              ListTile(
                leading: const Icon(
                  Icons.play_circle_outline,
                  color: AppColors.teal,
                ),
                title: Text('Replay intro', style: AppText.label),
                trailing: Icon(Icons.chevron_right, color: AppColors.muted),
                onTap: () => replayOnboarding.value++,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
