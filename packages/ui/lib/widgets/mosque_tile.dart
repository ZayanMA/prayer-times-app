import 'package:flutter/material.dart';
import 'package:prayer_times_core/core.dart';

import '../theme/tokens.dart';

class MosqueTile extends StatelessWidget {
  const MosqueTile({
    super.key,
    required this.mosque,
    required this.isFavourite,
    required this.onFavouriteToggle,
    this.onTap,
    this.trailing,
  });

  final Mosque mosque;
  final bool isFavourite;
  final VoidCallback onFavouriteToggle;
  final VoidCallback? onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xs,
        ),
        title: Text(mosque.name, maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Text(
          '${mosque.area}, ${mosque.city} · ${mosque.sourceKind.label}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        leading: CircleAvatar(
          backgroundColor: theme.colorScheme.primaryContainer,
          foregroundColor: theme.colorScheme.onPrimaryContainer,
          child: const Icon(Icons.mosque_outlined),
        ),
        trailing: trailing ??
            IconButton(
              tooltip: isFavourite ? 'Remove favourite' : 'Add favourite',
              onPressed: onFavouriteToggle,
              icon: Icon(isFavourite ? Icons.star : Icons.star_border),
            ),
      ),
    );
  }
}
