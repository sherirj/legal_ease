import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:file_picker/file_picker.dart';
import 'package:open_filex/open_filex.dart';
import 'web_utils.dart';

class LegalDocumentsPage extends StatefulWidget {
  const LegalDocumentsPage({super.key});

  @override
  State<LegalDocumentsPage> createState() => _LegalDocumentsPageState();
}

class _LegalDocumentsPageState extends State<LegalDocumentsPage> {
  final CollectionReference _docsRef =
      FirebaseFirestore.instance.collection('documents');

  bool _uploading = false;

  Future<void> _uploadDocument() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        allowMultiple: false,
        withData: kIsWeb,
        type: FileType.any,
      );

      if (result == null) {
        print('No file selected.');
        return;
      }

      final fileName = result.files.single.name;
      setState(() => _uploading = true);
      String downloadUrl = '';

      if (kIsWeb) {
        final bytes = result.files.single.bytes;
        if (bytes == null) throw 'File bytes are null on Web.';
        final ref = FirebaseStorage.instance.ref('documents/$fileName');
        await ref.putData(bytes);
        downloadUrl = await ref.getDownloadURL();
      } else {
        final path = result.files.single.path;
        if (path == null) throw 'File path is null on non-web platform.';
        final file = File(path);
        final ref = FirebaseStorage.instance.ref('documents/$fileName');
        await ref.putFile(file);
        downloadUrl = await ref.getDownloadURL();
      }

      await _docsRef.add({
        'name': fileName,
        'url': downloadUrl,
        'uploadedAt': FieldValue.serverTimestamp(),
      });

      print('✅ File uploaded: $fileName -> $downloadUrl');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.grey[850],
          content: Text(
            '✅ "$fileName" uploaded successfully!',
            style: const TextStyle(color: Color(0xFFd4af37)),
          ),
        ),
      );
    } catch (e, st) {
      print('⚠️ Upload failed: $e\n$st');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red.shade900,
          content: Text('⚠️ Upload failed: $e'),
        ),
      );
    } finally {
      setState(() => _uploading = false);
    }
  }

  Future<void> _deleteDocument(String id, String name) async {
    try {
      await FirebaseStorage.instance.ref('documents/$name').delete();
      await _docsRef.doc(id).delete();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.grey[850],
          content: Text('🗑️ "$name" deleted',
              style: const TextStyle(color: Color(0xFFd4af37))),
        ),
      );
    } catch (e) {
      print('⚠️ Delete failed: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('⚠️ Delete failed: $e')),
      );
    }
  }

  Future<void> _openDocument(String url, String name) async {
    try {
      if (kIsWeb) {
        openUrl(url);
        return;
      }

      String filePath = url;

      if (Platform.isWindows) {
        final dir = Directory.systemTemp;
        final file = File('${dir.path}/$name');

        if (!await file.exists()) {
          final bytes = await HttpClient()
              .getUrl(Uri.parse(url))
              .then((req) => req.close())
              .then((res) => res.fold<List<int>>([], (a, b) => a..addAll(b)));
          await file.writeAsBytes(bytes);
        }

        filePath = file.path;
      }

      final result = await OpenFilex.open(filePath);
      if (result.type != ResultType.done) throw 'Could not open file.';
    } catch (e) {
      print('⚠️ Error opening "$name": $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('⚠️ Error opening "$name": $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFFd4af37),
        onPressed: _uploading ? null : _uploadDocument,
        child: _uploading
            ? const CircularProgressIndicator(color: Colors.black)
            : const Icon(Icons.upload_file, color: Colors.black),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: const [
                Icon(Icons.description, color: Color(0xFFd4af37)),
                SizedBox(width: 8),
                Text(
                  'Legal Documents',
                  style: TextStyle(
                    color: Color(0xFFd4af37),
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _docsRef
                    .orderBy('uploadedAt', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                        child: CircularProgressIndicator(
                            color: Color(0xFFd4af37)));
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(
                        child: Text('No documents found.',
                            style: TextStyle(color: Colors.white54)));
                  }

                  final docs = snapshot.data!.docs;

                  return ListView.builder(
                    itemCount: docs.length,
                    itemBuilder: (context, index) {
                      final doc = docs[index];
                      final data = doc.data() as Map<String, dynamic>;

                      return Card(
                        color: Colors.grey[900],
                        elevation: 3,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        child: ListTile(
                          leading: const Icon(Icons.insert_drive_file,
                              color: Color(0xFFd4af37), size: 32),
                          title: Text(
                            data['name'] ?? 'Unnamed Document',
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold),
                          ),
                          subtitle: const Text(
                            'Tap to open or long-press to delete',
                            style: TextStyle(color: Colors.white54),
                          ),
                          onTap: () => _openDocument(data['url'], data['name']),
                          onLongPress: () =>
                              _deleteDocument(doc.id, data['name']),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
