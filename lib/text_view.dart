import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

class SpeechToTextScreen extends StatefulWidget {
  const SpeechToTextScreen({super.key});

  @override
  SpeechToTextScreenState createState() => SpeechToTextScreenState();
}

class SpeechToTextScreenState extends State<SpeechToTextScreen> {
  stt.SpeechToText _speech = stt.SpeechToText();
  bool _isListening = false;
  String _text = 'Press the button to start speaking';

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
  }

  Future<bool> _checkPermissions() async {
    var status = await Permission.microphone.request();
    return status.isGranted;
  }

  void _listen() async {
    if (!_isListening) {
      bool hasPermission = await _checkPermissions();
      if (!hasPermission) {
        setState(() => _text = "Microphone permission denied");
        return;
      }
      bool available = await _speech.initialize(
        onStatus: (status) {
          setState(() {
            if (status == 'done' || status == 'notListening') {
              _isListening = false;
            }
          });
        },
        onError: (error) {
          setState(() {
            _isListening = false;
            _text = "Error: ${error.errorMsg}";
          });
        },
      );
      if (available) {
        setState(() => _isListening = true);
        _speech
            .listen(
              onResult: (result) => setState(() {
                _text = result.recognizedWords;
              }),
              listenFor: Duration(seconds: 30),
              pauseFor: Duration(seconds: 5),
              localeId: "en_US",
            )
            .catchError((e) {
              setState(() {
                _isListening = false;
                _text = "Error: $e";
              });
            });
      }
    } else {
      setState(() => _isListening = false);
      _speech.stop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Speech to Text')),
      body: Center(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.record_voice_over_rounded, size: 40),

            const SizedBox(height: 20),
            Text(_text),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _listen,
        child: Icon(_isListening ? Icons.mic : Icons.mic_none),
      ),
    );
  }
}
