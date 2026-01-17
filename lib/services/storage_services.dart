import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';

class StorageService {
  final _storage = FirebaseStorage.instance;

  Future<String> uploadFile({
    required File file,
    required String chatId,
    required String filename,
    void Function(double)? onProgress,
  }) async {
    final ref = _storage.ref().child('chat_attachments').child(chatId).child(filename);
    final uploadTask = ref.putFile(file);

    uploadTask.snapshotEvents.listen((snapshot) {
      final progress = snapshot.bytesTransferred / (snapshot.totalBytes ?? 1);
      if (onProgress != null) onProgress(progress);
    });

    final snapshot = await uploadTask;
    final downloadUrl = await snapshot.ref.getDownloadURL();
    return downloadUrl;
  }
}
