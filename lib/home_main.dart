import 'package:flutter/material.dart';
import 'package:bingah/home_page.dart';
import 'package:bingah/profile_page.dart';
import 'package:bingah/measurement_page.dart';
import 'package:bingah/history_page.dart';
import 'package:bingah/theme.dart';

class HomeMain extends StatefulWidget {
  const HomeMain({super.key});

  @override
  State<HomeMain> createState() => _HomeMainState();
}

class _HomeMainState extends State<HomeMain> {
  int _selectedIndex = 0;

  static const List<String> _pageTitles = <String>[
    'Beranda',
    'Pengukuran',
    'Riwayat',
    'Profil',
  ];

  static const List<Widget> _pages = <Widget>[
    HomePage(),
    MeasurementPage(),
    HistoryPage(),
    ProfilePage(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _pageTitles[_selectedIndex],
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: bingahTextDark,
          ),
        ),
        centerTitle: true,
      ),
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Beranda'),
          BottomNavigationBarItem(
            icon: Icon(Icons.accessibility_new),
            label: 'Ukur',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: 'Riwayat'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profil'),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: theme.colorScheme.primary, // Ini akan menjadi hijau
        unselectedItemColor: bingahTextGrey,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }
}
