
import 'dart:io';
import 'package:llama_cpp_dart/llama_cpp_dart.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../main.dart';
import '../models/teach_settings.dart';

class LocalModelInfo {
  final String id;
  final String name;
  final String url;
  final int sizeBytes;
  final String sha256;
  const LocalModelInfo({
    required this.id,
    required this.name,
    required this.url,
    required this.sizeBytes,
    this.sha256 = '',
  });
}

/// Example model list (swap URLs/hashes as needed).
const availableLocalModels = [
  LocalModelInfo(
    id: 'tiny-3b-q4_0',
    name: 'Tiny 3B Q4_0 (~1.6GB)',
    url:
        'https://huggingface.co/TheBloke/TinyLlama-1.1B-Chat-v1.0-GGUF/resolve/main/tinyllama-1.1b-chat-v1.0.Q4_K_M.gguf',
    sizeBytes: 1600000000,
  ),
];

class LocalModelManager {
  Future<Directory> _modelDir() async {
    final dir = await getApplicationDocumentsDirectory();
    final models = Directory(p.join(dir.path, 'local_models'));
    if (!models.existsSync()) {
      models.createSync(recursive: true);
    }
    return models;
  }

  Future<bool> isInstalled(LocalModelInfo model) async {
    final dir = await _modelDir();
    return File(p.join(dir.path, '${model.id}.gguf')).exists();
    }

  Future<String?> installedPath(LocalModelInfo model) async {
    final dir = await _modelDir();
    final path = p.join(dir.path, '${model.id}.gguf');
    return File(path).existsSync() ? path : null;
  }

  Future<void> remove(LocalModelInfo model) async {
    final dir = await _modelDir();
    final file = File(p.join(dir.path, '${model.id}.gguf'));
    if (await file.exists()) {
      await file.delete();
    }
  }

  /// Simple downloader using HttpClient; call [onProgress] with 0..1.
  Future<String> download(LocalModelInfo model, void Function(double) onProgress) async {
    final dir = await _modelDir();
    final tmpPath = p.join(dir.path, '${model.id}.part');
    final finalPath = p.join(dir.path, '${model.id}.gguf');

    final uri = Uri.parse(model.url);
    final client = HttpClient();
    final req = await client.getUrl(uri);
    final resp = await req.close();
    if (resp.statusCode != 200) {
      throw Exception('Download failed: ${resp.statusCode}');
    }

    final sink = File(tmpPath).openWrite();
    int downloaded = 0;
    final total = model.sizeBytes > 0 ? model.sizeBytes : resp.contentLength;
    await for (final chunk in resp) {
      downloaded += chunk.length;
      sink.add(chunk);
      if (total > 0) {
        onProgress(downloaded / total);
      }
    }
    await sink.close();
    await File(tmpPath).rename(finalPath);
    onProgress(1);
    return finalPath;
  }
}

class TeachService {
  final _modelManager = LocalModelManager();
  final _runtime = LlamaRuntime();

  Future<TeachSettings> loadSettings() async {
    final existing = await isar.collection<TeachSettings>().get(0);
    if (existing != null) return existing;
    final defaults = TeachSettings();
    await isar.writeTxn(() async => isar.collection<TeachSettings>().put(defaults));
    return defaults;
  }

  Future<void> saveSettings(TeachSettings settings) async {
    await isar.writeTxn(() async => isar.collection<TeachSettings>().put(settings));
  }

  LocalModelManager get modelManager => _modelManager;

  Future<String> critiqueLocally({
    required String explanation,
    required String topic,
    String audience = 'peer',
    String? modelId,
  }) async {
    final id = modelId ?? availableLocalModels.first.id;
    final info = availableLocalModels.firstWhere((m) => m.id == id, orElse: () => availableLocalModels.first);
    final path = await _modelManager.installedPath(info);
    if (path == null) throw Exception("Model not installed");
    await _runtime.load(path);

    final prompt = """
You are a concise tutor. Critique the explanation below for clarity, accuracy, and completeness. Topic: $topic. Audience: $audience.

Explanation:
$explanation

Respond with:
Clarity: x/10
Accuracy: x/10
Completeness: x/10

Feedback: bullet points, brief.
Follow-ups: 2-3 suggested questions.
""";

    try {
      final result = await _runtime.generate(prompt);
      return result;
    } catch (e) {
      return "Failed to run local model: $e";
    }
  }
}

final teachService = TeachService();

class LlamaRuntime {
  Llama? _llama;
  String? _loadedPath;
  String? _libPath;

  String? _findLibrary() {
    if (_libPath != null) return _libPath;
    final cwd = Directory.current.path;
    final exeDir = p.dirname(Platform.resolvedExecutable);
    final candidates = [
      p.join(cwd, 'llama.dll'),
      p.join(cwd, 'bin', 'llama.dll'),
      p.join(exeDir, 'llama.dll'),
      p.join(exeDir, 'bin', 'llama.dll'),
    ];
    for (final candidate in candidates) {
      if (File(candidate).existsSync()) {
        _libPath = candidate;
        return _libPath;
      }
    }
    return null;
  }

  Future<void> load(String path) async {
    if (_loadedPath == path && _llama != null) return;
    _llama?.dispose();
    final libPath = _findLibrary();
    if (libPath == null) {
      throw Exception("llama.dll not found in current directory or bin/ subfolder");
    }
    Llama.libraryPath = libPath;
    _llama = Llama(path, null, ContextParams()
      ..nCtx = 2048
      ..nPredict = 256);
    _loadedPath = path;
  }

  Future<String> generate(String prompt) async {
    final llama = _llama;
    if (llama == null) throw Exception("Model not loaded");
    try {
      llama.setPrompt(prompt);
      final buffer = StringBuffer();
      await for (final chunk in llama.generateText()) {
        buffer.write(chunk);
      }
      return buffer.toString();
    } catch (e) {
      rethrow;
    }
  }
}
