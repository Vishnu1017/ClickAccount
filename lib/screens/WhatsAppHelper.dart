import 'package:url_launcher/url_launcher.dart';

class WhatsAppHelper {
  static Future<void> sendWhatsAppMessage({
    required String phone,
    required String message,
  }) async {
    try {
      // Clean digits
      String cleanedPhone = phone.replaceAll(RegExp(r'\D'), '');
      if (cleanedPhone.length == 10) {
        cleanedPhone = '91$cleanedPhone'; // Add India code if needed
      }

      final encodedMessage = Uri.encodeComponent(message);
      final url = Uri.parse("https://wa.me/$cleanedPhone?text=$encodedMessage");

      // Use external app launch mode
      if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
        throw Exception("Could not launch WhatsApp");
      }
    } catch (e) {
      throw Exception("WhatsApp error: ${e.toString()}");
    }
  }
}
