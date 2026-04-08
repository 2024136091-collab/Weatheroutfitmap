import { useState, type FormEvent } from 'react';
import { X, Mail, Lock, User } from 'lucide-react';
import { GoogleLogin } from '@react-oauth/google';
import { useAuth } from '../contexts/AuthContext';

const API = 'http://localhost:3001';

// ── 카카오 SDK 타입 선언 ──
declare global {
  interface Window {
    Kakao: {
      init: (key: string) => void;
      isInitialized: () => boolean;
      Auth: {
        login: (options: { success: (res: { access_token: string }) => void; fail: (err: unknown) => void }) => void;
      };
    };
  }
}

const KAKAO_JS_KEY = 'YOUR_KAKAO_JAVASCRIPT_KEY'; // 카카오 JavaScript 키 입력
const GOOGLE_CLIENT_ID = 'YOUR_GOOGLE_CLIENT_ID';  // Google 클라이언트 ID 입력 (main.tsx에서도 설정)

function loadKakaoSdk(): Promise<void> {
  return new Promise(resolve => {
    if (window.Kakao) { resolve(); return; }
    const script = document.createElement('script');
    script.src = 'https://developers.kakao.com/sdk/js/kakao.js';
    script.onload = () => resolve();
    document.head.appendChild(script);
  });
}

interface Props {
  onClose: () => void;
}

type Tab = 'login' | 'register';

export function LoginModal({ onClose }: Props) {
  const { login } = useAuth();
  const [tab, setTab] = useState<Tab>('login');
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [username, setUsername] = useState('');
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');

  const handleSubmit = async (e: FormEvent) => {
    e.preventDefault();
    setError('');
    setLoading(true);
    try {
      const endpoint = tab === 'login' ? '/auth/login' : '/auth/register';
      const body = tab === 'login'
        ? { email, password }
        : { email, password, username };
      const res = await fetch(`${API}${endpoint}`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(body),
      });
      const data = await res.json();
      if (!res.ok) { setError(data.error); return; }
      login(data.token, data.user);
      onClose();
    } catch {
      setError('서버에 연결할 수 없습니다');
    } finally {
      setLoading(false);
    }
  };

  const handleKakao = async () => {
    try {
      await loadKakaoSdk();
      if (!window.Kakao.isInitialized()) window.Kakao.init(KAKAO_JS_KEY);
      window.Kakao.Auth.login({
        success: async ({ access_token }) => {
          const res = await fetch(`${API}/auth/social/kakao`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ accessToken: access_token }),
          });
          const data = await res.json();
          if (!res.ok) { setError(data.error); return; }
          login(data.token, data.user);
          onClose();
        },
        fail: () => setError('카카오 로그인에 실패했습니다'),
      });
    } catch {
      setError('카카오 SDK 로드에 실패했습니다');
    }
  };

  const handleGoogle = async (credential: string) => {
    try {
      const res = await fetch(`${API}/auth/social/google`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ credential }),
      });
      const data = await res.json();
      if (!res.ok) { setError(data.error); return; }
      login(data.token, data.user);
      onClose();
    } catch {
      setError('구글 로그인에 실패했습니다');
    }
  };

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/40 backdrop-blur-sm">
      <div className="bg-white rounded-2xl shadow-xl w-full max-w-sm mx-4 p-6 relative">
        {/* 닫기 */}
        <button
          onClick={onClose}
          className="absolute top-4 right-4 text-slate-400 hover:text-slate-600 transition"
        >
          <X className="w-5 h-5" />
        </button>

        {/* 탭 */}
        <div className="flex gap-1 bg-slate-100 rounded-xl p-1 mb-6">
          {(['login', 'register'] as Tab[]).map(t => (
            <button
              key={t}
              onClick={() => { setTab(t); setError(''); }}
              className={`flex-1 py-2 rounded-lg text-sm font-medium transition
                ${tab === t ? 'bg-white shadow text-slate-800' : 'text-slate-500'}`}
            >
              {t === 'login' ? '로그인' : '회원가입'}
            </button>
          ))}
        </div>

        {/* 폼 */}
        <form onSubmit={handleSubmit} className="space-y-3">
          {tab === 'register' && (
            <div className="relative">
              <User className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-slate-400" />
              <input
                type="text"
                placeholder="닉네임"
                value={username}
                onChange={e => setUsername(e.target.value)}
                className="w-full pl-10 pr-4 py-3 rounded-xl border border-slate-200 text-sm focus:outline-none focus:ring-2 focus:ring-blue-500"
                required
              />
            </div>
          )}
          <div className="relative">
            <Mail className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-slate-400" />
            <input
              type="email"
              placeholder="이메일"
              value={email}
              onChange={e => setEmail(e.target.value)}
              className="w-full pl-10 pr-4 py-3 rounded-xl border border-slate-200 text-sm focus:outline-none focus:ring-2 focus:ring-blue-500"
              required
            />
          </div>
          <div className="relative">
            <Lock className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-slate-400" />
            <input
              type="password"
              placeholder="비밀번호"
              value={password}
              onChange={e => setPassword(e.target.value)}
              className="w-full pl-10 pr-4 py-3 rounded-xl border border-slate-200 text-sm focus:outline-none focus:ring-2 focus:ring-blue-500"
              required
            />
          </div>

          {error && (
            <p className="text-xs text-red-500 text-center">{error}</p>
          )}

          <button
            type="submit"
            disabled={loading}
            className="w-full py-3 bg-blue-500 hover:bg-blue-600 text-white rounded-xl text-sm font-medium transition disabled:opacity-60"
          >
            {loading ? '처리 중...' : tab === 'login' ? '로그인' : '회원가입'}
          </button>
        </form>

        {/* 구분선 */}
        <div className="flex items-center gap-3 my-4">
          <div className="flex-1 h-px bg-slate-100" />
          <span className="text-xs text-slate-400">또는</span>
          <div className="flex-1 h-px bg-slate-100" />
        </div>

        {/* 소셜 로그인 */}
        <div className="space-y-2">
          {/* 카카오 */}
          <button
            onClick={handleKakao}
            className="w-full flex items-center justify-center gap-2 py-3 bg-[#FEE500] hover:bg-[#F5DC00] text-[#3C1E1E] rounded-xl text-sm font-medium transition"
          >
            <svg width="18" height="18" viewBox="0 0 18 18" fill="none">
              <path fillRule="evenodd" clipRule="evenodd"
                d="M9 1C4.582 1 1 3.896 1 7.455c0 2.285 1.52 4.29 3.818 5.408L3.9 16.3a.3.3 0 0 0 .456.316L8.4 13.88a9.8 9.8 0 0 0 .6.027c4.418 0 8-2.895 8-6.452C17 3.896 13.418 1 9 1Z"
                fill="#3C1E1E"/>
            </svg>
            카카오로 로그인
          </button>

          {/* 구글 */}
          <div className="flex justify-center">
            <GoogleLogin
              onSuccess={({ credential }) => credential && handleGoogle(credential)}
              onError={() => setError('구글 로그인에 실패했습니다')}
              width="100%"
              text={tab === 'login' ? 'signin_with' : 'signup_with'}
              locale="ko"
            />
          </div>
        </div>
      </div>
    </div>
  );
}

export { GOOGLE_CLIENT_ID };