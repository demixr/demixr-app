import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:flutter/services.dart';

import 'system_media_handler.dart';

/// Lets the CarPlay scene browse and play through the same media handler as
/// Android Auto. The system Now Playing template uses audio_service directly.
class CarPlayBridge {
  // The native handler is present only while a CarPlay scene is connected.
  static const _channel = OptionalMethodChannel('com.demixr.demixrApp/carplay');
  final SystemMediaHandler _mediaHandler;

  CarPlayBridge(this._mediaHandler);

  void start() {
    _channel.setMethodCallHandler(_handleCall);
    _mediaHandler.subscribeToChildren(AudioService.browsableRootId).listen((_) {
      unawaited(_channel.invokeMethod<void>('libraryChanged'));
    });
  }

  Future<Object?> _handleCall(MethodCall call) async {
    switch (call.method) {
      case 'getLibrary':
        final items = await _mediaHandler.getChildren(
          AudioService.browsableRootId,
        );
        return [
          for (final item in items)
            {'id': item.id, 'title': item.title, 'artist': item.artist},
        ];
      case 'playSong':
        return _mediaHandler.playSong(call.arguments as String);
      default:
        throw MissingPluginException();
    }
  }
}
