import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

const supabaseUrl = "https://zpprbzujtziokfyyhlfa.supabase.co";
const supabaseKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InpwcHJienVqdHppb2tmeXlobGZhIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDA3ODAyNzgsImV4cCI6MjA1NjM1NjI3OH0.cVRK3Ffrkjk7M4peHsiPPpv_cmXwpX859Ii49hohSLk";
const supabaseTable = "documentos_procesados";

class MindeeScreen extends StatefulWidget {
  const MindeeScreen({super.key});

  @override
  State<MindeeScreen> createState() => _MindeeScreenState();
}

class _MindeeScreenState extends State<MindeeScreen> {
  Uint8List? _fileBytes;
  String? _fileName;
  String _responseText = "No se ha analizado ningún archivo aún.";
  bool _isLoading = false;
  Map<String, dynamic>? _jsonData;

  Future<void> pickAndSendFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      withData: true,
      type: FileType.custom,
      allowedExtensions: ['pdf', 'docx', 'jpg', 'jpeg', 'png'],
    );

    if (result != null && result.files.single.bytes != null) {
      final file = result.files.first;
      setState(() {
        _fileBytes = file.bytes;
        _fileName = file.name;
        _isLoading = true;
        _responseText = "Analizando archivo con Mindee...";
      });

      await sendToMindeeAsync(file.name, file.bytes!);
    }
  }

  Future<void> sendToMindeeAsync(String filename, Uint8List bytes) async {
    const apiKey = "e151df3d4c503c1b4680c9edacb68f65";
    final predictUri = Uri.parse("https://api.mindee.net/v1/products/lacastrilp/api_docs/v1/predict_async?webhook=true");

    final request = http.MultipartRequest("POST", predictUri)
      ..headers['Authorization'] = 'Token $apiKey'
      ..files.add(http.MultipartFile.fromBytes('document', bytes, filename: filename));

    try {
      final response = await request.send();

      if ([200, 201, 202].contains(response.statusCode)) {
        final responseData = await response.stream.bytesToString();
        final data = jsonDecode(responseData);
        final jobId = data['job']['id'];
        final availableAt = data['job']['available_at'];

        setState(() {
          _responseText = "📥 Archivo enviado exitosamente. El análisis será entregado vía webhook en aproximadamente: $availableAt";
          _isLoading = false;
        });
      } else {
        setState(() {
          _responseText = "Error al enviar archivo: ${response.statusCode}";
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _responseText = "Error de conexión: $e";
        _isLoading = false;
      });
    }
  }

  Future<void> fetchMindeeDocument(String documentId) async {
    const apiKey = "e151df3d4c503c1b4680c9edacb68f65";
    final docUri = Uri.parse("https://api.mindee.net/v1/products/lacastrilp/api_docs/v1/documents/$documentId");

    final response = await http.get(docUri, headers: {
      'Authorization': 'Token $apiKey',
    });

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      setState(() {
        _jsonData = data;
        _responseText = const JsonEncoder.withIndent('  ').convert(data);
        _isLoading = false;
      });
    } else {
      setState(() {
        _responseText = "Error al obtener documento: ${response.statusCode}";
        _isLoading = false;
      });
    }
  }

  Widget _buildStructuredView(Map<String, dynamic>? data) {
    if (data == null || data['document'] == null || data['document']['inference'] == null) {
      return const Center(child: Text("Sin datos para mostrar"));
    }

    final prediction = data['document']['inference']['prediction'];
    if (prediction == null || prediction is! Map) {
      return const Center(child: Text("Estructura de datos no reconocida"));
    }

    return ListView(
      children: prediction.entries.map<Widget>((entry) {
        final value = entry.value?['value'];
        return ListTile(
          title: Text(entry.key),
          subtitle: Text(value?.toString() ?? 'Sin valor'),
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF090467);
    const backgroundColor = Color(0xfff5f5fa);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: const Color(0xFFeff8ff),
        foregroundColor: primaryColor,
        elevation: 1,
        title: Text("Escaneo de Documento", style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Analizador de Archivos',
              style: GoogleFonts.poppins(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: primaryColor,
              ),
            ),
            const SizedBox(height: 20),
            if (_fileName != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Text(
                  'Archivo seleccionado: $_fileName',
                  style: GoogleFonts.poppins(fontSize: 14, color: Colors.black87),
                ),
              ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: pickAndSendFile,
              icon: const Icon(Icons.upload_file),
              label: const Text("Seleccionar y analizar archivo"),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                textStyle: GoogleFonts.poppins(fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 30),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(16),
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : DefaultTabController(
                  length: 2,
                  child: Column(
                    children: [
                      const TabBar(
                        labelColor: primaryColor,
                        tabs: [
                          Tab(text: "Vista organizada"),
                          Tab(text: "JSON crudo"),
                        ],
                      ),
                      Expanded(
                        child: TabBarView(
                          children: [
                            _buildStructuredView(_jsonData),
                            SingleChildScrollView(
                              padding: const EdgeInsets.all(8),
                              child: SelectableText(
                                _responseText,
                                style: const TextStyle(fontFamily: 'monospace'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
