import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gizi_flutter/services/api_service.dart';
import 'home_screen.dart';
import 'coach_home_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _passwordConfirmController = TextEditingController();
  final _coachCodeController = TextEditingController();
  bool _isLoading = false;
  String _selectedRole = 'user'; // 'user' = atlet, 'coach' = pelatih

  Future<void> _handleRegister() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final passwordConfirm = _passwordConfirmController.text.trim();

    if (name.isEmpty || email.isEmpty || password.isEmpty || passwordConfirm.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Semua field harus diisi')),
      );
      return;
    }

    // Validasi format email
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(email)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Format email tidak valid')),
      );
      return;
    }

    // Validasi kekuatan password (minimal 8 karakter, ada huruf dan angka)
    final passwordRegex = RegExp(r'^(?=.*[A-Za-z])(?=.*\d).{8,}$');
    if (!passwordRegex.hasMatch(password)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password harus minimal 8 karakter dan mengandung kombinasi huruf dan angka'),
        ),
      );
      return;
    }

    if (_selectedRole == 'coach') {
      final coachCode = _coachCodeController.text.trim();
      if (coachCode.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Kode verifikasi pelatih wajib diisi')),
        );
        return;
      }
      // ⚠️ CATATAN KEAMANAN: Validasi di bawah ini hanyalah sanity check di sisi client.
      // Server backend Anda WAJIB memvalidasi parameter 'coach_code' ini pada endpoint registrasinya.
      if (coachCode != 'pelatihakses') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Kode verifikasi pelatih salah!')),
        );
        return;
      }
    }

    if (password != passwordConfirm) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password dan konfirmasi password tidak cocok')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final res = await ApiService.register(
        name,
        email,
        password,
        passwordConfirm,
        role: _selectedRole,
        coachCode: _selectedRole == 'coach' ? _coachCodeController.text.trim() : null,
      );

      if (res['success'] == true) {
        // Baca role, nama, dan email dari API response
        final String role = res['role'] ?? res['data']?['role'] ?? _selectedRole;
        final String? userName = res['data']?['name'];
        final String? userEmail = res['data']?['email'];

        await ApiService.saveToken(
          res['token'],
          role: role,
          name: userName,
          email: userEmail,
        );
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                role == 'coach'
                    ? 'Registrasi berhasil! Selamat datang, Pelatih!'
                    : 'Registrasi berhasil! Selamat datang!',
              ),
            ),
          );
          
          if (role == 'coach') {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => const CoachHomeScreen()),
              (route) => false,
            );
          } else {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => const HomeScreen()),
              (route) => false,
            );
          }
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(res['message'] ?? 'Registrasi gagal')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Kesalahan: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleGoogleLogin() async {
    setState(() => _isLoading = true);
    
    try {
      final res = await ApiService.loginWithGoogle();
      
      if (res['success'] == true) {
        final String role = res['role'] ?? res['data']?['role'] ?? 'user';
        final String? userName = res['data']?['name'];
        final String? userEmail = res['data']?['email'];

        await ApiService.saveToken(
          res['token'],
          role: role,
          name: userName,
          email: userEmail,
        );
        
        if (mounted) {
          if (role == 'coach') {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => const CoachHomeScreen()),
              (route) => false,
            );
          } else {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => const HomeScreen()),
              (route) => false,
            );
          }
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(res['message'] ?? 'Login Google gagal')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Kesalahan: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 30.0, vertical: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Tombol Kembali
              InkWell(
                onTap: () => Navigator.pop(context),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.arrow_back, size: 16, color: Colors.grey),
                    const SizedBox(width: 8),
                    Text(
                      'Kembali ke Login',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),

              // Title & Subtitle
              Text(
                'Daftar Akun',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Lengkapi data di bawah ini untuk membuat akun baru.',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  color: Colors.grey[500],
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),

              // ── PILIHAN ROLE ─────────────────────────────────
              _buildLabel('DAFTAR SEBAGAI'),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _buildRoleCard(
                      title: 'Atlet',
                      subtitle: 'Pantau gizi & nutrisi harian',
                      icon: Icons.directions_run_rounded,
                      value: 'user',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildRoleCard(
                      title: 'Pelatih',
                      subtitle: 'Pantau perkembangan atlet',
                      icon: Icons.sports_rounded,
                      value: 'coach',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Form Input Nama Lengkap
              _buildLabel('NAMA LENGKAP'),
              _buildTextField(
                controller: _nameController,
                hintText: 'Masukkan nama lengkap',
              ),
              const SizedBox(height: 20),

              // Form Input Email
              _buildLabel('ALAMAT EMAIL'),
              _buildTextField(
                controller: _emailController,
                hintText: 'email@contoh.com',
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 20),

              // Form Input Kode Verifikasi Pelatih
              if (_selectedRole == 'coach') ...[
                _buildLabel('KODE AKSES VERIFIKASI PELATIH'),
                _buildTextField(
                  controller: _coachCodeController,
                  hintText: 'Masukkan kode akses pelatih',
                  obscureText: true,
                ),
                const SizedBox(height: 20),
              ],

              // Form Input Password
              _buildLabel('PASSWORD'),
              _buildTextField(
                controller: _passwordController,
                hintText: 'Masukkan password',
                obscureText: true,
              ),
              const SizedBox(height: 20),

              // Form Input Konfirmasi Password
              _buildLabel('KONFIRMASI PASSWORD'),
              _buildTextField(
                controller: _passwordConfirmController,
                hintText: 'Masukkan ulang password',
                obscureText: true,
              ),
              const SizedBox(height: 30),

              // Tombol Daftar
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleRegister,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFBEF264), // Lime Green
                    foregroundColor: Colors.black,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                        )
                      : Text(
                          _selectedRole == 'coach'
                              ? 'Daftar sebagai Pelatih'
                              : 'Daftar sebagai Atlet',
                          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 16),
                        ),
                ),
              ),

              const SizedBox(height: 25),
              // Separator "Atau"
              Row(
                children: [
                  Expanded(child: Divider(color: Colors.grey[200])),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 15),
                    child: Text(
                      'ATAU',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[400],
                      ),
                    ),
                  ),
                  Expanded(child: Divider(color: Colors.grey[200])),
                ],
              ),
              const SizedBox(height: 25),

              // Google Login
              SizedBox(
                width: double.infinity,
                height: 55,
                child: OutlinedButton(
                  onPressed: _isLoading ? null : _handleGoogleLogin,
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Colors.grey[200]!),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.g_mobiledata, color: Colors.red, size: 30),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          'Daftar dengan Google',
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.plusJakartaSans(
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[700],
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 25),
              // Link Login
              Center(
                child: InkWell(
                  onTap: () => Navigator.pop(context),
                  child: RichText(
                    text: TextSpan(
                      style: GoogleFonts.plusJakartaSans(fontSize: 14, color: Colors.grey[600]),
                      children: [
                        const TextSpan(text: 'Sudah punya akun? '),
                        const TextSpan(
                          text: 'Masuk di sini',
                          style: TextStyle(
                            color: Color(0xFF65A30D),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        text,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: Colors.grey[400],
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    bool obscureText = false,
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
        filled: true,
        fillColor: const Color(0xFFF9FAFB),
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[200]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[200]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFBEF264), width: 2),
        ),
      ),
    );
  }

  /// Card pemilih role (Atlet / Pelatih)
  Widget _buildRoleCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required String value,
  }) {
    final bool isSelected = _selectedRole == value;
    return GestureDetector(
      onTap: () => setState(() => _selectedRole = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFFBEF264).withOpacity(0.15)
              : const Color(0xFFF9FAFB),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? const Color(0xFF65A30D) : Colors.grey.shade200,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 28,
              color: isSelected ? const Color(0xFF16A34A) : Colors.grey[400],
            ),
            const SizedBox(height: 6),
            Text(
              title,
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: isSelected
                    ? const Color(0xFF16A34A)
                    : const Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 3),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 10,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
