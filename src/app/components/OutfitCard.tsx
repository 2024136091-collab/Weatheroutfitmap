import type { WeatherData } from '../types/weather';

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
}

export function OutfitCard({ weather }: Props) {
  const { title, items, extras, tip } = getOutfit(
    weather.temperature,
    weather.condition,
    weather.humidity,
    weather.windSpeed
  );

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
    </div>
  );
}