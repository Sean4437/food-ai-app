import 'dart:convert';
import 'dart:html' as html;
import 'data_exporter.dart';

class DataExporterImpl implements DataExporter {
  @override
  Future<void> saveJson(String filename, String content) async {
    final bytes = utf8.encode(content);
    final blob = html.Blob([bytes], 'application/json');
    final url = html.Url.createObjectUrlFromBlob(blob);
    final anchor = html.AnchorElement(href: url)
      ..download = filename
      ..style.display = 'none';
    html.document.body?.append(anchor);
    anchor.click();
    anchor.remove();
    html.Url.revokeObjectUrl(url);
  }
}
