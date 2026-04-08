import { useState, type FormEvent } from 'react';
import { Search, LocateFixed } from 'lucide-react';

interface Props {
  onSearch: (city: string) => void;
  onLocate: () => void;
  loading?: boolean;
}

export function SearchBar({ onSearch, onLocate, loading }: Props) {
  const [value, setValue] = useState('');

  const handleSubmit = (e: FormEvent) => {
    e.preventDefault();
    const trimmed = value.trim();
    if (trimmed) onSearch(trimmed);
  };

  return (
    <form onSubmit={handleSubmit}>
      <div className="flex gap-2">
        <div className="relative flex-1">
          <input
            type="text"
            value={value}
            onChange={e => setValue(e.target.value)}
            placeholder="도시를 검색하세요 (예: 서울, 부산)"
            disabled={loading}
            className="w-full pl-4 pr-12 py-3.5 rounded-xl bg-white border border-slate-200 shadow-sm
                       text-slate-800 placeholder-slate-400 text-sm
                       focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent
                       disabled:opacity-60 transition"
          />
          <button
            type="submit"
            disabled={loading}
            className="absolute right-3 top-1/2 -translate-y-1/2
                       text-slate-400 hover:text-blue-600 disabled:opacity-40 transition"
          >
            <Search className="w-5 h-5" />
          </button>
        </div>
        <button
          type="button"
          onClick={onLocate}
          disabled={loading}
          title="현재 위치로 검색"
          className="px-3.5 rounded-xl bg-white border border-slate-200 shadow-sm
                     text-slate-400 hover:text-blue-600 hover:border-blue-300
                     disabled:opacity-40 transition"
        >
          <LocateFixed className="w-5 h-5" />
        </button>
      </div>
    </form>
  );
}