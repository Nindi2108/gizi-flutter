import 'package:google_generative_ai/google_generative_ai.dart';

class GeminiService {
  final String apiKey;

  GeminiService({required this.apiKey});

  /// Fungsi untuk mengirim pertanyaan/prompt ke Gemini Pro
  Future<String?> tanyaGemini(String promptText) async {
    if (apiKey.isEmpty) {
      return "Terjadi kesalahan: API Key tidak boleh kosong.";
    }
    try {
      // Menggunakan model gemini-1.5-pro sesuai dengan hak akses Pro Anda
      final model = GenerativeModel(
        model: 'gemini-1.5-pro',
        apiKey: apiKey,
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