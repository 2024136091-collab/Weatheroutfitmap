import type { ForecastData } from '../types/weather';

const WEATHER_EMOJI: Record<string, string> = {
  Clear:        '☀️',
  Clouds:       '☁️',
  Rain:         '🌧️',
  Drizzle:      '🌦️',
  Snow:         '❄️',
  Thunderstorm: '⛈️',
  Fog:          '🌫️',
};

interface Props {
  forecast: ForecastData[];
}

export function ForecastCard({ forecast }: Props) {
  if (forecast.length === 0) return null;

  return (
    <div className="bg-white rounded-2xl border border-slate-100 shadow-sm p-5">
      <h3 className="text-sm font-semibold text-slate-500 uppercase tracking-wide mb-4">
        {forecast.length > 5 ? '15일 예보' : '5일 예보'}
      </h3>
      <div className="space-y-1 max-h-96 overflow-y-auto pr-1">
        {forecast.map((item, i) => (
          <div
            key={i}
            className="flex items-center justify-between py-2.5 border-b border-slate-50 last:border-0"
          >
            <span className="text-sm font-medium text-slate-700 w-20 shrink-0">{item.date}</span>
            <span className="text-xl">{WEATHER_EMOJI[item.condition] ?? '🌡️'}</span>
            <span className="text-sm text-slate-500 flex-1 text-center capitalize">{item.description}</span>
            {item.precipitationProbability > 0 ? (
              <span className="text-xs text-blue-400 w-9 text-right shrink-0">
                💧{item.precipitationProbability}%
              </span>
            ) : (
              <span className="w-9 shrink-0" />
            )}
            <div className="flex items-center gap-1.5 text-sm ml-2 shrink-0">
              <span className="text-blue-500">{Math.round(item.tempMin)}°</span>
              <span className="text-slate-300">/</span>
              <span className="text-slate-800 font-medium">{Math.round(item.tempMax)}°</span>
            </div>
          </div>
        ))}
      </div>
    </div>
  );
}