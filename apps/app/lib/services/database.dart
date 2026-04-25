import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:prayer_times_data/data.dart';

Future<AppDatabase> openAppDatabase() async {
  final supportDirectory = await getApplicationSupportDirectory();
  final databaseDirectory = Directory(
    path.join(supportDirectory.path, 'prayer_times_app'),
  );
  if (!databaseDirectory.existsSync()) {
    databaseDirectory.createSync(recursive: true);
  }
  return AppDatabase.openFile(
    File(path.join(databaseDirectory.path, 'prayer_times.sqlite')),
  );
}
