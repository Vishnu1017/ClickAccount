import 'package:url_launcher/url_launcher.dart';

class WhatsAppHelper {
  static Future<void> sendWhatsAppMessage({
    required String phone,
    required String message,
  }) async {
    try {
      // Remove all non-digit characters
      final cleanedPhone = phone.replaceAll(RegExp(r'\D'), '');

      if (cleanedPhone.length < 10) {
        throw Exception("Invalid phone number");
      }

      final encodedMessage = Uri.encodeComponent(message);

      // Try both versions: with and without 91
      final url1 = Uri.parse(
        "https://wa.me/$cleanedPhone?text=$encodedMessage",
      );
      final url2 = Uri.parse(
        "https://wa.me/91$cleanedPhone?text=$encodedMessage",
      );

      if (await canLaunchUrl(url1)) {
        await launchUrl(url1, mode: LaunchMode.externalApplication);
      } else if (await canLaunchUrl(url2)) {
        await launchUrl(url2, mode: LaunchMode.externalApplication);
      } else {
        throw Exception("WhatsApp is not installed or URL can't be launched");
      }
    } catch (e) {
      throw Exception("WhatsApp error: ${e.toString()}");
    }
  }
}
