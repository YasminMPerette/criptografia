import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:encrypt/encrypt.dart' as encrypt;

void main() {
  runApp(const CofreApp());
}

class CofreApp extends StatelessWidget {
  const CofreApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Cofrinho de Recados',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.indigo),
      home: const CofrePage(),
    );
  }
}

class CofrePage extends StatefulWidget {
  const CofrePage({super.key});

  @override
  State<CofrePage> createState() => _CofrePageState();
}

class _CofrePageState extends State<CofrePage> {
  final TextEditingController _controller = TextEditingController();
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  final _key = encrypt.Key.fromUtf8('1234567890123456'); // 16 chars
  final _iv = encrypt.IV.fromLength(16);
  late final encrypt.Encrypter _encrypter;

  String? _recadoCriptografado;
  String? _recadoDescriptografado;

  @override
  void initState() {
    super.initState();
    _encrypter = encrypt.Encrypter(encrypt.AES(_key));
  }

  String _criptografar(String texto) {
    final encrypted = _encrypter.encrypt(texto, iv: _iv);
    return encrypted.base64;
  }

  String _descriptografar(String texto) {
    return _encrypter.decrypt64(texto, iv: _iv);
  }

  Future<void> _salvarRecado() async {
    final texto = _controller.text;
    if (texto.isEmpty) return;

    final criptografado = _criptografar(texto);
    await _secureStorage.write(key: 'recado', value: criptografado);

    setState(() {
      _recadoCriptografado = criptografado;
      _recadoDescriptografado = null;
    });

    _controller.clear();
  }

  Future<void> _lerRecado() async {
    final criptografado = await _secureStorage.read(key: 'recado');
    if (criptografado == null) return;

    final textoOriginal = _descriptografar(criptografado);

    setState(() {
      _recadoCriptografado = criptografado;
      _recadoDescriptografado = textoOriginal;
    });
  }

  Future<void> _apagarRecado() async {
    await _secureStorage.delete(key: 'recado');

    setState(() {
      _recadoCriptografado = null;
      _recadoDescriptografado = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('🔐 Cofrinho de Recados')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _controller,
              decoration: const InputDecoration(
                labelText: 'Digite seu recado secreto',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                ElevatedButton.icon(
                  onPressed: _salvarRecado,
                  icon: const Icon(Icons.lock),
                  label: const Text('Salvar'),
                ),
                ElevatedButton.icon(
                  onPressed: _lerRecado,
                  icon: const Icon(Icons.lock_open),
                  label: const Text('Ler'),
                ),
                ElevatedButton.icon(
                  onPressed: _apagarRecado,
                  icon: const Icon(Icons.delete),
                  label: const Text('Apagar'),
                  style: ElevatedButton.styleFrom(backgroundColor: const Color.fromARGB(255, 244, 231, 54)),
                ),
              ],
            ),
            const SizedBox(height: 24),
            if (_recadoCriptografado != null)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('🔒 Recado criptografado:',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  Text(_recadoCriptografado!),
                  const SizedBox(height: 16),
                ],
              ),
            if (_recadoDescriptografado != null)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('🔓 Recado original:',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  Text(_recadoDescriptografado!),
                ],
              ),
          ],
        ),
      ),
    );
  }
}