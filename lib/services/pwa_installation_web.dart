import 'dart:html' as html;
import 'dart:js_interop';

@JS('window.studiaPwaIsStandalone')
external bool _studiaPwaIsStandalone();

@JS('window.studiaPwaIsIOS')
external bool _studiaPwaIsIOS();

@JS('window.studiaPwaCanInstall')
external bool _studiaPwaCanInstall();

@JS('window.studiaPwaPromptInstall')
external JSPromise<JSString> _studiaPwaPromptInstall();

typedef PwaInstallChanged = void Function();

class PwaInstallation {
  PwaInstallation({required this.onChanged}) {
    html.window.addEventListener('studia-pwa-install-change', _handleChange);
  }

  final PwaInstallChanged onChanged;

  void _handleChange(html.Event _) => onChanged();

  bool get isWeb => true;

  bool get isStandalone => _studiaPwaIsStandalone();

  bool get isIOS => _studiaPwaIsIOS();

  bool get canInstall => _studiaPwaCanInstall();

  Future<bool> promptInstall() async {
    final result = await _studiaPwaPromptInstall().toDart;
    return result.toDart == 'accepted';
  }

  void dispose() {
    html.window.removeEventListener('studia-pwa-install-change', _handleChange);
  }
}
