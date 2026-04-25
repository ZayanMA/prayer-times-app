import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:prayer_times_core/core.dart';

import '../theme/tokens.dart';

class PrayerRow extends StatelessWidget {
  const PrayerRow({
    super.key,
    required this.entry,
  });

  final PrayerTimeEntry entry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final format = DateFormat.Hm();

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              entry.name,
              style: theme.textTheme.titleMedium,
            ),
          ),
          Text(
            format.format(entry.begins),
            style: theme.textTheme.titleMedium?.copyWith(
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          if (entry.jamaat != null) ...[
            const SizedBox(width: AppSpacing.md),
            Text(
              format.format(entry.jamaat!),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.muted,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
