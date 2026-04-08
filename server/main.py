from fastapi import FastAPI, HTTPException, Depends
from fastapi.middleware.cors import CORSMiddleware
from contextlib import asynccontextmanager
from pydantic import BaseModel
import aiomysql
import httpx
import jwt as pyjwt
from passlib.context import CryptContext
from dotenv import load_dotenv
import os

load_dotenv()

JWT_SECRET = os.getenv("JWT_SECRET", "dev-secret-change-in-prod")
CLIENT_ORIGIN = os.getenv("CLIENT_ORIGIN", "http://localhost:5174")

DB_CONFIG = {
    "host": os.getenv("DB_HOST", "localhost"),
    "port": int(os.getenv("DB_PORT", 3306)),
    "user": os.getenv("DB_USER"),
    "password": os.getenv("DB_PASSWORD", ""),
    "db": os.getenv("DB_NAME"),
    "autocommit": True,
    "charset": "utf8mb4",
}

pwd_ctx = CryptContext(schemes=["bcrypt"], deprecated="auto")
pool: aiomysql.Pool = None


# ── DB 초기화 ──────────────────────────────

async def init_db():
    async with pool.acquire() as conn:
        async with conn.cursor() as cur:
            await cur.execute("""
                CREATE TABLE IF NOT EXISTS search_history (
                    id          INT AUTO_INCREMENT PRIMARY KEY,
                    city        VARCHAR(100) NOT NULL,
                    searched_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
                )
            """)
            await cur.execute("""
                CREATE TABLE IF NOT EXISTS favorite_cities (
                    id           INT AUTO_INCREMENT PRIMARY KEY,
                    city         VARCHAR(100) NOT NULL,
                    display_name VARCHAR(100) NOT NULL,
                    added_at     TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                    UNIQUE KEY uq_city (city)
                )
            """)
            await cur.execute("""
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
            """)
    print("DB 테이블 초기화 완료")


@asynccontextmanager
async def lifespan(app: FastAPI):
    global pool
    pool = await aiomysql.create_pool(**DB_CONFIG, minsize=1, maxsize=10)
    await init_db()
    print(f"서버 실행 중: http://localhost:{os.getenv('PORT', 3001)}")
    yield
    pool.close()
    await pool.wait_closed()


app = FastAPI(lifespan=lifespan)

app.add_middleware(
    CORSMiddleware,
    allow_origins=[CLIENT_ORIGIN],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


# ── JWT ───────────────────────────────────

def issue_token(user: dict) -> str:
    return pyjwt.encode(
        {"id": user["id"], "email": user["email"], "username": user["username"]},
        JWT_SECRET,
        algorithm="HS256",
    )


def verify_token(token: str) -> dict:
    try:
        return pyjwt.decode(token, JWT_SECRET, algorithms=["HS256"])
    except pyjwt.PyJWTError:
        raise HTTPException(status_code=401, detail="유효하지 않은 토큰입니다")


async def auth_required(authorization: str = None) -> dict:
    from fastapi import Header
    if not authorization or not authorization.startswith("Bearer "):
        raise HTTPException(status_code=401, detail="인증이 필요합니다")
    return verify_token(authorization.split(" ")[1])


# ── 스키마 ────────────────────────────────

class RegisterBody(BaseModel):
    email: str
    password: str
    username: str

class LoginBody(BaseModel):
    email: str
    password: str

class KakaoBody(BaseModel):
    accessToken: str

class GoogleBody(BaseModel):
    credential: str

class HistoryBody(BaseModel):
    city: str

class FavoriteBody(BaseModel):
    city: str
    displayName: str


# ── 인증 라우트 ────────────────────────────

@app.post("/auth/register")
async def register(body: RegisterBody):
    async with pool.acquire() as conn:
        async with conn.cursor(aiomysql.DictCursor) as cur:
            await cur.execute("SELECT id FROM users WHERE email = %s", (body.email,))
            if await cur.fetchone():
                raise HTTPException(status_code=409, detail="이미 사용 중인 이메일입니다")
            hashed = pwd_ctx.hash(body.password)
            await cur.execute(
                'INSERT INTO users (email, password, username, provider) VALUES (%s, %s, %s, "local")',
                (body.email.strip(), hashed, body.username.strip()),
            )
            user_id = cur.lastrowid
    user = {"id": user_id, "email": body.email, "username": body.username}
    return {"token": issue_token(user), "user": user}


@app.post("/auth/login")
async def login(body: LoginBody):
    async with pool.acquire() as conn:
        async with conn.cursor(aiomysql.DictCursor) as cur:
            await cur.execute(
                'SELECT * FROM users WHERE email = %s AND provider = "local"', (body.email,)
            )
            user = await cur.fetchone()
    if not user or not pwd_ctx.verify(body.password, user["password"]):
        raise HTTPException(status_code=401, detail="이메일 또는 비밀번호가 올바르지 않습니다")
    u = {"id": user["id"], "email": user["email"], "username": user["username"]}
    return {"token": issue_token(u), "user": u}


@app.post("/auth/social/kakao")
async def kakao_login(body: KakaoBody):
    async with httpx.AsyncClient() as client:
        r = await client.get(
            "https://kapi.kakao.com/v2/user/me",
            headers={"Authorization": f"Bearer {body.accessToken}"},
        )
    data = r.json()
    provider_id = str(data["id"])
    email = data.get("kakao_account", {}).get("email") or f"kakao_{provider_id}@kakao.com"
    username = data.get("properties", {}).get("nickname", "카카오 사용자")

    async with pool.acquire() as conn:
        async with conn.cursor(aiomysql.DictCursor) as cur:
            await cur.execute(
                'SELECT * FROM users WHERE provider = "kakao" AND provider_id = %s', (provider_id,)
            )
            user = await cur.fetchone()
            if not user:
                await cur.execute(
                    'INSERT INTO users (email, username, provider, provider_id) VALUES (%s, %s, "kakao", %s)',
                    (email, username, provider_id),
                )
                user = {"id": cur.lastrowid, "email": email, "username": username}
    u = {"id": user["id"], "email": user["email"], "username": user["username"]}
    return {"token": issue_token(u), "user": u}


@app.post("/auth/social/google")
async def google_login(body: GoogleBody):
    async with httpx.AsyncClient() as client:
        r = await client.get(
            f"https://oauth2.googleapis.com/tokeninfo?id_token={body.credential}"
        )
    data = r.json()
    if "error" in data:
        raise HTTPException(status_code=401, detail="구글 토큰이 유효하지 않습니다")
    provider_id = data["sub"]
    email = data["email"]
    username = data.get("name") or email.split("@")[0]

    async with pool.acquire() as conn:
        async with conn.cursor(aiomysql.DictCursor) as cur:
            await cur.execute(
                'SELECT * FROM users WHERE provider = "google" AND provider_id = %s', (provider_id,)
            )
            user = await cur.fetchone()
            if not user:
                await cur.execute(
                    'INSERT INTO users (email, username, provider, provider_id) VALUES (%s, %s, "google", %s)',
                    (email, username, provider_id),
                )
                user = {"id": cur.lastrowid, "email": email, "username": username}
    u = {"id": user["id"], "email": user["email"], "username": user["username"]}
    return {"token": issue_token(u), "user": u}


@app.get("/auth/me")
async def me(authorization: str = None):
    from fastapi import Header
    if not authorization or not authorization.startswith("Bearer "):
        raise HTTPException(status_code=401, detail="인증이 필요합니다")
    user = verify_token(authorization.split(" ")[1])
    return {"user": user}


# ── 검색 기록 ──────────────────────────────

@app.get("/api/history")
async def get_history():
    async with pool.acquire() as conn:
        async with conn.cursor(aiomysql.DictCursor) as cur:
            await cur.execute(
                "SELECT id, city, searched_at FROM search_history ORDER BY searched_at DESC LIMIT 10"
            )
            rows = await cur.fetchall()
    return [{"id": r["id"], "city": r["city"], "searched_at": r["searched_at"].isoformat()} for r in rows]


@app.post("/api/history")
async def add_history(body: HistoryBody):
    async with pool.acquire() as conn:
        async with conn.cursor() as cur:
            await cur.execute(
                "INSERT INTO search_history (city) VALUES (%s) ON DUPLICATE KEY UPDATE searched_at = CURRENT_TIMESTAMP",
                (body.city.strip(),),
            )
    return {"success": True}


@app.delete("/api/history")
async def clear_history():
    async with pool.acquire() as conn:
        async with conn.cursor() as cur:
            await cur.execute("DELETE FROM search_history")
    return {"success": True}


# ── 즐겨찾기 ───────────────────────────────

@app.get("/api/favorites")
async def get_favorites():
    async with pool.acquire() as conn:
        async with conn.cursor(aiomysql.DictCursor) as cur:
            await cur.execute(
                "SELECT id, city, display_name AS displayName, added_at FROM favorite_cities ORDER BY added_at DESC"
            )
            rows = await cur.fetchall()
    return [{"id": r["id"], "city": r["city"], "displayName": r["displayName"], "added_at": r["added_at"].isoformat()} for r in rows]


@app.post("/api/favorites")
async def add_favorite(body: FavoriteBody):
    async with pool.acquire() as conn:
        async with conn.cursor() as cur:
            await cur.execute(
                "INSERT IGNORE INTO favorite_cities (city, display_name) VALUES (%s, %s)",
                (body.city.strip(), body.displayName.strip()),
            )
    return {"success": True}


@app.delete("/api/favorites/{fav_id}")
async def delete_favorite(fav_id: int):
    if fav_id <= 0:
        raise HTTPException(status_code=400, detail="올바르지 않은 ID입니다")
    async with pool.acquire() as conn:
        async with conn.cursor() as cur:
            await cur.execute("DELETE FROM favorite_cities WHERE id = %s", (fav_id,))
    return {"success": True}