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
}

class StaffDashboard extends StatefulWidget {
  const StaffDashboard({super.key});

  @override
  State<StaffDashboard> createState() => _StaffDashboardState();
}

class _StaffDashboardState extends State<StaffDashboard>
    with SingleTickerProviderStateMixin {
  final _api = ApiService();
  final _auth = AuthService();
  late TabController _tabController;

  bool _isLoading = true;
  String _staffName = 'Staff';

  // Data
  List<dynamic> _attendance = [];
  List<dynamic> _equipment = [];
  List<dynamic> _lockers = [];

  // Check-in form
  final _memberIdCtrl = TextEditingController();
  bool _isCheckingIn = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadAll();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _memberIdCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadAll() async {
    setState(() => _isLoading = true);
    try {
      final meRes = await _api.get(ApiConfig.me);
      if (meRes.success && meRes.data != null) {
        final user = meRes.data['user'] ?? meRes.data;
        setState(() {
          _staffName =
              '${user['first_name'] ?? ''} ${user['last_name'] ?? ''}'.trim();
          if (_staffName.isEmpty) _staffName = 'Staff';
        });
      }
    } catch (_) {}

    await Future.wait([
      _loadAttendance(),
      _loadEquipment(),
    ]);
    setState(() => _isLoading = false);
  }

  Future<void> _loadAttendance() async {
    try {
      final res = await _api.get(ApiConfig.staffAttendanceToday);
      if (res.success && res.data != null) {
        setState(() {
          _attendance = res.data['attendance'] ?? res.data ?? [];
        });
      }
    } catch (_) {}
  }

  Future<void> _loadEquipment() async {
    try {
      final res = await _api.get(ApiConfig.staffEquipment);
      if (res.success && res.data != null) {
        setState(() {
          _equipment = res.data['equipment'] ?? res.data ?? [];
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

  Future<void> _checkIn(int memberId) async {
    setState(() => _isCheckingIn = true);
    try {
      final res = await _api.post(ApiConfig.staffCheckin,
          body: {'member_id': memberId});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(res.success
              ? 'Member #$memberId checked in successfully!'
              : res.error ?? 'Check-in failed'),
          backgroundColor: res.success ? _C.success : _C.error,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ));
        if (res.success) {
          _memberIdCtrl.clear();
          _loadAttendance();
        }
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Network error. Please try again.'),
          backgroundColor: _C.error,
        ));
      }
    } finally {
      if (mounted) setState(() => _isCheckingIn = false);
    }
  }

  Future<void> _checkOut(int memberId) async {
    try {
      final res = await _api.post(ApiConfig.staffCheckout,
          body: {'member_id': memberId});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(res.success
              ? 'Member #$memberId checked out!'
              : res.error ?? 'Check-out failed'),
          backgroundColor: res.success ? _C.warning : _C.error,
          behavior: SnackBarBehavior.floating,
        ));
        if (res.success) _loadAttendance();
      }
    } catch (_) {}
  }

  Future<void> _updateEquipmentStatus(
      int equipmentId, String status) async {
    try {
      final res = await _api.put(
        ApiConfig.staffEquipmentUpdate(equipmentId),
        body: {'status': status},
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(res.success
              ? 'Equipment status updated!'
              : res.error ?? 'Update failed'),
          backgroundColor: res.success ? _C.success : _C.error,
          behavior: SnackBarBehavior.floating,
        ));
        if (res.success) _loadEquipment();
      }
    } catch (_) {}
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
                      _buildCheckinTab(),
                      _buildAttendanceTab(),
                      _buildEquipmentTab(),
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
          child: Row(children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                    colors: [_C.gold, _C.darkGold]),
              ),
              child:
                  const Icon(Icons.badge, color: _C.bgPrimary, size: 24),
            ),
            const SizedBox(width: 12),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Welcome back,',
                  style:
                      TextStyle(color: _C.textSecondary, fontSize: 13)),
              Text(_staffName,
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
                color: _C.info.withOpacity(0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: _C.info.withOpacity(0.4)),
              ),
              child: const Text('STAFF',
                  style: TextStyle(
                      color: _C.info,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1)),
            ),
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
          Tab(text: 'Check In'),
          Tab(text: 'Attendance'),
          Tab(text: 'Equipment'),
        ],
      ),
    );
  }

  // ── CHECK-IN TAB ──────────────────────────────────────────
  Widget _buildCheckinTab() {
    final checkedInCount =
        _attendance.where((a) => a['check_out_time'] == null).length;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Stats row
        Row(children: [
          Expanded(
            child: _miniStat('Today\'s Check-ins',
                '${_attendance.length}', Icons.login_rounded, _C.success),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _miniStat('Currently Inside', '$checkedInCount',
                Icons.people_rounded, _C.gold),
          ),
        ]),
        const SizedBox(height: 24),

        // Check-in card
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: _C.bgCard,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _C.glassBorder),
            boxShadow: [
              BoxShadow(
                  color: _C.gold.withOpacity(0.05),
                  blurRadius: 20,
                  spreadRadius: 2),
            ],
          ),
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
            const Row(children: [
              Icon(Icons.login_rounded, color: _C.gold, size: 20),
              SizedBox(width: 8),
              Text('Member Check-In',
                  style: TextStyle(
                      color: _C.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.bold)),
            ]),
            const SizedBox(height: 16),
            TextField(
              controller: _memberIdCtrl,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: _C.textPrimary),
              decoration: InputDecoration(
                hintText: 'Enter Member ID',
                hintStyle: const TextStyle(color: _C.textSecondary),
                prefixIcon: const Icon(Icons.badge_outlined,
                    color: _C.textSecondary, size: 20),
                filled: true,
                fillColor: _C.bgElevated,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: _C.gold, width: 1.5),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _isCheckingIn
                      ? null
                      : () {
                          final id =
                              int.tryParse(_memberIdCtrl.text.trim());
                          if (id != null) _checkIn(id);
                        },
                  icon: _isCheckingIn
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: _C.bgPrimary))
                      : const Icon(Icons.login_rounded, size: 18),
                  label:
                      Text(_isCheckingIn ? 'Checking in...' : 'Check In'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _C.gold,
                    foregroundColor: _C.bgPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    final id = int.tryParse(_memberIdCtrl.text.trim());
                    if (id != null) _checkOut(id);
                  },
                  icon: const Icon(Icons.logout_rounded, size: 18),
                  label: const Text('Check Out'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _C.warning,
                    side: BorderSide(color: _C.warning.withOpacity(0.5)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ]),
          ]),
        ),

        // Recent check-ins
        if (_attendance.isNotEmpty) ...[
          const SizedBox(height: 24),
          const Text('Recent Check-ins',
              style: TextStyle(
                  color: _C.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          ..._attendance.take(5).map((a) => _attendanceTile(a)),
        ],
      ],
    );
  }

  // ── ATTENDANCE TAB ────────────────────────────────────────
  Widget _buildAttendanceTab() {
    return RefreshIndicator(
      color: _C.gold,
      backgroundColor: _C.bgCard,
      onRefresh: _loadAttendance,
      child: _attendance.isEmpty
          ? _emptyState(
              icon: Icons.people_outline,
              title: 'No Attendance Today',
              subtitle: 'Check-in records will appear here',
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _attendance.length,
              itemBuilder: (_, i) => _attendanceCard(_attendance[i]),
            ),
    );
  }

  // ── EQUIPMENT TAB ─────────────────────────────────────────
  Widget _buildEquipmentTab() {
    final operational =
        _equipment.where((e) => e['status'] == 'operational').length;
    final maintenance =
        _equipment.where((e) => e['status'] == 'maintenance').length;
    final outOfOrder =
        _equipment.where((e) => e['status'] == 'out_of_order').length;

    return RefreshIndicator(
      color: _C.gold,
      backgroundColor: _C.bgCard,
      onRefresh: _loadEquipment,
      child: _equipment.isEmpty
          ? _emptyState(
              icon: Icons.fitness_center_outlined,
              title: 'No Equipment Data',
              subtitle: 'Equipment list will appear here',
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Status summary
                Row(children: [
                  Expanded(
                      child: _miniStat(
                          'Operational', '$operational',
                          Icons.check_circle_outline, _C.success)),
                  const SizedBox(width: 8),
                  Expanded(
                      child: _miniStat('Maintenance', '$maintenance',
                          Icons.build_outlined, _C.warning)),
                  const SizedBox(width: 8),
                  Expanded(
                      child: _miniStat('Out of Order', '$outOfOrder',
                          Icons.cancel_outlined, _C.error)),
                ]),
                const SizedBox(height: 16),
                ..._equipment.map((e) => _equipmentCard(e)),
              ],
            ),
    );
  }

  // ── WIDGETS ───────────────────────────────────────────────
  Widget _miniStat(
      String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(height: 6),
        Text(value,
            style: TextStyle(
                color: color,
                fontSize: 20,
                fontWeight: FontWeight.bold)),
        Text(label,
            style: const TextStyle(color: _C.textSecondary, fontSize: 10)),
      ]),
    );
  }

  Widget _attendanceTile(dynamic a) {
    final name =
        '${a['first_name'] ?? ''} ${a['last_name'] ?? ''}'.trim();
    final checkIn = a['check_in_time'] ?? '';
    final isInside = a['check_out_time'] == null;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: _C.bgCard,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Row(children: [
        CircleAvatar(
          radius: 16,
          backgroundColor: isInside
              ? _C.success.withOpacity(0.15)
              : _C.textSecondary.withOpacity(0.1),
          child: Text(
            name.isNotEmpty ? name[0].toUpperCase() : '?',
            style: TextStyle(
                color: isInside ? _C.success : _C.textSecondary,
                fontWeight: FontWeight.bold,
                fontSize: 12),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(name.isEmpty ? 'Member' : name,
              style: const TextStyle(color: _C.textPrimary, fontSize: 13)),
        ),
        Text(checkIn,
            style:
                const TextStyle(color: _C.textSecondary, fontSize: 11)),
        const SizedBox(width: 8),
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isInside ? _C.success : _C.textSecondary,
          ),
        ),
      ]),
    );
  }

  Widget _attendanceCard(dynamic a) {
    final name =
        '${a['first_name'] ?? ''} ${a['last_name'] ?? ''}'.trim();
    final checkIn = a['check_in_time'] ?? 'N/A';
    final checkOut = a['check_out_time'] ?? 'Still inside';
    final isInside = a['check_out_time'] == null;
    final memberId = a['member_id'] ?? a['user_id'];

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _C.bgCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isInside
              ? _C.success.withOpacity(0.2)
              : Colors.white.withOpacity(0.05),
        ),
      ),
      child: Row(children: [
        CircleAvatar(
          radius: 20,
          backgroundColor: isInside
              ? _C.success.withOpacity(0.15)
              : _C.bgElevated,
          child: Text(
            name.isNotEmpty ? name[0].toUpperCase() : '?',
            style: TextStyle(
                color: isInside ? _C.success : _C.textSecondary,
                fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
            Text(name.isEmpty ? 'Member #$memberId' : name,
                style: const TextStyle(
                    color: _C.textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 14)),
            const SizedBox(height: 2),
            Row(children: [
              const Icon(Icons.login, size: 11, color: _C.textSecondary),
              const SizedBox(width: 3),
              Text(checkIn,
                  style: const TextStyle(
                      color: _C.textSecondary, fontSize: 11)),
              if (!isInside) ...[
                const SizedBox(width: 8),
                const Icon(Icons.logout, size: 11, color: _C.textSecondary),
                const SizedBox(width: 3),
                Text(checkOut,
                    style: const TextStyle(
                        color: _C.textSecondary, fontSize: 11)),
              ],
            ]),
          ]),
        ),
        if (isInside)
          TextButton(
            onPressed: () {
              if (memberId != null) _checkOut(memberId);
            },
            style: TextButton.styleFrom(
              foregroundColor: _C.warning,
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            ),
            child: const Text('Check Out',
                style: TextStyle(fontSize: 12)),
          )
        else
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: _C.bgElevated,
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Text('Done',
                style:
                    TextStyle(color: _C.textSecondary, fontSize: 11)),
          ),
      ]),
    );
  }

  Widget _equipmentCard(dynamic e) {
    final name = e['equipment_name'] ?? e['name'] ?? 'Equipment';
    final status = e['status'] ?? 'operational';
    final equipmentId = e['equipment_id'] ?? e['id'];

    final statusColor = status == 'operational'
        ? _C.success
        : status == 'maintenance'
            ? _C.warning
            : _C.error;

    final statusLabel = status == 'operational'
        ? 'Operational'
        : status == 'maintenance'
            ? 'Maintenance'
            : 'Out of Order';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _C.bgCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: statusColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(Icons.fitness_center, color: statusColor, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
            Text(name,
                style: const TextStyle(
                    color: _C.textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 14)),
            const SizedBox(height: 2),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(statusLabel,
                  style: TextStyle(
                      color: statusColor,
                      fontSize: 10,
                      fontWeight: FontWeight.w500)),
            ),
          ]),
        ),
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert,
              color: _C.textSecondary, size: 20),
          color: _C.bgElevated,
          onSelected: (val) {
            if (equipmentId != null) {
              _updateEquipmentStatus(equipmentId, val);
            }
          },
          itemBuilder: (_) => [
            const PopupMenuItem(
              value: 'operational',
              child: Row(children: [
                Icon(Icons.check_circle_outline,
                    color: _C.success, size: 16),
                SizedBox(width: 8),
                Text('Mark Operational',
                    style: TextStyle(color: _C.textPrimary, fontSize: 13)),
              ]),
            ),
            const PopupMenuItem(
              value: 'maintenance',
              child: Row(children: [
                Icon(Icons.build_outlined,
                    color: _C.warning, size: 16),
                SizedBox(width: 8),
                Text('Send to Maintenance',
                    style: TextStyle(color: _C.textPrimary, fontSize: 13)),
              ]),
            ),
            const PopupMenuItem(
              value: 'out_of_order',
              child: Row(children: [
                Icon(Icons.cancel_outlined, color: _C.error, size: 16),
                SizedBox(width: 8),
                Text('Mark Out of Order',
                    style: TextStyle(color: _C.textPrimary, fontSize: 13)),
              ]),
            ),
          ],
        ),
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
}