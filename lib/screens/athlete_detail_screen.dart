import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';

class AthleteDetailScreen extends StatefulWidget {
  final int athleteId;

  const AthleteDetailScreen({super.key, required this.athleteId});

  @override
  State<AthleteDetailScreen> createState() => _AthleteDetailScreenState();
}

class _AthleteDetailScreenState extends State<AthleteDetailScreen> with WidgetsBindingObserver {
  bool _isLoading = true;
  String _error = '';
  Map<String, dynamic>? _data;
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
    _fetchDetail();
    _startRealtimeUpdates();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
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
      _fetchDetailSilent();
    });
  }

  Future<void> _fetchDetailSilent() async {
    try {
      final res = await ApiService.getCoachAthleteDetail(widget.athleteId);
      if (res['success'] == true) {
        if (mounted) {
          setState(() {
            _data = res['data'];
          });
        }
      }
    } catch (e) {
      debugPrint('Background update failed: $e');
    }
  }

  Future<void> _fetchDetail() async {
    setState(() {
      _isLoading = true;
      _error = '';
    });

    try {
      final res = await ApiService.getCoachAthleteDetail(widget.athleteId);
      if (res['success'] == true) {
        setState(() {
          _data = res['data'];
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = res['message'] ?? 'Gagal memuat detail atlet';
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          'Detail Atlet',
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.bold,
            color: const Color(0xFF1E293B),
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _fetchDetail,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF16A34A)),
            )
          : _error.isNotEmpty
              ? _buildErrorState()
              : _buildContent(),
    );
  }

  Widget _buildContent() {
    final athlete = _data!['athlete'] as Map<String, dynamic>;
    final bmi = _data!['bmi'] as Map<String, dynamic>?;
    final int caloriesConsumed = _pd(_data!['calories_today']).toInt();
    final int caloriesTarget = _pd(_data!['calories_target'], 2000).toInt();
    final recentLogs = (_data!['recent_food_logs'] as List<dynamic>?) ?? [];

    final String name = athlete['name'] ?? '-';
    final String initials = name
        .split(' ')
        .take(2)
        .map((w) => w.isNotEmpty ? w[0].toUpperCase() : '')
        .join();

    Color bmiColor = const Color(0xFF10B981);
    if (bmi != null) {
      final cat = bmi['category'] ?? '';
      if (cat == 'Kurus') bmiColor = const Color(0xFF3B82F6);
      if (cat == 'Gemuk') bmiColor = const Color(0xFFF59E0B);
      if (cat.toString().contains('Obesitas')) bmiColor = const Color(0xFFEF4444);
    }

    final double progressPct = caloriesTarget > 0
        ? (caloriesConsumed / caloriesTarget).clamp(0.0, 1.0)
        : 0.0;

    return RefreshIndicator(
      onRefresh: _fetchDetail,
      color: const Color(0xFF16A34A),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Profile Card ──────────────────────────────────
            Center(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 48,
                    backgroundColor: const Color(0xFF16A34A).withOpacity(0.12),
                    child: Text(
                      initials,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF16A34A),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    name,
                    style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                      color: const Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    athlete['email'] ?? '',
                    style: TextStyle(color: Colors.grey[500], fontSize: 13),
                  ),
                  if (bmi != null && bmi['last_update'] != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Data terakhir: ${bmi['last_update']}',
                      style: TextStyle(color: Colors.grey[400], fontSize: 11),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 28),

            // ── BMI Status ────────────────────────────────────
            _buildSectionTitle('Status BMI'),
            const SizedBox(height: 10),
            bmi == null
                ? _buildEmptyCard('Atlet belum mengisi data fisik.')
                : Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: _cardDecoration(),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Skor BMI',
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${bmi['skor']}',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 32,
                                    fontWeight: FontWeight.bold,
                                    color: bmiColor,
                                  ),
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: bmiColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                bmi['category'] ?? '-',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: bmiColor,
                                  fontSize: 15,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        const Divider(height: 1),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildBmiStat('Tinggi', '${bmi['tinggi_badan']} cm'),
                            _buildBmiStat('Berat', '${bmi['berat_badan']} kg'),
                            _buildBmiStat(
                                'Target Kalori', '${bmi['kalori_target']} kkal'),
                          ],
                        ),
                      ],
                    ),
                  ),
            const SizedBox(height: 24),

            // ── Asupan Kalori ─────────────────────────────────
            _buildSectionTitle('Asupan Kalori Hari Ini'),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: _cardDecoration(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total Asupan',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      Text(
                        '$caloriesConsumed / $caloriesTarget kkal',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF16A34A),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LinearProgressIndicator(
                      value: progressPct,
                      minHeight: 12,
                      backgroundColor: const Color(0xFFF1F5F9),
                      color: const Color(0xFF16A34A),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    '${(progressPct * 100).toStringAsFixed(0)}% dari target harian terpenuhi',
                    style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ── Riwayat Makanan ───────────────────────────────
            _buildSectionTitle('Riwayat Makanan (7 hari)'),
            const SizedBox(height: 10),
            recentLogs.isEmpty
                ? _buildEmptyCard('Belum ada log makanan.')
                : Container(
                    decoration: _cardDecoration(),
                    child: ListView.separated(
                      physics: const NeverScrollableScrollPhysics(),
                      shrinkWrap: true,
                      itemCount: recentLogs.length,
                      separatorBuilder: (_, __) =>
                          const Divider(height: 1, indent: 16, endIndent: 16),
                      itemBuilder: (context, index) {
                        final log = recentLogs[index] as Map<String, dynamic>;
                        return ListTile(
                          dense: true,
                          leading: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: const Color(0xFF16A34A).withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.restaurant_rounded,
                              size: 16,
                              color: Color(0xFF16A34A),
                            ),
                          ),
                          title: Text(
                            log['nama_makanan'] ?? '-',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          subtitle: Text(
                            '${log['waktu_makan']} · ${log['porsi_gram']}g',
                            style:
                                TextStyle(fontSize: 11, color: Colors.grey[500]),
                          ),
                          trailing: Text(
                            '${log['kalori']} kkal',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              color: Color(0xFF16A34A),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildBmiStat(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF1E293B),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(fontSize: 11, color: Colors.grey[500]),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.plusJakartaSans(
        fontWeight: FontWeight.bold,
        fontSize: 16,
        color: const Color(0xFF1E293B),
      ),
    );
  }

  Widget _buildEmptyCard(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration(),
      child: Text(
        message,
        style: TextStyle(color: Colors.grey[500], fontStyle: FontStyle.italic),
        textAlign: TextAlign.center,
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
            const Icon(Icons.error_outline_rounded, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              _error,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[500]),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _fetchDetail,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Coba Lagi'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFBEF264),
                foregroundColor: Colors.black,
                shape:
                    RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.03),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }
}
