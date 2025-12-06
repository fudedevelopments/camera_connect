/// Connection status entity
enum ConnectionStatus {
  disconnected,
  connecting,
  connected,
  error;

  String get displayName {
    switch (this) {
      case ConnectionStatus.disconnected:
        return 'Disconnected';
      case ConnectionStatus.connecting:
        return 'Connecting...';
      case ConnectionStatus.connected:
        return 'Connected';
      case ConnectionStatus.error:
        return 'Error';
    }
  }

  bool get isConnected => this == ConnectionStatus.connected;
  bool get isConnecting => this == ConnectionStatus.connecting;
  bool get isDisconnected => this == ConnectionStatus.disconnected;
  bool get hasError => this == ConnectionStatus.error;
}
