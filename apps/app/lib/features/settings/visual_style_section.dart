import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:prayer_times_core/core.dart';
import 'package:prayer_times_ui/ui.dart';

class VisualStyleSection extends StatelessWidget {
  const VisualStyleSection({
    super.key,
    required this.current,
    required this.onChanged,
    this.isAlmanac = false,
    this.isCalligraphic = false,
    this.isCelestial = false,
  });

  final AppDesignDirection current;
  final ValueChanged<AppDesignDirection> onChanged;
  final bool isAlmanac;
  final bool isCalligraphic;
  final bool isCelestial;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StyleTile(
            label: 'A',
            title: 'Almanac',
            direction: AppDesignDirection.almanac,
            current: current,
            onTap: () => onChanged(AppDesignDirection.almanac),
            isAlmanac: isAlmanac,
            isCalligraphic: isCalligraphic,
            isCelestial: isCelestial,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _StyleTile(
            label: 'ب',
            title: 'Calligraphic',
            direction: AppDesignDirection.calligraphic,
            current: current,
            onTap: () => onChanged(AppDesignDirection.calligraphic),
            isAlmanac: isAlmanac,
            isCalligraphic: isCalligraphic,
            isCelestial: isCelestial,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _StyleTile(
            label: '☽',
            title: 'Celestial',
            direction: AppDesignDirection.celestial,
            current: current,
            onTap: () => onChanged(AppDesignDirection.celestial),
            isAlmanac: isAlmanac,
            isCalligraphic: isCalligraphic,
            isCelestial: isCelestial,
          ),
        ),
      ],
    );
  }
}

class _StyleTile extends StatelessWidget {
  const _StyleTile({
    required this.label,
    required this.title,
    required this.direction,
    required this.current,
    required this.onTap,
    required this.isAlmanac,
    required this.isCalligraphic,
    required this.isCelestial,
  });

  final String label;
  final String title;
  final AppDesignDirection direction;
  final AppDesignDirection current;
  final VoidCallback onTap;
  final bool isAlmanac;
  final bool isCalligraphic;
  final bool isCelestial;

  bool get isSelected => direction == current;

  @override
  Widget build(BuildContext context) {
    if (isAlmanac) return _buildAlmanac();
    if (isCalligraphic) return _buildCalligraphic();
    return _buildCelestial();
  }

  Widget _buildAlmanac() {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected ? ATokens.ink : Colors.transparent,
          border: Border.all(color: ATokens.rule),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: isSelected
                  ? ATokens.mono(size: 18, color: ATokens.paper)
                  : ATokens.serif(size: 18, italic: true),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: ATokens.mono(
                size: 9,
                color: isSelected ? ATokens.paper : ATokens.ink60,
                letterSpacing: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCalligraphic() {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected ? BTokens.gold : Colors.transparent,
          border: Border.all(
              color: isSelected ? BTokens.gold : BTokens.goldDim),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: isSelected
                  ? BTokens.arabic(size: 22, color: BTokens.bg)
                  : BTokens.arabic(size: 22, color: BTokens.gold),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: BTokens.body(
                size: 9,
                color: isSelected ? BTokens.bg : BTokens.ink60,
                letterSpacing: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCelestial() {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
            decoration: BoxDecoration(
              color: isSelected
                  ? Colors.white.withValues(alpha: 0.25)
                  : Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected
                    ? CTokens.gold
                    : Colors.white.withValues(alpha: 0.18),
              ),
            ),
            child: Column(
              children: [
                Text(
                  label,
                  style: isSelected
                      ? CTokens.serif(size: 18, color: CTokens.gold)
                      : CTokens.serif(size: 18),
                ),
                const SizedBox(height: 4),
                Text(
                  title,
                  style: CTokens.body(
                    size: 9,
                    color: isSelected ? CTokens.gold : CTokens.ink70,
                    letterSpacing: 1.4,
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
