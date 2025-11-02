import 'package:datum/datum.dart';
import 'package:example/data/task/entity/task.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';


class DatumProviderWithLifecycle extends ConsumerStatefulWidget {
  final Widget child;

  const DatumProviderWithLifecycle({super.key, required this.child});

  @override
  DatumProviderWithLifecycleState createState() =>
      DatumProviderWithLifecycleState();
}

class DatumProviderWithLifecycleState
    extends ConsumerState<DatumProviderWithLifecycle>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    Datum.instance.pause();
    Datum.instance.resume();
    Datum.manager<Task>().remoteAdapter.readAll();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
