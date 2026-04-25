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
    this.distanceKm,
  });

  final Mosque mosque;
  final bool isFavourite;
  final VoidCallback onFavouriteToggle;
  final VoidCallback? onTap;
  final Widget? trailing;
  final double? distanceKm;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final subtitleParts = <String>[
      if (mosque.area.isNotEmpty && mosque.area != 'Unknown') mosque.area,
      if (mosque.city.isNotEmpty &&
          mosque.city != 'Unknown' &&
          mosque.city != mosque.area)
        mosque.city,
      if (distanceKm != null) _formatDistance(distanceKm!),
    ];

    return Card(
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xs,
        ),
        title: Text(
          mosque.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.titleMedium,
        ),
        subtitle: subtitleParts.isEmpty
            ? null
            : Text(
                subtitleParts.join(' · '),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
        leading: Container(
          width: 44,
          height: 44,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: theme.colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(AppRadii.md),
          ),
          child: Icon(
            Icons.mosque_outlined,
            color: theme.colorScheme.onPrimaryContainer,
          ),
        ),
        trailing: trailing ??
            IconButton(
              tooltip: isFavourite ? 'Remove favourite' : 'Add favourite',
              onPressed: onFavouriteToggle,
              icon: Icon(
                isFavourite ? Icons.favorite : Icons.favorite_border,
                color: isFavourite ? theme.colorScheme.primary : null,
              ),
            ),
      ),
    );
  }

  String _formatDistance(double km) {
    if (km < 1) return '${(km * 1000).round()} m';
    if (km < 10) return '${km.toStringAsFixed(1)} km';
    return '${km.round()} km';
  }
}
