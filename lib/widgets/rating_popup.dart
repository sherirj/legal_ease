import 'package:flutter/material.dart';

class RatingPopup extends StatefulWidget {
  final Function(double rating, String feedback) onSubmit;

  const RatingPopup({super.key, required this.onSubmit, required lawyerId});

  @override
  State<RatingPopup> createState() => _RatingPopupState();
}

class _RatingPopupState extends State<RatingPopup> {
  double rating = 0;
  final TextEditingController feedbackCtrl = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.black,
      title: const Text(
        "Rate Your Lawyer",
        style: TextStyle(color: Color(0xFFd4af37)),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              5,
              (index) => IconButton(
                onPressed: () {
                  setState(() => rating = index + 1.0);
                },
                icon: Icon(
                  Icons.star,
                  color: rating >= index + 1 ? Colors.amber : Colors.grey,
                  size: 30,
                ),
              ),
            ),
          ),
          TextField(
            controller: feedbackCtrl,
            maxLines: 3,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: "Write feedback...",
              hintStyle: const TextStyle(color: Colors.white54),
              filled: true,
              fillColor: Colors.grey[900],
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Cancel", style: TextStyle(color: Colors.white54)),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFd4af37)),
          onPressed: () {
            widget.onSubmit(rating, feedbackCtrl.text.trim());
            Navigator.pop(context);
          },
          child: const Text("Submit"),
        ),
      ],
    );
  }
}
