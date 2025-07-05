import 'dart:io';

import 'package:path/path.dart'
    as p; // Import the path package for robust path joining
import 'package:rename/platform_file_editors/android_platform_file_editor.dart';
import 'package:test/test.dart';

// Minimal TestAndroidPlatformFileEditor based on the structure from your problem description
// This assumes the original AndroidPlatformFileEditor has a getter for the path.
class TestAndroidPlatformFileEditor extends AndroidPlatformFileEditor {
  final String _mockPath;

  TestAndroidPlatformFileEditor({required String mockPath})
      : _mockPath = mockPath;

  @override
  String get androidAppBuildGradlePathKts => _mockPath;
}

void main() {
  group('AndroidPlatformFileEditor', () {
    late Directory tempDir;
    late String copiedMockGradleFilePath;

    setUpAll(() async {
      tempDir = await Directory.systemTemp.createTemp('editor_test_');
      final sourceFile =
          File('test/test.build.gradle.tks'); // Your source mock file

      // Ensure the source file exists before trying to copy
      if (!await sourceFile.exists()) {
        throw FileSystemException(
            "Source mock file not found", sourceFile.path);
      }

      // Define the destination path including the filename
      // Using p.basename to get the original filename is a good practice
      final destinationFileName = p.basename(sourceFile.path);
      copiedMockGradleFilePath = p.join(tempDir.path, destinationFileName);

      // Now copy to the full destination path
      await sourceFile.copy(copiedMockGradleFilePath);
      print('Copied mock gradle file to: $copiedMockGradleFilePath');
    });

    tearDownAll(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
        print('Deleted temporary directory: ${tempDir.path}');
      }
    });

    group('AndroidPlatformFileEditor', () {
      group('getBundleId', () {
        test('should retrieve the correct bundleId from the copied mock file',
            () async {
          final platformFileEditor =
              TestAndroidPlatformFileEditor(mockPath: copiedMockGradleFilePath);

          const expectedBundleId = 'com.test.qa';

          final String? actualBundleId = await platformFileEditor.getBundleId();

          expect(actualBundleId, isNotNull);
          expect(actualBundleId, equals(expectedBundleId));
        });
      });
      group('setBundleId', () {
        test('should update the bundleId in the copied mock file', () async {
          final platformFileEditor =
              TestAndroidPlatformFileEditor(mockPath: copiedMockGradleFilePath);

          const newBundleId = 'com.updated.test';

          // Call the method under test
          await platformFileEditor.setBundleId(bundleId: newBundleId);

          // Read the file content back to verify the change
          final updatedFileContent = await File(copiedMockGradleFilePath).readAsString();
          final validPatterns = [
            'applicationId = "$newBundleId"',
            'applicationId "$newBundleId"',
            "applicationId = '$newBundleId'",
            "applicationId '$newBundleId'",
          ];
          final matchFound = validPatterns.any(updatedFileContent.contains);
          expect(matchFound, isTrue);

          // Optionally, confirm using getBundleId
          final actualBundleId = await platformFileEditor.getBundleId();
          expect(actualBundleId, equals(newBundleId));
        });
      });
    });
  });
}
