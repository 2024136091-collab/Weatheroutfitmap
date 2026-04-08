import type { Favorite } from '../types/weather';

const BASE_URL = 'http://localhost:3001/api';

export interface HistoryItem {
  id: number;
  city: string;
  searched_at: string;
}

async function request<T>(path: string, options?: RequestInit): Promise<T> {
  const res = await fetch(`${BASE_URL}${path}`, options);
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