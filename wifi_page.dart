import 'package:flutter/material.dart';
import 'package:http/http.dart' as http; // لاستدعاء ملف الـ PHP
import 'dart:convert'; // لتحويل JSON

class WifiPage extends StatefulWidget {
  const WifiPage({super.key});

  @override
  State<WifiPage> createState() => _WifiPageState();
}

class _WifiPageState extends State<WifiPage> {
  // ❗️❗️ **تعديل مهم:** غيّر هذا الرابط إلى الرابط الصحيح لملف angles.php على السيرفر الخاص بك
  final String _phpUrl = "http://10.45.113.212/angles.php"; // مثال فقط

  double _motor1 = 90.0;
  double _motor2 = 90.0;
  double _motor3 = 90.0;
  double _motor4 = 90.0;

  // قائمة لتخزين الوضعيات المحفوظة من الداتابيس
  List<Map<String, dynamic>> _savedPoses = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    // جلب الوضعيات المحفوظة عند فتح الصفحة
    _fetchSavedPoses();
  }

  // --- دوال الاتصال بقاعدة البيانات ---

  // 1. جلب كل الوضعيات المحفوظة
  Future<void> _fetchSavedPoses() async {
    setState(() { _isLoading = true; });
    try {
      final response = await http.get(Uri.parse("$_phpUrl?action=fetch"));
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          _savedPoses = List<Map<String, dynamic>>.from(data);
          _isLoading = false;
        });
      } else {
        _showError('Failed to fetch poses. Server error.');
      }
    } catch (e) {
      _showError('Failed to connect to server: $e');
    }
    setState(() { _isLoading = false; });
  }

  // 2. حفظ الوضعية الحالية
  Future<void> _saveCurrentPose() async {
    try {
      final response = await http.post(
        Uri.parse("$_phpUrl?action=save"),
        body: {
          'motor1': _motor1.round().toString(),
          'motor2': _motor2.round().toString(),
          'motor3': _motor3.round().toString(),
          'motor4': _motor4.round().toString(),
        },
      );
      if (response.statusCode == 200) {
        _fetchSavedPoses(); // إعادة تحميل القائمة بعد الحفظ
        _showSuccess('Pose saved successfully!');
      } else {
        _showError('Failed to save pose.');
      }
    } catch (e) {
      _showError('Failed to connect to server: $e');
    }
  }

  // 3. تشغيل وضعية (إرسالها للـ ESP ليقرأها)
  // هذه الدالة ترسل الزوايا (سواء الحالية أو المحفوظة) إلى الداتابيس
  // الـ ESP يفترض أنه يقرأ من الداتابيس
  Future<void> _runPose(double m1, double m2, double m3, double m4) async {
    try {
      // "run" يرسل الزوايا إلى ملف الـ PHP
      // ملف الـ PHP سيقوم بتحديث جدول "current_pose"
      // الـ ESP سيقرأ من جدول "current_pose"
      final response = await http.post(
        Uri.parse("$_phpUrl?action=run"),
        body: {
          'motor1': m1.round().toString(),
          'motor2': m2.round().toString(),
          'motor3': m3.round().toString(),
          'motor4': m4.round().toString(),
        },
      );
      if (response.statusCode == 200) {
        _showSuccess('Running pose!');
      } else {
        _showError('Failed to run pose.');
      }
    } catch (e) {
      _showError('Failed to connect to server: $e');
    }
  }

  // 4. حذف وضعية
  Future<void> _deletePose(String id) async {
    try {
      final response = await http.get(Uri.parse("$_phpUrl?action=delete&id=$id"));
      if (response.statusCode == 200) {
        _fetchSavedPoses(); // إعادة تحميل القائمة بعد الحذف
        _showSuccess('Pose deleted.');
      } else {
        _showError('Failed to delete pose.');
      }
    } catch(e) {
      _showError('Failed to connect to server: $e');
    }
  }


  // --- دوال مساعدة ---

  void _resetSliders() {
    setState(() {
      _motor1 = 90.0;
      _motor2 = 90.0;
      _motor3 = 90.0;
      _motor4 = 90.0;
    });
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Wi-Fi Control Panel'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Sliders ---
            _buildMotorSlider('Motor 1', _motor1, (val) => setState(() => _motor1 = val)),
            _buildMotorSlider('Motor 2', _motor2, (val) => setState(() => _motor2 = val)),
            _buildMotorSlider('Motor 3', _motor3, (val) => setState(() => _motor3 = val)),
            _buildMotorSlider('Motor 4', _motor4, (val) => setState(() => _motor4 = val)),
            const SizedBox(height: 20),

            // --- Buttons (Reset, Save, Run) ---
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(onPressed: _resetSliders, child: const Text('Reset')),
                ElevatedButton(
                  onPressed: _saveCurrentPose, // حفظ في الداتابيس
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                  child: const Text('Save Pose'),
                ),
                ElevatedButton(
                  onPressed: () => _runPose(_motor1, _motor2, _motor3, _motor4), // تشغيل الزوايا الحالية
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                  child: const Text('Run'),
                ),
              ],
            ),
            const Divider(height: 40),

            // --- Saved Poses List ---
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Saved Poses:', style: Theme.of(context).textTheme.headlineSmall),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: _fetchSavedPoses, // زر تحديث القائمة
                ),
              ],
            ),
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _savedPoses.isEmpty
                    ? const Center(child: Text('No saved poses found.'))
                    : ListView.builder(
                        shrinkWrap: true, // مهم داخل SingleChildScrollView
                        physics: const NeverScrollableScrollPhysics(), // لمنع التداخل
                        itemCount: _savedPoses.length,
                        itemBuilder: (context, index) {
                          final pose = _savedPoses[index];
                          // جلب الزوايا
                          final m1 = double.parse(pose['motor1'].toString());
                          final m2 = double.parse(pose['motor2'].toString());
                          final m3 = double.parse(pose['motor3'].toString());
                          final m4 = double.parse(pose['motor4'].toString());

                          return Card(
                            elevation: 2,
                            child: ListTile(
                              title: Text('Pose ${index + 1}: ${m1.round()}, ${m2.round()}, ${m3.round()}, ${m4.round()}'),
                              // زر التشغيل (Run)
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.play_arrow, color: Colors.green),
                                    onPressed: () => _runPose(m1, m2, m3, m4),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete, color: Colors.red),
                                    onPressed: () => _deletePose(pose['id'].toString()),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ],
        ),
      ),
    );
  }

  // دالة مساعدة لبناء السلايدر
  Widget _buildMotorSlider(String label, double value, ValueChanged<double> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('$label: ${value.round()}°', style: const TextStyle(fontSize: 16)),
        Slider(
          value: value,
          min: 0,
          max: 180,
          divisions: 180,
          label: value.round().toString(),
          onChanged: onChanged,
        ),
      ],
    );
  }
}