import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';
import 'athlete_detail_screen.dart';

class CoachDashboardScreen extends StatefulWidget {
  const CoachDashboardScreen({super.key});

  @override
  State<CoachDashboardScreen> createState() => _CoachDashboardScreenState();
}

class _CoachDashboardScreenState extends State<CoachDashboardScreen> with WidgetsBindingObserver {
  bool _isLoading = true;
  String _error = '';
  List<Map<String, dynamic>> _athletes = [];
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  Timer? _timer;

  double _pd(dynamic val, [double def = 0]) {
    if (val == null) return def;
    if (val is double) return val;
    if (val is int) return val.toDouble();
    if (val is String) return double.tryParse(val) ?? def;
    return def;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _fetchAthletes();
    _startRealtimeUpdates();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _timer?.cancel();
    } else if (state == AppLifecycleState.resumed) {
      _startRealtimeUpdates();
    }
  }

  void _startRealtimeUpdates() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 10), (timer) {
      _fetchAthletesSilent();
    });
  }

  Future<void> _fetchAthletesSilent() async {
    try {
      final res = await ApiService.getCoachAthletes();
      if (res['success'] == true) {
        final rawList = res['data'] as List<dynamic>? ?? [];
        if (mounted) {
          setState(() {
            _athletes = rawList.cast<Map<String, dynamic>>();
          });
        }
      }
    } catch (e) {
      debugPrint('Background update failed: $e');
    }
  }

  Future<void> _fetchAthletes() async {
    setState(() {
      _isLoading = true;
      _error = '';
    });

    try {
      final res = await ApiService.getCoachAthletes();
      if (res['success'] == true) {
        final rawList = res['data'] as List<dynamic>? ?? [];
        setState(() {
          _athletes = rawList.cast<Map<String, dynamic>>();
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = res['message'] ?? 'Gagal memuat daftar atlet';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Kesalahan koneksi: $e';
        _isLoading = false;
      });
    }
  }

  List<Map<String, dynamic>> get _filteredAthletes {
    if (_searchQuery.isEmpty) return _athletes;
    return _athletes
        .where((a) =>
            (a['name'] ?? '').toLowerCase().contains(_searchQuery.toLowerCase()) ||
            (a['email'] ?? '').toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ─────────────────────────────────────────
            Container(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
              color: Colors.white,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Dashboard Pelatih',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _isLoading
                        ? 'Memuat data atlet...'
                        : '${_athletes.length} atlet terdaftar',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      color: Colors.grey[500],
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Search bar
                  TextField(
                    controller: _searchController,
                    onChanged: (v) => setState(() => _searchQuery = v),
                    decoration: InputDecoration(
                      hintText: 'Cari atlet...',
                      hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
                      prefixIcon: Icon(Icons.search, color: Colors.grey[400]),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 18),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _searchQuery = '');
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade200),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade200),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFBEF264), width: 2),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── Stats Row ───────────────────────────────────────
            if (!_isLoading && _error.isEmpty)
              Container(
                color: Colors.white,
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                child: Row(
                  children: [
                    _buildStatChip(
                      label: 'Total Atlet',
                      value: '${_athletes.length}',
                      color: const Color(0xFF16A34A),
                      icon: Icons.people_rounded,
                    ),
                    const SizedBox(width: 10),
                    _buildStatChip(
                      label: 'Perlu Perhatian',
                      value: '${_athletes.where((a) => _needsAttention(a)).length}',
                      color: const Color(0xFFF59E0B),
                      icon: Icons.warning_rounded,
                    ),
                    const SizedBox(width: 10),
                    _buildStatChip(
                      label: 'Status Normal',
                      value: '${_athletes.where((a) => (a['bmi_category'] ?? '') == 'Normal').length}',
                      color: const Color(0xFF3B82F6),
                      icon: Icons.check_circle_rounded,
                    ),
                  ],
                ),
              ),

            // ── Body ────────────────────────────────────────────
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: Color(0xFF16A34A)),
                    )
                  : _error.isNotEmpty
                      ? _buildErrorState()
                      : _filteredAthletes.isEmpty
                          ? _buildEmptyState()
                          : RefreshIndicator(
                              onRefresh: _fetchAthletes,
                              color: const Color(0xFF16A34A),
                              child: ListView.builder(
                                padding: const EdgeInsets.all(16),
                                itemCount: _filteredAthletes.length,
                                itemBuilder: (context, index) {
                                  return _buildAthleteCard(_filteredAthletes[index]);
                                },
                              ),
                            ),
            ),
          ],
        ),
      ),
    );
  }

  bool _needsAttention(Map<String, dynamic> athlete) {
    final cat = (athlete['bmi_category'] ?? '').toString();
    return cat == 'Kurus' || cat.contains('Gemuk') || cat.contains('Obesitas');
  }

  Widget _buildStatChip({
    required String label,
    required String value,
    required Color color,
    required IconData icon,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 6),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                  Text(
                    label,
                    style: TextStyle(fontSize: 9, color: color.withOpacity(0.8)),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAthleteCard(Map<String, dynamic> athlete) {
    final String category = athlete['bmi_category'] ?? 'Belum diisi';
    Color bmiColor = const Color(0xFF10B981); // Normal (Green)
    if (category == 'Kurus') bmiColor = const Color(0xFF3B82F6);
    if (category == 'Gemuk') bmiColor = const Color(0xFFF59E0B);
    if (category.contains('Obesitas')) bmiColor = const Color(0xFFEF4444);
    if (category == 'Belum diisi') bmiColor = Colors.grey;

    final int consumed = _pd(athlete['calories_consumed']).toInt();
    final int target = _pd(athlete['calories_target'], 2000).toInt();
    final double progress = target > 0 ? (consumed / target).clamp(0.0, 1.0) : 0.0;

    // Inisial nama untuk avatar
    final String name = athlete['name'] ?? '-';
    final String initials = name.isNotEmpty
        ? name
            .split(' ')
            .take(2)
            .map((w) => w.isNotEmpty ? w[0].toUpperCase() : '')
            .join()
        : '?';

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AthleteDetailScreen(athleteId: athlete['id']),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Avatar dengan inisial
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: const Color(0xFF16A34A).withOpacity(0.12),
                    child: Text(
                      initials,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF16A34A),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: GoogleFonts.plusJakartaSans(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: const Color(0xFF1E293B),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          athlete['email'] ?? '',
                          style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  // BMI Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: bmiColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        Text(
                          athlete['bmi'] != null
                              ? '${athlete['bmi']}'
                              : '-',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: bmiColor,
                          ),
                        ),
                        Text(
                          category,
                          style: TextStyle(fontSize: 9, color: bmiColor, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Progress kalori
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Kalori hari ini',
                    style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                  ),
                  Text(
                    '$consumed / $target kkal',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF16A34A),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 6,
                  backgroundColor: const Color(0xFFF1F5F9),
                  color: progress > 1.0
                      ? const Color(0xFFEF4444)
                      : const Color(0xFF16A34A),
                ),
              ),
              if (athlete['last_bmi_update'] != null) ...[
                const SizedBox(height: 8),
                Text(
                  'Update terakhir: ${athlete['last_bmi_update']}',
                  style: TextStyle(fontSize: 10, color: Colors.grey[400]),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.wifi_off_rounded, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              'Gagal memuat data',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _error,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[500], fontSize: 13),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _fetchAthletes,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Coba Lagi'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFBEF264),
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.people_outline_rounded, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              _searchQuery.isNotEmpty ? 'Atlet tidak ditemukan' : 'Belum ada atlet',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _searchQuery.isNotEmpty
                  ? 'Coba kata kunci lain'
                  : 'Belum ada atlet yang terdaftar di sistem.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[500], fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}
