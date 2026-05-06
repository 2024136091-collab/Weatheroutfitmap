import type { WeatherData, ForecastData, AirQuality } from '../types/weather';

const API_KEY = '7e29173a70b89b4919dfe873c2352b30';
const BASE_URL = 'https://api.openweathermap.org/data/2.5';

interface GeoResult {
  lat: number;
  lon: number;
  name: string;
  country: string;
}

/**
 * Open-Meteo 지오코딩 API로 도시명(한글·영문 모두 지원)을 위경도로 변환
 */
async function geocodeCity(input: string): Promise<GeoResult> {
  // 영문 + 국가코드 형식(예: Seoul,KR)이면 도시명만 추출
  const cityName = input.split(',')[0].trim();

  const res = await fetch(
    `https://geocoding-api.open-meteo.com/v1/search?name=${encodeURIComponent(cityName)}&count=1&language=ko&format=json`
  );
  if (!res.ok) throw new Error('위치를 찾을 수 없습니다');

  const data = await res.json();
  if (!data.results?.length) throw new Error('도시를 찾을 수 없습니다. 다른 도시명으로 검색해 보세요.');

  const { latitude, longitude, name, country_code } = data.results[0];
  return { lat: latitude, lon: longitude, name, country: country_code };
}

async function reverseGeocodeKo(lat: number, lon: number): Promise<string | undefined> {
  try {
    const res = await fetch(
      `https://nominatim.openstreetmap.org/reverse?lat=${lat}&lon=${lon}&format=json&accept-language=ko`,
      { headers: { 'User-Agent': 'WeatherCodiApp/1.0' } }
    );
    if (!res.ok) return undefined;
    const data = await res.json();
    const addr = data.address ?? {};
    const parts = [
      addr.city_district ?? addr.county,
      addr.suburb ?? addr.neighbourhood ?? addr.quarter,
    ].filter(Boolean);
    return parts.length ? parts.join(' ') : undefined;
  } catch {
    return undefined;
  }
}

export async function fetchWeatherByCoords(lat: number, lon: number): Promise<WeatherData> {
  const [weatherRes, district] = await Promise.all([
    fetch(`${BASE_URL}/weather?lat=${lat}&lon=${lon}&appid=${API_KEY}&units=metric&lang=kr`),
    reverseGeocodeKo(lat, lon),
  ]);
  if (!weatherRes.ok) throw new Error('날씨 정보를 가져올 수 없습니다');
  const d = await weatherRes.json();
  return {
    city: d.name,
    country: d.sys.country === 'KR' ? '대한민국' : d.sys.country,
    district,
    temperature: d.main.temp,
    feelsLike: d.main.feels_like,
    description: d.weather[0].description,
    condition: d.weather[0].main,
    humidity: d.main.humidity,
    windSpeed: d.wind.speed,
    pressure: d.main.pressure,
    visibility: d.visibility,
    sunrise: d.sys.sunrise,
    sunset: d.sys.sunset,
  };
}

export async function fetchWeatherData(city: string): Promise<WeatherData> {
  const { lat, lon, name: koName } = await geocodeCity(city);

  const [res, district] = await Promise.all([
    fetch(`${BASE_URL}/weather?lat=${lat}&lon=${lon}&appid=${API_KEY}&units=metric&lang=kr`),
    reverseGeocodeKo(lat, lon),
  ]);
  if (!res.ok) throw new Error('날씨 정보를 가져올 수 없습니다');

  const d = await res.json();

  if (d.sys.country !== 'KR') {
    throw new Error('국내 도시만 검색할 수 있습니다');
  }

  return {
    city: koName || d.name,
    country: '대한민국',
    district,
    temperature: d.main.temp,
    feelsLike: d.main.feels_like,
    description: d.weather[0].description,
    condition: d.weather[0].main,
    humidity: d.main.humidity,
    windSpeed: d.wind.speed,
    pressure: d.main.pressure,
    visibility: d.visibility,
    sunrise: d.sys.sunrise,
    sunset: d.sys.sunset,
  };
}

// WMO 날씨 코드 → condition/description 매핑
const WMO_MAP: Record<number, { condition: string; description: string }> = {
  0:  { condition: 'Clear',        description: '맑음' },
  1:  { condition: 'Clear',        description: '대체로 맑음' },
  2:  { condition: 'Clouds',       description: '구름 조금' },
  3:  { condition: 'Clouds',       description: '흐림' },
  45: { condition: 'Fog',          description: '안개' },
  48: { condition: 'Fog',          description: '안개' },
  51: { condition: 'Drizzle',      description: '가벼운 이슬비' },
  53: { condition: 'Drizzle',      description: '이슬비' },
  55: { condition: 'Drizzle',      description: '강한 이슬비' },
  61: { condition: 'Rain',         description: '가벼운 비' },
  63: { condition: 'Rain',         description: '비' },
  65: { condition: 'Rain',         description: '강한 비' },
  71: { condition: 'Snow',         description: '가벼운 눈' },
  73: { condition: 'Snow',         description: '눈' },
  75: { condition: 'Snow',         description: '강한 눈' },
  77: { condition: 'Snow',         description: '싸락눈' },
  80: { condition: 'Rain',         description: '소나기' },
  81: { condition: 'Rain',         description: '소나기' },
  82: { condition: 'Rain',         description: '강한 소나기' },
  85: { condition: 'Snow',         description: '눈 소나기' },
  86: { condition: 'Snow',         description: '강한 눈 소나기' },
  95: { condition: 'Thunderstorm', description: '천둥번개' },
  96: { condition: 'Thunderstorm', description: '우박 동반 천둥' },
  99: { condition: 'Thunderstorm', description: '강한 우박 동반 천둥' },
};

function wmoLookup(code: number): { condition: string; description: string } {
  return WMO_MAP[code] ?? { condition: 'Clouds', description: '흐림' };
}

export interface OpenMeteoResult {
  forecast: ForecastData[];
  todayUvIndex: number;
  todayPrecipProb: number;
  airQuality: AirQuality | null;
}

export async function fetchOpenMeteoByCoords(lat: number, lon: number): Promise<OpenMeteoResult> {
  return fetchOpenMeteoForecast(lat, lon);
}

async function fetchOpenMeteoForecast(latitude: number, longitude: number): Promise<OpenMeteoResult> {
  const [fRes, aqRes] = await Promise.allSettled([
    fetch(
      `https://api.open-meteo.com/v1/forecast?latitude=${latitude}&longitude=${longitude}` +
      `&daily=temperature_2m_max,temperature_2m_min,weathercode,precipitation_probability_max,uv_index_max` +
      `&timezone=auto&forecast_days=15`
    ),
    fetch(
      `https://air-quality-api.open-meteo.com/v1/air-quality?latitude=${latitude}&longitude=${longitude}` +
      `&hourly=pm10,pm2_5,european_aqi&timezone=auto&forecast_days=1`
    ),
  ]);

  if (fRes.status === 'rejected' || !fRes.value.ok) throw new Error('예보를 가져올 수 없습니다');
  const fData = await fRes.value.json();

  const daily = fData.daily;
  const forecast: ForecastData[] = (daily.time as string[]).map((dateStr, i) => {
    const date = new Date(dateStr + 'T12:00:00');
    const { condition, description } = wmoLookup(daily.weathercode[i]);
    const tempMax: number = daily.temperature_2m_max[i];
    const tempMin: number = daily.temperature_2m_min[i];
    return {
      date: date.toLocaleDateString('ko-KR', { weekday: 'short', month: 'numeric', day: 'numeric' }),
      temp: Math.round((tempMax + tempMin) / 2),
      tempMin,
      tempMax,
      condition,
      description,
      precipitationProbability: daily.precipitation_probability_max[i] ?? 0,
    };
  });

  let airQuality: AirQuality | null = null;
  if (aqRes.status === 'fulfilled' && aqRes.value.ok) {
    try {
      const aqData = await aqRes.value.json();
      const times = aqData.hourly?.time as string[] | undefined;
      if (times?.length) {
        const nowHour = new Date().toISOString().slice(0, 13);
        let idx = times.findIndex(t => t.slice(0, 13) >= nowHour);
        if (idx < 0) idx = times.length - 1;
        airQuality = {
          pm25: Math.round(aqData.hourly.pm2_5[idx] ?? 0),
          pm10: Math.round(aqData.hourly.pm10[idx] ?? 0),
          aqi: Math.round(aqData.hourly.european_aqi[idx] ?? 0),
        };
      }
    } catch { /* AQI 실패 시 null 유지 */ }
  }

  return {
    forecast,
    todayUvIndex: daily.uv_index_max[0] ?? 0,
    todayPrecipProb: daily.precipitation_probability_max[0] ?? 0,
    airQuality,
  };
}

export async function fetchOpenMeteoData(city: string): Promise<OpenMeteoResult> {
  const { lat, lon } = await geocodeCity(city);
  return fetchOpenMeteoForecast(lat, lon);
}