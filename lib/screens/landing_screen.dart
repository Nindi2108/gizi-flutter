import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import 'login_screen.dart';
import 'home_screen.dart';
import 'coach_home_screen.dart';

class LandingScreen extends StatefulWidget {
  const LandingScreen({super.key});

  @override
  State<LandingScreen> createState() => _LandingScreenState();
}

class _LandingScreenState extends State<LandingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  bool _isLoading = false;

  final List<Map<String, String>> _pages = [
    {
      'title': 'Pantau Gizi Harianmu',
      'description': 'Catat apa yang kamu makan dan ketahui asupan kalori serta nutrisi setiap hari dengan mudah.',
      'icon': 'food_bank_outlined'
    },
    {
      'title': 'Ketahui Status BMI',
      'description': 'Pantau berat badan idealmu dan dapatkan rekomendasi asupan yang sesuai dengan kondisi fisikmu.',
      'icon': 'monitor_weight_outlined'
    },
    {
      'title': 'Terhubung dengan Pelatih',
      'description': 'Pelatih profesional dapat membantu memantau perkembangan kesehatanmu secara langsung.',
      'icon': 'health_and_safety_outlined'
    },
  ];

  Future<void> _handleStart() async {
    setState(() => _isLoading = true);

    // Cek token lokal
    final token = await ApiService.getToken();
    final localRole = await ApiService.getRole() ?? 'user';

    if (!mounted) return;

    if (token != null && token.isNotEmpty) {
      // Validasi token ke server
      final validation = await ApiService.validateToken();

      if (!mounted) return;

      if (validation['success'] == true) {
        // Ambil role terverifikasi dari server, fallback ke localRole
        final serverRole = validation['role'] ?? validation['data']?['role'] ?? localRole;

        // Perbarui local role agar sinkron dengan database
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('role', serverRole);

        if (!mounted) return;

        setState(() => _isLoading = false);
        if (serverRole == 'coach') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const CoachHomeScreen()),
          );
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const HomeScreen()),
          );
        }
      } else {
        // Token expired/invalid → hapus dan ke login
        await ApiService.clearToken();
        if (!mounted) return;
        setState(() => _isLoading = false);
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      }
    } else {
      // Belum login
      setState(() => _isLoading = false);
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    }
  }

  IconData _getIcon(String name) {
    switch (name) {
      case 'food_bank_outlined': return Icons.food_bank_outlined;
      case 'monitor_weight_outlined': return Icons.monitor_weight_outlined;
      case 'health_and_safety_outlined': return Icons.health_and_safety_outlined;
      default: return Icons.star_border;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 40, bottom: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF16A34A).withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.spa, color: Color(0xFF16A34A), size: 30),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'GiziApp',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF16A34A),
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
            ),
            
            // Slider (PageView)
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                itemCount: _pages.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.all(40.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 200,
                          height: 200,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            _getIcon(_pages[index]['icon']!),
                            size: 100,
                            color: const Color(0xFFBEF264), // Lime Green
                          ),
                        ),
                        const SizedBox(height: 40),
                        Text(
                          _pages[index]['title']!,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF1E293B),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _pages[index]['description']!,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            color: Colors.grey[500],
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            
            // Indikator Titik (Dots)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _pages.length,
                (index) => AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  height: 8,
                  width: _currentPage == index ? 24 : 8,
                  decoration: BoxDecoration(
                    color: _currentPage == index ? const Color(0xFF16A34A) : Colors.grey[300],
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 40),
            
            // Tombol Mulai
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 30),
              child: SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleStart,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFBEF264), // Lime Green
                    foregroundColor: Colors.black,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                        )
                      : Text(
                          'Mulai Sekarang',
                          style: GoogleFonts.plusJakartaSans(
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
