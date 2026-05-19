import 'package:google_cloud_logging/google_cloud_logging.dart';
import 'package:logging/logging.dart';

void main() {
  const cloudLogger = CloudLogger.structuredLogger();
  Logger.root.onRecord.listen(cloudLogger.handleLog);
  Logger.root.level = Level.ALL;

  Logger('MyClassName').fine('Starting file copy.');
}
