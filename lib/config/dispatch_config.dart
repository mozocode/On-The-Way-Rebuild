class WaveConfig {
  final int waveNumber;
  final double minRadiusMiles;
  final double maxRadiusMiles;
  final int timeoutSeconds;
  final int maxHeroesPerWave;

  const WaveConfig({
    required this.waveNumber,
    required this.minRadiusMiles,
    required this.maxRadiusMiles,
    required this.timeoutSeconds,
    required this.maxHeroesPerWave,
  });
}

class DispatchConfig {
  static const List<WaveConfig> waves = [
    WaveConfig(waveNumber: 1, minRadiusMiles: 0, maxRadiusMiles: 2, timeoutSeconds: 30, maxHeroesPerWave: 10),
    WaveConfig(waveNumber: 2, minRadiusMiles: 2, maxRadiusMiles: 5, timeoutSeconds: 45, maxHeroesPerWave: 15),
    WaveConfig(waveNumber: 3, minRadiusMiles: 5, maxRadiusMiles: 10, timeoutSeconds: 60, maxHeroesPerWave: 20),
    WaveConfig(waveNumber: 4, minRadiusMiles: 10, maxRadiusMiles: 25, timeoutSeconds: 90, maxHeroesPerWave: 30),
  ];

  static const int heroResponseTimeoutSeconds = 20;
  static const int maxDispatchTimeMinutes = 15;
}
