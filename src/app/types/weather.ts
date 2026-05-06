export interface WeatherData {
  city: string;
  country: string;
  district?: string;
  temperature: number;
  feelsLike: number;
  description: string;
  condition: string;
  humidity: number;
  windSpeed: number;
  pressure: number;
  visibility: number;
  sunrise?: number;
  sunset?: number;
}

export interface AirQuality {
  pm25: number;
  pm10: number;
  aqi: number;
}

export interface ForecastData {
  date: string;
  temp: number;
  tempMin: number;
  tempMax: number;
  condition: string;
  description: string;
  precipitationProbability: number;
}

export interface Favorite {
  city: string;
  displayName: string;
}