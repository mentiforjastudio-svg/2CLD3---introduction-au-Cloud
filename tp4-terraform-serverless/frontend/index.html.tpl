<!DOCTYPE html>
<html lang="fr">
<head>
  <meta charset="UTF-8">
  <title>Auth App – 2CLD3</title>
  <style>
    body {
      font-family: Arial, sans-serif;
      background: #f0f4f8;
      display: flex;
      justify-content: center;
      align-items: center;
      min-height: 100vh;
      margin: 0;
    }
    .container {
      background: white;
      padding: 40px;
      border-radius: 16px;
      box-shadow: 0 4px 20px rgba(0,0,0,0.1);
      width: 100%;
      max-width: 400px;
    }
    h1 { color: #1a3a6b; text-align: center; margin-top: 0; }
    h2 { color: #6d28d9; margin-top: 0; }
    .tabs { display: flex; gap: 8px; margin-bottom: 24px; }
    .tab {
      flex: 1; padding: 10px; border: 2px solid #dce6f2;
      background: white; border-radius: 8px; cursor: pointer;
      font-weight: bold; color: #5d6980;
    }
    .tab.active { border-color: #6d28d9; color: #6d28d9; background: #f3f0ff; }
    input {
      width: 100%; padding: 10px; margin-bottom: 12px;
      border: 1px solid #dce6f2; border-radius: 8px;
      font-size: 1rem; box-sizing: border-box;
    }
    button.submit {
      width: 100%; padding: 12px; background: #6d28d9;
      color: white; border: none; border-radius: 8px;
      font-size: 1rem; font-weight: bold; cursor: pointer;
    }
    button.submit:hover { background: #5b21b6; }
    button.logout {
      width: 100%; padding: 10px; background: #fee2e2;
      color: #991b1b; border: none; border-radius: 8px;
      font-size: .95rem; font-weight: bold; cursor: pointer;
      margin-top: 12px;
    }
    .message { margin-top: 12px; padding: 10px; border-radius: 8px; font-size: .93rem; }
    .message.error { background: #fee2e2; color: #991b1b; }
    .message.success { background: #d1fae5; color: #065f46; }
    .hidden { display: none; }
    .connected-box { text-align: center; }
    .token-box {
      background: #f3f0ff; border-radius: 8px; padding: 10px;
      font-family: monospace; font-size: .8rem; word-break: break-all;
      color: #6d28d9; margin-top: 12px;
    }
    .badge {
      display: inline-block; background: #e8f4fd; color: #0b65c2;
      padding: 4px 12px; border-radius: 999px; font-size: .85rem; margin-top: 8px;
    }
  </style>
</head>
<body>
<div class="container">
  <h1>🔐 Auth App</h1>

  <div class="tabs" id="tabs">
    <button class="tab active" onclick="showTab('register', this)">Inscription</button>
    <button class="tab" onclick="showTab('login', this)">Connexion</button>
  </div>

  <!-- Formulaire inscription -->
  <div id="register">
    <h2>Créer un compte</h2>
    <input type="email" id="reg-email" placeholder="Email">
    <input type="password" id="reg-password" placeholder="Mot de passe">
    <button class="submit" onclick="doRegister()">S'inscrire</button>
    <div id="reg-msg" class="message hidden"></div>
  </div>

  <!-- Formulaire connexion -->
  <div id="login" class="hidden">
    <h2>Se connecter</h2>
    <input type="email" id="login-email" placeholder="Email">
    <input type="password" id="login-password" placeholder="Mot de passe">
    <button class="submit" onclick="doLogin()">Se connecter</button>
    <div id="login-msg" class="message hidden"></div>
  </div>

  <!-- État connecté -->
  <div id="connected" class="connected-box hidden">
    <h2>Connecté</h2>
    <p id="user-display"></p>
    <div class="token-box" id="token-display"></div>
    <div class="badge">Session active</div>
    <button class="logout" onclick="doLogout()">Se déconnecter</button>
  </div>

  <p style="text-align:center; color:#5d6980; font-size:.8rem; margin-bottom:0">
    2CLD3 – Déployé avec Terraform + LocalStack
  </p>
</div>

<script>
  // URL de l'API injectée par Terraform au moment du déploiement
  const API_URL = "${api_url}";

  function showTab(tab, btn) {
    ["register", "login"].forEach(function(id) {
      document.getElementById(id).classList.add("hidden");
    });
    document.querySelectorAll(".tab").forEach(function(t) {
      t.classList.remove("active");
    });
    document.getElementById(tab).classList.remove("hidden");
    btn.classList.add("active");
  }

  function showMsg(id, text, type) {
    var el = document.getElementById(id);
    el.textContent = text;
    el.className = "message " + type;
  }

  async function doRegister() {
    var email = document.getElementById("reg-email").value.trim();
    var password = document.getElementById("reg-password").value;
    if (!email || !password) {
      showMsg("reg-msg", "Remplir tous les champs.", "error");
      return;
    }
    try {
      var res = await fetch(API_URL + "/register", {
        method: "POST",
        headers: {"Content-Type": "application/json"},
        body: JSON.stringify({"email": email, "password": password})
      });
      var data = await res.json();
      if (res.ok) {
        sessionStorage.setItem("token", data.token);
        sessionStorage.setItem("email", data.email);
        showConnected(data.email, data.token);
      } else {
        showMsg("reg-msg", data.error, "error");
      }
    } catch(e) {
      showMsg("reg-msg", "Erreur réseau : " + e.message, "error");
    }
  }

  async function doLogin() {
    var email = document.getElementById("login-email").value.trim();
    var password = document.getElementById("login-password").value;
    if (!email || !password) {
      showMsg("login-msg", "Remplir tous les champs.", "error");
      return;
    }
    try {
      var res = await fetch(API_URL + "/login", {
        method: "POST",
        headers: {"Content-Type": "application/json"},
        body: JSON.stringify({"email": email, "password": password})
      });
      var data = await res.json();
      if (res.ok) {
        sessionStorage.setItem("token", data.token);
        sessionStorage.setItem("email", data.email);
        showConnected(data.email, data.token);
      } else {
        showMsg("login-msg", data.error, "error");
      }
    } catch(e) {
      showMsg("login-msg", "Erreur réseau : " + e.message, "error");
    }
  }

  function showConnected(email, token) {
    document.getElementById("tabs").classList.add("hidden");
    document.getElementById("register").classList.add("hidden");
    document.getElementById("login").classList.add("hidden");
    document.getElementById("connected").classList.remove("hidden");
    document.getElementById("user-display").textContent = email;
    document.getElementById("token-display").textContent = "Token : " + token;
  }

  function doLogout() {
    sessionStorage.clear();
    location.reload();
  }

  // Restaurer la session si elle existe déjà
  if (sessionStorage.getItem("token")) {
    showConnected(
      sessionStorage.getItem("email"),
      sessionStorage.getItem("token")
    );
  }
</script>
</body>
</html>
