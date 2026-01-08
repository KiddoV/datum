import 'package:datum/datum.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

final simpleDatumProvider = Provider.autoDispose<Datum>(
  (ref) => throw UnimplementedError(""),
  name: "simpleDatumProvider",
);
