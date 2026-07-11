import 'package:google_generative_ai/google_generative_ai.dart';

class GeminiService {
  // ⚠️ GANTI dengan API Key Pro Anda dari Google AI Studio
  static const String _apiKey = "AQ.Ab8RN6KFaLtbmdowgEqjHSiX0klVorvQFdiwVE9AsduFK0V1_g";

  /// Fungsi untuk mengirim pertanyaan/prompt ke Gemini Pro
  Future<String?> tanyaGemini(String promptText) async {
    try {
      // Menggunakan model gemini-1.5-pro sesuai dengan hak akses Pro Anda
      final model = GenerativeModel(
        model: 'gemini-1.5-pro',
        apiKey: _apiKey,
      );

      final content = [Content.text(promptText)];
      final response = await model.generateContent(content);
      
      // Mengembalikan teks respons dari Gemini
      return response.text;
    } catch (e) {
      // Jika terjadi error (misal masalah jaringan atau API key)
      return "Terjadi kesalahan: $e";
    }
  }
}