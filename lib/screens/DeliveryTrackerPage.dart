import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:click_account/models/sale.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class DeliveryTrackerPage extends StatefulWidget {
  final Sale sale;

  const DeliveryTrackerPage({required this.sale});

  @override
  State<DeliveryTrackerPage> createState() => _DeliveryTrackerPageState();
}

class _DeliveryTrackerPageState extends State<DeliveryTrackerPage> {
  final TextEditingController _linkController = TextEditingController();
  String? _selectedStatus;
  final List<String> statuses = [
    'All Non Editing Images',
    'Editing',
    'Printed',
    'Delivered',
  ];

  @override
  void initState() {
    super.initState();
    _linkController.text = widget.sale.deliveryLink;
    _selectedStatus =
        widget.sale.deliveryStatus.isNotEmpty
            ? widget.sale.deliveryStatus
            : 'All Non Editing Images';
  }

  void _saveDeliveryDetails() async {
    widget.sale.deliveryLink = _linkController.text;
    widget.sale.deliveryStatus = _selectedStatus!;
    await widget.sale.save();
    Navigator.pop(context);
  }

  void _sendWhatsApp() {
    final customerName =
        widget.sale.customerName.isNotEmpty
            ? widget.sale.customerName
            : "Customer";
    final deliveryStatus = _selectedStatus ?? 'Ready';
    final deliveryLink =
        _linkController.text.isNotEmpty
            ? _linkController.text
            : 'Link not available';
    final phone = widget.sale.phoneNumber.replaceAll(' ', '');

    if (phone.length < 10 || !RegExp(r'^[0-9]+$').hasMatch(phone)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Please enter a valid 10-digit phone number")),
      );
      return;
    }

    String message;
    if (_selectedStatus == 'All Non Editing Images') {
      message =
          "Hi $customerName,\n\n"
          "Your non-edited photos are now ready for download!\n\n"
          "You can access them here: $deliveryLink\n\n"
          "Note: These are the raw, unedited images from your session. "
          "The final edited versions will be shared separately once completed.\n\n"
          "Thanks,\n"
          "Shutter Life Photography";
    } else {
      message =
          "Hi $customerName,\n\n"
          "Your photos are now *$deliveryStatus*.\n"
          "Download here: $deliveryLink\n\n"
          "Thanks,\n"
          "Shutter Life Photography";
    }

    final url1 = "https://wa.me/$phone?text=${Uri.encodeComponent(message)}";
    final url2 = "https://wa.me/91$phone?text=${Uri.encodeComponent(message)}";

    canLaunchUrl(Uri.parse(url1)).then((canLaunch) {
      if (canLaunch) {
        launchUrl(Uri.parse(url1), mode: LaunchMode.externalApplication);
      } else {
        launchUrl(Uri.parse(url2), mode: LaunchMode.externalApplication);
      }
    });
  }

  int getCurrentStepIndex() {
    return statuses.indexOf(_selectedStatus ?? 'All Non Editing Images');
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isSmallScreen = screenWidth < 600;
    final isPortrait = screenHeight > screenWidth;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(kToolbarHeight),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF1A237E), Color(0xFF00BCD4)],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
          ),
          child: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            automaticallyImplyLeading: true,
            centerTitle: true,
            iconTheme: IconThemeData(color: Colors.white),
            title: Text(
              'Photo Delivery Tracker',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: isSmallScreen ? 18 : 20,
              ),
            ),
          ),
        ),
      ),
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF1A237E), Color(0xFF00BCD4).withOpacity(0.4)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + kToolbarHeight + 20,
                bottom: isSmallScreen ? 12 : 20,
                left: isSmallScreen ? 12 : 20,
                right: isSmallScreen ? 12 : 20,
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: isSmallScreen ? double.infinity : 600,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
                    child: Container(
                      padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: Colors.white30, width: 1.5),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Stepper Timeline - Responsive version
                          _buildResponsiveStepper(isSmallScreen, isPortrait),
                          SizedBox(height: isSmallScreen ? 10 : 20),

                          // Status Dropdown
                          DropdownButtonFormField<String>(
                            value: _selectedStatus,
                            decoration: InputDecoration(
                              labelText: 'Delivery Status',
                              labelStyle: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: isSmallScreen ? 14 : 16,
                              ),
                              filled: true,
                              fillColor: Colors.white.withOpacity(0.05),
                              contentPadding: EdgeInsets.symmetric(
                                vertical: isSmallScreen ? 14 : 18,
                                horizontal: isSmallScreen ? 12 : 16,
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide(
                                  color: Colors.white.withOpacity(0.2),
                                  width: 1.2,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide(
                                  color: Colors.white,
                                  width: 1.5,
                                ),
                              ),
                            ),
                            dropdownColor: Colors.white,
                            iconEnabledColor: Colors.white,
                            icon: Icon(
                              Icons.keyboard_arrow_down_rounded,
                              size: isSmallScreen ? 24 : 28,
                            ),
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: isSmallScreen ? 14 : 16,
                            ),
                            items:
                                statuses.map((status) {
                                  return DropdownMenuItem<String>(
                                    value: status,
                                    child: Text(
                                      status,
                                      style: TextStyle(
                                        color: Colors.black,
                                        fontWeight: FontWeight.w700,
                                        fontSize: isSmallScreen ? 13 : 14,
                                      ),
                                    ),
                                  );
                                }).toList(),
                            selectedItemBuilder: (BuildContext context) {
                              return statuses.map((status) {
                                return Text(
                                  status,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: isSmallScreen ? 14 : 16,
                                  ),
                                );
                              }).toList();
                            },
                            onChanged: (value) {
                              setState(() {
                                _selectedStatus = value!;
                              });
                            },
                          ),
                          SizedBox(height: isSmallScreen ? 15 : 20),

                          // Link Field
                          TextFormField(
                            controller: _linkController,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: isSmallScreen ? 14 : 16,
                            ),
                            decoration: InputDecoration(
                              labelText: 'Google Drive / Download Link',
                              labelStyle: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: isSmallScreen ? 14 : 16,
                              ),
                              filled: true,
                              fillColor: Colors.white.withOpacity(0.05),
                              contentPadding: EdgeInsets.symmetric(
                                vertical: isSmallScreen ? 14 : 18,
                                horizontal: isSmallScreen ? 12 : 16,
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide(
                                  color: Colors.white.withOpacity(0.2),
                                  width: 1.2,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide(
                                  color: Colors.white,
                                  width: 1.5,
                                ),
                              ),
                            ),
                          ),
                          SizedBox(height: isSmallScreen ? 20 : 30),

                          // Responsive Buttons
                          _buildResponsiveButtons(isSmallScreen),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildResponsiveStepper(bool isSmallScreen, bool isPortrait) {
    if (isSmallScreen && !isPortrait) {
      // Horizontal stepper for landscape on small screens
      return SizedBox(
        height: 100,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: statuses.length,
          itemBuilder: (context, index) {
            return Container(
              width: 150,
              padding: EdgeInsets.all(8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color:
                          index <= getCurrentStepIndex()
                              ? Colors.white
                              : Colors.white.withOpacity(0.3),
                    ),
                    child:
                        index < getCurrentStepIndex()
                            ? Icon(Icons.check, size: 16, color: Colors.black)
                            : null,
                  ),
                  SizedBox(height: 8),
                  Text(
                    statuses[index],
                    style: TextStyle(
                      color:
                          index <= getCurrentStepIndex()
                              ? Colors.white
                              : Colors.white60,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                  ),
                ],
              ),
            );
          },
        ),
      );
    } else {
      // Vertical stepper for most cases
      return MediaQuery.removePadding(
        context: context,
        removeTop: true,
        child: Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Colors.white,
              onSurface: Colors.white54,
            ),
          ),
          child: Stepper(
            currentStep: getCurrentStepIndex(),
            controlsBuilder: (context, _) => SizedBox.shrink(),
            physics: NeverScrollableScrollPhysics(),
            steps:
                statuses.map((status) {
                  final index = statuses.indexOf(status);
                  return Step(
                    title: Text(
                      status,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color:
                            index <= getCurrentStepIndex()
                                ? Colors.white
                                : Colors.white60,
                        fontSize: isSmallScreen ? 14 : 16,
                      ),
                    ),
                    content: SizedBox.shrink(),
                    isActive: index <= getCurrentStepIndex(),
                    state:
                        index < getCurrentStepIndex()
                            ? StepState.complete
                            : index == getCurrentStepIndex()
                            ? StepState.editing
                            : StepState.indexed,
                  );
                }).toList(),
          ),
        ),
      );
    }
  }

  Widget _buildResponsiveButtons(bool isSmallScreen) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _saveDeliveryDetails,
            icon: Icon(
              Icons.save,
              color: Colors.white,
              size: isSmallScreen ? 18 : 24,
            ),
            label: Text(
              "Save",
              style: TextStyle(
                color: Colors.white,
                fontSize: isSmallScreen ? 14 : 16,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF1A237E),
              padding: EdgeInsets.symmetric(vertical: isSmallScreen ? 12 : 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ),
        SizedBox(width: isSmallScreen ? 8 : 12),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _sendWhatsApp,
            icon: FaIcon(
              FontAwesomeIcons.whatsapp,
              color: Colors.white,
              size: isSmallScreen ? 18 : 20,
            ),
            label: Text(
              "WhatsApp",
              style: TextStyle(
                color: Colors.white,
                fontSize: isSmallScreen ? 14 : 16,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green.shade700,
              padding: EdgeInsets.symmetric(vertical: isSmallScreen ? 12 : 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
