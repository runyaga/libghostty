import 'dart:io';
import 'dart:ui' as ui;

final _fontsDir =
    '${Directory.current.path}${Platform.pathSeparator}test'
    '${Platform.pathSeparator}fixtures${Platform.pathSeparator}fonts';

Future<void> loadBundledFonts() async {
  await _load('JetBrainsMono-Regular.ttf', 'JetBrains Mono');
  await _load('JetBrainsMono-Bold.ttf', 'JetBrains Mono');
  await _load('NotoEmoji-Regular.ttf', 'Noto Emoji');
  await _load('NotoSansJP-Regular.ttf', 'Noto Sans JP');
}

Future<void> _load(String filename, String family) async {
  final path = '$_fontsDir${Platform.pathSeparator}$filename';
  await ui.loadFontFromList(File(path).readAsBytesSync(), fontFamily: family);
}
