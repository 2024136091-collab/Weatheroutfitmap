import { useEffect, useState } from 'react';
import { Loader2, AlertCircle, LogIn, LogOut, User } from 'lucide-react';
import { useWeather } from './hooks/useWeather';
import { useStorage } from './hooks/useStorage';
import { SearchBar } from './components/SearchBar';
import { WeatherCard } from './components/WeatherCard';
import { ForecastCard } from './components/ForecastCard';
import { OutfitCard } from './components/OutfitCard';
import { LivingIndexCard } from './components/LivingIndexCard';
import { CityGrid } from './components/CityGrid';
import { LoginModal } from './components/LoginModal';
import { useAuth } from './contexts/AuthContext';

export default function App() {
  const { weather, forecast, todayUvIndex, todayPrecipProb, loading, error, search, searchByLocation } = useWeather();
  const { history, favorites, saveHistory, deleteHistory, toggleFavorite, deleteFavorite, isFavorite } = useStorage();
  const { user, logout } = useAuth();
  const [showLogin, setShowLogin] = useState(false);

  useEffect(() => {
    search('Seoul,KR');
  }, []);

  const handleSearch = async (city: string) => {
    const result = await search(city);
    if (result) {
      saveHistory(`${result.city},${result.country}`);
    }
  };

  const currentCityKey = weather ? `${weather.city},${weather.country}` : '';

  return (
    <div className="min-h-screen bg-slate-50">
      <div className="max-w-md mx-auto px-4 py-6 space-y-4">

        {/* 헤더 */}
        <header className="pb-2">
          <div className="flex items-center justify-between">
            <div>
              <h1 className="text-2xl font-bold text-slate-800">날씨별 코디</h1>
              <p className="text-sm text-slate-400 mt-0.5">오늘 날씨에 맞는 옷차림을 추천해드려요</p>
            </div>
            {user ? (
              <div className="flex items-center gap-2">
                <div className="flex items-center gap-1.5 bg-blue-50 text-blue-700 text-xs font-medium px-3 py-1.5 rounded-full">
                  <User className="w-3.5 h-3.5" />
                  {user.username}
                </div>
                <button
                  onClick={logout}
                  className="p-2 text-slate-400 hover:text-slate-600 transition"
                  title="로그아웃"
                >
                  <LogOut className="w-4 h-4" />
                </button>
              </div>
            ) : (
              <button
                onClick={() => setShowLogin(true)}
                className="flex items-center gap-1.5 bg-blue-500 hover:bg-blue-600 text-white text-sm font-medium px-4 py-2 rounded-xl transition"
              >
                <LogIn className="w-4 h-4" />
                로그인
              </button>
            )}
          </div>
        </header>

        {showLogin && <LoginModal onClose={() => setShowLogin(false)} />}

        {/* 검색바 */}
        <SearchBar onSearch={handleSearch} onLocate={searchByLocation} loading={loading} />

        {/* 로딩 */}
        {loading && (
          <div className="flex justify-center py-16">
            <Loader2 className="w-8 h-8 animate-spin text-blue-400" />
          </div>
        )}

        {/* 에러 */}
        {!loading && error && (
          <div className="flex items-center gap-2 bg-red-50 border border-red-200 text-red-600 rounded-xl px-4 py-3 text-sm">
            <AlertCircle className="w-4 h-4 shrink-0" />
            {error}
          </div>
        )}

        {/* 날씨 결과 */}
        {!loading && !error && weather && (
          <>
            <WeatherCard
              weather={weather}
              isFavorite={isFavorite(currentCityKey)}
              onToggleFavorite={() => toggleFavorite(currentCityKey, weather.city)}
            />
            <OutfitCard weather={weather} />
            <LivingIndexCard weather={weather} uvIndex={todayUvIndex} precipProb={todayPrecipProb} />
            <ForecastCard forecast={forecast} />
          </>
        )}

        {/* 도시 목록 — 항상 표시 */}
        {!loading && (
          <CityGrid
            favorites={favorites}
            history={history}
            onSelect={handleSearch}
            onRemoveFavorite={deleteFavorite}
            onClearHistory={deleteHistory}
            onToggleFavorite={toggleFavorite}
            isFavorite={isFavorite}
          />
        )}

      </div>
    </div>
  );
}