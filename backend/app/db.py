import psycopg2
from psycopg2 import pool
from .config import Config

connection_pool = None

def init_db():
    global connection_pool

    connection_pool = psycopg2.pool.SimpleConnectionPool(
        1,
        10,
        host=Config.DB_HOST,
        port=Config.DB_PORT,
        database=Config.DB_NAME,
        user=Config.DB_USER,
        password=Config.DB_PASSWORD
    )

def get_connection():
    return connection_pool.getconn()

def release_connection(conn):
    connection_pool.putconn(conn)
