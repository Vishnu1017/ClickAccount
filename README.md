<h1 align="center">📒 ClickAccount</h1>
<h3 align="center">A Flutter-based billing and accounting app</h3>

<p align="center">
  <a href="https://github.com/Vishnu1017/ClickAccount">
    <img src="https://img.shields.io/github/stars/Vishnu1017/ClickAccount?style=social" alt="GitHub Stars">
  </a>
  <a href="https://github.com/Vishnu1017/ClickAccount">
    <img src="https://img.shields.io/github/forks/Vishnu1017/ClickAccount?style=social" alt="GitHub Forks">
  </a>
  <a href="https://github.com/Vishnu1017/ClickAccount">
    <img src="https://img.shields.io/github/issues/Vishnu1017/ClickAccount" alt="Issues">
  </a>
  <a href="https://github.com/Vishnu1017/ClickAccount">
    <img src="https://img.shields.io/github/license/Vishnu1017/ClickAccount" alt="License">
  </a>
</p>

<h2>🧾 About the App</h2>
<p><strong>ClickAccount</strong> is a Flutter application designed for small businesses, freelancers, and entrepreneurs to manage users, roles, customers, products, and invoices efficiently. It uses <strong>Hive</strong> for local offline-first storage and allows generating GST-compliant PDF invoices with embedded UPI QR codes.</p>

<h2>🔧 Features</h2>
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

<h2>📁 Project Structure</h2>
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

<h2>🚀 Getting Started</h2>

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

<h2>🛠️ Technologies Used</h2>
<p>
  <a href="https://flutter.dev" target="_blank"><img src="https://www.vectorlogo.zone/logos/flutterio/flutterio-icon.svg" alt="Flutter" width="40" height="40" style="margin-right:10px"/></a>
  <a href="https://dart.dev" target="_blank"><img src="https://raw.githubusercontent.com/devicons/devicon/master/icons/dart/dart-original.svg" alt="Dart" width="40" height="40" style="margin-right:10px"/></a>
 <a href="https://pub.dev/packages/hive" target="_blank">
  <img src="https://raw.githubusercontent.com/hivedb/hive/master/logo/hive.png" alt="Hive" width="40" height="40"/>
</a>

  <a href="https://www.w3.org/html/" target="_blank"><img src="https://cdn.jsdelivr.net/gh/devicons/devicon/icons/html5/html5-original.svg" alt="HTML5" width="40" height="40"/></a>
</p>


<h2>📈 Roadmap</h2>
<ul>
  <li>Dark mode support</li>
  <li>Multi-user support</li>
  <li>Cloud sync and backup (optional)</li>
  <li>Analytics dashboard for invoices and revenue</li>
  <li>Custom themes and branding options</li>
</ul>

<h2>👤 Author</h2>
<ul>
  <li>Vishnu Chandan</li>
  <li>GitHub: <a href="https://github.com/Vishnu1017">Vishnu1017</a></li>
  <li>Email: (playroll.vish@gmail.com)</li>
</ul>

<h2>📄 License</h2>
<p>MIT License – see LICENSE file for details.</p>

<h2>📸 Screenshots</h2>
<p>Make sure to add your app screenshots in <code>assets/screenshots/</code> directory.</p>
<ul>
  <li><img src="assets/screenshots/login.png" alt="Login Screen" width="250"/></li>
  <li><img src="assets/screenshots/dashboard.png" alt="Dashboard" width="250"/></li>
  <li><img src="assets/screenshots/invoice.png" alt="Invoice Screen" width="250"/></li>
</ul>

