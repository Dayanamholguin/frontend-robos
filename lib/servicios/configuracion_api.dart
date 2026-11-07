// Dirección base de la API. Se define al compilar, para no dejar IPs fijas en el código:
//   flutter run --dart-define=URL_API=http://<IP-de-tu-PC>:5162
// En el teléfono "localhost" es el propio teléfono, por eso hay que usar la IP de la computadora.
const String urlApi = String.fromEnvironment(
  'URL_API',
  defaultValue: 'http://localhost:5162',
);
