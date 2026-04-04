import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../config/api_config.dart';

class PurchaseMembershipScreen extends StatefulWidget {
  const PurchaseMembershipScreen({super.key});

  @override
  State<PurchaseMembershipScreen> createState() => _PurchaseMembershipScreenState();
}

class _PurchaseMembershipScreenState extends State<PurchaseMembershipScreen> {
  final _api = ApiService();
  List<dynamic> _tiers = [];
  int? _selectedTierId;
  String _paymentMethod = 'credit_card';
  bool _isLoading = true;
  bool _isPurchasing = false;

  @override
  void initState() {
    super.initState();
    _loadTiers();
  }

  Future<void> _loadTiers() async {
    setState(() => _isLoading = true);
    
    final response = await _api.get(
      ApiConfig.membershipTiers,
      requiresAuth: false,
    );
    
    if (response.success) {
      setState(() {
        _tiers = response.data['tiers'] ?? [];
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _purchaseMembership() async {
    if (_selectedTierId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a membership tier'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Show confirmation dialog
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Purchase'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('This will:'),
            const SizedBox(height: 8),
            const Text('✓ Create payment record', style: TextStyle(fontSize: 12)),
            const Text('✓ Activate membership', style: TextStyle(fontSize: 12)),
            const Text('✓ Assign locker (if Premium/VIP)', style: TextStyle(fontSize: 12)),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue.shade900.withOpacity(0.3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                '💡 ACID Transaction Demo:\nAll operations succeed together or rollback on failure',
                style: TextStyle(fontSize: 11, color: Colors.blue),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD4AF37)),
            child: const Text('Confirm Purchase'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isPurchasing = true);

    // Call ACID transaction endpoint
    final response = await _api.post(
      ApiConfig.purchaseMembership,
      body: {
        'tier_id': _selectedTierId,
        'payment_method': _paymentMethod,
      },
    );

    setState(() => _isPurchasing = false);

    if (!mounted) return;

    if (response.success) {
      // Show success with transaction details
      await _showSuccessDialog(response.data);
      
      // Go back to dashboard
      Navigator.of(context).pop();
    } else {
      // Show rollback message
      _showErrorDialog(response.error ?? 'Transaction failed');
    }
  }

  Future<void> _showSuccessDialog(Map<String, dynamic> data) async {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle, color: Colors.green, size: 32),
            ),
            const SizedBox(width: 12),
            const Text('Success!'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Transaction Completed Successfully',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Text('ACID Transaction Steps:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            _buildTransactionStep('1. BEGIN TRANSACTION', true),
            _buildTransactionStep('2. Payment Record Created', true),
            _buildTransactionStep('3. Membership Activated', true),
            if (data['transaction']?['locker_id'] != null)
              _buildTransactionStep('4. Locker Assigned', true),
            _buildTransactionStep('5. COMMIT TRANSACTION', true),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFD4AF37).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFD4AF37)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Transaction Details:',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade300,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Membership ID: ${data['transaction']?['membership_id']}',
                    style: const TextStyle(fontSize: 11),
                  ),
                  Text(
                    'Payment ID: ${data['transaction']?['payment_id']}',
                    style: const TextStyle(fontSize: 11),
                  ),
                  if (data['transaction']?['locker_id'] != null)
                    Text(
                      'Locker ID: ${data['transaction']?['locker_id']}',
                      style: const TextStyle(fontSize: 11),
                    ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD4AF37)),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String error) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.error, color: Colors.red, size: 32),
            ),
            const SizedBox(width: 12),
            const Text('Transaction Failed'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(error),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '🔄 ROLLBACK Executed',
                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
                  ),
                  const SizedBox(height: 8),
                  _buildTransactionStep('Payment NOT created', false),
                  _buildTransactionStep('Membership NOT activated', false),
                  _buildTransactionStep('Locker NOT assigned', false),
                  const SizedBox(height: 8),
                  const Text(
                    'All operations reversed - database unchanged',
                    style: TextStyle(fontSize: 11, fontStyle: FontStyle.italic),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionStep(String text, bool success) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(
            success ? Icons.check_circle : Icons.cancel,
            color: success ? Colors.green : Colors.red,
            size: 16,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Purchase Membership'),
        backgroundColor: Colors.grey.shade900,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFD4AF37)))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ACID Demo Notice
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.blue.shade900, Colors.blue.shade700],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.science, color: Colors.white),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Text(
                                'ACID Transaction Demonstration',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'This purchase uses atomic transactions - all steps succeed or all rollback',
                                style: TextStyle(fontSize: 11, color: Colors.white70),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Membership Tiers
                  const Text(
                    'Choose Your Plan',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  ..._tiers.map((tier) => _buildTierCard(tier)),
                  
                  const SizedBox(height: 24),
                  
                  // Payment Method
                  const Text(
                    'Payment Method',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  
                  const SizedBox(height: 12),
                  
                  _buildPaymentMethod('credit_card', 'Credit Card', Icons.credit_card),
                  _buildPaymentMethod('debit_card', 'Debit Card', Icons.payment),
                  _buildPaymentMethod('cash', 'Cash', Icons.money),
                  _buildPaymentMethod('online', 'Online', Icons.account_balance),
                  
                  const SizedBox(height: 32),
                  
                  // Purchase Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isPurchasing ? null : _purchaseMembership,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFD4AF37),
                        foregroundColor: Colors.black87,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isPurchasing
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation(Colors.black87),
                              ),
                            )
                          : const Text(
                              'Complete Purchase (ACID Transaction)',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildTierCard(Map<String, dynamic> tier) {
    final isSelected = _selectedTierId == tier['tier_id'];
    
    return GestureDetector(
      onTap: () => setState(() => _selectedTierId = tier['tier_id']),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey.shade900,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? const Color(0xFFD4AF37) : Colors.grey.shade800,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Radio<int>(
              value: tier['tier_id'],
              groupValue: _selectedTierId,
              onChanged: (value) => setState(() => _selectedTierId = value),
              activeColor: const Color(0xFFD4AF37),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tier['tier_name'] ?? '',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    tier['description'] ?? '',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade400,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      if (tier['access_sauna'] == true)
                        _buildFeatureBadge('Sauna'),
                      if (tier['access_pool'] == true)
                        _buildFeatureBadge('Pool'),
                      Text(
                        '${tier['max_classes_per_month']} classes/mo',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Text(
              '₨${tier['monthly_fee']?.toStringAsFixed(0)}',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFFD4AF37),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureBadge(String text) {
    return Container(
      margin: const EdgeInsets.only(right: 4),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFFD4AF37).withOpacity(0.2),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 9,
          color: Color(0xFFD4AF37),
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildPaymentMethod(String value, String label, IconData icon) {
    return RadioListTile<String>(
      value: value,
      groupValue: _paymentMethod,
      onChanged: (val) => setState(() => _paymentMethod = val!),
      activeColor: const Color(0xFFD4AF37),
      title: Row(
        children: [
          Icon(icon, color: Colors.grey.shade400, size: 20),
          const SizedBox(width: 12),
          Text(label, style: const TextStyle(color: Colors.white)),
        ],
      ),
    );
  }
}