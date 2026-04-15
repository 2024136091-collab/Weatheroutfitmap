import { X, User, Mail, Star, Clock, Trash2, LogOut } from 'lucide-react';
import { useAuth } from '../contexts/AuthContext';
import type { FavoriteItem, HistoryItem } from '../utils/api';

interface Props {
  favorites: FavoriteItem[];
  history: HistoryItem[];
  onClose: () => void;
  onSelectCity: (city: string) => void;
  onRemoveFavorite: (id: number) => void;
  onClearHistory: () => void;
}

export function MyPage({ favorites, history, onClose, onSelectCity, onRemoveFavorite, onClearHistory }: Props) {
  const { user, logout } = useAuth();

  const handleLogout = () => {
    logout();
    onClose();
  };

  const handleCity = (city: string) => {
    onSelectCity(city);
    onClose();
  };

  return (
    <div className="fixed inset-0 z-50 flex items-end sm:items-center justify-center bg-black/40 backdrop-blur-sm">
      <div className="bg-white w-full max-w-md rounded-t-3xl sm:rounded-2xl shadow-xl max-h-[85vh] flex flex-col">

        {/* 헤더 */}
        <div className="flex items-center justify-between px-6 pt-6 pb-4 border-b border-slate-100 shrink-0">
          <h2 className="text-base font-semibold text-slate-800">마이페이지</h2>
          <button onClick={onClose} className="text-slate-400 hover:text-slate-600 transition">
            <X className="w-5 h-5" />
          </button>
        </div>

        <div className="overflow-y-auto flex-1 px-6 py-4 space-y-6">

          {/* 프로필 */}
          <section className="flex items-center gap-4 bg-slate-50 rounded-2xl p-4">
            <div className="w-14 h-14 rounded-full bg-blue-100 flex items-center justify-center shrink-0">
              <User className="w-7 h-7 text-blue-500" />
            </div>
            <div className="min-w-0">
              <p className="font-semibold text-slate-800 truncate">{user?.username}</p>
              <p className="text-sm text-slate-400 flex items-center gap-1 mt-0.5 truncate">
                <Mail className="w-3.5 h-3.5 shrink-0" />
                {user?.email}
              </p>
            </div>
          </section>

          {/* 즐겨찾기 */}
          <section>
            <h3 className="text-xs font-semibold text-slate-400 uppercase tracking-wide mb-3 flex items-center gap-1">
              <Star className="w-3 h-3" /> 즐겨찾기 {favorites.length > 0 && `(${favorites.length})`}
            </h3>
            {favorites.length === 0 ? (
              <p className="text-sm text-slate-300 text-center py-4">즐겨찾기한 도시가 없어요</p>
            ) : (
              <div className="grid grid-cols-4 gap-2">
                {favorites.map(f => (
                  <div
                    key={f.id}
                    className="relative group flex flex-col items-center gap-1 bg-amber-50 border border-amber-200 rounded-xl py-3 px-1 hover:bg-amber-100 transition"
                  >
                    <button
                      onClick={() => onRemoveFavorite(f.id)}
                      className="absolute top-1 right-1 text-amber-300 hover:text-red-400 transition opacity-0 group-hover:opacity-100"
                      aria-label="삭제"
                    >
                      <X className="w-3 h-3" />
                    </button>
                    <button
                      onClick={() => handleCity(f.city)}
                      className="flex flex-col items-center gap-1 text-amber-800 text-xs font-medium w-full"
                    >
                      <Star className="w-4 h-4 fill-amber-400 text-amber-400" />
                      {f.displayName}
                    </button>
                  </div>
                ))}
              </div>
            )}
          </section>

          {/* 최근 검색 */}
          <section>
            <div className="flex items-center justify-between mb-3">
              <h3 className="text-xs font-semibold text-slate-400 uppercase tracking-wide flex items-center gap-1">
                <Clock className="w-3 h-3" /> 최근 검색 {history.length > 0 && `(${history.length})`}
              </h3>
              {history.length > 0 && (
                <button
                  onClick={onClearHistory}
                  className="text-xs text-slate-400 hover:text-red-400 flex items-center gap-0.5 transition"
                >
                  <Trash2 className="w-3 h-3" /> 전체 삭제
                </button>
              )}
            </div>
            {history.length === 0 ? (
              <p className="text-sm text-slate-300 text-center py-4">최근 검색 기록이 없어요</p>
            ) : (
              <div className="flex flex-wrap gap-2">
                {history.map(h => (
                  <button
                    key={h.id}
                    onClick={() => handleCity(h.city)}
                    className="text-sm bg-slate-100 hover:bg-slate-200 text-slate-600 rounded-full px-3 py-1.5 transition"
                  >
                    {h.city.replace(',KR', '')}
                  </button>
                ))}
              </div>
            )}
          </section>
        </div>

        {/* 로그아웃 */}
        <div className="px-6 py-4 border-t border-slate-100 shrink-0">
          <button
            onClick={handleLogout}
            className="w-full flex items-center justify-center gap-2 py-3 rounded-xl text-sm font-medium text-red-500 hover:bg-red-50 transition"
          >
            <LogOut className="w-4 h-4" />
            로그아웃
          </button>
        </div>

      </div>
    </div>
  );
}