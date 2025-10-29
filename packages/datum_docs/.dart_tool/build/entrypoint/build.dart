// @dart=3.6
// ignore_for_file: directives_ordering
// build_runner >=2.4.16
// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:build_runner/src/build_plan/builder_factories.dart' as _i1;
import 'package:build_modules/builders.dart' as _i2;
import 'package:jaspr_builder/builder.dart' as _i3;
import 'package:jaspr_web_compilers/builders.dart' as _i4;
import 'package:source_gen/builder.dart' as _i5;
import 'dart:io' as _i6;
import 'package:build_runner/src/bootstrap/processes.dart' as _i7;

final _builderFactories = _i1.BuilderFactories(
  builderFactories: {
    'build_modules:module_library': [_i2.moduleLibraryBuilder],
    'jaspr_builder:client_module': [_i3.buildClientModule],
    'jaspr_builder:client_registry': [_i3.buildClientRegistry],
    'jaspr_builder:clients_bundle': [_i3.buildClientsBundle],
    'jaspr_builder:codec_bundle': [_i3.buildCodecBundle],
    'jaspr_builder:codec_module': [_i3.buildCodecModule],
    'jaspr_builder:import_output': [_i3.buildImportsOutput],
    'jaspr_builder:imports_module': [_i3.buildImportsModule],
    'jaspr_builder:jaspr_options': [_i3.buildJasprOptions],
    'jaspr_builder:stub': [_i3.buildPlatformStubs],
    'jaspr_builder:styles_bundle': [_i3.buildStylesBundle],
    'jaspr_builder:styles_module': [_i3.buildStylesModule],
    'jaspr_builder:sync_mixins_module': [_i3.buildSyncMixins],
    'jaspr_web_compilers:dart2js_modules': [
      _i4.dart2jsMetaModuleBuilder,
      _i4.dart2jsMetaModuleCleanBuilder,
      _i4.dart2jsModuleBuilder,
    ],
    'jaspr_web_compilers:dart2wasm_modules': [
      _i4.dart2wasmMetaModuleBuilder,
      _i4.dart2wasmMetaModuleCleanBuilder,
      _i4.dart2wasmModuleBuilder,
    ],
    'jaspr_web_compilers:ddc': [
      _i4.ddcKernelBuilder,
      _i4.ddcBuilder,
    ],
    'jaspr_web_compilers:ddc_modules': [
      _i4.ddcMetaModuleBuilder,
      _i4.ddcMetaModuleCleanBuilder,
      _i4.ddcModuleBuilder,
    ],
    'jaspr_web_compilers:entrypoint': [_i4.webEntrypointBuilder],
    'jaspr_web_compilers:entrypoint_bootstrap': [
      _i4.webEntrypointBootstrapBuilder
    ],
    'jaspr_web_compilers:sdk_js': [_i4.sdkJsCopy],
    'jaspr_web_compilers:web_plugins': [_i4.webPluginsBuilder],
    'source_gen:combining_builder': [_i5.combiningBuilder],
  },
  postProcessBuilderFactories: {
    'build_modules:module_cleanup': _i2.moduleCleanup,
    'jaspr_web_compilers:dart2js_archive_extractor':
        _i4.dart2jsArchiveExtractor,
    'jaspr_web_compilers:dart_source_cleanup': _i4.dartSourceCleanup,
    'source_gen:part_cleanup': _i5.partCleanup,
  },
);
void main(List<String> args) async {
  _i6.exitCode = await _i7.ChildProcess.run(
    args,
    _builderFactories,
  )!;
}
