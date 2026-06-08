int mapFileUploadProgress({required int sent, required int total}) {
  if (total <= 0) {
    return 0;
  }

  final normalizedSent = sent.clamp(0, total);
  return (normalizedSent / total * 90).round().clamp(0, 90);
}

int mapFileImSendProgress(int progress) {
  final normalized = progress.clamp(0, 100);
  return (90 + (normalized * 0.09).floor()).clamp(90, 99);
}

int normalizeFileSendProgress(int progress) {
  return progress.clamp(0, 100);
}

bool shouldNotifyFileSendProgress({
  required int previousProgress,
  required int nextProgress,
  bool statusChanged = false,
}) {
  return statusChanged ||
      normalizeFileSendProgress(previousProgress) !=
          normalizeFileSendProgress(nextProgress);
}

String? normalizeFileRemoteUrl(String? remote) {
  final value = remote?.trim();
  if (value == null || value.isEmpty) {
    return null;
  }

  return value;
}

bool isSamePendingFileRemote({
  required String? pendingRemote,
  required String? incomingRemote,
}) {
  final pending = normalizeFileRemoteUrl(pendingRemote);
  final incoming = normalizeFileRemoteUrl(incomingRemote);
  return pending != null && incoming != null && pending == incoming;
}
