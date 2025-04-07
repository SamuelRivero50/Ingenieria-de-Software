# Scanner_CV

Proyecto para Ingeniería de Software, para el pregrado de Ingeniería de Sistemas de la Universidad EAFIT.

**Código de la clase:** 6894 (Paola Noreña Cardona)

## Integrantes del equipo
- Samuel Enrique Rivero Urribarrí (Scrum Master)
- Luis Alejandro Castrillón Pulgarín (Desarrollador)
- Juan José Gómez (Desarrollador)
- Juan Manuel Escobar (Desarrollador)



## Instrucciones de configuración y despliegue

### 1. Clonar el repositorio desde GitHub
```bash
git clone https://github.com/usuario/repositorio.git
cd repositorio
```

### 2. Instalar las dependencias de Flutter
```bash
flutter pub get
```

### 3. Configurar variables de entorno
- Crear un archivo `.env` en la raíz del proyecto.
- Agregar las siguientes líneas con las credenciales de Supabase:

```env
SUPABASE_URL=https://su-proyecto.supabase.co
SUPABASE_ANON_KEY=su-clave-anonima
```

- **Importante:** Asegúrate de que el archivo `.env` esté incluido en el `.gitignore` para no compartir credenciales sensibles.

### 4. Importar las variables del archivo `.env` en `main.dart`
Asegúrate de cargar las variables de entorno antes de acceder a Supabase, agregando el siguiente código en `main.dart`:

```dart
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async {
  await dotenv.load();
  runApp(MyApp());
}
```

### 5. Instalar Firebase CLI (para Hosting)
Si aún no tienes Firebase CLI instalado, ejecuta:

```bash
npm install -g firebase-tools
```

### 6. Iniciar sesión en Firebase
```bash
firebase login
```

### 7. Crear un proyecto en Firebase (si no lo tienes)
- Ir a [Firebase Console](https://console.firebase.google.com/).
- Crear un nuevo proyecto.
- Activar **Firebase Hosting** en la configuración del proyecto.

### 8. Conectar el proyecto con Firebase Hosting
```bash
firebase init hosting
```

### 9. Ejecutar la aplicación en un emulador o dispositivo físico
```bash
flutter run
```

