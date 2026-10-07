typedef PwaInstallChanged = void Function();

class PwaInstallation {
  PwaInstallation({required this.onChanged});

  final PwaInstallChanged onChanged;

  bool get isWeb => false;
  bool get isStandalone => false;
  bool get isIOS => false;
  bool get canInstall => false;

  Future<bool> promptInstall() async => false;

  void dispose() {}
}
