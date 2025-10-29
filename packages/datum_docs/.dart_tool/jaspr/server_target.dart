  import 'package:datum_docs/main.dart' as m;
  import 'package:hotreloader/hotreloader.dart';
      
  void main() async {
    try {
      await HotReloader.create(
        debounceInterval: Duration.zero,
        onAfterReload: (ctx) => m.main(),
      );
      print('[INFO] Server hot reload is enabled.');
    } on StateError catch (e) {
      if (e.message.contains('VM service not available')) {
        print('[WARNING] Server hot reload not enabled. Run with --enable-vm-service to enable hot reload.');
      } else {
        rethrow;
      }
    }
    
    m.main();
  }
