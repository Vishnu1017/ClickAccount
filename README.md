<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>ClickAccount README</title>
<style>
  body {
    font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
    background-color: #f8f9fa;
    color: #2c3e50;
    line-height: 1.6;
    padding: 20px;
  }
  h1, h2, h3 {
    color: #2c3e50;
  }
  h1 {
    text-align: center;
  }
  h3 {
    margin-top: 20px;
  }
  p, ul {
    margin: 10px 0;
  }
  ul {
    list-style-type: disc;
    margin-left: 40px;
  }
  a {
    color: #4b6cb7;
    text-decoration: none;
  }
  a:hover {
    text-decoration: underline;
  }
  .center {
    text-align: center;
  }
  .badge {
    margin: 5px;
  }
  code {
    background-color: #e0e7ff;
    padding: 2px 6px;
    border-radius: 4px;
  }
  .section {
    margin-top: 30px;
    padding: 20px;
    background-color: #ffffff;
    border-radius: 10px;
    box-shadow: 0px 5px 15px rgba(0,0,0,0.05);
  }
</style>
</head>
<body>

<h1>📒 ClickAccount</h1>
<h3 class="center">A Flutter-based billing and accounting app</h3>

<h3>Connect with me:</h3>
<p>
  <a href="https://github.com/Vishnu1017" target="_blank">GitHub</a> |
  <a href="mailto:youremail@example.com" target="_blank">Email</a>
</p>

<h3>Languages and Tools:</h3>
<p>
  <a href="https://flutter.dev" target="_blank"><img class="badge" src="https://www.vectorlogo.zone/logos/flutterio/flutterio-icon.svg" alt="Flutter" width="40" height="40"/></a>
  <a href="https://www.w3.org/html/" target="_blank"><img class="badge" src="https://raw.githubusercontent.com/devicons/devicon/master/icons/html5/html5-original-wordmark.svg" alt="HTML5" width="40" height="40"/></a>
  <a href="https://dart.dev" target="_blank"><img class="badge" src="https://raw.githubusercontent.com/devicons/devicon/master/icons/dart/dart-original.svg" alt="Dart" width="40" height="40"/></a>
  <a href="https://pub.dev/packages/hive" target="_blank"><img class="badge" src="https://raw.githubusercontent.com/hivedb/hive/master/logo/logo.png" alt="Hive" width="40" height="40"/></a>
</p>

<div class="section">
  <h2>About the App</h2>
  <p><strong>ClickAccount</strong> is a Flutter application for small businesses, freelancers, and entrepreneurs to manage users, roles, customers, products, and invoices efficiently. It uses <strong>Hive</strong> for local offline-first storage and allows generating GST-compliant PDF invoices with embedded UPI QR codes.</p>
</div>

<div class="section">
  <h2>Features</h2>
  <ul>
    <li>Login with email/phone and passcode</li>
    <li>Android biometric authentication (Fingerprint/Face ID)</li>
    <li>Session management with auto-login</li>
    <li>Role selection during signup (Photographer, Sales, Manager, etc.)</li>
    <li>Manage users, products, and customers locally using Hive</li>
    <li>Create, edit, and manage GST-compliant invoices</li>
    <li>Generate and share PDF invoices with UPI QR codes</li>
    <li>Offline-first functionality for fast performance</li>
  </ul>
</div>

<div class="section">
  <h2>Project Structure</h2>
  <pre>
lib/
├── models/          # Hive data models (User, Product, Invoice)
├── screens/         # App screens (Login, Signup, Dashboard, AuthGate, Passcode)
├── widgets/         # Reusable UI components
├── services/        # Business logic (PDF, Invoice generation, UPI QR)
└── main.dart        # App entry point
assets/              # Images, icons, fonts
android/
ios/
web/
  </pre>
</div>

<div class="section">
  <h2>Getting Started</h2>
  <h3>Prerequisites</h3>
  <ul>
    <li>Flutter 3.x or higher</li>
    <li>Dart 3.x</li>
    <li>Android 5.0+ for biometric authentication</li>
  </ul>

  <h3>Installation</h3>
  <pre>
git clone https://github.com/Vishnu1017/ClickAccount.git
cd ClickAccount
flutter pub get
  </pre>

  <h3>Running the App</h3>
  <pre>flutter run</pre>

  <h3>Building Release Versions</h3>
  <pre>
flutter build apk    # Android
flutter build ios    # iOS (requires Xcode)
flutter build web    # Web
  </pre>
</div>

<div class="section">
  <h2>Roadmap</h2>
  <ul>
    <li>Dark mode support</li>
    <li>Multi-user support</li>
    <li>Cloud sync and backup (optional)</li>
    <li>Analytics dashboard for invoices and revenue</li>
    <li>Custom themes and branding options</li>
  </ul>
</div>

<div class="section">
  <h2>Author</h2>
  <ul>
    <li>Vishnu Chandan</li>
    <li>GitHub: <a href="https://github.com/Vishnu1017">Vishnu1017</a></li>
    <li>Email: (add your email here)</li>
  </ul>
</div>

<div class="section">
  <h2>License</h2>
  <p>MIT License – see LICENSE file for details.</p>
</div>

</body>
</html>
