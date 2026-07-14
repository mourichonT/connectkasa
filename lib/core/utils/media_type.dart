const List<String> videoExtensions = ['mp4', 'mov', 'm4v'];

bool isVideoExtension(String extension) {
  return videoExtensions.contains(extension.toLowerCase());
}

/// Déduit si une URL Firebase Storage pointe vers une vidéo à partir de son
/// extension (avant les paramètres de requête `?alt=media&token=...`).
bool isVideoUrl(String? url) {
  if (url == null || url.isEmpty) return false;
  final withoutQuery = url.split('?').first;
  final extension = withoutQuery.split('.').last.toLowerCase();
  return isVideoExtension(extension);
}
