import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'ai_recipe_screen.dart';
import '../services/api_service.dart';

class FoodSearchScreen extends StatefulWidget {
  final String waktuMakan;
  const FoodSearchScreen({super.key, required this.waktuMakan});

  @override
  State<FoodSearchScreen> createState() => _FoodSearchScreenState();
}

class _FoodSearchScreenState extends State<FoodSearchScreen>
    with SingleTickerProviderStateMixin {
  final _searchController = TextEditingController();
  final _porsiController = TextEditingController(text: '100');

  List<dynamic> _allFoods = [];
  List<dynamic> _filteredFoods = [];
  bool _isLoading = true;
  late String _selectedSlot;
  bool _isSearchMode = false; // true = cari semua kategori
  bool _hasLoggedAnyFood = false;

  // Slot label mapping
  static const Map<String, Map<String, dynamic>> _slotInfo = {
    'sarapan':     {'label': 'Sarapan',    'icon': Icons.wb_sunny_outlined,     'color': Color(0xFFF59E0B)},
    'makan_siang': {'label': 'Siang',      'icon': Icons.wb_cloudy_outlined,    'color': Color(0xFF3B82F6)},
    'makan_malam': {'label': 'Malam',      'icon': Icons.nightlight_outlined,   'color': Color(0xFF8B5CF6)},
    'cemilan':     {'label': 'Cemilan',    'icon': Icons.cookie_outlined,       'color': Color(0xFFEF4444)},
  };

  @override
  void initState() {
    super.initState();
    _selectedSlot = widget.waktuMakan;
    _fetchFoods();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _porsiController.dispose();
    super.dispose();
  }

  /// Ambil semua makanan dari API (limit 200 sekarang)
  Future<void> _fetchFoods() async {
    setState(() => _isLoading = true);
    try {
      final res = await ApiService.getFoods();
      if (mounted) {
        setState(() {
          _allFoods = res['data'] ?? [];
          _isLoading = false;
        });
        _applyFilter(); // dipanggil setelah _allFoods terisi
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// Filter:
  /// - Tanpa search  → hanya tampilkan makanan sesuai slot yang dipilih
  /// - Ada search    → cari dari SEMUA kategori
  void _applyFilter() {
    final query = _searchController.text.trim().toLowerCase();
    List<dynamic> source;

    if (query.isEmpty) {
      // Filter KETAT: hanya makanan dari slot/kategori yang dipilih
      source = _allFoods
          .where((f) => f['kategori'] == _selectedSlot)
          .toList();
    } else {
      // Saat ada teks pencarian → cari di SEMUA kategori
      source = _allFoods
          .where((f) => f['nama_makanan'].toString().toLowerCase().contains(query))
          .toList();
    }

    setState(() {
      _filteredFoods = source;
      _isSearchMode = query.isNotEmpty;
    });
  }

  void _onSearchChanged(String query) {
    _applyFilter();
  }

  void _onSlotChanged(String slot) {
    // Update slot lalu apply filter dalam satu langkah
    _selectedSlot = slot;
    _applyFilter();
  }

  void _showPortionDialog(dynamic food) {
    _porsiController.text = '100';
    final slotColor = (_slotInfo[_selectedSlot]?['color'] as Color?) ?? const Color(0xFF16A34A);
    bool isSubmitting = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  food['nama_makanan'],
                  style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 4),
                // Info nutrisi per 100g
                Wrap(
                  spacing: 6,
                  children: [
                    _infoChip('🔥 ${food['kalori']} kkal', Colors.orange),
                    _infoChip('💪 P ${food['protein']}g', Colors.blue),
                    _infoChip('🌾 K ${food['karbohidrat']}g', Colors.amber),
                    _infoChip('🫙 L ${food['lemak']}g', Colors.red),
                  ],
                ),
                const SizedBox(height: 2),
                Text('per 100g', style: TextStyle(fontSize: 10, color: Colors.grey[400])),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Berapa gram yang kamu makan?',
                  style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _porsiController,
                  keyboardType: TextInputType.number,
                  autofocus: true,
                  decoration: InputDecoration(
                    suffixText: 'gram',
                    filled: true,
                    fillColor: const Color(0xFFF1F5F9),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: slotColor, width: 2),
                    ),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: isSubmitting ? null : () => Navigator.pop(context),
                child: const Text('Batal', style: TextStyle(color: Colors.grey)),
              ),
              ElevatedButton(
                onPressed: isSubmitting
                    ? null
                    : () {
                        setStateDialog(() {
                          isSubmitting = true;
                        });
                        Navigator.pop(context);
                        _logFood(food['id'], double.tryParse(_porsiController.text) ?? 100);
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: slotColor,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: isSubmitting
                    ? const SizedBox(
                        height: 16,
                        width: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Catat Makan', style: TextStyle(color: Colors.white)),
              ),
            ],
          );
        }
      ),
    );
  }

  Widget _infoChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(label, style: TextStyle(fontSize: 9, color: color, fontWeight: FontWeight.bold)),
    );
  }

  Future<void> _logFood(int foodId, double porsi) async {
    // Tampilkan dialog loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(color: Color(0xFF16A34A)),
      ),
    );

    try {
      final res = await ApiService.logFood(foodId, _selectedSlot, porsi: porsi);
      if (mounted) {
        Navigator.pop(context); // Tutup dialog loading
        if (res['success'] == true) {
          _hasLoggedAnyFood = true;
          final nextSlot = res['next_slot'] as String?;
          final oldSlot = _selectedSlot;

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(children: [
                const Icon(Icons.check_circle, color: Colors.white, size: 18),
                const SizedBox(width: 8),
                Expanded(child: Text('Berhasil dicatat ke ${_slotInfo[oldSlot]?['label']}!')),
              ]),
              backgroundColor: const Color(0xFF16A34A),
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 2),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          );

          if (nextSlot != null && nextSlot != oldSlot) {
            if (_slotInfo.containsKey(nextSlot)) {
              // Auto switch ke slot berikutnya
              setState(() {
                _selectedSlot = nextSlot;
                _searchController.clear();
              });
              _applyFilter();
              
              Future.delayed(const Duration(milliseconds: 500), () {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Target ${_slotInfo[oldSlot]?['label']} terpenuhi! Lanjut ke ${_slotInfo[nextSlot]?['label']}.'),
                      backgroundColor: Colors.blue[600],
                      behavior: SnackBarBehavior.floating,
                      duration: const Duration(seconds: 3),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  );
                }
              });
            } else {
              // Jika nextSlot bukan sarapan/siang/malam/cemilan
              Future.delayed(const Duration(milliseconds: 500), () {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Row(children: [
                        const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 18),
                        const SizedBox(width: 8),
                        Expanded(child: Text('Peringatan: Batas maksimal untuk ${_slotInfo[oldSlot]?['label']} sudah terpenuhi/berlebih!')),
                      ]),
                      backgroundColor: const Color(0xFFF59E0B), // Orange warning
                      behavior: SnackBarBehavior.floating,
                      duration: const Duration(seconds: 4),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  );
                }
              });
            }
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(res['message'] ?? 'Gagal mencatat')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Tutup dialog loading jika error
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Navigator.pop(context, _hasLoggedAnyFood);
        return false;
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          foregroundColor: Colors.black,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context, _hasLoggedAnyFood),
          ),
          title: Text(
            'Tambah Makanan',
            style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.auto_awesome, color: Color(0xFF16A34A)),
              tooltip: 'AI Resep & Gizi',
              onPressed: () async {
                final navigator = Navigator.of(context);
                final logged = await navigator.push(
                  MaterialPageRoute(
                    builder: (context) => AiRecipeScreen(waktuMakan: _selectedSlot),
                  ),
                );
                if (logged == true) {
                  navigator.pop(true);
                }
              },
            ),
          ],
        ),
      body: Column(
        children: [
          _buildTopSearch(),
          _buildSlotPicker(),
          if (!_isLoading) _buildResultInfo(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF16A34A)))
                : _buildFoodList(),
          ),
        ],
      ),
    ));
  }

  Widget _buildTopSearch() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: TextField(
        controller: _searchController,
        onChanged: _onSearchChanged,
        decoration: InputDecoration(
          hintText: 'Cari dari semua makanan...',
          hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
          prefixIcon: const Icon(Icons.search, color: Colors.grey),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, color: Colors.grey, size: 18),
                  onPressed: () {
                    _searchController.clear();
                    _applyFilter();
                  },
                )
              : null,
          filled: true,
          fillColor: const Color(0xFFF1F5F9),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 0),
        ),
      ),
    );
  }

  Widget _buildSlotPicker() {
    final slots = _slotInfo.keys.toList();
    return Container(
      height: 62,
      color: Colors.white,
      padding: const EdgeInsets.only(bottom: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: slots.length,
        itemBuilder: (context, index) {
          final s = slots[index];
          final info = _slotInfo[s]!;
          final isSelected = _selectedSlot == s;
          final color = info['color'] as Color;

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
            child: GestureDetector(
              onTap: () => _onSlotChanged(s),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: isSelected ? color : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: isSelected
                      ? [BoxShadow(color: color.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 3))]
                      : [],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      info['icon'] as IconData,
                      size: 14,
                      color: isSelected ? Colors.white : Colors.grey,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      info['label'] as String,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: isSelected ? Colors.white : Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildResultInfo() {
    final slotLabel = _slotInfo[_selectedSlot]?['label'] ?? _selectedSlot;
    final color = (_slotInfo[_selectedSlot]?['color'] as Color?) ?? const Color(0xFF16A34A);

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              _isSearchMode
                  ? '${_filteredFoods.length} hasil pencarian di semua kategori'
                  : '${_filteredFoods.length} makanan $slotLabel',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
          if (_isSearchMode) ...[
            const SizedBox(width: 8),
            Text(
              '(semua kategori)',
              style: TextStyle(fontSize: 10, color: Colors.grey[400]),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFoodList() {
    if (_filteredFoods.isEmpty) {
      return Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.search_off, size: 48, color: Colors.grey[300]),
              const SizedBox(height: 12),
              Text(
                'Makanan tidak ditemukan',
                style: GoogleFonts.plusJakartaSans(color: Colors.grey[400], fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              Text(
                'Coba kata kunci lain, atau gunakan AI Resep untuk membuat makanan kustom Anda.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: Colors.grey[500], height: 1.4),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () async {
                  final navigator = Navigator.of(context);
                  final logged = await navigator.push(
                    MaterialPageRoute(
                      builder: (context) => AiRecipeScreen(waktuMakan: _selectedSlot),
                    ),
                  );
                  if (logged == true) {
                    navigator.pop(true);
                  }
                },
                icon: const Icon(Icons.auto_awesome, size: 16),
                label: const Text('Buat & Catat dengan AI Resep', style: TextStyle(fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFBEF264),
                  foregroundColor: Colors.black,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      itemCount: _filteredFoods.length,
      itemBuilder: (context, index) {
        final food = _filteredFoods[index];
        final isSlotMatch = food['kategori'] == _selectedSlot;
        return _buildFoodCard(food, isSlotMatch);
      },
    );
  }

  Widget _buildFoodCard(dynamic food, bool isSlotMatch) {
    final slotColor = (_slotInfo[_selectedSlot]?['color'] as Color?) ?? const Color(0xFF16A34A);
    final foodKategori = food['kategori'] as String? ?? '';
    final kategoriInfo = _slotInfo[foodKategori];
    final kategoriColor = (kategoriInfo?['color'] as Color?) ?? Colors.grey;
    final kategoriLabel = (kategoriInfo?['label'] as String?) ?? foodKategori;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: isSlotMatch
            ? Border.all(color: slotColor.withOpacity(0.3), width: 1.5)
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _showPortionDialog(food),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              // Ikon kategori
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: kategoriColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  (kategoriInfo?['icon'] as IconData?) ?? Icons.restaurant,
                  color: kategoriColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            food['nama_makanan'],
                            style: GoogleFonts.plusJakartaSans(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        // Badge kategori jika bukan slot aktif
                        if (!isSlotMatch)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: kategoriColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              kategoriLabel,
                              style: TextStyle(
                                fontSize: 9,
                                color: kategoriColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Text(
                          '${food['kalori']} kkal',
                          style: TextStyle(
                            color: slotColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                        const Text(' / 100g', style: TextStyle(fontSize: 10, color: Colors.grey)),
                        const Spacer(),
                        _nutrientBadge('P ${food['protein']}g', Colors.blue),
                        _nutrientBadge('K ${food['karbohidrat']}g', Colors.orange),
                        _nutrientBadge('L ${food['lemak']}g', Colors.red),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: slotColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.add, color: slotColor, size: 18),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _nutrientBadge(String label, Color color) {
    return Container(
      margin: const EdgeInsets.only(left: 4),
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.bold),
      ),
    );
  }
}
