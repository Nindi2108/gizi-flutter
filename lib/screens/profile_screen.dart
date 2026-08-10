import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';
import 'login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isLoading = true;
  Map<String, dynamic>? _user;
  Map<String, dynamic>? _bmi;

  @override
  void initState() {
    super.initState();
    _fetchProfileData();
  }

  Future<void> _fetchProfileData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // 1. Ambil Profil User
      final userRes = await ApiService.getUserProfile();
      
      // 2. Ambil BMI Terbaru (bisa null jika belum isi)
      final bmiRes = await ApiService.getLatestBmi();

      if (!mounted) return;

      if (userRes['success'] == true) {
        setState(() {
          _user = userRes['data'];
          _bmi = bmiRes['success'] == true ? bmiRes['data'] : null;
          _isLoading = false;
        });
      } else {
        // Fallback dari local storage jika gagal koneksi
        final name = await ApiService.getUserName();
        final email = await ApiService.getUserEmail();
        final role = await ApiService.getRole();
        
        setState(() {
          _user = {
            'nama_lengkap': name ?? 'Pengguna',
            'email': email ?? '-',
            'role': role ?? 'user',
          };
          _bmi = null;
          _isLoading = false;
        });
      }
    } catch (e) {
      // Fallback local storage
      final name = await ApiService.getUserName();
      final email = await ApiService.getUserEmail();
      final role = await ApiService.getRole();

      if (mounted) {
        setState(() {
          _user = {
            'nama_lengkap': name ?? 'Pengguna',
            'email': email ?? '-',
            'role': role ?? 'user',
          };
          _bmi = null;
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Keluar',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold),
        ),
        content: const Text('Apakah Anda yakin ingin keluar dari aplikasi?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Keluar'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() => _isLoading = true);
      try {
        await ApiService.logout();
      } catch (_) {}
      await ApiService.clearToken();
      
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (_) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          'Profil Saya',
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: const Color(0xFF1E293B),
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1E293B)),
          onPressed: () => Navigator.pop(context),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(
            color: const Color(0xFFF1F5F9),
            height: 1.0,
          ),
        ),
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: Color(0xFF16A34A)))
            : RefreshIndicator(
                onRefresh: _fetchProfileData,
                color: const Color(0xFF16A34A),
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      // ── Avatar & Name Section ───────────────────────
                      _buildAvatarSection(),
                      const SizedBox(height: 32),

                      // ── Health/BMI Summary Card ─────────────────────
                      _buildBmiSummaryCard(),
                      const SizedBox(height: 24),

                      // ── Account Details Card ────────────────────────
                      _buildInfoCard(),
                      const SizedBox(height: 32),

                      // ── Logout Button ───────────────────────────────
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton.icon(
                          onPressed: _logout,
                          icon: const Icon(Icons.logout_rounded),
                          label: Text(
                            'Keluar dari Akun',
                            style: GoogleFonts.plusJakartaSans(
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFEF4444),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildAvatarSection() {
    final name = _user?['nama_lengkap'] ?? _user?['name'] ?? 'Pengguna';
    final initials = name
        .split(' ')
        .take(2)
        .map((w) => w.isNotEmpty ? w[0].toUpperCase() : '')
        .join();

    return Column(
      children: [
        Container(
          width: 90,
          height: 90,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              colors: [Color(0xFF16A34A), Color(0xFFBEF264)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF16A34A).withOpacity(0.3),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Center(
            child: Text(
              initials,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ),
        const SizedBox(height: 14),
        Text(
          name,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF1E293B),
          ),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFF16A34A).withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            '🏃 Atlet',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              color: const Color(0xFF16A34A),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBmiSummaryCard() {
    if (_bmi == null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            const Icon(Icons.monitor_weight_outlined, size: 40, color: Colors.grey),
            const SizedBox(height: 10),
            Text(
              'Data Fisik Belum Lengkap',
              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 4),
            Text(
              'Silakan isi berat dan tinggi badan Anda di halaman utama.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[500], fontSize: 12),
            ),
          ],
        ),
      );
    }

    final skorBmi = _bmi!['skor'] ?? _bmi!['skor_bmi'] ?? 0.0;
    final category = _bmi!['category'] ?? _bmi!['status_teks'] ?? '-';
    final targetKalori = _bmi!['kalori_target'] ?? _bmi!['kebutuhan_kalori'] ?? 2000;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF16A34A), Color(0xFF15803D)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF16A34A).withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'STATUS KESEHATAN',
                style: GoogleFonts.plusJakartaSans(
                  color: Colors.white70,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                ),
              ),
              const Icon(Icons.insights, color: Colors.white70, size: 20),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildBmiStatItem(
                  label: 'Skor BMI',
                  value: skorBmi.toString(),
                ),
              ),
              Container(width: 1, height: 40, color: Colors.white24),
              Expanded(
                child: _buildBmiStatItem(
                  label: 'Kategori',
                  value: category,
                ),
              ),
              Container(width: 1, height: 40, color: Colors.white24),
              Expanded(
                child: _buildBmiStatItem(
                  label: 'Target Kalori',
                  value: '${round(targetKalori)} kkal',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBmiStatItem({required String label, required String value}) {
    return Column(
      children: [
        Text(
          value,
          textAlign: TextAlign.center,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.white70, fontSize: 11),
        ),
      ],
    );
  }

  double round(dynamic val) {
    if (val == null) return 0;
    if (val is double) return val;
    if (val is int) return val.toDouble();
    if (val is String) return double.tryParse(val) ?? 0;
    return 0;
  }

  Widget _buildInfoCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildInfoRow(
            icon: Icons.person_rounded,
            label: 'Nama Lengkap',
            value: _user?['nama_lengkap'] ?? _user?['name'] ?? '-',
          ),
          const Divider(height: 1, indent: 56),
          _buildInfoRow(
            icon: Icons.email_rounded,
            label: 'Email',
            value: _user?['email'] ?? '-',
          ),
          const Divider(height: 1, indent: 56),
          _buildInfoRow(
            icon: Icons.badge_rounded,
            label: 'Peran',
            value: _user?['role'] == 'coach' ? 'Pelatih' : 'Atlet / Pengguna',
          ),
          if (_bmi != null && _bmi!['tinggi_badan'] != null) ...[
            const Divider(height: 1, indent: 56),
            _buildInfoRow(
              icon: Icons.height,
              label: 'Tinggi Badan',
              value: '${_bmi!['tinggi_badan']} cm',
            ),
          ],
          if (_bmi != null && _bmi!['berat_badan'] != null) ...[
            const Divider(height: 1, indent: 56),
            _buildInfoRow(
              icon: Icons.monitor_weight_outlined,
              label: 'Berat Badan',
              value: '${_bmi!['berat_badan']} kg',
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF16A34A).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 18, color: const Color(0xFF16A34A)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1E293B),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
