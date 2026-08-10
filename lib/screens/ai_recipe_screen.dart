import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';

class AiRecipeScreen extends StatefulWidget {
  final String waktuMakan;
  const AiRecipeScreen({super.key, required this.waktuMakan});

  @override
  State<AiRecipeScreen> createState() => _AiRecipeScreenState();
}

class _AiRecipeScreenState extends State<AiRecipeScreen> {
  final _promptController = TextEditingController();
  final _porsiController = TextEditingController(text: '100');
  
  bool _isLoading = false;
  bool _isSaving = false;
  Map<String, dynamic>? _aiData;
  String _error = '';

  @override
  void dispose() {
    _promptController.dispose();
    _porsiController.dispose();
    super.dispose();
  }

  Future<void> _generateRecipe() async {
    final prompt = _promptController.text.trim();
    if (prompt.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Silakan masukkan nama makanan atau bahan terlebih dahulu')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _error = '';
      _aiData = null;
    });

    final res = await ApiService.generateAiRecipe(prompt);

    if (!mounted) return;

    if (res['success'] == true) {
      setState(() {
        _aiData = res['data'];
        _isLoading = false;
      });
    } else {
      setState(() {
        _error = res['message'] ?? 'Gagal menghubungi asisten AI';
        _isLoading = false;
      });
    }
  }

  Future<void> _saveCustomFood() async {
    if (_aiData == null) return;

    final porsi = double.tryParse(_porsiController.text) ?? 100;
    if (porsi <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Porsi makanan harus lebih besar dari 0 gram')),
      );
      return;
    }

    setState(() => _isSaving = true);

    final res = await ApiService.logCustomFood(
      namaMakanan: _aiData!['nama_makanan'] ?? 'Makanan AI',
      kalori: _toDouble(_aiData!['kalori']),
      protein: _toDouble(_aiData!['protein']),
      karbohidrat: _toDouble(_aiData!['karbohidrat']),
      lemak: _toDouble(_aiData!['lemak']),
      waktuMakan: widget.waktuMakan,
      porsi: porsi,
      resep: _aiData!['resep'],
    );

    if (!mounted) return;
    setState(() => _isSaving = false);

    if (res['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(child: Text('${_aiData!['nama_makanan']} berhasil dicatat!')),
            ],
          ),
          backgroundColor: const Color(0xFF16A34A),
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.pop(context, true); // kembalikan true agar dashboard memicu refresh
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(res['message'] ?? 'Gagal mencatat makanan')),
      );
    }
  }

  double _toDouble(dynamic val) {
    if (val == null) return 0.0;
    if (val is double) return val;
    if (val is int) return val.toDouble();
    if (val is String) return double.tryParse(val) ?? 0.0;
    return 0.0;
  }

  @override
  Widget build(BuildContext context) {
    final slotLabel = widget.waktuMakan.replaceAll('_', ' ').toUpperCase();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          'AI Resep & Gizi',
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
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header Slot ─────────────────────────────────────────
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF16A34A).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Slot: $slotLabel',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF16A34A),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              
              Text(
                'Tulis makanan kustom Anda',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'AI akan mengestimasi resep serta kandungan gizi (kalori, protein, karbohidrat, lemak) secara instan.',
                style: TextStyle(fontSize: 13, color: Colors.grey[600], height: 1.4),
              ),
              const SizedBox(height: 20),

              // ── Input Prompt ────────────────────────────────────────
              TextField(
                controller: _promptController,
                maxLines: 2,
                decoration: InputDecoration(
                  hintText: 'Contoh: Nasi liwet Sunda dengan ayam goreng dan sambal terasi...',
                  hintStyle: TextStyle(color: Colors.grey[400], fontSize: 13),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: Colors.grey.shade200),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: Colors.grey.shade200),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: Color(0xFF16A34A), width: 1.5),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // ── Tombol Analisis ─────────────────────────────────────
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _generateRecipe,
                  icon: const Icon(Icons.auto_awesome, size: 18),
                  label: Text(
                    'Analisis dengan AI',
                    style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFBEF264),
                    foregroundColor: Colors.black,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // ── Loading & Error States ──────────────────────────────
              if (_isLoading)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 40),
                    child: Column(
                      children: [
                        const CircularProgressIndicator(color: Color(0xFF16A34A)),
                        const SizedBox(height: 16),
                        Text(
                          'Gemini sedang meracik resep & mengestimasi gizi...',
                          style: TextStyle(color: Colors.grey[600], fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ),
              
              if (_error.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline_rounded, color: Colors.red),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _error,
                          style: const TextStyle(color: Colors.red, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),

              // ── Hasil AI ────────────────────────────────────────────
              if (_aiData != null) ...[
                _buildResultsCard(),
                const SizedBox(height: 24),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResultsCard() {
    final nama = _aiData!['nama_makanan'] ?? 'Makanan Kustom';
    final kalori = _toDouble(_aiData!['kalori']);
    final protein = _toDouble(_aiData!['protein']);
    final karbo = _toDouble(_aiData!['karbohidrat']);
    final lemak = _toDouble(_aiData!['lemak']);
    final resep = _aiData!['resep'] ?? 'Resep tidak tersedia.';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Kartu Gizi
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
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
            border: Border.all(color: const Color(0xFF16A34A).withOpacity(0.1)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'HASIL ESTIMASI AI',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF16A34A),
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                nama,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1E293B),
                ),
              ),
              Text(
                'Nilai gizi di bawah adalah estimasi per 100 gram.',
                style: TextStyle(fontSize: 11, color: Colors.grey[500]),
              ),
              const SizedBox(height: 16),
              
              // Kolom Gizi
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _nutritionItem('Kalori', '${kalori.toStringAsFixed(0)} kcal', Colors.orange),
                  _nutritionItem('Protein', '${protein.toStringAsFixed(1)}g', Colors.blue),
                  _nutritionItem('Karbo', '${karbo.toStringAsFixed(1)}g', Colors.green),
                  _nutritionItem('Lemak', '${lemak.toStringAsFixed(1)}g', Colors.red),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Resep Card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.restaurant_menu, size: 18, color: Color(0xFF1E293B)),
                  const SizedBox(width: 8),
                  Text(
                    'AI Resep Pembuatan',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF1E293B),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                resep,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  color: const Color(0xFF475569),
                  height: 1.6,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Input Porsi
        Container(
          padding: const EdgeInsets.all(20),
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
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Porsi Makan',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Tentukan porsi makan Anda',
                      style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              SizedBox(
                width: 120,
                child: TextField(
                  controller: _porsiController,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  decoration: InputDecoration(
                    suffixText: 'gram',
                    suffixStyle: const TextStyle(fontSize: 12, color: Colors.grey),
                    filled: true,
                    fillColor: const Color(0xFFF1F5F9),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFF16A34A), width: 1.5),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Tombol Simpan
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton.icon(
            onPressed: _isSaving ? null : _saveCustomFood,
            icon: _isSaving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                  )
                : const Icon(Icons.check_circle_rounded),
            label: Text(
              _isSaving ? 'Sedang mencatat...' : 'Catat Makan Sekarang',
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF16A34A),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _nutritionItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF1E293B),
          ),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            label,
            style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }
}
