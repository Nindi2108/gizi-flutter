import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';
import 'food_search_screen.dart';

class FoodHistoryScreen extends StatefulWidget {
  const FoodHistoryScreen({super.key});

  @override
  State<FoodHistoryScreen> createState() => _FoodHistoryScreenState();
}

class _FoodHistoryScreenState extends State<FoodHistoryScreen> {
  List<dynamic> _historyData = [];
  bool _isLoading = true;
  bool _isDeleting = false;
  String? _error;

  // Track which days are expanded
  final Set<int> _expandedDays = {0}; // Hari ini (index 0) dibuka default

  static const Map<String, Map<String, dynamic>> _slotInfo = {
    'sarapan':     {'label': 'Sarapan',    'icon': Icons.wb_sunny_outlined,   'color': Color(0xFFF59E0B)},
    'makan_siang': {'label': 'Makan Siang','icon': Icons.wb_cloudy_outlined,  'color': Color(0xFF3B82F6)},
    'makan_malam': {'label': 'Makan Malam','icon': Icons.nightlight_outlined, 'color': Color(0xFF8B5CF6)},
    'cemilan':     {'label': 'Cemilan',    'icon': Icons.cookie_outlined,     'color': Color(0xFFEF4444)},
  };

  @override
  void initState() {
    super.initState();
    _fetchHistory();
  }

  Future<void> _fetchHistory() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final res = await ApiService.getFoodHistory(days: 7);
      if (res['success'] == true) {
        setState(() {
          _historyData = res['data'] ?? [];
          _isLoading = false;
        });
      } else {
        setState(() { _error = res['message'] ?? 'Gagal memuat history'; _isLoading = false; });
      }
    } catch (e) {
      setState(() { _error = 'Tidak dapat terhubung ke server'; _isLoading = false; });
    }
  }

  Future<void> _deleteFoodLog(dynamic item) async {
    final logId = item['id'];
    if (logId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ID log tidak ditemukan'), backgroundColor: Colors.red),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFEF4444).withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.delete_outline, color: Color(0xFFEF4444), size: 20),
            ),
            const SizedBox(width: 12),
            Text(
              'Hapus Makanan',
              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ],
        ),
        content: Text(
          'Yakin ingin menghapus "${item['food_name'] ?? 'makanan ini'}" dari catatan?',
          style: GoogleFonts.plusJakartaSans(fontSize: 14, color: const Color(0xFF64748B)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'Batal',
              style: GoogleFonts.plusJakartaSans(color: const Color(0xFF94A3B8), fontWeight: FontWeight.w600),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
            child: Text(
              'Hapus',
              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isDeleting = true);
    try {
      final res = await ApiService.deleteFoodLog(logId is int ? logId : int.parse(logId.toString()));
      if (res['success'] == true) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.white, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '"${item['food_name']}" berhasil dihapus',
                      style: GoogleFonts.plusJakartaSans(color: Colors.white),
                    ),
                  ),
                ],
              ),
              backgroundColor: const Color(0xFF16A34A),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              margin: const EdgeInsets.all(16),
            ),
          );
        }
        await _fetchHistory();
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(res['message'] ?? 'Gagal menghapus makanan'),
              backgroundColor: const Color(0xFFEF4444),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              margin: const EdgeInsets.all(16),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Tidak dapat terhubung ke server'),
            backgroundColor: const Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isDeleting = false);
    }
  }

  double _pd(dynamic val, [double def = 0]) {
    if (val == null) return def;
    if (val is double) return val;
    if (val is int) return val.toDouble();
    if (val is String) return double.tryParse(val) ?? def;
    return def;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: CustomScrollView(
        slivers: [
          // App Bar
          SliverAppBar(
            backgroundColor: Colors.white,
            pinned: true,
            elevation: 0,
            title: Text(
              'Riwayat Makan',
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: const Color(0xFF1E293B),
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh_rounded, color: Color(0xFF16A34A)),
                onPressed: _fetchHistory,
              ),
            ],
          ),

          if (_isLoading || _isDeleting)
            const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator(color: Color(0xFF16A34A))),
            )
          else if (_error != null)
            SliverFillRemaining(child: _buildError())
          else if (_historyData.isEmpty)
            SliverFillRemaining(child: _buildEmpty())
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (ctx, i) => _buildDayCard(i, _historyData[i]),
                  childCount: _historyData.length,
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final refresh = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const FoodSearchScreen(waktuMakan: 'sarapan'),
            ),
          );
          if (refresh == true) _fetchHistory();
        },
        backgroundColor: const Color(0xFF16A34A),
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text(
          'Tambah Log',
          style: GoogleFonts.plusJakartaSans(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Icon(Icons.cloud_off_rounded, size: 56, color: Color(0xFFCBD5E1)),
        const SizedBox(height: 16),
        Text(_error!, style: GoogleFonts.plusJakartaSans(color: const Color(0xFF64748B))),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: _fetchHistory,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF16A34A),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: const Text('Coba Lagi'),
        ),
      ]),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(color: Colors.grey[100], shape: BoxShape.circle),
          child: const Icon(Icons.restaurant_menu_outlined, size: 56, color: Colors.grey),
        ),
        const SizedBox(height: 20),
        Text(
          'Belum ada catatan makan',
          style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          'Mulai catat makananmu hari ini!',
          style: TextStyle(color: Colors.grey[500], fontSize: 13),
        ),
      ]),
    );
  }

  Widget _buildDayCard(int index, dynamic dayData) {
    final isExpanded = _expandedDays.contains(index);
    final totalKal  = _pd(dayData['total']?['kalori']);
    final targetKal = _pd(dayData['target'], 2000);
    final pct       = _pd(dayData['pct']);
    final label     = dayData['label'] ?? dayData['date'] ?? '-';
    final logsData  = dayData['logs'];
    final logs      = (logsData is Map) ? Map<String, dynamic>.from(logsData) : <String, dynamic>{};
    final hasLogs   = logs.isNotEmpty;
    final isToday   = index == 0;

    Color progressColor = const Color(0xFF16A34A);
    if (pct > 110) progressColor = const Color(0xFFEF4444);
    else if (pct > 90) progressColor = const Color(0xFFF59E0B);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: isToday
            ? Border.all(color: const Color(0xFF16A34A).withOpacity(0.4), width: 1.5)
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header hari — bisa di-tap untuk expand/collapse
          InkWell(
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(20),
              topRight: const Radius.circular(20),
              bottomLeft: Radius.circular(isExpanded ? 0 : 20),
              bottomRight: Radius.circular(isExpanded ? 0 : 20),
            ),
            onTap: hasLogs
                ? () => setState(() {
                    if (isExpanded) _expandedDays.remove(index);
                    else _expandedDays.add(index);
                  })
                : null,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      // Ikon status
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: hasLogs
                              ? progressColor.withOpacity(0.1)
                              : Colors.grey[100],
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          hasLogs ? Icons.check_circle_outline : Icons.radio_button_unchecked,
                          color: hasLogs ? progressColor : Colors.grey[400],
                          size: 18,
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
                                    label,
                                    style: GoogleFonts.plusJakartaSans(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                      color: const Color(0xFF1E293B),
                                    ),
                                  ),
                                ),
                                if (isToday)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF16A34A),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      'Hari Ini',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 10,
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              hasLogs
                                  ? '${totalKal.toInt()} / ${targetKal.toInt()} kkal  •  $pct%'
                                  : 'Belum ada catatan makan',
                              style: TextStyle(
                                fontSize: 12,
                                color: hasLogs ? progressColor : Colors.grey[400],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (hasLogs)
                        Icon(
                          isExpanded ? Icons.expand_less : Icons.expand_more,
                          color: Colors.grey[400],
                        ),
                    ],
                  ),

                  // Progress bar (hanya jika ada log)
                  if (hasLogs) ...[
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(99),
                      child: LinearProgressIndicator(
                        value: (pct / 100).clamp(0.0, 1.0),
                        minHeight: 6,
                        backgroundColor: const Color(0xFFF1F5F9),
                        valueColor: AlwaysStoppedAnimation<Color>(progressColor),
                      ),
                    ),
                    const SizedBox(height: 10),
                    // Makro ringkas
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _macroChip('P', '${_pd(dayData['total']?['protein']).toInt()}g', Colors.blue),
                        _macroChip('K', '${_pd(dayData['total']?['karbohidrat']).toInt()}g', Colors.orange),
                        _macroChip('L', '${_pd(dayData['total']?['lemak']).toInt()}g', Colors.red),
                        Text(
                          '${logs.length} slot makan',
                          style: TextStyle(fontSize: 11, color: Colors.grey[400]),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),

          // Detail logs (expandable)
          if (isExpanded && hasLogs) ...[
            const Divider(height: 1, color: Color(0xFFF1F5F9)),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: Column(
                children: _slotInfo.entries
                    .where((e) => logs.containsKey(e.key))
                    .map((e) => _buildSlotSection(e.key, logs[e.key] as List))
                    .toList(),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSlotSection(String slot, List items) {
    final info  = _slotInfo[slot]!;
    final color = info['color'] as Color;
    final label = info['label'] as String;
    final icon  = info['icon'] as IconData;

    final slotKal = items.fold<double>(0, (sum, item) => sum + _pd(item['kalori']));

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Slot header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 14),
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              const Spacer(),
              Text(
                '${slotKal.toInt()} kkal',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Items
          ...items.map((item) => _buildDismissibleLogItem(item, color)),
        ],
      ),
    );
  }

  Widget _buildDismissibleLogItem(dynamic item, Color slotColor) {
    final logId = item['id'];
    return Dismissible(
      key: Key('food-log-${logId ?? item.hashCode}'),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) async {
        await _deleteFoodLog(item);
        return false; // We handle removal via _fetchHistory
      },
      background: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: const Color(0xFFEF4444),
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.centerRight,
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.delete_outline, color: Colors.white, size: 18),
            SizedBox(width: 4),
            Text('Hapus', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
          ],
        ),
      ),
      child: _buildLogItem(item, slotColor),
    );
  }

  Widget _buildLogItem(dynamic item, Color slotColor) {
    final kal   = _pd(item['kalori']);
    final porsi = _pd(item['porsi_gram'], 100);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          // Dot
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: slotColor, shape: BoxShape.circle),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item['food_name'] ?? '-',
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    _miniNutrient('P ${_pd(item['protein']).toStringAsFixed(1)}g', Colors.blue),
                    _miniNutrient('K ${_pd(item['karbohidrat']).toStringAsFixed(1)}g', Colors.orange),
                    _miniNutrient('L ${_pd(item['lemak']).toStringAsFixed(1)}g', Colors.red),
                    Text(
                      ' • ${porsi.toInt()}g',
                      style: const TextStyle(fontSize: 10, color: Colors.grey),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Text(
            '${kal.toInt()} kkal',
            style: GoogleFonts.plusJakartaSans(
              fontWeight: FontWeight.bold,
              fontSize: 13,
              color: slotColor,
            ),
          ),
          const SizedBox(width: 4),
          // Delete button
          GestureDetector(
            onTap: () => _deleteFoodLog(item),
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFFEF4444).withOpacity(0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.delete_outline, color: Color(0xFFEF4444), size: 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _macroChip(String label, String value, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 6, height: 6,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          '$label: $value',
          style: TextStyle(fontSize: 11, color: Colors.grey[600], fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  Widget _miniNutrient(String label, Color color) {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: Text(
        label,
        style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w600),
      ),
    );
  }
}
