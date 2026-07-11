// lib/config/app_config.dart
// ── Konfigurasi Terpusat Aplikasi ────────────────────────────
// Ganti baseUrl sesuai environment. Untuk production, ganti ke URL server publik.

class AppConfig {
  // ─── BASE URL ───────────────────────────────────────────────
  // Lokal (Laragon) — gunakan IP WiFi laptop agar HP bisa akses di jaringan sama
  // Contoh: 'http://192.168.1.7/gizi-app/public/api'
  //
  // Production (setelah deploy ke VPS/hosting):
  // Contoh: 'https://api.giziapp.com/api'
  static const String baseUrl = 'https://gizi-app.onrender.com/api';


  // ─── APP INFO ───────────────────────────────────────────────
  static const String appName    = 'GiziApp';
  static const String appVersion = '1.0.0';

  // ─── TIMEOUT ────────────────────────────────────────────────
  static const Duration connectTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 30);
}
