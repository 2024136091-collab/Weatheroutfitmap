import type { WeatherData, AirQuality } from '../types/weather';

interface IndexItem {
  emoji: string;
  name: string;
  label: string;
  color: string;
  bg: string;
}

function computeIndices(weather: WeatherData, uvIndex: number, precipProb: number): IndexItem[] {
  // 자외선 지수
  const uvLabel =
    uvIndex <= 2 ? '낮음' :
    uvIndex <= 5 ? '보통' :
    uvIndex <= 7 ? '높음' :
    uvIndex <= 10 ? '매우높음' : '위험';
  const uvColor =
    uvIndex <= 2 ? 'text-green-600' :
    uvIndex <= 5 ? 'text-yellow-600' :
    uvIndex <= 7 ? 'text-orange-500' : 'text-red-600';
  const uvBg =
    uvIndex <= 2 ? 'bg-green-50' :
    uvIndex <= 5 ? 'bg-yellow-50' :
    uvIndex <= 7 ? 'bg-orange-50' : 'bg-red-50';

  // 불쾌지수 (DI = T - 0.55×(1 - H/100)×(T - 14.5))
  const { temperature: T, humidity: H, windSpeed } = weather;
  const di = T - 0.55 * (1 - H / 100) * (T - 14.5);
  const diLabel =
    di < 68 ? '쾌적' :
    di < 72 ? '보통' :
    di < 75 ? '약간불쾌' :
    di < 80 ? '불쾌' : '매우불쾌';
  const diColor =
    di < 68 ? 'text-green-600' :
    di < 72 ? 'text-blue-600' :
    di < 75 ? 'text-yellow-600' :
    di < 80 ? 'text-orange-500' : 'text-red-600';
  const diBg =
    di < 68 ? 'bg-green-50' :
    di < 72 ? 'bg-blue-50' :
    di < 75 ? 'bg-yellow-50' :
    di < 80 ? 'bg-orange-50' : 'bg-red-50';

  // 세탁 지수 (강수확률↓ + 습도↓ + 바람 적당)
  const laundry = Math.round(
    (1 - precipProb / 100) * 50 +
    (1 - Math.min(H, 80) / 80) * 30 +
    Math.min(windSpeed / 10, 1) * 20
  );
  const laundryLabel =
    laundry >= 80 ? '매우좋음' :
    laundry >= 60 ? '좋음' :
    laundry >= 40 ? '보통' :
    laundry >= 20 ? '나쁨' : '매우나쁨';
  const laundryColor = laundry >= 60 ? 'text-green-600' : laundry >= 40 ? 'text-yellow-600' : 'text-red-600';
  const laundryBg   = laundry >= 60 ? 'bg-green-50'   : laundry >= 40 ? 'bg-yellow-50'   : 'bg-red-50';

  // 운동 지수 (15-22°C 최적, 습도↓, 강수확률↓)
  const tempFit =
    T >= 10 && T <= 25
      ? Math.max(0, 100 - Math.abs(T - 18) * 4)
      : T > 25
        ? Math.max(0, 100 - (T - 25) * 10)
        : Math.max(0, 100 - (10 - T) * 8);
  const humFit = Math.max(0, 100 - Math.max(0, H - 60) * 2);
  const exercise = Math.round(Math.max(0, tempFit * 0.5 + humFit * 0.3 - precipProb * 0.4));
  const exerciseLabel =
    exercise >= 80 ? '매우좋음' :
    exercise >= 60 ? '좋음' :
    exercise >= 40 ? '보통' :
    exercise >= 20 ? '나쁨' : '매우나쁨';
  const exerciseColor = exercise >= 60 ? 'text-green-600' : exercise >= 40 ? 'text-yellow-600' : 'text-red-600';
  const exerciseBg   = exercise >= 60 ? 'bg-green-50'   : exercise >= 40 ? 'bg-yellow-50'   : 'bg-red-50';

  // 우산 지수 (강수확률 그대로)
  const umbrellaLabel =
    precipProb < 20 ? '불필요' :
    precipProb < 50 ? '챙기기' :
    precipProb < 80 ? '권장' : '필수';
  const umbrellaColor =
    precipProb < 20 ? 'text-green-600' :
    precipProb < 50 ? 'text-yellow-600' :
    precipProb < 80 ? 'text-orange-500' : 'text-red-600';
  const umbrellaBg =
    precipProb < 20 ? 'bg-green-50' :
    precipProb < 50 ? 'bg-yellow-50' :
    precipProb < 80 ? 'bg-orange-50' : 'bg-red-50';

  return [
    { emoji: '🌞', name: '자외선',  label: uvLabel,       color: uvColor,       bg: uvBg       },
    { emoji: '🌡️', name: '불쾌지수', label: diLabel,       color: diColor,       bg: diBg       },
    { emoji: '👕',  name: '세탁',    label: laundryLabel,  color: laundryColor,  bg: laundryBg  },
    { emoji: '🏃',  name: '운동',    label: exerciseLabel, color: exerciseColor, bg: exerciseBg },
    { emoji: '☂️',  name: '우산',    label: umbrellaLabel, color: umbrellaColor, bg: umbrellaBg },
  ];
}

interface AqiBarProps {
  label: string;
  value: number;
  unit: string;
  thresholds: [number, number, number];
  max: number;
}

function AqiBar({ label, value, unit, thresholds, max }: AqiBarProps) {
  const [t1, t2, t3] = thresholds;
  const grade =
    value <= t1 ? { text: '좋음', color: 'text-green-600', bar: 'bg-green-400' } :
    value <= t2 ? { text: '보통', color: 'text-yellow-600', bar: 'bg-yellow-400' } :
    value <= t3 ? { text: '나쁨', color: 'text-orange-500', bar: 'bg-orange-400' } :
                  { text: '매우나쁨', color: 'text-red-600', bar: 'bg-red-500' };
  const pct = Math.min(100, Math.round((value / max) * 100));

  return (
    <div>
      <div className="flex items-center justify-between mb-1">
        <span className="text-xs text-slate-500">{label}</span>
        <div className="flex items-center gap-1.5">
          <span className={`text-xs font-semibold ${grade.color}`}>{grade.text}</span>
          <span className="text-xs text-slate-400">{value}{unit}</span>
        </div>
      </div>
      <div className="h-1.5 bg-slate-100 rounded-full overflow-hidden">
        <div className={`h-full rounded-full transition-all ${grade.bar}`} style={{ width: `${pct}%` }} />
      </div>
    </div>
  );
}

interface Props {
  weather: WeatherData;
  uvIndex: number;
  precipProb: number;
  airQuality?: AirQuality | null;
}

export function LivingIndexCard({ weather, uvIndex, precipProb, airQuality }: Props) {
  const indices = computeIndices(weather, uvIndex, precipProb);

  return (
    <div className="bg-white rounded-2xl border border-slate-100 shadow-sm p-5">
      <h3 className="text-sm font-semibold text-slate-500 uppercase tracking-wide mb-4">생활 지수</h3>
      <div className="grid grid-cols-5 gap-2">
        {indices.map((item) => (
          <div key={item.name} className="flex flex-col items-center gap-1.5">
            <div className={`w-11 h-11 rounded-full flex items-center justify-center text-xl ${item.bg}`}>
              {item.emoji}
            </div>
            <span className="text-xs text-slate-500 text-center leading-tight">{item.name}</span>
            <span className={`text-xs font-semibold text-center leading-tight ${item.color}`}>{item.label}</span>
          </div>
        ))}
      </div>

      {airQuality && (
        <div className="mt-4 pt-4 border-t border-slate-100 space-y-2.5">
          <p className="text-xs font-semibold text-slate-400 uppercase tracking-wide">미세먼지</p>
          <AqiBar label="미세먼지 (PM10)" value={airQuality.pm10} unit="㎍/㎥" thresholds={[30, 80, 150]} max={200} />
          <AqiBar label="초미세먼지 (PM2.5)" value={airQuality.pm25} unit="㎍/㎥" thresholds={[15, 35, 75]} max={100} />
        </div>
      )}
    </div>
  );
}