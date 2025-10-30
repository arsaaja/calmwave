import 'package:flutter/material.dart';
import 'package:calm_wave/common/widget/app_card.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1B1A55),
      body: Center(
        child: SingleChildScrollView(
          child: AppCard(
            // Login card
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Logo
                Column(
                  children: [
                    Image.asset('assets/images/logo.png', height: 150),
                  ],
                ),

                const SizedBox(height: 30),

                // Email
                _buildTextField("Email"),
                const SizedBox(height: 12),

                // Password
                _buildTextField("Password", obscure: true),
                const SizedBox(height: 12),

                // Tombol Login
                ElevatedButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/tab_bar');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1B1A55),
                    minimumSize: const Size(double.infinity, 48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    "Login",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                ),

                const SizedBox(height: 15),

                // Sudah punya akun?
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      "Belum punya akun? ",
                      style: TextStyle(color: Colors.white),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pushNamed(context, '/signup');
                      },
                      child: const Text(
                        "Daftar sekarang",
                        style: TextStyle(
                          color: Color(0xFF070F2B),
                          fontWeight: FontWeight.bold,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(String hint, {bool obscure = false}) {
    return TextFormField(
      obscureText: obscure,
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 15,
          vertical: 12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
