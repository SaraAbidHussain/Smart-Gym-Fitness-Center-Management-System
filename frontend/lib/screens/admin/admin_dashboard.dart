import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import '../../config/api_config.dart';
import '../auth/login_screen.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  final _api = ApiService();
  final _auth = AuthService();
  
  Map<String, dynamic>? _analytics;
  Map<String, dynamic>? _revenue;
  List<dynamic> _users = [];
  bool _isLoading = true;
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    final analyticsRes = await _api.get(ApiConfig.adminAnalytics);
    final revenueRes = await _api.get(ApiConfig.adminRevenue);
    final usersRes = await _api.get(ApiConfig.adminUsers, queryParams: {'per_page': '10'});
    
    setState(() {
      if (analyticsRes.success) _analytics = analyticsRes.data['analytics'];
      if (revenueRes.success) _revenue = revenueRes.data['revenue'];
      if (usersRes.success) _users = usersRes.data['users'] ?? [];
      _isLoading = false;
    });
  }

  Future<void> _handleLogout() async {
    await _auth.logout();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        backgroundColor: Colors.grey.shade900,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadData),
          IconButton(icon: const Icon(Icons.logout), onPressed: _handleLogout),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFD4AF37)))
          : IndexedStack(
              index: _selectedIndex,
              children: [
                _buildOverviewTab(),
                _buildUsersTab(),
                _buildRevenueTab(),
              ],
            ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        backgroundColor: Colors.grey.shade900,
        selectedItemColor: const Color(0xFFD4AF37),
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Overview'),
          BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Users'),
          BottomNavigationBarItem(icon: Icon(Icons.attach_money), label: 'Revenue'),
        ],
      ),
    );
  }

  Widget _buildOverviewTab() {
    final userStats = _analytics?['user_stats'] ?? {};
    final memberStats = userStats['member'] ?? {};
    final classStats = _analytics?['class_stats'] ?? {};
    
    return RefreshIndicator(
      onRefresh: _loadData,
      color: const Color(0xFFD4AF37),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Stats Grid
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.5,
              children: [
                _buildStatCard('Total Users', '${_users.length}', Icons.people, Colors.blue),
                _buildStatCard('Members', '${memberStats['active'] ?? 0}', Icons.person, Colors.green),
                _buildStatCard('Classes', '${classStats['total_schedules'] ?? 0}', Icons.event, Colors.orange),
                _buildStatCard('Revenue', '₨${_revenue?['total_revenue']?.toStringAsFixed(0) ?? '0'}', Icons.money, Color(0xFFD4AF37)),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // User Distribution Chart
            _buildUserDistributionChart(),
            
            const SizedBox(height: 24),
            
            // Quick Stats
            _buildQuickStats(),
          ],
        ),
      ),
    );
  }

  Widget _buildUsersTab() {
    return RefreshIndicator(
      onRefresh: _loadData,
      color: const Color(0xFFD4AF37),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _users.length,
        itemBuilder: (context, index) {
          final user = _users[index];
          return _buildUserCard(user);
        },
      ),
    );
  }

  Widget _buildRevenueTab() {
    return RefreshIndicator(
      onRefresh: _loadData,
      color: const Color(0xFFD4AF37),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildRevenueCard('Total Revenue', _revenue?['total_revenue'], Colors.green),
            _buildRevenueCard('Membership', _revenue?['membership_revenue'], Color(0xFFD4AF37)),
            _buildRevenueCard('Training', _revenue?['training_revenue'], Colors.blue),
            _buildRevenueCard('Products', _revenue?['product_revenue'], Colors.orange),
            
            const SizedBox(height: 24),
            _buildRevenueChart(),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade900,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 4),
          Text(title, style: TextStyle(fontSize: 12, color: Colors.grey.shade400), textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _buildUserCard(Map<String, dynamic> user) {
    final isActive = user['is_active'] ?? false;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade900,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade800),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: const Color(0xFFD4AF37).withOpacity(0.2),
            child: Text(
              '${user['first_name']?[0] ?? 'U'}${user['last_name']?[0] ?? ''}',
              style: const TextStyle(color: Color(0xFFD4AF37)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${user['first_name']} ${user['last_name']}',
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                ),
                Text(user['email'] ?? '', style: TextStyle(fontSize: 12, color: Colors.grey.shade400)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: (user['role'] == 'admin' ? Colors.red : Color(0xFFD4AF37)).withOpacity(0.2),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              user['role'] ?? '',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: user['role'] == 'admin' ? Colors.red : const Color(0xFFD4AF37),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Icon(
            isActive ? Icons.check_circle : Icons.cancel,
            color: isActive ? Colors.green : Colors.red,
            size: 20,
          ),
        ],
      ),
    );
  }

  Widget _buildRevenueCard(String title, dynamic amount, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade900,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(color: Colors.white)),
          Text(
            '₨${amount?.toStringAsFixed(0) ?? '0'}',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color),
          ),
        ],
      ),
    );
  }

  Widget _buildUserDistributionChart() {
    final userStats = _analytics?['user_stats'] ?? {};
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade900,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('User Distribution', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: PieChart(
              PieChartData(
                sectionsSpace: 2,
                centerSpaceRadius: 40,
                sections: [
                  PieChartSectionData(
                    value: (userStats['member']?['total'] ?? 0).toDouble(),
                    title: 'Members',
                    color: Colors.blue,
                    radius: 50,
                  ),
                  PieChartSectionData(
                    value: (userStats['trainer']?['total'] ?? 0).toDouble(),
                    title: 'Trainers',
                    color: Colors.green,
                    radius: 50,
                  ),
                  PieChartSectionData(
                    value: (userStats['staff']?['total'] ?? 0).toDouble(),
                    title: 'Staff',
                    color: Colors.orange,
                    radius: 50,
                  ),
                  PieChartSectionData(
                    value: (userStats['admin']?['total'] ?? 0).toDouble(),
                    title: 'Admins',
                    color: Colors.red,
                    radius: 50,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRevenueChart() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade900,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Revenue Breakdown', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: BarChart(
              BarChartData(
                barGroups: [
                  BarChartGroupData(x: 0, barRods: [BarChartRodData(toY: (_revenue?['membership_revenue'] ?? 0).toDouble(), color: Color(0xFFD4AF37))]),
                  BarChartGroupData(x: 1, barRods: [BarChartRodData(toY: (_revenue?['training_revenue'] ?? 0).toDouble(), color: Colors.blue)]),
                  BarChartGroupData(x: 2, barRods: [BarChartRodData(toY: (_revenue?['product_revenue'] ?? 0).toDouble(), color: Colors.orange)]),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStats() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade900,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Quick Stats', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 12),
          _buildQuickStatRow('Active Memberships', '${_analytics?['membership_stats']?['active'] ?? 0}'),
          _buildQuickStatRow('Total Schedules', '${_analytics?['class_stats']?['total_schedules'] ?? 0}'),
          _buildQuickStatRow('Upcoming Classes', '${_analytics?['class_stats']?['upcoming'] ?? 0}'),
        ],
      ),
    );
  }

  Widget _buildQuickStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey.shade400)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        ],
      ),
    );
  }
}