const express = require('express');
const mysql = require('mysql2/promise');
const cors = require('cors');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const axios = require('axios');
const path = require('path');
const Anthropic = require('@anthropic-ai/sdk');
require('dotenv').config({ path: path.join(__dirname, '.env') });

const anthropic = new Anthropic({ apiKey: process.env.ANTHROPIC_API_KEY });

const JWT_SECRET = process.env.JWT_SECRET || 'dev-secret-change-in-prod';

const app = express();
const ALLOWED_ORIGINS = [
  process.env.CLIENT_ORIGIN || 'http://localhost:5173',
  'http://localhost:5175',
];
app.use(cors({
  origin: (origin, cb) => {
    if (!origin || ALLOWED_ORIGINS.includes(origin)) cb(null, true);
    else cb(new Error('CORS 차단: ' + origin));
  },
}));
app.use(express.json());

// ── DB 연결 풀 ─────────────────────────────

const pool = mysql.createPool({
  host: process.env.DB_HOST || 'localhost',
  port: Number(process.env.DB_PORT) || 3306,
  user: process.env.DB_USER,
  password: process.env.DB_PASSWORD,
  database: process.env.DB_NAME,
  waitForConnections: true,
  connectionLimit: 10,
});

// ── DB 초기화 ──────────────────────────────

async function initDB() {
  const conn = await pool.getConnection();
  try {
    await conn.execute(`
      CREATE TABLE IF NOT EXISTS search_history (
        id          INT AUTO_INCREMENT PRIMARY KEY,
        user_id     INT NULL,
        city        VARCHAR(100) NOT NULL,
        searched_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        UNIQUE KEY uq_city_user (city, user_id)
      )
    `);
    // 기존 테이블에 user_id 컬럼이 없으면 추가
    await conn.execute('ALTER TABLE search_history ADD COLUMN user_id INT NULL').catch(() => {});
    await conn.execute('ALTER TABLE search_history ADD UNIQUE KEY uq_city_user (city, user_id)').catch(() => {});

    await conn.execute(`
      CREATE TABLE IF NOT EXISTS favorite_cities (
        id           INT AUTO_INCREMENT PRIMARY KEY,
        user_id      INT NULL,
        city         VARCHAR(100) NOT NULL,
        display_name VARCHAR(100) NOT NULL,
        added_at     TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        UNIQUE KEY uq_city_user (city, user_id)
      )
    `);
    // 기존 테이블에 user_id 컬럼이 없으면 추가
    await conn.execute('ALTER TABLE favorite_cities ADD COLUMN user_id INT NULL').catch(() => {});
    await conn.execute('ALTER TABLE favorite_cities DROP KEY uq_city').catch(() => {});
    await conn.execute('ALTER TABLE favorite_cities ADD UNIQUE KEY uq_city_user (city, user_id)').catch(() => {});
    await conn.execute(`
      CREATE TABLE IF NOT EXISTS users (
        id          INT AUTO_INCREMENT PRIMARY KEY,
        email       VARCHAR(255) NOT NULL,
        password    VARCHAR(255),
        username    VARCHAR(100) NOT NULL,
        provider    ENUM('local','google') NOT NULL DEFAULT 'local',
        provider_id VARCHAR(255),
        created_at  TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        UNIQUE KEY uq_email (email),
        UNIQUE KEY uq_provider (provider, provider_id)
      )
    `);
    // 기존 테이블 provider enum이 다를 경우 업데이트
    await conn.execute(`
      ALTER TABLE users
        MODIFY COLUMN provider ENUM('local','google') NOT NULL DEFAULT 'local'
    `).catch(() => {});
    console.log('DB 테이블 초기화 완료');
  } finally {
    conn.release();
  }
}

// ── 에러 핸들러 헬퍼 ────────────────────────

function asyncHandler(fn) {
  return (req, res, next) => fn(req, res, next).catch(next);
}

// ── JWT 미들웨어 ───────────────────────────

function optionalAuth(req, res, next) {
  const token = req.headers.authorization?.split(' ')[1];
  if (token) {
    try { req.user = jwt.verify(token, JWT_SECRET); } catch {}
  }
  next();
}

function authMiddleware(req, res, next) {
  const token = req.headers.authorization?.split(' ')[1];
  if (!token) return res.status(401).json({ error: '인증이 필요합니다' });
  try {
    req.user = jwt.verify(token, JWT_SECRET);
    next();
  } catch {
    res.status(401).json({ error: '유효하지 않은 토큰입니다' });
  }
}

function issueToken(user) {
  return jwt.sign(
    { id: user.id, email: user.email, username: user.username },
    JWT_SECRET,
    { expiresIn: '7d' }
  );
}

// ── 인증 라우트 ────────────────────────────

// 회원가입
app.post('/auth/register', asyncHandler(async (req, res) => {
  const { email, password, username } = req.body;
  if (!email || !password || !username) {
    return res.status(400).json({ error: '이메일, 비밀번호, 닉네임을 모두 입력해주세요' });
  }
  const [existing] = await pool.execute('SELECT id FROM users WHERE email = ?', [email]);
  if (existing.length) return res.status(409).json({ error: '이미 사용 중인 이메일입니다' });

  const hash = await bcrypt.hash(password, 10);
  const [result] = await pool.execute(
    'INSERT INTO users (email, password, username, provider) VALUES (?, ?, ?, "local")',
    [email.trim(), hash, username.trim()]
  );
  const token = issueToken({ id: result.insertId, email, username });
  res.json({ token, user: { id: result.insertId, email, username } });
}));

// 로그인
app.post('/auth/login', asyncHandler(async (req, res) => {
  const { email, password } = req.body;
  if (!email || !password) {
    return res.status(400).json({ error: '이메일과 비밀번호를 입력해주세요' });
  }
  const [rows] = await pool.execute('SELECT * FROM users WHERE email = ? AND provider = "local"', [email]);
  if (!rows.length) return res.status(401).json({ error: '이메일 또는 비밀번호가 올바르지 않습니다' });

  const user = rows[0];
  const ok = await bcrypt.compare(password, user.password);
  if (!ok) return res.status(401).json({ error: '이메일 또는 비밀번호가 올바르지 않습니다' });

  const token = issueToken(user);
  res.json({ token, user: { id: user.id, email: user.email, username: user.username } });
}));

// 구글 소셜 로그인
app.post('/auth/social/google', asyncHandler(async (req, res) => {
  const { credential, accessToken } = req.body;
  if (!credential && !accessToken) return res.status(400).json({ error: '구글 토큰이 필요합니다' });

  let providerId, email, username;

  if (credential) {
    // idToken 검증 (React 웹 / 모바일)
    const { data } = await axios.get(
      `https://oauth2.googleapis.com/tokeninfo?id_token=${credential}`
    );
    providerId = data.sub;
    email = data.email;
    username = data.name || data.email.split('@')[0];
  } else {
    // accessToken 검증 (Flutter 웹)
    const { data } = await axios.get(
      'https://www.googleapis.com/oauth2/v3/userinfo',
      { headers: { Authorization: `Bearer ${accessToken}` } }
    );
    providerId = data.sub;
    email = data.email;
    username = data.name || data.email.split('@')[0];
  }

  const [rows] = await pool.execute(
    'SELECT * FROM users WHERE provider = "google" AND provider_id = ?', [providerId]
  );

  let user;
  if (rows.length) {
    user = rows[0];
  } else {
    const [result] = await pool.execute(
      'INSERT INTO users (email, username, provider, provider_id) VALUES (?, ?, "google", ?)',
      [email, username, providerId]
    );
    user = { id: result.insertId, email, username };
  }

  const token = issueToken(user);
  res.json({ token, user: { id: user.id, email: user.email, username: user.username } });
}));

// 내 정보
app.get('/auth/me', authMiddleware, (req, res) => {
  res.json({ user: req.user });
});

// ── 검색 기록 ──────────────────────────────

app.get('/api/history', optionalAuth, asyncHandler(async (req, res) => {
  const userId = req.user?.id ?? null;
  const [rows] = await pool.execute(
    'SELECT id, city, searched_at FROM search_history WHERE user_id <=> ? ORDER BY searched_at DESC LIMIT 10',
    [userId]
  );
  res.json(rows);
}));

app.post('/api/history', optionalAuth, asyncHandler(async (req, res) => {
  const { city } = req.body;
  if (!city || typeof city !== 'string') {
    return res.status(400).json({ error: 'city 필드가 필요합니다' });
  }
  const userId = req.user?.id ?? null;
  await pool.execute(
    `INSERT INTO search_history (city, user_id) VALUES (?, ?)
     ON DUPLICATE KEY UPDATE searched_at = CURRENT_TIMESTAMP`,
    [city.trim(), userId]
  );
  res.json({ success: true });
}));

app.delete('/api/history', optionalAuth, asyncHandler(async (req, res) => {
  const userId = req.user?.id ?? null;
  await pool.execute('DELETE FROM search_history WHERE user_id <=> ?', [userId]);
  res.json({ success: true });
}));

app.delete('/api/history/:id', optionalAuth, asyncHandler(async (req, res) => {
  const id = Number(req.params.id);
  if (!Number.isInteger(id) || id <= 0) {
    return res.status(400).json({ error: '올바르지 않은 ID입니다' });
  }
  const userId = req.user?.id ?? null;
  await pool.execute('DELETE FROM search_history WHERE id = ? AND user_id <=> ?', [id, userId]);
  res.json({ success: true });
}));

// ── 즐겨찾기 ───────────────────────────────

app.get('/api/favorites', optionalAuth, asyncHandler(async (req, res) => {
  const userId = req.user?.id ?? null;
  const [rows] = await pool.execute(
    'SELECT id, city, display_name AS displayName, added_at FROM favorite_cities WHERE user_id <=> ? ORDER BY added_at DESC',
    [userId]
  );
  res.json(rows);
}));

app.post('/api/favorites', optionalAuth, asyncHandler(async (req, res) => {
  const { city, displayName } = req.body;
  if (!city || !displayName || typeof city !== 'string' || typeof displayName !== 'string') {
    return res.status(400).json({ error: 'city, displayName 필드가 필요합니다' });
  }
  const userId = req.user?.id ?? null;
  await pool.execute(
    'INSERT IGNORE INTO favorite_cities (city, display_name, user_id) VALUES (?, ?, ?)',
    [city.trim(), displayName.trim(), userId]
  );
  res.json({ success: true });
}));

app.delete('/api/favorites', optionalAuth, asyncHandler(async (req, res) => {
  const userId = req.user?.id ?? null;
  await pool.execute('DELETE FROM favorite_cities WHERE user_id <=> ?', [userId]);
  res.json({ success: true });
}));

app.delete('/api/favorites/:id', optionalAuth, asyncHandler(async (req, res) => {
  const id = Number(req.params.id);
  if (!Number.isInteger(id) || id <= 0) {
    return res.status(400).json({ error: '올바르지 않은 ID입니다' });
  }
  const userId = req.user?.id ?? null;
  await pool.execute('DELETE FROM favorite_cities WHERE id = ? AND user_id <=> ?', [id, userId]);
  res.json({ success: true });
}));

// ── AI 코디 추천 ────────────────────────────

app.post('/api/ai/outfit', asyncHandler(async (req, res) => {
  const { city, temperature, feelsLike, condition, description, humidity, windSpeed, precipProb, uvIndex, tpo, pm25, pm10 } = req.body;

  if (!city || temperature === undefined) {
    return res.status(400).json({ error: '날씨 데이터가 필요합니다' });
  }

  const tpoLabel = tpo || '일상/캐주얼';
  const temp = Math.round(temperature);
  const feels = Math.round(feelsLike ?? temperature);

  const pm25Grade =
    pm25 === undefined ? null :
    pm25 <= 15 ? '좋음' : pm25 <= 35 ? '보통' : pm25 <= 75 ? '나쁨' : '매우나쁨';
  const airQualityLine = pm25Grade
    ? `\n- 초미세먼지(PM2.5): ${pm25}㎍/㎥ (${pm25Grade}) / 미세먼지(PM10): ${pm10 ?? '-'}㎍/㎥`
    : '';

  const prompt = `당신은 패션 스타일리스트입니다. 아래 날씨 정보와 TPO를 바탕으로 실용적이고 세련된 코디를 추천해 주세요.

[날씨]
- 도시: ${city}
- 기온: ${temp}°C (체감 ${feels}°C)
- 날씨: ${description}
- 습도: ${humidity}% / 풍속: ${windSpeed}m/s
- 강수확률: ${precipProb ?? 0}% / 자외선: ${uvIndex ?? 0}${airQualityLine}

[TPO] ${tpoLabel}

아래 형식을 지켜 한국어로 답변해 주세요 (마크다운 없이 plain text):

날씨 한 줄 요약
추천 코디: 상의 → 하의 → 겉옷(필요시) → 신발 순으로 구체적인 아이템명과 색상 제안
포인트 팁: ${tpoLabel} 상황에 맞는 실용적인 스타일링 팁 1가지${pm25Grade && pm25Grade !== '좋음' ? ' (미세먼지 수준도 반영)' : ''}

총 4~6문장으로 간결하고 친근하게 작성해 주세요.`;

  res.setHeader('Content-Type', 'text/plain; charset=utf-8');
  res.setHeader('Transfer-Encoding', 'chunked');
  res.setHeader('Cache-Control', 'no-cache');

  const stream = await anthropic.messages.stream({
    model: 'claude-haiku-4-5-20251001',
    max_tokens: 512,
    messages: [{ role: 'user', content: prompt }],
  });

  for await (const chunk of stream) {
    if (chunk.type === 'content_block_delta' && chunk.delta.type === 'text_delta') {
      res.write(chunk.delta.text);
    }
  }

  res.end();
}));

// ── 전역 에러 핸들러 ────────────────────────

app.use((err, req, res, _next) => {
  console.error(err.message);
  res.status(500).json({ error: '서버 오류가 발생했습니다' });
});

// ── 서버 시작 ──────────────────────────────

const PORT = Number(process.env.PORT) || 3001;

initDB()
  .then(() => {
    app.listen(PORT, () => {
      console.log(`서버 실행 중: http://localhost:${PORT}`);
    });
  })
  .catch(err => {
    console.error('DB 연결 실패:', err.message);
    process.exit(1);
  });