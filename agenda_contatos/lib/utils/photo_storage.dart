import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Guarda a foto escolhida/tirada de forma permanente.
///
/// O `image_picker` devolve um arquivo temporário (cache) que o Android pode
/// apagar a qualquer momento. Por isso a foto é copiada para a pasta de
/// documentos do app e só o caminho dela é salvo no SQLite.
///
/// Na web não existe sistema de arquivos: a imagem vira um data URI (base64).
Future<String> persistPhoto(XFile image) async {
  if (kIsWeb) {
    final bytes = await image.readAsBytes();
    return 'data:image/jpeg;base64,${base64Encode(bytes)}';
  }

  final docsDir = await getApplicationDocumentsDirectory();
  final photosDir = Directory(p.join(docsDir.path, 'contact_photos'));
  if (!await photosDir.exists()) {
    await photosDir.create(recursive: true);
  }

  var extension = p.extension(image.path);
  if (extension.isEmpty) extension = '.jpg';

  final fileName = 'contact_${DateTime.now().millisecondsSinceEpoch}$extension';
  final saved = await File(image.path).copy(p.join(photosDir.path, fileName));
  return saved.path;
}

/// Devolve o [ImageProvider] da foto salva ou `null` se não houver foto
/// (ou se o arquivo não existir mais).
ImageProvider<Object>? contactPhotoProvider(String? img) {
  if (img == null || img.isEmpty) return null;

  if (kIsWeb) {
    if (img.startsWith('data:image/')) {
      return MemoryImage(base64Decode(img.split(',').last));
    }
    return null;
  }

  final file = File(img);
  if (file.existsSync()) {
    return FileImage(file);
  }
  return null;
}
