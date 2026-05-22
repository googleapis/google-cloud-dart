import 'dart:io';
import 'package:path/path.dart' as p;

const dockerTemplate = '''
FROM dart:stable AS build

WORKDIR /app

# Copy the server
COPY server .

# Start server.
EXPOSE 8080
CMD ["/app/bin/server"]
''';

class CloudRunner {
  final Uri serverUri;

  // [path] is relative to the root of the directory
  static Future<CloudRunner> start(String path) async {
    final dir = Directory.systemTemp.createTempSync();
    final serverPath = p.join(dir.absolute.path, 'server');
    final dockerPath = p.join(dir.absolute.path, 'Dockerfile');
    final sourcePath = p.join(repoRoot, path);

    final compile = await Process.run('dart', [
      'compile',
      'exe',
      '--target-os=linux',
      '--target-arch=x64',
      '--output={$serverPath}/server',
      sourcePath,
    ]);
    if (compile.exitCode != 0) {
      // TODO: Handle this case
    }

    await File(dockerPath).writeAsString(dockerTemplate);

    Directory.current = dir;
  }

  Future<void> stop() async {}
}
