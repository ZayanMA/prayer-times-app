import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

const _overpassUrl = 'https://overpass-api.de/api/interpreter';

const _query = '''
[out:json][timeout:300];
area["ISO3166-1"="GB"][admin_level=2]->.uk;
(
  node["amenity"="place_of_worship"]["religion"="muslim"](area.uk);
  way["amenity"="place_of_worship"]["religion"="muslim"](area.uk);
  relation["amenity"="place_of_worship"]["religion"="muslim"](area.uk);
);
out center tags;
''';

Future<void> main(List<String> args) async {
  final outDir = args.isEmpty
      ? Directory('server/catalog/v1')
      : Directory('${args.first}/server/catalog/v1');
  outDir.createSync(recursive: true);

  stdout.writeln('Querying Overpass API...');
  final response = await http.post(
    Uri.parse(_overpassUrl),
    body: {'data': _query},
    headers: {'User-Agent': 'prayer-times-app-seed/1.0'},
  );
  if (response.statusCode != 200) {
    stderr.writeln('Overpass returned HTTP ${response.statusCode}');
    stderr.writeln(response.body.substring(0, 500));
    exitCode = 1;
    return;
  }

  final body = jsonDecode(response.body) as Map<String, dynamic>;
  final elements = (body['elements'] as List<dynamic>).cast<Map<String, dynamic>>();
  stdout.writeln('Received ${elements.length} elements.');

  final mosques = <Map<String, Object?>>[];
  final seenIds = <String>{};
  final now = DateTime.now().toUtc().toIso8601String();

  for (final el in elements) {
    final tags = (el['tags'] as Map?)?.cast<String, dynamic>() ?? const {};
    final name = (tags['name'] as String?)?.trim();
    if (name == null || name.isEmpty) continue;

    double? lat;
    double? lng;
    if (el['type'] == 'node') {
      lat = _toDouble(el['lat']);
      lng = _toDouble(el['lon']);
    } else {
      final center = (el['center'] as Map?)?.cast<String, dynamic>();
      lat = _toDouble(center?['lat']);
      lng = _toDouble(center?['lon']);
    }
    if (lat == null || lng == null) continue;

    final osmType = el['type'] as String;
    final osmId = el['id'].toString();
    final id = 'osm-$osmType-$osmId';
    if (!seenIds.add(id)) continue;

    final slug = '${_slugify(name)}-$osmId';

    final postcode = (tags['addr:postcode'] as String?)?.trim();
    final street = (tags['addr:street'] as String?)?.trim();
    final houseNumber = (tags['addr:housenumber'] as String?)?.trim();
    final addressParts = <String>[
      if (houseNumber != null && houseNumber.isNotEmpty) houseNumber,
      if (street != null && street.isNotEmpty) street,
    ];
    final addressLine = addressParts.isEmpty ? null : addressParts.join(' ');

    final city = ((tags['addr:city'] as String?) ??
            (tags['addr:town'] as String?) ??
            (tags['addr:suburb'] as String?) ??
            '')
        .trim();
    final area = ((tags['addr:suburb'] as String?) ??
            (tags['addr:district'] as String?) ??
            (tags['addr:hamlet'] as String?) ??
            city)
        .trim();

    final website = (tags['website'] as String?) ??
        (tags['contact:website'] as String?) ??
        '';

    mosques.add({
      'id': id,
      'name': name,
      'slug': slug,
      'area': area.isEmpty ? 'Unknown' : area,
      'city': city.isEmpty ? 'Unknown' : city,
      'websiteUrl': website,
      'sourceKind': 'calculated',
      'updatedAt': now,
      'isActive': true,
      'latitude': lat,
      'longitude': lng,
      if (postcode != null && postcode.isNotEmpty) 'postcode': postcode,
      if (addressLine != null) 'addressLine': addressLine,
    });
  }

  // Merge in any curated mosques from server/source_config/mosques.json so
  // hand-tuned adapters (web table / pdf) coexist with the OSM bulk seed.
  final curatedConfig = File(
    args.isEmpty
        ? 'server/source_config/mosques.json'
        : '${args.first}/server/source_config/mosques.json',
  );
  if (curatedConfig.existsSync()) {
    final curated = jsonDecode(curatedConfig.readAsStringSync())
        as Map<String, dynamic>;
    final entries =
        (curated['mosques'] as List<dynamic>).cast<Map<String, dynamic>>();
    for (final entry in entries) {
      seenIds.add(entry['id'] as String);
      mosques.add({
        'id': entry['id'],
        'name': entry['name'],
        'slug': entry['slug'],
        'area': entry['area'],
        'city': entry['city'],
        'websiteUrl': entry['websiteUrl'],
        'sourceKind': entry['sourceKind'],
        'updatedAt': now,
        'isActive': entry['isActive'] ?? true,
        if (entry['latitude'] != null) 'latitude': entry['latitude'],
        if (entry['longitude'] != null) 'longitude': entry['longitude'],
        if (entry['postcode'] != null) 'postcode': entry['postcode'],
        if (entry['addressLine'] != null) 'addressLine': entry['addressLine'],
      });
    }
  }

  mosques.sort((a, b) => (a['name'] as String).compareTo(b['name'] as String));

  final out = {
    'generatedAt': now,
    'attribution':
        'Mosque locations © OpenStreetMap contributors, ODbL (https://www.openstreetmap.org/copyright)',
    'mosques': mosques,
  };

  final file = File('${outDir.path}/mosques.json');
  file.writeAsStringSync(const JsonEncoder.withIndent('  ').convert(out));
  stdout.writeln('Wrote ${mosques.length} mosques to ${file.path}');
}

double? _toDouble(Object? value) {
  if (value == null) return null;
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value);
  return null;
}

String _slugify(String input) {
  final lower = input.toLowerCase();
  final replaced = lower.replaceAll(RegExp(r'[^a-z0-9]+'), '-');
  return replaced.replaceAll(RegExp(r'^-+|-+$'), '');
}
