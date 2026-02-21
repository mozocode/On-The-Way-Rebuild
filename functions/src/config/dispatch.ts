export interface WaveConfig {
  waveNumber: number;
  minRadiusMiles: number;
  maxRadiusMiles: number;
  timeoutSeconds: number;
  maxHeroesPerWave: number;
}

export const DISPATCH_WAVES: WaveConfig[] = [
  { waveNumber: 1, minRadiusMiles: 0, maxRadiusMiles: 2, timeoutSeconds: 30, maxHeroesPerWave: 10 },
  { waveNumber: 2, minRadiusMiles: 2, maxRadiusMiles: 5, timeoutSeconds: 45, maxHeroesPerWave: 15 },
  { waveNumber: 3, minRadiusMiles: 5, maxRadiusMiles: 10, timeoutSeconds: 60, maxHeroesPerWave: 20 },
  { waveNumber: 4, minRadiusMiles: 10, maxRadiusMiles: 25, timeoutSeconds: 90, maxHeroesPerWave: 30 },
];

export const MAX_DISPATCH_WAVES = DISPATCH_WAVES.length;
export const HERO_RESPONSE_TIMEOUT_SECONDS = 20;
export const HERO_NOTIFICATION_COOLDOWN_SECONDS = 300;
export const MAX_DISPATCH_TIME_MINUTES = 15;
export const HERO_LOCATION_TTL_MS = 5 * 60 * 1000;

export const HERO_SCORE_WEIGHTS = {
  proximity: 0.40,
  rating: 0.25,
  acceptanceRate: 0.20,
  responseTime: 0.15,
};
