// lib/config/app_config.dart
// ── Konfigurasi Terpusat Aplikasi ────────────────────────────
import 'package:flutter/foundation.dart';

class AppConfig {
  // ─── BASE URL ───────────────────────────────────────────────
  // Lokal (Laragon) — gunakan IP WiFi laptop agar HP bisa akses di jaringan sama
  static const String _localUrl = 'http://192.168.1.6/gizi-app/public/api';

  // Production (setelah deploy ke VPS/hosting):
  // ⚠️ WAJIB menggunakan HTTPS untuk keamanan data dan mencegah serangan MITM
  static const String _productionUrl = 'https://api.giziapp.com/api'; // Ganti dengan domain produksi asli Anda

  // Otomatis memilih URL berdasarkan mode aplikasi (Debug menggunakan lokal, Release menggunakan produksi secure)
  static const String baseUrl = kDebugMode ? _localUrl : _productionUrl;


  // ─── APP INFO ───────────────────────────────────────────────
  static const String appName    = 'GiziApp';
  static const String appVersion = '1.0.0';

  // ─── TIMEOUT ────────────────────────────────────────────────
  static const Duration connectTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 30);
}
