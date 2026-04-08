import { useState, useEffect, useCallback } from 'react';
import {
  getHistory, addHistory, clearHistory,
  getFavorites, addFavorite, removeFavorite,
  type HistoryItem, type FavoriteItem,
} from '../utils/api';

export function useStorage() {
  const [history, setHistory] = useState<HistoryItem[]>([]);
  const [favorites, setFavorites] = useState<FavoriteItem[]>([]);
  const [ready, setReady] = useState(false);

  useEffect(() => {
    Promise.all([
      getHistory().catch(() => [] as HistoryItem[]),
      getFavorites().catch(() => [] as FavoriteItem[]),
    ]).then(([h, f]) => {
      setHistory(h);
      setFavorites(f);
      setReady(true);
    });
  }, []);

  const saveHistory = useCallback(async (city: string) => {
    try {
      await addHistory(city);
      const updated = await getHistory();
      setHistory(updated);
    } catch {
      // 서버 미연결 시 무시
    }
  }, []);

  const deleteHistory = useCallback(async () => {
    try {
      await clearHistory();
      setHistory([]);
    } catch {
      // 서버 미연결 시 무시
    }
  }, []);

  const toggleFavorite = useCallback(async (city: string, displayName: string) => {
    const existing = favorites.find(f => f.city === city);
    try {
      if (existing) {
        await removeFavorite(existing.id);
      } else {
        await addFavorite(city, displayName);
      }
      const updated = await getFavorites();
      setFavorites(updated);
    } catch {
      // 서버 미연결 시 무시
    }
  }, [favorites]);

  const deleteFavorite = useCallback(async (id: number) => {
    try {
      await removeFavorite(id);
      setFavorites(prev => prev.filter(f => f.id !== id));
    } catch {
      // 서버 미연결 시 무시
    }
  }, []);

  const isFavorite = useCallback((city: string) => {
    return favorites.some(f => f.city === city);
  }, [favorites]);

  return { history, favorites, ready, saveHistory, deleteHistory, toggleFavorite, deleteFavorite, isFavorite };
}