const express = require('express');
const mongoose = require('mongoose');
const bodyParser = require('body-parser');
const cors = require('cors');

const app = express();
const port = 3000;

app.use(bodyParser.json());
app.use(cors());

mongoose.connect('mongodb+srv://samir:admin@primeraapp.phez2jl.mongodb.net/?retryWrites=true&w=majority&appName=primeraApp', { useNewUrlParser: true, useUnifiedTopology: true });

const conversionSchema = new mongoose.Schema({
  tipo: String,
  cantidad: Number,
  resultado: Number
});

const Conversion = mongoose.model('Conversion', conversionSchema);

app.post('/convertir', async (req, res) => {
  const { tipo, cantidad, resultado } = req.body;

  try {
    const nuevaConversion = new Conversion({ tipo, cantidad, resultado });
    await nuevaConversion.save();
    res.status(200).send(nuevaConversion);
  } catch (error) {
    console.error('Error al guardar la conversión:', error);
    res.status(500).send({ error: 'Error al guardar la conversión' });
  }
});

app.get('/historico', async (req, res) => {
  try {
    const historico = await Conversion.find({});
    res.status(200).send(historico);
  } catch (error) {
    console.error('Error al cargar el historial:', error);
    res.status(500).send({ error: 'Error al cargar el historial' });
  }
});

app.delete('/convertir/:id', async (req, res) => {
  const { id } = req.params;

  try {
    await Conversion.findByIdAndDelete(id);
    res.status(200).send({ message: 'Conversión eliminada' });
  } catch (error) {
    console.error('Error al eliminar la conversión:', error);
    res.status(500).send({ error: 'Error al eliminar la conversión' });
  }
});

app.listen(port, () => {
  console.log(`Servidor escuchando en el puerto ${port}`);
});
