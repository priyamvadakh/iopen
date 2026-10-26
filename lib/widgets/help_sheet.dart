import 'package:flutter/material.dart';

import '../app/theme.dart';
import 'common.dart';

const _faqs = [
  (
    'When do I pay?',
    'Only after your Guide joins the live video. If they don’t join, you '
        'pay nothing.',
  ),
  ('Can I cancel?', 'Yes, free of charge any time before your Guide joins.'),
  (
    'How are Guides checked?',
    'Every Guide verifies their ID and is rated by travellers after each '
        'session. You see their rating before you book.',
  ),
  (
    'What if the video drops?',
    'Your Guide calls you back straight away. Lost minutes are added back, '
        'or refunded if the session can’t continue.',
  ),
  (
    'Can I record the session?',
    'Yes. A recording is saved to Sessions so you can watch it again.',
  ),
];

/// Short answers to the questions people ask before and after booking.
Future<void> showHelpSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    showDragHandle: true,
    builder: (context) => SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.8,
        ),
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
          children: [
            Text('Help', style: AppText.title),
            const SizedBox(height: 4),
            Text(
              'Quick answers. We’re here if you need more.',
              style: AppText.body,
            ),
            const SizedBox(height: 8),
            for (final (q, a) in _faqs)
              Theme(
                data: Theme.of(context)
                    .copyWith(dividerColor: Colors.transparent),
                child: ExpansionTile(
                  tilePadding: EdgeInsets.zero,
                  title: Text(q, style: AppText.label),
                  childrenPadding: const EdgeInsets.only(bottom: 12),
                  expandedCrossAxisAlignment: CrossAxisAlignment.start,
                  children: [Text(a, style: AppText.body)],
                ),
              ),
            const SizedBox(height: 12),
            GlossyButton(
              onPressed: () {
                Navigator.pop(context);
                showComingSoon(context, 'Live chat with support');
              },
              child: const Text('Chat with us'),
            ),
          ],
        ),
      ),
    ),
  );
}
