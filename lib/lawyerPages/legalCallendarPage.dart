import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart'; // For formatting Timestamp

class LegalCalendarPage extends StatelessWidget {
  const LegalCalendarPage({super.key});

  @override
  Widget build(BuildContext context) {
    final bookingsCollection =
        FirebaseFirestore.instance.collection('bookings');

    return Scaffold(
      backgroundColor: Colors.black,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Text(
              'Legal Calendar',
              style: TextStyle(
                color: Color(0xFFd4af37),
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: bookingsCollection.orderBy('date').snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFFd4af37),
                      ),
                    );
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(
                      child: Text(
                        'No bookings found',
                        style: TextStyle(color: Colors.white54),
                      ),
                    );
                  }

                  final events = snapshot.data!.docs;

                  return ListView.builder(
                    itemCount: events.length,
                    itemBuilder: (context, index) {
                      final eventData =
                          events[index].data() as Map<String, dynamic>;

                      // Handle both Timestamp and String dates
                      String eventDate = '';
                      final rawDate = eventData['date'];
                      if (rawDate is Timestamp) {
                        eventDate =
                            DateFormat('yyyy-MM-dd').format(rawDate.toDate());
                      } else if (rawDate is String) {
                        eventDate = rawDate;
                      }

                      final eventName = eventData['event'] ?? 'No Title';

                      return Card(
                        color: Colors.grey[900],
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: ListTile(
                          leading: const Icon(
                            Icons.event_note_outlined,
                            color: Color(0xFFd4af37),
                          ),
                          title: Text(
                            eventName,
                            style: const TextStyle(color: Colors.white),
                          ),
                          subtitle: Text(
                            eventDate,
                            style: const TextStyle(color: Colors.white54),
                          ),
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
