import psycopg2
from psycopg2 import pool
from app.config import Config

connection_pool = psycopg2.pool.SimpleConnectionPool(
    1,
    10,
    host=Config.DB_HOST,
    port=Config.DB_PORT,
    database=Config.DB_NAME,
    user=Config.DB_USER,
    password=Config.DB_PASSWORD
)

def get_db_connection():
    return connection_pool.getconn()

def release_connection(conn):
    connection_pool.putconn(conn)


def test_connection():
    conn = get_db_connection()
    cur = conn.cursor()

    cur.execute("SELECT version();")
    version = cur.fetchone()

    print("Connected to:", version)

    cur.close()
    release_connection(conn)