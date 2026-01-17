import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/supabase_service.dart';

class FileUploadsPage extends StatefulWidget {
  const FileUploadsPage({super.key});

  @override
  State<FileUploadsPage> createState() => _FileUploadsPageState();
}

class _FileUploadsPageState extends State<FileUploadsPage> {
  final CollectionReference _docsRef =
      FirebaseFirestore.instance.collection('documents');
  final User? _user = FirebaseAuth.instance.currentUser;

  bool _uploading = false;

  Future<void> _uploadDocument() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        allowMultiple: false,
        type: FileType.any,
      );

      if (result == null) return;

      setState(() => _uploading = true);

      final fileObj = result.files.single;
      final fileName = fileObj.name;

      // Sanitize and create a unique name
      String sanitizedName = fileName.replaceAll(RegExp(r'\s+'), '_');
      String uniqueFileName =
          '${DateTime.now().millisecondsSinceEpoch}_$sanitizedName';
      String? downloadUrl;

      if (kIsWeb) {
        if (fileObj.bytes != null) {
          downloadUrl = await SupabaseService.uploadBinary(
              fileObj.bytes!, uniqueFileName);
        } else {
          throw 'File bytes missing for Web upload';
        }
      } else if (fileObj.path != null) {
        final file = File(fileObj.path!);
        downloadUrl =
            await SupabaseService.uploadDocument(file, uniqueFileName);
      } else {
        throw "File path not available";
      }

      if (downloadUrl == null) throw 'Upload failed.';

      await _docsRef.add({
        'name': fileName,
        'storageName': uniqueFileName,
        'url': downloadUrl,
        'uploadedAt': FieldValue.serverTimestamp(),
        'userId': _user?.uid,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.grey[850],
            content: Text('✅ Uploaded "$fileName"',
                style: const TextStyle(color: Color(0xFFd4af37))),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.red.shade900,
            content: Text('⚠️ Upload error: $e'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<void> _deleteDocument(String id, String url) async {
    try {
      await SupabaseService.deleteDocument(url);
      await _docsRef.doc(id).delete();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('🗑️ File deleted')),
        );
      }
    } catch (e) {
      print('Delete error: $e');
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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open file: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          Colors.white, // Keeping theme consistent with previous or default?
      // Previous code used Colors.brown.shade800 cards, implying a light or brown theme.
      // But LegalDocumentsPage was black. I'll stick to what the file implies or basic scaffold.
      // Let's use a background that fits 'Law Firm' - maybe white/cream?
      body: StreamBuilder<QuerySnapshot>(
        stream: _user != null
            ? _docsRef
                .where('userId', isEqualTo: _user!.uid)
                .orderBy('uploadedAt', descending: true)
                .snapshots()
            : _docsRef.orderBy('uploadedAt', descending: true).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
                child: Text('Error: ${snapshot.error}',
                    style: const TextStyle(color: Colors.red)));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data?.docs ?? [];

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                'File Uploads',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Colors.brown.shade700, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              if (docs.isEmpty)
                const Center(
                    child: Padding(
                  padding: EdgeInsets.all(32.0),
                  child: Text("No documents uploaded yet."),
                )),
              ...docs.map((doc) {
                final data = doc.data() as Map<String, dynamic>;
                final name = data['name'] ?? 'Document';
                final url = data['url'] ?? '';

                return Card(
                  color: Colors.brown.shade800,
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  child: ListTile(
                    leading: Icon(Icons.insert_drive_file_outlined,
                        color: Colors.brown.shade300),
                    title:
                        Text(name, style: const TextStyle(color: Colors.white)),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(Icons.open_in_new,
                              color: Colors.brown.shade300),
                          onPressed: () => _openDocument(url, name),
                        ),
                        IconButton(
                          icon:
                              const Icon(Icons.delete, color: Colors.redAccent),
                          onPressed: () => _deleteDocument(doc.id, url),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(), // using .toList() (though map returns iterable, spread operator works)

              // Keeping the "files.map" structure from before but interactive now

              const SizedBox(height: 24),
              ElevatedButton.icon(
                icon: _uploading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(color: Colors.white))
                    : const Icon(Icons.file_upload),
                label: Text(_uploading ? 'Uploading...' : 'Upload New File'),
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.brown.shade700,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12))),
                onPressed: _uploading ? null : _uploadDocument,
              ),
            ],
          );
        },
      ),
    );
  }
}
