// advanced_search_bar.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

enum DateRangePreset {
  today,
  thisWeek,
  thisMonth,
  thisQuarter,
  thisFinancialYear,
  custom,
}

class AdvancedSearchBar extends StatefulWidget {
  final String hintText;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<DateTimeRange?> onDateRangeChanged;
  final bool showDateFilter;
  final String? initialSearchQuery;

  const AdvancedSearchBar({
    super.key,
    this.hintText = 'Search...',
    required this.onSearchChanged,
    required this.onDateRangeChanged,
    this.showDateFilter = true,
    this.initialSearchQuery,
  });

  @override
  State<AdvancedSearchBar> createState() => _AdvancedSearchBarState();
}

class _AdvancedSearchBarState extends State<AdvancedSearchBar> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  bool _isSearchExpanded = false;
  DateTimeRange? selectedRange;
  DateRangePreset? selectedPreset;

  @override
  void initState() {
    super.initState();

    if (widget.initialSearchQuery != null) {
      _searchController.text = widget.initialSearchQuery!;
    }

    _searchFocusNode.addListener(() {
      setState(() {
        _isSearchExpanded =
            _searchFocusNode.hasFocus || _searchController.text.isNotEmpty;
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  Future<void> _selectDateRange(BuildContext context) async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      initialDateRange: selectedRange,
    );
    if (picked != null) {
      setState(() {
        selectedRange = picked;
        selectedPreset = DateRangePreset.custom;
      });
      widget.onDateRangeChanged(selectedRange);
    }
  }

  void _handlePresetSelection(DateRangePreset preset) {
    final now = DateTime.now();
    DateTime startDate;
    DateTime endDate;

    switch (preset) {
      case DateRangePreset.today:
        startDate = DateTime(now.year, now.month, now.day);
        endDate = DateTime(now.year, now.month, now.day);
        break;
      case DateRangePreset.thisWeek:
        startDate = DateTime(now.year, now.month, now.day - now.weekday + 1);
        endDate = DateTime(now.year, now.month, now.day - now.weekday + 7);
        break;
      case DateRangePreset.thisMonth:
        startDate = DateTime(now.year, now.month, 1);
        endDate = DateTime(now.year, now.month + 1, 0);
        break;
      case DateRangePreset.thisQuarter:
        final quarter = (now.month - 1) ~/ 3 + 1;
        startDate = DateTime(now.year, (quarter - 1) * 3 + 1, 1);
        endDate = DateTime(now.year, quarter * 3 + 1, 0);
        break;
      case DateRangePreset.thisFinancialYear:
        startDate =
            now.month >= 4
                ? DateTime(now.year, 4, 1)
                : DateTime(now.year - 1, 4, 1);
        endDate =
            now.month >= 4
                ? DateTime(now.year + 1, 3, 31)
                : DateTime(now.year, 3, 31);
        break;
      case DateRangePreset.custom:
        _selectDateRange(context);
        return;
    }

    setState(() {
      selectedRange = DateTimeRange(start: startDate, end: endDate);
      selectedPreset = preset;
    });
    widget.onDateRangeChanged(selectedRange);
  }

  void _clearDateFilter() {
    setState(() {
      selectedRange = null;
      selectedPreset = null;
    });
    widget.onDateRangeChanged(null);
  }

  void _clearSearch() {
    _searchController.clear();
    _searchFocusNode.unfocus();
    setState(() {
      _isSearchExpanded = false;
    });
    widget.onSearchChanged("");
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isSmallScreen = constraints.maxWidth < 600;
        final bool isVerySmallScreen = constraints.maxWidth < 400;

        return Column(
          children: [
            Container(
              margin: EdgeInsets.symmetric(
                horizontal:
                    isVerySmallScreen
                        ? 12
                        : isSmallScreen
                        ? 16
                        : 20,
                vertical: 15,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      height: 50,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                        border: Border.all(
                          color:
                              _isSearchExpanded
                                  ? Colors.indigo.withOpacity(0.3)
                                  : Colors.transparent,
                          width: 1.5,
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Padding(
                              padding: EdgeInsets.only(
                                left: isVerySmallScreen ? 16 : 20,
                                right: 10,
                              ),
                              child: TextField(
                                controller: _searchController,
                                focusNode: _searchFocusNode,
                                decoration: InputDecoration(
                                  hintText: widget.hintText,
                                  hintStyle: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: isVerySmallScreen ? 14 : null,
                                  ),
                                  border: InputBorder.none,
                                ),
                                onChanged: (value) {
                                  setState(() {
                                    _isSearchExpanded =
                                        value.isNotEmpty ||
                                        _searchFocusNode.hasFocus;
                                  });
                                  widget.onSearchChanged(value);
                                },
                              ),
                            ),
                          ),
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 200),
                            child:
                                _searchController.text.isEmpty
                                    ? IconButton(
                                      icon: Icon(
                                        Icons.search,
                                        color: Colors.indigo,
                                        size: isVerySmallScreen ? 20 : 24,
                                      ),
                                      onPressed: () {
                                        _searchFocusNode.requestFocus();
                                      },
                                    )
                                    : IconButton(
                                      icon: Icon(
                                        Icons.close,
                                        color: Colors.grey,
                                        size: isVerySmallScreen ? 20 : 24,
                                      ),
                                      onPressed: _clearSearch,
                                    ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (widget.showDateFilter) ...[
                    SizedBox(width: isVerySmallScreen ? 8 : 10),
                    Container(
                      height: 50,
                      width:
                          isVerySmallScreen ? 50 : (isSmallScreen ? 50 : null),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: PopupMenuButton<DateRangePreset>(
                        icon: Icon(
                          Icons.tune_rounded,
                          color: Colors.blue[800],
                          size: isVerySmallScreen ? 20 : 24,
                        ),
                        onSelected: _handlePresetSelection,
                        itemBuilder:
                            (BuildContext context) =>
                                <PopupMenuEntry<DateRangePreset>>[
                                  const PopupMenuItem<DateRangePreset>(
                                    value: DateRangePreset.today,
                                    child: Text('Today'),
                                  ),
                                  const PopupMenuItem<DateRangePreset>(
                                    value: DateRangePreset.thisWeek,
                                    child: Text('This Week'),
                                  ),
                                  const PopupMenuItem<DateRangePreset>(
                                    value: DateRangePreset.thisMonth,
                                    child: Text('This Month'),
                                  ),
                                  const PopupMenuItem<DateRangePreset>(
                                    value: DateRangePreset.thisQuarter,
                                    child: Text('This Quarter'),
                                  ),
                                  const PopupMenuItem<DateRangePreset>(
                                    value: DateRangePreset.thisFinancialYear,
                                    child: Text('This Financial Year'),
                                  ),
                                  const PopupMenuItem<DateRangePreset>(
                                    value: DateRangePreset.custom,
                                    child: Text('Custom Range'),
                                  ),
                                ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (selectedRange != null && widget.showDateFilter)
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal:
                      isVerySmallScreen
                          ? 12
                          : isSmallScreen
                          ? 16
                          : 20,
                ),
                child: Row(
                  children: [
                    Chip(
                      label: Text(
                        '${DateFormat('dd MMM yyyy').format(selectedRange!.start)} - ${DateFormat('dd MMM yyyy').format(selectedRange!.end)}',
                        style: TextStyle(fontSize: isVerySmallScreen ? 10 : 12),
                      ),
                      backgroundColor: Colors.blue[50],
                      deleteIcon: const Icon(Icons.close, size: 16),
                      onDeleted: _clearDateFilter,
                    ),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }
}
