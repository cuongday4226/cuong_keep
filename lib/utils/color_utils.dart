import 'package:flutter/material.dart';

class ColorUtils {
  // Lấy màu nền thích hợp cho giao diện Sáng/Tối
  static Color getAdaptiveColor(BuildContext context, int? colorValue) {
    if (colorValue == null) return Theme.of(context).cardColor;
    
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Nếu giao diện đang ở chế độ Tối (Dark Mode), ta tự động chuyển các màu sáng (từ database) thành màu tối tương ứng
    if (isDark) {
      if (colorValue == Colors.red.shade100.value) return const Color(0xFF5C2B29);
      if (colorValue == Colors.green.shade100.value) return const Color(0xFF345920);
      if (colorValue == Colors.blue.shade100.value) return const Color(0xFF1E3A5F);
      if (colorValue == Colors.yellow.shade100.value) return const Color(0xFF635D19);
      if (colorValue == Colors.purple.shade100.value) return const Color(0xFF42275E);
      if (colorValue == Colors.orange.shade100.value) return const Color(0xFF613A14);
    }
    
    return Color(colorValue);
  }
}
