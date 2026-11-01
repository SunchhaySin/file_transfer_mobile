class Metrics {
  static final Stopwatch _sw = Stopwatch();
  static final Set<String> _logged = {};
  static final List<String> entries = [];

  static void markAppStart() => _sw.start();

  // Logs the time since app start, once per name
  static void mark(String name) {
    if (!_logged.add(name)) return;
    log(name, _sw.elapsedMilliseconds);
  }

  static void log(String name, int ms) {
    final line = '$name=$ms';
    entries.add(line);
    print('METRIC $line');
  }
}