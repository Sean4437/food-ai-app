import 'data_exporter_stub.dart'
    if (dart.library.html) 'data_exporter_web.dart';

abstract class DataExporter {
  Future<void> saveJson(String filename, String content);
}

DataExporter createDataExporter() => DataExporterImpl();
