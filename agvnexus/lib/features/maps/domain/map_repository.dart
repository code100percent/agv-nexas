import 'map_model.dart';

abstract class MapRepository {
  Future<FactoryMapModel> getActiveMap();
  Future<List<StationModel>> getStations();
}
