//** TERMINAL - node server.js - para correr */

// Importar las bibliotecas necesarias
const express = require('express'); // Framework para crear aplicaciones web
const mongoose = require('mongoose'); // Biblioteca para interactuar con MongoDB
const bodyParser = require('body-parser'); // Middleware para parsear cuerpos de solicitudes
const cors = require('cors'); // Middleware para habilitar CORS (Cross-Origin Resource Sharing)

// Crear una instancia de la aplicación Express
const app = express();

// Definir el puerto en el que correrá la aplicación
const port = 3000;

// Usar middlewares
app.use(bodyParser.json()); // Parsear cuerpos de solicitudes como JSON
app.use(cors()); // Habilitar CORS

// Conectarse a la base de datos de MongoDB
mongoose.connect('mongodb+srv://samir:admin@primeraapp.phez2jl.mongodb.net/?retryWrites=true&w=majority&appName=primeraApp', { useNewUrlParser: true, useUnifiedTopology: true });

// Definir el esquema de la colección "conversions" en MongoDB
const conversionSchema = new mongoose.Schema({
  tipo: String, // Tipo de conversión (por ejemplo, moneda)
  cantidad: Number, // Cantidad a convertir
  resultado: Number // Resultado de la conversión
});

// Crear el modelo "Conversion" basado en el esquema definido
const Conversion = mongoose.model('Conversion', conversionSchema);

// Definir la ruta para guardar una nueva conversión
app.post('/convertir', async (req, res) => {
  // Extraer datos del cuerpo de la solicitud
  const { tipo, cantidad, resultado } = req.body;

  try {
    // Crear una nueva instancia de "Conversion" con los datos recibidos
    const nuevaConversion = new Conversion({ tipo, cantidad, resultado });
    // Guardar la nueva conversión en la base de datos
    await nuevaConversion.save();
    // Enviar la conversión guardada como respuesta con el código de estado 200 (OK)
    res.status(200).send(nuevaConversion);
  } catch (error) {
    // Manejar errores y enviar un mensaje de error con el código de estado 500 (Internal Server Error)
    console.error('Error al guardar la conversión:', error);
    res.status(500).send({ error: 'Error al guardar la conversión' });
  }
});

// Definir la ruta para obtener el historial de conversiones
app.get('/historico', async (req, res) => {
  try {
    // Obtener todas las conversiones de la base de datos
    const historico = await Conversion.find({});
    // Enviar el historial como respuesta con el código de estado 200 (OK)
    res.status(200).send(historico);
  } catch (error) {
    // Manejar errores y enviar un mensaje de error con el código de estado 500 (Internal Server Error)
    console.error('Error al cargar el historial:', error);
    res.status(500).send({ error: 'Error al cargar el historial' });
  }
});

// Definir la ruta para eliminar una conversión por ID
app.delete('/convertir/:id', async (req, res) => {
  // Extraer el ID de la conversión de los parámetros de la solicitud
  const { id } = req.params;

  try {
    // Eliminar la conversión correspondiente en la base de datos
    await Conversion.findByIdAndDelete(id);
    // Enviar un mensaje de éxito como respuesta con el código de estado 200 (OK)
    res.status(200).send({ message: 'Conversión eliminada' });
  } catch (error) {
    // Manejar errores y enviar un mensaje de error con el código de estado 500 (Internal Server Error)
    console.error('Error al eliminar la conversión:', error);
    res.status(500).send({ error: 'Error al eliminar la conversión' });
  }
});

// Iniciar el servidor para que escuche en el puerto definido
app.listen(port, () => {
  console.log(`Servidor escuchando en el puerto ${port}`);
});

