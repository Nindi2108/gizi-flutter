import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gizi_flutter/services/api_service.dart';

class ResetPasswordScreen extends StatefulWidget {
  final String email;
  final String? debugOtp;

  const ResetPasswordScreen({
    super.key,
    required this.email,
    this.debugOtp,
  });

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _otpController = TextEditingController();
  final _passwordController = TextEditingController();
  final _passwordConfirmController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Auto-fill OTP jika dalam mode debug untuk mempermudah testing
    if (widget.debugOtp != null) {
      _otpController.text = widget.debugOtp!;
    }
  }

  Future<void> _handleResetPassword() async {
    final otp = _otpController.text.trim();
    final password = _passwordController.text.trim();
    final passwordConfirm = _passwordConfirmController.text.trim();

    if (otp.isEmpty || password.isEmpty || passwordConfirm.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Semua field harus diisi')),
      );
      return;
    }

    if (otp.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kode verifikasi OTP harus 6 digit')),
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

    if (password != passwordConfirm) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password dan konfirmasi password tidak cocok')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final res = await ApiService.resetPassword(
        widget.email,
        otp,
        password,
        passwordConfirm,
      );

      if (res['success'] == true) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(res['message'] ?? 'Password berhasil diubah!')),
          );

          // Pindah kembali ke Login (kembalikan route stack hingga ke login screen)
          Navigator.of(context).popUntil((route) => route.isFirst);
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(res['message'] ?? 'Gagal mengatur ulang password')),
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
                      'Kembali',
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
                'Reset Password',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Kami telah mengirimkan 6 digit kode verifikasi ke email:\n${widget.email}',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  color: Colors.grey[500],
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 20),

              // Tampilan Debug OTP (Hanya untuk keperluan demo sidang jika server offline)
              if (widget.debugOtp != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFBEF264).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFF65A30D).withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.bug_report, color: Color(0xFF65A30D)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Mode Debug: Kode OTP Anda adalah ${widget.debugOtp} (otomatis diisi di bawah)',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            color: const Color(0xFF65A30D),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],

              // Form Input OTP
              _buildLabel('KODE OTP (6 DIGIT)'),
              _buildTextField(
                controller: _otpController,
                hintText: 'Masukkan 6 digit kode',
                keyboardType: TextInputType.number,
                maxLength: 6,
              ),
              const SizedBox(height: 20),

              // Form Input Password Baru
              _buildLabel('PASSWORD BARU'),
              _buildTextField(
                controller: _passwordController,
                hintText: 'Masukkan password baru',
                obscureText: true,
              ),
              const SizedBox(height: 20),

              // Form Input Konfirmasi Password Baru
              _buildLabel('KONFIRMASI PASSWORD BARU'),
              _buildTextField(
                controller: _passwordConfirmController,
                hintText: 'Masukkan ulang password baru',
                obscureText: true,
              ),
              const SizedBox(height: 30),

              // Tombol Simpan
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleResetPassword,
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
                          'Simpan Password Baru',
                          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 16),
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
    int? maxLength,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      maxLength: maxLength,
      decoration: InputDecoration(
        counterText: '', // Sembunyikan counter maxLength bawaan
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
}
