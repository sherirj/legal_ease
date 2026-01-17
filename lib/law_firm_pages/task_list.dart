import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class Task {
  String id;
  String title;
  bool completed;

  Task({required this.id, required this.title, this.completed = false});
}

class TaskListPage extends StatefulWidget {
  const TaskListPage({super.key});

  @override
  State<TaskListPage> createState() => _TaskListPageState();
}

class _TaskListPageState extends State<TaskListPage> {
  final CollectionReference tasksCollection =
      FirebaseFirestore.instance.collection('tasks');

  final TextEditingController _taskController = TextEditingController();
  final Color gold = const Color(0xFFD4AF37); // Premium gold

  Future<void> _addTask(String title) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please login first')),
      );
      return;
    }

    try {
      await tasksCollection.add({
        'title': title,
        'completed': false,
        'userId': user.uid,
        'createdAt': FieldValue.serverTimestamp(),
      });
      _taskController.clear();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error adding task: $e')),
      );
    }
  }

  Future<void> _updateTask(String taskId, bool completed) async {
    if (completed) {
      // Delete the task when marked complete
      await tasksCollection.doc(taskId).delete();
    } else {
      // Update the completed status
      await tasksCollection.doc(taskId).update({'completed': completed});
    }
  }

  Future<void> _deleteTask(String taskId) async {
    await tasksCollection.doc(taskId).delete();
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Container(
      color: Colors.black,
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Text(
            'Task List',
            style: TextStyle(
              color: gold,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          // Add Task Field
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _taskController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Add new task...',
                    hintStyle: TextStyle(color: gold.withOpacity(0.7)),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: gold),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: gold, width: 2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.grey.shade900,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () {
                  if (_taskController.text.trim().isNotEmpty) {
                    _addTask(_taskController.text.trim());
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: gold,
                ),
                child: const Icon(Icons.add, color: Colors.black),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Task List
          Expanded(
            child: user != null
                ? StreamBuilder<QuerySnapshot>(
                    stream: tasksCollection
                        .where('userId', isEqualTo: user.uid)
                        .orderBy('createdAt', descending: true)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                          child: CircularProgressIndicator(color: Colors.amber),
                        );
                      }

                      if (snapshot.hasError) {
                        return Center(
                          child: Text(
                            'Error: ${snapshot.error}',
                            style: TextStyle(color: gold.withOpacity(0.7)),
                          ),
                        );
                      }

                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return Center(
                          child: Text(
                            'No tasks yet',
                            style: TextStyle(color: gold.withOpacity(0.7)),
                          ),
                        );
                      }

                      final tasks = snapshot.data!.docs
                          .map((doc) => Task(
                                id: doc.id,
                                title: doc['title'] ?? 'Untitled',
                                completed: doc['completed'] ?? false,
                              ))
                          .toList();

                      return ListView.builder(
                        itemCount: tasks.length,
                        itemBuilder: (context, index) {
                          final task = tasks[index];
                          return Card(
                            color: Colors.grey.shade900,
                            margin: const EdgeInsets.symmetric(vertical: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                              side: BorderSide(
                                  color: gold.withOpacity(0.3), width: 1),
                            ),
                            child: ListTile(
                              leading: Checkbox(
                                value: task.completed,
                                activeColor: gold,
                                checkColor: Colors.black,
                                onChanged: (value) {
                                  _updateTask(task.id, value ?? false);
                                },
                              ),
                              title: Text(
                                task.title,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              trailing: IconButton(
                                icon: Icon(Icons.delete_outline, color: gold),
                                onPressed: () => _deleteTask(task.id),
                              ),
                            ),
                          );
                        },
                      );
                    },
                  )
                : Center(
                    child: Text(
                      'Please login to see tasks',
                      style: TextStyle(color: gold.withOpacity(0.7)),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
