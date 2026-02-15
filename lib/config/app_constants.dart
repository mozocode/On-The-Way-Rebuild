class AppConstants {
  static const String appName = 'OTW';
  static const String appVersion = '1.0.0';
  static const List<int> dispatchWaveRadii = [2, 3, 5, 7, 9];
  static const int dispatchWaveDuration = 20;
  static const int maxDispatchAttempts = 5;
  static const double defaultLatitude = 40.7128;
  static const double defaultLongitude = -74.0060;
  static const int locationUpdateInterval = 5;
  static const int locationDistanceFilter = 5;
  static const int apiTimeout = 30;
  static const int routeRefreshInterval = 120;
  static const double arrivalThreshold = 50;
  static const double stepAdvanceThreshold = 50;
  static const int maxSavedLocations = 10;
  static const int serviceFeePercent = 10;
  static const int markerAnimationDuration = 1000;
  static const int pageTransitionDuration = 300;
}
