import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:open_filex/open_filex.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/supabase_service.dart';
// import 'web_utils.dart'; // Removed unused import

class LegalDocumentsPage extends StatefulWidget {
  const LegalDocumentsPage({super.key});

  @override
  State<LegalDocumentsPage> createState() => _LegalDocumentsPageState();
}

class _LegalDocumentsPageState extends State<LegalDocumentsPage> {
  final CollectionReference _docsRef =
      FirebaseFirestore.instance.collection('documents');
  final User? _user = FirebaseAuth.instance.currentUser;

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

      setState(() => _uploading = true);

      final fileObj = result.files.single;
      final fileName = fileObj.name;

      String? downloadUrl;
      // Sanitize and create a unique name
      String sanitizedName = fileName.replaceAll(RegExp(r'\s+'), '_');
      String uniqueFileName =
          '${DateTime.now().millisecondsSinceEpoch}_$sanitizedName';

      if (kIsWeb) {
        if (fileObj.bytes != null) {
          downloadUrl =
              await SupabaseService.uploadBinary(fileObj.bytes!, uniqueFileName);
        } else {
          throw 'File bytes missing for Web upload';
        }
      } else if (fileObj.path != null) {
        final file = File(fileObj.path!);
        downloadUrl = await SupabaseService.uploadDocument(file, uniqueFileName);
      } else {
        throw 'File path unavailable';
      }

      if (downloadUrl == null) throw 'Upload failed (no URL returned).';

      await _docsRef.add({
        'name': fileName, // Original name for display
        'storageName': uniqueFileName, // Name in bucket
        'url': downloadUrl,
        'uploadedAt': FieldValue.serverTimestamp(),
        'userId': _user?.uid, // Track who uploaded
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
    } catch (e) {
      print('⚠️ Upload failed: $e');
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

  Future<void> _deleteDocument(String id, String url) async {
    try {
      // Delete from Supabase
      await SupabaseService.deleteDocument(url);

      // Delete from Firestore
      await _docsRef.doc(id).delete();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.grey[850],
          content: const Text('🗑️ Document deleted',
              style: TextStyle(color: Color(0xFFd4af37))),
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
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        throw 'Could not launch $url';
      }
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
                // Filter by user ID so they only see their own docs?
                // The prompt says "which document was uploaded by which user", implies some admin view,
                // but this is 'ClientPages', so usually they see their own.
                // However, I'll stick to showing ALL for now or filter if user exists.
                // Previous code didn't filter. I will add filter if user is logged in.
                stream: _user != null
                    ? _docsRef
                        .where('userId', isEqualTo: _user!.uid)
                        .orderBy('uploadedAt', descending: true)
                        .snapshots()
                    : _docsRef
                        .orderBy('uploadedAt', descending: true)
                        .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Text(
                          'Error loading documents: ${snapshot.error}',
                          style: const TextStyle(color: Colors.red),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    );
                  }

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
                      final name = data['name'] ?? 'Unnamed Document';
                      final url = data['url'] ?? '';

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
                            name,
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold),
                          ),
                          subtitle: const Text(
                            'Tap to open or long-press to delete',
                            style: TextStyle(color: Colors.white54),
                          ),
                          onTap: () => _openDocument(url, name),
                          onLongPress: () => _deleteDocument(doc.id, url),
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
