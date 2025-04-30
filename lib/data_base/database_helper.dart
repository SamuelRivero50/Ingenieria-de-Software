import 'package:sqflite/sqflite.dart'; // Importa la biblioteca sqflite para manejar la base de datos SQLite.
    import 'package:path/path.dart'; // Importa la biblioteca path para manejar rutas de archivos.
    import 'package:shared_preferences/shared_preferences.dart'; // Importa la biblioteca shared_preferences para manejar preferencias compartidas.

    class DatabaseHelper {
      static final DatabaseHelper instance = DatabaseHelper._init(); // Crea una instancia única de DatabaseHelper.
      static Database? _database; // Variable para almacenar la instancia de la base de datos.

      DatabaseHelper._init(); // Constructor privado para inicializar la clase.

      Future<Database> get database async {
        if (_database != null) return _database!; // Si la base de datos ya está inicializada, la devuelve.
        _database = await _initDB('usuarios.db'); // Si no, inicializa la base de datos.
        return _database!; // Devuelve la base de datos inicializada.
      }

      Future<Database> _initDB(String filePath) async {
        final dbPath = await getDatabasesPath(); // Obtiene la ruta del directorio de bases de datos.
        final path = join(dbPath, filePath); // Une la ruta del directorio con el nombre del archivo de la base de datos.

        return await openDatabase(
          path, // Abre la base de datos en la ruta especificada.
          version: 1, // Especifica la versión de la base de datos.
          onCreate: _createDB, // Llama a _createDB cuando se crea la base de datos.
        );
      }

      Future<void> _createDB(Database db, int version) async {
        await db.execute('''
          CREATE TABLE usuarios (
            id INTEGER PRIMARY KEY AUTOINCREMENT, // Columna id como clave primaria autoincremental.
            nombre TEXT NOT NULL, // Columna nombre de tipo texto, no nulo.
            email TEXT UNIQUE NOT NULL, // Columna email de tipo texto, único y no nulo.
            password TEXT NOT NULL // Columna password de tipo texto, no nulo.
          )
        '''); // Ejecuta la sentencia SQL para crear la tabla usuarios.
      }

      Future<Map<String, dynamic>?> obtenerUsuarioPorEmail(String email) async {
        final db = await instance.database; // Obtiene la instancia de la base de datos.
        final result = await db.query(
          'usuarios', // Consulta la tabla usuarios.
          where: 'email = ?', // Condición de la consulta.
          whereArgs: [email], // Argumentos de la condición.
        );

        if (result.isNotEmpty) {
          return result.first; // Si hay resultados, devuelve el primer resultado.
        }
        return null; // Si no hay resultados, devuelve null.
      }

      Future<int> agregarUsuario(String nombre, String email, String password) async {
        final db = await instance.database; // Obtiene la instancia de la base de datos.
        final id = await db.insert('usuarios', {
          'nombre': nombre, // Inserta el nombre en la columna nombre.
          'email': email, // Inserta el email en la columna email.
          'password': password, // Inserta el password en la columna password.
        });

        await _guardarSesion(email); // Guarda la sesión del usuario.
        return id; // Devuelve el id del usuario insertado.
      }

      Future<Map<String, dynamic>?> autenticarUsuario(String email, String password) async {
        final db = await instance.database; // Obtiene la instancia de la base de datos.
        final result = await db.query(
          'usuarios', // Consulta la tabla usuarios.
          where: 'email = ? AND password = ?', // Condición de la consulta.
          whereArgs: [email, password], // Argumentos de la condición.
        );

        if (result.isNotEmpty) {
          await _guardarSesion(email); // Guarda la sesión del usuario.
          return result.first; // Si hay resultados, devuelve el primer resultado.
        }
        return null; // Si no hay resultados, devuelve null.
      }

      Future<void> _guardarSesion(String email) async {
        final prefs = await SharedPreferences.getInstance(); // Obtiene la instancia de SharedPreferences.
        final usuarioRegistrado = await obtenerSesion(); // Obtiene la sesión del usuario.

        if (usuarioRegistrado == null) {
          await prefs.setString('usuario_actual', email); // Si no hay sesión, guarda el email del usuario actual.
        }
      }

      Future<String?> obtenerSesion() async {
        final prefs = await SharedPreferences.getInstance(); // Obtiene la instancia de SharedPreferences.
        return prefs.getString('usuario_actual'); // Devuelve el email del usuario actual.
      }

      Future<void> cerrarSesion() async {
        final prefs = await SharedPreferences.getInstance(); // Obtiene la instancia de SharedPreferences.
        await prefs.remove('usuario_actual'); // Elimina la sesión del usuario actual.
      }
    }