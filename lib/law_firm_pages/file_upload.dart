import 'package:flutter/material.dart';

class FileUploadsPage extends StatelessWidget {
  const FileUploadsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final files = [
      'Contract_2024.pdf',
      'Client_Agreement.docx',
      'Case_Notes_05July.pdf',
      'Evidence_Photos.zip',
    ];

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'File Uploads',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Colors.brown.shade300, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        ...files.map(
          (file) => Card(
            color: Colors.brown.shade800,
            margin: const EdgeInsets.symmetric(vertical: 8),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: ListTile(
              leading: Icon(Icons.insert_drive_file_outlined,
                  color: Colors.brown.shade300),
              title: Text(file, style: const TextStyle(color: Colors.white)),
              trailing: IconButton(
                icon: Icon(Icons.upload_file_outlined,
                    color: Colors.brown.shade300),
                tooltip: 'Upload file',
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Upload pressed for $file')),
                  );
                },
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
        ElevatedButton.icon(
          icon: const Icon(Icons.file_upload),
          label: const Text('Upload New File'),
          style: ElevatedButton.styleFrom(
              backgroundColor: Colors.brown.shade700,
              minimumSize: const Size(double.infinity, 50),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12))),
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Upload New File pressed')),
            );
          },
        ),
      ],
    );
  }
}
