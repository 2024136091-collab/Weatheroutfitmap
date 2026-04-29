// ignore: avoid_web_libraries_in_flutter
import 'dart:async';
// ignore: avoid_web_libraries_in_flutter
import 'dart:js' as js;

Future<String?> signInWithGoogleWeb() {
  final completer = Completer<String?>();

  js.context['_flutterGoogleTokenCb'] = js.allowInterop((dynamic token) {
    if (!completer.isCompleted) {
      completer.complete(token as String?);
    }
  });

  js.context.callMethod('eval', [r'''
    (function tryInit() {
      if (typeof google === 'undefined' || !google.accounts || !google.accounts.oauth2) {
        setTimeout(tryInit, 300);
        return;
      }
      try {
        var client = google.accounts.oauth2.initTokenClient({
          client_id: "440354179334-1fq5m5uaqj9kin549lga5gpvd6cscvei.apps.googleusercontent.com",
          scope: "email profile",
          callback: function(tokenResponse) {
            if (tokenResponse && tokenResponse.access_token) {
              if (window._flutterGoogleTokenCb) window._flutterGoogleTokenCb(tokenResponse.access_token);
            } else {
              if (window._flutterGoogleTokenCb) window._flutterGoogleTokenCb(null);
            }
          },
          error_callback: function(err) {
            console.error('Google OAuth error:', JSON.stringify(err));
            if (window._flutterGoogleTokenCb) window._flutterGoogleTokenCb(null);
          }
        });
        client.requestToken();
      } catch(e) {
        console.error('GIS error:', e.message || e);
        if (window._flutterGoogleTokenCb) window._flutterGoogleTokenCb(null);
      }
    })();
  ''']);

  return completer.future.timeout(
    const Duration(minutes: 3),
    onTimeout: () => null,
  );
}

void cancelGoogleSignIn() {
  try {
    js.context.callMethod('eval', [r'''
      try { google.accounts.oauth2.revoke('', function(){}); } catch(e) {}
    ''']);
  } catch (_) {}
}