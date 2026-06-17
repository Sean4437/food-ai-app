enum GallerySaveStatus {
  saved,
  disabled,
  notSupported,
  permissionDenied,
  failed,
}

class GallerySaveResult {
  const GallerySaveResult(this.status, {this.errorMessage});

  final GallerySaveStatus status;
  final String? errorMessage;

  bool get isSuccess => status == GallerySaveStatus.saved;
  bool get shouldNotifyFailure =>
      status == GallerySaveStatus.permissionDenied ||
      status == GallerySaveStatus.failed;
}
