import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../services/supabase_service.dart';

class DocumentUploadWidget extends StatefulWidget {
  final Function(String url)? onUploadComplete;

  const DocumentUploadWidget({super.key, this.onUploadComplete});

  @override
  State<DocumentUploadWidget> createState() => _DocumentUploadWidgetState();
}

class _DocumentUploadWidgetState extends State<DocumentUploadWidget> {
  bool _isUploading = false;
  String? _uploadStatus;

  Future<void> _pickAndUpload() async {
    try {
      // 1. Pick File
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'png', 'doc', 'docx'],
      );

      if (result != null) {
        final fileObj = result.files.single;
        if (kIsWeb ? fileObj.bytes == null : fileObj.path == null) return;

        setState(() {
          _isUploading = true;
          _uploadStatus = "Uploading to Supabase...";
        });

        // Sanitize filename
        String originalName = fileObj.name;
        String sanitizedName = originalName.replaceAll(RegExp(r'\s+'), '_');
        String fileName =
            '${DateTime.now().millisecondsSinceEpoch}_$sanitizedName';

        // 2. Upload to Supabase
        String? publicUrl;
        if (kIsWeb) {
          publicUrl =
              await SupabaseService.uploadBinary(fileObj.bytes!, fileName);
        } else {
          File file = File(fileObj.path!);
          publicUrl = await SupabaseService.uploadDocument(file, fileName);
        }

        if (publicUrl != null) {
          setState(() {
            _uploadStatus = "Saving metadata...";
          });

          // 3. Save Metadata to Firestore
          final user = FirebaseAuth.instance.currentUser;
          if (user != null) {
            await FirebaseFirestore.instance.collection('user_documents').add({
              'userId': user.uid,
              'url': publicUrl,
              'fileName': originalName,
              'uploadedAt': FieldValue.serverTimestamp(),
              'fileType': result.files.single.extension,
            });
          }

          setState(() {
            _uploadStatus = "Upload Complete!";
            _isUploading = false;
          });

          if (widget.onUploadComplete != null) {
            widget.onUploadComplete!(publicUrl);
          }
        }
      }
    } catch (e) {
      setState(() {
        _isUploading = false;
        _uploadStatus = "Error: $e";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            "Upload Document",
            style: TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 12),
          Center(
            child: ElevatedButton.icon(
              onPressed: _isUploading ? null : _pickAndUpload,
              icon: _isUploading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.black))
                  : const Icon(Icons.cloud_upload),
              label: Text(_isUploading ? 'Uploading...' : 'Select File'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFd4af37), // Gold theme
                foregroundColor: Colors.black,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ),
          if (_uploadStatus != null) ...[
            const SizedBox(height: 12),
            Center(
              child: Text(
                _uploadStatus!,
                style: TextStyle(
                    color: _uploadStatus!.startsWith("Error")
                        ? Colors.redAccent
                        : Colors.greenAccent,
                    fontSize: 13),
              ),
            ),
          ]
        ],
      ),
    );
  }
}
