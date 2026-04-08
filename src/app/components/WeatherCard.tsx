import { Droplets, Wind, Gauge, Eye, Star } from 'lucide-react';
import type { WeatherData } from '../types/weather';

const WEATHER_BG: Record<string, string> = {
  Clear:        'from-amber-400 to-orange-300',
  Clouds:       'from-slate-400 to-slate-300',
  Rain:         'from-blue-500 to-cyan-400',
  Drizzle:      'from-blue-400 to-cyan-300',
  Snow:         'from-sky-300 to-blue-200',
  Thunderstorm: 'from-purple-600 to-slate-500',
};

const WEATHER_EMOJI: Record<string, string> = {
  Clear: '☀️',
  Clouds: '☁️',
  Rain: '🌧️',
  Drizzle: '🌦️',
  Snow: '❄️',
  Thunderstorm: '⛈️',
};

interface Props {
  weather: WeatherData;
  isFavorite: boolean;
  onToggleFavorite: () => void;
}

export function WeatherCard({ weather, isFavorite, onToggleFavorite }: Props) {
  const bg = WEATHER_BG[weather.condition] ?? WEATHER_BG.Clouds;
  const emoji = WEATHER_EMOJI[weather.condition] ?? '🌡️';

  return (
    <div className={`rounded-2xl bg-gradient-to-br ${bg} p-5 text-white shadow-md`}>
      {/* 상단 */}
      <div className="flex items-start justify-between">
        <div>
          <p className="text-xs font-medium opacity-80 mb-0.5">{weather.country}</p>
          <h2 className="text-2xl font-semibold">{weather.city}</h2>
          {weather.district && (
            <p className="text-xs opacity-70 mt-0.5">{weather.district}</p>
          )}
          <p className="text-sm opacity-80 capitalize mt-0.5">{weather.description}</p>
        </div>
        <button
          onClick={onToggleFavorite}
          className={`mt-0.5 p-2 rounded-full transition
            ${isFavorite ? 'bg-white/30' : 'bg-white/10 hover:bg-white/20'}`}
          aria-label={isFavorite ? '즐겨찾기 해제' : '즐겨찾기 추가'}
        >
          <Star className={`w-4 h-4 ${isFavorite ? 'fill-white' : ''}`} />
        </button>
      </div>

      {/* 온도 */}
      <div className="flex items-end gap-3 mt-4">
        <span className="text-6xl font-light">{Math.round(weather.temperature)}°</span>
        <span className="text-5xl mb-1">{emoji}</span>
      </div>
      <p className="text-sm opacity-75 mt-1">체감 {Math.round(weather.feelsLike)}°C</p>

      {/* 세부 정보 */}
      <div className="grid grid-cols-4 gap-2 mt-5 pt-4 border-t border-white/20">
        {[
          { icon: <Droplets className="w-3.5 h-3.5" />, label: '습도', value: `${weather.humidity}%` },
          { icon: <Wind className="w-3.5 h-3.5" />, label: '풍속', value: `${weather.windSpeed}m/s` },
          { icon: <Gauge className="w-3.5 h-3.5" />, label: '기압', value: `${weather.pressure}` },
          { icon: <Eye className="w-3.5 h-3.5" />, label: '가시', value: `${(weather.visibility / 1000).toFixed(1)}km` },
        ].map(({ icon, label, value }) => (
          <div key={label} className="flex flex-col items-center gap-1">
            <span className="opacity-70">{icon}</span>
            <span className="text-xs opacity-60">{label}</span>
            <span className="text-sm font-medium">{value}</span>
          </div>
        ))}
      </div>
    </div>
  );
}