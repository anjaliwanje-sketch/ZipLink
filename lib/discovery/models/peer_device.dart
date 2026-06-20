class PeerDevice {
  final String id;
  final String name;
  final String? ipAddress;
  final String protocolType;
  final int signalStrength;

  PeerDevice({
    required this.id,
    required this.name,
    this.ipAddress,
    required this.protocolType,
    required this.signalStrength,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PeerDevice && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
