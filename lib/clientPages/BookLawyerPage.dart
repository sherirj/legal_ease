import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:legal_ease/lawyerPages/lawyer_info.dart';
import 'lawfirm_info.dart';

class BookLawyerPage extends StatefulWidget {
  const BookLawyerPage({super.key});

  @override
  State<BookLawyerPage> createState() => _BookLawyerPageState();
}

class _BookLawyerPageState extends State<BookLawyerPage>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _descController = TextEditingController();
  DateTime? _selectedDate;
  bool _loading = true;

  // Lawyers
  List<Map<String, dynamic>> _lawyers = [];
  List<Map<String, dynamic>> _filteredLawyers = [];
  Map<String, bool> _lawyerAvailability = {};

  // Firms
  List<Map<String, dynamic>> _lawFirms = [];
  bool _loadingFirms = true;
  Map<String, bool> _firmAvailability = {};

  // Auth / client
  User? _currentUser;
  String _clientName = '';

  // Filters
  String? _selectedSpecialization;
  String _selectedRatingFilter = 'All';

  final List<String> _specializations = [
    'All',
    'General Law',
    'Criminal Law',
    'Corporate Law'
  ];

  final List<String> _ratingFilters = [
    'All',
    'Highly Rated (4+)',
    'Top Rated (4.5+)',
  ];

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _getCurrentUser();
    _fetchLawyers();
    _fetchLawFirms();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _descController.dispose();
    super.dispose();
  }

  void _getCurrentUser() {
    _currentUser = FirebaseAuth.instance.currentUser;
    if (_currentUser != null) {
      FirebaseFirestore.instance
          .collection('clients')
          .doc(_currentUser!.uid)
          .get()
          .then((doc) {
        if (doc.exists) {
          setState(() {
            _clientName = doc.data()?['name'] ?? 'Client';
          });
        }
      }).catchError((_) {
        // ignore
      });
    }
  }

  Future<void> _fetchLawyers() async {
    try {
      final snapshot =
          await FirebaseFirestore.instance.collection('lawyers').get();
      _lawyers = snapshot.docs.map((doc) {
        final data = doc.data();
        _lawyerAvailability[doc.id] = true;
        return {
          'id': doc.id,
          'name': data['name'] ?? 'Unnamed Lawyer',
          'specialization': data['specialization'] ?? 'General Law',
          'experience': data['experience'] ?? 'N/A',
          'avgRating': 0.0,
          'reviewCount': 0,
          'firmId': data['firmId'] ?? '',
          'hourlyRate': data['hourlyRate'] ?? 0,
        };
      }).toList();

      // load ratings per lawyer
      for (var i = 0; i < _lawyers.length; i++) {
        final lid = _lawyers[i]['id'];
        final rSnap = await FirebaseFirestore.instance
            .collection('ratings')
            .where('lawyerId', isEqualTo: lid)
            .get();
        if (rSnap.docs.isNotEmpty) {
          int sum = 0;
          for (var d in rSnap.docs) {
            final r = d.data()['rating'];
            sum += (r is int) ? r : int.tryParse(r.toString()) ?? 0;
          }
          _lawyers[i]['avgRating'] = sum / rSnap.docs.length;
          _lawyers[i]['reviewCount'] = rSnap.docs.length;
        }
      }

      _applyFilter();
      setState(() {
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('⚠️ Failed to load lawyers: $e')),
      );
    }
  }

  Future<void> _fetchLawFirms() async {
    try {
      final snap =
          await FirebaseFirestore.instance.collection('lawfirms').get();
      _lawFirms = snap.docs.map((doc) {
        final data = doc.data();
        _firmAvailability[doc.id] = true;
        return {
          'id': doc.id,
          'firmName': data['firmName'] ?? 'Unnamed Firm',
          'name': data['firmName'] ?? 'Unnamed Firm',
          'email': data['email'] ?? 'N/A',
          'location': data['location'] ?? 'N/A',
          'specialization': data['specialization'] ?? 'General Law',
          'createdAt': data['createdAt'],
        };
      }).toList();
      setState(() => _loadingFirms = false);
    } catch (e) {
      setState(() => _loadingFirms = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('⚠️ Failed to load law firms: $e')),
      );
    }
  }

  void _applyFilter() {
    setState(() {
      _filteredLawyers = _lawyers.where((lawyer) {
        if (_selectedSpecialization != null &&
            _selectedSpecialization != 'All') {
          if (lawyer['specialization'] != _selectedSpecialization) {
            return false;
          }
        }

        final avgRating = lawyer['avgRating'] ?? 0.0;
        if (_selectedRatingFilter == 'Highly Rated (4+)') {
          if (avgRating < 4.0) return false;
        } else if (_selectedRatingFilter == 'Top Rated (4.5+)') {
          if (avgRating < 4.5) return false;
        }

        return true;
      }).toList();

      _filteredLawyers.sort((a, b) {
        final ratingA = a['avgRating'] ?? 0.0;
        final ratingB = b['avgRating'] ?? 0.0;
        return ratingB.compareTo(ratingA);
      });
    });
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
      await _checkAllAvailability(picked);
    }
  }

  Future<void> _checkAllAvailability(DateTime date) async {
    final formatted = DateFormat('yyyy-MM-dd').format(date);

    final snapshot = await FirebaseFirestore.instance
        .collection('bookings')
        .where('date', isEqualTo: formatted)
        .get();

    Map<String, bool> lawyerAvail = {};
    Map<String, bool> firmAvail = {};

    for (var lawyer in _lawyers) {
      lawyerAvail[lawyer['id']] = true;
    }
    for (var firm in _lawFirms) {
      firmAvail[firm['id']] = true;
    }

    for (var doc in snapshot.docs) {
      final data = doc.data();
      final lawyerId = data['lawyerId'] as String?;
      final firmId = data['lawfirmId'] as String? ??
          data['lawFirmId'] as String? ??
          data['firmId'] as String?;
      if (lawyerId != null && lawyerId.isNotEmpty) {
        lawyerAvail[lawyerId] = false;
      }
      if (firmId != null && firmId.isNotEmpty) {
        firmAvail[firmId] = false;
      }
    }

    setState(() {
      _lawyerAvailability = lawyerAvail;
      _firmAvailability = firmAvail;
    });
  }

  Future<void> _book({
    required Map<String, dynamic> target,
    required String type,
  }) async {
    if (_descController.text.trim().isEmpty || _selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please enter case details and select a date')),
      );
      return;
    }

    if (_currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('⚠️ Please log in first')),
      );
      return;
    }

    final id = target['id'] as String;
    final isAvailable = (type == 'lawyer')
        ? (_lawyerAvailability[id] ?? true)
        : (_firmAvailability[id] ?? true);

    if (!isAvailable) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('⚠️ Already booked for this date')),
      );
      return;
    }

    try {
      final batch = FirebaseFirestore.instance.batch();
      final bookingRef =
          FirebaseFirestore.instance.collection('bookings').doc();
      final caseRef = FirebaseFirestore.instance.collection('cases').doc();

      final bookingData = {
        'clientId': _currentUser!.uid,
        'clientName': _clientName,
        'date': DateFormat('yyyy-MM-dd').format(_selectedDate!),
        'status': 'Pending',
        'description': _descController.text.trim(),
        'createdAt': FieldValue.serverTimestamp(),
      };

      final caseData = {
        'clientId': _currentUser!.uid,
        'clientName': _clientName,
        'title': '',
        'description': _descController.text.trim(),
        'status': 'Pending',
        'caseStatus': 'pending',
        'submittedAt': FieldValue.serverTimestamp(),
        'respondedAt': null,
        'rejectionReason': null,
      };

      if (type == 'lawyer') {
        bookingData['lawyerId'] = id;
        bookingData['lawyerName'] = target['name'];
        bookingData['specialization'] = target['specialization'] ?? '';
        caseData['lawyerId'] = id;
        caseData['lawyerName'] = target['name'];
        caseData['title'] = 'Case with ${target['name']}';
      } else if (type == 'lawfirm') {
        bookingData['lawfirmId'] = id;
        bookingData['firmId'] = id;
        bookingData['firmName'] = target['firmName'] ?? target['name'];
        bookingData['specialization'] = target['specialization'] ?? '';
        caseData['lawfirmId'] = id;
        caseData['firmId'] = id;
        caseData['firmName'] = target['firmName'] ?? target['name'];
        caseData['title'] =
            'Case with firm ${target['firmName'] ?? target['name']}';
      }

      batch.set(bookingRef, bookingData);
      batch.set(caseRef, caseData);

      await batch.commit();

      final displayName = (type == 'lawfirm')
          ? (target['firmName'] ?? target['name'])
          : target['name'];

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                '✅ Case submitted to $displayName (${type == 'lawyer' ? 'Lawyer' : 'Law Firm'}')),
      );

      setState(() {
        _descController.clear();
        _selectedDate = null;
      });

      await _checkAllAvailability(_selectedDate ?? DateTime.now());
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('⚠️ Error submitting case: $e')),
      );
    }
  }

  Widget _buildTopFilters() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFFD700), width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Filters',
            style: TextStyle(
              color: Color(0xFFFFD700),
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.work_outline, color: Colors.white70, size: 20),
              const SizedBox(width: 8),
              const Text('Specialization:',
                  style: TextStyle(color: Colors.white70)),
              const SizedBox(width: 8),
              Expanded(
                child: DropdownButton<String>(
                  value: _selectedSpecialization ?? 'All',
                  dropdownColor: const Color(0xFF1A1A1A),
                  style: const TextStyle(color: Colors.white),
                  isExpanded: true,
                  items: _specializations.map((spec) {
                    return DropdownMenuItem(
                      value: spec,
                      child: Text(spec,
                          style: const TextStyle(color: Colors.white)),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedSpecialization = value;
                    });
                    _applyFilter();
                  },
                ),
              ),
              const SizedBox(width: 12),
              const Icon(Icons.star_outline, color: Colors.white70, size: 20),
              const SizedBox(width: 8),
              const Text('Rating:', style: TextStyle(color: Colors.white70)),
              const SizedBox(width: 8),
              SizedBox(
                width: 150,
                child: DropdownButton<String>(
                  value: _selectedRatingFilter,
                  dropdownColor: const Color(0xFF1A1A1A),
                  style: const TextStyle(color: Colors.white),
                  isExpanded: true,
                  items: _ratingFilters.map((filter) {
                    return DropdownMenuItem(
                      value: filter,
                      child: Text(filter,
                          style: const TextStyle(color: Colors.white)),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedRatingFilter = value ?? 'All';
                    });
                    _applyFilter();
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLawyersTab() {
    if (_loading) {
      return const Center(
          child: CircularProgressIndicator(color: Color(0xFFFFD700)));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTopFilters(),
        const SizedBox(height: 16),
        TextFormField(
          controller: _descController,
          maxLines: 3,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            labelText: 'Case Description',
            labelStyle: const TextStyle(color: Colors.white70),
            filled: true,
            fillColor: const Color(0xFF1A1A1A),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFFFD700)),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A1A),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFFFD700), width: 0.7),
          ),
          child: ListTile(
            title: const Text('Select Date',
                style: TextStyle(color: Colors.white)),
            subtitle: Text(
              _selectedDate != null
                  ? DateFormat('yyyy-MM-dd').format(_selectedDate!)
                  : 'No date selected',
              style: const TextStyle(color: Colors.white70),
            ),
            trailing: IconButton(
              icon: const Icon(Icons.calendar_today, color: Color(0xFFFFD700)),
              onPressed: _pickDate,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Available Lawyers:',
                style: TextStyle(
                    color: Color(0xFFFFD700),
                    fontSize: 18,
                    fontWeight: FontWeight.bold)),
            Text('${_filteredLawyers.length} found',
                style: const TextStyle(color: Colors.white70)),
          ],
        ),
        const SizedBox(height: 10),
        if (_filteredLawyers.isEmpty)
          Center(
            child: Column(
              children: const [
                SizedBox(height: 40),
                Icon(Icons.search_off, color: Colors.white38, size: 60),
                SizedBox(height: 16),
                Text('No lawyers found matching your filters.',
                    style: TextStyle(color: Colors.white70)),
                SizedBox(height: 8),
                Text('Try adjusting your filter settings.',
                    style: TextStyle(color: Colors.white54, fontSize: 12)),
              ],
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _filteredLawyers.length,
            itemBuilder: (context, index) {
              final lawyer = _filteredLawyers[index];
              final isAvailable = _lawyerAvailability[lawyer['id']] ?? true;

              return Container(
                margin: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1A1A1A), Color(0xFF262626)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                  border:
                      Border.all(color: const Color(0xFFFFD700), width: 0.8),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.amber.withOpacity(0.15),
                        blurRadius: 8,
                        offset: const Offset(0, 3))
                  ],
                ),
                child: ListTile(
                  leading: const Icon(Icons.person,
                      color: Color(0xFFFFD700), size: 30),
                  title: Text(lawyer['name'],
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16)),
                  subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                            '${lawyer['specialization']} • ${lawyer['experience']}',
                            style: const TextStyle(color: Colors.white70)),
                        const SizedBox(height: 6),
                        Row(children: [
                          Text(
                            (lawyer['avgRating'] ?? 0.0) > 0
                                ? (lawyer['avgRating'] ?? 0.0)
                                    .toStringAsFixed(1)
                                : '—',
                            style: const TextStyle(
                                color: Colors.white70,
                                fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(width: 6),
                          const Icon(Icons.star,
                              color: Color(0xFFFFD700), size: 16),
                          const SizedBox(width: 8),
                          Text('(${lawyer['reviewCount'] ?? 0} reviews)',
                              style: const TextStyle(color: Colors.white54)),
                        ]),
                        const SizedBox(height: 6),
                        if ((lawyer['hourlyRate'] ?? 0) > 0)
                          Row(
                            children: [
                              const Icon(Icons.attach_money,
                                  color: Color(0xFFFFD700), size: 16),
                              const SizedBox(width: 4),
                              Text(
                                'PKR ${lawyer['hourlyRate']}/hr',
                                style: const TextStyle(
                                  color: Color(0xFFFFD700),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          )
                        else
                          const Row(
                            children: [
                              Icon(Icons.info_outlined,
                                  color: Colors.white54, size: 16),
                              SizedBox(width: 4),
                              Text(
                                'Rate not specified',
                                style: TextStyle(
                                  color: Colors.white54,
                                  fontSize: 12,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ],
                          ),
                      ]),
                  trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                    IconButton(
                      icon: const Icon(Icons.info_outline,
                          color: Color(0xFFD4AF37)),
                      onPressed: () {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => LawyerInformationPage(
                                    lawyerId: lawyer['id'])));
                      },
                    ),
                    ElevatedButton(
                      onPressed: isAvailable
                          ? () => _book(target: lawyer, type: 'lawyer')
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            isAvailable ? const Color(0xFFFFD700) : Colors.grey,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      child: Text(isAvailable ? 'Book' : 'Booked'),
                    ),
                  ]),
                ),
              );
            },
          ),
      ],
    );
  }

  Widget _buildFirmsTab() {
    if (_loadingFirms) {
      return const Center(
          child: CircularProgressIndicator(color: Color(0xFFFFD700)));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),
        TextFormField(
          controller: _descController,
          maxLines: 3,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            labelText: 'Case Description (for firm booking)',
            labelStyle: const TextStyle(color: Colors.white70),
            filled: true,
            fillColor: const Color(0xFF1A1A1A),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFFFD700)),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A1A),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFFFD700), width: 0.7),
          ),
          child: ListTile(
            title: const Text('Select Date',
                style: TextStyle(color: Colors.white)),
            subtitle: Text(
              _selectedDate != null
                  ? DateFormat('yyyy-MM-dd').format(_selectedDate!)
                  : 'No date selected',
              style: const TextStyle(color: Colors.white70),
            ),
            trailing: IconButton(
              icon: const Icon(Icons.calendar_today, color: Color(0xFFFFD700)),
              onPressed: _pickDate,
            ),
          ),
        ),
        const SizedBox(height: 16),
        const Text('Law Firms:',
            style: TextStyle(
                color: Color(0xFFFFD700),
                fontSize: 18,
                fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        if (_lawFirms.isEmpty)
          const Center(
              child: Text('No law firms found',
                  style: TextStyle(color: Colors.white70)))
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _lawFirms.length,
            itemBuilder: (context, firmIndex) {
              final firm = _lawFirms[firmIndex];
              final isAvailable = _firmAvailability[firm['id']] ?? true;

              return Container(
                margin: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                      colors: [Color(0xFF1A1A1A), Color(0xFF262626)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight),
                  borderRadius: BorderRadius.circular(14),
                  border:
                      Border.all(color: const Color(0xFFFFD700), width: 0.8),
                ),
                child: ListTile(
                  leading: const Icon(Icons.business,
                      color: Color(0xFFFFD700), size: 30),
                  title: Text(firm['firmName'] ?? firm['name'],
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16)),
                  subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Email: ${firm['email']}',
                            style: const TextStyle(color: Colors.white70)),
                        Text('Location: ${firm['location']}',
                            style: const TextStyle(color: Colors.white70)),
                      ]),
                  trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                    IconButton(
                      icon: const Icon(Icons.info_outline,
                          color: Color(0xFFD4AF37)),
                      onPressed: () {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => LawFirmInformationPage(
                                    firmId: firm['id'])));
                      },
                    ),
                    ElevatedButton(
                      onPressed: isAvailable
                          ? () => _book(target: firm, type: 'lawfirm')
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            isAvailable ? const Color(0xFFFFD700) : Colors.grey,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      child: Text(isAvailable ? 'Book' : 'Booked'),
                    ),
                  ]),
                ),
              );
            },
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D0D0D),
        elevation: 0,
        title: const Text('Book a Lawyer or Firm',
            style: TextStyle(color: Color(0xFFFFD700))),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFFFFD700),
          tabs: const [
            Tab(
                icon: Icon(Icons.person, color: Colors.white70),
                text: 'Lawyers'),
            Tab(
                icon: Icon(Icons.business, color: Colors.white70),
                text: 'Law Firms'),
          ],
        ),
      ),
      body: SafeArea(
        child: TabBarView(
          controller: _tabController,
          children: [
            SingleChildScrollView(
                padding: const EdgeInsets.all(20), child: _buildLawyersTab()),
            SingleChildScrollView(
                padding: const EdgeInsets.all(20), child: _buildFirmsTab()),
          ],
        ),
      ),
    );
  }
}
