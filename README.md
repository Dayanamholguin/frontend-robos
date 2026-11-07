# AppRobos - Frontend

Aplicación móvil ciudadana de AppRobos para consultar y reportar hurtos en Medellín y el Valle de Aburrá. Se conecta a la API del backend.

## Tecnologías

- Flutter (canal estable, SDK 3.13 o superior)
- flutter_map con teselas de OpenStreetMap (solo desarrollo)
- Geolocator para la ubicación del teléfono
- Connectivity Plus para revisar la conexión
- Flutter Secure Storage para guardar el token de sesión

## Requisitos

- Flutter instalado y el Modo de desarrollador activo en Windows (necesario para los plugins)
- Un teléfono Android con depuración USB, o un emulador
- La API del backend en ejecución, accesible desde el teléfono

## Ejecución

El teléfono no puede usar `localhost` para llegar a la API. Hay que indicar la IP de la computadora en la red Wi-Fi:

```
flutter run --dart-define=URL_API=http://<IP-de-tu-PC>:5162
```

Sin `URL_API`, la app usa `http://localhost:5162`, que solo funciona en un emulador con la API local.

## Estructura

- `lib/inicio/`: bienvenida, presentación y permisos.
- `lib/ingreso/`: inicio de sesión.
- `lib/registro/`: crear cuenta.
- `lib/mapa/`: mapa y riesgo en la zona.
- `lib/perfil/`: perfil, cambio de contraseña y pantalla de despedida.
- `lib/widgets/`: componentes compartidos (campos, botones, barra de navegación y capa sin conexión).
- `lib/validacion/`: reglas de los formularios (las mismas que aplica la API).
- `lib/servicios/`: llamadas a la API y permisos.
- `lib/transiciones/`: transición entre pantallas según la velocidad de la red.
- `lib/tema/`: colores, tipografía y escala de tamaños.

## Notas

- El mapa usa teselas de OpenStreetMap solo para desarrollo. Para producción hay que cambiar a un proveedor con clave. El crédito "© OpenStreetMap contributors" es obligatorio.
- Cuando no hay conexión, la app se cubre con una capa gris difuminada que muestra el logo y un indicador de carga.
