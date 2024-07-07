import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => MyAppState(),
      child: MaterialApp(
        title: 'Convertidor de Monedas',
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepOrange),
        ),
        home: MyHomePage(),
      ),
    );
  }
}

class MyAppState extends ChangeNotifier {
  final List<Map<String, String>> dolaresASoles = [];
  final List<Map<String, String>> solesADolares = [];
  final double tasaCambio = 3.75;
  String resultadoConversion = '';
  final String serverUrl = 'http://localhost:3000';

  MyAppState() {
    _cargarHistorico();
  }

  Future<void> _cargarHistorico() async {
    try {
      final response = await http.get(Uri.parse('$serverUrl/historico'));

      if (response.statusCode == 200) {
        List<dynamic> historico = jsonDecode(response.body);
        for (var item in historico) {
          if (item['tipo'] == 'DolaresASoles') {
            dolaresASoles.add({
              'id': item['_id'],
              'conversion': '${item['cantidad']} Dólares = ${item['resultado']} Soles'
            });
          } else if (item['tipo'] == 'SolesADolares') {
            solesADolares.add({
              'id': item['_id'],
              'conversion': '${item['cantidad']} Soles = ${item['resultado']} Dólares'
            });
          }
        }
        notifyListeners();
      } else {
        throw Exception('Error al cargar el historial');
      }
    } catch (error) {
      print('Error: $error');
    }
  }

  Future<void> _guardarConversion(String tipo, double cantidad, double resultado) async {
    try {
      final response = await http.post(
        Uri.parse('$serverUrl/convertir'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'tipo': tipo,
          'cantidad': cantidad,
          'resultado': resultado,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final id = data['_id'];

        if (tipo == 'DolaresASoles') {
          dolaresASoles.add({
            'id': id,
            'conversion': '$cantidad Dólares = $resultado Soles',
          });
        } else if (tipo == 'SolesADolares') {
          solesADolares.add({
            'id': id,
            'conversion': '$cantidad Soles = $resultado Dólares',
          });
        }

        notifyListeners();
      } else {
        print('Error al guardar la conversión: ${response.body}');
        throw Exception('Error al guardar la conversión');
      }
    } catch (error) {
      print('Error: $error');
      throw Exception('Error al guardar la conversión');
    }
  }

  Future<void> convertirDolaresASoles(double cantidad) async {
    double resultado = cantidad * tasaCambio;
    resultadoConversion = '$cantidad Dólares = $resultado Soles';

    await _guardarConversion('DolaresASoles', cantidad, resultado);
    notifyListeners();
  }

  Future<void> convertirSolesADolares(double cantidad) async {
    double resultado = cantidad / tasaCambio;
    resultadoConversion = '$cantidad Soles = $resultado Dólares';

    await _guardarConversion('SolesADolares', cantidad, resultado);
    notifyListeners();
  }

  Future<void> eliminarConversion(String id) async {
    try {
      final response = await http.delete(Uri.parse('$serverUrl/convertir/$id'));

      if (response.statusCode == 200) {
        dolaresASoles.removeWhere((element) => element['id'] == id);
        solesADolares.removeWhere((element) => element['id'] == id);
        notifyListeners();
      } else {
        print('Error al eliminar la conversión: ${response.body}');
        throw Exception('Error al eliminar la conversión');
      }
    } catch (error) {
      print('Error: $error');
    }
  }
}

class MyHomePage extends StatefulWidget {
  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  var selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    Widget page;

    switch (selectedIndex) {
      case 0:
        page = ConvertidorPage();
        break;
      case 1:
        page = HistoricoPage();
        break;
      default:
        throw UnimplementedError('no widget for $selectedIndex');
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        return Scaffold(
          body: Row(
            children: [
              SafeArea(
                child: NavigationRail(
                  extended: constraints.maxWidth >= 600,
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
                  selectedIndex: selectedIndex,
                  onDestinationSelected: (value) {
                    setState(() {
                      selectedIndex = value;
                    });
                  },
                ),
              ),
              Expanded(
                child: Container(
                  color: Theme.of(context).colorScheme.primaryContainer,
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

class ConvertidorPage extends StatefulWidget {
  const ConvertidorPage({super.key});

  @override
  _ConvertidorPageState createState() => _ConvertidorPageState();
}

class _ConvertidorPageState extends State<ConvertidorPage> {
  bool convertirDolaresASoles = true;
  bool convertirSolesADolares = false;
  TextEditingController controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    var appState = context.watch<MyAppState>();

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Convertidor de Monedas',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          SizedBox(height: 20),
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
          ElevatedButton(
            onPressed: () {
              double cantidad = double.parse(controller.text);
              if (convertirDolaresASoles) {
                appState.convertirDolaresASoles(cantidad);
              } else if (convertirSolesADolares) {
                appState.convertirSolesADolares(cantidad);
              }
            },
            child: Text('Convertir'),
          ),
          SizedBox(height: 20),
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

class HistoricoPage extends StatelessWidget {
  const HistoricoPage({super.key});

  @override
  Widget build(BuildContext context) {
    var appState = context.watch<MyAppState>();

    return ListView(
      children: [
        Padding(
          padding: const EdgeInsets.all(20),
          child: Text(
            'Historial de Conversiones',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
        ),
        if (appState.dolaresASoles.isEmpty && appState.solesADolares.isEmpty)
          Center(child: Text('No hay conversiones realizadas.')),
        if (appState.dolaresASoles.isNotEmpty)
          ...appState.dolaresASoles.map((conversion) => ListTile(
                leading: Icon(Icons.delete),
                title: Text(conversion['conversion']!),
                onTap: () {
                  appState.eliminarConversion(conversion['id']!);
                },
              )),
        if (appState.solesADolares.isNotEmpty)
          ...appState.solesADolares.map((conversion) => ListTile(
                leading: Icon(Icons.delete),
                title: Text(conversion['conversion']!),
                onTap: () {
                  appState.eliminarConversion(conversion['id']!);
                },
              )),
      ],
    );
  }
}
