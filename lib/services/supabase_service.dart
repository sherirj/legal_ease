import 'dart:io';
import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  static final SupabaseClient _client = Supabase.instance.client;
  static const String _bucket = 'LegalDocuments';

  /// Uploads a file to the 'LegalDocuments' bucket.
  /// Returns the public URL of the uploaded file.
  static Future<String?> uploadDocument(File file, String fileName) async {
    try {
      final String path = 'uploads/$fileName';

      await _client.storage.from(_bucket).upload(
            path,
            file,
            fileOptions: const FileOptions(cacheControl: '3600', upsert: true),
          );

      // Get Public URL
      final String publicUrl = _client.storage.from(_bucket).getPublicUrl(path);
      return publicUrl;
    } catch (e) {
      print('Supabase Upload Error: $e');
      rethrow;
    }
  }

  /// Uploads binary data (Uint8List) to the 'LegalDocuments' bucket.
  /// Useful for Web where File path is not available.
  static Future<String?> uploadBinary(Uint8List data, String fileName) async {
    try {
      final String path = 'uploads/$fileName';

      await _client.storage.from(_bucket).uploadBinary(
            path,
            data,
            fileOptions: const FileOptions(cacheControl: '3600', upsert: true),
          );

      // Get Public URL
      final String publicUrl = _client.storage.from(_bucket).getPublicUrl(path);
      return publicUrl;
    } catch (e) {
      print('Supabase Binary Upload Error: $e');
      rethrow;
    }
  }

  /// Deletes a file from the 'LegalDocuments' bucket.
  static Future<void> deleteDocument(String pathOrUrl) async {
    try {
      // Extract path from URL if needed.
      // Assuming the URL involves the bucket name.
      // If we store the full URL in Firestore, we need to parse it or just store the path separately.
      // For simplicity in this project, let's try to extract the path.

      String path = pathOrUrl;
      if (pathOrUrl.startsWith('http')) {
        // Typical Supabase URL: https://<project>.supabase.co/storage/v1/object/public/<bucket>/<path>
        final uri = Uri.parse(pathOrUrl);
        final segments = uri.pathSegments;
        // segments: [storage, v1, object, public, LegalDocuments, uploads, filename.pdf]
        // We want: uploads/filename.pdf
        if (segments.contains('public')) {
          final bucketIndex = segments.indexOf(_bucket);
          if (bucketIndex != -1 && bucketIndex + 1 < segments.length) {
            path = segments.sublist(bucketIndex + 1).join('/');
          }
        }
      }

      await _client.storage.from(_bucket).remove([path]);
    } catch (e) {
      print('Supabase Delete Error: $e');
      rethrow;
    }
  }
}
