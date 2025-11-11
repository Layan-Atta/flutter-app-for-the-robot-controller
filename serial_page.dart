import 'dart:async';
import 'dart:typed_data'; // للتعامل مع البيانات
import 'package:flutter/material.dart';
import 'package:flutter_libserialport/flutter_libserialport.dart'; // مكتبة السيريال

class SerialPage extends StatefulWidget {
  const SerialPage({super.key});

  @override
  State<SerialPage> createState() => _SerialPageState();
}

class _SerialPageState extends State<SerialPage> {
  List<String> _availablePorts = [];
  SerialPort? _selectedPort;
  
  // ❗️ هذا هو التصحيح: الاسم الصحيح هو SerialPortReader
  SerialPortReader? _reader; 
  
  List<String> _consoleOutput = []; // لتخزين مخرجات الكونسول

  double _motor1 = 90.0;
  double _motor2 = 90.0;
  double _motor3 = 90.0;
  double _motor4 = 90.0;

  @override
  void initState() {
    super.initState();
    _findPorts();
  }

  @override
  void dispose() {
    _reader?.close();
    _selectedPort?.close();
    _selectedPort?.dispose();
    super.dispose();
  }

  // 1. البحث عن المنافذ المتاحة
  void _findPorts() {
    setState(() {
      _availablePorts = SerialPort.availablePorts;
      _consoleOutput.add('Found ports: $_availablePorts');
    });
  }

  // 2. الاتصال بمنفذ محدد
  void _connectToPort(String portName) {
    try {
      // إغلاق أي اتصال قديم أولاً
      _reader?.close();
      _selectedPort?.close();

      // فتح المنفذ الجديد
      _selectedPort = SerialPort(portName);
      if (!_selectedPort!.openReadWrite()) {
        _showError('Failed to open port. Error: ${SerialPort.lastError}');
        _selectedPort = null;
        return;
      }

      // ❗️ هذا هو التصحيح الثاني: استخدام SerialPortReader
      _reader = SerialPortReader(_selectedPort!);
      _reader!.stream.listen((data) {
        // تم استلام بيانات من الأردوينو
        String receivedText = String.fromCharCodes(data);
        setState(() {
          _consoleOutput.add('Received: $receivedText');
        });
      }, onError: (e) {
        _showError("Stream Error: $e");
      });

      setState(() {
        _consoleOutput.add('✅ Connected to $portName');
      });
      _showSuccess('Connected to $portName');
    } catch (e) {
      _showError("Connection Failed: $e");
    }
  }

  // 3. إرسال البيانات (الزوايا)
  Future<void> _sendData() async {
    if (_selectedPort == null || !_selectedPort!.isOpen) {
      _showError("Not connected to any port.");
      return;
    }

    // نفس تنسيق الرسالة
    String command =
        "s1:${_motor1.round()},s2:${_motor2.round()},s3:${_motor3.round()},s4:${_motor4.round()}\n";

    try {
      // تحويل الرسالة إلى Uint8List لإرسالها
      Uint8List dataToSend = Uint8List.fromList(command.codeUnits);
      _selectedPort!.write(dataToSend);
      
      setState(() {
        _consoleOutput.add('Sent: $command');
      });
    } catch (e) {
      _showError("Failed to send data: $e");
      setState(() {
        _consoleOutput.add('Error sending: $e');
      });
    }
  }

  void _resetSliders() {
    setState(() {
      _motor1 = 90.0;
      _motor2 = 90.0;
      _motor3 = 90.0;
      _motor4 = 90.0;
    });
    _sendData(); // إرسال حالة الريست مباشرة
  }

  // --- واجهات المستخدم ---
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('USB Serial Control'),
      ),
      // تبديل الواجهة بناءً على حالة الاتصال
      body: _selectedPort == null
          ? _buildPortList() // عرض قائمة المنافذ
          : _buildControlPanel(), // عرض لوحة التحكم
    );
  }

  // واجهة قائمة المنافذ
  Widget _buildPortList() {
    return Column(
      children: [
        ElevatedButton(
          onPressed: _findPorts,
          child: const Text('Find Ports'),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: _availablePorts.length,
            itemBuilder: (context, index) {
              final portName = _availablePorts[index];
              return Card(
                child: ListTile(
                  title: Text(portName),
                  subtitle: Text('Serial/USB Device'),
                  trailing: const Icon(Icons.usb),
                  onTap: () => _connectToPort(portName),
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
    return Column(
      children: [
        // Sliders
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Text(
                'Connected to: ${_selectedPort!.name}',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              _buildMotorSlider('Motor 1', _motor1, (val) => setState(() => _motor1 = val)),
              _buildMotorSlider('Motor 2', _motor2, (val) => setState(() => _motor2 = val)),
              _buildMotorSlider('Motor 3', _motor3, (val) => setState(() => _motor3 = val)),
              _buildMotorSlider('Motor 4', _motor4, (val) => setState(() => _motor4 = val)),
              const SizedBox(height: 10),
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
        ),
        const Divider(),
        // Serial Console
        _buildSerialConsole(),
      ],
    );
  }

  // واجهة الكونسول
  Widget _buildSerialConsole() {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Serial Console:', style: Theme.of(context).textTheme.titleMedium),
                IconButton(
                  icon: const Icon(Icons.clear_all),
                  onPressed: () => setState(() => _consoleOutput.clear()),
                ),
              ],
            ),
            Expanded(
              child: Container(
                color: Colors.grey.shade200,
                child: ListView.builder(
                  itemCount: _consoleOutput.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 2.0),
                      child: Text(_consoleOutput[index]),
                    );
                  },
                ),
              ),
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