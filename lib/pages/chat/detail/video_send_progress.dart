int mapVideoCompressionProgress(double progress) {
  final normalized = progress.clamp(0, 100).toDouble();
  return (normalized * 0.4).round().clamp(0, 40);
}

int mapVideoUploadProgress({
  required int videoSent,
  required int videoTotal,
  required int coverSent,
  required int coverTotal,
}) {
  final total = videoTotal + coverTotal;
  if (total <= 0) {
    return 40;
  }

  final sent = (videoSent + coverSent).clamp(0, total);
  return (40 + (sent / total * 50).round()).clamp(40, 90);
}

int mapVideoImSendProgress(int progress) {
  final normalized = progress.clamp(0, 100);
  return (90 + (normalized * 0.09).floor()).clamp(90, 99);
}

int normalizeVideoSendProgress(int progress) {
  return progress.clamp(0, 100);
}

bool shouldNotifyVideoSendProgress({
  required int previousProgress,
  required int nextProgress,
  bool statusChanged = false,
}) {
  return statusChanged ||
      normalizeVideoSendProgress(previousProgress) !=
          normalizeVideoSendProgress(nextProgress);
}

String? normalizeVideoRemoteUrl(String? remote) {
  final value = remote?.trim();
  if (value == null || value.isEmpty) {
    return null;
  }

  return value;
}

bool isSamePendingVideoRemote({
  required String? pendingRemote,
  required String? incomingRemote,
}) {
  final pending = normalizeVideoRemoteUrl(pendingRemote);
  final incoming = normalizeVideoRemoteUrl(incomingRemote);
  return pending != null && incoming != null && pending == incoming;
}
