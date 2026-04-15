import { useEffect, useState } from 'react';
import { MapPin, Star, X, Clock, Trash2, Search } from 'lucide-react';
import type { FavoriteItem, HistoryItem } from '../utils/api';
import { fetchWeatherData } from '../utils/weatherApi';

const QUICK_CITIES = [
  { city: 'Seoul,KR',      name: '서울',  region: '경기·수도권' },
  { city: 'Busan,KR',      name: '부산',  region: '경상남도' },
  { city: 'Incheon,KR',    name: '인천',  region: '경기·수도권' },
  { city: 'Daegu,KR',      name: '대구',  region: '경상북도' },
  { city: 'Daejeon,KR',    name: '대전',  region: '충청남도' },
  { city: 'Gwangju,KR',    name: '광주',  region: '전라남도' },
  { city: 'Suwon,KR',      name: '수원',  region: '경기도' },
  { city: 'Ulsan,KR',      name: '울산',  region: '경상남도' },
  { city: 'Jeju City,KR',  name: '제주',  region: '제주도' },
  { city: 'Changwon,KR',   name: '창원',  region: '경상남도' },
  { city: 'Jeonju,KR',     name: '전주',  region: '전라북도' },
  { city: 'Chuncheon,KR',  name: '춘천',  region: '강원도' },
];

const WEATHER_EMOJI: Record<string, string> = {
  Clear: '☀️',
  Clouds: '☁️',
  Rain: '🌧️',
  Drizzle: '🌦️',
  Snow: '❄️',
  Thunderstorm: '⛈️',
  Fog: '🌫️',
};

const WEATHER_COLOR: Record<string, string> = {
  Clear:        'bg-amber-50 border-amber-200 hover:border-amber-400 hover:bg-amber-100',
  Clouds:       'bg-slate-50 border-slate-200 hover:border-slate-400 hover:bg-slate-100',
  Rain:         'bg-blue-50 border-blue-200 hover:border-blue-400 hover:bg-blue-100',
  Drizzle:      'bg-cyan-50 border-cyan-200 hover:border-cyan-400 hover:bg-cyan-100',
  Snow:         'bg-sky-50 border-sky-200 hover:border-sky-400 hover:bg-sky-100',
  Thunderstorm: 'bg-purple-50 border-purple-200 hover:border-purple-400 hover:bg-purple-100',
  Fog:          'bg-gray-50 border-gray-200 hover:border-gray-400 hover:bg-gray-100',
};

interface CityWeather {
  temp: number;
  condition: string;
  description: string;
}

interface Props {
  favorites: FavoriteItem[];
  history: HistoryItem[];
  onSelect: (city: string) => void;
  onRemoveFavorite: (id: number) => void;
  onDeleteHistory: (id: number) => void;
  onClearHistory: () => void;
  onToggleFavorite: (city: string, displayName: string) => void;
  isFavorite: (city: string) => boolean;
}

export function CityGrid({ favorites, history, onSelect, onRemoveFavorite, onDeleteHistory, onClearHistory, onToggleFavorite, isFavorite }: Props) {
  const [cityWeathers, setCityWeathers] = useState<Record<string, CityWeather>>({});
  const [query, setQuery] = useState('');

  useEffect(() => {
    QUICK_CITIES.forEach(({ city }) => {
      fetchWeatherData(city)
        .then(w => setCityWeathers(prev => ({
          ...prev,
          [city]: { temp: Math.round(w.temperature), condition: w.condition, description: w.description },
        })))
        .catch(() => {});
    });
  }, []);

  return (
    <div className="space-y-5">
      {/* 즐겨찾기 */}
      {favorites.length > 0 && (
        <section>
          <h3 className="text-xs font-semibold text-slate-400 uppercase tracking-wide mb-2 flex items-center gap-1">
            <Star className="w-3 h-3" /> 즐겨찾기
          </h3>
          <div className="grid grid-cols-5 gap-2">
            {favorites.map(f => (
              <div
                key={f.id}
                className="relative flex flex-col items-center gap-1 bg-amber-50 border border-amber-200 rounded-xl py-3 px-1 shadow-sm hover:border-amber-400 hover:bg-amber-100 transition group"
              >
                <button
                  onClick={() => onRemoveFavorite(f.id)}
                  className="absolute top-1 right-1 text-amber-300 hover:text-red-400 transition opacity-0 group-hover:opacity-100"
                  aria-label="즐겨찾기 삭제"
                >
                  <X className="w-3 h-3" />
                </button>
                <button
                  onClick={() => onSelect(f.city)}
                  className="flex flex-col items-center gap-1 text-amber-800 hover:text-amber-600 text-xs font-medium w-full"
                >
                  <Star className="w-4 h-4 fill-amber-400 text-amber-400" />
                  {f.displayName}
                </button>
              </div>
            ))}
          </div>
        </section>
      )}

      {/* 최근 검색 */}
      {history.length > 0 && (
        <section>
          <div className="flex items-center justify-between mb-2">
            <h3 className="text-xs font-semibold text-slate-400 uppercase tracking-wide flex items-center gap-1">
              <Clock className="w-3 h-3" /> 최근 검색
            </h3>
            <button
              onClick={onClearHistory}
              className="text-xs text-slate-400 hover:text-red-400 flex items-center gap-0.5 transition"
            >
              <Trash2 className="w-3 h-3" /> 전체 삭제
            </button>
          </div>
          <div className="flex flex-wrap gap-2">
            {history.map(h => (
              <div key={h.id} className="relative group flex items-center">
                <button
                  onClick={() => onSelect(h.city)}
                  className="text-sm bg-slate-100 hover:bg-slate-200 text-slate-600 rounded-full pl-3 pr-7 py-1.5 transition"
                >
                  {h.city.replace(',KR', '')}
                </button>
                <button
                  onClick={() => onDeleteHistory(h.id)}
                  className="absolute right-2 text-slate-300 hover:text-red-400 transition"
                  aria-label="삭제"
                >
                  <X className="w-3 h-3" />
                </button>
              </div>
            ))}
          </div>
        </section>
      )}

      {/* 주요 도시 */}
      <section>
        <h3 className="text-xs font-semibold text-slate-400 uppercase tracking-wide mb-2 flex items-center gap-1">
          <MapPin className="w-3 h-3" /> 주요 도시
        </h3>

        {/* 도시 검색 */}
        <div className="relative mb-3">
          <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-3.5 h-3.5 text-slate-400" />
          <input
            type="text"
            value={query}
            onChange={e => setQuery(e.target.value)}
            placeholder="도시 이름으로 검색"
            className="w-full pl-9 pr-4 py-2 rounded-xl border border-slate-200 bg-white text-sm text-slate-700
                       placeholder-slate-400 focus:outline-none focus:ring-2 focus:ring-blue-500 transition"
          />
          {query && (
            <button
              onClick={() => setQuery('')}
              className="absolute right-3 top-1/2 -translate-y-1/2 text-slate-300 hover:text-slate-500"
            >
              <X className="w-3.5 h-3.5" />
            </button>
          )}
        </div>

        {/* 목록에 없는 도시 → 전체 검색 버튼 */}
        {(() => {
          const filtered = QUICK_CITIES.filter(c =>
            c.name.includes(query) || c.region.includes(query)
          );
          if (query && filtered.length === 0) {
            return (
              <button
                onClick={() => { onSelect(query); setQuery(''); }}
                className="w-full py-3 mb-3 rounded-xl border border-dashed border-blue-300 bg-blue-50
                           text-blue-600 text-sm font-medium hover:bg-blue-100 transition"
              >
                "{query}" 날씨 검색하기
              </button>
            );
          }
          return null;
        })()}

        <div className="grid grid-cols-3 gap-2">
          {QUICK_CITIES.filter(c =>
            !query || c.name.includes(query) || c.region.includes(query)
          ).map(c => {
            const w = cityWeathers[c.city];
            const colorClass = WEATHER_COLOR[w?.condition ?? ''] ?? WEATHER_COLOR.Clouds;
            return (
              <div
                key={c.city}
                className={`relative flex flex-col border rounded-xl p-3 shadow-sm transition group ${colorClass}`}
              >
                {/* 즐겨찾기 버튼 */}
                <button
                  onClick={() => onToggleFavorite(c.city, c.name)}
                  className={`absolute top-2 right-2 transition ${isFavorite(c.city) ? 'opacity-100' : 'opacity-0 group-hover:opacity-100'}`}
                  aria-label={isFavorite(c.city) ? '즐겨찾기 해제' : '즐겨찾기 추가'}
                >
                  <Star className={`w-3.5 h-3.5 ${isFavorite(c.city) ? 'fill-amber-400 text-amber-400' : 'text-slate-300'}`} />
                </button>

                {/* 도시 정보 */}
                <button
                  onClick={() => onSelect(c.city)}
                  className="flex flex-col gap-1 text-left w-full"
                >
                  <div className="text-xl leading-none">
                    {w ? (WEATHER_EMOJI[w.condition] ?? '🌡️') : '…'}
                  </div>
                  <div className="font-semibold text-slate-800 text-sm mt-1">{c.name}</div>
                  <div className="text-xs text-slate-400">{c.region}</div>
                  {w ? (
                    <>
                      <div className="text-lg font-bold text-slate-700 mt-0.5">{w.temp}°</div>
                      <div className="text-xs text-slate-500 truncate">{w.description}</div>
                    </>
                  ) : (
                    <div className="text-xs text-slate-300 mt-1">불러오는 중...</div>
                  )}
                </button>
              </div>
            );
          })}
        </div>

      </section>
    </div>
  );
}