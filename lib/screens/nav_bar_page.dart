import 'package:click_account/screens/CalendarPage.dart';
import 'package:flutter/material.dart';
import 'home_page.dart';
import 'dashboard_page.dart';
import 'customers_page.dart';
import 'products_page.dart';
import 'profile_page.dart';
import 'select_items_screen.dart';
import 'new_sale_screen.dart';
import '../models/product_store.dart';

class NavBarPage extends StatefulWidget {
  @override
  State<NavBarPage> createState() => _NavBarPageState();
}

class _NavBarPageState extends State<NavBarPage>
    with SingleTickerProviderStateMixin {
  int _currentIndex = 0;
  late AnimationController _animationController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  final List<String> _titles = [
    "Home",
    "Dashboard",
    "Customers",
    "Products",
    "Profile",
  ];

  final List<Widget> _pages = [
    HomePage(),
    DashboardPage(),
    CustomersPage(),
    ProductsPage(),
    ProfilePage(),
  ];

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 500),
    );

    _slideAnimation = Tween<Offset>(
      begin: Offset(0, 1),
      end: Offset(0, 0),
    ).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutBack),
    );

    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _animationController.forward();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

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
        padding: const EdgeInsets.only(bottom: 2.0),
        child: SlideTransition(
          position: _slideAnimation,
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Container(
              width: MediaQuery.of(context).size.width * 0.85,
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
                label: Text(
                  labelText,
                  style: TextStyle(color: Colors.white, fontSize: 16),
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
      ),
    );
  }

  Widget _buildAddItemButton() {
    if (_currentIndex != 3) return SizedBox.shrink();

    return Align(
      alignment: Alignment.bottomCenter,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 0.0),
        child: SlideTransition(
          position: _slideAnimation,
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Container(
              width: MediaQuery.of(context).size.width * 0.85,
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
                icon: Icon(
                  Icons.add_box_rounded,
                  color: Colors.white,
                  size: 26,
                ),
                label: Text(
                  'Add Items',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
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
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text(
          _titles[_currentIndex],
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 32,
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
                    padding: const EdgeInsets.only(right: 10.0, bottom: 10),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(32),
                        gradient: LinearGradient(
                          colors: [
                            Color.fromARGB(88, 20, 14, 188),
                            Color.fromARGB(167, 20, 14, 188),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.9),
                          width: 2,
                        ),
                      ),
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
                              horizontal: 16,
                              vertical: 12,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.calendar_today,
                                  color: Colors.white,
                                  size: 18,
                                ),
                                SizedBox(width: 10),
                                Text(
                                  "Calendar",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 15,
                                    letterSpacing: 0.6,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ]
                : null,
      ),
      body: Stack(
        children: [
          _pages[_currentIndex],
          _buildAddSaleButton(),
          _buildAddItemButton(),
        ],
      ),
      bottomNavigationBar: Container(
        margin: EdgeInsets.all(12),
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
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (int newIndex) async {
            setState(() {
              _currentIndex = newIndex;
              _animationController.reset();
              _animationController.forward();
            });

            if (newIndex == 3) {
              await Future.delayed(Duration(milliseconds: 100));
              setState(() {});
            }
          },
          backgroundColor: Colors.transparent,
          type: BottomNavigationBarType.fixed,
          elevation: 0,
          selectedItemColor: Color(0xFF1A237E),
          unselectedItemColor: Colors.grey,
          showSelectedLabels: true,
          showUnselectedLabels: false,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
            BottomNavigationBarItem(
              icon: Icon(Icons.dashboard),
              label: 'Dashboard',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.group),
              label: 'Customers',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.inventory),
              label: 'Items',
            ),
            BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
          ],
        ),
      ),
    );
  }
}

class SelectItemsScreenWithCallback extends StatelessWidget {
  final Function(String) onItemSaved;
  const SelectItemsScreenWithCallback({required this.onItemSaved});

  @override
  Widget build(BuildContext context) {
    return SelectItemsScreen(onItemSaved: onItemSaved);
  }
}
