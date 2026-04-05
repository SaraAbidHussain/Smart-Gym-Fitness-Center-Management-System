import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../config/api_config.dart';
//import '../../services/auth_service.dart';
//import '../../services/token_storage.dart';

class _C {
  static const gold = Color(0xFFD4AF37);
  static const lightGold = Color(0xFFE6C86E);
  static const darkGold = Color(0xFFB8942A);
  static const navy = Color(0xFF1E293B);
  static const navyLight = Color(0xFF334155);
  static const bgPrimary = Color(0xFF0A0A0A);
  static const bgSecondary = Color(0xFF141414);
  static const bgCard = Color(0xFF1F1F1F);
  static const bgElevated = Color(0xFF2A2A2A);
  static const success = Color(0xFF10B981);
  static const warning = Color(0xFFF59E0B);
  static const error = Color(0xFFEF4444);
  static const textPrimary = Colors.white;
  static const textSecondary = Color(0xFF94A3B8);
  static const glassBorder = Color(0x40D4AF37); // 25% opacity
  static const glassTint = Color(0x14D4AF37); // 8% opacity
}

class ClassSchedule {
  final int scheduleId;
  final String className;
  final String classType;
  final String trainerName;
  final DateTime startTime;
  final DateTime endTime;
  final int maxCapacity;
  final int currentBookings;
  final double price;
  final String? description;
  final String? location;

  ClassSchedule({
    required this.scheduleId,
    required this.className,
    required this.classType,
    required this.trainerName,
    required this.startTime,
    required this.endTime,
    required this.maxCapacity,
    required this.currentBookings,
    required this.price,
    this.description,
    this.location,
  });

  int get spotsLeft => maxCapacity - currentBookings;
  bool get isFull => spotsLeft <= 0;
  double get fillPercent => currentBookings / maxCapacity;

  factory ClassSchedule.fromJson(Map<String, dynamic> json) {
    return ClassSchedule(
      scheduleId: json['schedule_id'] ?? json['id'] ?? 0,
      className: json['class_name'] ?? json['name'] ?? 'Unnamed Class',
      classType: json['class_type'] ?? json['type'] ?? 'General',
      trainerName: json['trainer_name'] ?? json['trainer'] ?? 'TBA',
      startTime: DateTime.tryParse(json['start_time'] ?? '') ?? DateTime.now(),
      endTime: DateTime.tryParse(json['end_time'] ?? '') ??
          DateTime.now().add(const Duration(hours: 1)),
      maxCapacity: json['max_capacity'] ?? json['capacity'] ?? 20,
      currentBookings: json['current_bookings'] ?? json['bookings'] ?? 0,
      price: (json['price'] ?? 0).toDouble(),
      description: json['description'],
      location: json['location'] ?? json['room'],
    );
  }
}

enum DateFilter { all, today, tomorrow, thisWeek }

enum SortOption { dateAsc, dateDesc, availability, price }

class FilterState {
  DateFilter dateFilter;
  String? selectedType;
  String? selectedTrainer;
  String searchQuery;
  SortOption sortOption;
  bool showAvailableOnly;

  FilterState({
    this.dateFilter = DateFilter.all,
    this.selectedType,
    this.selectedTrainer,
    this.searchQuery = '',
    this.sortOption = SortOption.dateAsc,
    this.showAvailableOnly = false,
  });

  bool get hasActiveFilters =>
      dateFilter != DateFilter.all ||
      selectedType != null ||
      selectedTrainer != null ||
      searchQuery.isNotEmpty ||
      showAvailableOnly;

  int get activeCount {
    int count = 0;
    if (dateFilter != DateFilter.all) count++;
    if (selectedType != null) count++;
    if (selectedTrainer != null) count++;
    if (searchQuery.isNotEmpty) count++;
    if (showAvailableOnly) count++;
    return count;
  }

  FilterState copyWith({
    DateFilter? dateFilter,
    String? selectedType,
    String? selectedTrainer,
    String? searchQuery,
    SortOption? sortOption,
    bool? showAvailableOnly,
    bool clearType = false,
    bool clearTrainer = false,
  }) {
    return FilterState(
      dateFilter: dateFilter ?? this.dateFilter,
      selectedType: clearType ? null : (selectedType ?? this.selectedType),
      selectedTrainer:
          clearTrainer ? null : (selectedTrainer ?? this.selectedTrainer),
      searchQuery: searchQuery ?? this.searchQuery,
      sortOption: sortOption ?? this.sortOption,
      showAvailableOnly: showAvailableOnly ?? this.showAvailableOnly,
    );
  }
}

class BrowseClassesScreen extends StatefulWidget {
  const BrowseClassesScreen({super.key});

  @override
  State<BrowseClassesScreen> createState() => _BrowseClassesScreenState();
}

class _BrowseClassesScreenState extends State<BrowseClassesScreen>
    with SingleTickerProviderStateMixin {
  final ApiService _api = ApiService();
  //final AuthService _auth = AuthService();
  final TextEditingController _searchController = TextEditingController();

  List<ClassSchedule> _allClasses = [];
  List<ClassSchedule> _filteredClasses = [];
  bool _isLoading = true;
  String? _error;
  bool _isBooking = false;
  int? _bookingId;

  FilterState _filters = FilterState();
  bool _showFilterPanel = false;
  late AnimationController _filterAnimCtrl;
  late Animation<double> _filterAnim;

  // Derived filter options
  List<String> get _classTypes =>
      _allClasses.map((c) => c.classType).toSet().toList()..sort();
  List<String> get _trainers =>
      _allClasses.map((c) => c.trainerName).toSet().toList()..sort();

  @override
  void initState() {
    super.initState();
    _filterAnimCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 300));
    _filterAnim =
        CurvedAnimation(parent: _filterAnimCtrl, curve: Curves.easeInOut);
    _searchController.addListener(() {
      setState(() {
        _filters = _filters.copyWith(searchQuery: _searchController.text);
        _applyFilters();
      });
    });
    _loadClasses();
  }

  @override
  void dispose() {
    _filterAnimCtrl.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadClasses() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final response = await _api.get(ApiConfig.classSchedule);
      if (response.success && response.data != null) {
        final raw = response.data is List
            ? response.data as List
            : (response.data['schedules'] ?? response.data['classes'] ?? []);
        setState(() {
          _allClasses =
              raw.map((j) => ClassSchedule.fromJson(j as Map<String, dynamic>)).toList();
          _isLoading = false;
        });
        _applyFilters();
      } else {
        // Show demo data if API has no classes
        setState(() {
          _allClasses = _demoClasses();
          _isLoading = false;
        });
        _applyFilters();
      }
    } catch (_) {
      setState(() {
        _allClasses = _demoClasses();
        _isLoading = false;
      });
      _applyFilters();
    }
  }

  List<ClassSchedule> _demoClasses() {
    final now = DateTime.now();
    return [
      ClassSchedule(
        scheduleId: 1,
        className: 'Power Yoga',
        classType: 'Yoga',
        trainerName: 'Sarah Johnson',
        startTime: now.add(const Duration(hours: 2)),
        endTime: now.add(const Duration(hours: 3)),
        maxCapacity: 20,
        currentBookings: 15,
        price: 15.00,
        description: 'Energizing flow combining strength and flexibility.',
        location: 'Studio A',
      ),
      ClassSchedule(
        scheduleId: 2,
        className: 'HIIT Blast',
        classType: 'HIIT',
        trainerName: 'Mike Chen',
        startTime: now.add(const Duration(hours: 4)),
        endTime: now.add(const Duration(hours: 5)),
        maxCapacity: 15,
        currentBookings: 15,
        price: 20.00,
        description: 'High-intensity interval training for maximum calorie burn.',
        location: 'Main Floor',
      ),
      ClassSchedule(
        scheduleId: 3,
        className: 'Pilates Core',
        classType: 'Pilates',
        trainerName: 'Emma Davis',
        startTime: now.add(const Duration(days: 1, hours: 1)),
        endTime: now.add(const Duration(days: 1, hours: 2)),
        maxCapacity: 12,
        currentBookings: 6,
        price: 18.00,
        description: 'Core strengthening using Pilates principles.',
        location: 'Studio B',
      ),
      ClassSchedule(
        scheduleId: 4,
        className: 'Spin Cycle',
        classType: 'Cardio',
        trainerName: 'Jake Rivera',
        startTime: now.add(const Duration(days: 1, hours: 5)),
        endTime: now.add(const Duration(days: 1, hours: 6)),
        maxCapacity: 25,
        currentBookings: 10,
        price: 12.00,
        description: 'Indoor cycling session with rhythm-based intervals.',
        location: 'Cycle Room',
      ),
      ClassSchedule(
        scheduleId: 5,
        className: 'Strength & Conditioning',
        classType: 'Strength',
        trainerName: 'Mike Chen',
        startTime: now.add(const Duration(days: 2, hours: 2)),
        endTime: now.add(const Duration(days: 2, hours: 3, minutes: 30)),
        maxCapacity: 10,
        currentBookings: 3,
        price: 25.00,
        description: 'Progressive overload program for serious gains.',
        location: 'Weight Room',
      ),
      ClassSchedule(
        scheduleId: 6,
        className: 'Morning Meditation',
        classType: 'Yoga',
        trainerName: 'Sarah Johnson',
        startTime: now.add(const Duration(days: 3, hours: 0)),
        endTime: now.add(const Duration(days: 3, hours: 1)),
        maxCapacity: 30,
        currentBookings: 8,
        price: 10.00,
        description: 'Mindfulness and breathing exercises to start your day.',
        location: 'Studio A',
      ),
    ];
  }

  void _applyFilters() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final weekEnd = today.add(const Duration(days: 7));

    List<ClassSchedule> result = List.from(_allClasses);

    // Date filter
    switch (_filters.dateFilter) {
      case DateFilter.today:
        result = result
            .where((c) =>
                c.startTime.isAfter(today) &&
                c.startTime.isBefore(tomorrow))
            .toList();
        break;
      case DateFilter.tomorrow:
        result = result
            .where((c) =>
                c.startTime.isAfter(tomorrow) &&
                c.startTime.isBefore(tomorrow.add(const Duration(days: 1))))
            .toList();
        break;
      case DateFilter.thisWeek:
        result = result
            .where((c) =>
                c.startTime.isAfter(today) && c.startTime.isBefore(weekEnd))
            .toList();
        break;
      case DateFilter.all:
        break;
    }

    // Type filter
    if (_filters.selectedType != null) {
      result =
          result.where((c) => c.classType == _filters.selectedType).toList();
    }

    // Trainer filter
    if (_filters.selectedTrainer != null) {
      result = result
          .where((c) => c.trainerName == _filters.selectedTrainer)
          .toList();
    }

    // Availability filter
    if (_filters.showAvailableOnly) {
      result = result.where((c) => !c.isFull).toList();
    }

    // Search
    if (_filters.searchQuery.isNotEmpty) {
      final q = _filters.searchQuery.toLowerCase();
      result = result
          .where((c) =>
              c.className.toLowerCase().contains(q) ||
              c.classType.toLowerCase().contains(q) ||
              c.trainerName.toLowerCase().contains(q) ||
              (c.description?.toLowerCase().contains(q) ?? false))
          .toList();
    }

    // Sort
    switch (_filters.sortOption) {
      case SortOption.dateAsc:
        result.sort((a, b) => a.startTime.compareTo(b.startTime));
        break;
      case SortOption.dateDesc:
        result.sort((a, b) => b.startTime.compareTo(a.startTime));
        break;
      case SortOption.availability:
        result.sort((a, b) => b.spotsLeft.compareTo(a.spotsLeft));
        break;
      case SortOption.price:
        result.sort((a, b) => a.price.compareTo(b.price));
        break;
    }

    setState(() => _filteredClasses = result);
  }

  void _clearAllFilters() {
    _searchController.clear();
    setState(() {
      _filters = FilterState();
      _applyFilters();
    });
  }

  void _toggleFilterPanel() {
    setState(() => _showFilterPanel = !_showFilterPanel);
    if (_showFilterPanel) {
      _filterAnimCtrl.forward();
    } else {
      _filterAnimCtrl.reverse();
    }
  }
  Future<void> _bookClass(ClassSchedule cls) async {
  setState(() {
    _isBooking = true;
    _bookingId = cls.scheduleId;
  });

  try {
    final response = await _api.post(
      ApiConfig.memberBookClass,
      body: {'schedule_id': cls.scheduleId},
    );

    if (mounted) {
      if (response.success) {
        _showSuccessDialog(cls);
        _loadClasses();
      } else {
        _showErrorSnack(response.error ?? 'Booking failed. Please try again.');
      }
    }
  } catch (e) {
    if (mounted) _showErrorSnack('Network error. Please try again.');
  } finally {
    if (mounted) setState(() {
      _isBooking = false;
      _bookingId = null;
    });
  }
}

  void _showErrorSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(children: [
          const Icon(Icons.error_outline, color: Colors.white, size: 18),
          const SizedBox(width: 8),
          Expanded(child: Text(msg)),
        ]),
        backgroundColor: _C.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _showSuccessDialog(ClassSchedule cls) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: _C.bgCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: _C.gold.withOpacity(0.3)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [
                  _C.gold.withOpacity(0.3),
                  _C.gold.withOpacity(0.05),
                ]),
                border: Border.all(color: _C.gold, width: 2),
              ),
              child: const Icon(Icons.check_rounded, color: _C.gold, size: 32),
            ),
            const SizedBox(height: 16),
            const Text('Booking Confirmed!',
                style: TextStyle(
                    color: _C.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(cls.className,
                style: const TextStyle(
                    color: _C.gold, fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text(_formatDateTime(cls.startTime),
                style: const TextStyle(color: _C.textSecondary, fontSize: 13)),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _C.gold,
                  foregroundColor: _C.bgPrimary,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text('Great!',
                    style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  String _formatDateTime(DateTime dt) {
    final weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final months = [
      'Jan','Feb','Mar','Apr','May','Jun',
      'Jul','Aug','Sep','Oct','Nov','Dec'
    ];
    final wd = weekdays[dt.weekday - 1];
    final mo = months[dt.month - 1];
    final h = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final m = dt.minute.toString().padLeft(2, '0');
    final ap = dt.hour < 12 ? 'AM' : 'PM';
    return '$wd, ${dt.day} $mo · $h:$m $ap';
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final m = dt.minute.toString().padLeft(2, '0');
    final ap = dt.hour < 12 ? 'AM' : 'PM';
    return '$h:$m $ap';
  }

  String _dateLabel(DateTime dt) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final d = DateTime(dt.year, dt.month, dt.day);
    if (d == today) return 'Today';
    if (d == today.add(const Duration(days: 1))) return 'Tomorrow';
    final months = [
      'Jan','Feb','Mar','Apr','May','Jun',
      'Jul','Aug','Sep','Oct','Nov','Dec'
    ];
    return '${dt.day} ${months[dt.month - 1]}';
  }

  Color _typeColor(String type) {
    const map = {
      'Yoga': Color(0xFF8B5CF6),
      'HIIT': Color(0xFFEF4444),
      'Pilates': Color(0xFF06B6D4),
      'Cardio': Color(0xFFF59E0B),
      'Strength': Color(0xFF10B981),
      'Boxing': Color(0xFFEC4899),
      'Dance': Color(0xFF6366F1),
      'Spin': Color(0xFFF97316),
    };
    return map[type] ?? _C.gold;
  }

  IconData _typeIcon(String type) {
    const map = {
      'Yoga': Icons.self_improvement,
      'HIIT': Icons.flash_on,
      'Pilates': Icons.accessibility_new,
      'Cardio': Icons.directions_run,
      'Strength': Icons.fitness_center,
      'Boxing': Icons.sports_mma,
      'Dance': Icons.music_note,
      'Spin': Icons.pedal_bike,
    };
    return map[type] ?? Icons.sports_gymnastics;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _C.bgPrimary,
      body: RefreshIndicator(
        color: _C.gold,
        backgroundColor: _C.bgCard,
        onRefresh: _loadClasses,
        child: CustomScrollView(
          slivers: [
            _buildAppBar(),
            SliverToBoxAdapter(child: _buildSearchBar()),
            SliverToBoxAdapter(child: _buildQuickFilters()),
            SliverAnimatedOpacity(
              opacity: _showFilterPanel ? 1 : 0,
              duration: const Duration(milliseconds: 250),
              sliver: SliverToBoxAdapter(
                child: _showFilterPanel ? _buildExpandedFilters() : const SizedBox.shrink(),
              ),
            ),
            SliverToBoxAdapter(child: _buildResultsHeader()),
            _isLoading
                ? SliverFillRemaining(child: _buildLoader())
                : _error != null
                    ? SliverFillRemaining(child: _buildError())
                    : _filteredClasses.isEmpty
                        ? SliverFillRemaining(child: _buildEmpty())
                        : _buildClassList(),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 100,
      pinned: true,
      backgroundColor: _C.bgPrimary,
      surfaceTintColor: Colors.transparent,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new, color: _C.gold, size: 18),
        onPressed: () => Navigator.pop(context),
      ),
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.only(left: 56, bottom: 16),
        title: const Text('Browse Classes',
            style: TextStyle(
                color: _C.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.bold)),
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [_C.navy.withOpacity(0.4), _C.bgPrimary],
            ),
          ),
        ),
      ),
      actions: [
        Stack(
          alignment: Alignment.topRight,
          children: [
            IconButton(
              icon: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: Icon(
                  _showFilterPanel ? Icons.tune : Icons.tune_rounded,
                  key: ValueKey(_showFilterPanel),
                  color: _showFilterPanel ? _C.gold : _C.textSecondary,
                  size: 22,
                ),
              ),
              onPressed: _toggleFilterPanel,
              tooltip: 'Filters',
            ),
            if (_filters.activeCount > 0)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  width: 16,
                  height: 16,
                  decoration: const BoxDecoration(
                    color: _C.gold,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '${_filters.activeCount}',
                      style: const TextStyle(
                          color: _C.bgPrimary,
                          fontSize: 9,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(width: 4),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Container(
        decoration: BoxDecoration(
          color: _C.bgCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: _searchController.text.isNotEmpty
                ? _C.glassBorder
                : Colors.white.withOpacity(0.08),
          ),
        ),
        child: TextField(
          controller: _searchController,
          style: const TextStyle(color: _C.textPrimary, fontSize: 14),
          decoration: InputDecoration(
            hintText: 'Search classes, trainers, types...',
            hintStyle: const TextStyle(color: _C.textSecondary, fontSize: 14),
            prefixIcon: const Icon(Icons.search_rounded, color: _C.textSecondary, size: 20),
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.close_rounded,
                        color: _C.textSecondary, size: 18),
                    onPressed: () {
                      _searchController.clear();
                      setState(() {
                        _filters = _filters.copyWith(searchQuery: '');
                        _applyFilters();
                      });
                    },
                  )
                : null,
            border: InputBorder.none,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
      ),
    );
  }

  Widget _buildQuickFilters() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Date filters row
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(children: [
            _dateChip(DateFilter.all, 'All Dates', Icons.calendar_month_outlined),
            const SizedBox(width: 8),
            _dateChip(DateFilter.today, 'Today', Icons.today_outlined),
            const SizedBox(width: 8),
            _dateChip(DateFilter.tomorrow, 'Tomorrow', Icons.event_outlined),
            const SizedBox(width: 8),
            _dateChip(DateFilter.thisWeek, 'This Week', Icons.date_range_outlined),
            const SizedBox(width: 8),
            // Available only toggle
            _toggleChip(
              active: _filters.showAvailableOnly,
              label: 'Available Only',
              icon: Icons.check_circle_outline,
              onTap: () {
                setState(() {
                  _filters = _filters.copyWith(
                      showAvailableOnly: !_filters.showAvailableOnly);
                  _applyFilters();
                });
              },
            ),
          ]),
        ),
        const SizedBox(height: 8),
        // Sort row
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(children: [
            const Text('Sort:',
                style: TextStyle(color: _C.textSecondary, fontSize: 12)),
            const SizedBox(width: 8),
            _sortChip(SortOption.dateAsc, 'Earliest'),
            const SizedBox(width: 6),
            _sortChip(SortOption.dateDesc, 'Latest'),
            const SizedBox(width: 6),
            _sortChip(SortOption.availability, 'Available'),
            const SizedBox(width: 6),
            _sortChip(SortOption.price, 'Price ↑'),
          ]),
        ),
      ]),
    );
  }

  Widget _dateChip(DateFilter filter, String label, IconData icon) {
    final active = _filters.dateFilter == filter;
    return GestureDetector(
      onTap: () {
        setState(() {
          _filters = _filters.copyWith(dateFilter: filter);
          _applyFilters();
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          gradient: active
              ? LinearGradient(
                  colors: [_C.gold, _C.darkGold],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: active ? null : _C.bgCard,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: active ? _C.gold : Colors.white.withOpacity(0.1),
          ),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 13, color: active ? _C.bgPrimary : _C.textSecondary),
          const SizedBox(width: 5),
          Text(label,
              style: TextStyle(
                  color: active ? _C.bgPrimary : _C.textSecondary,
                  fontSize: 12,
                  fontWeight:
                      active ? FontWeight.bold : FontWeight.normal)),
        ]),
      ),
    );
  }

  Widget _sortChip(SortOption sort, String label) {
    final active = _filters.sortOption == sort;
    return GestureDetector(
      onTap: () {
        setState(() {
          _filters = _filters.copyWith(sortOption: sort);
          _applyFilters();
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: active ? _C.gold.withOpacity(0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: active ? _C.gold.withOpacity(0.5) : Colors.transparent,
          ),
        ),
        child: Text(label,
            style: TextStyle(
                color: active ? _C.lightGold : _C.textSecondary,
                fontSize: 12,
                fontWeight:
                    active ? FontWeight.w600 : FontWeight.normal)),
      ),
    );
  }

  Widget _toggleChip(
      {required bool active,
      required String label,
      required IconData icon,
      required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: active ? _C.success.withOpacity(0.15) : _C.bgCard,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: active
                ? _C.success.withOpacity(0.5)
                : Colors.white.withOpacity(0.1),
          ),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon,
              size: 13, color: active ? _C.success : _C.textSecondary),
          const SizedBox(width: 5),
          Text(label,
              style: TextStyle(
                  color: active ? _C.success : _C.textSecondary,
                  fontSize: 12,
                  fontWeight:
                      active ? FontWeight.w600 : FontWeight.normal)),
        ]),
      ),
    );
  }
  Widget _buildExpandedFilters() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _C.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _C.glassBorder),
        boxShadow: [
          BoxShadow(
            color: _C.gold.withOpacity(0.05),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Advanced Filters',
                style: TextStyle(
                    color: _C.gold,
                    fontWeight: FontWeight.bold,
                    fontSize: 14)),
            if (_filters.hasActiveFilters)
              GestureDetector(
                onTap: _clearAllFilters,
                child: const Text('Clear All',
                    style: TextStyle(
                        color: _C.error,
                        fontSize: 12,
                        fontWeight: FontWeight.w500)),
              ),
          ],
        ),
        const SizedBox(height: 16),

        // Class Type
        const Text('Class Type',
            style: TextStyle(
                color: _C.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _filterPill(
              label: 'All Types',
              active: _filters.selectedType == null,
              color: _C.gold,
              onTap: () => setState(() {
                _filters = _filters.copyWith(clearType: true);
                _applyFilters();
              }),
            ),
            ..._classTypes.map((t) => _filterPill(
                  label: t,
                  active: _filters.selectedType == t,
                  color: _typeColor(t),
                  icon: _typeIcon(t),
                  onTap: () => setState(() {
                    _filters = _filters.selectedType == t
                        ? _filters.copyWith(clearType: true)
                        : _filters.copyWith(selectedType: t);
                    _applyFilters();
                  }),
                )),
          ],
        ),

        const SizedBox(height: 16),

        // Trainer
        const Text('Trainer',
            style: TextStyle(
                color: _C.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _filterPill(
              label: 'All Trainers',
              active: _filters.selectedTrainer == null,
              color: _C.gold,
              onTap: () => setState(() {
                _filters = _filters.copyWith(clearTrainer: true);
                _applyFilters();
              }),
            ),
            ..._trainers.map((t) => _filterPill(
                  label: t,
                  active: _filters.selectedTrainer == t,
                  color: _C.navy,
                  icon: Icons.person_outline,
                  onTap: () => setState(() {
                    _filters = _filters.selectedTrainer == t
                        ? _filters.copyWith(clearTrainer: true)
                        : _filters.copyWith(selectedTrainer: t);
                    _applyFilters();
                  }),
                )),
          ],
        ),
      ]),
    );
  }

  Widget _filterPill({
    required String label,
    required bool active,
    required Color color,
    IconData? icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: active ? color.withOpacity(0.2) : _C.bgElevated,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: active ? color.withOpacity(0.6) : Colors.white.withOpacity(0.08),
          ),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: active ? color : _C.textSecondary),
            const SizedBox(width: 4),
          ],
          Text(label,
              style: TextStyle(
                  color: active ? color : _C.textSecondary,
                  fontSize: 12,
                  fontWeight: active ? FontWeight.w600 : FontWeight.normal)),
        ]),
      ),
    );
  }

  Widget _buildResultsHeader() {
    if (_isLoading) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: '${_filteredClasses.length} ',
                  style: const TextStyle(
                      color: _C.gold,
                      fontSize: 15,
                      fontWeight: FontWeight.bold),
                ),
                TextSpan(
                  text: _filteredClasses.length == 1 ? 'class found' : 'classes found',
                  style: const TextStyle(color: _C.textSecondary, fontSize: 13),
                ),
              ],
            ),
          ),
          if (_filters.hasActiveFilters)
            GestureDetector(
              onTap: _clearAllFilters,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _C.error.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: _C.error.withOpacity(0.3)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.close_rounded, size: 12, color: _C.error),
                    SizedBox(width: 4),
                    Text('Clear filters',
                        style: TextStyle(color: _C.error, fontSize: 11)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildClassList() {
    // Group by date
    final grouped = <String, List<ClassSchedule>>{};
    for (final cls in _filteredClasses) {
      final key = _dateLabel(cls.startTime);
      grouped.putIfAbsent(key, () => []).add(cls);
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (ctx, i) {
          final entries = grouped.entries.toList();
          int idx = 0;
          for (final entry in entries) {
            if (i == idx) {
              return _buildDateHeader(entry.key);
            }
            idx++;
            for (final cls in entry.value) {
              if (i == idx) return _buildClassCard(cls);
              idx++;
            }
          }
          return const SizedBox(height: 24);
        },
        childCount: grouped.entries.fold(0, (sum, e) => sum + 1 + e.value.length) + 1,
      ),
    );
  }

  Widget _buildDateHeader(String label) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            gradient: LinearGradient(
                colors: [_C.gold.withOpacity(0.2), _C.gold.withOpacity(0.05)]),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: _C.gold.withOpacity(0.3)),
          ),
          child: Text(label,
              style: const TextStyle(
                  color: _C.gold,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5)),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Divider(color: Colors.white.withOpacity(0.06), thickness: 1),
        ),
      ]),
    );
  }

  Widget _buildClassCard(ClassSchedule cls) {
    final typeColor = _typeColor(cls.classType);
    final isBusy = _isBooking && _bookingId == cls.scheduleId;
    final fillPct = cls.fillPercent.clamp(0.0, 1.0);
    final spotsColor = cls.isFull
        ? _C.error
        : cls.spotsLeft <= 3
            ? _C.warning
            : _C.success;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Container(
        decoration: BoxDecoration(
          color: _C.bgCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.06)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Header band
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [typeColor.withOpacity(0.15), Colors.transparent],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
              border: Border(
                  left: BorderSide(color: typeColor, width: 3),
                  bottom: BorderSide(
                      color: Colors.white.withOpacity(0.05))),
            ),
            child: Row(children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: typeColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(_typeIcon(cls.classType), color: typeColor, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text(cls.className,
                      style: const TextStyle(
                          color: _C.textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.bold)),
                  Text(cls.classType,
                      style: TextStyle(
                          color: typeColor,
                          fontSize: 11,
                          fontWeight: FontWeight.w500)),
                ]),
              ),
              // Price badge
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _C.gold.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: _C.gold.withOpacity(0.3)),
                ),
                child: Text(
                  cls.price == 0 ? 'FREE' : '\$${cls.price.toStringAsFixed(0)}',
                  style: const TextStyle(
                      color: _C.gold,
                      fontSize: 13,
                      fontWeight: FontWeight.bold),
                ),
              ),
            ]),
          ),

          // Details
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
              Row(children: [
                _infoChip(Icons.access_time_outlined,
                    '${_formatTime(cls.startTime)} – ${_formatTime(cls.endTime)}'),
                const SizedBox(width: 12),
                if (cls.location != null)
                  _infoChip(Icons.location_on_outlined, cls.location!),
              ]),
              const SizedBox(height: 8),
              _infoChip(Icons.person_outline, cls.trainerName),
              if (cls.description != null) ...[
                const SizedBox(height: 8),
                Text(cls.description!,
                    style: const TextStyle(
                        color: _C.textSecondary, fontSize: 12),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis),
              ],

              const SizedBox(height: 12),

              // Capacity bar
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(children: [
                    Icon(Icons.people_outline, size: 14, color: spotsColor),
                    const SizedBox(width: 4),
                    Text(
                      cls.isFull
                          ? 'Fully Booked'
                          : '${cls.spotsLeft} spot${cls.spotsLeft == 1 ? '' : 's'} left',
                      style: TextStyle(
                          color: spotsColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w500),
                    ),
                  ]),
                  Text('${cls.currentBookings}/${cls.maxCapacity}',
                      style: const TextStyle(
                          color: _C.textSecondary, fontSize: 11)),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: fillPct,
                  minHeight: 5,
                  backgroundColor: Colors.white.withOpacity(0.08),
                  valueColor: AlwaysStoppedAnimation(spotsColor),
                ),
              ),

              const SizedBox(height: 14),

              // Book button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: cls.isFull || isBusy
                      ? null
                      : () => _bookClass(cls),
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        cls.isFull ? _C.bgElevated : _C.gold,
                    foregroundColor:
                        cls.isFull ? _C.textSecondary : _C.bgPrimary,
                    disabledBackgroundColor: _C.bgElevated,
                    disabledForegroundColor: _C.textSecondary,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    elevation: cls.isFull ? 0 : 2,
                  ),
                  child: isBusy
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: _C.bgPrimary))
                      : Text(
                          cls.isFull ? 'Class Full' : 'Book Now',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                ),
              ),
            ]),
          ),
        ]),
      ),
    );
  }

  Widget _infoChip(IconData icon, String text) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 13, color: _C.textSecondary),
      const SizedBox(width: 4),
      Text(text,
          style: const TextStyle(color: _C.textSecondary, fontSize: 12)),
    ]);
  }

  // ── STATES ────────────────────────────────────────────────
  Widget _buildLoader() {
    return const Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        SizedBox(
          width: 40,
          height: 40,
          child: CircularProgressIndicator(
            color: _C.gold,
            strokeWidth: 2.5,
          ),
        ),
        SizedBox(height: 16),
        Text('Loading classes...',
            style: TextStyle(color: _C.textSecondary, fontSize: 14)),
      ]),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Icon(Icons.wifi_off_rounded, color: _C.textSecondary, size: 48),
          const SizedBox(height: 16),
          const Text('Couldn\'t load classes',
              style: TextStyle(
                  color: _C.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(_error ?? 'Please check your connection',
              style: const TextStyle(color: _C.textSecondary, fontSize: 13),
              textAlign: TextAlign.center),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _loadClasses,
            icon: const Icon(Icons.refresh_rounded, size: 16),
            label: const Text('Retry'),
            style: ElevatedButton.styleFrom(
              backgroundColor: _C.gold,
              foregroundColor: _C.bgPrimary,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _C.bgCard,
              border: Border.all(color: _C.glassBorder),
            ),
            child: const Icon(Icons.search_off_rounded,
                color: _C.textSecondary, size: 36),
          ),
          const SizedBox(height: 20),
          const Text('No classes found',
              style: TextStyle(
                  color: _C.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(
            _filters.hasActiveFilters
                ? 'Try adjusting your filters'
                : 'No upcoming classes scheduled',
            style: const TextStyle(color: _C.textSecondary, fontSize: 13),
            textAlign: TextAlign.center,
          ),
          if (_filters.hasActiveFilters) ...[
            const SizedBox(height: 20),
            OutlinedButton.icon(
              onPressed: _clearAllFilters,
              icon: const Icon(Icons.filter_list_off, size: 16, color: _C.gold),
              label: const Text('Clear Filters',
                  style: TextStyle(color: _C.gold)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: _C.gold),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ]),
      ),
    );
  }
}