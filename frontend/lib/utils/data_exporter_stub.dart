import 'data_exporter.dart';

class DataExporterImpl implements DataExporter {
  @override
  Future<void> saveJson(String filename, String content) async {
    // Not supported in non-web builds.
  }
}
