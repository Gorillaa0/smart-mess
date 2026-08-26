import 'package:flutter/material.dart';

class ManagerWastageScreen extends StatefulWidget {
  const ManagerWastageScreen({super.key});

  @override
  State<ManagerWastageScreen> createState() => _ManagerWastageScreenState();
}

class _ManagerWastageScreenState extends State<ManagerWastageScreen> {
  final _prepController = TextEditingController(text: '168');
  final _actualController = TextEditingController(text: '161');
  final _wasteController = TextEditingController(text: '7');
  bool _isSaved = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAF8),
      appBar: AppBar(
        title: const Text('Record Meal Wastage', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF1B5E20),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.amber.shade200),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.amber, size: 22),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Entering wastage closes the meal audit loop and feeds data back into training the Random Forest AI model.',
                      style: TextStyle(fontSize: 12, color: Colors.black87),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            const Text('LUNCH AUDIT (25 AUG 2026)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey)),
            const SizedBox(height: 12),

            _buildInputField('Food Portions Prepared', _prepController, Icons.soup_kitchen),
            const SizedBox(height: 16),
            _buildInputField('Actual Students Consumed', _actualController, Icons.people),
            const SizedBox(height: 16),
            _buildInputField('Wasted Portions (Surplus / Waste)', _wasteController, Icons.delete_outline),
            const SizedBox(height: 24),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: const Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Predicted by Model:'),
                      Text('163 portions', style: TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                  SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Actual Consumed:'),
                      Text('161 portions', style: TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                  Divider(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Prediction Error:'),
                      Text('2 portions (98.8% Accuracy)', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1B5E20),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                icon: Icon(_isSaved ? Icons.check_circle : Icons.save),
                label: Text(_isSaved ? 'AUDIT SUBMITTED' : 'SUBMIT WASTAGE AUDIT', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                onPressed: () {
                  setState(() => _isSaved = true);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Wastage record committed to ML dataset & audit log!'),
                      backgroundColor: Color(0xFF2E7D32),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputField(String label, TextEditingController controller, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: const Color(0xFF1B5E20)),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade300)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade300)),
          ),
        ),
      ],
    );
  }
}
