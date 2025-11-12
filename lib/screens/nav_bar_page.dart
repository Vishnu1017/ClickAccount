// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:bizmate/screens/Camera%20rental%20page/camera_rental_nav_bar.dart';
import 'package:flutter/material.dart';
import 'package:bizmate/models/user_model.dart';
import 'package:bizmate/screens/CalendarPage.dart';
import 'package:shared_preferences/shared_preferences.dart'
    show SharedPreferences;

import '../models/product_store.dart';
import 'customers_page.dart';
import 'dashboard_page.dart';
import 'home_page.dart';
import 'new_sale_screen.dart';
import 'products_page.dart';
import 'profile_page.dart';
import 'select_items_screen.dart';

class NavBarPage extends StatefulWidget {
  final User user;
  const NavBarPage({super.key, required this.user});

  @override
  State<NavBarPage> createState() => _NavBarPageState();
}

class _NavBarPageState extends State<NavBarPage> {
  int _currentIndex = 0;
  bool _isRentalEnabled = false;

  final List<String> _titles = [
    "Home",
    "Dashboard",
    "Customers",
    "Packages",
    "Profile",
  ];

  @override
  void initState() {
    super.initState();
    _loadRentalStatus();
  }

  Future<void> _loadRentalStatus() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isRentalEnabled =
          prefs.getBool('${widget.user.email}_rentalEnabled') ?? false;
    });
  }

  // ✅ Add this method to reload rental status and rebuild HomePage instantly
  Future<void> _reloadRentalStatus() async {
    await _loadRentalStatus();
    setState(() {}); // Force refresh UI when role or rental status changes
  }

  List<Widget> get _pages => [
    HomePage(),
    DashboardPage(),
    CustomersPage(),
    ProductsPage(),
    // ✅ Pass callback to ProfilePage
    ProfilePage(
      user: widget.user,
      onRentalStatusChanged: () async {
        await _reloadRentalStatus();
        setState(() {
          // 🔥 This ensures UI refreshes with new role immediately
          widget.user.role = widget.user.role;
        });
      },
    ),
  ];

  Widget _buildAddSaleButton() {
    if (![_currentIndex].contains(0) &&
        ![_currentIndex].contains(1) &&
        ![_currentIndex].contains(2)) {
      return SizedBox.shrink();
    }

    String labelText =
        _currentIndex == 0
            ? "Add New Sale"
            : _currentIndex == 1
            ? "Add Sale Now"
            : "Create New Sale";

    return Align(
      alignment: Alignment.bottomCenter,
      child: Padding(
        padding: EdgeInsets.only(bottom: 16.0, left: 16.0, right: 16.0),
        child: SizedBox(
          width: double.infinity,
          child: Container(
            constraints: BoxConstraints(maxWidth: 500),
            height: 55,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              gradient: LinearGradient(
                colors: [Color(0xFF1A237E), Color(0xFF00BCD4)],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
            ),
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => NewSaleScreen()),
                );
              },
              icon: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [Colors.white, Colors.white70],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  border: Border.all(
                    color: Colors.deepPurple.shade100,
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.white.withOpacity(0.3),
                      blurRadius: 5,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                padding: EdgeInsets.all(5),
                child: Icon(
                  Icons.currency_rupee,
                  color: Color(0xFF1A237E),
                  size: 20,
                ),
              ),
              label: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  labelText,
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAddItemButton() {
    if (_currentIndex != 3) return SizedBox.shrink();

    return Align(
      alignment: Alignment.bottomCenter,
      child: Padding(
        padding: EdgeInsets.only(bottom: 16.0, left: 16.0, right: 16.0),
        child: SizedBox(
          width: double.infinity,
          child: Container(
            constraints: BoxConstraints(maxWidth: 500),
            height: 55,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              gradient: LinearGradient(
                colors: [Color(0xFF1A237E), Color(0xFF00BCD4)],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
            ),
            child: ElevatedButton.icon(
              icon: Icon(Icons.add_box_rounded, color: Colors.white, size: 26),
              label: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  'Add Packages',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                padding: EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28),
                ),
              ),
              onPressed: () async {
                bool continueAdding = true;

                while (continueAdding) {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => SelectItemsScreen()),
                  );

                  if (result != null && result['itemName'] != null) {
                    final itemName = result['itemName'];
                    final rate = result['rate'] ?? 0.0;

                    ProductStore().add(itemName, rate);
                    setState(() {});
                  }

                  continueAdding = result != null && result['continue'] == true;
                }
              },
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isPhotographer = widget.user.role == 'Photographer';

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            _titles[_currentIndex],
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 32,
            ),
          ),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF1A237E), Color(0xFF00BCD4)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        actions:
            _currentIndex == 0
                ? [
                  Padding(
                    padding: const EdgeInsets.only(right: 14.0, bottom: 10),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // 📅 Calendar Button (always visible)
                        Container(
                          constraints: BoxConstraints(maxWidth: 150),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(32),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => CalendarPage(),
                                  ),
                                );
                              },
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                child: Icon(
                                  Icons.calendar_today,
                                  color: Colors.white,
                                  size: 22,
                                ),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 8),

                        // 🎥 Camera Rental Button (only if Photographer AND enabled)
                        if (isPhotographer && _isRentalEnabled)
                          Container(
                            constraints: BoxConstraints(maxWidth: 150),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(32),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder:
                                          (context) =>
                                              const CameraRentalNavBar(),
                                    ),
                                  );
                                },
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 6,
                                  ),
                                  child: Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      Icon(
                                        Icons.camera_alt,
                                        color: Colors.white,
                                        size: 28,
                                      ),
                                      Positioned(
                                        bottom: 0,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 4,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.red,
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                          child: const Text(
                                            "Rental",
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 8,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ]
                : null,
      ),
      body: SafeArea(
        child: Stack(
          children: [
            AnimatedSwitcher(
              duration: Duration(milliseconds: 300),
              child: _pages[_currentIndex],
              transitionBuilder: (Widget child, Animation<double> animation) {
                return FadeTransition(opacity: animation, child: child);
              },
            ),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Column(
                children: [_buildAddSaleButton(), _buildAddItemButton()],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        margin: EdgeInsets.symmetric(
          horizontal: MediaQuery.of(context).size.width * 0.05,
          vertical: 8,
        ),
        constraints: BoxConstraints(maxWidth: 500),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: (int newIndex) async {
              setState(() {
                _currentIndex = newIndex;
              });
              if (newIndex == 3) {
                await Future.delayed(Duration(milliseconds: 100));
                setState(() {});
              }
              // ✅ Reload rental status when switching tabs
              _loadRentalStatus();
            },
            backgroundColor: Colors.transparent,
            type: BottomNavigationBarType.fixed,
            elevation: 0,
            selectedItemColor: Color(0xFF1A237E),
            unselectedItemColor: Colors.grey,
            showSelectedLabels: false,
            showUnselectedLabels: false,
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.home_outlined),
                activeIcon: Icon(Icons.home),
                label: '',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.dashboard_outlined),
                activeIcon: Icon(Icons.dashboard),
                label: '',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.group_outlined),
                activeIcon: Icon(Icons.group),
                label: '',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.inventory_2_outlined),
                activeIcon: Icon(Icons.inventory),
                label: '',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.person_outline),
                activeIcon: Icon(Icons.person),
                label: '',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SelectItemsScreenWithCallback extends StatelessWidget {
  final Function(String) onItemSaved;
  const SelectItemsScreenWithCallback({super.key, required this.onItemSaved});

  @override
  Widget build(BuildContext context) {
    return SelectItemsScreen(onItemSaved: onItemSaved);
  }
}
