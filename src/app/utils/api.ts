import type { Favorite } from '../types/weather';

const BASE_URL = 'http://localhost:3001/api';

export interface HistoryItem {
  id: number;
  city: string;
  searched_at: string;
}

function authHeaders(): HeadersInit {
  const token = localStorage.getItem('auth_token');
  return token ? { Authorization: `Bearer ${token}` } : {};
}

async function request<T>(path: string, options?: RequestInit): Promise<T> {
  const res = await fetch(`${BASE_URL}${path}`, {
    ...options,
    headers: { ...authHeaders(), ...(options?.headers ?? {}) },
  });
  if (!res.ok) throw new Error(`API 오류: ${res.status}`);
  return res.json();
}

// ── 검색 기록 ──────────────────────────────

export async function getHistory(): Promise<HistoryItem[]> {
  return request('/history');
}

export async function addHistory(city: string): Promise<void> {
  await request('/history', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ city }),
  });
}

export async function clearHistory(): Promise<void> {
  await request('/history', { method: 'DELETE' });
}

export async function deleteHistoryItem(id: number): Promise<void> {
  await request(`/history/${id}`, { method: 'DELETE' });
}

// ── 즐겨찾기 ───────────────────────────────

export interface FavoriteItem extends Favorite {
  id: number;
}

export async function getFavorites(): Promise<FavoriteItem[]> {
  return request('/favorites');
}

export async function addFavorite(city: string, displayName: string): Promise<void> {
  await request('/favorites', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ city, displayName }),
  });
}

export async function removeFavorite(id: number): Promise<void> {
  await request(`/favorites/${id}`, { method: 'DELETE' });
}

export async function clearFavorites(): Promise<void> {
  await request('/favorites', { method: 'DELETE' });
}

// ── AI 코디 추천 ───────────────────────────

export interface OutfitAiRequest {
  city: string;
  temperature: number;
  feelsLike?: number;
  condition: string;
  description: string;
  humidity: number;
  windSpeed: number;
  precipProb?: number;
  uvIndex?: number;
  tpo?: string;
  pm25?: number;
  pm10?: number;
}

/** 스트리밍 응답. onChunk 콜백으로 텍스트를 조각씩 받는다. */
export async function streamAiOutfit(
  data: OutfitAiRequest,
  onChunk: (text: string) => void,
  signal?: AbortSignal
): Promise<void> {
  const res = await fetch(`${BASE_URL}/ai/outfit`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(data),
    signal,
  });
  if (!res.ok) throw new Error('AI 추천을 가져올 수 없습니다');

  const reader = res.body?.getReader();
  if (!reader) throw new Error('스트림을 읽을 수 없습니다');

  const decoder = new TextDecoder();
  while (true) {
    const { done, value } = await reader.read();
    if (done) break;
    onChunk(decoder.decode(value, { stream: true }));
  }
}