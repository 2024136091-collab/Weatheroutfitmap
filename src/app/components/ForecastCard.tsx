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

function getForecastOutfit(tempMax: number, condition: string, precipProb: number): string[] {
  let base: string[];

  if (tempMax < 5) {
    base = ['🧥', '🧣', '🧤'];
  } else if (tempMax < 10) {
    base = ['🧥', '👕', '👖'];
  } else if (tempMax < 15) {
    base = ['🧥', '👕', '👖'];
  } else if (tempMax < 20) {
    base = ['👕', '👖', '👟'];
  } else if (tempMax < 25) {
    base = ['👕', '👖', '👟'];
  } else {
    base = ['👕', '👖', '👡'];
  }

  const extras: string[] = [];
  if (['Rain', 'Drizzle', 'Thunderstorm'].includes(condition) || precipProb >= 50) {
    extras.push('☂️');
  }
  if (condition === 'Snow') {
    extras.push('👢');
  }
  if (condition === 'Clear' && tempMax >= 20) {
    extras.push('🕶️');
  }

  return [...base, ...extras];
}

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
        {forecast.map((item, i) => {
          const outfit = getForecastOutfit(item.tempMax, item.condition, item.precipitationProbability);
          return (
            <div
              key={i}
              className="flex items-center gap-2 py-2.5 border-b border-slate-50 last:border-0"
            >
              {/* 날짜 */}
              <span className="text-sm font-medium text-slate-700 w-16 shrink-0">{item.date}</span>

              {/* 날씨 이모지 */}
              <span className="text-lg shrink-0">{WEATHER_EMOJI[item.condition] ?? '🌡️'}</span>

              {/* 강수확률 */}
              {item.precipitationProbability > 0 ? (
                <span className="text-xs text-blue-400 w-8 shrink-0">
                  💧{item.precipitationProbability}%
                </span>
              ) : (
                <span className="w-8 shrink-0" />
              )}

              {/* 기온 */}
              <div className="flex items-center gap-1 text-sm shrink-0">
                <span className="text-blue-500">{Math.round(item.tempMin)}°</span>
                <span className="text-slate-300">/</span>
                <span className="text-slate-800 font-medium">{Math.round(item.tempMax)}°</span>
              </div>

              {/* 코디 */}
              <div className="flex items-center gap-0.5 ml-auto">
                {outfit.map((emoji, j) => (
                  <span key={j} className="text-base leading-none">{emoji}</span>
                ))}
              </div>
            </div>
          );
        })}
      </div>
    </div>
  );
}