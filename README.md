# tlaxgomobil

Aplicación Flutter de Tlax.Go conectada a Firebase.

## Roles e itinerarios

- Las cuentas nuevas tienen el rol `user` y pueden consultar los itinerarios.
- La cuenta cuyo UID está configurado como administrador en `firestore.rules`
  tiene el rol `admin` en la aplicación y puede publicar itinerarios.
- Para dar acceso de administrador a otra cuenta, configura el custom claim
  `role: "admin"` con Firebase Admin SDK y el campo `role: "admin"` en su
  documento `users/{uid}`. El cliente no puede asignarse ese rol.
- Los itinerarios se guardan en la colección global `itineraries`; la app los
  escucha en tiempo real y pueden consultarse desde la web usando la misma
  colección de Firestore.
- La persistencia local de Firestore está habilitada en Android: los itinerarios
  que ya se descargaron pueden consultarse sin conexión. Las publicaciones y
  favoritos hechos sin conexión se guardan localmente y se sincronizan al
  recuperar internet. El primer acceso a itinerarios requiere conexión, y la
  sincronización puede ser rechazada si las reglas no autorizan la operación.
- Publica las reglas con `firebase deploy --only firestore:rules` para habilitar
  la lectura compartida y restringir la escritura a administradores.
