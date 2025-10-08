import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:bingah/theme.dart';
import 'package:intl/intl.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class MeasurementPage extends StatefulWidget {
  const MeasurementPage({super.key});

  @override
  State<MeasurementPage> createState() => _MeasurementPageState();
}

class _MeasurementPageState extends State<MeasurementPage> {
  final _formKey = GlobalKey<FormState>();
  final _namaController = TextEditingController();
  final _namaAyahController = TextEditingController();
  final _namaIbuController = TextEditingController();
  final _alamatController = TextEditingController();
  final _tinggiController = TextEditingController();
  final _beratController = TextEditingController();
  final _lingkarKepalaController = TextEditingController();
  final _lingkarLenganController = TextEditingController();

  DateTime? _tanggalLahir;
  DateTime? _tanggalUkur;
  String? _jenisKelamin;
  String? _caraUkur;
  bool _pemberianVitA = false;

  String _hasilStunting = '';
  String _pesanRekomendasi = '';
  bool _isLoading = false;

  // --- PERBAIKAN: Menggunakan API Key yang benar untuk Generative AI ---
  final _apiKey = dotenv.env['GOOGLE_GEN_AI_API_KEY']!;
  late final GenerativeModel _model;

  @override
  void initState() {
    super.initState();
    // --- PERBAIKAN: Menggunakan model 'gemini-pro' yang stabil ---
    _model = GenerativeModel(model: 'gemini-2.5-flash', apiKey: _apiKey);
  }

  @override
  void dispose() {
    _namaController.dispose();
    _namaAyahController.dispose();
    _namaIbuController.dispose();
    _alamatController.dispose();
    _tinggiController.dispose();
    _beratController.dispose();
    _lingkarKepalaController.dispose();
    _lingkarLenganController.dispose();
    super.dispose();
  }

  int _calculateAgeInMonths() {
    if (_tanggalLahir == null || _tanggalUkur == null) {
      return -1;
    }
    // Logika perhitungan usia sudah benar
    int ageInMonths =
        (_tanggalUkur!.year - _tanggalLahir!.year) * 12 +
        _tanggalUkur!.month -
        _tanggalLahir!.month;
    if (_tanggalUkur!.day < _tanggalLahir!.day) {
      ageInMonths--;
    }
    return ageInMonths;
  }

  void _hitungStunting() async {
    // Validasi form, termasuk field yang wajib diisi
    if (!_formKey.currentState!.validate() ||
        _tanggalLahir == null ||
        _tanggalUkur == null ||
        _jenisKelamin == null ||
        _caraUkur == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Harap lengkapi semua data wajib (*).'),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.only(bottom: 60),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final int usiaBulan = _calculateAgeInMonths();
    double tinggiAwal =
        double.tryParse(_tinggiController.text.replaceAll(',', '.')) ?? 0;

    // Buat variabel baru untuk tinggi yang sudah dikoreksi
    double tinggiKoreksi = tinggiAwal;

    if (usiaBulan < 0 || usiaBulan > 60) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Usia anak tidak dalam rentang 0-60 bulan.'),
        ),
      );
      return;
    }

    // --- PERBAIKAN: Logika Koreksi Tinggi Badan Dibuat Lebih Jelas ---
    // Aturan:
    // 1. Anak < 24 bulan: Idealnya diukur telentang. Jika diukur berdiri, maka tinggi + 0.7 cm.
    // 2. Anak >= 24 bulan: Idealnya diukur berdiri. Jika diukur telentang, maka tinggi - 0.7 cm.
    if (usiaBulan < 24 && _caraUkur == 'Berdiri') {
      tinggiKoreksi += 0.7;
    } else if (usiaBulan >= 24 && _caraUkur == 'Telentang') {
      tinggiKoreksi -= 0.7;
    }
    // Jika cara ukur sudah sesuai usia (misal: < 24 bln & telentang), tidak ada koreksi.

    // Standar tinggi minimal (batas stunting) yang Anda tentukan
    double tinggiStuntingThreshold = 0;
    if (_jenisKelamin == 'Laki-laki') {
      if (usiaBulan <= 12)
        tinggiStuntingThreshold = 65.5;
      else if (usiaBulan <= 24)
        tinggiStuntingThreshold = 78.5;
      else if (usiaBulan <= 36)
        tinggiStuntingThreshold = 87.1;
      else if (usiaBulan <= 48)
        tinggiStuntingThreshold = 93.9;
      else
        tinggiStuntingThreshold = 100.0;
    } else {
      // Perempuan
      if (usiaBulan <= 12)
        tinggiStuntingThreshold = 64.0;
      else if (usiaBulan <= 24)
        tinggiStuntingThreshold = 76.8;
      else if (usiaBulan <= 36)
        tinggiStuntingThreshold = 86.4;
      else if (usiaBulan <= 48)
        tinggiStuntingThreshold = 93.1;
      else
        tinggiStuntingThreshold = 99.0;
    }

    if (tinggiKoreksi > 0) {
      // Bandingkan tinggi yang sudah dikoreksi dengan standar
      if (tinggiKoreksi < tinggiStuntingThreshold) {
        _hasilStunting = 'Stunting Terdeteksi!';
      } else {
        _hasilStunting = 'Tidak Ada Indikasi Stunting.';
      }

      await _generateRecommendation(
        usiaBulan,
        _jenisKelamin!,
        tinggiKoreksi, // Kirim tinggi yang sudah dikoreksi ke Gemini
        _hasilStunting,
        _beratController.text,
        _lingkarKepalaController.text,
        _lingkarLenganController.text,
        _pemberianVitA,
      );

      setState(() {
        _isLoading = false;
      });

      if (context.mounted) {
        _showResultDialog();
      }
    } else {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Masukkan data tinggi badan yang valid.')),
      );
    }
  }

  void _showResultDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          title: Text(
            _hasilStunting,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: _hasilStunting.contains('Tidak')
                  ? bingahPrimaryGreen
                  : Colors.red,
            ),
          ),
          content: SingleChildScrollView(
            child: Text(
              _pesanRekomendasi,
              textAlign: TextAlign.justify,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          actionsAlignment: MainAxisAlignment.spaceEvenly,
          actions: <Widget>[
            OutlinedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _resetForm();
              },
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: bingahTextGrey.withOpacity(0.5)),
                foregroundColor: bingahTextGrey,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                minimumSize: const Size(120, 45),
              ),
              child: const Text('Ukur Ulang'),
            ),
            ElevatedButton(
              onPressed: () {
                _simpanHasil();
                Navigator.of(context).pop();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: bingahPrimaryGreen,
                foregroundColor: bingahWhite,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                minimumSize: const Size(120, 45),
              ),
              child: const Text('Simpan'),
            ),
          ],
        );
      },
    );
  }

  void _resetForm() {
    _formKey.currentState?.reset();
    _namaController.clear();
    _namaAyahController.clear();
    _namaIbuController.clear();
    _alamatController.clear();
    _tinggiController.clear();
    _beratController.clear();
    _lingkarKepalaController.clear();
    _lingkarLenganController.clear();
    setState(() {
      _tanggalLahir = null;
      _tanggalUkur = null;
      _jenisKelamin = null;
      _caraUkur = null;
      _pemberianVitA = false;
      _hasilStunting = '';
      _pesanRekomendasi = '';
    });
  }

  Future<void> _generateRecommendation(
    int usiaBulan,
    String jenisKelamin,
    double tinggi,
    String hasilStunting,
    String berat,
    String lingkarKepala,
    String lingkarLengan,
    bool pemberianVitA,
  ) async {
    // Prompt untuk Gemini sudah bagus, tidak perlu diubah
    final prompt =
        '''
    Sebagai seorang ahli gizi dan kesehatan anak, berikan rekomendasi kesehatan yang personal dan informatif berdasarkan data berikut:
    - Nama: ${_namaController.text}
    - Usia: $usiaBulan bulan
    - Jenis Kelamin: $jenisKelamin
    - Tinggi Badan (setelah dikoreksi jika perlu): $tinggi cm
    - Berat Badan: ${berat.isNotEmpty ? berat : 'Tidak diketahui'} kg
    - Lingkar Kepala: ${lingkarKepala.isNotEmpty ? lingkarKepala : 'Tidak diketahui'} cm
    - Lingkar Lengan Atas: ${lingkarLengan.isNotEmpty ? lingkarLengan : 'Tidak diketahui'} cm
    - Pemberian Vitamin A: ${pemberianVitA ? 'Sudah' : 'Belum'}
    - Status Deteksi Stunting: $hasilStunting

    Instruksi:
    Buat rekomendasi dalam 2 atau 3 poin bernomor, tergantung status stunting. Batasi total kata tidak lebih dari 120, dan pastikan bahasanya mudah dimengerti orang awam, jangan gunakan tanda ** di rekomendasi.

    - Jika 'Stunting Terdeteksi', berikan langkah konkret untuk orang tua dalam 3 poin. Fokus pada nutrisi, stimulasi, dan pentingnya konsultasi ke tenaga kesehatan.
    - Jika 'Tidak Ada Indikasi Stunting', berikan saran praktis dalam 2 poin untuk mempertahankan tumbuh kembang optimal. Fokus pada pemantauan rutin dan variasi nutrisi.
    ''';

    try {
      final response = await _model.generateContent([Content.text(prompt)]);
      setState(() {
        _pesanRekomendasi =
            response.text ?? 'Rekomendasi tidak dapat dihasilkan.';
      });
    } catch (e) {
      setState(() {
        _pesanRekomendasi =
            'Gagal menghasilkan rekomendasi: Periksa koneksi internet atau API Key Anda.';
        debugPrint('Error dari Gemini: $e');
      });
    }
  }

  void _simpanHasil() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Anda harus login untuk menyimpan data.')),
      );
      return;
    }

    // Validasi form sebelum menyimpan
    if (!_formKey.currentState!.validate() ||
        _tanggalLahir == null ||
        _tanggalUkur == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Harap lengkapi semua data wajib (*).'),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.only(bottom: 60),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }

    try {
      await FirebaseFirestore.instance
          .collection('measurements')
          .doc(user.uid)
          .collection('history')
          .add({
            'nama': _namaController.text,
            'namaAyah': _namaAyahController.text,
            'namaIbu': _namaIbuController.text,
            'alamat': _alamatController.text,
            'tanggalLahir': _tanggalLahir,
            'tanggalUkur': _tanggalUkur,
            'usiaBulan': _calculateAgeInMonths(),
            'jenisKelamin': _jenisKelamin,
            'caraUkur': _caraUkur,
            // Menyimpan tinggi asli yang diinput pengguna, bukan yang dikoreksi
            'tinggi':
                double.tryParse(_tinggiController.text.replaceAll(',', '.')) ??
                0,
            'berat':
                double.tryParse(_beratController.text.replaceAll(',', '.')) ??
                0,
            'lingkarKepala':
                double.tryParse(
                  _lingkarKepalaController.text.replaceAll(',', '.'),
                ) ??
                0,
            'lingkarLengan':
                double.tryParse(
                  _lingkarLenganController.text.replaceAll(',', '.'),
                ) ??
                0,
            'pemberianVitA': _pemberianVitA,
            'hasil': _hasilStunting,
            'rekomendasi': _pesanRekomendasi,
            'timestamp': FieldValue.serverTimestamp(),
          });
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Data berhasil disimpan!'),
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.only(bottom: 60),
            backgroundColor: bingahPrimaryGreen,
          ),
        );
        _resetForm();
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menyimpan data: $e'),
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.only(bottom: 60),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  Future<void> _selectDateLahir(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _tanggalLahir ?? DateTime.now(),
      firstDate: DateTime(DateTime.now().year - 5), // 5 tahun ke belakang
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _tanggalLahir) {
      setState(() {
        _tanggalLahir = picked;
      });
    }
  }

  Future<void> _selectDateUkur(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _tanggalUkur ?? DateTime.now(),
      firstDate: _tanggalLahir ?? DateTime(DateTime.now().year - 5),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _tanggalUkur) {
      setState(() {
        _tanggalUkur = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Salin dan tempel sisa kode UI (widget build) Anda di sini.
    // Tidak ada perubahan pada bagian UI.
    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Aplikasi ini digunakan untuk anak balita usia 0-60 bulan.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: bingahTextGrey,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _namaController,
                        decoration: const InputDecoration(
                          labelText: 'Nama Anak*',
                          prefixIcon: Icon(Icons.person),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Nama anak wajib diisi.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: _namaAyahController,
                        decoration: const InputDecoration(
                          labelText: 'Nama Ayah*',
                          prefixIcon: Icon(Icons.man),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Nama Ayah wajib diisi.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: _namaIbuController,
                        decoration: const InputDecoration(
                          labelText: 'Nama Ibu*',
                          prefixIcon: Icon(Icons.woman),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Nama Ibu wajib diisi.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: _alamatController,
                        decoration: const InputDecoration(
                          labelText: 'Alamat*',
                          prefixIcon: Icon(Icons.home),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Alamat wajib diisi.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 10),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          _tanggalLahir == null
                              ? '  Pilih Tanggal Lahir*'
                              : '  Tanggal Lahir: ${DateFormat('dd/MM/yyyy').format(_tanggalLahir!)}',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: _tanggalLahir == null
                                ? bingahTextGrey
                                : Colors.black87,
                            fontSize: 16,
                          ),
                        ),
                        trailing: Icon(
                          Icons.calendar_today,
                          color: bingahPrimaryGreen,
                        ),
                        onTap: () => _selectDateLahir(context),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                          side: BorderSide(
                            color: bingahTextGrey.withOpacity(0.5),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      DropdownButtonFormField<String>(
                        value: _jenisKelamin,
                        decoration: InputDecoration(
                          labelText: 'Jenis Kelamin*',
                          prefixIcon: Icon(
                            _jenisKelamin == 'Perempuan'
                                ? Icons.female
                                : _jenisKelamin == 'Laki-laki'
                                ? Icons.male
                                : Icons.wc,
                          ),
                        ),
                        items: ['Laki-laki', 'Perempuan'].map((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          );
                        }).toList(),
                        onChanged: (newValue) {
                          setState(() {
                            _jenisKelamin = newValue;
                          });
                        },
                        validator: (value) {
                          if (value == null) {
                            return 'Jenis kelamin wajib dipilih.';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: ListTile(
                              contentPadding: EdgeInsets.zero,
                              title: Text(
                                _tanggalUkur == null
                                    ? '  Tgl. Pengukuran*'
                                    : '  Tgl. Ukur: ${DateFormat('dd/MM/yyyy').format(_tanggalUkur!)}',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: _tanggalUkur == null
                                      ? bingahTextGrey
                                      : Colors.black87,
                                  fontSize: 16,
                                ),
                              ),
                              trailing: Icon(
                                Icons.calendar_today,
                                color: bingahPrimaryGreen,
                              ),
                              onTap: () => _selectDateUkur(context),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                                side: BorderSide(
                                  color: bingahTextGrey.withOpacity(0.5),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text('Umur', style: theme.textTheme.bodySmall),
                                const SizedBox(height: 8),
                                Text(
                                  _tanggalLahir != null && _tanggalUkur != null
                                      ? '${_calculateAgeInMonths()} bulan'
                                      : '-',
                                  style: theme.textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      DropdownButtonFormField<String>(
                        value: _caraUkur,
                        decoration: const InputDecoration(
                          labelText: 'Cara Pengukuran*',
                          prefixIcon: Icon(Icons.rule),
                        ),
                        items: ['Berdiri', 'Telentang'].map((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          );
                        }).toList(),
                        onChanged: (newValue) {
                          setState(() {
                            _caraUkur = newValue;
                          });
                        },
                        validator: (value) {
                          if (value == null) {
                            return 'Cara pengukuran wajib dipilih.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: _tinggiController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Tinggi/Panjang Badan (cm)*',
                          prefixIcon: Icon(Icons.height),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Tinggi badan wajib diisi.';
                          }
                          if (double.tryParse(value.replaceAll(',', '.')) ==
                              null) {
                            return 'Gunakan format angka yang benar (contoh: 80.5).';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: _beratController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Berat Badan (kg)*',
                          prefixIcon: Icon(Icons.monitor_weight),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Berat badan wajib diisi.';
                          }
                          if (double.tryParse(value.replaceAll(',', '.')) ==
                              null) {
                            return 'Gunakan format angka yang benar (contoh: 10.2).';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: _lingkarKepalaController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Lingkar Kepala (cm)*',
                          prefixIcon: Icon(Icons.face_retouching_natural),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Lingkar kepala wajib diisi.';
                          }
                          if (double.tryParse(value.replaceAll(',', '.')) ==
                              null) {
                            return 'Gunakan format angka yang benar (contoh: 45.5).';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: _lingkarLenganController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Lingkar Lengan Atas (cm)*',
                          prefixIcon: Icon(Icons.accessibility_new),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Lingkar lengan wajib diisi.';
                          }
                          if (double.tryParse(value.replaceAll(',', '.')) ==
                              null) {
                            return 'Gunakan format angka yang benar (contoh: 15.0).';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 10),
                      SwitchListTile(
                        title: Text(
                          'Pemberian Vitamin A',
                          style: theme.textTheme.bodyMedium,
                        ),
                        value: _pemberianVitA,
                        onChanged: (bool value) {
                          setState(() {
                            _pemberianVitA = value;
                          });
                        },
                        activeColor: bingahPrimaryGreen,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _isLoading ? null : _hitungStunting,
                style: ElevatedButton.styleFrom(
                  backgroundColor: bingahPrimaryGreen,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Text(
                        'Ukur',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: bingahWhite,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
