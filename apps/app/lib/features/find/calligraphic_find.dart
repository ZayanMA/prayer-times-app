import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:prayer_times_core/core.dart';
import 'package:prayer_times_ui/ui.dart';

import '../../services/providers.dart';
import 'find_helpers.dart';

class CalligraphicFindScreen extends ConsumerStatefulWidget {
  const CalligraphicFindScreen({super.key});

  @override
  ConsumerState<CalligraphicFindScreen> createState() =>
      _CalligraphicFindScreenState();
}

class _CalligraphicFindScreenState
    extends ConsumerState<CalligraphicFindScreen> {
  static const _pageSize = 60;

  String _query = '';
  MosqueFindFilter _activeFilter = MosqueFindFilter.nearest;
  MosqueFindView _view = MosqueFindView.list;
  int _visibleCount = _pageSize;
  late final ScrollController _scrollCtrl;

  @override
  void initState() {
    super.initState();
    _scrollCtrl = ScrollController()..addListener(_loadMoreNearBottom);
  }

  @override
  void dispose() {
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
      backgroundColor: BTokens.bg,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Mosques',
                  style: BTokens.body(
                    size: 10,
                    color: BTokens.gold,
                    letterSpacing: 2.4,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Find a place\nto pray.',
                  style: BTokens.display(size: 38, italic: true),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 12),
            child: Container(
              decoration: BoxDecoration(
                border: Border(
                  bottom:
                      BorderSide(color: BTokens.gold.withValues(alpha: 0.5)),
                ),
              ),
              child: Row(
                children: [
                  Text('⌕', style: BTokens.body(size: 16, color: BTokens.gold)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      style: BTokens.display(size: 15, italic: true),
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        hintText: 'by name, area or postcode',
                        hintStyle: BTokens.display(
                          size: 15,
                          italic: true,
                          color: BTokens.ink40,
                        ),
                        isDense: true,
                        contentPadding:
                            const EdgeInsets.symmetric(vertical: 10),
                      ),
                      onChanged: (value) => setState(() {
                        _query = value;
                        _resetListWindow();
                      }),
                    ),
                  ),
                  Text(
                    '${results.length}',
                    style: BTokens.body(size: 10, color: BTokens.ink40),
                  ),
                ],
              ),
            ),
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
                ? Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    child: MosqueMap(
                      mosques: results,
                      userLocation: userLocation,
                      onMosqueTap: _showMosqueSheet,
                    ),
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
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: BTokens.bg,
      builder: (context) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(mosque.name, style: BTokens.display(size: 24, italic: true)),
            const SizedBox(height: 6),
            Text(
              mosqueAddressSummary(mosque),
              style: BTokens.body(size: 12, color: BTokens.ink60),
            ),
            const SizedBox(height: 18),
            _GoldButton(
              label: 'SET AS ACTIVE',
              onTap: () {
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
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
      child: Column(
        children: [
          Row(
            children: [
              _Chip(
                label: 'LIST',
                active: view == MosqueFindView.list,
                onTap: () => onViewChanged(MosqueFindView.list),
              ),
              const SizedBox(width: 8),
              _Chip(
                label: 'MAP',
                active: view == MosqueFindView.map,
                onTap: () => onViewChanged(MosqueFindView.map),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final filter in mosqueFindFilters)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: _Chip(
                      label: mosqueFindFilterLabel(filter),
                      active: filter == activeFilter,
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

class _Chip extends StatelessWidget {
  const _Chip({
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
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: active ? BTokens.gold : Colors.transparent,
          border: Border.all(color: active ? BTokens.gold : BTokens.goldDim),
        ),
        child: Text(
          label,
          style: BTokens.body(
            size: 10,
            color: active ? BTokens.bg : BTokens.gold,
            letterSpacing: 1.8,
          ),
        ),
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
          style: BTokens.body(size: 12, color: BTokens.ink60),
        ),
      );
    }

    return ListView.builder(
      controller: controller,
      padding: const EdgeInsets.fromLTRB(24, 4, 24, 0),
      itemCount: count + (count < mosques.length ? 1 : 0),
      itemBuilder: (context, index) {
        if (index >= count) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 18),
            child: Center(
              child: _GoldButton(label: 'SHOW MORE', onTap: onShowMore),
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
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: BTokens.ink20)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        mosque.name,
                        style: BTokens.display(size: 18, italic: true),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        mosqueLocationSummary(mosque).toUpperCase(),
                        style: BTokens.body(
                          size: 10,
                          color: BTokens.ink40,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (distance != null)
                      RichText(
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: distance.toStringAsFixed(1),
                              style: BTokens.display(
                                size: 22,
                                color: BTokens.gold,
                              ).copyWith(
                                fontFeatures: const [
                                  FontFeature.tabularFigures(),
                                ],
                              ),
                            ),
                            TextSpan(
                              text: ' km',
                              style: BTokens.body(
                                size: 10,
                                color: BTokens.goldDim,
                              ),
                            ),
                          ],
                        ),
                      ),
                    if (distance == null && userLocation == null)
                      Text(
                        'ENABLE LOCATION',
                        style: BTokens.body(
                          size: 9,
                          color: BTokens.ink40,
                          letterSpacing: 1.2,
                        ),
                      ),
                    if (isFav)
                      Text('*',
                          style: BTokens.body(size: 10, color: BTokens.gold)),
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

class _GoldButton extends StatelessWidget {
  const _GoldButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(border: Border.all(color: BTokens.goldDim)),
        child: Text(
          label,
          style:
              BTokens.body(size: 10, color: BTokens.gold, letterSpacing: 2.0),
        ),
      ),
    );
  }
}
