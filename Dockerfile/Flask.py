from flask import Flask, render_template
import mysql.connector

app = Flask(__name__)

# MySQL连接信息
db_config = {
    'host': 'mysql-service',  # 假设MySQL服务在同一个namespace, 服务名通常为mysql-service
    'user': 'root',
    'password': 'rancher',
    'database': 'testdb'
}

@app.route('/')
def display_data():
    conn = mysql.connector.connect(**db_config)
    cursor = conn.cursor()
    cursor.execute("SELECT * FROM testdb")
    data = cursor.fetchall()
    cursor.close()
    conn.close()
    return render_template('index.html', data=data)

if __name__ == '__main__':
    app.run(host='0.0.0.0', debug=True)
