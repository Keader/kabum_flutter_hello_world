import 'dart:async';
import 'package:floor/floor.dart';
import 'package:kabumflutterhelloworld/appDB/watch.dart';
import 'package:sqflite/sqflite.dart' as sqflite;

part 'appDatabase.g.dart'; // the generated code will be there

@Database(version: 1, entities: [Watch])
abstract class AppDatabase extends FloorDatabase {
  WatchDao get watchDao;
}

/*final migration1to2 = Migration(1, 2, (database) async {
  await database.execute('ALTER TABLE Watch modify column price DOUBLE');
});*/

class DB {
  AppDatabase database;
  WatchDao watchDB;

  DB(AppDatabase database) {
    this.database = database;
    watchDB = database.watchDao;
  }
}

