import 'package:flutter/material.dart';

class ProfileScreen extends StatelessWidget {
  final String username;
  final String nama;
  const ProfileScreen({super.key, required this.username, required this.nama});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Profil')),
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ClipOval(
                child: Image.asset(
                  'assets/images/foto.jpg',
                  width: 140,
                  height: 140,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) =>
                      Icon(Icons.account_circle, size: 140, color: Colors.green),
                ),
              ),
              SizedBox(height: 20),
              Text(nama, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              SizedBox(height: 4),
              Text('@$username', style: TextStyle(color: Colors.grey)),
            ],
          ),
        ),
      ),
    );
  }
}
