from flask import Flask, render_template

app = Flask(__name__)

@app.route('/')
def index():
    return render_template('login.html')

@app.route('/registro')
def registro():
    return render_template('registro.html')

@app.route('/albumes')
def albumes():
    return render_template('albumes.html')

@app.route('/canciones')
def canciones():
    return render_template('canciones.html')

@app.route('/busqueda')
def busqueda():
    return render_template('busqueda.html')

if __name__ == '__main__':
    app.run(debug=True)
