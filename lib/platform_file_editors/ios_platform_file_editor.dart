/// File: ios_platform_file_editor.dart
/// Project: rename
/// Author: Onat Cipli
/// Created Date: 24.09.2023
/// Description: This file is responsible for editing iOS platform files.

// ignore_for_file: unused_local_variable

import 'package:rename/enums.dart';
import 'package:rename/platform_file_editors/abs_platform_file_editor.dart';

/// [IosPlatformFileEditor] is responsible for editing iOS platform files.
/// Attributes:
/// - [iosInfoPlistPath]: Path to the iOS Info.plist file.
/// - [iosProjectPbxprojPath]: Path to the iOS project.pbxproj file.
class IosPlatformFileEditor extends AbstractPlatformFileEditor {
  String iosInfoPlistPath = AbstractPlatformFileEditor.convertPath(
    ['ios', 'Runner', 'Info.plist'],
  );
  String iosProjectPbxprojPath = AbstractPlatformFileEditor.convertPath(
    ['ios', 'Runner.xcodeproj', 'project.pbxproj'],
  );

  /// Creates an instance of [IosPlatformFileEditor].
  IosPlatformFileEditor({
    RenamePlatform platform = RenamePlatform.ios,
  }) : super(platform: platform);

  /// Fetches the app name from the iOS Info.plist file.
  ///
  /// Returns: Future<String?>, the app name if found, null otherwise.
  @override
  Future<String?> getAppName() async {
    final filePath = iosInfoPlistPath;
    var contentLineByLine = await readFileAsLineByline(
      filePath: filePath,
    );
    for (var i = 0; i < contentLineByLine.length; i++) {
      if (contentLineByLine[i]?.contains('<key>CFBundleName</key>') ?? false) {
        var match = RegExp(r'<string>(.*?)</string>')
            .firstMatch(contentLineByLine[i + 1]!);
        return match?.group(1)?.trim();
      }
    }
    return null;
  }

  /// Fetches the bundle ID from the iOS project.pbxproj file.
  ///
  /// Returns: Future<String?>, the bundle ID if found, null otherwise.
  @override
  Future<String?> getBundleId() async {
    final filePath = iosProjectPbxprojPath;
    var contentLineByLine = await readFileAsLineByline(filePath: filePath);
    var isInBuildSettings = false;
    var isInCorrectBuildSettings = false;

    String? bundleId;
    for (var line in contentLineByLine) {
      if (line == null) continue;

      if (!isInBuildSettings && line.contains('buildSettings = {')) {
        isInCorrectBuildSettings = false;
        isInBuildSettings = true;
        bundleId = null;
        continue;
      }

      if (!isInBuildSettings) continue;

      if (line.contains('INFOPLIST_FILE = Runner/Info.plist')) {
        isInCorrectBuildSettings = true;
        continue;
      }

      if (line.contains('PRODUCT_BUNDLE_IDENTIFIER')) {
        bundleId = line.split('=').last.trim().replaceAll(';', '').trim();
        continue;
      }

      if (line.contains('};')) {
        if (isInCorrectBuildSettings && bundleId != null) return bundleId;
        bundleId = null;
        isInCorrectBuildSettings = false;
        isInBuildSettings = false;
      }
    }

    return null;
  }

  /// Sets the app name in the iOS Info.plist file.
  ///
  /// Parameters:
  /// - `appName`: The new app name to be set for the application.
  ///
  /// Returns: Future<String?>, a success message indicating the change in app name.
  @override
  Future<String?> setAppName({required String appName}) async {
    final filePath = iosInfoPlistPath;
    List? contentLineByLine = await readFileAsLineByline(
      filePath: filePath,
    );
    for (var i = 0; i < contentLineByLine.length; i++) {
      if (contentLineByLine[i].contains('<key>CFBundleName</key>')) {
        contentLineByLine[i + 1] = '\t<string>$appName</string>\r';
        break;
      }
    }

    for (var i = 0; i < contentLineByLine.length; i++) {
      if (contentLineByLine[i].contains('<key>CFBundleDisplayName</key>')) {
        contentLineByLine[i + 1] = '\t<string>$appName</string>\r';
        break;
      }
    }

    final message = await super.setAppName(appName: appName);
    var writtenFile = await writeFile(
      filePath: filePath,
      content: contentLineByLine.join('\n'),
    );
    return message;
  }

  /// Sets the bundle ID in the iOS project.pbxproj file.
  ///
  /// Parameters:
  /// - `bundleId`: The new Bundle ID to be set for the application.
  ///
  /// Returns: Future<String?>, a success message indicating the change in Bundle ID.
  @override
  Future<String?> setBundleId({required String bundleId}) async {
    final filePath = iosProjectPbxprojPath;
    var contentLineByLine = await readFileAsLineByline(
      filePath: filePath,
    );

    final mainBundleId = await getBundleId();
    if (mainBundleId == null) return null;

    final newContentLineByLine = contentLineByLine.map(
        (line) {
          if (line == null) return line;
          if (line.contains('PRODUCT_BUNDLE_IDENTIFIER')) {
            line = line.replaceAll(mainBundleId, bundleId);
          }
          return line;
        }
    ).toList();

    final message = await super.setBundleId(bundleId: bundleId);
    var writtenFile = await writeFile(
      filePath: filePath,
      content: newContentLineByLine.join('\n'),
    );
    return message;
  }
}
