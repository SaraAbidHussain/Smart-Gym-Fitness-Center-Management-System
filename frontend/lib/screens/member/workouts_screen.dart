import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../config/api_config.dart';

class WorkoutsScreen extends StatefulWidget {
  const WorkoutsScreen({super.key});

  @override
  State<WorkoutsScreen> createState() => _WorkoutsScreenState();
}

class _WorkoutsScreenState extends State<WorkoutsScreen> {
  final _api = ApiService();
  final _formKey = GlobalKey<FormState>();
  final _exerciseController = TextEditingController();
  final _setsController = TextEditingController();
  final _repsController = TextEditingController();
  final _weightController = TextEditingController();
  final _caloriesController = TextEditingController();
  
  List<dynamic> _workouts = [];
  bool _isLoading = true;
  bool _isSubmitting = false;
  String _selectedDifficulty = 'moderate';

  @override
  void initState() {
    super.initState();
    _loadWorkouts();
  }

  @override
  void dispose() {
    _exerciseController.dispose();
    _setsController.dispose();
    _repsController.dispose();
    _weightController.dispose();
    _caloriesController.dispose();
    super.dispose();
  }

  Future<void> _loadWorkouts() async {
    setState(() => _isLoading = true);
    
    final response = await _api.get(
      ApiConfig.memberWorkouts,
      queryParams: {'limit': '20'},
    );
    
    if (response.success) {
      setState(() {
        _workouts = response.data['workouts'] ?? [];
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _logWorkout() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    final response = await _api.post(
      ApiConfig.memberWorkouts,
      body: {
        'exercise_name': _exerciseController.text.trim(),
        'sets': int.tryParse(_setsController.text),
        'reps': int.tryParse(_repsController.text),
        'weight_kg': double.tryParse(_weightController.text),
        'calories_burned': int.tryParse(_caloriesController.text),
        'difficulty': _selectedDifficulty,
      },
    );

    setState(() => _isSubmitting = false);

    if (!mounted) return;

    if (response.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Workout logged successfully!'),
          backgroundColor: Colors.green,
        ),
      );
      
      // Clear form
      _formKey.currentState!.reset();
      _exerciseController.clear();
      _setsController.clear();
      _repsController.clear();
      _weightController.clear();
      _caloriesController.clear();
      
      Navigator.pop(context);
      _loadWorkouts();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(response.error ?? 'Failed to log workout'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showLogWorkoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Log Workout'),
        content: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _exerciseController,
                  decoration: const InputDecoration(labelText: 'Exercise Name *'),
                  validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
                ),
                TextFormField(
                  controller: _setsController,
                  decoration: const InputDecoration(labelText: 'Sets'),
                  keyboardType: TextInputType.number,
                ),
                TextFormField(
                  controller: _repsController,
                  decoration: const InputDecoration(labelText: 'Reps'),
                  keyboardType: TextInputType.number,
                ),
                TextFormField(
                  controller: _weightController,
                  decoration: const InputDecoration(labelText: 'Weight (kg)'),
                  keyboardType: TextInputType.number,
                ),
                TextFormField(
                  controller: _caloriesController,
                  decoration: const InputDecoration(labelText: 'Calories'),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: _selectedDifficulty,
                  items: const [
                    DropdownMenuItem(value: 'easy', child: Text('Easy')),
                    DropdownMenuItem(value: 'moderate', child: Text('Moderate')),
                    DropdownMenuItem(value: 'hard', child: Text('Hard')),
                  ],
                  onChanged: (v) => setState(() => _selectedDifficulty = v!),
                  decoration: const InputDecoration(labelText: 'Difficulty'),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: _isSubmitting ? null : _logWorkout,
            child: _isSubmitting
                ? const SizedBox(
                    height: 16,
                    width: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Log'),
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
        title: const Text('Workout Logs'),
        backgroundColor: Colors.grey.shade900,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFD4AF37)))
          : _workouts.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.fitness_center, size: 64, color: Colors.grey.shade700),
                      const SizedBox(height: 16),
                      Text('No workouts logged yet', style: TextStyle(color: Colors.grey.shade500)),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _showLogWorkoutDialog,
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD4AF37)),
                        child: const Text('Log Your First Workout'),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _workouts.length,
                  itemBuilder: (context, index) {
                    final workout = _workouts[index];
                    return _buildWorkoutCard(workout);
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showLogWorkoutDialog,
        backgroundColor: const Color(0xFFD4AF37),
        child: const Icon(Icons.add, color: Colors.black87),
      ),
    );
  }

  Widget _buildWorkoutCard(Map<String, dynamic> workout) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade900,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade800),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            workout['exercise_name'] ?? 'Exercise',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              if (workout['sets'] != null) ...[
                Text('${workout['sets']} sets', style: TextStyle(color: Colors.grey.shade400)),
                const Text(' • ', style: TextStyle(color: Colors.grey)),
              ],
              if (workout['reps'] != null) ...[
                Text('${workout['reps']} reps', style: TextStyle(color: Colors.grey.shade400)),
                const Text(' • ', style: TextStyle(color: Colors.grey)),
              ],
              if (workout['weight_kg'] != null)
                Text('${workout['weight_kg']} kg', style: TextStyle(color: Colors.grey.shade400)),
            ],
          ),
          if (workout['calories_burned'] != null) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.local_fire_department, size: 14, color: Colors.orange),
                const SizedBox(width: 4),
                Text('${workout['calories_burned']} cal', style: TextStyle(color: Colors.grey.shade400, fontSize: 12)),
              ],
            ),
          ],
        ],
      ),
    );
  }
}