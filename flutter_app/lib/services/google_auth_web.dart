import 'dart:js_interop';

@JS('getGoogleToken')
external JSPromise<JSString> _getGoogleTokenJs(JSString clientId);

Future<String?> getGoogleAccessToken(String clientId) async {
  final result = await _getGoogleTokenJs(clientId.toJS).toDart;
  return result.toDart;
}