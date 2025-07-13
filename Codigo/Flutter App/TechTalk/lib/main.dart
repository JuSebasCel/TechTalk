//lib/main.dart
import 'package:flutter/material.dart'; //UI de estilo MaterialApp.
import 'package:hive_flutter/hive_flutter.dart'; //Base de datos local (NoSQL).
import 'package:google_fonts/google_fonts.dart'; //Fuentes de Google, en este caso Poppins.
import 'screens/splash_screen.dart'; //Pantalla de carga (Logo&Name).
import 'models/perfil.dart'; //Modelo de datos, generado automaticamente por HiveBox.

//Funcion principal asincronica (Pantallas que esperan resultados sin detener la App).
void main() async {
  WidgetsFlutterBinding.ensureInitialized(); //Espera que todo este cargado.
  await Hive.initFlutter(); //Inicializa HiveBox para entorno Flutter.

  //Inicializa adaptadores y Box donde estara toda la información.
  Hive.registerAdapter(CombinacionAdapter());
  Hive.registerAdapter(PerfilAdapter());
  await Hive.openBox<Perfil>('perfilesBox');

  //Inicia la aplicación desde la clase GuanteComunicadorApp
  runApp(const GuanteComunicadorApp());
}

//Clase tipo estatico pues no cambiara por ningun motivo.
class GuanteComunicadorApp extends StatelessWidget {
  const GuanteComunicadorApp({super.key});

  //El builder que se encarga de cargar la UI de Material Dark.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Guante Comunicador',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        textTheme: GoogleFonts.poppinsTextTheme(ThemeData.dark().textTheme),
      ),
      home:
          const SplashScreen(), //Se inicia primero por SplashScreen ("Pantalla de Carga").
    );
  }
}
