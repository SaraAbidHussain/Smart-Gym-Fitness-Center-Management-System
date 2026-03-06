from app import create_app
from app.db import get_connection, release_connection

app = create_app()

@app.route("/test-db")
def test_db():
    try:
        conn = get_connection()
        cursor = conn.cursor()

        cursor.execute("SELECT version();")
        version = cursor.fetchone()

        cursor.close()
        release_connection(conn)

        return {"database": "connected", "version": version[0]}

    except Exception as e:
        return {"error": str(e)}


if __name__ == "__main__":
    app.run(debug=True)
