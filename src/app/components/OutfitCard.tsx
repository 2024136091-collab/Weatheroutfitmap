import { useState, useRef } from 'react';
import { Sparkles, Loader2, RefreshCw, LogIn } from 'lucide-react';
import type { WeatherData } from '../types/weather';
import { streamAiOutfit } from '../utils/api';
import { useAuth } from '../contexts/AuthContext';

const TPO_OPTIONS = [
  { key: '일상/캐주얼', label: '캐주얼' },
  { key: '출근/비즈니스', label: '출근' },
  { key: '데이트/외출', label: '데이트' },
  { key: '운동/야외활동', label: '운동' },
] as const;

type TpoKey = typeof TPO_OPTIONS[number]['key'];

interface OutfitItem {
  emoji: string;
  name: string;
}

function getOutfit(temp: number, condition: string, humidity: number, windSpeed: number) {
  let title: string;
  let items: OutfitItem[];
  let tip: string;

  if (temp < 5) {
    title = '매우 추운 날씨';
    items = [
      { emoji: '🧥', name: '패딩' },
      { emoji: '🧣', name: '목도리' },
      { emoji: '🧤', name: '장갑' },
      { emoji: '🧢', name: '모자' },
    ];
    tip = '두꺼운 겨울옷 필수! 레이어드로 보온하세요.';
  } else if (temp < 10) {
    title = '쌀쌀한 날씨';
    items = [
      { emoji: '🧥', name: '코트' },
      { emoji: '👕', name: '니트' },
      { emoji: '👖', name: '두꺼운 바지' },
      { emoji: '👟', name: '운동화' },
    ];
    tip = '겉옷은 필수, 레이어드가 효과적이에요.';
  } else if (temp < 15) {
    title = '선선한 날씨';
    items = [
      { emoji: '🧥', name: '자켓' },
      { emoji: '👕', name: '가디건' },
      { emoji: '👕', name: '긴팔티' },
      { emoji: '👖', name: '청바지' },
    ];
    tip = '아침저녁으로 쌀쌀하니 가벼운 겉옷을 챙기세요.';
  } else if (temp < 20) {
    title = '쾌적한 날씨';
    items = [
      { emoji: '👕', name: '긴팔티' },
      { emoji: '👕', name: '셔츠' },
      { emoji: '👖', name: '면바지' },
      { emoji: '👟', name: '스니커즈' },
    ];
    tip = '야외활동하기 딱 좋은 날씨예요!';
  } else if (temp < 25) {
    title = '따뜻한 날씨';
    items = [
      { emoji: '👕', name: '반팔티' },
      { emoji: '👕', name: '얇은 셔츠' },
      { emoji: '👖', name: '면바지' },
      { emoji: '👟', name: '스니커즈' },
    ];
    tip = '가볍고 편한 옷차림이 좋아요.';
  } else {
    title = '더운 날씨';
    items = [
      { emoji: '👕', name: '반팔티' },
      { emoji: '👖', name: '반바지' },
      { emoji: '👕', name: '린넨셔츠' },
      { emoji: '👡', name: '샌들' },
    ];
    tip = '통풍이 잘 되는 시원한 소재를 선택하세요.';
  }

  const extras: OutfitItem[] = [];

  if (['Rain', 'Drizzle', 'Thunderstorm'].includes(condition)) {
    extras.push({ emoji: '☂️', name: '우산' }, { emoji: '🧥', name: '방수자켓' });
    tip += ' 비 소식이 있으니 우산 필수!';
  }
  if (condition === 'Snow') {
    extras.push({ emoji: '👢', name: '방한부츠' });
    tip += ' 눈길 미끄럼 조심하세요.';
  }
  if (temp > 22 || (condition === 'Clear' && temp > 18)) {
    extras.push({ emoji: '🕶️', name: '선글라스' });
  }
  if (windSpeed > 7) {
    extras.push({ emoji: '🧥', name: '바람막이' });
    tip += ' 바람이 강해요.';
  }
  if (humidity > 80) {
    extras.push({ emoji: '💧', name: '통풍의류' });
  }

  return { title, items, extras, tip };
}

interface Props {
  weather: WeatherData;
  todayPrecipProb?: number;
  todayUvIndex?: number;
  onLoginRequest?: () => void;
}

export function OutfitCard({ weather, todayPrecipProb, todayUvIndex, onLoginRequest }: Props) {
  const { title, items, extras, tip } = getOutfit(
    weather.temperature,
    weather.condition,
    weather.humidity,
    weather.windSpeed
  );
  const { user } = useAuth();

  const [aiText, setAiText] = useState('');
  const [aiLoading, setAiLoading] = useState(false);
  const [aiError, setAiError] = useState('');
  const [selectedTpo, setSelectedTpo] = useState<TpoKey>('일상/캐주얼');
  const abortRef = useRef<AbortController | null>(null);

  const handleAiRequest = async () => {
    if (!user) {
      onLoginRequest?.();
      return;
    }
    if (aiLoading) {
      abortRef.current?.abort();
      return;
    }
    setAiText('');
    setAiError('');
    setAiLoading(true);
    const ctrl = new AbortController();
    abortRef.current = ctrl;

    try {
      await streamAiOutfit(
        {
          city: weather.city,
          temperature: weather.temperature,
          feelsLike: weather.feelsLike,
          condition: weather.condition,
          description: weather.description,
          humidity: weather.humidity,
          windSpeed: weather.windSpeed,
          precipProb: todayPrecipProb,
          uvIndex: todayUvIndex,
          tpo: selectedTpo,
        },
        chunk => setAiText(prev => prev + chunk),
        ctrl.signal
      );
    } catch (e: unknown) {
      if (e instanceof Error && e.name !== 'AbortError') {
        setAiError('AI 추천을 불러올 수 없습니다. 서버 연결을 확인해 주세요.');
      }
    } finally {
      setAiLoading(false);
    }
  };

  return (
    <div className="bg-white rounded-2xl border border-slate-100 shadow-sm p-5">
      <div className="flex items-baseline justify-between mb-4">
        <h3 className="text-sm font-semibold text-slate-500 uppercase tracking-wide">오늘의 코디</h3>
        <span className="text-sm font-medium text-slate-700">{title}</span>
      </div>

      {/* 기본 의상 */}
      <div className="flex flex-wrap gap-2 mb-3">
        {items.map((item, i) => (
          <span
            key={i}
            className="inline-flex items-center gap-1.5 bg-slate-50 border border-slate-200 rounded-full px-3 py-1.5 text-sm text-slate-700"
          >
            <span>{item.emoji}</span>
            {item.name}
          </span>
        ))}
      </div>

      {/* 추가 아이템 */}
      {extras.length > 0 && (
        <div className="flex flex-wrap gap-2 mb-3">
          {extras.map((item, i) => (
            <span
              key={i}
              className="inline-flex items-center gap-1.5 bg-blue-50 border border-blue-200 rounded-full px-3 py-1.5 text-sm text-blue-700"
            >
              <span>{item.emoji}</span>
              {item.name}
            </span>
          ))}
        </div>
      )}

      {/* 팁 */}
      <p className="text-xs text-slate-500 mt-3 leading-relaxed">💡 {tip}</p>

      {/* AI 추천 버튼 */}
      <div className="mt-4 pt-4 border-t border-slate-100">
        {/* TPO 선택 */}
        <div className="flex gap-1.5 mb-3 flex-wrap">
          {TPO_OPTIONS.map(opt => (
            <button
              key={opt.key}
              onClick={() => { setSelectedTpo(opt.key); setAiText(''); setAiError(''); }}
              disabled={aiLoading}
              className={`text-xs px-3 py-1 rounded-full border transition
                ${selectedTpo === opt.key
                  ? 'bg-purple-100 border-purple-300 text-purple-700 font-semibold'
                  : 'bg-slate-50 border-slate-200 text-slate-500 hover:border-slate-300'}
                disabled:opacity-50`}
            >
              {opt.label}
            </button>
          ))}
        </div>
        <button
          onClick={handleAiRequest}
          className={`w-full flex items-center justify-center gap-2 py-2.5 rounded-xl text-sm font-medium transition
            ${!user
              ? 'bg-slate-50 border border-slate-200 text-slate-400 hover:bg-slate-100'
              : aiLoading
                ? 'bg-purple-50 text-purple-400 border border-purple-200'
                : 'bg-gradient-to-r from-purple-500 to-indigo-500 hover:from-purple-600 hover:to-indigo-600 text-white shadow-sm'
            }`}
        >
          {!user ? (
            <>
              <LogIn className="w-4 h-4" />
              로그인 후 AI 코디 추천 받기
            </>
          ) : aiLoading ? (
            <>
              <Loader2 className="w-4 h-4 animate-spin" />
              AI가 추천 중...
            </>
          ) : aiText ? (
            <>
              <RefreshCw className="w-4 h-4" />
              AI 추천 다시 받기
            </>
          ) : (
            <>
              <Sparkles className="w-4 h-4" />
              AI 코디 추천 받기
            </>
          )}
        </button>

        {/* AI 응답 */}
        {aiError && (
          <p className="mt-3 text-xs text-red-500">{aiError}</p>
        )}
        {(aiText || aiLoading) && !aiError && (
          <div className="mt-3 bg-purple-50 rounded-xl p-4">
            <p className="text-xs text-purple-700 leading-relaxed whitespace-pre-wrap">
              {aiText}
              {aiLoading && <span className="inline-block w-1 h-3 ml-0.5 bg-purple-400 animate-pulse rounded-sm" />}
            </p>
          </div>
        )}
      </div>
    </div>
  );
}