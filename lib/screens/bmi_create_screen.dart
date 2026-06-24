import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';

class BmiCreateScreen extends StatefulWidget {
  final VoidCallback? onSaved;
  const BmiCreateScreen({super.key, this.onSaved});

  @override
  State<BmiCreateScreen> createState() => _BmiCreateScreenState();
}

class _BmiCreateScreenState extends State<BmiCreateScreen> {
  final _tinggiController = TextEditingController();
  final _beratController = TextEditingController();
  final _usiaController = TextEditingController();
  String _gender = 'L';
  String _aktivitas = 'sedentary';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadExistingData();
  }

  Future<void> _loadExistingData() async {
    try {
      final res = await ApiService.getLatestBmi();
      if (!mounted) return;
      if (res['success'] == true && res['data'] != null) {
        final data = res['data'];
        setState(() {
          _tinggiController.text = data['tinggi_badan']?.toString() ?? '';
          _beratController.text = data['berat_badan']?.toString() ?? '';
          _usiaController.text = data['usia']?.toString() ?? '';
          _gender = data['jenis_kelamin'] ?? 'L';
          _aktivitas = data['aktivitas'] ?? 'sedentary';
        });
      }
    } catch (e) {
      // Abaikan jika gagal memuat (misal belum pernah isi)
    }
  }

  final List<Map<String, String>> _aktivitasOptions = [
    {'value': 'sedentary', 'label': 'Sangat Jarang Olahraga'},
    {'value': 'lightly_active', 'label': 'Jarang Olahraga (1-3 hari/minggu)'},
    {'value': 'moderately_active', 'label': 'Cukup Olahraga (3-5 hari/minggu)'},
    {'value': 'very_active', 'label': 'Sering Olahraga (6-7 hari/minggu)'},
    {'value': 'extra_active', 'label': 'Sangat Sering Olahraga / Atlet'},
  ];

  Future<void> _submit() async {
    if (_tinggiController.text.isEmpty || _beratController.text.isEmpty || _usiaController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Harap isi semua data')));
      return;
    }

    setState(() => _isLoading = true);

    try {
      final res = await ApiService.updateBmi(
        tinggi: double.parse(_tinggiController.text),
        berat: double.parse(_beratController.text),
        usia: int.parse(_usiaController.text),
        gender: _gender,
        aktivitas: _aktivitas,
      );

      if (mounted) {
        if (res['success'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Data BMI berhasil disimpan!')));
          if (widget.onSaved != null) {
            widget.onSaved!(); // Kembali ke tab dashboard
          } else if (Navigator.canPop(context)) {
            Navigator.pop(context, true);
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res['message'] ?? 'Gagal menyimpan data')));
        }
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('Hitung BMI & Kalori', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(25),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Lengkapi data fisik Anda untuk mendapatkan target nutrisi yang akurat.', 
              style: TextStyle(color: Colors.grey[600], fontSize: 14)),
            const SizedBox(height: 30),

            _buildLabel('JENIS KELAMIN'),
            Row(
              children: [
                _genderChip('Laki-laki', 'L'),
                const SizedBox(width: 15),
                _genderChip('Perempuan', 'P'),
              ],
            ),
            const SizedBox(height: 25),

            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLabel('TINGGI (CM)'),
                      _buildTextField(_tinggiController, 'Contoh: 170'),
                    ],
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLabel('BERAT (KG)'),
                      _buildTextField(_beratController, 'Contoh: 65'),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 25),

            _buildLabel('USIA (TAHUN)'),
            _buildTextField(_usiaController, 'Contoh: 25'),
            const SizedBox(height: 25),

            _buildLabel('TINGKAT AKTIVITAS'),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 15),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(12),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _aktivitas,
                  isExpanded: true,
                  onChanged: (val) => setState(() => _aktivitas = val!),
                  items: _aktivitasOptions.map((opt) {
                    return DropdownMenuItem(
                      value: opt['value'],
                      child: Text(opt['label']!, style: const TextStyle(fontSize: 14)),
                    );
                  }).toList(),
                ),
              ),
            ),
            const SizedBox(height: 40),

            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF16A34A),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  elevation: 0,
                ),
                child: _isLoading 
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Simpan & Hitung Sekarang', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4),
      child: Text(label, style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey[400])),
    );
  }

  Widget _buildTextField(TextEditingController controller, String hint) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: const Color(0xFFF1F5F9),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      ),
    );
  }

  Widget _genderChip(String label, String value) {
    final isSelected = _gender == value;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _gender = value),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 15),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF16A34A) : const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(12),
          ),
          alignment: Alignment.center,
          child: Text(label, style: TextStyle(color: isSelected ? Colors.white : Colors.black, fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }
}
