// import 'package:flutter/material.dart';
// import '../../services/api_service.dart';
// import '../../services/auth_service.dart';
// import '../../config/api_config.dart';
// import '../auth/login_screen.dart';
// import 'bookings_screen.dart';
// import 'workouts_screen.dart';
// import 'browse_classes_screen.dart'; 
// import 'purchase_membership_screen.dart'; 


// class MemberDashboard extends StatefulWidget {
//   const MemberDashboard({super.key});

//   @override
//   State<MemberDashboard> createState() => _MemberDashboardState();
// }

// class _MemberDashboardState extends State<MemberDashboard> {
//   final _api = ApiService();
//   final _auth = AuthService();
  
//   Map<String, dynamic>? _dashboardData;
//   bool _isLoading = true;
//   String? _error;

//   @override
//   void initState() {
//     super.initState();
//     _loadDashboard();
//   }

//   Future<void> _loadDashboard() async {
//     setState(() => _isLoading = true);
    
//     final response = await _api.get(ApiConfig.memberDashboard);
    
//     if (response.success) {
//       setState(() {
//         _dashboardData = response.data['dashboard'];
//         _isLoading = false;
//         _error = null;
//       });
//     } else {
//       setState(() {
//         _error = response.error;
//         _isLoading = false;
//       });
//     }
//   }

//   Future<void> _handleLogout() async {
//     await _auth.logout();
//     if (!mounted) return;
//     Navigator.of(context).pushReplacement(
//       MaterialPageRoute(builder: (context) => const LoginScreen()),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.black,
//       appBar: AppBar(
//         title: const Text('Member Dashboard'),
//         backgroundColor: Colors.grey.shade900,
//         actions: [
//           IconButton(
//             icon: const Icon(Icons.refresh),
//             onPressed: _loadDashboard,
//           ),
//           IconButton(
//             icon: const Icon(Icons.logout),
//             onPressed: _handleLogout,
//           ),
//         ],
//       ),
//       body: _isLoading
//           ? const Center(child: CircularProgressIndicator(color: Color(0xFFD4AF37)))
//           : _error != null
//               ? Center(child: Text('Error: $_error', style: const TextStyle(color: Colors.red)))
//               : RefreshIndicator(
//                   onRefresh: _loadDashboard,
//                   color: const Color(0xFFD4AF37),
//                   child: SingleChildScrollView(
//                     physics: const AlwaysScrollableScrollPhysics(),
//                     padding: const EdgeInsets.all(16),
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         // Welcome Card
//                         _buildWelcomeCard(),
//                         const SizedBox(height: 16),
                        
//                         // Stats Cards
//                         _buildStatsGrid(),
//                         const SizedBox(height: 24),
                        
//                         // Quick Actions
//                         _buildQuickActions(),
//                         const SizedBox(height: 24),
                        
//                         // Membership Info
//                         _buildMembershipCard(),
//                       ],
//                     ),
//                   ),
//                 ),
//     );
//   }

//   Widget _buildWelcomeCard() {
//     return Container(
//       width: double.infinity,
//       padding: const EdgeInsets.all(20),
//       decoration: BoxDecoration(
//         gradient: const LinearGradient(
//           colors: [Color(0xFFD4AF37), Color(0xFFB8942A)],
//           begin: Alignment.topLeft,
//           end: Alignment.bottomRight,
//         ),
//         borderRadius: BorderRadius.circular(16),
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Text(
//             'Welcome back, ${_dashboardData?['full_name'] ?? 'Member'}! 👋',
//             style: const TextStyle(
//               fontSize: 20,
//               fontWeight: FontWeight.bold,
//               color: Colors.black87,
//             ),
//           ),
//           const SizedBox(height: 4),
//           Text(
//             _dashboardData?['membership_tier'] ?? 'Member',
//             style: const TextStyle(
//               fontSize: 14,
//               color: Colors.black54,
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildStatsGrid() {
//     return GridView.count(
//       crossAxisCount: 2,
//       shrinkWrap: true,
//       physics: const NeverScrollableScrollPhysics(),
//       mainAxisSpacing: 12,
//       crossAxisSpacing: 12,
//       childAspectRatio: 1.5,
//       children: [
//         _buildStatCard(
//           'Total Visits',
//           '${_dashboardData?['total_visits'] ?? 0}',
//           Icons.calendar_today,
//           Colors.blue,
//         ),
//         _buildStatCard(
//           'Classes Booked',
//           '${_dashboardData?['confirmed_bookings'] ?? 0}',
//           Icons.event_seat,
//           Colors.green,
//         ),
//         _buildStatCard(
//           'Calories Burned',
//           '${_dashboardData?['total_calories_burned'] ?? 0}',
//           Icons.local_fire_department,
//           Colors.orange,
//         ),
//         _buildStatCard(
//           'Workout Logs',
//           '${_dashboardData?['total_workout_logs'] ?? 0}',
//           Icons.fitness_center,
//           Colors.purple,
//         ),
//       ],
//     );
//   }

//   Widget _buildStatCard(String title, String value, IconData icon, Color color) {
//     return Container(
//       padding: const EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         color: Colors.grey.shade900,
//         borderRadius: BorderRadius.circular(12),
//         border: Border.all(color: Colors.grey.shade800),
//       ),
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           Icon(icon, color: color, size: 28),
//           const SizedBox(height: 8),
//           Text(
//             value,
//             style: const TextStyle(
//               fontSize: 24,
//               fontWeight: FontWeight.bold,
//               color: Colors.white,
//             ),
//           ),
//           const SizedBox(height: 4),
//           Text(
//             title,
//             style: TextStyle(
//               fontSize: 12,
//               color: Colors.grey.shade400,
//             ),
//             textAlign: TextAlign.center,
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildQuickActions() {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         const Text(
//           'Quick Actions',
//           style: TextStyle(
//             fontSize: 18,
//             fontWeight: FontWeight.bold,
//             color: Colors.white,
//           ),
//         ),
//         const SizedBox(height: 12),
//         Row(
//           children: [
//             Expanded(
//               child: _buildActionButton(
//                 'Browse Classes',
//                 Icons.event_available,
//                 () {
//                   Navigator.push(
//                     context,
//                     MaterialPageRoute(builder: (context) => const BrowseClassesScreen()),
//                   );
//                 },
//               ),

//             ),
//             const SizedBox(width: 12),
//             Expanded(
//               child: _buildActionButton(
//                 'Log Workout',
//                 Icons.add_circle,
//                 () {
//                   Navigator.push(
//                     context,
//                     MaterialPageRoute(builder: (context) => const WorkoutsScreen()),
//                   );
//                 },
//               ),
//             ),
//           ],
//         ),
//       ],
//     );
//   }

//   Widget _buildActionButton(String label, IconData icon, VoidCallback onTap) {
//     return InkWell(
//       onTap: onTap,
//       child: Container(
//         padding: const EdgeInsets.all(16),
//         decoration: BoxDecoration(
//           color: const Color(0xFFD4AF37),
//           borderRadius: BorderRadius.circular(12),
//         ),
//         child: Row(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Icon(icon, color: Colors.black87, size: 20),
//             const SizedBox(width: 8),
//             Text(
//               label,
//               style: const TextStyle(
//                 color: Colors.black87,
//                 fontWeight: FontWeight.bold,
//                 fontSize: 14,
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildMembershipCard() {
//     final status = _dashboardData?['membership_status'] ?? 'inactive';
//     final expires = _dashboardData?['membership_expires'];
    
//     return Container(
//       width: double.infinity,
//       padding: const EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         color: Colors.grey.shade900,
//         borderRadius: BorderRadius.circular(12),
//         border: Border.all(
//           color: status == 'active' ? Colors.green : Colors.red,
//           width: 2,
//         ),
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Row(
//             children: [
//               Icon(
//                 status == 'active' ? Icons.check_circle : Icons.cancel,
//                 color: status == 'active' ? Colors.green : Colors.red,
//               ),
//               const SizedBox(width: 8),
//               Text(
//                 'Membership Status',
//                 style: TextStyle(
//                   fontSize: 16,
//                   fontWeight: FontWeight.bold,
//                   color: Colors.grey.shade300,
//                 ),
//               ),
//             ],
//           ),
//           const SizedBox(height: 8),
//           Text(
//             status == 'active' ? 'Active' : 'Inactive',
//             style: TextStyle(
//               fontSize: 14,
//               color: status == 'active' ? Colors.green : Colors.red,
//             ),
//           ),
//           if (expires != null) ...[
//             const SizedBox(height: 4),
//             Text(
//               'Expires: $expires',
//               style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
//             ),
//           ],
//         ],
//       ),
//     );
//   }
// }

import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import '../../config/api_config.dart';
import '../auth/login_screen.dart';
import 'bookings_screen.dart';
import 'workouts_screen.dart';
import 'browse_classes_screen.dart'; 
import 'purchase_membership_screen.dart'; 

class MemberDashboard extends StatefulWidget {
  const MemberDashboard({super.key});

  @override
  State<MemberDashboard> createState() => _MemberDashboardState();
}

class _MemberDashboardState extends State<MemberDashboard> {
  final _api = ApiService();
  final _auth = AuthService();
  
  Map<String, dynamic>? _dashboardData;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadDashboard();
  }

  Future<void> _loadDashboard() async {
    setState(() => _isLoading = true);
    
    final response = await _api.get(ApiConfig.memberDashboard);
    
    if (response.success) {
      setState(() {
        _dashboardData = response.data['dashboard'];
        _isLoading = false;
        _error = null;
      });
    } else {
      setState(() {
        _error = response.error;
        _isLoading = false;
      });
    }
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
        title: const Text('Member Dashboard'),
        backgroundColor: Colors.grey.shade900,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadDashboard,
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _handleLogout,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFD4AF37)))
          : _error != null
              ? Center(child: Text('Error: $_error', style: const TextStyle(color: Colors.red)))
              : RefreshIndicator(
                  onRefresh: _loadDashboard,
                  color: const Color(0xFFD4AF37),
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildWelcomeCard(),
                        const SizedBox(height: 16),
                        _buildStatsGrid(),
                        const SizedBox(height: 24),
                        _buildQuickActions(),
                        const SizedBox(height: 24),
                        _buildMembershipCard(),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildWelcomeCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFD4AF37), Color(0xFFB8942A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Welcome back, ${_dashboardData?['full_name'] ?? 'Member'}! 👋',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _dashboardData?['membership_tier'] ?? 'Member',
            style: const TextStyle(
              fontSize: 14,
              color: Colors.black54,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.5,
      children: [
        _buildStatCard(
          'Total Visits',
          '${_dashboardData?['total_visits'] ?? 0}',
          Icons.calendar_today,
          Colors.blue,
        ),
        _buildStatCard(
          'Classes Booked',
          '${_dashboardData?['confirmed_bookings'] ?? 0}',
          Icons.event_seat,
          Colors.green,
        ),
        _buildStatCard(
          'Calories Burned',
          '${_dashboardData?['total_calories_burned'] ?? 0}',
          Icons.local_fire_department,
          Colors.orange,
        ),
        _buildStatCard(
          'Workout Logs',
          '${_dashboardData?['total_workout_logs'] ?? 0}',
          Icons.fitness_center,
          Colors.purple,
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade900,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade800),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade400,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Quick Actions',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildActionButton(
                'Browse Classes',
                Icons.event_available,
                () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const BrowseClassesScreen()),
                  );
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionButton(
                'Log Workout',
                Icons.add_circle,
                () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const WorkoutsScreen()),
                  );
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionButton(String label, IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFD4AF37),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.black87, size: 20),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                color: Colors.black87,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMembershipCard() {
    final status = _dashboardData?['membership_status'] ?? 'inactive';
    final expires = _dashboardData?['membership_expires'];
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade900,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: status == 'active' ? Colors.green : Colors.red,
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                status == 'active' ? Icons.check_circle : Icons.cancel,
                color: status == 'active' ? Colors.green : Colors.red,
              ),
              const SizedBox(width: 8),
              Text(
                'Membership Status',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade300,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            status == 'active' ? 'Active' : 'Inactive',
            style: TextStyle(
              fontSize: 14,
              color: status == 'active' ? Colors.green : Colors.red,
            ),
          ),
          if (expires != null) ...[
            const SizedBox(height: 4),
            Text(
              'Expires: $expires',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
            ),
          ],

          const SizedBox(height: 12),

          
          if (status != 'active')
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFD4AF37),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const PurchaseMembershipScreen(),
                    ),
                  );
                },
                child: const Text(
                  'Purchase Membership',
                  style: TextStyle(color: Colors.black),
                ),
              ),
            ),
        ],
      ),
    );
  }
}