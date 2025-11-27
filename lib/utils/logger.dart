import 'package:flutter/foundation.dart';

class Logger {
  // 通常のログ
  static void log(String message) {
    if (kDebugMode) {
      print(message);
    }
  }

  // エラーログ
  static void error(String message) {
    if (kDebugMode) {
      print('❌ エラー: $message');
    }
  }

  // 警告ログ
  static void warning(String message) {
    if (kDebugMode) {
      print('⚠️ 警告: $message');
    }
  }

  // 成功ログ
  static void success(String message) {
    if (kDebugMode) {
      print('✅ $message');
    }
  }

  // デバッグログ（詳細情報）
  static void debug(String message) {
    if (kDebugMode) {
      print('🔍 デバッグ: $message');
    }
  }

  // セクション開始
  static void section(String title) {
    if (kDebugMode) {
      print('\n=== $title ===');
    }
  }

  // セクション終了
  static void sectionEnd(String title) {
    if (kDebugMode) {
      print('=== $title 終了 ===\n');
    }
  }
}
