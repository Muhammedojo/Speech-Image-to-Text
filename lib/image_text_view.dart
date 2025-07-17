import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';

class ImageToTextScreen extends StatefulWidget {
  const ImageToTextScreen({super.key});

  @override
  ImageToTextScreenState createState() => ImageToTextScreenState();
}

class ImageToTextScreenState extends State<ImageToTextScreen> {
  File? _selectedImage;
  String _extractedText = '';
  bool _isProcessing = false;
  final ImagePicker _picker = ImagePicker();
  late TextRecognizer _textRecognizer;

  @override
  void initState() {
    super.initState();
    // Initialize the text recognizer
    _textRecognizer = TextRecognizer();
  }

  @override
  void dispose() {
    // Clean up the recognizer when done
    _textRecognizer.close();
    super.dispose();
  }

  Future<void> _pickImageFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
          _extractedText = '';
        });
        await _extractTextFromImage();
      }
    } catch (e) {
      _showErrorDialog('Error picking image: $e');
    }
  }

  Future<void> _pickImageFromCamera() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
          _extractedText = '';
        });
        await _extractTextFromImage();
      }
    } catch (e) {
      _showErrorDialog('Error taking picture: $e');
    }
  }

  Future<void> _extractTextFromImage() async {
    if (_selectedImage == null) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      final inputImage = InputImage.fromFilePath(_selectedImage!.path);
      final RecognizedText recognizedText = await _textRecognizer.processImage(
        inputImage,
      );

      setState(() {
        _extractedText = recognizedText.text.isEmpty
            ? 'No text found in the image'
            : recognizedText.text;
        _isProcessing = false;
      });
    } catch (e) {
      setState(() {
        _isProcessing = false;
      });
      _showErrorDialog('Error extracting text: $e');
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  void _copyTextToClipboard() {
    if (_extractedText.isNotEmpty) {

       Clipboard.setData(ClipboardData(text: _extractedText));
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Text copied to clipboard')));
    }
  }

  void _clearAll() {
    setState(() {
      _selectedImage = null;
      _extractedText = '';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Image to Text'),
        
        actions: [
          if (_selectedImage != null)
            IconButton(
              icon: Icon(Icons.clear),
              onPressed: _clearAll,
              tooltip: 'Clear',
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Image selection buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _pickImageFromGallery,
                    icon: Icon(Icons.photo_library),
                    label: Text('Gallery'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _pickImageFromCamera,
                    icon: Icon(Icons.camera_alt),
                    label: Text('Camera'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),

            SizedBox(height: 20),

            // Selected image display
            if (_selectedImage != null)
              Container(
                height: 300,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.file(_selectedImage!, fit: BoxFit.contain),
                ),
              ),

            if (_selectedImage != null) SizedBox(height: 20),

            // Processing indicator
            if (_isProcessing)
              Center(
                child: Column(
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Extracting text...'),
                  ],
                ),
              ),

            // Extracted text display
            if (_extractedText.isNotEmpty && !_isProcessing)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Extracted Text:',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.copy),
                        onPressed: _copyTextToClipboard,
                        tooltip: 'Copy text',
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: SelectableText(
                      _extractedText,
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                ],
              ),

            // Instructions
            if (_selectedImage == null)
              Container(
                padding: EdgeInsets.all(20),
                margin: EdgeInsets.only(top: 20),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Column(
                  children: [
                    Icon(Icons.info_outline, size: 48, color: Colors.blue),
                    SizedBox(height: 16),
                    Text(
                      'Select an image to extract text',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue[800],
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Choose an image from your gallery or take a new photo. The app will automatically detect and extract any text found in the image.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 14, color: Colors.blue[600]),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
