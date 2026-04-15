import { MapPin, Star, X, Clock, Trash2 } from 'lucide-react';
import type { FavoriteItem, HistoryItem } from '../utils/api';

const QUICK_CITIES = [
  { city: 'Seoul,KR', name: '서울' },
  { city: 'Busan,KR', name: '부산' },
  { city: 'Incheon,KR', name: '인천' },
  { city: 'Daegu,KR', name: '대구' },
  { city: 'Daejeon,KR', name: '대전' },
  { city: 'Gwangju,KR', name: '광주' },
  { city: 'Suwon,KR', name: '수원' },
  { city: 'Ulsan,KR', name: '울산' },
  { city: 'Jeju City,KR', name: '제주' },
  { city: 'Changwon,KR', name: '창원' },
];

interface Props {
  favorites: FavoriteItem[];
  history: HistoryItem[];
  onSelect: (city: string) => void;
  onRemoveFavorite: (id: number) => void;
  onClearHistory: () => void;
  onToggleFavorite: (city: string, displayName: string) => void;
  isFavorite: (city: string) => boolean;
}

export function CityGrid({ favorites, history, onSelect, onRemoveFavorite, onClearHistory, onToggleFavorite, isFavorite }: Props) {
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
              <button
                key={h.id}
                onClick={() => onSelect(h.city)}
                className="text-sm bg-slate-100 hover:bg-slate-200 text-slate-600 rounded-full px-3 py-1.5 transition"
              >
                {h.city.replace(',KR', '')}
              </button>
            ))}
          </div>
        </section>
      )}

      {/* 주요 도시 */}
      <section>
        <h3 className="text-xs font-semibold text-slate-400 uppercase tracking-wide mb-2 flex items-center gap-1">
          <MapPin className="w-3 h-3" /> 주요 도시
        </h3>
        <div className="grid grid-cols-5 gap-2">
          {QUICK_CITIES.map(c => (
            <div
              key={c.city}
              className="relative flex flex-col items-center gap-1 bg-white border border-slate-200 rounded-xl py-3 px-1
                         hover:border-blue-300 hover:bg-blue-50 shadow-sm transition group"
            >
              <button
                onClick={() => onToggleFavorite(c.city, c.name)}
                className={`absolute top-1 right-1 transition ${isFavorite(c.city) ? 'opacity-100' : 'opacity-0 group-hover:opacity-100'}`}
                aria-label={isFavorite(c.city) ? '즐겨찾기 해제' : '즐겨찾기 추가'}
              >
                <Star className={`w-3 h-3 ${isFavorite(c.city) ? 'fill-amber-400 text-amber-400' : 'text-slate-300'}`} />
              </button>
              <button
                onClick={() => onSelect(c.city)}
                className="flex flex-col items-center gap-1 text-slate-700 group-hover:text-blue-700 text-xs font-medium w-full"
              >
                <MapPin className="w-4 h-4 text-slate-400 group-hover:text-blue-400" />
                {c.name}
              </button>
            </div>
          ))}
        </div>
      </section>
    </div>
  );
}