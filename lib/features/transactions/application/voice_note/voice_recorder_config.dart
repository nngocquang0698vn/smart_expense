class VoiceRecorderConfig {
  const VoiceRecorderConfig({
    required this.sessionId,
    required this.maxDuration,
  });

  final Object sessionId;
  final Duration maxDuration;

  @override
  bool operator ==(Object other) {
    return other is VoiceRecorderConfig &&
        identical(other.sessionId, sessionId) &&
        other.maxDuration == maxDuration;
  }

  @override
  int get hashCode => Object.hash(identityHashCode(sessionId), maxDuration);
}
