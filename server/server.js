const express = require('express');
const mysql = require('mysql2/promise');
const cors = require('cors');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const axios = require('axios');
const multer = require('multer');
const path = require('path');
const fs = require('fs');
const Anthropic = require('@anthropic-ai/sdk');
require('dotenv').config({ path: path.join(__dirname, '.env') });

const anthropic = new Anthropic({ apiKey: process.env.ANTHROPIC_API_KEY });
const JWT_SECRET = process.env.JWT_SECRET || 'dev-secret-change-in-prod';

const app = express();

const ALLOWED_ORIGINS = [
  'http://localhost:3000',
  'http://localhost:3001',
  'http://localhost:5173',
  'http://localhost:5174',
  'http://localhost:5175',
  'http://localhost:5176',
  ...(process.env.CLIENT_ORIGIN ? [process.env.CLIENT_ORIGIN] : []),
];
app.use(cors({
  origin: (origin, cb) => {
    if (!origin || ALLOWED_ORIGINS.includes(origin)) cb(null, true);
    else cb(new Error('CORS 차단: ' + origin));
  },
}));
app.use(express.json());

// ── 파일 업로드 설정 ────────────────────────
const uploadsDir = path.join(__dirname, 'uploads');
if (!fs.existsSync(uploadsDir)) fs.mkdirSync(uploadsDir, { recursive: true });

const storage = multer.diskStorage({
  destination: (req, file, cb) => cb(null, uploadsDir),
  filename: (req, file, cb) => {
    const ext = path.extname(file.originalname) || '.jpg';
    cb(null, `${Date.now()}_${Math.random().toString(36).slice(2)}${ext}`);
  },
});
const upload = multer({ storage, limits: { fileSize: 10 * 1024 * 1024 } });

app.use('/uploads', express.static(uploadsDir));

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
      CREATE TABLE IF NOT EXISTS users (
        id          INT AUTO_INCREMENT PRIMARY KEY,
        email       VARCHAR(255) NOT NULL,
        password    VARCHAR(255),
        name        VARCHAR(100) NOT NULL DEFAULT '',
        age         VARCHAR(20)  NOT NULL DEFAULT '20대',
        style       VARCHAR(50)  NOT NULL DEFAULT '캐주얼',
        provider    ENUM('local','google') NOT NULL DEFAULT 'local',
        provider_id VARCHAR(255),
        created_at  TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        UNIQUE KEY uq_email (email),
        UNIQUE KEY uq_provider (provider, provider_id)
      )
    `);
    for (const col of [
      "ADD COLUMN name                   VARCHAR(100) NOT NULL DEFAULT ''",
      "ADD COLUMN age                    VARCHAR(20)  NOT NULL DEFAULT '20대'",
      "ADD COLUMN style                  VARCHAR(50)  NOT NULL DEFAULT '캐주얼'",
      "ADD COLUMN profile_image          VARCHAR(500) NULL",
      "ADD COLUMN withdrawal_requested_at DATETIME    NULL",
    ]) {
      await conn.execute(`ALTER TABLE users ${col}`).catch(() => {});
    }

    // 30일 경과한 탈퇴 신청 계정 자동 삭제
    const [pendingUsers] = await conn.execute(
      `SELECT id FROM users WHERE withdrawal_requested_at IS NOT NULL
       AND withdrawal_requested_at <= DATE_SUB(NOW(), INTERVAL 30 DAY)`
    );
    for (const u of pendingUsers) {
      const [items] = await conn.execute('SELECT image_url FROM closet_items WHERE user_id = ?', [u.id]);
      for (const item of items) {
        const fp = path.join(__dirname, item.image_url);
        if (fs.existsSync(fp)) fs.unlinkSync(fp);
      }
      const [uRow] = await conn.execute('SELECT profile_image FROM users WHERE id = ?', [u.id]);
      if (uRow.length && uRow[0].profile_image) {
        const fp = path.join(__dirname, uRow[0].profile_image);
        if (fs.existsSync(fp)) fs.unlinkSync(fp);
      }
      await conn.execute('DELETE FROM closet_items WHERE user_id = ?', [u.id]);
      await conn.execute('DELETE FROM search_history WHERE user_id = ?', [u.id]);
      await conn.execute('DELETE FROM favorite_cities WHERE user_id = ?', [u.id]);
      await conn.execute('DELETE FROM users WHERE id = ?', [u.id]);
    }
    if (pendingUsers.length) console.log(`만료된 탈퇴 계정 ${pendingUsers.length}개 삭제 완료`);

    await conn.execute(`
      CREATE TABLE IF NOT EXISTS closet_items (
        id          INT AUTO_INCREMENT PRIMARY KEY,
        user_id     INT NOT NULL,
        image_url   VARCHAR(500) NOT NULL,
        category    VARCHAR(50)  NOT NULL DEFAULT '기타',
        description VARCHAR(200) NOT NULL DEFAULT '',
        color       VARCHAR(50)  NOT NULL DEFAULT '',
        style       VARCHAR(50)  NOT NULL DEFAULT '',
        season      VARCHAR(20)  NOT NULL DEFAULT '사계절',
        created_at  TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        KEY idx_user (user_id)
      )
    `);

    await conn.execute(`
      CREATE TABLE IF NOT EXISTS search_history (
        id          INT AUTO_INCREMENT PRIMARY KEY,
        user_id     INT NULL,
        city        VARCHAR(100) NOT NULL,
        searched_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        UNIQUE KEY uq_city_user (city, user_id)
      )
    `);
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
    await conn.execute('ALTER TABLE favorite_cities ADD COLUMN user_id INT NULL').catch(() => {});
    await conn.execute('ALTER TABLE favorite_cities DROP KEY uq_city').catch(() => {});
    await conn.execute('ALTER TABLE favorite_cities ADD UNIQUE KEY uq_city_user (city, user_id)').catch(() => {});

    console.log('DB 테이블 초기화 완료');
  } finally {
    conn.release();
  }
}

// ── 헬퍼 ──────────────────────────────────
function asyncHandler(fn) {
  return (req, res, next) => fn(req, res, next).catch(next);
}

function optionalAuth(req, res, next) {
  const token = req.headers.authorization?.split(' ')[1];
  if (token) {
    try { req.user = jwt.verify(token, JWT_SECRET); } catch {}
  }
  next();
}

function authMiddleware(req, res, next) {
  const token = req.headers.authorization?.split(' ')[1];
  if (!token) return res.status(401).json({ detail: '인증이 필요합니다' });
  try {
    req.user = jwt.verify(token, JWT_SECRET);
    next();
  } catch {
    res.status(401).json({ detail: '유효하지 않은 토큰입니다' });
  }
}

function issueToken(user) {
  return jwt.sign({ id: user.id, email: user.email }, JWT_SECRET, { expiresIn: '7d' });
}

// ── AI 크레딧 부족 시 규칙 기반 폴백 ──────────
function fallbackRecommendation(temperature, weatherStatus, userAge, userStyle) {
  let outfit = '';
  if (temperature >= 28) {
    outfit = '반소매 티셔츠와 반바지 또는 얇은 원피스를 추천합니다. 통풍이 잘 되는 린넨 소재가 좋아요.';
  } else if (temperature >= 23) {
    outfit = '얇은 반소매 티셔츠에 청바지나 면 소재 팬츠를 추천합니다.';
  } else if (temperature >= 17) {
    outfit = '긴소매 셔츠나 가디건을 걸치고, 청바지나 슬랙스를 매치해 보세요.';
  } else if (temperature >= 11) {
    outfit = '얇은 니트나 맨투맨에 청바지, 가벼운 재킷을 레이어드하세요.';
  } else if (temperature >= 5) {
    outfit = '두꺼운 니트나 코트를 착용하고 스카프도 챙기세요.';
  } else {
    outfit = '패딩이나 두꺼운 코트, 목도리와 장갑을 꼭 챙기세요.';
  }
  const weatherTip =
    weatherStatus.includes('비') ? ' 우산을 꼭 챙기세요.' :
    weatherStatus.includes('눈') ? ' 미끄럼 방지 신발을 신으세요.' :
    weatherStatus.includes('뇌우') ? ' 외출을 자제하고 우산을 준비하세요.' : '';
  return `오늘 ${weatherStatus} 날씨에 ${temperature}°C입니다. ${outfit}${weatherTip} ${userAge} ${userStyle} 스타일에 맞게 코디해 보세요!`;
}

// ── WMO 날씨 코드 → 한국어 ─────────────────
function wmoToKorean(code) {
  if (code === 0) return '맑음';
  if (code <= 3) return '구름 조금';
  if (code <= 48) return '안개';
  if (code <= 55) return '이슬비';
  if (code <= 65) return '비';
  if (code <= 75) return '눈';
  if (code <= 82) return '소나기';
  if (code >= 95) return '뇌우';
  return '흐림';
}

// ── 인증 ──────────────────────────────────

app.post('/auth/register', asyncHandler(async (req, res) => {
  const { name, email, password, age = '20대', style = '캐주얼' } = req.body;
  if (!name || !email || !password) {
    return res.status(400).json({ detail: '이름, 이메일, 비밀번호를 모두 입력해주세요' });
  }
  if (password.length < 6) {
    return res.status(400).json({ detail: '비밀번호는 6자 이상이어야 합니다' });
  }
  const [existing] = await pool.execute('SELECT id FROM users WHERE email = ?', [email.trim()]);
  if (existing.length) return res.status(409).json({ detail: '이미 사용 중인 이메일입니다' });

  const hash = await bcrypt.hash(password, 10);
  const [result] = await pool.execute(
    'INSERT INTO users (email, password, username, name, age, style, provider) VALUES (?, ?, ?, ?, ?, ?, "local")',
    [email.trim(), hash, name.trim(), name.trim(), age, style]
  );
  const token = issueToken({ id: result.insertId, email: email.trim() });
  res.json({ token, name: name.trim(), email: email.trim(), age, style });
}));

app.post('/auth/login', asyncHandler(async (req, res) => {
  const { email, password } = req.body;
  if (!email || !password) {
    return res.status(400).json({ detail: '이메일과 비밀번호를 입력해주세요' });
  }
  const [rows] = await pool.execute(
    'SELECT * FROM users WHERE email = ? AND provider = "local"', [email.trim()]
  );
  if (!rows.length) return res.status(401).json({ detail: '이메일 또는 비밀번호가 올바르지 않습니다' });

  const user = rows[0];
  const ok = await bcrypt.compare(password, user.password);
  if (!ok) return res.status(401).json({ detail: '이메일 또는 비밀번호가 올바르지 않습니다' });

  const token = issueToken(user);
  res.json({
    token,
    name: user.name || user.email.split('@')[0],
    email: user.email,
    age: user.age || '20대',
    style: user.style || '캐주얼',
    withdrawal_requested_at: user.withdrawal_requested_at || null,
  });
}));

app.get('/auth/me', authMiddleware, asyncHandler(async (req, res) => {
  const [rows] = await pool.execute(
    'SELECT name, email, age, style, profile_image, withdrawal_requested_at FROM users WHERE id = ?',
    [req.user.id]
  );
  if (!rows.length) return res.status(401).json({ detail: '사용자를 찾을 수 없습니다' });
  res.json(rows[0]);
}));

app.post('/auth/profile-image', authMiddleware, upload.single('image'), asyncHandler(async (req, res) => {
  if (!req.file) return res.status(400).json({ detail: '이미지를 선택해주세요' });
  const imageUrl = `/uploads/${req.file.filename}`;
  const [rows] = await pool.execute('SELECT profile_image FROM users WHERE id = ?', [req.user.id]);
  if (rows.length && rows[0].profile_image) {
    const old = path.join(__dirname, rows[0].profile_image);
    if (fs.existsSync(old)) fs.unlinkSync(old);
  }
  await pool.execute('UPDATE users SET profile_image = ? WHERE id = ?', [imageUrl, req.user.id]);
  res.json({ profile_image: imageUrl });
}));

app.put('/auth/profile', authMiddleware, asyncHandler(async (req, res) => {
  const { age, style } = req.body;
  if (!age || !style) return res.status(400).json({ detail: '연령대와 스타일을 입력해주세요' });
  await pool.execute('UPDATE users SET age = ?, style = ? WHERE id = ?', [age, style, req.user.id]);
  res.json({ success: true });
}));

app.put('/auth/password', authMiddleware, asyncHandler(async (req, res) => {
  const { current_password, new_password } = req.body;
  if (!current_password || !new_password) {
    return res.status(400).json({ detail: '비밀번호를 입력해주세요' });
  }
  if (new_password.length < 6) {
    return res.status(400).json({ detail: '새 비밀번호는 6자 이상이어야 합니다' });
  }
  const [rows] = await pool.execute('SELECT password FROM users WHERE id = ?', [req.user.id]);
  if (!rows.length) return res.status(404).json({ detail: '사용자를 찾을 수 없습니다' });

  const ok = await bcrypt.compare(current_password, rows[0].password);
  if (!ok) return res.status(401).json({ detail: '현재 비밀번호가 올바르지 않습니다' });

  const hash = await bcrypt.hash(new_password, 10);
  await pool.execute('UPDATE users SET password = ? WHERE id = ?', [hash, req.user.id]);
  res.json({ success: true });
}));

app.delete('/auth/withdraw', authMiddleware, asyncHandler(async (req, res) => {
  const userId = req.user.id;
  const [rows] = await pool.execute('SELECT withdrawal_requested_at FROM users WHERE id = ?', [userId]);
  if (!rows.length) return res.status(404).json({ detail: '사용자를 찾을 수 없습니다' });
  if (rows[0].withdrawal_requested_at) {
    return res.status(409).json({ detail: '이미 탈퇴 신청이 처리 중입니다' });
  }
  await pool.execute('UPDATE users SET withdrawal_requested_at = NOW() WHERE id = ?', [userId]);
  res.json({ success: true, message: '탈퇴 신청이 완료됐습니다. 30일 후 계정이 완전히 삭제됩니다.' });
}));

app.post('/auth/withdraw/cancel', authMiddleware, asyncHandler(async (req, res) => {
  await pool.execute('UPDATE users SET withdrawal_requested_at = NULL WHERE id = ?', [req.user.id]);
  res.json({ success: true });
}));

// ── 날씨 + AI 추천 ─────────────────────────

app.get('/recommend-smart', optionalAuth, asyncHandler(async (req, res) => {
  const { lat, lon, city: cityQuery } = req.query;
  let latitude, longitude, cityName;

  if (lat && lon) {
    latitude = parseFloat(lat);
    longitude = parseFloat(lon);
    try {
      const { data } = await axios.get(
        `https://nominatim.openstreetmap.org/reverse?lat=${latitude}&lon=${longitude}&format=json`,
        { headers: { 'User-Agent': 'WeatherStyleApp/1.0' }, timeout: 5000 }
      );
      cityName = data.address?.city || data.address?.county || data.address?.state || '내 위치';
    } catch {
      cityName = '내 위치';
    }
  } else {
    const query = cityQuery || 'Seongnam';
    const { data } = await axios.get(
      `https://geocoding-api.open-meteo.com/v1/search?name=${encodeURIComponent(query)}&count=1&language=ko`,
      { timeout: 5000 }
    );
    const result = data.results?.[0];
    if (!result) return res.status(404).json({ detail: '도시를 찾을 수 없습니다' });
    latitude = result.latitude;
    longitude = result.longitude;
    cityName = result.name;
  }

  const { data: weatherData } = await axios.get(
    `https://api.open-meteo.com/v1/forecast` +
    `?latitude=${latitude}&longitude=${longitude}` +
    `&current=temperature_2m,weathercode,windspeed_10m,relativehumidity_2m` +
    `&timezone=Asia/Seoul`,
    { timeout: 5000 }
  );
  const cur = weatherData.current;
  const temperature = cur.temperature_2m;
  const weatherStatus = wmoToKorean(cur.weathercode);
  const humidity = cur.relativehumidity_2m;
  const windSpeed = cur.windspeed_10m;

  let userAge = '20대', userStyle = '캐주얼';
  if (req.user) {
    const [rows] = await pool.execute(
      'SELECT age, style FROM users WHERE id = ?', [req.user.id]
    );
    if (rows.length) { userAge = rows[0].age; userStyle = rows[0].style; }
  }

  let aiRecommendation;
  try {
    const aiRes = await anthropic.messages.create({
      model: 'claude-haiku-4-5-20251001',
      max_tokens: 300,
      messages: [{
        role: 'user',
        content: `현재 날씨: ${cityName}, ${temperature}°C, ${weatherStatus}, 습도 ${humidity}%, 풍속 ${windSpeed}m/s\n사용자: ${userAge} ${userStyle} 스타일\n날씨에 맞는 오늘의 코디를 3~4문장으로 추천해주세요.`,
      }],
    });
    aiRecommendation = aiRes.content[0].text;
  } catch (e) {
    console.error('AI 추천 오류 (폴백 사용):', e.message);
    aiRecommendation = fallbackRecommendation(temperature, weatherStatus, userAge, userStyle);
  }

  const seed = Math.abs(Math.floor(temperature * 10)) % 1000;
  res.json({
    city: cityName,
    temperature,
    weather_status: weatherStatus,
    humidity,
    wind_speed: windSpeed,
    ai_recommendation: aiRecommendation,
    recommended_clothes: [
      { image_url: `https://picsum.photos/seed/outfit${seed}/600/800` },
    ],
  });
}));

// ── 옷장 ──────────────────────────────────

app.get('/closet', authMiddleware, asyncHandler(async (req, res) => {
  const [rows] = await pool.execute(
    'SELECT id, image_url, category, description, color, style, season, created_at FROM closet_items WHERE user_id = ? ORDER BY created_at DESC',
    [req.user.id]
  );
  res.json(rows);
}));

app.post('/closet/upload', authMiddleware, upload.single('file'), asyncHandler(async (req, res) => {
  if (!req.file) return res.status(400).json({ detail: '파일이 없습니다' });

  const imageUrl = `/uploads/${req.file.filename}`;
  let category = '기타', description = '의류', color = '', style = '캐주얼', season = '사계절';

  try {
    const imageData = fs.readFileSync(req.file.path).toString('base64');
    const ext = path.extname(req.file.filename).toLowerCase();
    const mimeType = ext === '.png' ? 'image/png' : ext === '.webp' ? 'image/webp' : 'image/jpeg';

    const aiRes = await anthropic.messages.create({
      model: 'claude-haiku-4-5-20251001',
      max_tokens: 200,
      messages: [{
        role: 'user',
        content: [
          { type: 'image', source: { type: 'base64', media_type: mimeType, data: imageData } },
          { type: 'text', text: '이 옷을 분석해서 JSON만 반환하세요: {"category":"상의/하의/아우터/신발/악세서리/원피스/기타","description":"20자 이내 한국어 설명","color":"주요 색상","style":"캐주얼/스트릿/포멀/스포티/미니멀","season":"봄/여름/가을/겨울/사계절"}' },
        ],
      }],
    });

    const match = aiRes.content[0].text.match(/\{[\s\S]*?\}/);
    if (match) {
      const parsed = JSON.parse(match[0]);
      category = parsed.category || category;
      description = parsed.description || description;
      color = parsed.color || color;
      style = parsed.style || style;
      season = parsed.season || season;
    }
  } catch (e) {
    console.error('AI 분석 오류:', e.message);
  }

  const [result] = await pool.execute(
    'INSERT INTO closet_items (user_id, image_url, category, description, color, style, season) VALUES (?, ?, ?, ?, ?, ?, ?)',
    [req.user.id, imageUrl, category, description, color, style, season]
  );

  res.json({
    message: '옷장에 추가됐어요!',
    items: [{ id: result.insertId, image_url: imageUrl, category, description, color, style, season }],
  });
}));

app.delete('/closet/:id', authMiddleware, asyncHandler(async (req, res) => {
  const id = Number(req.params.id);
  if (!Number.isInteger(id) || id <= 0) return res.status(400).json({ detail: '올바르지 않은 ID' });

  const [rows] = await pool.execute(
    'SELECT image_url FROM closet_items WHERE id = ? AND user_id = ?', [id, req.user.id]
  );
  if (rows.length) {
    const filePath = path.join(__dirname, rows[0].image_url);
    if (fs.existsSync(filePath)) fs.unlinkSync(filePath);
  }
  await pool.execute('DELETE FROM closet_items WHERE id = ? AND user_id = ?', [id, req.user.id]);
  res.json({ success: true });
}));

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
  if (!city || typeof city !== 'string') return res.status(400).json({ detail: 'city 필드가 필요합니다' });
  const userId = req.user?.id ?? null;
  await pool.execute(
    'INSERT INTO search_history (city, user_id) VALUES (?, ?) ON DUPLICATE KEY UPDATE searched_at = CURRENT_TIMESTAMP',
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
  if (!Number.isInteger(id) || id <= 0) return res.status(400).json({ detail: '올바르지 않은 ID' });
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
  if (!city || !displayName) return res.status(400).json({ detail: 'city, displayName 필드가 필요합니다' });
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
  if (!Number.isInteger(id) || id <= 0) return res.status(400).json({ detail: '올바르지 않은 ID' });
  const userId = req.user?.id ?? null;
  await pool.execute('DELETE FROM favorite_cities WHERE id = ? AND user_id <=> ?', [id, userId]);
  res.json({ success: true });
}));

// ── AI 코디 추천 (스트리밍) ─────────────────

app.post('/api/ai/outfit', asyncHandler(async (req, res) => {
  const { city, temperature, feelsLike, condition, description, humidity, windSpeed, precipProb, uvIndex } = req.body;
  if (!city || temperature === undefined) {
    return res.status(400).json({ detail: '날씨 데이터가 필요합니다' });
  }

  const prompt = `현재 날씨 정보를 바탕으로 오늘 입기 좋은 코디를 추천해 주세요.
날씨: ${city}, ${Math.round(temperature)}°C (체감 ${Math.round(feelsLike ?? temperature)}°C), ${description}
습도: ${humidity}%, 풍속: ${windSpeed}m/s, 강수확률: ${precipProb ?? 0}%, UV: ${uvIndex ?? 0}
3~5문장으로 추천해주세요: 날씨 요약 + 추천 의상 + 생활 팁`;

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

// ── 에러 핸들러 ────────────────────────────

app.use((err, req, res, _next) => {
  console.error(err.message);
  res.status(500).json({ detail: '서버 오류가 발생했습니다' });
});

// ── 서버 시작 ──────────────────────────────

const PORT = Number(process.env.PORT) || 3001;

initDB()
  .then(() => app.listen(PORT, () => console.log(`서버 실행 중: http://localhost:${PORT}`)))
  .catch(err => { console.error('DB 연결 실패:', err.message); process.exit(1); });