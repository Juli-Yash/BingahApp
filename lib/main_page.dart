import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:bingah/login_page.dart';
import 'package:bingah/home_main.dart';

class MainPage extends StatelessWidget {
  const MainPage({super.key});

  // Fungsi untuk membersihkan sesi jika data tidak ditemukan
  Future<void> _clearSession(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sesi login tidak valid. Silakan login kembali.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const LoginPage();
          }

          final user = snapshot.data;
          if (user != null) {
            return FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance
                  .collection('users')
                  .doc(user.uid)
                  .get(),
              builder: (context, firestoreSnapshot) {
                if (firestoreSnapshot.connectionState ==
                    ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!firestoreSnapshot.hasData ||
                    !firestoreSnapshot.data!.exists) {
                  _clearSession(context);
                  return const Center(child: CircularProgressIndicator());
                }

                return const HomeMain();
              },
            );
          }

          return const LoginPage();
        },
      ),
    );
  }
}
