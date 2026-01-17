import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DatabaseManagerPage extends StatefulWidget {
  const DatabaseManagerPage({super.key});

  @override
  State<DatabaseManagerPage> createState() => _DatabaseManagerPageState();
}

class _DatabaseManagerPageState extends State<DatabaseManagerPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final List<String> _tabs = [
    'Clients',
    'Cases',
    'Bookings',
    'Messages',
    'Documents'
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Widget _buildCrudList(String collectionName, List<String> fields) {
    final CollectionReference collection =
        FirebaseFirestore.instance.collection(collectionName);

    return StreamBuilder<QuerySnapshot>(
      stream: collection.orderBy('updatedAt', descending: true).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
              child: CircularProgressIndicator(color: Colors.brown));
        }

        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) {
          return const Center(
            child: Text("No records found.",
                style: TextStyle(color: Colors.white70)),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(8),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final doc = docs[index];
            return Card(
              color: Colors.brown.shade800,
              margin: const EdgeInsets.symmetric(vertical: 6),
              child: ListTile(
                title: Text(
                  doc.id,
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  fields.map((f) => "$f: ${doc[f] ?? '-'}").join("\n"),
                  style: const TextStyle(color: Colors.white70),
                ),
                trailing: PopupMenuButton<String>(
                  color: Colors.brown.shade900,
                  onSelected: (value) async {
                    if (value == 'edit') {
                      _showCrudDialog(collectionName, fields, doc: doc);
                    } else if (value == 'delete') {
                      await collection.doc(doc.id).delete();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('🗑️ Record deleted successfully.')),
                      );
                    }
                  },
                  itemBuilder: (_) => const [
                    PopupMenuItem(value: 'edit', child: Text('Edit')),
                    PopupMenuItem(value: 'delete', child: Text('Delete')),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showCrudDialog(String collectionName, List<String> fields,
      {DocumentSnapshot? doc}) {
    final Map<String, TextEditingController> controllers = {
      for (var f in fields)
        f: TextEditingController(text: doc != null ? doc[f]?.toString() ?? '' : '')
    };

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.brown.shade900,
        title: Text(
          doc == null
              ? 'Add to $collectionName'
              : 'Edit ${doc.id} in $collectionName',
          style: const TextStyle(color: Colors.white),
        ),
        content: SingleChildScrollView(
          child: Column(
            children: [
              for (var f in fields)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: TextField(
                    controller: controllers[f],
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: f,
                      labelStyle: const TextStyle(color: Colors.white70),
                      enabledBorder: const OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.white30)),
                      focusedBorder: const OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.brown)),
                    ),
                  ),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child:
                const Text('Cancel', style: TextStyle(color: Colors.white70)),
          ),
          ElevatedButton(
            style:
                ElevatedButton.styleFrom(backgroundColor: Colors.brown.shade700),
            onPressed: () async {
              final Map<String, dynamic> data = {
                for (var f in fields) f: controllers[f]!.text.trim(),
                'updatedAt': Timestamp.now(),
              };

              final col = FirebaseFirestore.instance.collection(collectionName);

              if (doc == null) {
                await col.add(data);
                ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('✅ Record Added')));
              } else {
                await col.doc(doc.id).update(data);
                ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('✅ Record Updated')));
              }

              Navigator.pop(context);
            },
            child: Text(doc == null ? 'Add' : 'Save'),
          ),
        ],
      ),
    );
  }

  Widget _buildTab(String name) {
    switch (name) {
      case 'Clients':
        return _buildCrudList('clients', ['name', 'email', 'phone']);
      case 'Cases':
        return _buildCrudList(
            'cases', ['clientId', 'title', 'description', 'status', 'createdAt']);
      case 'Bookings':
        return _buildCrudList(
            'bookings', ['clientId', 'lawyerId', 'date', 'status']);
      case 'Messages':
        return _buildCrudList(
            'messages', ['clientId', 'lawyerId', 'message', 'createdAt']);
      case 'Documents':
        return _buildCrudList(
            'documents', ['clientId', 'name', 'url', 'uploadedAt']);
      default:
        return const Center(child: Text("Unknown tab"));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Database Manager'),
        backgroundColor: Colors.brown.shade700,
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: Colors.white,
          tabs: _tabs.map((t) => Tab(text: t)).toList(),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.brown.shade700,
        onPressed: () {
          final currentTab = _tabs[_tabController.index];
          final fields = _getFieldsForCollection(currentTab);
          _showCrudDialog(currentTab.toLowerCase(), fields);
        },
        child: const Icon(Icons.add),
      ),
      body: TabBarView(
        controller: _tabController,
        children: _tabs.map(_buildTab).toList(),
      ),
    );
  }

  List<String> _getFieldsForCollection(String tabName) {
    switch (tabName) {
      case 'Clients':
        return ['name', 'email', 'phone'];
      case 'Cases':
        return ['clientId', 'title', 'description', 'status', 'createdAt'];
      case 'Bookings':
        return ['clientId', 'lawyerId', 'date', 'status'];
      case 'Messages':
        return ['clientId', 'lawyerId', 'message', 'createdAt'];
      case 'Documents':
        return ['clientId', 'name', 'url', 'uploadedAt'];
      default:
        return [];
    }
  }
}