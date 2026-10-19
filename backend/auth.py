import hashlib
import hmac
import re
import secrets
from datetime import datetime, timedelta, timezone

from .store import marker, transaction


class UserExists(ValueError):
    pass


def _credentials(payload):
    if not isinstance(payload, dict):
        raise ValueError('Expected a JSON object')
    username, password = payload.get('username'), payload.get('password')
    if not isinstance(username, str) or not re.fullmatch(r'[A-Za-z0-9_]{3,40}', username):
        raise ValueError('Username must contain 3 to 40 letters, digits, or underscores')
    if not isinstance(password, str) or not 10 <= len(password) <= 128:
        raise ValueError('Password must contain 10 to 128 characters')
    return username.lower(), password


def password_hash(password, salt):
    return hashlib.pbkdf2_hmac('sha256', password.encode(), bytes.fromhex(salt), 310000).hex()


def create_user(db, payload):
    username, password = _credentials(payload)
    salt = secrets.token_hex(16)
    p = marker(db)
    with transaction(db):
        row = db.execute(f'''INSERT INTO users(username,password_hash,salt,created_at)
            VALUES ({p},{p},{p},{p}) ON CONFLICT(username) DO NOTHING RETURNING id, username''',
            (username, password_hash(password, salt), salt, datetime.now(timezone.utc).isoformat())).fetchone()
        if row is None:
            raise UserExists('This username is already taken')
    return dict(row)


def login(db, payload):
    username, password = _credentials(payload)
    row = db.execute(f'SELECT * FROM users WHERE username = {marker(db)}', (username,)).fetchone()
    salt = row['salt'] if row else '0' * 32
    candidate = password_hash(password, salt)
    if row is None or not hmac.compare_digest(candidate, row['password_hash']):
        return None
    return {'id': row['id'], 'username': row['username']}


def create_session(db, user):
    token = secrets.token_urlsafe(32)
    token_hash = hashlib.sha256(token.encode()).hexdigest()
    expires_at = (datetime.now(timezone.utc) + timedelta(hours=8)).isoformat()
    p = marker(db)
    with transaction(db):
        db.execute(f'DELETE FROM sessions WHERE expires_at < {p}', (datetime.now(timezone.utc).isoformat(),))
        db.execute(f'INSERT INTO sessions(token_hash,user_id,expires_at) VALUES ({p},{p},{p})',
                   (token_hash, user['id'], expires_at))
    return {'token': token, 'user': user, 'expires_at': expires_at}


def current_user(db, authorization):
    if not authorization.startswith('Bearer ') or len(authorization) > 512:
        return None
    token_hash = hashlib.sha256(authorization[7:].encode()).hexdigest()
    p = marker(db)
    row = db.execute(f'''SELECT users.id, users.username FROM sessions JOIN users ON users.id=sessions.user_id
        WHERE token_hash={p} AND expires_at>{p}''', (token_hash, datetime.now(timezone.utc).isoformat())).fetchone()
    return dict(row) if row else None


def logout(db, authorization):
    token_hash = hashlib.sha256(authorization[7:].encode()).hexdigest()
    with transaction(db):
        db.execute(f'DELETE FROM sessions WHERE token_hash={marker(db)}', (token_hash,))
