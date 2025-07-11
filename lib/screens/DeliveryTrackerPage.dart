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
    final encodedMsg = Uri.encodeComponent(
      "Hi $customerName,\n\nYour photos are now *$deliveryStatus*.\nDownload here: $deliveryLink\n\nThanks,\nShutter Life Photography",
    );
    final url = "https://wa.me/$phone?text=$encodedMsg";
    launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  }

  int getCurrentStepIndex() {
    return statuses.indexOf(_selectedStatus ?? 'All Non Editing Images');
  }

  @override
  Widget build(BuildContext context) {
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
                fontSize: 20,
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
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
              child: Container(
                margin: EdgeInsets.symmetric(horizontal: 20, vertical: 100),
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.white30, width: 1.5),
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // 🎯 Stepper Timeline
                      MediaQuery.removePadding(
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
                      ),
                      SizedBox(height: 10),
                      // 🔽 Status Dropdown
                      DropdownButtonFormField<String>(
                        value: _selectedStatus,
                        decoration: InputDecoration(
                          labelText: 'Delivery Status',
                          labelStyle: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                          filled: true,
                          fillColor: Colors.white.withOpacity(0.05),
                          contentPadding: EdgeInsets.symmetric(
                            vertical: 18,
                            horizontal: 16,
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
                        icon: Icon(Icons.keyboard_arrow_down_rounded, size: 28),
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
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
                                    fontSize: 14,
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
                                fontSize: 16,
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
                      SizedBox(height: 20),

                      // 🔗 Link Field
                      TextFormField(
                        controller: _linkController,
                        style: TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          labelText: 'Google Drive / Download Link',
                          labelStyle: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                          filled: true,
                          fillColor: Colors.white.withOpacity(0.05),
                          contentPadding: EdgeInsets.symmetric(
                            vertical: 18,
                            horizontal: 16,
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
                      SizedBox(height: 30),
                      // Buttons
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _saveDeliveryDetails,
                              icon: Icon(Icons.save, color: Colors.white),
                              label: Text(
                                "Save",
                                style: TextStyle(color: Colors.white),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Color(0xFF1A237E),
                                padding: EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                            ),
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _sendWhatsApp,
                              icon: FaIcon(
                                FontAwesomeIcons.whatsapp,
                                color: Colors.white,
                              ),
                              label: Text(
                                "WhatsApp",
                                style: TextStyle(color: Colors.white),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green.shade700,
                                padding: EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
