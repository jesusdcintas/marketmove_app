# MarketMove App

## Descripción del proyecto
MarketMove es una aplicación móvil pensada para que negocios pequeños lleven el control de sus productos, ventas y gastos desde un mismo lugar. La app permite registrar cada movimiento, mostrar el balance general y conectar la información directamente con una base de datos en la nube para que todo el equipo la tenga actualizada.

## Integrantes del equipo
- Jesús (desarrollo principal)
- [Agrega aquí otros nombres si hay más colaboradores]

## Fases del proyecto
1. **Descubrimiento:** se revisó la estructura real de las tablas de Supabase para asegurarnos de que los campos estén alineados con lo que maneja el negocio.
2. **Autenticación:** se separaron las pantallas de inicio de sesión y registro, y se garantizaron flujos rápidos sin solicitudes de verificación de correo.
3. **Registro de datos:** se implementaron pantallas específicas para productos, ventas, gastos y balance, todas con sus servicios actualizados para usar los datos del usuario conectado.
4. **Calidad y despliegue:** se ajustó la navegación, se revisaron los permisos de Supabase y se corrió la compilación para Android para confirmar que el código genera el archivo final sin errores.

## Requisitos técnicos
- Flutter 3.x o superior
- SDK de Dart incluido con Flutter
- Cuenta de Supabase configurada con las tablas `productos`, `ventas` y `gastos` y las políticas RLS ya definidas.
- Variables de entorno (`.env`) con `SUPABASE_URL` y `SUPABASE_ANON_KEY` apuntando al proyecto correcto.
- Emulador o dispositivo Android con soporte para Flutter.

## Cómo ejecutar el proyecto
1. Clona este repositorio y abre la carpeta del proyecto.
2. Instala las dependencias con:
	```bash
	flutter pub get
	```
3. Asegúrate de tener un emulador Android abierto o un dispositivo conectado.
4. Ejecuta la app con:
	```bash
	flutter run
	```
5. Inicia sesión o crea una cuenta para comenzar a usar las pantallas de productos, ventas, gastos y balance.

## Cómo generar el APK
Una vez que la aplicación está lista y probada, crea el APK para instalarlo directamente o compartirlo con:
```bash
flutter build apk --release
```
El archivo resultante se ubicará en `build/app/outputs/flutter-apk/app-release.apk`.
