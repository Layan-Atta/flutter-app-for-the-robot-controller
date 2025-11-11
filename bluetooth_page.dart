import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart'; // مكتبة البلوتوث
import 'dart:io' show Platform; // للتحقق من نظام التشغيل

class BluetoothPage extends StatefulWidget {
  const BluetoothPage({super.key});

  @override
  State<BluetoothPage> createState() => _BluetoothPageState();
}

class _BluetoothPageState extends State<BluetoothPage> {
  BluetoothDevice? _connectedDevice;
  BluetoothCharacteristic? _targetCharacteristic;
  StreamSubscription<List<ScanResult>>? _scanSubscription;
  List<ScanResult> _scanResults = [];

  double _motor1 = 90.0;
  double _motor2 = 90.0;
  double _motor3 = 90.0;
  double _motor4 = 90.0;

  @override
  void initState() {
    super.initState();
    _startScan();
  }

  @override
  void dispose() {
    _scanSubscription?.cancel();
    _connectedDevice?.disconnect();
    super.dispose();
  }

  // 1. بدء البحث عن الأجهزة
  Future<void> _startScan() async {
    // طلب الأذونات الضرورية
    if (Platform.isAndroid) {
      await FlutterBluePlus.turnOn(); // طلب تشغيل البلوتوث
    }

    _scanSubscription = FlutterBluePlus.scanResults.listen((results) {
      // تحديث قائمة الأجهزة المعثور عليها
      setState(() {
        _scanResults = results;
      });
    }, onError: (e) {
      _showError("Scan Error: $e");
    });

    // بدء البحث الفعلي
    await FlutterBluePlus.startScan(timeout: const Duration(seconds: 10));
  }

  // 2. الاتصال بجهاز محدد
  Future<void> _connectToDevice(BluetoothDevice device) async {
    await _scanSubscription?.cancel(); // إيقاف البحث
    try {
      await device.connect();
      setState(() {
        _connectedDevice = device;
      });
      _discoverServices(device);
    } catch (e) {
      _showError("Connection Failed: $e");
    }
  }

  // 3. اكتشاف الخدمات والخصائص
  Future<void> _discoverServices(BluetoothDevice device) async {
    try {
      List<BluetoothService> services = await device.discoverServices();
      for (var service in services) {
        // ابحث عن الخدمة والخاصية المحددة (يجب تغييرها لتطابق جهازك)
        // هذا مثال شائع (UART Service)
        for (var characteristic in service.characteristics) {
          if (characteristic.properties.write) {
            // وجدنا خاصية يمكن الكتابة عليها
            setState(() {
              _targetCharacteristic = characteristic;
            });
            _showSuccess("Connected! Ready to send data.");
            return; // توقف عند العثور على أول خاصية مناسبة
          }
        }
      }
      _showError("No writable characteristic found!");
    } catch (e) {
      _showError("Service Discovery Failed: $e");
    }
  }

  // 4. إرسال البيانات (الزوايا)
  Future<void> _sendData() async {
    if (_targetCharacteristic == null) {
      _showError("Not connected or no characteristic found.");
      return;
    }

    // تنسيق الرسالة كما في الصورة (Received command: s1:110,s2:71...)
    String command =
        "s1:${_motor1.round()},s2:${_motor2.round()},s3:${_motor3.round()},s4:${_motor4.round()}\n";

    try {
      // إرسال الأمر كـ bytes
      await _targetCharacteristic!.write(command.codeUnits);
      _showSuccess("Command Sent: $command");
    } catch (e) {
      _showError("Failed to send data: $e");
    }
  }

  void _resetSliders() {
    setState(() {
      _motor1 = 90.0;
      _motor2 = 90.0;
      _motor3 = 90.0;
      _motor4 = 90.0;
    });
  }

  // --- واجهات المستخدم ---
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_connectedDevice == null ? 'Find Devices' : 'Bluetooth Control'),
        actions: [
          if (_connectedDevice != null)
            IconButton(
              icon: const Icon(Icons.bluetooth_disabled),
              onPressed: () {
                _connectedDevice?.disconnect();
                setState(() {
                  _connectedDevice = null;
                  _targetCharacteristic = null;
                });
                _startScan(); // ابدأ البحث مجدداً
              },
            ),
        ],
      ),
      // تبديل الواجهة بناءً على حالة الاتصال
      body: _connectedDevice == null
          ? _buildScanResultList() // عرض قائمة الأجهزة
          : _buildControlPanel(), // عرض لوحة التحكم
    );
  }

  // واجهة قائمة الأجهزة
  Widget _buildScanResultList() {
    return Column(
      children: [
        ElevatedButton(
          onPressed: _startScan,
          child: const Text('Rescan'),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: _scanResults.length,
            itemBuilder: (context, index) {
              final result = _scanResults[index];
              return Card(
                child: ListTile(
                  title: Text(result.device.platformName.isEmpty
                      ? '(Unknown Device)'
                      : result.device.platformName),
                  subtitle: Text(result.device.remoteId.toString()),
                  trailing: const Icon(Icons.bluetooth),
                  onTap: () => _connectToDevice(result.device),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // واجهة لوحة التحكم (بعد الاتصال)
  Widget _buildControlPanel() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Text(
            'Connected to: ${_connectedDevice!.platformName}',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 20),
          // Sliders
          _buildMotorSlider('Motor 1', _motor1, (val) => setState(() => _motor1 = val)),
          _buildMotorSlider('Motor 2', _motor2, (val) => setState(() => _motor2 = val)),
          _buildMotorSlider('Motor 3', _motor3, (val) => setState(() => _motor3 = val)),
          _buildMotorSlider('Motor 4', _motor4, (val) => setState(() => _motor4 = val)),
          const SizedBox(height: 30),
          // Buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton(onPressed: _resetSliders, child: const Text('Reset')),
              ElevatedButton(
                onPressed: _sendData,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                child: const Text('Run'),
              ),
            ],
          )
        ],
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

  // دوال مساعدة لإظهار الرسائل
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
}