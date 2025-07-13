import 'package:flutter/material.dart'; //UI de estilo MaterialApp.
import 'package:google_fonts/google_fonts.dart'; //Fuentes de Google, en este caso Poppins.
import 'home_screen.dart'; //Importa la pantalla a donde continuara, en este caso HomeScreen.

//Pantalla con estado (Cambiara con el tiempo).
//StatefulWidget es decir Se vera modificada por otro Widget.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

//Clase que contiene la logica y comportamiento de esta screen.
class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  //Variables de animacion
  late AnimationController _controller; //Controla (duración, inicio, tiempo).
  late Animation<double> _fadeOutAnimation; //Efecto de desvanecimiento.

  //Metodo para inicializar los valores.
  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this, //Eficiencia básicamente.
      duration: const Duration(
        milliseconds: 800,
      ), //Duración en milis del fadeout
    );

    _fadeOutAnimation = Tween<double>(
      begin: 1.0, //Incia con opacidad transparente.
      end: 0.0, //Finaliza en opacidad completamente oscura.
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    //Espera 3 segundos antes de iniciar el fadeout.
    Future.delayed(const Duration(seconds: 3), () {
      _controller.forward(); //Inicia la animación fade out

      //Cuando la animación termina envia a la Homescreen.
      _controller.addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => HomeScreen()),
          );
        }
      });
    });
  }

  //Limpia los recursos usados para la animación (Eficiencia).
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  //Construcción de la IU de la screen.
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromRGBO(20, 17, 24, 1),
      body: FadeTransition(
        opacity: _fadeOutAnimation,
        //Cuerpo central de la pantalla, contenido en un Scaffold.
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              //Iniciamos con el logo de la universidad de manera centrada.
              Image.asset(
                'assets/images/unal_logo.png',
                width: 120,
                height: 120,
              ),
              const SizedBox(height: 30),
              Text(
                //Nombre de la app.
                'TechTalk',
                style: GoogleFonts.poppins(
                  fontSize: 28,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
