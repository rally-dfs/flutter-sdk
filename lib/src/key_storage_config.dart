class KeyStorageConfig {
  bool saveToCloud;
  bool rejectOnCloudSaveFailure;

  KeyStorageConfig({
    required this.saveToCloud,
    required this.rejectOnCloudSaveFailure,
  });
}
