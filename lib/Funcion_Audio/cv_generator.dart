import 'dart:convert';
import 'dart:typed_data';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:html' as html;
import 'package:record/record.dart';
import 'package:audioplayers/audioplayers.dart';
import '../WidgetBarra.dart';
import 'monkey_pdf_integration.dart'; // Importar la integración con Monkey PDF
import 'package:google_fonts/google_fonts.dart';

// Acceder a la instancia de Supabase
final supabase = Supabase.instance.client;

// Modelo para las secciones de CV
class CVSection {
  final String id;
  final String title;
  final String description;
  final List<String> fields;
  String? audioUrl;
  String? transcription;
  bool isCompleted = false;

  CVSection({
    required this.id,
    required this.title,
    required this.description,
    required this.fields,
    this.audioUrl,
    this.transcription,
  });
}

// Datos para las secciones predefinidas del CV
final List<CVSection> cvSections = [
  CVSection(
    id: 'personal_info',
    title: 'Información Personal',
    description:
        'Cuéntanos sobre ti: nombre completo, dirección, teléfono, correo, nacionalidad, fecha de nacimiento, estado civil, redes sociales y portafolio.',
    fields: [
      'Nombre completo',
      'Dirección',
      'Teléfono',
      'Correo',
      'Nacionalidad',
      'Fecha de nacimiento',
      'Estado civil',
      'LinkedIn',
      'GitHub',
      'Portafolio',
    ],
  ),
  CVSection(
    id: 'professional_profile',
    title: 'Perfil Profesional',
    description:
        'Resume quién eres, qué haces y cuál es tu enfoque profesional. Esta es tu oportunidad para destacar.',
    fields: ['Resumen profesional'],
  ),
  CVSection(
    id: 'education',
    title: 'Educación',
    description:
        'Menciona tus estudios realizados, instituciones, fechas y títulos obtenidos, comenzando por los más recientes.',
    fields: ['Estudios', 'Instituciones', 'Fechas', 'Títulos'],
  ),
  CVSection(
    id: 'work_experience',
    title: 'Experiencia Laboral',
    description:
        'Detalla las empresas donde has trabajado, cargos, funciones, logros y duración, comenzando por la más reciente.',
    fields: ['Empresas', 'Cargos', 'Funciones', 'Logros', 'Duración'],
  ),
  CVSection(
    id: 'skills',
    title: 'Habilidades y Certificaciones',
    description:
        'Enumera tus habilidades técnicas, blandas y cualquier certificación relevante que hayas obtenido.',
    fields: ['Habilidades técnicas', 'Habilidades blandas', 'Certificaciones'],
  ),
  CVSection(
    id: 'languages',
    title: 'Idiomas y Otros Logros',
    description:
        'Menciona los idiomas que hablas, publicaciones, premios, voluntariados, experiencia internacional, permisos o licencias.',
    fields: [
      'Idiomas',
      'Publicaciones',
      'Premios',
      'Voluntariados',
      'Experiencia internacional',
      'Permisos/Licencias',
    ],
  ),
  CVSection(
    id: 'references',
    title: 'Referencias y Detalles Adicionales',
    description:
        'Incluye referencias laborales/personales, expectativas laborales, contacto de emergencia y disponibilidad para entrevistas.',
    fields: [
      'Referencias laborales',
      'Referencias personales',
      'Expectativas laborales',
      'Contacto de emergencia',
      'Disponibilidad',
    ],
  ),
];

class CVGenerator extends StatefulWidget {
  const CVGenerator({super.key});

  @override
  _CVGeneratorState createState() => _CVGeneratorState();
}

class _CVGeneratorState extends State<CVGenerator> {
  // Propiedades para manejo de audio
  Record _audioRecorder = Record();
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isRecording = false;
  bool _isPlaying = false;

  // Propiedades para manejo de datos del CV
  int _currentSectionIndex = 0;
  final Map<String, String> _transcriptions = {};
  final Map<String, String> _audioUrls = {};

  // Estado de procesamiento
  bool _isProcessing = false;
  bool _isComplete = false;
  String _processingStatus = '';

  // Controlador para PageView
  final PageController _pageController = PageController();

  // Variables para el formulario de edición
  Map<String, dynamic> _editableInfo = {};
  bool _isFormLoading = false;
  String _formError = '';
  String _recordId = '';

  // Intenta corregir el problema de JSArray vs String en Flutter web
  // Asegurarse de que todos los mapas se convierten a Map<String, String> forzosamente
  void _asegurarTiposDeDatos() {
    Map<String, dynamic> temp = {};

    try {
      // Verificar primero que _editableInfo no es nulo
      if (_editableInfo.isEmpty) {
        print("DEPURANDO: _editableInfo está vacío");
        return;
      }

      print(
        "DEPURANDO: Asegurando tipos de datos para: ${_editableInfo.keys.join(', ')}",
      );

      _editableInfo.forEach((key, value) {
        try {
          if (value == null) {
            temp[key] = "";
          } else if (value is List) {
            // Si es una lista, convertirla a String para la visualización
            temp[key] = value.join(", ");
          } else if (value is Map) {
            // Si es un mapa, convertirlo a String para la visualización
            temp[key] = json.encode(value);
          } else {
            temp[key] = value.toString();
          }
        } catch (e) {
          print("DEPURANDO: Error al procesar campo '$key': $e");
          temp[key] = "";
        }
      });

      // Reemplazar _editableInfo con la versión segura
      _editableInfo = Map<String, dynamic>.from(temp);
      print("DEPURANDO: Tipos de datos asegurados correctamente");
    } catch (e) {
      print("DEPURANDO: Error al asegurar tipos de datos: $e");
      // En caso de error, inicializar con un mapa vacío
      _editableInfo = {};
    }
  }

  // Función para solicitar permisos de audio
  Future<bool> _requestPermission() async {
    try {
      return await _audioRecorder.hasPermission();
    } catch (e) {
      print("Error al solicitar permisos: $e");
      return false;
    }
  }

  Future<void> _initializeAudioHandlers() async {
    try {
      await _audioRecorder.dispose();
      _audioRecorder = Record();

      bool hasPermission = await _audioRecorder.hasPermission();
      if (!hasPermission) {
        bool permissionGranted = await _requestPermission();
        if (!permissionGranted) {
          // Manejar la falta de permisos
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Se requieren permisos de micrófono para grabar audio',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
              ),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }
      }

      _audioPlayer.onPlayerComplete.listen((event) {
        setState(() {
          _isPlaying = false;
        });
      });

      print("Audio handlers inicializados correctamente");
    } catch (e) {
      print("Error al inicializar el grabador: $e");
    }
  }

  Future<void> _startRecording() async {
    try {
      if (_isRecording) {
        await _audioRecorder.stop();
      }

      // Reinicia el grabador
      await _initializeAudioHandlers();

      setState(() {
        _isRecording = true;
      });

      await _audioRecorder.start();
    } catch (e) {
      print("Error al iniciar grabación: $e");
      setState(() {
        _isRecording = false;
      });
    }
  }

  Future<void> _stopRecording() async {
    if (!_isRecording) return;

    try {
      final path = await _audioRecorder.stop();
      setState(() {
        _isRecording = false;
        // Guardar la URL del audio para la sección actual
        _audioUrls[cvSections[_currentSectionIndex].id] = path!;
      });
    } catch (e) {
      print("Error al detener grabación: $e");
      setState(() {
        _isRecording = false;
      });
    }
  }

  Future<void> _playRecording() async {
    if (_isPlaying) {
      await _audioPlayer.stop();
      setState(() {
        _isPlaying = false;
      });
      return;
    }

    final audioUrl = _audioUrls[cvSections[_currentSectionIndex].id];
    if (audioUrl != null) {
      try {
        await _audioPlayer.play(DeviceFileSource(audioUrl));
        setState(() {
          _isPlaying = true;
        });
      } catch (e) {
        print("Error al reproducir audio: $e");
      }
    }
  }

  void _nextSection() {
    if (_currentSectionIndex < cvSections.length - 1) {
      setState(() {
        _currentSectionIndex++;
      });
      _pageController.animateToPage(
        _currentSectionIndex,
        duration: Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      // Si estamos en la última sección, mostramos el diálogo de confirmación
      _showConfirmationDialog();
    }
  }

  // Mostrar diálogo de confirmación antes de procesar todos los audios
  void _showConfirmationDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: Text('Finalizar y procesar', style: GoogleFonts.poppins()),
          content: Text(
            '¿Has terminado de grabar todas las secciones? '
            'Al continuar, se procesarán todos los audios y se generará tu hoja de vida. '
            'Este proceso puede tardar varios minutos.',
            style: GoogleFonts.poppins(),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              style: TextButton.styleFrom(foregroundColor: Colors.grey[700]),
              child: Text(
                'Cancelar',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w800),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _processAllAudios();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xff9ee4b8),
                foregroundColor: Colors.white,
              ),
              child: Text(
                'Continuar',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w800),
              ),
            ),
          ],
        );
      },
    );
  }

  // Método para procesar todos los audios grabados
  Future<void> _processAllAudios() async {
    // Mostrar la pantalla de procesamiento
    setState(() {
      _isProcessing = true;
      _processingStatus = 'Preparando audios...';
    });

    try {
      // Paso 1: Preparar para procesar todos los audios
      final now = DateTime.now();
      final cvId = now.millisecondsSinceEpoch.toString();

      // Paso 2: Recopilar todos los audios grabados
      Map<String, String> sectionAudios = {};
      List<String> sectionIds = [];

      setState(() {
        _processingStatus = 'Preparando audios...';
      });

      // Contador para reportar progreso
      int totalSections = 0;
      int processedSections = 0;

      // Contar cuántas secciones tienen audio
      for (var section in cvSections) {
        if (_audioUrls.containsKey(section.id)) {
          totalSections++;
          sectionIds.add(section.id);
        }
      }

      if (totalSections == 0) {
        throw Exception("No se encontraron grabaciones de audio");
      }

      print("Se procesarán $totalSections secciones con grabaciones de audio");

      // Mapa para almacenar las transcripciones por sección
      Map<String, String> transcripcionesPorSeccion = {};
      Map<String, String> urlsPorSeccion = {};

      // Procesar cada sección con audio grabado
      for (var section in cvSections) {
        if (_audioUrls.containsKey(section.id)) {
          final audioPath = _audioUrls[section.id]!;

          setState(() {
            processedSections++;
            _processingStatus =
                'Procesando audio $processedSections/$totalSections: ${section.title}';
          });

          print("Procesando audio de la sección: ${section.title}");
          print("Ruta del audio: $audioPath");

          try {
            // Para Flutter web, necesitamos usar un FileReader para acceder al blob
            final completer = Completer<Uint8List>();
            final xhr = html.HttpRequest();
            xhr.open('GET', audioPath);
            xhr.responseType = 'blob';

            xhr.onLoad.listen((event) {
              if (xhr.status == 200) {
                final blob = xhr.response as html.Blob;
                final reader = html.FileReader();

                reader.onLoadEnd.listen((event) {
                  final Uint8List audioBytes = Uint8List.fromList(
                    reader.result is List<int>
                        ? (reader.result as List<int>)
                        : Uint8List.view(reader.result as ByteBuffer).toList(),
                  );
                  completer.complete(audioBytes);
                });

                reader.readAsArrayBuffer(blob);
              } else {
                completer.completeError(
                  'Error al obtener el audio: código ${xhr.status}',
                );
              }
            });

            xhr.onError.listen((event) {
              completer.completeError('Error de red al obtener el audio');
            });

            xhr.send();

            final Uint8List audioBytes = await completer.future;

            setState(() {
              _processingStatus =
                  'Subiendo a Supabase ($processedSections/$totalSections)...';
            });

            // Nombre único para este archivo de audio
            final fileName =
                'cv_${cvId}_${section.id}_${now.millisecondsSinceEpoch}.webm';

            print("Bytes de audio obtenidos: ${audioBytes.length} bytes");
            print("Subiendo audio a Supabase como: $fileName");

            // Subir a Supabase
            final response = await supabase.storage
                .from('Audios')
                .uploadBinary(
                  fileName,
                  audioBytes,
                  fileOptions: const FileOptions(contentType: 'audio/webm'),
                );

            print("Respuesta de Supabase al subir: $response");

            // Guardar la URL del audio
            final audioUrl = supabase.storage
                .from('Audios')
                .getPublicUrl(fileName);

            sectionAudios[section.id] = audioUrl;
            urlsPorSeccion[section.title] = audioUrl;

            print("URL pública del audio de ${section.title}: $audioUrl");

            // Transcribir usando AssemblyAI
            setState(() {
              _processingStatus =
                  'Transcribiendo ($processedSections/$totalSections): ${section.title}';
            });

            try {
              String transcripcion = await _transcribirAudio(audioUrl);
              transcripcionesPorSeccion[section.title] = transcripcion;
              print("Transcripción de ${section.title} completada");
            } catch (e) {
              print("Error transcribiendo audio de ${section.title}: $e");
              transcripcionesPorSeccion[section.title] =
                  "Error en la transcripción: $e";
              // Continuar con el proceso a pesar del error
            }
          } catch (e) {
            print("Error procesando audio de ${section.title}: $e");
            transcripcionesPorSeccion[section.title] =
                "Error en la transcripción: $e";
            // Continuar con el proceso a pesar del error
          }
        }
      }

      // Una vez procesados todos los audios individuales, guardar en la base de datos
      setState(() {
        _processingStatus = 'Guardando información en la base de datos...';
      });

      try {
        // Crear un texto combinado con todas las transcripciones organizadas por sección
        StringBuffer transcripcionCombinada = StringBuffer();

        for (var section in cvSections) {
          if (transcripcionesPorSeccion.containsKey(section.title)) {
            transcripcionCombinada.writeln(
              "### ${section.title.toUpperCase()} ###",
            );
            transcripcionCombinada.writeln(
              transcripcionesPorSeccion[section.title],
            );
            transcripcionCombinada.writeln("\n");
          }
        }

        // Analizar la transcripción usando OpenRouter.ai
        setState(() {
          _processingStatus = 'Analizando transcripción con IA...';
        });

        Map<String, dynamic> analyzedTranscription;
        try {
          analyzedTranscription = await _analizarTranscripcionConLLM(
            transcripcionCombinada.toString(),
          );
        } catch (e) {
          print("Error al analizar transcripción: $e");
          // Proporcionar un objeto JSON vacío con la estructura esperada en caso de error
          analyzedTranscription = {
            "nombres": "",
            "apellidos": "",
            // Incluir todos los demás campos necesarios con valores vacíos
            "correo": "",
            "telefono": "",
            "direccion": "",
            "perfil_profesional": "",
            "experiencia_laboral": "",
            "educacion": "",
            "habilidades": "",
            "idiomas": "",
          };
        }

        // Construir JSON con metadatos de las secciones incluidas
        Map<String, dynamic> seccionesInfo = {};
        for (var section in cvSections) {
          if (transcripcionesPorSeccion.containsKey(section.title)) {
            seccionesInfo[section.title] = {
              'id': section.id,
              'descripcion': section.description,
              'enlace_audio': urlsPorSeccion[section.title],
            };
          }
        }

        // Crear un solo registro con todas las transcripciones y metadatos
        final audioRecord = {
          'transcripcion': transcripcionCombinada.toString(),
          'enlace_audio': '', // No hay un solo enlace, están en el JSON
          'transcripcion_organizada_json':
              analyzedTranscription, // Datos estructurados por la IA
          'informacion_audios': jsonEncode({
            // Nueva columna para los metadatos originales
            'cv_id': cvId,
            'timestamp': now.toIso8601String(),
            'secciones': seccionesInfo,
          }),
        };

        print("Guardando registro combinado en la base de datos");

        // Guardar el registro combinado en la base de datos y obtener el ID
        final insertResponse = await supabase
            .from('audio_transcrito')
            .insert(audioRecord)
            .select('id');

        print("Información guardada correctamente en la base de datos");

        // Obtener el ID del registro recién creado
        if (insertResponse.isNotEmpty) {
          _recordId = insertResponse[0]['id'].toString();
          print("ID del registro: $_recordId");
        } else {
          print("No se pudo obtener el ID del registro");
        }

        // Cargar la información extraída por la IA para editar
        _editableInfo = Map<String, dynamic>.from(analyzedTranscription);
        _asegurarTiposDeDatos(); // Llamar al nuevo método para asegurar tipos

        // Proceso completado
        setState(() {
          _isProcessing = false;
          _isComplete = true;
        });
      } catch (e) {
        print("Error al guardar en la base de datos: $e");
        setState(() {
          _isProcessing = false;
          _processingStatus = 'Error: $e';
        });

        // Mostrar el error al usuario
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error al guardar en la base de datos: $e',
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      print("Error en el procesamiento: $e");
      setState(() {
        _isProcessing = false;
        _processingStatus = 'Error: $e';
      });

      // Mostrar el error al usuario
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Ocurrió un error durante el procesamiento: $e',
            style: GoogleFonts.poppins(),
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Método para transcribir audio usando AssemblyAI
  Future<String> _transcribirAudio(String audioUrl) async {
    print("Iniciando transcripción para URL: $audioUrl");
    String transcripcion = "";

    try {
      // Primero, enviamos la URL del audio a AssemblyAI
      var uploadRequest = http.Request(
        'POST',
        Uri.parse('https://api.assemblyai.com/v2/transcript'),
      );

      uploadRequest.headers.addAll({
        'authorization': '127d118f76c446a0ad8dce63a120336d',
        'content-type': 'application/json',
      });

      uploadRequest.body = json.encode({
        'audio_url': audioUrl,
        'language_code': 'es', // Español
      });

      // Enviamos la solicitud
      var uploadResponse = await http.Client().send(uploadRequest);
      var uploadResponseData = await http.Response.fromStream(uploadResponse);
      var responseJson = json.decode(uploadResponseData.body);

      print("Respuesta inicial de transcripción: $responseJson");

      if (uploadResponseData.statusCode == 200) {
        // Obtenemos el ID de la transcripción
        String transcriptId = responseJson['id'];
        String pollingEndpoint =
            'https://api.assemblyai.com/v2/transcript/$transcriptId';

        print("ID de transcripción: $transcriptId");

        // Consultamos hasta que la transcripción esté lista
        bool completed = false;
        int maxAttempts = 60; // 3 minutos máximo (60 intentos x 3 segundos)
        int attempts = 0;

        while (!completed && attempts < maxAttempts) {
          attempts++;
          try {
            var pollingResponse = await http.get(
              Uri.parse(pollingEndpoint),
              headers: {'authorization': '127d118f76c446a0ad8dce63a120336d'},
            );

            var pollingJson = json.decode(pollingResponse.body);
            print("Estado de transcripción: ${pollingJson['status']}");

            if (pollingJson['status'] == 'completed') {
              transcripcion = pollingJson['text'];
              print("Transcripción obtenida: $transcripcion");
              completed = true;
              break;
            } else if (pollingJson['status'] == 'error') {
              throw Exception(
                'Error en la transcripción: ${pollingJson['error']}',
              );
            } else if (pollingJson['status'] == 'processing' ||
                pollingJson['status'] == 'queued') {
              // Seguimos esperando
              await Future.delayed(Duration(seconds: 3));
              print("Intento $attempts: Esperando transcripción...");
            } else {
              print("Estado desconocido: ${pollingJson['status']}");
              await Future.delayed(Duration(seconds: 3));
            }
          } catch (e) {
            print("Error al consultar estado de transcripción: $e");
            await Future.delayed(Duration(seconds: 3));
          }
        }

        if (!completed) {
          throw Exception(
            'Tiempo de espera agotado. La transcripción está tomando demasiado tiempo.',
          );
        }
      } else {
        throw Exception(
          'Error al iniciar la transcripción: ${uploadResponseData.statusCode} - ${responseJson['error']}',
        );
      }
    } catch (e) {
      print("Error en la transcripción: $e");
      transcripcion = "Error en la transcripción: $e";
    }

    return transcripcion;
  }

  Future<Map<String, dynamic>> _analizarTranscripcionConLLM(
    String transcripcion,
  ) async {
    print("Iniciando análisis de transcripción con LLM...");

    // Crear un mapa vacío con todos los campos requeridos como respaldo
    final Map<String, dynamic> defaultJson = {
      "nombres": "",
      "apellidos": "",
      "fotografia": "",
      "direccion": "",
      "telefono": "",
      "correo": "",
      "nacionalidad": "",
      "fecha_nacimiento": "",
      "estado_civil": "",
      "linkedin": "",
      "github": "",
      "portafolio": "",
      "perfil_profesional": "",
      "objetivos_profesionales": "",
      "experiencia_laboral": "",
      "educacion": "",
      "habilidades": "",
      "idiomas": "",
      "certificaciones": "",
      "proyectos": "",
      "publicaciones": "",
      "premios": "",
      "voluntariados": "",
      "referencias": "",
      "expectativas_laborales": "",
      "experiencia_internacional": "",
      "permisos_documentacion": "",
      "vehiculo_licencias": "",
      "contacto_emergencia": "",
      "disponibilidad_entrevistas": "",
    };

    // Si la transcripción está vacía o es un error, usar fallback
    if (transcripcion.isEmpty ||
        transcripcion.toLowerCase().contains('error')) {
      print("Transcripción vacía o con error, usando fallback");
      return _useFallbackExtraction(transcripcion, defaultJson);
    }

    // Intentar con OpenRouter LLM
    try {
      print("Llamando a OpenRouter para organización inteligente...");

      final openRouterApiKey =
          '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';
      final openRouterUrl = Uri.parse(
        'https://openrouter.ai/api/v1/chat/completions',
      );

      final prompt =
          '''Analiza esta transcripción de CV y extrae datos específicos para cada campo:

TRANSCRIPCIÓN:
"$transcripcion"

Responde SOLO con JSON válido usando EXACTAMENTE estos campos:
{
  "nombres": "solo nombres aquí",
  "apellidos": "solo apellidos aquí", 
  "direccion": "solo dirección aquí",
  "telefono": "solo teléfono aquí",
  "correo": "solo email aquí",
  "nacionalidad": "solo nacionalidad aquí",
  "fecha_nacimiento": "solo fecha aquí",
  "estado_civil": "solo estado civil aquí",
  "linkedin": "solo linkedin aquí",
  "github": "solo github aquí",
  "portafolio": "solo portafolio aquí",
  "perfil_profesional": "solo resumen profesional aquí",
  "objetivos_profesionales": "solo objetivos aquí",
  "experiencia_laboral": "solo experiencia laboral aquí",
  "educacion": "solo educación aquí",
  "habilidades": "solo habilidades aquí",
  "idiomas": "solo idiomas aquí",
  "certificaciones": "solo certificaciones aquí",
  "proyectos": "solo proyectos aquí",
  "publicaciones": "solo publicaciones aquí",
  "premios": "solo premios aquí",
  "voluntariados": "solo voluntariados aquí",
  "referencias": "solo referencias aquí",
  "expectativas_laborales": "solo expectativas aquí",
  "experiencia_internacional": "solo experiencia internacional aquí",
  "permisos_documentacion": "solo permisos aquí",
  "vehiculo_licencias": "solo licencias aquí",
  "contacto_emergencia": "solo contacto emergencia aquí",
  "disponibilidad_entrevistas": "solo disponibilidad aquí"
}

IMPORTANTE:
- NO repitas toda la transcripción en cada campo
- Extrae solo la información específica para cada campo
- Si no hay información para un campo, usa ""
- Responde SOLO el JSON, nada más''';

      final response = await http.post(
        openRouterUrl,
        headers: {
          'Authorization': 'Bearer $openRouterApiKey',
          'Content-Type': 'application/json',
          'HTTP-Referer': 'https://cv-generator-app.com',
        },
        body: json.encode({
          'messages': [
            {'role': 'user', 'content': prompt},
          ],
          'model': 'meta-llama/llama-3.1-8b-instruct:free',
          'max_tokens': 1500,
          'temperature': 0.1,
          'top_p': 0.9,
        }),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final jsonResponse = json.decode(response.body);
        final content =
            jsonResponse['choices'][0]['message']['content'] as String;

        print("Respuesta del LLM recibida");

        // Múltiples estrategias de parsing
        Map<String, dynamic>? parsedData = _robustJSONParse(content);

        if (parsedData != null) {
          // Fusionar con defaultJson
          Map<String, dynamic> result = Map.from(defaultJson);
          parsedData.forEach((key, value) {
            if (result.containsKey(key)) {
              String cleanValue = (value?.toString() ?? '').trim();
              if (cleanValue.isNotEmpty) {
                result[key] = cleanValue;
              }
            }
          });

          print("✅ Datos organizados por LLM exitosamente");
          return result;
        }
      }
    } catch (e) {
      print("❌ Error con OpenRouter: $e");
    }

    // Fallback si el LLM falla
    print("🔄 Usando extracción fallback...");
    return _useFallbackExtraction(transcripcion, defaultJson);
  }

  // Función robusta para parsear JSON
  Map<String, dynamic>? _robustJSONParse(String content) {
    List<String> attempts = [
      content.trim(),
      content
          .replaceAll(RegExp(r'```json\s*'), '')
          .replaceAll(RegExp(r'```\s*'), '')
          .trim(),
      content.substring(content.indexOf('{')),
    ];

    // Agregar extracción por regex
    RegExp jsonRegex = RegExp(r'\{[^{}]*(?:\{[^{}]*\}[^{}]*)*\}');
    var match = jsonRegex.firstMatch(content);
    if (match != null) attempts.add(match.group(0) ?? '');

    for (String attempt in attempts) {
      try {
        if (attempt.isEmpty) continue;

        String cleaned = attempt
            .replaceAll(RegExp(r',\s*}'), '}')
            .replaceAll(RegExp(r',\s*]'), ']');

        var parsed = json.decode(cleaned);
        if (parsed is Map<String, dynamic>) {
          print("✅ JSON parseado exitosamente");
          return parsed;
        }
      } catch (e) {
        continue;
      }
    }

    print("❌ No se pudo parsear JSON");
    return null;
  }

  // Función de fallback mejorada
  Map<String, dynamic> _useFallbackExtraction(
    String transcripcion,
    Map<String, dynamic> defaultJson,
  ) {
    Map<String, dynamic> result = Map.from(defaultJson);

    if (transcripcion.isEmpty) return result;

    // Dividir por secciones si existen
    Map<String, String> secciones = {};

    if (transcripcion.contains('###')) {
      RegExp seccionRegex = RegExp(
        r'###\s*([^#]+?)\s*###\s*\n?(.*?)(?=###|\Z)',
        dotAll: true,
      );
      var matches = seccionRegex.allMatches(transcripcion);

      for (var match in matches) {
        String nombreSeccion = match.group(1)?.trim() ?? '';
        String contenidoSeccion = match.group(2)?.trim() ?? '';
        if (nombreSeccion.isNotEmpty) {
          secciones[nombreSeccion.toUpperCase()] = contenidoSeccion;
        }
      }
    } else {
      secciones['GENERAL'] = transcripcion;
    }

    // Extraer información específica
    String textoGeneral =
        secciones['INFORMACIÓN PERSONAL'] ??
        secciones['GENERAL'] ??
        transcripcion;

    // Nombres
    RegExp nombreRegex = RegExp(
      r'mi nombre(?:\s+completo)?[,:]?\s*([^.]+)',
      caseSensitive: false,
    );
    var nombreMatch = nombreRegex.firstMatch(textoGeneral);
    if (nombreMatch != null) {
      String nombreCompleto = nombreMatch.group(1)?.trim() ?? '';
      List<String> partes =
          nombreCompleto.split(' ').where((p) => p.isNotEmpty).toList();
      if (partes.length >= 2) {
        result['nombres'] = partes.take(2).join(' ');
        if (partes.length > 2) {
          result['apellidos'] = partes.skip(2).join(' ');
        }
      } else if (partes.length == 1) {
        result['nombres'] = partes[0];
      }
    }

    // Dirección
    RegExp direccionRegex = RegExp(
      r'mi dirección es\s*([^.]+)',
      caseSensitive: false,
    );
    var direccionMatch = direccionRegex.firstMatch(textoGeneral);
    if (direccionMatch != null) {
      result['direccion'] = direccionMatch.group(1)?.trim() ?? '';
    }

    // Teléfono
    RegExp telefonoRegex = RegExp(
      r'mi teléfono es\s*([\d\s\-\+\(\)]+)',
      caseSensitive: false,
    );
    var telefonoMatch = telefonoRegex.firstMatch(textoGeneral);
    if (telefonoMatch != null) {
      result['telefono'] =
          telefonoMatch.group(1)?.replaceAll(RegExp(r'[^\d\+]'), '') ?? '';
    }

    // Nacionalidad
    RegExp nacionalidadRegex = RegExp(
      r'(?:nacionalidad|binacionalidad)\s*([^.]+)',
      caseSensitive: false,
    );
    var nacionalidadMatch = nacionalidadRegex.firstMatch(textoGeneral);
    if (nacionalidadMatch != null) {
      result['nacionalidad'] = nacionalidadMatch.group(1)?.trim() ?? '';
    }

    // Secciones específicas
    secciones.forEach((seccion, contenido) {
      if (contenido.trim().isEmpty ||
          contenido.toLowerCase().contains('no tengo'))
        return;

      switch (seccion) {
        case 'EXPERIENCIA LABORAL':
          result['experiencia_laboral'] = contenido.trim();
          break;
        case 'EDUCACIÓN':
          if (!contenido.toLowerCase().contains('nula')) {
            result['educacion'] = contenido.trim();
          }
          break;
        case 'HABILIDADES Y CERTIFICACIONES':
          result['habilidades'] = contenido.trim();
          break;
        case 'IDIOMAS Y OTROS LOGROS':
          result['idiomas'] = contenido.trim();
          break;
        case 'PERFIL PROFESIONAL':
          result['perfil_profesional'] = contenido.trim();
          break;
        case 'REFERENCIAS Y DETALLES ADICIONALES':
          result['referencias'] = contenido.trim();
          break;
      }
    });

    print("📋 Extracción fallback completada");
    return result;
  }

  // Método para validar información con la IA
  Future<bool> _validateInfoWithAI() async {
    try {
      // Actualizar la API key de OpenRouter
      final openRouterApiKey =
          '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';
      final openRouterUrl = Uri.parse(
        'https://openrouter.ai/api/v1/chat/completions',
      );

      // Construir el prompt para el LLM - hacerlo más específico para evitar respuestas inválidas
      final prompt = '''
Valida la siguiente información de un CV y devuelve un JSON con los errores encontrados.

INSTRUCCIONES IMPORTANTES:
1. DEBES devolver un objeto JSON válido con EXACTAMENTE la estructura que se indica abajo.
2. NO incluyas ningún texto adicional antes o después del JSON.
3. El campo "esValido" debe ser exactamente true o false (booleano).
4. El campo "errores" debe ser un array, incluso si está vacío.
5. IMPORTANTE: Los campos vacíos o faltantes son PERMITIDOS - solo valida el FORMATO de los campos que tienen contenido.
6. No reportes como error que falten campos o que estén vacíos.

Información a validar:
${json.encode(_editableInfo)}

Estructura EXACTA de respuesta requerida:
{
  "esValido": true,
  "errores": []
}

O si hay errores de formato:
{
  "esValido": false,
  "errores": [
    {
      "campo": "nombre del campo con error",
      "problema": "descripción del problema encontrado",
      "sugerencia": "sugerencia para corregir el problema (opcional)"
    }
  ]
}
''';

      // Añadir un manejo de errores más detallado y bypass de validación si hay problemas
      try {
        // Realizar la llamada a la API
        final response = await http.post(
          openRouterUrl,
          headers: {
            'Authorization': 'Bearer $openRouterApiKey',
            'Content-Type': 'application/json',
            'HTTP-Referer': 'https://cv-generator-app.com',
          },
          body: json.encode({
            'messages': [
              {'role': 'user', 'content': prompt},
            ],
            'model': 'meta-llama/llama-4-maverick:free',
            'max_tokens': 2000,
            'temperature': 0.1,
          }),
        );

        if (response.statusCode >= 200 && response.statusCode < 300) {
          // Procesamiento normal de la respuesta
          final jsonResponse = json.decode(response.body);

          // Extraer el contenido de la respuesta
          final content =
              jsonResponse['choices'][0]['message']['content'] as String;
          print("Contenido original LLM: $content");

          try {
            // Intento #1: Intentar parsear directamente (por si el LLM ya respondió correctamente)
            try {
              final validationResult = json.decode(content);
              print("Parseo directo exitoso: $validationResult");

              // Verificar que tiene la estructura esperada
              if (validationResult.containsKey('esValido')) {
                bool esValido = validationResult['esValido'] ?? false;
                List<dynamic> errores = validationResult['errores'] ?? [];

                // Procesar el resultado
                if (esValido && errores.isEmpty) {
                  setState(() {
                    _formError = '';
                  });
                  return true;
                } else {
                  _mostrarErroresValidacion(errores);
                  return false;
                }
              }
            } catch (e) {
              print("Parseo directo falló: $e");
              // Continuar con limpieza
            }

            // Intento #2: Eliminar posibles decoradores markdown y extraer JSON
            String cleanedContent =
                content.replaceAll('```json', '').replaceAll('```', '').trim();
            print("Contenido sin markdown: $cleanedContent");

            // Utilizar expresión regular para encontrar el objeto JSON
            RegExp jsonRegex = RegExp(r'(\{.*\})', dotAll: true);
            var match = jsonRegex.firstMatch(cleanedContent);

            if (match != null) {
              String jsonStr = match.group(1) ?? '';
              print("JSON extraído con regex: $jsonStr");

              try {
                final validationResult = json.decode(jsonStr);

                if (validationResult.containsKey('esValido')) {
                  bool esValido = validationResult['esValido'] ?? false;
                  List<dynamic> errores = validationResult['errores'] ?? [];

                  // Procesar el resultado
                  if (esValido && errores.isEmpty) {
                    setState(() {
                      _formError = '';
                    });
                    return true;
                  } else {
                    _mostrarErroresValidacion(errores);
                    return false;
                  }
                } else {
                  throw Exception(
                    "Estructura JSON incorrecta, falta campo 'esValido'",
                  );
                }
              } catch (e) {
                print("Parseo del JSON extraído falló: $e");
                // Continuar con solución de emergencia
              }
            }

            // Solución de emergencia: Crear un objeto de validación que permita continuar
            print("Usando solución de emergencia: asumir que es válido");
            setState(() {
              _formError =
                  'La IA no pudo validar el formato, pero se procederá a guardar.';
            });

            // Permitir guardar aunque haya habido un problema con la validación
            return true;
          } catch (e) {
            print("Error general en procesamiento: $e");
            setState(() {
              _formError =
                  'Error al analizar la respuesta. Se procederá a guardar sin validar.';
            });
            return true;
          }
        } else {
          print("Error HTTP: ${response.statusCode}, ${response.body}");

          // Si hay error de API, permitir guardar de todos modos
          setState(() {
            _formError =
                'Error en la validación con IA. Se procederá a guardar sin validar.';
          });

          // Permitir continuar sin validación cuando hay error de API
          return true;
        }
      } catch (e) {
        print("Error al conectar con OpenRouter: $e");

        // Si hay error de conexión, permitir guardar de todos modos
        setState(() {
          _formError =
              'Error en la conexión con IA. Se procederá a guardar sin validar.';
        });

        // Permitir continuar sin validación cuando hay error de conexión
        return true;
      }
    } catch (e) {
      print("Error general en _validateInfoWithAI: $e");
      setState(() {
        _formError =
            'Error al validar información: Se procederá a guardar sin validar.';
      });

      // Permitir guardar aunque haya error
      return true;
    }
  }

  // Método para mostrar errores de validación de forma legible
  void _mostrarErroresValidacion(List<dynamic> errores) {
    if (errores.isEmpty) return;

    try {
      String errorMessage = 'Se encontraron problemas en la información:\n\n';
      for (var error in errores) {
        if (error is Map) {
          String campo = error['campo']?.toString() ?? 'campo desconocido';
          String problema =
              error['problema']?.toString() ?? 'error no especificado';
          errorMessage += '- $campo: $problema\n';
        } else if (error is String) {
          errorMessage += '- $error\n';
        }
      }

      setState(() {
        _formError = errorMessage;
      });
    } catch (e) {
      print("Error al formatear mensaje de errores: $e");
      setState(() {
        _formError =
            'Hay errores en la información, pero no se pudieron mostrar correctamente.';
      });
    }
  }

  void _previousSection() {
    if (_currentSectionIndex > 0) {
      setState(() {
        _currentSectionIndex--;
      });
      _pageController.animateToPage(
        _currentSectionIndex,
        duration: Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _updateTranscription(String text) {
    setState(() {
      _transcriptions[cvSections[_currentSectionIndex].id] = text;
    });
  }

  @override
  void initState() {
    super.initState();
    _initializeAudioHandlers();
  }

  @override
  Widget build(BuildContext context) {
    // Si estamos procesando o ya completamos, mostrar pantalla correspondiente
    if (_isProcessing || _isComplete) {
      return _buildProcessingScreen();
    }

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: const CustomAppBar(title: 'Generador de Hojas de Vida'),
      body: Column(
        children: [
          // Indicador de progreso
          Container(
            padding: EdgeInsets.symmetric(vertical: 16, horizontal: 20),
            child: LinearProgressIndicator(
              value: (_currentSectionIndex + 1) / cvSections.length,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF090467)),
              minHeight: 10,
              borderRadius: BorderRadius.circular(10),
            ),
          ),

          // Contador de pasos
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Paso ${_currentSectionIndex + 1} de ${cvSections.length}',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[700],
                  ),
                ),
                Text(
                  cvSections[_currentSectionIndex].title,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF090467),
                  ),
                ),
              ],
            ),
          ),

          // Tarjetas de secciones
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              physics: NeverScrollableScrollPhysics(),
              itemCount: cvSections.length,
              onPageChanged: (index) {
                setState(() {
                  _currentSectionIndex = index;
                });
              },
              itemBuilder: (context, index) {
                final section = cvSections[index];

                return CVSectionCard(
                  section: section,
                  isRecording: _isRecording,
                  isPlaying: _isPlaying,
                  hasAudio: _audioUrls.containsKey(section.id),
                  transcription: _transcriptions[section.id] ?? '',
                  onStartRecording: _startRecording,
                  onStopRecording: _stopRecording,
                  onPlayRecording: _playRecording,
                  onUpdateTranscription: _updateTranscription,
                  onNext: _nextSection,
                  onPrevious: _previousSection,
                  isFirstSection: index == 0,
                  isLastSection: index == cvSections.length - 1,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProcessingScreen() {
    // Color verde de la aplicación
    final Color primaryGreen = Color(0xff9ee4b8);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: CustomAppBar(
        title: _isComplete ? 'Informacion Personal' : 'Procesando',
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_isProcessing)
                Column(
                  children: [
                    CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(primaryGreen),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      _processingStatus,
                      style: const TextStyle(fontSize: 16),
                      textAlign: TextAlign.center,
                    ),
                  ],
                )
              else if (_isComplete)
                Expanded(child: _buildInfoEditForm(primaryGreen))
              else
                Column(
                  children: [
                    const Icon(
                      Icons.error_outline,
                      color: Colors.red,
                      size: 60.0,
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Error: $_processingStatus',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        color: Colors.red,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoEditForm(Color primaryColor) {
    if (_editableInfo.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    // Convertir _editableInfo a un Map seguro para evitar problemas con JSArray
    Map<String, dynamic> safeInfo = {};
    try {
      // Intenta convertir cada valor a su tipo seguro para Dart
      _editableInfo.forEach((key, value) {
        safeInfo[key] = _fixUtf8Encoding(value?.toString() ?? '');
      });

      print("Información cargada en el formulario: $safeInfo");
    } catch (e) {
      print("Error al preparar datos para UI: $e");
      // Si hay error, usar un mapa vacío con los campos esperados
      safeInfo = {
        'nombres': '',
        'apellidos': '',
        'correo': '',
        'telefono': '',
        'direccion': '',
        'nacionalidad': '',
        'fecha_nacimiento': '',
        'estado_civil': '',
        'linkedin': '',
        'github': '',
        'portafolio': '',
        'perfil_profesional': '',
        'objetivos_profesionales': '',
        'experiencia_laboral': '',
        'educacion': '',
        'habilidades': '',
        'idiomas': '',
        'certificaciones': '',
      };
    }

    // Lista de campos a mostrar y sus etiquetas
    final fieldLabels = {
      'nombres': 'Nombres',
      'apellidos': 'Apellidos',
      'correo': 'Correo electrónico',
      'telefono': 'Teléfono',
      'direccion': 'Dirección',
      'nacionalidad': 'Nacionalidad',
      'fecha_nacimiento': 'Fecha de nacimiento',
      'estado_civil': 'Estado civil',
      'linkedin': 'LinkedIn',
      'github': 'GitHub',
      'portafolio': 'Portafolio',
      'perfil_profesional': 'Perfil profesional',
      'objetivos_profesionales': 'Objetivos profesionales',
      'experiencia_laboral': 'Experiencia laboral',
      'educacion': 'Educación',
      'habilidades': 'Habilidades',
      'idiomas': 'Idiomas',
      'certificaciones': 'Certificaciones',
    };

    return Column(
      children: [
        Expanded(
          child: ListView(
            children: [
              Text(
                'Revisa y edita la información extraída',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF090467),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              if (_formError.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(10),
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color:
                        _formError.contains('Validando')
                            ? Colors.blue.shade100
                            : Colors.red.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      if (_formError.contains('Validando'))
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.blue.shade700,
                              ),
                            ),
                          ),
                        ),
                      Text(
                        _formError,
                        style: GoogleFonts.poppins(
                          color:
                              _formError.contains('Validando')
                                  ? Color(0xFF090467)
                                  : Colors.red.shade800,
                        ),
                      ),
                    ],
                  ),
                ),
              ...fieldLabels.entries.map((entry) {
                final fieldName = entry.key;
                final fieldLabel = entry.value;
                final isLongText = [
                  'perfil_profesional',
                  'objetivos_profesionales',
                  'educacion',
                  'experiencia_laboral',
                  'habilidades',
                ].contains(fieldName);

                // Asegurarse de que el valor sea una cadena vacía si es nulo
                String fieldValue = safeInfo[fieldName]?.toString() ?? '';

                return Padding(
                  padding: const EdgeInsets.only(bottom: 15),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        fieldLabel,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: primaryColor,
                        ),
                      ),
                      const SizedBox(height: 5),
                      if (isLongText)
                        TextFormField(
                          initialValue: fieldValue,
                          maxLines: 4,
                          decoration: InputDecoration(
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: primaryColor),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(
                                color: primaryColor,
                                width: 2,
                              ),
                            ),
                            hintText: 'Ingrese $fieldLabel',
                            hintStyle: TextStyle(color: Colors.grey.shade400),
                          ),
                          textCapitalization: TextCapitalization.sentences,
                          keyboardType: TextInputType.multiline,
                          onChanged: (value) {
                            setState(() {
                              _editableInfo[fieldName] = value;
                            });
                          },
                        )
                      else
                        TextFormField(
                          initialValue: fieldValue,
                          decoration: InputDecoration(
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: primaryColor),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(
                                color: primaryColor,
                                width: 2,
                              ),
                            ),
                            hintText: 'Ingrese $fieldLabel',
                            hintStyle: GoogleFonts.poppins(
                              color: Colors.grey.shade400,
                            ),
                          ),
                          textCapitalization: TextCapitalization.sentences,
                          keyboardType: TextInputType.text,
                          onChanged: (value) {
                            setState(() {
                              _editableInfo[fieldName] = value;
                            });
                          },
                        ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 20.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: Colors.grey,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  'Cancelar',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF090467),
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: _isFormLoading ? null : _saveEditedInfo,
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: primaryColor,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child:
                    _isFormLoading
                        ? Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Color(0xFF090467),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              'Guardando...',
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF090467),
                              ),
                            ),
                          ],
                        )
                        : Text(
                          'Guardar información',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF090467),
                          ),
                        ),
              ),
              // Añadir botón para vista previa
              if (!_isFormLoading)
                ElevatedButton(
                  onPressed: () {
                    try {
                      print("Botón de Vista Previa pulsado");

                      // Verificar si tenemos datos para mostrar
                      if (_editableInfo.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'No hay información para mostrar. Guarde primero los datos.',
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF090467),
                              ),
                            ),
                            backgroundColor: Colors.orange,
                          ),
                        );
                        return;
                      }

                      // Mostrar mensaje de carga
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Generando vista previa...',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF090467),
                            ),
                          ),
                          backgroundColor: Colors.blue,
                          duration: Duration(seconds: 1),
                        ),
                      );

                      // Preparar datos asegurando que todos los valores sean seguros
                      Map<String, dynamic> safeInfo = {};

                      // Agregar todos los campos necesarios con valores por defecto
                      final requiredFields = [
                        'nombres',
                        'apellidos',
                        'correo',
                        'telefono',
                        'direccion',
                        'nacionalidad',
                        'profesion',
                      ];

                      // Inicializar campos requeridos con valores vacíos si no existen
                      for (var field in requiredFields) {
                        safeInfo[field] = '';
                      }

                      // Agregar datos del formulario, protegiendo contra nulos
                      _editableInfo.forEach((key, value) {
                        if (value != null) {
                          final String strValue = value.toString();
                          if (strValue.isNotEmpty) {
                            safeInfo[key] = strValue;
                          }
                        }
                      });

                      // Asegurar campos mínimos obligatorios
                      if (safeInfo['nombres']?.isEmpty ?? true) {
                        safeInfo['nombres'] = 'Nombre';
                      }
                      if (safeInfo['apellidos']?.isEmpty ?? true) {
                        safeInfo['apellidos'] = 'Apellido';
                      }
                      if (safeInfo['profesion']?.isEmpty ?? true) {
                        safeInfo['profesion'] = 'Profesional';
                      }

                      // Lanzar la generación de la vista previa
                      Future(() async {
                        try {
                          // Llamamos directamente al método de generación de vista previa
                          final result =
                              await MonkeyPDFIntegration.generatePDFFromCV(
                                safeInfo,
                              );
                          print("Vista previa generada correctamente: $result");
                        } catch (innerError) {
                          print(
                            "Error interno generando vista previa: $innerError",
                          );

                          if (!mounted) return;

                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Error: $innerError',
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              backgroundColor: Colors.red,
                              duration: Duration(seconds: 3),
                            ),
                          );
                        }
                      });
                    } catch (e) {
                      print("Error al generar vista previa: $e");

                      if (!mounted) return;

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Error: $e',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          backgroundColor: Colors.red,
                          duration: Duration(seconds: 3),
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: Color(0xff9ee4b8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    'Vista Previa',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF090467),
                    ),
                  ),
                ),
              // Añadir botón para generar PDF
              if (!_isFormLoading)
                GeneratePDFButton(
                  cvData: safeInfo,
                  onGenerating: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Generando PDF...',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF090467),
                          ),
                        ),
                        backgroundColor: Colors.blue,
                      ),
                    );
                  },
                  onGenerated: (String pdfUrl) {
                    print("PDF generado: $pdfUrl");
                    // Puedes abrir el PDF en una nueva pestaña si lo deseas
                    // html.window.open(pdfUrl, '_blank');
                  },
                  onError: (String error) {
                    print("Error al generar PDF: $error");
                  },
                ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _saveEditedInfo() async {
    setState(() {
      _isFormLoading = true;
      _formError = '';
    });

    try {
      if (_recordId.isEmpty) {
        throw Exception('No se encontró el ID del registro');
      }

      print("DEPURANDO: _editableInfo antes de validar: $_editableInfo");

      // Crear una copia antes de modificarla para la UI
      Map<String, dynamic> editableInfoParaGuardar = Map.from(_editableInfo);

      // Asegurar que _editableInfo es un mapa seguro para la UI
      _asegurarTiposDeDatos();

      print(
        "DEPURANDO: _editableInfo después de asegurar para UI: $_editableInfo",
      );

      // Primero validar la información con el LLM
      setState(() {
        _formError = 'Validando información...';
      });

      final bool isValid = await _validateInfoWithAI();

      if (!isValid) {
        // Si la validación falló, detener el proceso de guardado
        setState(() {
          _isFormLoading = false;
        });
        return;
      }

      // Usar la información tal como está, sin normalizar caracteres
      Map<String, dynamic> infoParaGuardar = {};
      editableInfoParaGuardar.forEach((key, value) {
        // Conservar el valor original sin normalizar
        infoParaGuardar[key] = value;
      });

      print("DEPURANDO: infoParaGuardar para guardar: $infoParaGuardar");

      // Asegurar que el JSON a guardar tenga los campos básicos
      // Solo inicializamos campos básicos si están completamente ausentes
      final camposBasicos = ['nombres', 'apellidos', 'correo', 'telefono'];

      // Solo asegurar campos básicos
      for (var campo in camposBasicos) {
        if (!infoParaGuardar.containsKey(campo)) {
          infoParaGuardar[campo] = "";
        }
      }

      // Convertir a formato Schema.org
      final schemaOrgData = _convertToSchemaOrgFormat(infoParaGuardar);
      print("DEPURANDO: Formato Schema.org: $schemaOrgData");

      // Actualizar el registro en la base de datos
      try {
        // Asegurar que el JSON se codifica correctamente con UTF-8
        final jsonString = json.encode(infoParaGuardar);
        final schemaJsonString = json.encode(schemaOrgData);

        // Verificar que no haya caracteres malformados
        print("DEPURANDO: Verificando JSON codificado: $jsonString");
        print(
          "DEPURANDO: Verificando JSON Schema codificado: $schemaJsonString",
        );

        await supabase
            .from('audio_transcrito')
            .update({
              'informacion_organizada_usuario': infoParaGuardar,
              'esquema_json': schemaOrgData,
            })
            .eq('id', _recordId);

        print("DEPURANDO: Actualización en base de datos completada");
      } catch (dbError) {
        print("DEPURANDO: Error en la base de datos: $dbError");
        rethrow;
      }

      setState(() {
        _isFormLoading = false;
      });

      // Mostrar mensaje de éxito
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Información guardada correctamente. Ahora puedes generar el PDF.',
          ),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 3),
        ),
      );

      // Ya no regresamos a la pantalla principal
      // Navigator.of(context).pop(); - Esta línea se ha eliminado
    } catch (e) {
      print("DEPURANDO: Error general en _saveEditedInfo: $e");
      setState(() {
        _isFormLoading = false;
        _formError = 'Error al guardar: $e';
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al guardar: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  void dispose() {
    _audioRecorder.dispose();
    _audioPlayer.dispose();
    _pageController.dispose();
    super.dispose();
  }

  // Método para corregir problemas de codificación UTF-8
  String _fixUtf8Encoding(String text) {
    if (text.isEmpty) return text;

    try {
      // Detectar caracteres mal codificados (típicamente aparecen como Ã seguido de otro carácter)
      if (text.contains('Ã')) {
        // Estrategia 1: Re-codificar a UTF-8
        List<int> bytes = utf8.encode(text);
        String decoded = utf8.decode(bytes, allowMalformed: true);

        // Si detectamos mejora (menos caracteres Ã), usamos esta versión
        if (decoded.contains('Ã') &&
            decoded.split('Ã').length < text.split('Ã').length) {
          return decoded;
        }

        // Estrategia 2: Reemplazos básicos para los caracteres más comunes
        String result = text;

        // Tabla de reemplazos
        result = result.replaceAll('Ã¡', 'á');
        result = result.replaceAll('Ã©', 'é');
        result = result.replaceAll('Ã­', 'í');
        result = result.replaceAll('Ã³', 'ó');
        result = result.replaceAll('Ãº', 'ú');
        result = result.replaceAll('Ã±', 'ñ');

        return result;
      }
    } catch (e) {
      print("Error al corregir codificación UTF-8: $e");
    }

    // Si no se pudo o no fue necesario corregir, devolver el texto original
    return text;
  }

  // Método para convertir los datos del formulario al formato Schema.org
  Map<String, dynamic> _convertToSchemaOrgFormat(
    Map<String, dynamic> formData,
  ) {
    // Crear estructura de Schema.org para un CV
    Map<String, dynamic> schemaData = {
      "@context": "https://schema.org",
      "@type": "Person",
      "name":
          "${formData['nombres'] ?? ''} ${formData['apellidos'] ?? ''}".trim(),
    };

    // Añadir información de contacto
    if ((formData['correo'] ?? '').isNotEmpty) {
      schemaData["email"] = formData['correo'];
    }

    if ((formData['telefono'] ?? '').isNotEmpty) {
      schemaData["telephone"] = formData['telefono'];
    }

    // Añadir dirección si está disponible
    if ((formData['direccion'] ?? '').isNotEmpty) {
      schemaData["address"] = {
        "@type": "PostalAddress",
        "streetAddress": formData['direccion'],
      };
    }

    // Añadir sitios web/redes sociales
    List<String> urls = [];
    if ((formData['linkedin'] ?? '').isNotEmpty) {
      urls.add(formData['linkedin']);
    }
    if ((formData['github'] ?? '').isNotEmpty) {
      urls.add(formData['github']);
    }
    if ((formData['portafolio'] ?? '').isNotEmpty) {
      urls.add(formData['portafolio']);
    }

    if (urls.isNotEmpty) {
      if (urls.length == 1) {
        schemaData["url"] = urls[0];
      } else {
        schemaData["sameAs"] = urls;
      }
    }

    // Añadir educación si está disponible
    if ((formData['educacion'] ?? '').isNotEmpty) {
      // Intentamos extraer información estructurada de texto libre
      final String educacionTexto = formData['educacion'];
      List<Map<String, dynamic>> educacionLista = [];

      // Método simple de extracción - esto podría refinarse
      final List<String> educacionItems =
          educacionTexto
              .split('\n')
              .where((line) => line.trim().isNotEmpty)
              .toList();

      if (educacionItems.isNotEmpty) {
        educacionLista =
            educacionItems
                .map(
                  (item) => {
                    "@type": "EducationalOrganization",
                    "name":
                        item, // Simplificado, idealmente separaríamos la institución del título
                  },
                )
                .toList();

        schemaData["alumniOf"] = educacionLista;
      }
    }

    // Añadir experiencia laboral
    if ((formData['experiencia_laboral'] ?? '').isNotEmpty) {
      final String experienciaTexto = formData['experiencia_laboral'];
      List<Map<String, dynamic>> experienciaLista = [];

      final List<String> experienciaItems =
          experienciaTexto
              .split('\n')
              .where((line) => line.trim().isNotEmpty)
              .toList();

      if (experienciaItems.isNotEmpty) {
        experienciaLista =
            experienciaItems
                .map(
                  (item) => {"@type": "OrganizationRole", "description": item},
                )
                .toList();

        schemaData["workExperience"] = experienciaLista;
      }
    }

    // Añadir habilidades
    if ((formData['habilidades'] ?? '').isNotEmpty) {
      schemaData["skills"] = formData['habilidades'];
    }

    // Añadir idiomas
    if ((formData['idiomas'] ?? '').isNotEmpty) {
      final String idiomasTexto = formData['idiomas'];
      List<Map<String, dynamic>> idiomasLista = [];

      final List<String> idiomaItems =
          idiomasTexto
              .split(',')
              .map((s) => s.trim())
              .where((s) => s.isNotEmpty)
              .toList();

      if (idiomaItems.isNotEmpty) {
        idiomasLista =
            idiomaItems
                .map((idioma) => {"@type": "Language", "name": idioma})
                .toList();

        schemaData["knowsLanguage"] = idiomasLista;
      }
    }

    // Añadir descripción/perfil profesional
    if ((formData['perfil_profesional'] ?? '').isNotEmpty) {
      schemaData["description"] = formData['perfil_profesional'];
    }

    return schemaData;
  }

  // Nueva función para extraer información de la transcripción usando lógica simple
  Map<String, dynamic> _extractInfoFromTranscription(String transcripcion) {
    Map<String, dynamic> result = {};
    String texto = transcripcion.toLowerCase();

    try {
      // Información personal
      if (texto.contains('mi nombre es') || texto.contains('me llamo')) {
        List<String> palabras = transcripcion.split(' ');
        for (int i = 0; i < palabras.length - 1; i++) {
          if (palabras[i].toLowerCase().contains('nombre') ||
              palabras[i].toLowerCase().contains('llamo')) {
            if (i + 1 < palabras.length) {
              result['nombres'] = palabras[i + 1]
                  .replaceAll(',', '')
                  .replaceAll('.', '');
            }
            if (i + 2 < palabras.length) {
              result['apellidos'] = palabras[i + 2]
                  .replaceAll(',', '')
                  .replaceAll('.', '');
            }
            break;
          }
        }
      }

      // Dirección
      if (texto.contains('vivo en') ||
          texto.contains('dirección') ||
          texto.contains('ubicado')) {
        result['direccion'] = _extractAfterKeywords(transcripcion, [
          'vivo en',
          'dirección',
          'ubicado en',
        ]);
      }

      // Teléfono
      if (texto.contains('teléfono') ||
          texto.contains('número') ||
          texto.contains('celular')) {
        String phone = _extractPhoneNumber(transcripcion);
        if (phone.isNotEmpty) result['telefono'] = phone;
      }

      // Email
      if (texto.contains('@') ||
          texto.contains('correo') ||
          texto.contains('email')) {
        String email = _extractEmail(transcripcion);
        if (email.isNotEmpty) result['correo'] = email;
      }

      // Nacionalidad
      if (texto.contains('nacionalidad') ||
          texto.contains('país') ||
          texto.contains('soy de')) {
        result['nacionalidad'] = _extractAfterKeywords(transcripcion, [
          'nacionalidad',
          'soy de',
          'país',
        ]);
      }

      // Estado civil
      if (texto.contains('soltero') ||
          texto.contains('casado') ||
          texto.contains('divorciado') ||
          texto.contains('viudo') ||
          texto.contains('estado civil')) {
        result['estado_civil'] = _extractMaritalStatus(texto);
      }

      // LinkedIn
      if (texto.contains('linkedin') || texto.contains('linked in')) {
        result['linkedin'] = _extractAfterKeywords(transcripcion, [
          'linkedin',
          'linked in',
        ]);
      }

      // GitHub
      if (texto.contains('github') || texto.contains('git hub')) {
        result['github'] = _extractAfterKeywords(transcripcion, [
          'github',
          'git hub',
        ]);
      }

      // Experiencia laboral
      if (texto.contains('trabajo') ||
          texto.contains('empresa') ||
          texto.contains('experiencia') ||
          texto.contains('laboré') ||
          texto.contains('trabajé')) {
        result['experiencia_laboral'] = transcripcion;
      }

      // Educación
      if (texto.contains('estudié') ||
          texto.contains('universidad') ||
          texto.contains('colegio') ||
          texto.contains('título') ||
          texto.contains('carrera') ||
          texto.contains('educación')) {
        result['educacion'] = transcripcion;
      }

      // Habilidades
      if (texto.contains('habilidad') ||
          texto.contains('capacidad') ||
          texto.contains('sé hacer') ||
          texto.contains('dominio') ||
          texto.contains('experto') ||
          texto.contains('certificación')) {
        result['habilidades'] = transcripcion;
        // También puede ser certificaciones
        if (texto.contains('certificación') || texto.contains('certificado')) {
          result['certificaciones'] = transcripcion;
        }
      }

      // Idiomas
      if (texto.contains('idioma') ||
          texto.contains('inglés') ||
          texto.contains('español') ||
          texto.contains('francés') ||
          texto.contains('alemán') ||
          texto.contains('hablo')) {
        result['idiomas'] = transcripcion;
      }

      // Referencias
      if (texto.contains('referencia') ||
          texto.contains('contacto') ||
          texto.contains('recomendación')) {
        result['referencias'] = transcripcion;
      }

      // Perfil profesional (si no encaja en otras categorías pero es descriptivo)
      if (result.isEmpty && transcripcion.length > 20) {
        result['perfil_profesional'] = transcripcion;
      }
    } catch (e) {
      print("Error en extracción de información: $e");
    }

    return result;
  }

  String _extractAfterKeywords(String text, List<String> keywords) {
    String loweredText = text.toLowerCase();
    for (String keyword in keywords) {
      int index = loweredText.indexOf(keyword.toLowerCase());
      if (index != -1) {
        String remaining = text.substring(index + keyword.length).trim();
        // Tomar hasta el próximo punto o coma, o máximo 100 caracteres
        List<String> parts = remaining.split(RegExp(r'[.,;]'));
        return parts.isNotEmpty
            ? parts[0].trim()
            : remaining.substring(
              0,
              remaining.length > 100 ? 100 : remaining.length,
            );
      }
    }
    return '';
  }

  String _extractPhoneNumber(String text) {
    // Buscar patrones de teléfono
    RegExp phoneRegex = RegExp(r'[\d\s\-\+\(\)]{8,15}');
    var match = phoneRegex.firstMatch(text);
    return match?.group(0)?.replaceAll(RegExp(r'[^\d\+]'), '') ?? '';
  }

  String _extractEmail(String text) {
    // Buscar patrones de email
    RegExp emailRegex = RegExp(
      r'\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}\b',
    );
    var match = emailRegex.firstMatch(text);
    return match?.group(0) ?? '';
  }

  String _extractMaritalStatus(String text) {
    if (text.contains('soltero')) return 'Soltero';
    if (text.contains('soltera')) return 'Soltera';
    if (text.contains('casado')) return 'Casado';
    if (text.contains('casada')) return 'Casada';
    if (text.contains('divorciado')) return 'Divorciado';
    if (text.contains('divorciada')) return 'Divorciada';
    if (text.contains('viudo')) return 'Viudo';
    if (text.contains('viuda')) return 'Viuda';
    return '';
  }
}

// Widget reutilizable para cada tarjeta de sección
class CVSectionCard extends StatefulWidget {
  final CVSection section;
  final bool isRecording;
  final bool isPlaying;
  final bool hasAudio;
  final String transcription;
  final VoidCallback onStartRecording;
  final VoidCallback onStopRecording;
  final VoidCallback onPlayRecording;
  final Function(String) onUpdateTranscription;
  final VoidCallback onNext;
  final VoidCallback onPrevious;
  final bool isFirstSection;
  final bool isLastSection;

  const CVSectionCard({
    super.key,
    required this.section,
    required this.isRecording,
    required this.isPlaying,
    required this.hasAudio,
    required this.transcription,
    required this.onStartRecording,
    required this.onStopRecording,
    required this.onPlayRecording,
    required this.onUpdateTranscription,
    required this.onNext,
    required this.onPrevious,
    required this.isFirstSection,
    required this.isLastSection,
  });

  @override
  _CVSectionCardState createState() => _CVSectionCardState();
}

class _CVSectionCardState extends State<CVSectionCard> {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Column(
          children: [
            // Cabecera de la tarjeta
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Color(0xfff5f5fa),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.section.title,
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF090467),
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    widget.section.description,
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF090467),
                    ),
                  ),
                ],
              ),
            ),

            // Cuerpo de la tarjeta
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Campos relevantes para esta sección
                    Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Color(0xfff5f5fa),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Campos para incluir:',
                            style: GoogleFonts.poppins(
                              color: Color(0xFF090467),
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children:
                                widget.section.fields
                                    .map(
                                      (field) => Chip(
                                        label: Text(
                                          field,
                                          style: GoogleFonts.poppins(
                                            color: Color(0xFF090467),
                                            fontSize: 13,
                                            fontWeight: FontWeight.w400,
                                          ),
                                        ),
                                        backgroundColor: Color(
                                          0xff9ee4b8,
                                        ).withOpacity(0.2),
                                        labelStyle: GoogleFonts.poppins(
                                          fontSize: 12,
                                        ),
                                      ),
                                    )
                                    .toList(),
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: 24),

                    // Control de grabación de audio
                    Center(
                      child: Column(
                        children: [
                          GestureDetector(
                            onTap:
                                widget.isRecording
                                    ? widget.onStopRecording
                                    : widget.onStartRecording,
                            child: Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                color:
                                    widget.isRecording
                                        ? Colors.red
                                        : Color(0xff9ee4b8),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                widget.isRecording ? Icons.stop : Icons.mic,
                                color: Color(0xFF090467),
                                size: 40,
                              ),
                            ),
                          ),
                          SizedBox(height: 16),
                          Text(
                            widget.isRecording
                                ? 'Presiona para detener la grabación'
                                : 'Presiona para iniciar la grabación',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: Color(0xFF090467),
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: 24),

                    // Reproductor de audio (solo visible si hay audio grabado)
                    if (widget.hasAudio) ...[
                      Center(
                        child: ElevatedButton.icon(
                          icon: Icon(
                            widget.isPlaying ? Icons.stop : Icons.play_arrow,
                            color: Color(0xFF090467),
                          ),
                          label: Text(
                            widget.isPlaying
                                ? 'Detener'
                                : 'Reproducir grabación',
                            style: GoogleFonts.poppins(
                              color: Color(0xFF090467),
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xff9ee4b8),
                            padding: EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                          onPressed: widget.onPlayRecording,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            // Pie de la tarjeta con botones de navegación
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Botón Anterior
                  if (!widget.isFirstSection)
                    ElevatedButton.icon(
                      icon: Icon(Icons.arrow_back),
                      label: Text('Anterior', style: GoogleFonts.poppins()),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xffd2e8fc),
                        foregroundColor: Colors.black87,
                      ),
                      onPressed: widget.onPrevious,
                    )
                  else
                    SizedBox(width: 100),

                  // Botón Siguiente o Finalizar
                  ElevatedButton.icon(
                    icon: Icon(
                      widget.isLastSection ? Icons.check : Icons.arrow_forward,
                      color: Color(0xFF090467),
                      size: 14,
                    ),
                    label: Text(
                      widget.isLastSection ? 'Finalizar' : 'Siguiente',
                      style: GoogleFonts.poppins(
                        color: Color(0xFF090467),
                        fontSize: 14,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xff9ee4b8),
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: Colors.grey,
                    ),
                    onPressed: widget.hasAudio ? widget.onNext : null,
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

// Función utilitaria para convertir cualquier objeto JSON a tipos Dart compatibles
// Especialmente útil para Flutter web donde JSArray y otros tipos JS pueden causar problemas
dynamic convertToSafeDartType(dynamic value) {
  if (value == null) {
    return null;
  } else if (value is List) {
    return List<dynamic>.from(value.map((item) => convertToSafeDartType(item)));
  } else if (value is Map) {
    Map<String, dynamic> result = {};
    value.forEach((key, val) {
      if (key is String) {
        result[key] = convertToSafeDartType(val);
      } else {
        result[key.toString()] = convertToSafeDartType(val);
      }
    });
    return result;
  } else {
    return value;
  }
}

// Función para normalizar caracteres problemáticos pero preservando acentos y ñ
String normalizarTexto(String texto) {
  // Mapa de sustituciones solo para caracteres realmente problemáticos
  final Map<String, String> sustituciones = {
    '#': 'numero',
    '°': 'grados',
    'º': 'ordinal',
    '€': 'euros',
    '£': 'libras',
    '¥': 'yenes',
  };

  String textoNormalizado = texto;

  // Aplicar sustituciones solo a caracteres problemáticos
  sustituciones.forEach((special, normal) {
    textoNormalizado = textoNormalizado.replaceAll(special, normal);
  });

  return textoNormalizado;
}
