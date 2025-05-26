[# 📄 CV Generator - Generador de Currículums con Audio](https://scanner-6c414.web.app)

Proyecto para Ingeniería de Software, para el pregrado de Ingeniería de Sistemas de la Universidad EAFIT.

**Código de la clase:** 6894 (Paola Noreña Cardona)

## Integrantes del equipo
- Samuel Enrique Rivero Urribarrí (Scrum Master)
- Luis Alejandro Castrillón Pulgarín (Desarrollador)
- Juan José Gómez (Desarrollador)
- Juan Manuel Escobar (Desarrollador)

Una aplicación Flutter web innovadora que permite crear currículums profesionales de dos formas: grabando audio con IA para extraer información automáticamente o completando un formulario manual. Utiliza Supabase como backend y genera PDFs con diseño moderno.

## 🚀 Características Principales

### 🎤 **Generación de CV por Audio**
- **Grabación por secciones**: Sistema guiado que permite grabar audio para cada sección del CV
- **IA Inteligente**: Utiliza OpenRouter API para procesar y organizar automáticamente la información del audio
- **Transcripción automática**: Convierte el audio en texto y extrae datos estructurados
- **Validación inteligente**: El sistema valida y organiza la información automáticamente

### ✍️ **Formulario Manual**
- **Interfaz intuitiva**: Formulario completo para ingresar información del CV manualmente
- **Vista previa en tiempo real**: Permite ver cómo se verá el CV antes de generar el PDF
- **Validación de datos**: Sistema de validación para asegurar información correcta

### 📑 **Generación de PDF Profesional**
- **Diseño moderno**: CV con gradiente azul-morado, tipografía Inter y layout profesional
- **Responsive**: Se adapta correctamente al formato A4
- **Vista previa interactiva**: Permite revisar el CV antes de descargarlo
- **Descarga directa**: Genera y descarga el PDF automáticamente

### 🔐 **Sistema de Autenticación**
- **Login seguro**: Sistema de autenticación con Supabase
- **Registro de usuarios**: Permite crear nuevas cuentas
- **Gestión de sesiones**: Manejo automático de sesiones de usuario
- **Recuperación de contraseña**: Sistema para cambiar contraseñas

### 💾 **Base de Datos**
- **Almacenamiento en la nube**: Utiliza Supabase para guardar información
- **Historial de CVs**: Guarda todos los CVs creados por el usuario
- **Sincronización**: Acceso a la información desde cualquier dispositivo

## 🛠️ Tecnologías Utilizadas

- **Flutter Web** - Framework principal para la interfaz
- **Dart** - Lenguaje de programación
- **Supabase** - Backend como servicio (BaaS)
- **OpenRouter API** - Procesamiento de IA para audio
- **HTML2Canvas & jsPDF** - Generación de PDFs
- **Google Fonts** - Tipografías modernas
- **Audio Recording** - Grabación y reproducción de audio

## 📋 Requisitos Previos

Para ejecutar este proyecto localmente necesitas:

- **Flutter SDK** >= 3.7.0
- **Dart SDK** >= 3.7.0
- **Chrome** (navegador recomendado)
- **Conexión a internet** (para APIs y Supabase)

## 🔧 Instalación y Configuración

### 1. Clonar el repositorio
```bash
git clone [URL_DEL_REPOSITORIO]
cd scanner_personal
```

### 2. Verificar configuración de Flutter
```bash
flutter doctor
flutter config --enable-web
```

### 3. Instalar dependencias
```bash
flutter clean
flutter pub get
```

### 4. Configurar variables de entorno
Asegúrate de que el archivo `.env` esté configurado correctamente:

```env
SUPABASE_URL=https://zpprbzujtziokfyyhlfa.supabase.co
SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

### 5. Verificar que todo esté listo
```bash
flutter devices
# Debe mostrar Chrome como dispositivo disponible
```

### 6. Primera ejecución
```bash
flutter run -d chrome
```

> 💡 **Tip**: Si es la primera vez que ejecutas Flutter web, puede tardar unos minutos en descargar las dependencias web necesarias.

## 🚀 Ejecución del Proyecto

### **Comando principal para ejecutar:**
```bash
flutter run -d chrome
```

### **Para desarrollo con hot reload:**
```bash
flutter run -d chrome --debug
```

### **Para construcción y ejecución en modo release:**
```bash
flutter build web
flutter run -d chrome --release
```

### **Para servir la aplicación web construida:**
```bash
flutter build web
cd build/web
python -m http.server 8000
# O si tienes Node.js instalado:
# npx serve .
```

### Comandos adicionales útiles:
```bash
# Limpiar y reconstruir completamente
flutter clean && flutter pub get && flutter run -d chrome

# Construir para producción
flutter build web --release

# Ejecutar en modo debug con información detallada
flutter run -d chrome --debug --verbose

# Habilitar web explícitamente (si es necesario)
flutter config --enable-web
flutter run -d chrome
```

> ⚠️ **Importante**: 
> - Este proyecto está optimizado para **Chrome** debido a las APIs de audio y generación de PDF
> - Si tienes problemas, primero ejecuta `flutter clean && flutter pub get`
> - Asegúrate de tener Flutter web habilitado con `flutter config --enable-web`

## 📁 Estructura del Proyecto

```
lib/
├── main.dart                          # Punto de entrada de la aplicación
├── Funcion_Audio/                     # Módulo de generación por audio
│   ├── cv_generator.dart              # Generador principal de CV por audio
│   └── monkey_pdf_integration.dart    # Integración para generación de PDF
├── Formulario/                        # Módulo de formulario manual
│   └── cv_form.dart                   # Formulario para crear CV manualmente
├── Login/                             # Sistema de autenticación
│   ├── login_screen.dart              # Pantalla de login
│   ├── register_screen.dart           # Pantalla de registro
│   └── auth_router.dart               # Enrutador de autenticación
├── Home/                              # Pantalla principal
├── Perfil_Cv/                         # Gestión de perfil y CVs
├── Configuracion/                     # Configuraciones de la app
└── AI/                                # Integración con IA
```

## 🎯 Flujo de Uso

### **Método 1: Generación por Audio**
1. **Login**: Inicia sesión en la aplicación
2. **Seleccionar audio**: Elige la opción "Crear CV por Audio"
3. **Grabar por secciones**: El sistema guía a través de diferentes secciones
4. **Procesamiento IA**: La IA procesa y organiza automáticamente la información
5. **Revisión**: Revisa y edita la información extraída
6. **Generar PDF**: Crea la vista previa y descarga el PDF

### **Método 2: Formulario Manual**
1. **Login**: Inicia sesión en la aplicación
2. **Formulario**: Elige "Crear CV Manual"
3. **Completar información**: Llena todos los campos del formulario
4. **Vista previa**: Revisa cómo se verá el CV
5. **Generar PDF**: Crea y descarga el CV en PDF

## 🔑 Funcionalidades Clave

### **Sistema de Audio Inteligente**
- Grabación por secciones específicas (datos personales, experiencia, educación, etc.)
- Procesamiento con IA para extraer información relevante
- Transcripción automática con corrección de errores
- Organización inteligente de datos

### **Generación de PDF Avanzada**
- Diseño profesional con gradientes y tipografía moderna
- Vista previa interactiva antes de descargar
- Soporte para caracteres especiales y UTF-8
- Formato A4 optimizado para impresión

### **Base de Datos Inteligente**
- Almacenamiento automático de CVs
- Sincronización en tiempo real
- Historial de modificaciones
- Backup automático en la nube

## 🐛 Solución de Problemas

### **Error: "Could not find an option named '--web-renderer'"**
- Este error indica que estás usando una versión de Flutter que ya no soporta ese flag
- **Solución**: Usa simplemente `flutter run -d chrome`

### **Error: "No supported devices connected"**
- Flutter web no está habilitado o Chrome no está instalado
- **Solución**: 
  ```bash
  flutter config --enable-web
  flutter devices
  ```

### **Error: "No se puede conectar a Supabase"**
- Verifica que las variables de entorno estén configuradas correctamente
- Confirma que tienes conexión a internet
- Revisa que las credenciales de Supabase sean válidas
- **Solución**: Verifica el archivo `.env` y reinicia la aplicación

### **Error: "PDF no se genera correctamente"**
- Problemas con las librerías JavaScript de generación de PDF
- **Solución**:
  ```bash
  flutter clean
  flutter pub get
  flutter run -d chrome
  ```
- Asegúrate de usar **Chrome** (no otros navegadores)
- Confirma que JavaScript esté habilitado

### **Error: "Audio no se graba"**
- Permisos de micrófono no otorgados o problemas de HTTPS
- **Solución**:
  - Permite permisos de micrófono en Chrome
  - Verifica que el micrófono esté funcionando
  - Si estás en localhost, debería funcionar automáticamente
  - Para producción, necesitas HTTPS

### **Error: "Target of URI doesn't exist" al cargar archivos**
- Problemas con las rutas de assets
- **Solución**:
  ```bash
  flutter pub get
  flutter clean
  flutter run -d chrome
  ```

### **Error: "XMLHttpRequest error" con Supabase**
- Problemas de CORS o configuración de red
- **Solución**:
  - Verifica tu conexión a internet
  - Confirma que las URLs de Supabase sean correctas
  - Intenta ejecutar en modo incógnito para descartar extensiones

## ✅ Verificación de Instalación

### **Lista de verificación después de clonar:**

1. **✅ Flutter configurado correctamente**
   ```bash
   flutter doctor
   # Debe mostrar checkmarks verdes para Web development
   ```

2. **✅ Dependencias instaladas**
   ```bash
   flutter pub get
   # No debe mostrar errores
   ```

3. **✅ Chrome disponible como dispositivo**
   ```bash
   flutter devices
   # Debe listar "Chrome" como dispositivo disponible
   ```

4. **✅ Variables de entorno configuradas**
   - Verificar que existe el archivo `.env`
   - Confirmar que contiene `SUPABASE_URL` y `SUPABASE_ANON_KEY`

5. **✅ Primera ejecución exitosa**
   ```bash
   flutter run -d chrome
   # La aplicación debe abrir en Chrome y mostrar la pantalla de login
   ```

### **¿Todo funcionando?**
Si completaste todos los pasos anteriores sin errores, ¡tu instalación está lista! 🎉

Si algún paso falló, revisa la sección "🐛 Solución de Problemas" arriba.

## 📝 Notas Importantes

- **Solo funciona en Chrome**: La aplicación está optimizada para Chrome debido a las APIs de audio y PDF
- **Requiere internet**: Necesita conexión para Supabase y APIs de IA
- **Permisos de micrófono**: El navegador pedirá permisos para acceder al micrófono
