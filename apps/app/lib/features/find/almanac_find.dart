import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:prayer_times_core/core.dart';
import 'package:prayer_times_ui/ui.dart';

import '../../services/providers.dart';
import 'find_helpers.dart';

class AlmanacFindScreen extends ConsumerStatefulWidget {
  const AlmanacFindScreen({super.key});

  @override
  ConsumerState<AlmanacFindScreen> createState() => _AlmanacFindScreenState();
}

class _AlmanacFindScreenState extends ConsumerState<AlmanacFindScreen>
    with SingleTickerProviderStateMixin {
  static const _pageSize = 60;

  String _query = '';
  MosqueFindFilter _activeFilter = MosqueFindFilter.nearest;
  MosqueFindView _view = MosqueFindView.list;
  int _visibleCount = _pageSize;
  late final AnimationController _cursorCtrl;
  late final ScrollController _scrollCtrl;

  @override
  void initState() {
    super.initState();
    _cursorCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
    _scrollCtrl = ScrollController()..addListener(_loadMoreNearBottom);
  }

  @override
  void dispose() {
    _cursorCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _loadMoreNearBottom() {
    if (!_scrollCtrl.hasClients) return;
    final position = _scrollCtrl.position;
    if (position.pixels >= position.maxScrollExtent - 420) {
      setState(() => _visibleCount += _pageSize);
    }
  }

  void _resetListWindow() {
    _visibleCount = _pageSize;
    if (_scrollCtrl.hasClients) {
      _scrollCtrl.jumpTo(0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final mosques = ref.watch(mosquesProvider).valueOrNull ?? const <Mosque>[];
    final favourites =
        ref.watch(favouriteIdsProvider).valueOrNull ?? const <String>[];
    final userLocation = ref.watch(userLocationProvider).valueOrNull;
    final results = buildMosqueResults(
      mosques: mosques,
      query: _query,
      filter: _activeFilter,
      favouriteIds: favourites,
      userLocation: userLocation,
    );

    return Scaffold(
      backgroundColor: ATokens.paper,
      body: Column(
        children: [
          _Header(),
          _SearchBar(
            query: _query,
            resultCount: results.length,
            cursorCtrl: _cursorCtrl,
            onChanged: (value) => setState(() {
              _query = value;
              _resetListWindow();
            }),
          ),
          _Controls(
            view: _view,
            activeFilter: _activeFilter,
            onViewChanged: (view) => setState(() => _view = view),
            onFilterChanged: (filter) => setState(() {
              _activeFilter = filter;
              _resetListWindow();
            }),
          ),
          Expanded(
            child: _view == MosqueFindView.map
                ? _MapPane(
                    mosques: results,
                    userLocation: userLocation,
                    onMosqueTap: _showMosqueSheet,
                  )
                : _MosqueList(
                    controller: _scrollCtrl,
                    mosques: results,
                    visibleCount: _visibleCount,
                    favouriteIds: favourites,
                    userLocation: userLocation,
                    onMosqueTap: _setActiveMosque,
                    onShowMore: () =>
                        setState(() => _visibleCount += _pageSize),
                  ),
          ),
        ],
      ),
    );
  }

  Future<void> _setActiveMosque(Mosque mosque) async {
    await ref.read(activeMosqueIdProvider.notifier).setActiveMosque(mosque.id);
    if (mounted) context.go('/');
  }

  void _showMosqueSheet(Mosque mosque) {
    final userLocation = ref.read(userLocationProvider).valueOrNull;
    final distance = (userLocation != null && mosque.location != null)
        ? haversineKm(userLocation, mosque.location!)
        : null;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: ATokens.paper,
      builder: (context) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(mosque.name, style: ATokens.serif(size: 20, italic: true)),
            const SizedBox(height: 4),
            Text(
              mosqueAddressSummary(mosque),
              style: ATokens.mono(size: 11, color: ATokens.ink60),
            ),
            if (distance != null) ...[
              const SizedBox(height: 6),
              Text(
                '${distance.toStringAsFixed(1)} km away',
                style: ATokens.mono(size: 11, color: ATokens.ink60),
              ),
            ],
            const SizedBox(height: 16),
            _AOutlinedButton(
              label: 'SET AS ACTIVE',
              onPressed: () {
                Navigator.of(context).pop();
                _setActiveMosque(mosque);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 10),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: ATokens.rule, width: 2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'SECTION 02',
            style: ATokens.mono(
              size: 9,
              color: ATokens.ink60,
              letterSpacing: 1.8,
            ),
          ),
          const SizedBox(height: 4),
          Text('Mosques nearby', style: ATokens.serif(size: 28, italic: true)),
        ],
      ),
    );
  }
}

class _SearchBar extends StatelessWidget {
  const _SearchBar({
    required this.query,
    required this.resultCount,
    required this.cursorCtrl,
    required this.onChanged,
  });

  final String query;
  final int resultCount;
  final AnimationController cursorCtrl;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: ATokens.rule)),
      ),
      child: Row(
        children: [
          Text('›', style: ATokens.mono(size: 11, color: ATokens.ink40)),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              style: ATokens.mono(size: 12),
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: 'Search...',
                hintStyle: ATokens.mono(size: 12, color: ATokens.ink40),
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
              onChanged: onChanged,
            ),
          ),
          if (query.isEmpty)
            AnimatedBuilder(
              animation: cursorCtrl,
              builder: (_, __) => Opacity(
                opacity: cursorCtrl.value,
                child: Container(width: 1, height: 12, color: ATokens.ink),
              ),
            ),
          const SizedBox(width: 12),
          Text(
            '$resultCount RESULTS',
            style:
                ATokens.mono(size: 9, color: ATokens.ink40, letterSpacing: 1.4),
          ),
        ],
      ),
    );
  }
}

class _Controls extends StatelessWidget {
  const _Controls({
    required this.view,
    required this.activeFilter,
    required this.onViewChanged,
    required this.onFilterChanged,
  });

  final MosqueFindView view;
  final MosqueFindFilter activeFilter;
  final ValueChanged<MosqueFindView> onViewChanged;
  final ValueChanged<MosqueFindFilter> onFilterChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: ATokens.rule)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              _ToggleButton(
                label: 'LIST',
                active: view == MosqueFindView.list,
                onTap: () => onViewChanged(MosqueFindView.list),
              ),
              _ToggleButton(
                label: 'MAP',
                active: view == MosqueFindView.map,
                onTap: () => onViewChanged(MosqueFindView.map),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final filter in mosqueFindFilters)
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: _ToggleButton(
                      label: mosqueFindFilterLabel(filter),
                      active: activeFilter == filter,
                      onTap: () => onFilterChanged(filter),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ToggleButton extends StatelessWidget {
  const _ToggleButton({
    required this.label,
    required this.active,
    required this.onTap,
  });

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: active ? ATokens.ink : Colors.transparent,
          border: Border.all(color: ATokens.rule),
        ),
        child: Text(
          label,
          style: ATokens.mono(
            size: 9,
            color: active ? ATokens.paper : ATokens.ink,
            letterSpacing: 1.6,
          ),
        ),
      ),
    );
  }
}

class _MapPane extends StatelessWidget {
  const _MapPane({
    required this.mosques,
    required this.userLocation,
    required this.onMosqueTap,
  });

  final List<Mosque> mosques;
  final LatLng? userLocation;
  final ValueChanged<Mosque> onMosqueTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: MosqueMap(
        mosques: mosques,
        userLocation: userLocation,
        onMosqueTap: onMosqueTap,
      ),
    );
  }
}

class _MosqueList extends StatelessWidget {
  const _MosqueList({
    required this.controller,
    required this.mosques,
    required this.visibleCount,
    required this.favouriteIds,
    required this.userLocation,
    required this.onMosqueTap,
    required this.onShowMore,
  });

  final ScrollController controller;
  final List<Mosque> mosques;
  final int visibleCount;
  final List<String> favouriteIds;
  final LatLng? userLocation;
  final ValueChanged<Mosque> onMosqueTap;
  final VoidCallback onShowMore;

  @override
  Widget build(BuildContext context) {
    final count = math.min(visibleCount, mosques.length);
    if (mosques.isEmpty) {
      return Center(
        child: Text(
          'No matching mosques.',
          style: ATokens.mono(size: 11, color: ATokens.ink60),
        ),
      );
    }

    return ListView.builder(
      controller: controller,
      padding: EdgeInsets.zero,
      itemCount: count + (count < mosques.length ? 1 : 0),
      itemBuilder: (context, index) {
        if (index >= count) {
          return Padding(
            padding: const EdgeInsets.all(20),
            child: Center(
              child: _AOutlinedButton(
                label: 'SHOW MORE',
                onPressed: onShowMore,
              ),
            ),
          );
        }

        final mosque = mosques[index];
        final isFav = favouriteIds.contains(mosque.id);
        final distance = (userLocation != null && mosque.location != null)
            ? haversineKm(userLocation!, mosque.location!)
            : null;

        return InkWell(
          onTap: () => onMosqueTap(mosque),
          child: Container(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: ATokens.ink20)),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 28,
                  child: Text(
                    (index + 1).toString().padLeft(2, '0'),
                    style: ATokens.mono(size: 10, color: ATokens.ink40),
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(mosque.name, style: ATokens.serif(size: 15)),
                      const SizedBox(height: 2),
                      Text(
                        mosqueLocationSummary(mosque).toUpperCase(),
                        style: ATokens.mono(size: 10, color: ATokens.ink60),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      distance != null
                          ? '${distance.toStringAsFixed(1)} km'
                          : userLocation == null
                              ? 'enable location'
                              : '',
                      style: ATokens.mono(size: 12).copyWith(
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                    Text(
                      isFav ? 'FAV *' : '',
                      style: ATokens.mono(size: 9, color: ATokens.ink60),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _AOutlinedButton extends StatelessWidget {
  const _AOutlinedButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(border: Border.all(color: ATokens.rule)),
        child: Text(label, style: ATokens.mono(size: 10, letterSpacing: 1.6)),
      ),
    );
  }
}
