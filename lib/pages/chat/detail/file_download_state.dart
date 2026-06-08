import 'dart:convert';

enum FileDownloadStatus { idle, downloading, downloaded, failed }

class FileDownloadState {
  const FileDownloadState({
    this.status = FileDownloadStatus.idle,
    this.progress = 0,
    this.localPath,
  });

  final FileDownloadStatus status;
  final int progress;
  final String? localPath;

  FileDownloadState copyWith({
    FileDownloadStatus? status,
    int? progress,
    String? localPath,
  }) {
    return FileDownloadState(
      status: status ?? this.status,
      progress: progress ?? this.progress,
      localPath: localPath ?? this.localPath,
    );
  }
}

String sanitizeChatFileName(String? fileName) {
  final value = fileName?.trim();
  if (value == null || value.isEmpty) {
    return 'downloaded_file';
  }

  final sanitized = value
      .replaceAll(RegExp(r'[\\/:*?"<>|]'), '_')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();

  return sanitized.isEmpty ? 'downloaded_file' : sanitized;
}

String buildChatFileDownloadPath({
  required String directoryPath,
  required String messageId,
  required String? remoteUrl,
  required String? fileName,
}) {
  final safeName = sanitizeChatFileName(fileName);
  final stableKey = _stableFileKey(messageId: messageId, remoteUrl: remoteUrl);
  final normalizedDirectory = directoryPath.endsWith('/')
      ? directoryPath.substring(0, directoryPath.length - 1)
      : directoryPath;

  return '$normalizedDirectory/$stableKey-$safeName';
}

bool isUsableLocalFilePath(String? path) {
  final value = path?.trim();
  if (value == null || value.isEmpty) {
    return false;
  }

  return !value.startsWith('http://') && !value.startsWith('https://');
}

int mapFileDownloadProgress({required int received, required int total}) {
  if (total <= 0) {
    return 0;
  }

  final normalizedReceived = received.clamp(0, total);
  return (normalizedReceived / total * 100).round().clamp(0, 100);
}

String _stableFileKey({required String messageId, required String? remoteUrl}) {
  final source = remoteUrl?.trim().isNotEmpty == true
      ? remoteUrl!.trim()
      : messageId.trim();
  if (source.isEmpty) {
    return 'file';
  }

  final bytes = utf8.encode(source);
  final base64 = base64UrlEncode(bytes).replaceAll('=', '');

  if (base64.length <= 24) {
    return base64;
  }

  return base64.substring(0, 24);
}
