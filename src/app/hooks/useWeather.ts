import { useState, useCallback } from 'react';
import { fetchWeatherData, fetchOpenMeteoData, fetchWeatherByCoords, fetchOpenMeteoByCoords } from '../utils/weatherApi';
import type { WeatherData, ForecastData } from '../types/weather';

interface WeatherState {
  weather: WeatherData | null;
  forecast: ForecastData[];
  todayUvIndex: number;
  todayPrecipProb: number;
  loading: boolean;
  error: string | null;
}

export function useWeather() {
  const [state, setState] = useState<WeatherState>({
    weather: null,
    forecast: [],
    todayUvIndex: 0,
    todayPrecipProb: 0,
    loading: false,
    error: null,
  });

  const search = useCallback(async (city: string) => {
    const query = city.trim();
    setState(s => ({ ...s, loading: true, error: null }));

    try {
      const [weatherResult, openMeteoResult] = await Promise.allSettled([
        fetchWeatherData(query),
        fetchOpenMeteoData(query),
      ]);

      if (weatherResult.status === 'rejected') {
        throw weatherResult.reason;
      }

      const openMeteo = openMeteoResult.status === 'fulfilled' ? openMeteoResult.value : null;

      setState({
        weather: weatherResult.value,
        forecast: openMeteo?.forecast ?? [],
        todayUvIndex: openMeteo?.todayUvIndex ?? 0,
        todayPrecipProb: openMeteo?.todayPrecipProb ?? 0,
        loading: false,
        error: null,
      });

      return weatherResult.value;
    } catch (err) {
      const message = err instanceof Error ? err.message : '날씨 정보를 가져오는데 실패했습니다';
      setState(s => ({ ...s, loading: false, error: message }));
      return null;
    }
  }, []);

  const searchByLocation = useCallback((): Promise<WeatherData | null> => {
    return new Promise(resolve => {
      if (!navigator.geolocation) {
        setState(s => ({ ...s, error: 'GPS를 지원하지 않는 브라우저입니다' }));
        resolve(null);
        return;
      }
      setState(s => ({ ...s, loading: true, error: null }));
      navigator.geolocation.getCurrentPosition(
        async ({ coords }) => {
          const { latitude, longitude } = coords;
          try {
            const [weatherResult, openMeteoResult] = await Promise.allSettled([
              fetchWeatherByCoords(latitude, longitude),
              fetchOpenMeteoByCoords(latitude, longitude),
            ]);
            if (weatherResult.status === 'rejected') throw weatherResult.reason;
            const openMeteo = openMeteoResult.status === 'fulfilled' ? openMeteoResult.value : null;
            setState({
              weather: weatherResult.value,
              forecast: openMeteo?.forecast ?? [],
              todayUvIndex: openMeteo?.todayUvIndex ?? 0,
              todayPrecipProb: openMeteo?.todayPrecipProb ?? 0,
              loading: false,
              error: null,
            });
            resolve(weatherResult.value);
          } catch (err) {
            const message = err instanceof Error ? err.message : '날씨 정보를 가져오는데 실패했습니다';
            setState(s => ({ ...s, loading: false, error: message }));
            resolve(null);
          }
        },
        () => {
          setState(s => ({ ...s, loading: false, error: '위치 권한이 거부되었습니다' }));
          resolve(null);
        }
      );
    });
  }, []);

  return { ...state, search, searchByLocation };
}