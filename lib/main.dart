// Importar las bibliotecas necesarias
import 'dart:convert'; // Para convertir datos JSON
import 'package:flutter/material.dart'; // Biblioteca principal de Flutter
import 'package:provider/provider.dart'; // Para manejo del estado
import 'package:http/http.dart' as http; // Para hacer solicitudes HTTP

// Función principal que inicia la aplicación
void main() {
  runApp(MyApp());
}

// Clase principal de la aplicación
class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);
  //MyApp es el punto de entrada de la aplicación Flutter.

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      //Utiliza ChangeNotifierProvider para administrar 
      //el estado global (MyAppState) de la aplicación.
      create: (context) => MyAppState(),
      //Define una función que devuelve una nueva instancia de MyAppState, 
      //gestionará y notificará a los widgets cuando cambie.
      child: MaterialApp(
        //Configura el tema de la aplicación con MaterialApp.
        title: 'Convertidor de Monedas',
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepOrange),
        ),
        home: MyHomePage(),
        //Define MyHomePage() como la pantalla principal de la aplicación.
      ),
    );
  }
}

// Clase que maneja el estado de la aplicación
class MyAppState extends ChangeNotifier {

  //Cada conversión se guarda como un mapa (Map<String, String>)
  //que contiene un ID y una cadena que representa la conversión.
  final List<Map<String, String>> dolaresASoles = [];
  final List<Map<String, String>> solesADolares = [];

  //utilizada para las conversiones entre dólares y soles.
  final double tasaCambio = 3.75;

  //almacena el resultado de la última conversión realizada.
  String resultadoConversion = '';

  //URL base del servidor al que la aplicación se conectará 
  //para realizar operaciones CRUD.
  final String serverUrl = 'http://localhost:3000';

  MyAppState() {
    _cargarHistorico();
  }


// Función asíncrona que carga el historial de conversiones desde el servidor.
Future<void> _cargarHistorico() async {
  try {
    // Realiza una solicitud HTTP GET al servidor para obtener el historial de conversiones.
    final response = await http.get(Uri.parse('$serverUrl/historico'));

    // Verifica si la respuesta del servidor tiene un código de estado 200 (OK).
    if (response.statusCode == 200) {
      // Decodifica el cuerpo de la respuesta JSON en una lista dinámica.
      List<dynamic> historico = jsonDecode(response.body);

      // Itera sobre cada elemento del historial.
      for (var item in historico) {
        // Verifica si el tipo de conversión es "DolaresASoles".
        if (item['tipo'] == 'DolaresASoles') {
          // Añade una nueva entrada a la lista dolaresASoles.
          dolaresASoles.add({
            'id': item['_id'], // Almacena el ID del registro.
            'conversion': '${item['cantidad']} Dólares = ${item['resultado']} Soles' 
            // Almacena la conversión formateada.
          });
        }
        // Verifica si el tipo de conversión es "SolesADolares".
        else if (item['tipo'] == 'SolesADolares') {
          // Añade una nueva entrada a la lista solesADolares.
          solesADolares.add({
            'id': item['_id'], // Almacena el ID del registro.
            'conversion': '${item['cantidad']} Soles = ${item['resultado']} Dólares' 
            // Almacena la conversión formateada.
          });
        }
      }
      // Notifica a los oyentes que el estado ha cambiado.
      notifyListeners();
    } else {
      // Lanza una excepción si el código de estado no es 200.
      throw Exception('Error al cargar el historial');
    }
  } catch (error) {
    // Imprime el error en la consola si ocurre una excepción.
    print('Error: $error');
  }
}


  // Función asíncrona que guarda una nueva conversión en el servidor.
  Future<void> _guardarConversion(String tipo, double cantidad, double resultado) async {
  try {
    // Realiza una solicitud HTTP POST al servidor para guardar la conversión.
    final response = await http.post(
      Uri.parse('$serverUrl/convertir'),
      headers: {'Content-Type': 'application/json'}, // Establece el tipo de contenido como JSON.
      body: jsonEncode({
        'tipo': tipo, // El tipo de conversión (DolaresASoles o SolesADolares).
        'cantidad': cantidad, // La cantidad a convertir.
        'resultado': resultado, // El resultado de la conversión.
      }),
    );

    // Verifica si la respuesta del servidor tiene un código de estado 200 (OK).
    if (response.statusCode == 200) {
      // Decodifica el cuerpo de la respuesta JSON para obtener los datos.
      final data = jsonDecode(response.body);
      final id = data['_id']; // Obtiene el ID de la nueva conversión guardada.

      // Añade la nueva conversión a la lista correspondiente según su tipo.
      if (tipo == 'DolaresASoles') {
        dolaresASoles.add({
          'id': id, // Almacena el ID del registro.
          'conversion': '$cantidad Dólares = $resultado Soles' // Almacena la conversión formateada.
        });
      } else if (tipo == 'SolesADolares') {
        solesADolares.add({
          'id': id, // Almacena el ID del registro.
          'conversion': '$cantidad Soles = $resultado Dólares' // Almacena la conversión formateada.
        });
      }

      // Notifica a los oyentes que el estado ha cambiado.
      notifyListeners();
    } else {
      // Imprime un mensaje de error si el código de estado no es 200.
      print('Error al guardar la conversión: ${response.body}');
      throw Exception('Error al guardar la conversión');
    }
  } catch (error) {
    // Imprime el error en la consola si ocurre una excepción y lanza una excepción.
    print('Error: $error');
    throw Exception('Error al guardar la conversión');
  }
}


// Función para convertir dólares a soles
Future<void> convertirDolaresASoles(double cantidad) async {
  // Calcula el resultado de la conversión multiplicando la cantidad por la tasa de cambio
  double resultado = cantidad * tasaCambio;
  
  // Formatea el resultado de la conversión como una cadena
  resultadoConversion = '$cantidad Dólares = $resultado Soles';

  // Guarda la conversión en el servidor
  await _guardarConversion('DolaresASoles', cantidad, resultado);
  
  // Notifica a los oyentes que el estado ha cambiado
  notifyListeners();
}

// Función para convertir soles a dólares
Future<void> convertirSolesADolares(double cantidad) async {
  // Calcula el resultado de la conversión dividiendo la cantidad por la tasa de cambio
  double resultado = cantidad / tasaCambio;
  
  // Formatea el resultado de la conversión como una cadena
  resultadoConversion = '$cantidad Soles = $resultado Dólares';

  // Guarda la conversión en el servidor
  await _guardarConversion('SolesADolares', cantidad, resultado);
  
  // Notifica a los oyentes que el estado ha cambiado
  notifyListeners();
}

// Función para eliminar una conversión del servidor
Future<void> eliminarConversion(String id) async {
  try {
      // Realiza una solicitud HTTP DELETE al servidor para eliminar la conversión
      final response = await http.delete(Uri.parse('$serverUrl/convertir/$id'));

      // Verifica si la respuesta del servidor tiene un código de estado 200 (OK)
      if (response.statusCode == 200) {
        // Elimina la conversión de las listas locales según su tipo
        dolaresASoles.removeWhere((element) => element['id'] == id);
        solesADolares.removeWhere((element) => element['id'] == id);
        
        // Notifica a los oyentes que el estado ha cambiado
        notifyListeners();
      } else {
        // Imprime un mensaje de error si el código de estado no es 200
        print('Error al eliminar la conversión: ${response.body}');
        throw Exception('Error al eliminar la conversión');
      }
    } catch (error) {
      // Imprime el error en la consola si ocurre una excepción
      print('Error: $error');
    }
  }
}

// Página principal de la aplicación
class MyHomePage extends StatefulWidget {
  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  // Índice de la página seleccionada
  var selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    // Variable para almacenar el widget de la página seleccionada
    Widget page;

    // Selecciona la página a mostrar según el índice seleccionado
    switch (selectedIndex) {
      case 0:
        // Página de convertidor de monedas
        page = ConvertidorPage();
        break;
      case 1:
        // Página de historial de conversiones
        page = HistoricoPage();
        break;
        
      default:
        // Si el índice no corresponde a ninguna página, lanza un error
        throw UnimplementedError('no widget for $selectedIndex');
    }

    // Construye el layout principal usando un LayoutBuilder para adaptarse al tamaño de la pantalla
    return LayoutBuilder(
      builder: (context, constraints) {
        return Scaffold(
          body: Row(
            children: [
              // NavigationRail para la navegación entre páginas
              SafeArea(
                child: NavigationRail(
                  // Extiende el NavigationRail si el ancho de la pantalla es mayor o igual a 600
                  extended: constraints.maxWidth >= 600,
                  // Define los destinos del NavigationRail
                  destinations: const [
                    NavigationRailDestination(
                      icon: Icon(Icons.swap_horiz),
                      label: Text('Convertidor'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.history),
                      label: Text('Historial'),
                    ),
                  ],
                  // Índice del destino seleccionado
                  selectedIndex: selectedIndex,
                  // Actualiza el índice seleccionado cuando se selecciona un nuevo destino
                  onDestinationSelected: (value) {
                    setState(() {
                      selectedIndex = value;
                    });
                  },
                ),
              ),
              // Expande el contenedor para que ocupe el resto del espacio disponible
              Expanded(
                child: Container(
                  // Establece el color de fondo del contenedor usando el tema actual
                  color: Theme.of(context).colorScheme.primaryContainer,
                  // Muestra la página seleccionada
                  child: page,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}



// Página de conversión de monedas
class ConvertidorPage extends StatefulWidget {
  const ConvertidorPage({super.key});

  @override
  _ConvertidorPageState createState() => _ConvertidorPageState();
}

class _ConvertidorPageState extends State<ConvertidorPage> {
  // Variables para controlar las opciones de conversión
  bool convertirDolaresASoles = true;
  bool convertirSolesADolares = false;

  // Controlador para el campo de texto
  TextEditingController controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    // Obtener el estado de la aplicación
    var appState = context.watch<MyAppState>();

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Título de la página
          Text(
            'Convertidor de Monedas',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          SizedBox(height: 20),
          // Opción para convertir dólares a soles
          CheckboxListTile(
            title: Text('Dólares a Soles'),
            value: convertirDolaresASoles,
            onChanged: (bool? value) {
              setState(() {
                convertirDolaresASoles = value!;
                if (convertirDolaresASoles) convertirSolesADolares = false;
              });
            },
          ),
          // Opción para convertir soles a dólares
          CheckboxListTile(
            title: Text('Soles a Dólares'),
            value: convertirSolesADolares,
            onChanged: (bool? value) {
              setState(() {
                convertirSolesADolares = value!;
                if (convertirSolesADolares) convertirDolaresASoles = false;
              });
            },
          ),
          SizedBox(height: 20),
          // Campo de texto para ingresar el monto a convertir
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: TextField(
              controller: controller,
              decoration: InputDecoration(
                labelText: 'Monto a convertir',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
          ),
          SizedBox(height: 20),
          // Botón para realizar la conversión
          ElevatedButton(
            onPressed: () {
              // Obtener el monto ingresado
              double cantidad = double.parse(controller.text);
              // Llamar a la función de conversión según la opción seleccionada
              if (convertirDolaresASoles) {
                appState.convertirDolaresASoles(cantidad);
              } else if (convertirSolesADolares) {
                appState.convertirSolesADolares(cantidad);
              }
            },
            child: Text('Convertir'),
          ),
          SizedBox(height: 20),
          // Mostrar el resultado de la conversión si está disponible
          if (appState.resultadoConversion.isNotEmpty)
            Text(
              'Resultado: ${appState.resultadoConversion}',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
        ],
      ),
    );
  }
}


// Página para mostrar el historial de conversiones
class HistoricoPage extends StatelessWidget {
  const HistoricoPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Obtener el estado de la aplicación
    var appState = context.watch<MyAppState>();

    return ListView(
      children: [
        // Título de la página
        Padding(
          padding: const EdgeInsets.all(20),
          child: Text(
            'Historial de Conversiones',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
        ),
        // Mostrar un mensaje si no hay conversiones realizadas
        if (appState.dolaresASoles.isEmpty && appState.solesADolares.isEmpty)
          Center(child: Text('No hay conversiones realizadas.')),
        // Mostrar la lista de conversiones de dólares a soles
        if (appState.dolaresASoles.isNotEmpty)
          ...appState.dolaresASoles.map((conversion) => ListTile(
                leading: Icon(Icons.delete),
                title: Text(conversion['conversion']!),
                onTap: () {
                  // Eliminar la conversión al hacer clic
                  appState.eliminarConversion(conversion['id']!);
                },
              )),
        // Mostrar la lista de conversiones de soles a dólares
        if (appState.solesADolares.isNotEmpty)
          ...appState.solesADolares.map((conversion) => ListTile(
                leading: Icon(Icons.delete),
                title: Text(conversion['conversion']!),
                onTap: () {
                  // Eliminar la conversión al hacer clic
                  appState.eliminarConversion(conversion['id']!);
                },
              )),
      ],
    );
  }
}

