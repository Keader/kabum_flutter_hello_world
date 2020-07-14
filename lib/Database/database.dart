import 'dart:async';
import 'package:floor/floor.dart';
import 'package:kabumflutterhelloworld/Database/watch.dart';
import 'package:sqflite/sqflite.dart' as sqflite;

part 'database.g.dart'; // the generated code will be there

@Database(version: 1, entities: [Watch])
abstract class AppDatabase extends FloorDatabase {
  WatchDao get watchDao;
}
