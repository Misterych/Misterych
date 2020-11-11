// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:file/memory.dart';
import 'package:flutter_tools/src/artifacts.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/base/platform.dart';
import 'package:flutter_tools/src/base/user_messages.dart';
import 'package:flutter_tools/src/runner/local_engine.dart';
import 'package:matcher/matcher.dart';

import '../../src/common.dart';

const String kEngineRoot = '/flutter/engine';
const String kArbitraryEngineRoot = '/arbitrary/engine';
const String kDotPackages = '.packages';

void main() {
  testWithoutContext('works if --local-engine is specified and --local-engine-src-path '
    'is determined by sky_engine', () async {
    final FileSystem fileSystem = MemoryFileSystem.test();
    fileSystem
      .directory('$kArbitraryEngineRoot/src/out/ios_debug/gen/dart-pkg/sky_engine/lib/')
      .createSync(recursive: true);
    fileSystem
      .directory('$kArbitraryEngineRoot/src/out/host_debug')
      .createSync(recursive: true);
    fileSystem
      .file(kDotPackages)
      .writeAsStringSync('sky_engine:file://$kArbitraryEngineRoot/src/out/ios_debug/gen/dart-pkg/sky_engine/lib/');
    fileSystem
      .file('bin/cache/pkg/sky_engine/lib')
      .createSync(recursive: true);

    final LocalEngineLocator localEngineLocator = LocalEngineLocator(
      fileSystem: fileSystem,
      flutterRoot: '',
      logger: BufferLogger.test(),
      userMessages: UserMessages(),
      platform: FakePlatform(environment: <String, String>{}),
    );

    expect(
      await localEngineLocator.findEnginePath(null, 'ios_debug', null),
      matchesEngineBuildPaths(
        hostEngine: '/arbitrary/engine/src/out/host_debug',
        targetEngine: '/arbitrary/engine/src/out/ios_debug',
      ),
    );

    // Verify that this also works if the sky_engine path is a symlink to the engine root.
    fileSystem.link('/symlink').createSync(kArbitraryEngineRoot);
    fileSystem
      .file(kDotPackages)
      .writeAsStringSync('sky_engine:file:///symlink/src/out/ios_debug/gen/dart-pkg/sky_engine/lib/');

    expect(
      await localEngineLocator.findEnginePath(null, 'ios_debug', null),
      matchesEngineBuildPaths(
        hostEngine: '/symlink/src/out/host_debug',
        targetEngine: '/symlink/src/out/ios_debug',
      ),
    );
  });

  testWithoutContext('works if --local-engine is specified and --local-engine-src-path '
    'is specified', () async {
    final FileSystem fileSystem = MemoryFileSystem.test();
    // Intentionally do not create a package_config to verify that it is not required.
    fileSystem.directory('$kArbitraryEngineRoot/src/out/ios_debug').createSync(recursive: true);
    fileSystem.directory('$kArbitraryEngineRoot/src/out/host_debug').createSync(recursive: true);

    final LocalEngineLocator localEngineLocator = LocalEngineLocator(
      fileSystem: fileSystem,
      flutterRoot: '',
      logger: BufferLogger.test(),
      userMessages: UserMessages(),
      platform: FakePlatform(environment: <String, String>{}),
    );

    expect(
      await localEngineLocator.findEnginePath('$kArbitraryEngineRoot/src', 'ios_debug', null),
      matchesEngineBuildPaths(
        hostEngine: '/arbitrary/engine/src/out/host_debug',
        targetEngine: '/arbitrary/engine/src/out/ios_debug',
      ),
    );
  });

  testWithoutContext('works if --local-engine is specified and --local-engine-src-path '
    'is determined by flutter root', () async {
    final FileSystem fileSystem = MemoryFileSystem.test();
    fileSystem.file(kDotPackages).writeAsStringSync('\n');
    fileSystem
      .directory('$kEngineRoot/src/out/ios_debug')
      .createSync(recursive: true);
    fileSystem
      .directory('$kEngineRoot/src/out/host_debug')
      .createSync(recursive: true);
    fileSystem
      .file('bin/cache/pkg/sky_engine/lib')
      .createSync(recursive: true);

    final LocalEngineLocator localEngineLocator = LocalEngineLocator(
      fileSystem: fileSystem,
      flutterRoot: 'flutter/flutter',
      logger: BufferLogger.test(),
      userMessages: UserMessages(),
      platform: FakePlatform(environment: <String, String>{}),
    );

    expect(
      await localEngineLocator.findEnginePath(null, 'ios_debug', null),
      matchesEngineBuildPaths(
        hostEngine: 'flutter/engine/src/out/host_debug',
        targetEngine: 'flutter/engine/src/out/ios_debug',
      ),
    );
  });
}

Matcher matchesEngineBuildPaths({
  String hostEngine,
  String targetEngine,
}) {
  return const TypeMatcher<EngineBuildPaths>()
    .having((EngineBuildPaths paths) => paths.hostEngine, 'hostEngine', hostEngine)
    .having((EngineBuildPaths paths) => paths.targetEngine, 'targetEngine', targetEngine);
}
