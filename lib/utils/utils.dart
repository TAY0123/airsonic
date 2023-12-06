String printDuration(Duration duration) {
  String twoDigits(int n) => n.toString().padLeft(2, "0");
  String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
  String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
  if (duration.inHours > 0) {
    return "${twoDigits(duration.inHours)}:$twoDigitMinutes:$twoDigitSeconds";
  } else {
    return "$twoDigitMinutes:$twoDigitSeconds";
  }
}

/// Metadata of an audio item that can be played, or a folder containing
/// audio items.
class MediaItem {
  /// A unique id.
  final String id;

  /// The title of this media item.
  final String title;

  /// The album this media item belongs to.
  final String? album;

  /// The artist of this media item.
  final String? artist;

  /// The genre of this media item.
  final String? genre;

  /// The duration of this media item.
  final Duration? duration;

  /// The artwork URI for this media item.
  ///
  /// Supported types of URIs are:
  ///
  ///  * File - file://
  ///  * Network - http:// https:// etc.
  ///  * Android content URIs - content://
  ///
  /// ## Speeding up Android content URI loading
  ///
  /// For Android content:// URIs, the plugin by default uses
  /// `ContentResolver.openFileDescriptor`, which takes the direct URI of an
  /// image.
  ///
  /// On Android API >= 29 there is `ContentResolver.loadThumbnail` function
  /// which takes a URI of some content (for example, a song from `MediaStore`),
  /// and returns a thumbnail for it.
  ///
  /// It is noticeably faster to use this function. You can enable this by
  /// putting a `loadThumbnailUri` key into the [extras]. If `loadThumbnail` is
  /// not available, it will just fallback to using `openFileDescriptor`.
  final Uri? artUri;

  /// The HTTP headers to use when sending an HTTP request for [artUri].
  final Map<String, String>? artHeaders;

  /// Whether this is playable (i.e. not a folder).
  final bool? playable;

  /// Override the default title for display purposes.
  final String? displayTitle;

  /// Override the default subtitle for display purposes.
  final String? displaySubtitle;

  /// Override the default description for display purposes.
  final String? displayDescription;

  /// A map of additional metadata for the media item.
  ///
  /// The values must be of type `int`, `String`, `bool` or `double`.
  final Map<String, dynamic>? extras;

  /// Creates a [MediaItem].
  ///
  /// The [id] must be unique for each instance.
  const MediaItem({
    required this.id,
    required this.title,
    this.album,
    this.artist,
    this.genre,
    this.duration,
    this.artUri,
    this.artHeaders,
    this.playable = true,
    this.displayTitle,
    this.displaySubtitle,
    this.displayDescription,
    this.extras,
  });
}
