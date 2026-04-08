const express = require('express');
const mysql = require('mysql2/promise');
const cors = require('cors');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const axios = require('axios');
require('dotenv').config();

const JWT_SECRET = process.env.JWT_SECRET || 'dev-secret-change-in-prod';

const app = express();
app.use(cors({ origin: process.env.CLIENT_ORIGIN || 'http://localhost:5173' }));
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
        id         INT AUTO_INCREMENT PRIMARY KEY,
        city       VARCHAR(100) NOT NULL,
        searched_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      )
    `);
    await conn.execute(`
      CREATE TABLE IF NOT EXISTS favorite_cities (
        id           INT AUTO_INCREMENT PRIMARY KEY,
        city         VARCHAR(100) NOT NULL,
        display_name VARCHAR(100) NOT NULL,
        added_at     TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        UNIQUE KEY uq_city (city)
      )
    `);
    await conn.execute(`
      CREATE TABLE IF NOT EXISTS users (
        id          INT AUTO_INCREMENT PRIMARY KEY,
        email       VARCHAR(255) NOT NULL,
        password    VARCHAR(255),
        username    VARCHAR(100) NOT NULL,
        provider    ENUM('local','kakao','google') NOT NULL DEFAULT 'local',
        provider_id VARCHAR(255),
        created_at  TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        UNIQUE KEY uq_email (email),
        UNIQUE KEY uq_provider (provider, provider_id)
      )
    `);
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

// 카카오 소셜 로그인
app.post('/auth/social/kakao', asyncHandler(async (req, res) => {
  const { accessToken } = req.body;
  if (!accessToken) return res.status(400).json({ error: '카카오 토큰이 필요합니다' });

  const { data } = await axios.get('https://kapi.kakao.com/v2/user/me', {
    headers: { Authorization: `Bearer ${accessToken}` },
  });

  const providerId = String(data.id);
  const email = data.kakao_account?.email || `kakao_${providerId}@kakao.com`;
  const username = data.properties?.nickname || '카카오 사용자';

  const [rows] = await pool.execute(
    'SELECT * FROM users WHERE provider = "kakao" AND provider_id = ?', [providerId]
  );

  let user;
  if (rows.length) {
    user = rows[0];
  } else {
    const [result] = await pool.execute(
      'INSERT INTO users (email, username, provider, provider_id) VALUES (?, ?, "kakao", ?)',
      [email, username, providerId]
    );
    user = { id: result.insertId, email, username };
  }

  const token = issueToken(user);
  res.json({ token, user: { id: user.id, email: user.email, username: user.username } });
}));

// 구글 소셜 로그인
app.post('/auth/social/google', asyncHandler(async (req, res) => {
  const { credential } = req.body;
  if (!credential) return res.status(400).json({ error: '구글 토큰이 필요합니다' });

  const { data } = await axios.get(
    `https://oauth2.googleapis.com/tokeninfo?id_token=${credential}`
  );

  const providerId = data.sub;
  const email = data.email;
  const username = data.name || data.email.split('@')[0];

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

app.get('/api/history', asyncHandler(async (req, res) => {
  const [rows] = await pool.execute(
    'SELECT id, city, searched_at FROM search_history ORDER BY searched_at DESC LIMIT 10'
  );
  res.json(rows);
}));

app.post('/api/history', asyncHandler(async (req, res) => {
  const { city } = req.body;
  if (!city || typeof city !== 'string') {
    return res.status(400).json({ error: 'city 필드가 필요합니다' });
  }
  // 같은 도시가 이미 있으면 업데이트, 없으면 삽입
  await pool.execute(
    `INSERT INTO search_history (city) VALUES (?)
     ON DUPLICATE KEY UPDATE searched_at = CURRENT_TIMESTAMP`,
    [city.trim()]
  );
  res.json({ success: true });
}));

app.delete('/api/history', asyncHandler(async (req, res) => {
  await pool.execute('DELETE FROM search_history');
  res.json({ success: true });
}));

// ── 즐겨찾기 ───────────────────────────────

app.get('/api/favorites', asyncHandler(async (req, res) => {
  const [rows] = await pool.execute(
    'SELECT id, city, display_name AS displayName, added_at FROM favorite_cities ORDER BY added_at DESC'
  );
  res.json(rows);
}));

app.post('/api/favorites', asyncHandler(async (req, res) => {
  const { city, displayName } = req.body;
  if (!city || !displayName || typeof city !== 'string' || typeof displayName !== 'string') {
    return res.status(400).json({ error: 'city, displayName 필드가 필요합니다' });
  }
  await pool.execute(
    'INSERT IGNORE INTO favorite_cities (city, display_name) VALUES (?, ?)',
    [city.trim(), displayName.trim()]
  );
  res.json({ success: true });
}));

app.delete('/api/favorites/:id', asyncHandler(async (req, res) => {
  const id = Number(req.params.id);
  if (!Number.isInteger(id) || id <= 0) {
    return res.status(400).json({ error: '올바르지 않은 ID입니다' });
  }
  await pool.execute('DELETE FROM favorite_cities WHERE id = ?', [id]);
  res.json({ success: true });
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