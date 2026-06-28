import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AIService {
  static const String _apiKeyPref = 'gemini_api_key';

  // Kiểm tra xem đã có API Key chưa
  static Future<bool> hasApiKey() async {
    final prefs = await SharedPreferences.getInstance();
    final key = prefs.getString(_apiKeyPref);
    return key != null && key.isNotEmpty;
  }

  // Lưu API Key
  static Future<void> saveApiKey(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_apiKeyPref, key.trim());
  }

  // Lấy API Key
  static Future<String?> getApiKey() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_apiKeyPref);
  }

  // Khởi tạo Model
  static Future<GenerativeModel> _getModel() async {
    final apiKey = await getApiKey();
    if (apiKey == null || apiKey.isEmpty) {
      throw Exception('Vui lòng nhập Google Gemini API Key trước khi sử dụng.');
    }
    return GenerativeModel(
      model: 'gemini-2.5-flash',
      apiKey: apiKey,
    );
  }

  // Tính năng 1: Tóm tắt
  static Future<String> summarize(String title, String content) async {
    final model = await _getModel();
    final prompt = '''
Bạn là một trợ lý ghi chú thông minh. 
Hãy đọc nội dung ghi chú dưới đây và tóm tắt lại thành các ý chính ngắn gọn (bullet points).
Tiêu đề: $title
Nội dung: $content

Yêu cầu:
- Tóm tắt súc tích, giữ nguyên ý nghĩa cốt lõi.
- Trình bày dưới dạng danh sách gạch đầu dòng ngắn gọn.
- Trả lời bằng ngôn ngữ của văn bản gốc (ưu tiên Tiếng Việt).
- Chỉ trả về nội dung tóm tắt, không thêm câu chào hỏi dư thừa.
''';
    final response = await model.generateContent([Content.text(prompt)]);
    return response.text ?? 'Không thể tạo tóm tắt.';
  }

  // Tính năng 2: Sửa chính tả & Hành văn
  static Future<String> fixGrammar(String title, String content) async {
    final model = await _getModel();
    final prompt = '''
Bạn là một biên tập viên chuyên nghiệp.
Hãy đọc nội dung ghi chú dưới đây và sửa lại toàn bộ các lỗi chính tả, lỗi ngữ pháp, lỗi ngắt câu.
Tinh chỉnh lại văn phong cho mượt mà, dễ đọc hơn nhưng PHẢI GIỮ NGUYÊN ý nghĩa ban đầu và cách xưng hô.
Tiêu đề: $title
Nội dung gốc: 
$content

Yêu cầu:
- Chỉ trả về nội dung đã được sửa.
- Không giải thích lỗi, không thêm câu mào đầu.
- Nếu nội dung gốc có chứa các mục danh sách dạng "[ ] " hoặc "[x] ", BẮT BUỘC phải giữ nguyên định dạng này ở đầu mỗi dòng tương ứng trong kết quả trả về.
''';
    final response = await model.generateContent([Content.text(prompt)]);
    return response.text ?? content;
  }

  // Tính năng 3: Tự động gắn nhãn (Tags)
  static Future<List<String>> generateTags(String title, String content) async {
    final model = await _getModel();
    final prompt = '''
Hãy phân tích nội dung ghi chú dưới đây và đề xuất TỐI ĐA 3 từ khóa (tags/nhãn) ngắn gọn nhất mô tả nội dung.
Tiêu đề: $title
Nội dung: $content

Yêu cầu:
- Chỉ đề xuất tối đa 3 nhãn.
- Mỗi nhãn dài không quá 2 từ.
- Trả về danh sách nhãn, cách nhau bằng dấu phẩy (Ví dụ: Công việc, Học tập, Du lịch).
- Không thêm bất kỳ ký tự dư thừa nào khác.
''';
    final response = await model.generateContent([Content.text(prompt)]);
    final rawTags = response.text ?? '';
    if (rawTags.isEmpty) return [];

    // Tách chuỗi thành mảng
    return rawTags
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
  }
}
