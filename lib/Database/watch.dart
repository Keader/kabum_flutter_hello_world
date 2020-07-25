import 'package:floor/floor.dart';

@entity
class Watch {
  @primaryKey
  final int id;
  double price;
  int flags;

  Watch(this.id, this.price, this.flags);
}

@dao
abstract class WatchDao {

  @Query('SELECT * FROM Watch')
  Future<List<Watch>> findAllWatchs();

  @Query('SELECT * FROM Watch WHERE id = :id')
  Future<Watch> findWatchById(int id);

  @Query('DELETE FROM Watch WHERE id = :id')
  Future<void> deleteById(int id);

  @Query('DELETE FROM Watch')
  Future<void> deleteAllWatchs();

  @Insert(onConflict: OnConflictStrategy.replace)
  Future<void> insertWatch(Watch watch);

}
