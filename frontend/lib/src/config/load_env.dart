import 'load_env_stub.dart' if (dart.library.io) 'load_env_io.dart' as impl;

Future<void> loadRepoDotenv() => impl.loadRepoDotenv();
