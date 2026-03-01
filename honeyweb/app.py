from flask import Flask, request, render_template_string, jsonify
import logging
import datetime
import os

app = Flask(__name__)

# ─── Logging ──────────────────────────────────────────────────────
os.makedirs("/var/log/honeyweb", exist_ok=True)

logger = logging.getLogger("honeyweb")
logger.setLevel(logging.INFO)
handler = logging.FileHandler("/var/log/honeyweb/honeyweb.log")
handler.setFormatter(logging.Formatter("%(message)s"))
logger.addHandler(handler)

# ─── Template ─────────────────────────────────────────────────────
LOGIN_HTML = """
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Intranet Corporativa — Acceso</title>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }

        body {
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            background: #0f1923;
            min-height: 100vh;
            display: flex;
            align-items: center;
            justify-content: center;
            overflow: hidden;
        }

        /* Fondo animado */
        body::before {
            content: '';
            position: fixed;
            top: -50%;
            left: -50%;
            width: 200%;
            height: 200%;
            background: radial-gradient(ellipse at center, #1a2a3a 0%, #0f1923 60%);
            animation: bgPulse 8s ease-in-out infinite;
            z-index: 0;
        }

        @keyframes bgPulse {
            0%, 100% { transform: scale(1); }
            50% { transform: scale(1.05); }
        }

        /* Grid de líneas de fondo */
        .grid {
            position: fixed;
            top: 0; left: 0;
            width: 100%; height: 100%;
            background-image:
                linear-gradient(rgba(0, 150, 255, 0.03) 1px, transparent 1px),
                linear-gradient(90deg, rgba(0, 150, 255, 0.03) 1px, transparent 1px);
            background-size: 50px 50px;
            z-index: 0;
        }

        .container {
            position: relative;
            z-index: 1;
            width: 100%;
            max-width: 420px;
            padding: 20px;
        }

        /* Logo / Cabecera */
        .header {
            text-align: center;
            margin-bottom: 32px;
        }

        .logo {
            display: inline-flex;
            align-items: center;
            justify-content: center;
            width: 64px;
            height: 64px;
            background: linear-gradient(135deg, #0078d4, #005a9e);
            border-radius: 16px;
            margin-bottom: 16px;
            box-shadow: 0 8px 32px rgba(0, 120, 212, 0.3);
        }

        .logo svg {
            width: 32px;
            height: 32px;
            fill: white;
        }

        .company-name {
            font-size: 22px;
            font-weight: 700;
            color: #ffffff;
            letter-spacing: -0.5px;
        }

        .company-sub {
            font-size: 12px;
            color: #5a7a99;
            letter-spacing: 2px;
            text-transform: uppercase;
            margin-top: 4px;
        }

        /* Card */
        .card {
            background: rgba(255, 255, 255, 0.04);
            border: 1px solid rgba(255, 255, 255, 0.08);
            border-radius: 20px;
            padding: 36px 32px;
            backdrop-filter: blur(20px);
            box-shadow: 0 24px 64px rgba(0, 0, 0, 0.4);
        }

        .card-title {
            font-size: 18px;
            font-weight: 600;
            color: #e8edf2;
            margin-bottom: 6px;
        }

        .card-subtitle {
            font-size: 13px;
            color: #5a7a99;
            margin-bottom: 28px;
        }

        /* Inputs */
        .field {
            margin-bottom: 18px;
        }

        .field label {
            display: block;
            font-size: 12px;
            font-weight: 600;
            color: #7a9ab5;
            text-transform: uppercase;
            letter-spacing: 0.8px;
            margin-bottom: 8px;
        }

        .field input {
            width: 100%;
            padding: 13px 16px;
            background: rgba(255, 255, 255, 0.05);
            border: 1px solid rgba(255, 255, 255, 0.1);
            border-radius: 10px;
            color: #e8edf2;
            font-size: 14px;
            transition: all 0.2s;
            outline: none;
        }

        .field input:focus {
            border-color: #0078d4;
            background: rgba(0, 120, 212, 0.08);
            box-shadow: 0 0 0 3px rgba(0, 120, 212, 0.15);
        }

        .field input::placeholder {
            color: #3a5a7a;
        }

        /* Botón */
        .btn {
            width: 100%;
            padding: 14px;
            background: linear-gradient(135deg, #0078d4, #005a9e);
            border: none;
            border-radius: 10px;
            color: white;
            font-size: 14px;
            font-weight: 600;
            cursor: pointer;
            transition: all 0.2s;
            margin-top: 8px;
            letter-spacing: 0.3px;
        }

        .btn:hover {
            background: linear-gradient(135deg, #1a88e4, #0068b4);
            transform: translateY(-1px);
            box-shadow: 0 8px 24px rgba(0, 120, 212, 0.35);
        }

        .btn:active {
            transform: translateY(0);
        }

        .btn:disabled {
            opacity: 0.6;
            cursor: not-allowed;
            transform: none;
        }

        /* Spinner en botón */
        .btn-spinner {
            display: inline-block;
            width: 14px;
            height: 14px;
            border: 2px solid rgba(255,255,255,0.3);
            border-top-color: white;
            border-radius: 50%;
            animation: spin 0.7s linear infinite;
            margin-right: 8px;
            vertical-align: middle;
        }

        @keyframes spin {
            to { transform: rotate(360deg); }
        }

        /* Error */
        .alert {
            display: none;
            align-items: center;
            gap: 10px;
            background: rgba(220, 53, 69, 0.12);
            border: 1px solid rgba(220, 53, 69, 0.3);
            border-radius: 10px;
            padding: 12px 16px;
            margin-bottom: 20px;
            font-size: 13px;
            color: #ff6b7a;
            animation: shake 0.4s ease;
        }

        .alert.show { display: flex; }

        @keyframes shake {
            0%, 100% { transform: translateX(0); }
            20%, 60% { transform: translateX(-6px); }
            40%, 80% { transform: translateX(6px); }
        }

        .alert svg {
            width: 16px;
            height: 16px;
            flex-shrink: 0;
            fill: #ff6b7a;
        }

        /* Footer */
        .footer {
            text-align: center;
            margin-top: 24px;
            font-size: 11px;
            color: #2a4a6a;
        }

        .footer a {
            color: #3a6a9a;
            text-decoration: none;
        }

        /* Divisor */
        .divider {
            display: flex;
            align-items: center;
            gap: 12px;
            margin: 20px 0;
        }

        .divider::before, .divider::after {
            content: '';
            flex: 1;
            height: 1px;
            background: rgba(255,255,255,0.07);
        }

        .divider span {
            font-size: 11px;
            color: #3a5a7a;
            text-transform: uppercase;
            letter-spacing: 1px;
        }

        /* Badge seguridad */
        .security-badge {
            display: flex;
            align-items: center;
            justify-content: center;
            gap: 6px;
            margin-top: 20px;
            font-size: 11px;
            color: #3a5a7a;
        }

        .security-badge svg {
            width: 12px;
            height: 12px;
            fill: #3a5a7a;
        }
    </style>
</head>
<body>
    <div class="grid"></div>
    <div class="container">
        <div class="header">
            <div class="logo">
                <svg viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg">
                    <path d="M12 2L2 7l10 5 10-5-10-5zM2 17l10 5 10-5M2 12l10 5 10-5"/>
                </svg>
            </div>
            <div class="company-name">ALV Corp</div>
            <div class="company-sub">Intranet Corporativa</div>
        </div>

        <div class="card">
            <div class="card-title">Iniciar sesión</div>
            <div class="card-subtitle">Accede con tus credenciales corporativas</div>

            <div class="alert" id="alert">
                <svg viewBox="0 0 24 24"><path d="M12 2C6.48 2 2 6.48 2 12s4.48 10 10 10 10-4.48 10-10S17.52 2 12 2zm1 15h-2v-2h2v2zm0-4h-2V7h2v6z"/></svg>
                <span id="alert-msg">Usuario o contraseña incorrectos. Inténtalo de nuevo.</span>
            </div>

            <div class="field">
                <label>Usuario</label>
                <input type="text" id="username" placeholder="nombre.apellido@alvcorp.es" autocomplete="off" />
            </div>

            <div class="field">
                <label>Contraseña</label>
                <input type="password" id="password" placeholder="••••••••••••" autocomplete="off" />
            </div>

            <button class="btn" id="btn-login" onclick="doLogin()">
                Acceder
            </button>

            <div class="security-badge">
                <svg viewBox="0 0 24 24"><path d="M12 1L3 5v6c0 5.55 3.84 10.74 9 12 5.16-1.26 9-6.45 9-12V5l-9-4z"/></svg>
                Conexión cifrada · TLS 1.3
            </div>
        </div>

        <div class="footer">
            &copy; 2026 ALV Corp S.A. &nbsp;·&nbsp;
            <a href="#">Política de privacidad</a> &nbsp;·&nbsp;
            <a href="#">Soporte IT</a>
        </div>
    </div>

    <script>
        // Permitir Enter para enviar
        document.addEventListener('keydown', function(e) {
            if (e.key === 'Enter') doLogin();
        });

        function doLogin() {
            const username = document.getElementById('username').value.trim();
            const password = document.getElementById('password').value;
            const btn = document.getElementById('btn-login');
            const alert = document.getElementById('alert');

            if (!username || !password) {
                showAlert('Por favor, introduce usuario y contraseña.');
                return;
            }

            // Mostrar spinner
            btn.disabled = true;
            btn.innerHTML = '<span class="btn-spinner"></span>Verificando...';
            alert.classList.remove('show');

            fetch('/login', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ username, password })
            })
            .then(r => r.json())
            .then(data => {
                setTimeout(() => {
                    btn.disabled = false;
                    btn.innerHTML = 'Acceder';
                    showAlert(data.message || 'Usuario o contraseña incorrectos. Inténtalo de nuevo.');
                }, 800);
            })
            .catch(() => {
                btn.disabled = false;
                btn.innerHTML = 'Acceder';
                showAlert('Error de conexión. Inténtalo de nuevo.');
            });
        }

        function showAlert(msg) {
            const alert = document.getElementById('alert');
            document.getElementById('alert-msg').textContent = msg;
            alert.classList.remove('show');
            void alert.offsetWidth; // forzar reflow para reiniciar animación
            alert.classList.add('show');
        }
    </script>
</body>
</html>
"""

# ─── Rutas ────────────────────────────────────────────────────────
@app.route("/")
def index():
    return render_template_string(LOGIN_HTML)

@app.route("/login", methods=["POST"])
def login():
    data = request.get_json(silent=True) or {}
    username = data.get("username", "").strip()
    password = data.get("password", "")
    ip       = request.headers.get("X-Forwarded-For", request.remote_addr).split(",")[0].strip()
    ts       = datetime.datetime.utcnow().strftime("%Y-%m-%dT%H:%M:%S.%fZ")

    # Escribir log en formato CSV parseable por Logstash
    log_line = f"{ts},{ip},{username},{password}"
    logger.info(log_line)

    return jsonify({
        "success": False,
        "message": "Usuario o contraseña incorrectos. Inténtalo de nuevo."
    })

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=81, debug=False)
