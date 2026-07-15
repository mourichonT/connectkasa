// Test de régression pour la migration Phase 3 de CameraOrFiles
// (StatefulWidget -> ConsumerStatefulWidget, lib/vues/widget_view/
// components/camera_files_choices.dart) : vérifie que le widget se
// construit sous ProviderScope et que
// ref.read(storageRepositoryProvider) se résout sans erreur dans
// initState, au lieu de l'ancienne instanciation directe
// FirestoreStorageRepository(). Pas de mocktail : un faux repository
// écrit à la main suffit pour ce cas.
import 'dart:io';

import 'package:konodal/core/providers/storage_repository_provider.dart';
import 'package:konodal/core/repositories/storage_repository.dart';
import 'package:konodal/core/result/result.dart';
import 'package:konodal/vues/widget_view/components/camera_files_choices.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';

class _FakeStorageRepository implements IStorageRepository {
  @override
  Future<Result<String>> uploadImg(XFile file, String racine,
      String residence, String folderName, String fileName) async {
    return const Result.success('https://example.com/fake.png');
  }

  @override
  Future<Result<String>> uploadDocFile(
      File file,
      String racine,
      String residence,
      String folderName,
      String fileName,
      String? reflot) async {
    return const Result.success('https://example.com/fake.pdf');
  }

  @override
  Future<Result<String>> copyFile({
    required String sourceUrl,
    required String racine,
    required String residence,
    required String folderName,
    required String lotId,
    required String extension,
  }) async {
    return const Result.success('https://example.com/fake-copy.png');
  }

  @override
  Future<Result<void>> removeFolder(String racine, String folder) async {
    return const Result.success(null);
  }

  @override
  Future<Result<void>> removeFile(
    String racine,
    String residence,
    String folderName, {
    String? reflot,
    String? url,
    String? idPost,
  }) async {
    return const Result.success(null);
  }

  @override
  Future<Result<void>> deleteFolderRecursive(String path) async {
    return const Result.success(null);
  }

  @override
  Future<Result<void>> removeFileFromUrl(String url) async {
    return const Result.success(null);
  }
}

void main() {
  testWidgets(
      'CameraOrFiles se construit sous ProviderScope et affiche son état '
      'initial (régression migration ConsumerStatefulWidget)',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          storageRepositoryProvider
              .overrideWithValue(_FakeStorageRepository()),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: CameraOrFiles(
              racineFolder: 'test',
              residence: 'residence-test',
              folderName: 'folder-test',
              title: 'Test',
              cardOverlay: false,
              onImageUploaded: (_) {},
            ),
          ),
        ),
      ),
    );

    expect(find.text('Ajouter une image'), findsOneWidget);
    expect(find.byIcon(Icons.add_photo_alternate_rounded), findsOneWidget);

    // Ouvre le bottom sheet de sélection de source : vérifie que
    // l'interaction fonctionne toujours après la migration.
    await tester.tap(find.text('Ajouter une image'));
    await tester.pumpAndSettle();

    expect(find.text('Prendre une photo'), findsOneWidget);
    expect(find.text('Choisir depuis la galerie'), findsOneWidget);
  });

  testWidgets(
      'CameraOrFiles plante si instancié sans ProviderScope ancêtre '
      '(documente la dépendance introduite par la migration)',
      (tester) async {
    // Ce test échoue volontairement si CameraOrFiles est un jour utilisé
    // hors d'un ProviderScope (ex. dans un test qui pumpWidget()
    // directement le widget sans wrapper) - sert de garde-fou explicite
    // plutôt qu'un crash silencieux en profondeur.
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CameraOrFiles(
            racineFolder: 'test',
            residence: 'residence-test',
            folderName: 'folder-test',
            title: 'Test',
            cardOverlay: false,
            onImageUploaded: (_) {},
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNotNull);
  });
}
