import 'package:flutter/material.dart';
import 'dart:io'; 

class SentimentAnalysisScreen extends StatelessWidget {
  final String audioPath; 

  const SentimentAnalysisScreen({super.key, required this.audioPath});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hasil Analisis Sentimen'),
        backgroundColor: const Color(0xFF6EBAB3),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Rekaman berhasil dianalisis!',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Text('Path Audio: ${audioPath.split('/').last}'), 
            const SizedBox(height: 20),
            
            const Text(
              'Hasil Sentimen: Positif',
              style: TextStyle(fontSize: 20, color: Colors.green),
            ),
            const SizedBox(height: 10),
            const Text(
              'Transkripsi: "Ini adalah contoh suara yang positif dan ceria."',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: () {
                Navigator.popUntil(context, (route) => route.isFirst); 
              },
              child: const Text('Selesai'),
            ),
          ],
        ),
      ),
    );
  }
}