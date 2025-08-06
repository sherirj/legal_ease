import 'package:flutter/material.dart';

class LawyerBookingPage extends StatefulWidget {
  const LawyerBookingPage({super.key});

  @override
  State<LawyerBookingPage> createState() => _LawyerBookingPageState();
}

class _LawyerBookingPageState extends State<LawyerBookingPage>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();

  final String _category = 'Domestic Violence';
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _caseDescriptionController = TextEditingController();
  DateTime? _selectedDate;

  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _nameController.dispose();
    _caseDescriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  void _submitForm() {
    if (_formKey.currentState!.validate() && _selectedDate != null) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Booking Confirmed'),
          content: Text(
            'Category: $_category\n'
            'Name: ${_nameController.text}\n'
            'Date: ${_selectedDate!.toLocal().toString().split(' ')[0]}\n'
            'Description: ${_caseDescriptionController.text}',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    } else if (_selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select a date")),
      );
    }
  }

  Widget _animatedItem({required int index, required Widget child}) {
    return TweenAnimationBuilder(
      tween: Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero),
      duration: Duration(milliseconds: 500 + index * 150),
      curve: Curves.easeOut,
      builder: (context, offset, _) {
        return Transform.translate(
          offset: offset,
          child: Opacity(
            opacity: _animationController.value,
            child: child,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Book a Lawyer'),
        backgroundColor: Colors.blue.shade900,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              _animatedItem(
                index: 0,
                child: TextFormField(
                  enabled: false,
                  initialValue: _category,
                  decoration: const InputDecoration(
                    labelText: 'Lawyer Category',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              _animatedItem(
                index: 1,
                child: TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'Your Name'),
                  validator: (val) =>
                      val == null || val.isEmpty ? 'Enter your name' : null,
                ),
              ),
              const SizedBox(height: 20),
              _animatedItem(
                index: 2,
                child: TextFormField(
                  controller: _caseDescriptionController,
                  decoration: const InputDecoration(labelText: 'Case Description'),
                  maxLines: 3,
                  validator: (val) =>
                      val == null || val.isEmpty ? 'Describe your case' : null,
                ),
              ),
              const SizedBox(height: 20),
              _animatedItem(
                index: 3,
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Select Appointment Date'),
                  subtitle: Text(
                    _selectedDate != null
                        ? _selectedDate!.toLocal().toString().split(' ')[0]
                        : 'No date selected',
                    style: TextStyle(
                      color: _selectedDate != null ? Colors.black : Colors.grey,
                    ),
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.calendar_today),
                    onPressed: _pickDate,
                  ),
                ),
              ),
              const SizedBox(height: 30),
              _animatedItem(
                index: 4,
                child: ElevatedButton(
                  onPressed: _submitForm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade900,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    minimumSize: const Size.fromHeight(50),
                  ),
                  child: const Text('Book Now', style: TextStyle(fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
