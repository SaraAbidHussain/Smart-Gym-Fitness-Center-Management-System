import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import '../../config/api_config.dart';
import '../../services/token_storage.dart';
import '../auth/login_screen.dart';

// ─────────────────────────────────────────────────────────────
// THEME CONSTANTS
// ─────────────────────────────────────────────────────────────
class _C {
  static const gold = Color(0xFFD4AF37);
  static const lightGold = Color(0xFFE6C86E);
  static const darkGold = Color(0xFFB8942A);
  static const navy = Color(0xFF1E293B);
  static const bgPrimary = Color(0xFF0A0A0A);
  static const bgCard = Color(0xFF1F1F1F);
  static const bgElevated = Color(0xFF2A2A2A);
  static const success = Color(0xFF10B981);
  static const warning = Color(0xFFF59E0B);
  static const error = Color(0xFFEF4444);
  static const info = Color(0xFF3B82F6);
  static const textPrimary = Colors.white;
  static const textSecondary = Color(0xFF94A3B8);
  static const glassBorder = Color(0x40D4AF37);
  static const glassTint = Color(0x14D4AF37);
}

class TrainerDashboard extends StatefulWidget {
  const TrainerDashboard({super.key});

  @override
  State<TrainerDashboard> createState() => _TrainerDashboardState();
}

class _TrainerDashboardState extends State<TrainerDashboard>
    with SingleTickerProviderStateMixin {
  final _api = ApiService();
  final _auth = AuthService();
  late TabController _tabController;

  bool _isLoading = true;
  String _trainerName = 'Trainer';

  // Data
  List<dynamic> _clients = [];
  Map<String, dynamic> _performance = {};
  List<dynamic> _schedule = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadAll();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAll() async {
    setState(() => _isLoading = true);
    final role = await TokenStorage.getUserRole();
    // Load trainer name from stored data
    try {
      final meRes = await _api.get(ApiConfig.me);
      if (meRes.success && meRes.data != null) {
        final user = meRes.data['user'] ?? meRes.data;
        setState(() {
          _trainerName =
              '${user['first_name'] ?? ''} ${user['last_name'] ?? ''}'.trim();
          if (_trainerName.isEmpty) _trainerName = 'Trainer';
        });
      }
    } catch (_) {}

    await Future.wait([_loadClients(), _loadPerformance(), _loadSchedule()]);
    setState(() => _isLoading = false);
  }

  Future<void> _loadClients() async {
    try {
      final res = await _api.get(ApiConfig.trainerClients);
      if (res.success && res.data != null) {
        setState(() {
          _clients = res.data['clients'] ?? res.data ?? [];
        });
      }
    } catch (_) {}
  }

  Future<void> _loadPerformance() async {
    try {
      final res = await _api.get(ApiConfig.trainerPerformance);
      if (res.success && res.data != null) {
        setState(() => _performance = res.data as Map<String, dynamic>);
      }
    } catch (_) {}
  }

  Future<void> _loadSchedule() async {
    try {
      final res = await _api.get(ApiConfig.trainerSchedule);
      if (res.success && res.data != null) {
        setState(() {
          _schedule = res.data['schedule'] ?? res.data ?? [];
        });
      }
    } catch (_) {}
  }

  Future<void> _logout() async {
    await _auth.logout();
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (_) => false,
      );
    }
  }

  // ─────────────────────────────────────────────────────────────
  // BUILD
  // ─────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _C.bgPrimary,
      body: NestedScrollView(
        headerSliverBuilder: (_, __) => [_buildAppBar()],
        body: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: _C.gold))
            : Column(children: [
                _buildTabBar(),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildOverviewTab(),
                      _buildClientsTab(),
                      _buildScheduleTab(),
                    ],
                  ),
                ),
              ]),
      ),
    );
  }

  // ── APP BAR ───────────────────────────────────────────────
  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 140,
      pinned: true,
      backgroundColor: _C.bgPrimary,
      surfaceTintColor: Colors.transparent,
      automaticallyImplyLeading: false,
      actions: [
        IconButton(
          icon: const Icon(Icons.logout_rounded, color: _C.textSecondary),
          onPressed: _logout,
          tooltip: 'Logout',
        ),
        const SizedBox(width: 8),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [_C.navy.withOpacity(0.6), _C.bgPrimary],
            ),
          ),
          padding: const EdgeInsets.fromLTRB(20, 60, 20, 0),
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
            Row(children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [_C.gold, _C.darkGold],
                  ),
                ),
                child: const Icon(Icons.fitness_center,
                    color: _C.bgPrimary, size: 24),
              ),
              const SizedBox(width: 12),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Welcome back,',
                    style:
                        TextStyle(color: _C.textSecondary, fontSize: 13)),
                Text(_trainerName,
                    style: const TextStyle(
                        color: _C.textPrimary,
                        fontSize: 20,
                        fontWeight: FontWeight.bold)),
              ]),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _C.gold.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: _C.gold.withOpacity(0.4)),
                ),
                child: const Text('TRAINER',
                    style: TextStyle(
                        color: _C.gold,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1)),
              ),
            ]),
          ]),
        ),
      ),
    );
  }

  // ── TAB BAR ───────────────────────────────────────────────
  Widget _buildTabBar() {
    return Container(
      color: _C.bgPrimary,
      child: TabBar(
        controller: _tabController,
        labelColor: _C.gold,
        unselectedLabelColor: _C.textSecondary,
        indicatorColor: _C.gold,
        indicatorWeight: 2,
        tabs: const [
          Tab(text: 'Overview'),
          Tab(text: 'Clients'),
          Tab(text: 'Schedule'),
        ],
      ),
    );
  }

  // ── OVERVIEW TAB ──────────────────────────────────────────
  Widget _buildOverviewTab() {
    final totalClients = _performance['total_clients'] ??
        _performance['clients_count'] ??
        _clients.length;
    final avgRating =
        _performance['avg_rating'] ?? _performance['rating'] ?? 0.0;
    final totalSessions =
        _performance['total_sessions'] ?? _performance['sessions'] ?? 0;
    final upcomingClasses =
        _performance['upcoming_classes'] ?? _schedule.length;

    return RefreshIndicator(
      color: _C.gold,
      backgroundColor: _C.bgCard,
      onRefresh: _loadAll,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Stats grid
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.4,
            children: [
              _statCard('Clients', '$totalClients',
                  Icons.people_outline, _C.gold),
              _statCard('Avg Rating', '${(avgRating as num).toStringAsFixed(1)}⭐',
                  Icons.star_outline, _C.warning),
              _statCard('Sessions', '$totalSessions',
                  Icons.event_available_outlined, _C.success),
              _statCard('Upcoming', '$upcomingClasses',
                  Icons.schedule_outlined, _C.info),
            ],
          ),
          const SizedBox(height: 20),

          // Quick Actions
          _sectionHeader('Quick Actions'),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(
              child: _actionButton(
                icon: Icons.assignment_outlined,
                label: 'Create\nWorkout Plan',
                color: _C.gold,
                onTap: () => _showCreatePlanDialog('workout'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _actionButton(
                icon: Icons.restaurant_menu_outlined,
                label: 'Create\nNutrition Plan',
                color: _C.success,
                onTap: () => _showCreatePlanDialog('nutrition'),
              ),
            ),
          ]),
          const SizedBox(height: 20),

          // Recent clients preview
          if (_clients.isNotEmpty) ...[
            _sectionHeader('Recent Clients'),
            const SizedBox(height: 12),
            ..._clients.take(3).map((c) => _clientTile(c)),
          ],
        ],
      ),
    );
  }

  // ── CLIENTS TAB ───────────────────────────────────────────
  Widget _buildClientsTab() {
    return RefreshIndicator(
      color: _C.gold,
      backgroundColor: _C.bgCard,
      onRefresh: _loadClients,
      child: _clients.isEmpty
          ? _emptyState(
              icon: Icons.people_outline,
              title: 'No Clients Yet',
              subtitle: 'Your assigned clients will appear here',
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _clients.length,
              itemBuilder: (_, i) => _clientCard(_clients[i]),
            ),
    );
  }

  // ── SCHEDULE TAB ──────────────────────────────────────────
  Widget _buildScheduleTab() {
    return RefreshIndicator(
      color: _C.gold,
      backgroundColor: _C.bgCard,
      onRefresh: _loadSchedule,
      child: _schedule.isEmpty
          ? _emptyState(
              icon: Icons.calendar_today_outlined,
              title: 'No Upcoming Classes',
              subtitle: 'Your scheduled classes will appear here',
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _schedule.length,
              itemBuilder: (_, i) => _scheduleCard(_schedule[i]),
            ),
    );
  }

  // ── WIDGETS ───────────────────────────────────────────────
  Widget _statCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _C.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(value,
              style: const TextStyle(
                  color: _C.textPrimary,
                  fontSize: 22,
                  fontWeight: FontWeight.bold)),
          Text(label,
              style:
                  const TextStyle(color: _C.textSecondary, fontSize: 12)),
        ]),
      ]),
    );
  }

  Widget _actionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(label,
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: color,
                  fontSize: 12,
                  fontWeight: FontWeight.w600)),
        ]),
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Text(title,
        style: const TextStyle(
            color: _C.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.bold));
  }

  Widget _clientTile(dynamic client) {
    final name =
        '${client['first_name'] ?? ''} ${client['last_name'] ?? ''}'.trim();
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _C.bgCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Row(children: [
        CircleAvatar(
          radius: 18,
          backgroundColor: _C.gold.withOpacity(0.2),
          child: Text(
            name.isNotEmpty ? name[0].toUpperCase() : '?',
            style: const TextStyle(
                color: _C.gold, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(name.isEmpty ? 'Unknown' : name,
              style: const TextStyle(color: _C.textPrimary, fontSize: 14)),
        ),
        const Icon(Icons.chevron_right, color: _C.textSecondary, size: 18),
      ]),
    );
  }

  Widget _clientCard(dynamic client) {
    final name =
        '${client['first_name'] ?? ''} ${client['last_name'] ?? ''}'.trim();
    final email = client['email'] ?? '';
    final membership = client['membership_type'] ?? client['plan'] ?? 'Standard';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _C.bgCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Row(children: [
        CircleAvatar(
          radius: 24,
          backgroundColor: _C.gold.withOpacity(0.15),
          child: Text(
            name.isNotEmpty ? name[0].toUpperCase() : '?',
            style: const TextStyle(
                color: _C.gold,
                fontWeight: FontWeight.bold,
                fontSize: 18),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
            Text(name.isEmpty ? 'Unknown' : name,
                style: const TextStyle(
                    color: _C.textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 15)),
            if (email.isNotEmpty)
              Text(email,
                  style: const TextStyle(
                      color: _C.textSecondary, fontSize: 12)),
            const SizedBox(height: 4),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: _C.gold.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(membership,
                  style: const TextStyle(
                      color: _C.gold,
                      fontSize: 10,
                      fontWeight: FontWeight.w500)),
            ),
          ]),
        ),
      ]),
    );
  }

  Widget _scheduleCard(dynamic item) {
    final className = item['class_name'] ?? item['name'] ?? 'Class';
    final startTime = item['start_time'] ?? item['time'] ?? '';
    final date = item['schedule_date'] ?? item['date'] ?? '';
    final room = item['room_number'] ?? item['location'] ?? '';
    final capacity =
        '${item['current_capacity'] ?? 0}/${item['max_capacity'] ?? 0}';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _C.bgCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Row(children: [
        Container(
          width: 4,
          height: 56,
          decoration: BoxDecoration(
            color: _C.gold,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
            Text(className,
                style: const TextStyle(
                    color: _C.textPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 15)),
            const SizedBox(height: 4),
            Row(children: [
              const Icon(Icons.access_time_outlined,
                  size: 12, color: _C.textSecondary),
              const SizedBox(width: 4),
              Text('$date  $startTime',
                  style: const TextStyle(
                      color: _C.textSecondary, fontSize: 12)),
            ]),
            if (room.isNotEmpty)
              Row(children: [
                const Icon(Icons.location_on_outlined,
                    size: 12, color: _C.textSecondary),
                const SizedBox(width: 4),
                Text(room,
                    style: const TextStyle(
                        color: _C.textSecondary, fontSize: 12)),
              ]),
          ]),
        ),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          const Icon(Icons.people_outline,
              size: 14, color: _C.textSecondary),
          Text(capacity,
              style:
                  const TextStyle(color: _C.textSecondary, fontSize: 11)),
        ]),
      ]),
    );
  }

  Widget _emptyState(
      {required IconData icon,
      required String title,
      required String subtitle}) {
    return Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _C.bgCard,
            border: Border.all(color: _C.glassBorder),
          ),
          child: Icon(icon, color: _C.textSecondary, size: 32),
        ),
        const SizedBox(height: 16),
        Text(title,
            style: const TextStyle(
                color: _C.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        Text(subtitle,
            style:
                const TextStyle(color: _C.textSecondary, fontSize: 13),
            textAlign: TextAlign.center),
      ]),
    );
  }

  // ── CREATE PLAN DIALOG ────────────────────────────────────
  void _showCreatePlanDialog(String type) {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final isWorkout = type == 'workout';

    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: _C.bgCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: _C.gold.withOpacity(0.3)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text(
              isWorkout ? 'Create Workout Plan' : 'Create Nutrition Plan',
              style: const TextStyle(
                  color: _C.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: titleCtrl,
              style: const TextStyle(color: _C.textPrimary),
              decoration: InputDecoration(
                hintText: 'Plan title',
                hintStyle: const TextStyle(color: _C.textSecondary),
                filled: true,
                fillColor: _C.bgElevated,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: descCtrl,
              style: const TextStyle(color: _C.textPrimary),
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Description',
                hintStyle: const TextStyle(color: _C.textSecondary),
                filled: true,
                fillColor: _C.bgElevated,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Colors.white.withOpacity(0.2)),
                    foregroundColor: _C.textSecondary,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('Cancel'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () async {
                    Navigator.pop(context);
                    final endpoint = isWorkout
                        ? ApiConfig.trainerWorkoutPlans
                        : ApiConfig.trainerNutritionPlans;
                    final res = await _api.post(endpoint, body: {
                      'title': titleCtrl.text,
                      'description': descCtrl.text,
                    });
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text(res.success
                            ? 'Plan created successfully!'
                            : res.error ?? 'Failed to create plan'),
                        backgroundColor:
                            res.success ? _C.success : _C.error,
                        behavior: SnackBarBehavior.floating,
                      ));
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _C.gold,
                    foregroundColor: _C.bgPrimary,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('Create',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ]),
          ]),
        ),
      ),
    );
  }
}