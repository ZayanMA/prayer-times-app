import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:prayer_times_core/core.dart';
import 'package:prayer_times_ui/ui.dart';

import '../../services/providers.dart';
import 'find_helpers.dart';

class CelestialFindScreen extends ConsumerStatefulWidget {
  const CelestialFindScreen({super.key});

  @override
  ConsumerState<CelestialFindScreen> createState() =>
      _CelestialFindScreenState();
}

class _CelestialFindScreenState extends ConsumerState<CelestialFindScreen> {
  static const _pageSize = 60;

  String _query = '';
  DateTime _now = DateTime.now();
  MosqueFindFilter _activeFilter = MosqueFindFilter.nearest;
  MosqueFindView _view = MosqueFindView.list;
  int _visibleCount = _pageSize;
  late final Timer _timer;
  late final ScrollController _scrollCtrl;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(
      const Duration(minutes: 5),
      (_) => setState(() => _now = DateTime.now()),
    );
    _scrollCtrl = ScrollController()..addListener(_loadMoreNearBottom);
  }

  @override
  void dispose() {
    _timer.cancel();
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
    final gradient = CTokens.skyGradient(_now);

    return Stack(
      children: [
        Positioned.fill(
            child: DecoratedBox(decoration: BoxDecoration(gradient: gradient))),
        Scaffold(
          backgroundColor: Colors.transparent,
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 60),
              Padding(
                padding: const EdgeInsets.fromLTRB(22, 0, 22, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Mosques',
                        style: CTokens.body(size: 11, color: CTokens.ink70)),
                    const SizedBox(height: 2),
                    Text(
                      'Pray nearby.',
                      style: CTokens.serif(size: 36, w: FontWeight.w300),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(22, 14, 22, 0),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  child: Row(
                    children: [
                      const Text(
                        '⌕',
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          style: CTokens.body(size: 12),
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            hintText: 'Search by name, area, postcode',
                            hintStyle:
                                CTokens.body(size: 12, color: CTokens.ink70),
                            isDense: true,
                            contentPadding: EdgeInsets.zero,
                          ),
                          onChanged: (value) => setState(() {
                            _query = value;
                            _resetListWindow();
                          }),
                        ),
                      ),
                      Text(
                        '${results.length}',
                        style: CTokens.mono(size: 11, color: CTokens.ink70),
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
                        now: _now,
                        onMosqueTap: _setActiveMosque,
                        onShowMore: () =>
                            setState(() => _visibleCount += _pageSize),
                      ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _setActiveMosque(Mosque mosque) async {
    await ref.read(activeMosqueIdProvider.notifier).setActiveMosque(mosque.id);
    if (mounted) context.go('/');
  }

  void _showMosqueSheet(Mosque mosque) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF18213F),
      builder: (context) => Padding(
        padding: const EdgeInsets.fromLTRB(22, 20, 22, 30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(mosque.name, style: CTokens.serif(size: 24)),
            const SizedBox(height: 6),
            Text(
              mosqueAddressSummary(mosque),
              style: CTokens.body(size: 12, color: CTokens.ink70),
            ),
            const SizedBox(height: 18),
            _FrostButton(
              label: 'Set as active',
              active: true,
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
      padding: const EdgeInsets.fromLTRB(22, 12, 22, 4),
      child: Column(
        children: [
          Row(
            children: [
              _FrostButton(
                label: 'List',
                active: view == MosqueFindView.list,
                onTap: () => onViewChanged(MosqueFindView.list),
              ),
              const SizedBox(width: 8),
              _FrostButton(
                label: 'Map',
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
                    child: _FrostButton(
                      label: mosqueFindFilterLabel(filter).toLowerCase(),
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

class _MosqueList extends StatelessWidget {
  const _MosqueList({
    required this.controller,
    required this.mosques,
    required this.visibleCount,
    required this.favouriteIds,
    required this.userLocation,
    required this.now,
    required this.onMosqueTap,
    required this.onShowMore,
  });

  final ScrollController controller;
  final List<Mosque> mosques;
  final int visibleCount;
  final List<String> favouriteIds;
  final LatLng? userLocation;
  final DateTime now;
  final ValueChanged<Mosque> onMosqueTap;
  final VoidCallback onShowMore;

  @override
  Widget build(BuildContext context) {
    final count = math.min(visibleCount, mosques.length);
    if (mosques.isEmpty) {
      return Center(
        child: Text(
          'No matching mosques.',
          style: CTokens.body(size: 12, color: CTokens.ink70),
        ),
      );
    }

    return ListView.builder(
      controller: controller,
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      itemCount: count + (count < mosques.length ? 1 : 0),
      itemBuilder: (context, index) {
        if (index >= count) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Center(
              child: _FrostButton(
                label: 'Show more',
                active: false,
                onTap: onShowMore,
              ),
            ),
          );
        }

        final mosque = mosques[index];
        final isFav = favouriteIds.contains(mosque.id);
        final distance = (userLocation != null && mosque.location != null)
            ? haversineKm(userLocation!, mosque.location!)
            : null;
        final nowFrac = (now.hour + now.minute / 60.0) / 24.0;

        return GestureDetector(
          onTap: () => onMosqueTap(mosque),
          child: Container(
            margin: const EdgeInsets.only(bottom: 10),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.18),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    mosque.name,
                                    style: CTokens.serif(
                                      size: 16,
                                      w: FontWeight.w400,
                                    ),
                                  ),
                                ),
                                if (isFav)
                                  Text(
                                    '*',
                                    style: CTokens.body(
                                      size: 12,
                                      color: CTokens.gold,
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              mosqueLocationSummary(mosque),
                              style: CTokens.body(
                                size: 10,
                                color: CTokens.ink70,
                              ),
                            ),
                            const SizedBox(height: 8),
                            SizedBox(
                              height: 4,
                              child: LayoutBuilder(
                                builder: (context, constraints) {
                                  return Stack(
                                    clipBehavior: Clip.none,
                                    children: [
                                      Container(
                                        decoration: BoxDecoration(
                                          color: Colors.white
                                              .withValues(alpha: 0.15),
                                          borderRadius:
                                              BorderRadius.circular(2),
                                        ),
                                      ),
                                      Positioned(
                                        left:
                                            nowFrac * constraints.maxWidth - 4,
                                        top: -2,
                                        child: Container(
                                          width: 8,
                                          height: 8,
                                          decoration: BoxDecoration(
                                            color: CTokens.gold,
                                            borderRadius:
                                                BorderRadius.circular(4),
                                            boxShadow: [
                                              BoxShadow(
                                                color: CTokens.gold
                                                    .withValues(alpha: 0.6),
                                                blurRadius: 10,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 14),
                      Text(
                        distance != null
                            ? '${distance.toStringAsFixed(1)} km'
                            : userLocation == null
                                ? 'enable location'
                                : '',
                        style: CTokens.mono(size: 14),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _FrostButton extends StatelessWidget {
  const _FrostButton({
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
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: active
              ? Colors.white.withValues(alpha: 0.28)
              : Colors.white.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: active ? CTokens.gold : Colors.white.withValues(alpha: 0.18),
          ),
        ),
        child: Text(
          label,
          style: CTokens.body(
            size: 11,
            color: active ? CTokens.gold : CTokens.ink70,
          ),
        ),
      ),
    );
  }
}
