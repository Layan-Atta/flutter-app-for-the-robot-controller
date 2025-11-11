import 'package:flutter/material.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Connection Type'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // زر الواي فاي
              ElevatedButton.icon(
                icon: const Icon(Icons.wifi),
                label: const Text('Wi-Fi (Database) Control'),
                style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                onPressed: () {
                  // هذا سينقلك إلى صفحة الواي فاي
                  Navigator.pushNamed(context, '/wifi');
                },
              ),
              const SizedBox(height: 20),

              // زر البلوتوث
              ElevatedButton.icon(
                icon: const Icon(Icons.bluetooth),
                label: const Text('Bluetooth Control'),
                style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                onPressed: () {
                  // هذا سينقلك إلى صفحة البلوتوث
                  Navigator.pushNamed(context, '/bluetooth');
                },
              ),
              const SizedBox(height: 20),

              // زر اليو اس بي
              ElevatedButton.icon(
                icon: const Icon(Icons.usb),
                label: const Text('USB Serial Control'),
                style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                onPressed: () {
                  // هذا سينقلك إلى صفحة السيريال
                  Navigator.pushNamed(context, '/serial');
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}