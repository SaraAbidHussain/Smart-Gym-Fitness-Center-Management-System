import 'package:flutter/material.dart';
import 'member/member_dashboard.dart';
import 'admin/admin_dashboard.dart';
import 'trainer/trainer_dashboard.dart';
import 'staff/staff_dashboard.dart';

/// Dashboard Router
/// Routes users to appropriate dashboard based on their role
class DashboardRouter extends StatelessWidget {
  final String role;

  const DashboardRouter({
    super.key,
    required this.role,
  });

  @override
  Widget build(BuildContext context) {
    switch (role.toLowerCase()) {
      case 'member':
        return const MemberDashboard();
      case 'trainer':
        return const TrainerDashboard();
      case 'staff':
        return const StaffDashboard();
      case 'admin':
        return const AdminDashboard();
      default:
        return const MemberDashboard();
    }
  }
}