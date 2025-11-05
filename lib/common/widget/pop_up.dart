import 'package:flutter/material.dart';

class PopUp {
  static void show(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xff535C91),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          title: const Text("Perhatian", style: TextStyle(color: Colors.white)),
          content: const Text(
            "Untuk mengakses penuh aplikasi dibutuhkan login, anda ingin login?",
            style: TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              style: TextButton.styleFrom(
                backgroundColor: Color(0xff1B1A55),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () => Navigator.pop(context),
              child: const Text("Abaikan"),
            ),
            TextButton(
              style: TextButton.styleFrom(
                backgroundColor: Color(0xff070F2B),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () {
                Navigator.pop(context);
                Navigator.pushReplacementNamed(context, '/login');
              },
              child: const Text("Login"),
            ),
          ],
        );
      },
    );
  }
}
