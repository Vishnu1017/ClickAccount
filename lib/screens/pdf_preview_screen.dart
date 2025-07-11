import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:share_plus/share_plus.dart';

class PdfPreviewScreen extends StatelessWidget {
  final String filePath;

  const PdfPreviewScreen({required this.filePath});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final outerMargin = screenWidth * 0.03; // ~12 on small screens
    final innerMargin = screenWidth * 0.04; // ~16 on small screens

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(60),
        child: AppBar(
          elevation: 0,
          backgroundColor: Colors.transparent,
          iconTheme: IconThemeData(color: Colors.white),
          flexibleSpace: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF1A237E), Color(0xFF00BCD4)],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
            ),
          ),
          title: Text(
            "📄 Invoice Preview",
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
          ),
          centerTitle: true,
        ),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Container(
              margin: EdgeInsets.all(outerMargin),
              padding: EdgeInsets.all(10),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.transparent, width: 2),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(
                child: Container(
                  margin: EdgeInsets.symmetric(
                    horizontal: innerMargin,
                    vertical: screenWidth * 0.3, // smaller vertical margin
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(
                      color: Colors.black,
                      width: 3,
                    ), // 👈 as-is
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 10,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: SizedBox(
                      width: double.infinity,
                      height: double.infinity,
                      child: PDFView(
                        filePath: filePath,
                        enableSwipe: true,
                        swipeHorizontal: false,
                        autoSpacing: true,
                        pageFling: true,
                        fitEachPage: true,
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF1A237E), Color(0xFF00BCD4)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(30),
        ),
        child: FloatingActionButton.extended(
          backgroundColor: Colors.transparent,
          elevation: 0,
          icon: Icon(Icons.share, color: Colors.white),
          label: Text("Share", style: TextStyle(color: Colors.white)),
          onPressed: () {
            Share.shareXFiles([
              XFile(filePath),
            ], text: "Here is your invoice PDF");
          },
        ),
      ),
    );
  }
}
