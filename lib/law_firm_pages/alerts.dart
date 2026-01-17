import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class Alert {
  String id;
  String title;
  DateTime scheduledDate;
  String alertType;
  bool read;

  Alert({
    required this.id,
    required this.title,
    required this.scheduledDate,
    required this.alertType,
    this.read = false,
  });
}

class AlertsPage extends StatefulWidget {
  const AlertsPage({super.key});

  @override
  State<AlertsPage> createState() => _AlertsPageState();
}

class _AlertsPageState extends State<AlertsPage> {
  final CollectionReference alertsCollection =
      FirebaseFirestore.instance.collection('alerts');
  final Color gold = const Color(0xFFD4AF37);

  final TextEditingController _alertTitleController = TextEditingController();
  final TextEditingController _alertTypeController = TextEditingController();
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;

  Future<void> _addAlert() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please login first')),
      );
      return;
    }

    if (_alertTitleController.text.trim().isEmpty ||
        _selectedDate == null ||
        _selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all fields')),
      );
      return;
    }

    try {
      final scheduledDateTime = DateTime(
        _selectedDate!.year,
        _selectedDate!.month,
        _selectedDate!.day,
        _selectedTime!.hour,
        _selectedTime!.minute,
      );

      await alertsCollection.add({
        'title': _alertTitleController.text.trim(),
        'alertType': _alertTypeController.text.trim(),
        'scheduledDate': scheduledDateTime,
        'createdBy': user.uid,
        'read': false,
        'createdAt': FieldValue.serverTimestamp(),
      });

      _alertTitleController.clear();
      _alertTypeController.clear();
      _selectedDate = null;
      _selectedTime = null;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Alert scheduled successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Future<void> _deleteAlert(String alertId) async {
    await alertsCollection.doc(alertId).delete();
  }

  Future<void> _markAsRead(String alertId, bool currentStatus) async {
    await alertsCollection.doc(alertId).update({'read': !currentStatus});
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Container(
      color: Colors.black,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Alerts & Scheduling',
            style: TextStyle(
              color: gold,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),

          // Add Alert Form
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade900,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: gold.withOpacity(0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Schedule New Alert',
                  style: TextStyle(
                    color: gold,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _alertTitleController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Alert Title (e.g., Hearing reminder)',
                    hintStyle: TextStyle(color: gold.withOpacity(0.7)),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: gold),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: gold, width: 2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    filled: true,
                    fillColor: Colors.black,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _alertTypeController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Alert Type (e.g., Case #2023)',
                    hintStyle: TextStyle(color: gold.withOpacity(0.7)),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: gold),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: gold, width: 2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    filled: true,
                    fillColor: Colors.black,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: DateTime.now(),
                            firstDate: DateTime.now(),
                            lastDate: DateTime.now().add(
                              const Duration(days: 365),
                            ),
                          );
                          if (date != null) {
                            setState(() => _selectedDate = date);
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            border: Border.all(color: gold),
                            borderRadius: BorderRadius.circular(8),
                            color: Colors.black,
                          ),
                          child: Text(
                            _selectedDate == null
                                ? 'Select Date'
                                : '${_selectedDate!.toLocal()}'.split(' ')[0],
                            style: TextStyle(
                              color: _selectedDate == null
                                  ? gold.withOpacity(0.7)
                                  : Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: GestureDetector(
                        onTap: () async {
                          final time = await showTimePicker(
                            context: context,
                            initialTime: TimeOfDay.now(),
                          );
                          if (time != null) {
                            setState(() => _selectedTime = time);
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            border: Border.all(color: gold),
                            borderRadius: BorderRadius.circular(8),
                            color: Colors.black,
                          ),
                          child: Text(
                            _selectedTime == null
                                ? 'Select Time'
                                : _selectedTime!.format(context),
                            style: TextStyle(
                              color: _selectedTime == null
                                  ? gold.withOpacity(0.7)
                                  : Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _addAlert,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: gold,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text(
                      'Schedule Alert',
                      style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          Text(
            'Scheduled Alerts',
            style: TextStyle(
              color: gold,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),

          // Alerts List
          user != null
              ? StreamBuilder<QuerySnapshot>(
                  stream: alertsCollection
                      .orderBy('scheduledDate', descending: false)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(color: Colors.amber),
                      );
                    }

                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return Center(
                        child: Text(
                          'No alerts scheduled',
                          style: TextStyle(color: gold.withOpacity(0.7)),
                        ),
                      );
                    }

                    final alerts = snapshot.data!.docs
                        .map((doc) => Alert(
                              id: doc.id,
                              title: doc['title'],
                              scheduledDate:
                                  (doc['scheduledDate'] as Timestamp).toDate(),
                              alertType: doc['alertType'] ?? 'General',
                              read: doc['read'] ?? false,
                            ))
                        .toList();

                    return Column(
                      children: alerts.map((alert) {
                        return Card(
                          color: alert.read
                              ? Colors.grey.shade800
                              : Colors.grey.shade900,
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(
                              color: alert.read
                                  ? gold.withOpacity(0.2)
                                  : gold.withOpacity(0.5),
                            ),
                          ),
                          child: ListTile(
                            leading: GestureDetector(
                              onTap: () => _markAsRead(alert.id, alert.read),
                              child: Icon(
                                alert.read
                                    ? Icons.check_circle
                                    : Icons.circle_outlined,
                                color: gold,
                              ),
                            ),
                            title: Text(
                              alert.title,
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w500,
                                decoration: alert.read
                                    ? TextDecoration.lineThrough
                                    : null,
                              ),
                            ),
                            subtitle: Text(
                              '${alert.alertType} • ${alert.scheduledDate.toString().substring(0, 16)}',
                              style: TextStyle(
                                  color: gold.withOpacity(0.7), fontSize: 12),
                            ),
                            trailing: IconButton(
                              icon: Icon(Icons.delete_outline, color: gold),
                              onPressed: () => _deleteAlert(alert.id),
                            ),
                          ),
                        );
                      }).toList(),
                    );
                  },
                )
              : Center(
                  child: Text(
                    'Please login to manage alerts',
                    style: TextStyle(color: gold.withOpacity(0.7)),
                  ),
                ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _alertTitleController.dispose();
    _alertTypeController.dispose();
    super.dispose();
  }
}
