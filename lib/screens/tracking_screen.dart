import 'package:flutter/material.dart';

class TrackingScreen extends StatelessWidget {
  const TrackingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tracking Pesanan')),
      body: const Center(
        child: Text(
          'Belum ada pesanan yang dikirim',
          style: TextStyle(fontSize: 16),
        ),
      ),
    );
  }
}
