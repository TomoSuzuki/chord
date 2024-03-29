import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_midi_command/flutter_midi_command.dart';
import 'package:flutter_midi_command/flutter_midi_command_messages.dart';
import 'package:flutter_virtual_piano/flutter_virtual_piano.dart';

class ControllerPage extends StatelessWidget {
  final MidiDevice device;

  const ControllerPage(this.device, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chord Trainer'),
      ),
      body: MidiControls(device),
    );
  }
}

class MidiControls extends StatefulWidget {
  final MidiDevice device;

  const MidiControls(this.device, {Key? key}) : super(key: key);

  @override
  MidiControlsState createState() {
    return MidiControlsState();
  }
}

class MidiControlsState extends State<MidiControls> {
  StreamSubscription<MidiPacket>? _rxSubscription;
  final MidiCommand _midiCommand = MidiCommand();

  @override
  void initState() {
    if (kDebugMode) {
      print('init controller');
    }

    //

    _rxSubscription = _midiCommand.onMidiDataReceived?.listen((packet) {
      if (kDebugMode) {
        print('received packet $packet');
      }
      var data = packet.data;
      var timestamp = packet.timestamp;
      var device = packet.device;
      if (kDebugMode) {
        print(
            "data $data @ time $timestamp from device ${device.name}:${device.id}");
      }

      var status = data[0];

      if (status == 0xF8) {
        // Beat
        return;
      }

      if (status == 0xFE) {
        // Active sense;
        return;
      }
    });

    super.initState();
  }

  @override
  void dispose() {
    _rxSubscription?.cancel();
    super.dispose();
  }

  int _note = 0;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(12),
      children: <Widget>[
        SizedBox(
          height: 120,
          child: VirtualPiano(
            noteRange: const RangeValues(36, 76),
            onNotePressed: (note, vel) {
              NoteOnMessage(note: note, velocity: 100).send();
              if (kDebugMode) {
                print("note pressed $note ");
              }
              _setNote(note);
            },
            onNoteReleased: (note) {
              NoteOffMessage(note: note).send();
            },
          ),
        ),
        const SizedBox(height: 50),
        Center(
          child: SizedBox(
            height: 80,
            child: Text(
              '$_note',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ),
        ),
      ],
    );
  }

  void _setNote(int newValue) {
    setState(() {
      _note = newValue;
    });
  }
}
