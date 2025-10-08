import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:bingah/theme.dart';

// 1. Ubah class menjadi StatefulWidget
class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

// 2. Buat State class untuk menampung logika dan UI
class _HistoryPageState extends State<HistoryPage> {
  // 3. Pindahkan fungsi _deleteMeasurement ke dalam State
  Future<void> _deleteMeasurement(
    BuildContext context,
    String userId,
    String docId,
  ) async {
    bool? confirmDelete = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          title: const Text('Hapus Riwayat?'),
          content: const Text(
            'Apakah Anda yakin ingin menghapus riwayat pengukuran ini?',
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Tidak'),
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
            ),
            TextButton(
              style: TextButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Ya'),
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              },
            ),
          ],
        );
      },
    );

    if (confirmDelete == true) {
      try {
        await FirebaseFirestore.instance
            .collection('measurements')
            .doc(userId)
            .collection('history')
            .doc(docId)
            .delete();

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Riwayat berhasil dihapus!',
              style: TextStyle(color: Theme.of(context).colorScheme.onPrimary),
            ),
            backgroundColor: bingahPrimaryGreen,
            // PERBAIKAN: Gaya SnackBar yang konsisten dan benar posisinya
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.only(bottom: 60),
          ),
        );
      } catch (e) {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Gagal menghapus riwayat: $e',
              style: TextStyle(color: Theme.of(context).colorScheme.onPrimary),
            ),
            backgroundColor: Theme.of(context).colorScheme.error,
            // PERBAIKAN: Gaya SnackBar yang konsisten dan benar posisinya
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.only(bottom: 60),
          ),
        );
      }
    }
  }

  // 4. Pindahkan method build ke dalam State
  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final theme = Theme.of(context);

    if (user == null) {
      return Center(
        child: Text(
          'Anda harus login untuk melihat riwayat.',
          style: theme.textTheme.bodyMedium,
        ),
      );
    }

    return Scaffold(
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('measurements')
            .doc(user.uid)
            .collection('history')
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error: ${snapshot.error}',
                style: theme.textTheme.bodyMedium,
              ),
            );
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Text(
                'Belum ada riwayat pengukuran.',
                style: theme.textTheme.bodyMedium,
              ),
            );
          }

          final historyData = snapshot.data!.docs;

          return ListView.builder(
            itemCount: historyData.length,
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            itemBuilder: (context, index) {
              final measurement =
                  historyData[index].data() as Map<String, dynamic>;
              final docId = historyData[index].id;

              final timestamp =
                  (measurement['timestamp'] as Timestamp?)?.toDate() ??
                  DateTime.now();
              final formattedDate = DateFormat(
                'dd MMMM yyyy, HH:mm',
                'id_ID',
              ).format(timestamp);

              final tglLahirData = measurement['tanggalLahir'] as Timestamp?;
              final formattedTglLahir = tglLahirData != null
                  ? DateFormat(
                      'dd MMMM yyyy',
                      'id_ID',
                    ).format(tglLahirData.toDate())
                  : '-';

              final hasil =
                  measurement['hasil']?.toString() ?? 'Tidak ada hasil';

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                color: bingahWhite,
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // --- BAGIAN HEADER ---
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  measurement['nama'] ?? 'Nama Anak',
                                  style: theme.textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: bingahPrimaryGreen,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Diukur pada: $formattedDate',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: bingahTextGrey,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: Icon(
                              Icons.delete,
                              color: Colors.red.shade700,
                            ),
                            onPressed: () =>
                                _deleteMeasurement(context, user.uid, docId),
                          ),
                        ],
                      ),
                      const Divider(height: 24),

                      // --- BAGIAN DETAIL ANAK ---
                      Text(
                        'Detail Anak',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Tgl Lahir: $formattedTglLahir',
                        style: theme.textTheme.bodyMedium,
                      ),
                      Text(
                        'Usia saat diukur: ${measurement['usiaBulan'] ?? '-'} bulan',
                        style: theme.textTheme.bodyMedium,
                      ),
                      Text(
                        'Jenis Kelamin: ${measurement['jenisKelamin'] ?? '-'}',
                        style: theme.textTheme.bodyMedium,
                      ),
                      Text(
                        'Nama Ayah: ${measurement['namaAyah'] ?? '-'}',
                        style: theme.textTheme.bodyMedium,
                      ),
                      Text(
                        'Nama Ibu: ${measurement['namaIbu'] ?? '-'}',
                        style: theme.textTheme.bodyMedium,
                      ),
                      Text(
                        'Alamat: ${measurement['alamat'] ?? '-'}',
                        style: theme.textTheme.bodyMedium,
                      ),

                      const SizedBox(height: 16),

                      // --- BAGIAN PENGUKURAN ---
                      Text(
                        'Hasil Pengukuran',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text('Cara Ukur: ${measurement['caraUkur'] ?? '-'}'),
                      Text('Tinggi/Panjang: ${measurement['tinggi']} cm'),
                      Text('Berat Badan: ${measurement['berat']} kg'),
                      Text(
                        'Lingkar Kepala: ${measurement['lingkarKepala']} cm',
                      ),
                      Text(
                        'Lingkar Lengan: ${measurement['lingkarLengan']} cm',
                      ),
                      Text(
                        'Vitamin A: ${measurement['pemberianVitA'] == true ? 'Sudah Diberi' : 'Belum Diberi'}',
                      ),

                      const SizedBox(height: 16),

                      // --- BAGIAN HASIL & REKOMENDASI ---
                      Text(
                        'Analisis',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Hasil: $hasil',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: hasil.contains('Tidak')
                              ? bingahPrimaryGreen
                              : Colors.red.shade700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Rekomendasi: ${measurement['rekomendasi'] ?? '-'}',
                        style: theme.textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
