import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../services/api_service.dart';

class InsightScreen extends StatefulWidget {
  const InsightScreen({super.key});

  @override
  State<InsightScreen> createState() => _InsightScreenState();
}

class _InsightScreenState extends State<InsightScreen> {
  Map<String, dynamic>? _data;
  bool _loading = true;
  String? _error;

  String? _geminiApiKey;
  final TextEditingController _apiKeyController = TextEditingController();
  bool _isGeneratingAi = false;
  String? _aiResponse;

  @override
  void initState() {
    super.initState();
    _load();
    _loadApiKey();
  }

  Future<void> _loadApiKey() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _geminiApiKey = prefs.getString('gemini_api_key');
      if (_geminiApiKey != null) {
        _apiKeyController.text = _geminiApiKey!;
      }
    });
  }

  double _pd(dynamic val, [double def = 0]) {
    if (val == null) return def;
    if (val is double) return val;
    if (val is int) return val.toDouble();
    if (val is String) return double.tryParse(val) ?? def;
    return def;
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final res = await ApiService.getInsight();
      if (res['success'] == true) {
        setState(() { _data = res['data']; _loading = false; });
      } else {
        setState(() { _error = res['message'] ?? 'Gagal memuat insight'; _loading = false; });
      }
    } catch (e) {
      setState(() { _error = 'Tidak dapat terhubung ke server.'; _loading = false; });
    }
  }

  Color _bmiColor(double? bmi) {
    if (bmi == null || bmi == 0) return const Color(0xFF10b981);
    if (bmi < 18.5) return const Color(0xff3f6cb3);
    if (bmi < 25)   return const Color(0xFF10b981);
    if (bmi < 30)   return const Color(0xFFf59e0b);
    return const Color(0xFFef4444);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF10b981)))
          : _error != null
              ? _buildError()
              : _buildContent(),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Icon(Icons.bar_chart, size: 64, color: Color(0xFF94A3B8)),
        const SizedBox(height: 16),
        Text(_error!, style: GoogleFonts.inter(color: const Color(0xFF64748B))),
        const SizedBox(height: 16),
        ElevatedButton(onPressed: _load, style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10b981), foregroundColor: Colors.white), child: const Text('Coba Lagi')),
      ]),
    );
  }

  Widget _buildContent() {
    final d = _data!;
    final bmi = _pd(d['bmi']);
    final bmiColor = _bmiColor(bmi);
    final weekly = (d['weekly_summary'] as List?) ?? [];
    final targetKal = _pd(d['target_kalori'], 1);
    final consumedKal = _pd(d['consumed_kalori']);
    final pctKal = _pd(d['pct_kalori']).toInt();

    final macros = [
      {'label': 'Protein',    'cur': d['consumed_protein'], 'tar': d['target_protein'], 'color': const Color(0xFF3b82f6)},
      {'label': 'Karbohidrat','cur': d['consumed_karbo'],   'tar': d['target_karbo'],   'color': const Color(0xFFf59e0b)},
      {'label': 'Lemak',      'cur': d['consumed_lemak'],   'tar': d['target_lemak'],   'color': const Color(0xFFef4444)},
    ];

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          backgroundColor: Colors.white,
          pinned: true,
          title: Text('Insight Kesehatan', style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: const Color(0xFF1E293B))),
          actions: [IconButton(icon: const Icon(Icons.refresh_rounded, color: Color(0xFF10b981)), onPressed: _load)],
        ),
        SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: SliverList(delegate: SliverChildListDelegate([

            // BMI Card
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)]),
              child: Column(children: [
                Text('SKOR BMI', style: GoogleFonts.inter(fontSize: 10, letterSpacing: 1, fontWeight: FontWeight.w600, color: const Color(0xFF94A3B8))),
                const SizedBox(height: 8),
                Text(bmi == 0 ? '-' : bmi.toStringAsFixed(1), style: GoogleFonts.inter(fontSize: 52, fontWeight: FontWeight.w800, color: bmiColor, height: 1)),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                  decoration: BoxDecoration(color: bmiColor.withOpacity(0.1), borderRadius: BorderRadius.circular(99)),
                  child: Text(d['status'] ?? '-', style: GoogleFonts.inter(color: bmiColor, fontWeight: FontWeight.w700, fontSize: 13)),
                ),
                const SizedBox(height: 20),
                Row(children: [
                  _miniStat('Tinggi', '${d['tinggi_badan'] ?? '-'} cm'),
                  const SizedBox(width: 10),
                  _miniStat('Berat', '${d['berat_badan'] ?? '-'} kg'),
                  const SizedBox(width: 10),
                  _miniStat('Ideal', '${d['berat_ideal'] ?? '-'} kg'),
                ]),
              ]),
            ),
            const SizedBox(height: 16),

            // Calorie Progress
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)]),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Text('Kalori Hari Ini', style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: const Color(0xFF1E293B))),
                  Text('$pctKal%', style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: const Color(0xFF10b981))),
                ]),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(99),
                  child: LinearProgressIndicator(
                    value: (consumedKal / targetKal).clamp(0.0, 1.0),
                    minHeight: 12,
                    backgroundColor: const Color(0xFFF1F5F9),
                    valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF10b981)),
                  ),
                ),
                const SizedBox(height: 8),
                Text('${consumedKal.toInt()} / ${targetKal.toInt()} kkal', style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF64748B))),
              ]),
            ),
            const SizedBox(height: 16),

            // Weekly Chart
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)]),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Tren Kalori 7 Hari', style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: const Color(0xFF1E293B))),
                const SizedBox(height: 4),
                Text('Perbandingan asupan harian', style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF94A3B8))),
                const SizedBox(height: 20),
                SizedBox(
                  height: 140,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: weekly.map<Widget>((day) {
                      final kal = _pd(day['kalori']);
                      final tar = _pd(day['target'], 1);
                      final pct = (kal / tar).clamp(0.05, 1.0);
                      final isToday = day['date'] == DateTime.now().toIso8601String().split('T')[0];
                      return Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 3),
                          child: Column(mainAxisAlignment: MainAxisAlignment.end, children: [
                            Text('${kal.toInt()}', style: GoogleFonts.inter(fontSize: 8, color: const Color(0xFF94A3B8))),
                            const SizedBox(height: 4),
                            Expanded(
                              child: FractionallySizedBox(
                                alignment: Alignment.bottomCenter,
                                heightFactor: pct,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: isToday ? const Color(0xFF10b981) : const Color(0xFF10b981).withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(day['day'] ?? '', style: GoogleFonts.inter(fontSize: 10, fontWeight: isToday ? FontWeight.w700 : FontWeight.w400, color: isToday ? const Color(0xFF10b981) : const Color(0xFF94A3B8))),
                          ]),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ]),
            ),
            const SizedBox(height: 16),

            // Macros
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)]),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Distribusi Makronutrisi', style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: const Color(0xFF1E293B))),
                const SizedBox(height: 16),
                ...macros.map((m) {
                  final cur = _pd(m['cur']);
                  final tar = _pd(m['tar'], 1);
                  final pct = (cur / tar).clamp(0.0, 1.0);
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                        Text(m['label'] as String, style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13, color: const Color(0xFF374151))),
                        Text('${cur.toInt()} / ${tar.toInt()}g', style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF94A3B8))),
                      ]),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(99),
                        child: LinearProgressIndicator(value: pct, minHeight: 8, backgroundColor: const Color(0xFFF1F5F9), valueColor: AlwaysStoppedAnimation<Color>(m['color'] as Color)),
                      ),
                    ]),
                  );
                }),
              ]),
            ),
            _buildAiRecommendationCard(),
            const SizedBox(height: 24),
          ])),
        ),
      ],
    );
  }

  Widget _miniStat(String label, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(12)),
        child: Column(children: [
          Text(label, style: GoogleFonts.inter(fontSize: 10, color: const Color(0xFF94A3B8))),
          const SizedBox(height: 4),
          Text(value, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: const Color(0xFF1E293B))),
        ]),
      ),
    );
  }

  Future<void> _generateAiAnalysis() async {
    if (_geminiApiKey == null || _geminiApiKey!.isEmpty) return;
    setState(() {
      _isGeneratingAi = true;
      _aiResponse = null;
    });

    final d = _data!;
    final bmi = _pd(d['bmi']);
    final bmiStatus = d['status'] ?? '-';
    final height = d['tinggi_badan'] ?? '-';
    final weight = d['berat_badan'] ?? '-';
    final idealWeight = d['berat_ideal'] ?? '-';
    final targetKal = _pd(d['target_kalori']);
    final consumedKal = _pd(d['consumed_kalori']);
    final protein = d['consumed_protein'] ?? 0;
    final targetProtein = d['target_protein'] ?? 0;
    final karbo = d['consumed_karbo'] ?? 0;
    final targetKarbo = d['target_karbo'] ?? 0;
    final lemak = d['consumed_lemak'] ?? 0;
    final targetLemak = d['target_lemak'] ?? 0;

    final prompt = """
Analisis data gizi harian saya berikut ini:
- Skor BMI: $bmi (Status: $bmiStatus)
- Tinggi Badan: $height cm, Berat Badan: $weight kg (Berat Ideal: $idealWeight kg)
- Asupan Kalori Hari Ini: $consumedKal kkal dari target $targetKal kkal
- Asupan Protein: ${protein}g dari target ${targetProtein}g
- Asupan Karbohidrat: ${karbo}g dari target ${targetKarbo}g
- Asupan Lemak: ${lemak}g dari target ${targetLemak}g

Berdasarkan data di atas, tolong berikan analisis gizi dan rekomendasi pola makan singkat, terfokus, praktis, dan memotivasi dalam Bahasa Indonesia. Format dalam bullet points markdown. Batasi maksimal 3 poin penting saja. Jangan beri kalimat pengantar yang terlalu panjang.
""";

    try {
      final model = GenerativeModel(
        model: 'gemini-1.5-flash',
        apiKey: _geminiApiKey!,
      );

      final content = [Content.text(prompt)];
      final response = await model.generateContent(content);
      setState(() {
        _aiResponse = response.text;
        _isGeneratingAi = false;
      });
    } catch (e) {
      setState(() {
        _aiResponse = "Gagal memproses rekomendasi AI: $e\n\nPastikan API Key Google AI Studio Anda valid.";
        _isGeneratingAi = false;
      });
    }
  }

  Widget _buildAiRecommendationCard() {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFECFDF5), Color(0xFFF0FDF4)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFBEF264).withOpacity(0.5), width: 1.5),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.psychology_rounded, color: Color(0xFF16A34A), size: 24),
              const SizedBox(width: 8),
              Text(
                'AI Nutrition Assistant',
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: const Color(0xFF1E293B),
                ),
              ),
              const Spacer(),
              if (_geminiApiKey != null)
                IconButton(
                  icon: const Icon(Icons.settings, color: Colors.grey, size: 18),
                  onPressed: () {
                    setState(() {
                      _geminiApiKey = null;
                    });
                  },
                  tooltip: 'Ganti API Key',
                  constraints: const BoxConstraints(),
                  padding: EdgeInsets.zero,
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (_geminiApiKey == null) ...[
            Text(
              'Aktifkan analisis gizi pintar secara instan menggunakan Google Gemini Pro.',
              style: TextStyle(fontSize: 12, color: Colors.grey[600], height: 1.4),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _apiKeyController,
              obscureText: true,
              decoration: InputDecoration(
                hintText: 'Masukkan Gemini API Key Anda',
                hintStyle: TextStyle(color: Colors.grey[400], fontSize: 13),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: Colors.grey.shade200),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: Colors.grey.shade200),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Color(0xFF16A34A), width: 1.5),
                ),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  final key = _apiKeyController.text.trim();
                  if (key.isNotEmpty) {
                    final prefs = await SharedPreferences.getInstance();
                    await prefs.setString('gemini_api_key', key);
                    setState(() {
                      _geminiApiKey = key;
                    });
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFBEF264),
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  elevation: 0,
                ),
                child: const Text('Simpan & Aktifkan AI', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              ),
            ),
          ] else ...[
            if (_aiResponse == null && !_isGeneratingAi) ...[
              Text(
                'Dapatkan saran menu makanan, analisis BMI, dan tips kesehatan personal dari AI berdasarkan riwayat Anda.',
                style: TextStyle(fontSize: 12, color: Colors.grey[600], height: 1.4),
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _generateAiAnalysis,
                  icon: const Icon(Icons.auto_awesome, size: 16),
                  label: const Text('Tanya Asisten AI', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFBEF264),
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    elevation: 0,
                  ),
                ),
              ),
            ] else if (_isGeneratingAi) ...[
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Column(
                    children: [
                      CircularProgressIndicator(color: Color(0xFF16A34A)),
                      SizedBox(height: 12),
                      Text('Gemini sedang menganalisis gizi Anda...', style: TextStyle(fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                ),
              ),
            ] else if (_aiResponse != null) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade100),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _aiResponse!,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12.5,
                        color: const Color(0xFF334155),
                        height: 1.6,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Divider(height: 1),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Analisis AI realtime', style: TextStyle(fontSize: 9, color: Colors.grey[400])),
                        TextButton.icon(
                          onPressed: _generateAiAnalysis,
                          icon: const Icon(Icons.refresh, size: 12, color: Color(0xFF16A34A)),
                          label: const Text('Analisis Ulang', style: TextStyle(fontSize: 11, color: Color(0xFF16A34A), fontWeight: FontWeight.bold)),
                          style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: Size.zero, tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }
}
