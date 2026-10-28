import 'dart:convert';
import 'dart:io';

import 'package:corevent_work_app/core/design_system/work_widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() {
  test('textos do projeto usam UTF-8 sem sequencias corrompidas', () {
    final corrupted = RegExp(
      r'[\u00c2\u00c3][\u0080-\u00bf\u0152\u0153\u0160\u0161\u0178\u017d\u017e\u0192\u02c6\u02dc\u2013-\u2026\u2030\u2039\u203a\u20ac\u2122]'
      r'|[\u00e2\u00ef\u00f0][\u0080-\u00bf\u2013-\u2026\u2030\u2039\u203a\u20ac\u2122]{2}'
      r'|\ufffd',
    );
    final files = <File>[
      for (final path in ['lib', 'test', 'android/app/src', '.vscode'])
        ...Directory(path)
            .listSync(recursive: true, followLinks: false)
            .whereType<File>()
            .where(
              (file) => ['.dart', '.xml', '.json'].any(file.path.endsWith),
            ),
      File('README.md'),
      File('pubspec.yaml'),
      File('analysis_options.yaml'),
    ];
    for (final file in files) {
      final content = utf8.decode(
        file.readAsBytesSync(),
        allowMalformed: false,
      );
      expect(corrupted.hasMatch(content), isFalse, reason: file.path);
    }
  });

  test('datas preservam o separador e os acentos em portugues', () async {
    await initializeDateFormatting('pt_BR');
    final date = DateTime(2026, 3, 10, 14, 30);
    expect(shortDate(date), contains('\u00b7'));
    expect(fullDate(date), contains('mar\u00e7o \u00b7 14:30'));
  });
}
