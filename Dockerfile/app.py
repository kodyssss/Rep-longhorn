import os
from flask import Flask, render_template_string
import pymysql

app = Flask(__name__)

def get_db_connection():
    connection = pymysql.connect(
        host=os.getenv('DB_HOST', 'localhost'),
        user=os.getenv('DB_USER', 'root'),
        password=os.getenv('DB_PASSWORD', 'rancher'),
        database=os.getenv('DB_NAME', 'testdb')
    )
    return connection

@app.route('/')
def index():
    connection = get_db_connection()
    cursor = connection.cursor(pymysql.cursors.DictCursor)
    cursor.execute('SELECT * FROM testdb')
    rows = cursor.fetchall()
    cursor.close()
    connection.close()
    
    table_headers = rows[0].keys() if rows else []
    return render_template_string('''
        <html>
            <head>
                <title>MySQL Data</title>
            </head>
            <body>
                <h1>Data from MySQL</h1>
                <table border="1">
                    <tr>
                        {% for header in table_headers %}
                            <th>{{ header }}</th>
                        {% endfor %}
                    </tr>
                    {% for row in rows %}
                        <tr>
                            {% for cell in row.values() %}
                                <td>{{ cell }}</td>
                            {% endfor %}
                        </tr>
                    {% endfor %}
                </table>
            </body>
        </html>
    ''', table_headers=table_headers, rows=rows)

if __name__ == '__main__':
    app.run(debug=True, host='0.0.0.0', port=5000)
