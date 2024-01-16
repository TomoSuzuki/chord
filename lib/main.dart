import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_midi_command/flutter_midi_command.dart';
import 'controller.dart';
import 'dart:developer' as dev;
import 'package:flutter/services.dart';

//void main() => runApp(const MyApp());
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    // 横向き
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight
  ]).then((_) {
    runApp(const MyApp());
  });
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  MyAppState createState() => MyAppState();
}

class MyAppState extends State<MyApp> {
  StreamSubscription<String>? _setupSubscription;
  final MidiCommand _midiCommand = MidiCommand();

  @override
  void initState() {
    super.initState();

    _setupSubscription = _midiCommand.onMidiSetupChanged?.listen((data) async {
      if (kDebugMode) {
        print("setup changed $data");
      }

      setState(() {});
    });
  }

  @override
  void dispose() {
    _setupSubscription?.cancel();
    super.dispose();
  }

  IconData _deviceIconForType(String type) {
    switch (type) {
      case "native":
        return Icons.devices;
      default:
        return Icons.device_unknown;
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('FlutterMidiCommand Example'),
        ),
        body: Center(
          child: FutureBuilder(
            future: _midiCommand.devices,
            builder: (BuildContext context, AsyncSnapshot snapshot) {
              if (snapshot.hasData && snapshot.data != null) {
                var devices = snapshot.data as List<MidiDevice>;
                //if (kDebugMode) {
                //  print(devices);
                //}
                return ListView.builder(
                  itemCount: devices.length,
                  itemBuilder: (context, index) {
                    MidiDevice device = devices[index];
                    dev.log(device.name);
                    return ListTile(
                      title: Text(
                        device.name,
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      subtitle: Text(
                          "ins:${device.inputPorts.length} outs:${device.outputPorts.length}, ${device.id}, ${device.type}"),
                      leading: Icon(device.connected
                          ? Icons.radio_button_on
                          : Icons.radio_button_off),
                      trailing: Icon(_deviceIconForType(device.type)),
                      onLongPress: () {
                        _midiCommand.stopScanningForBluetoothDevices();
                        Navigator.of(context)
                            .push(MaterialPageRoute<void>(
                          builder: (_) => ControllerPage(device),
                        ))
                            .then((value) {
                          setState(() {});
                        });
                      },
                      onTap: () {
                        if (device.connected) {
                          if (kDebugMode) {
                            print("disconnect");
                          }
                          _midiCommand.disconnectDevice(device);
                        } else {
                          if (kDebugMode) {
                            print("connect");
                          }
                          _midiCommand.connectToDevice(device).then((_) {
                            if (kDebugMode) {
                              print("device connected async");
                            }
                          });
                        }
                      },
                    );
                  },
                );
              } else {
                return const CircularProgressIndicator();
              }
            },
          ),
        ),
      ),
    );
  }
}
