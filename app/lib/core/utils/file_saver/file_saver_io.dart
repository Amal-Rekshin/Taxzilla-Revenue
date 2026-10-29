import 'dart:io';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';

Future<String> saveAndOpenFileImpl({
  required List<int> bytes,
  required String fileName,
}) async {
  final dir = await getApplicationDocumentsDirectory();
  final file = File('${dir.path}/$fileName');
  await file.writeAsBytes(bytes, flush: true);

  final openResult = await OpenFilex.open(file.path);
  if (openResult.type != ResultType.done) {
    return 'Saved to ${file.path} (${openResult.message})';
  }
  return file.path;
}

