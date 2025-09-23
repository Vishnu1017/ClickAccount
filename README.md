<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>ClickAccount README</title>
<style>
    body {
        font-family: Arial, sans-serif;
        line-height: 1.6;
        padding: 20px;
        background-color: #f8f9fa;
        color: #212529;
    }
    h1, h2, h3 {
        color: #2c3e50;
    }
    h1 {
        border-bottom: 2px solid #2c3e50;
        padding-bottom: 5px;
    }
    ul {
        list-style-type: disc;
        margin-left: 20px;
    }
    code {
        background-color: #e9ecef;
        padding: 2px 6px;
        border-radius: 4px;
    }
    a {
        color: #007bff;
        text-decoration: none;
    }
    a:hover {
        text-decoration: underline;
    }
    .section {
        margin-bottom: 30px;
    }
    .note {
        background-color: #fff3cd;
        padding: 10px;
        border-left: 5px solid #ffeeba;
        margin: 10px 0;
    }
</style>
</head>
<body>

<h1>📒 ClickAccount</h1>

<p><strong>ClickAccount</strong> is a Flutter-based billing and accounting app designed for small businesses, freelancers, and entrepreneurs. It allows you to manage users, roles, customers, products, and invoices efficiently — completely offline. All data is securely stored on-device using <a href="https://pub.dev/packages/hive">Hive</a>, ensuring fast access and privacy.</p>

<p>The app supports generating GST-compliant PDF invoices with embedded UPI QR codes for easy payment collection.</p>

<div class="section">
<h2>🚀 Features</h2>

<h3>Authentication</h3>
<ul>
    <li>Login with email/phone and passcode</li>
    <li>Android biometric authentication (fingerprint/Face ID)</li>
    <li>Session management with auto-login</li>
    <li>Forgot password flow with email verification</li>
    <li>User role selection (Photographer, Sales, Manager, etc.)</li>
</ul>

<h3>User & Session Management</h3>
<ul>
    <li>User accounts stored locally using Hive</li>
    <li>Current session stored in Hive for auto-login</li>
    <li>Role-based user management</li>
</ul>

<h3>Billing & Invoices</h3>
<ul>
    <li>Create, edit, and manage GST-compliant invoices</li>
    <li>Apply taxes, discounts, and custom charges</li>
    <li>Generate PDF invoices</li>
    <li>Share invoices via WhatsApp, email, or other apps</li>
    <li>Unique invoice numbers for record-keeping</li>
</ul>

<h3>Products & Customers</h3>
<ul>
    <li>Manage product catalog and pricing</li>
    <li>Add and edit customer details</li>
    <li>Track customer invoices and payments</li>
</ul>

<h3>Offline-first & Hive Storage</h3>
<ul>
    <li>All data stored locally using Hive</li>
    <li>Fast performance with offline operation</li>
    <li>Data persists between app restarts</li>
    <li>Optional encrypted storage for sensitive data</li>
</ul>

<h3>User Experience</h3>
<ul>
    <li>Modern and responsive UI</li>
    <li>Animated login/signup screens</li>
    <li>Works on Android, iOS, and Web</li>
    <li>Smooth transitions using AuthGateScreen</li>
</ul>

<h3>PDF Invoice & UPI QR</h3>
<ul>
    <li>Generates professional PDF invoices for each transaction</li>
    <li>Embedded UPI QR codes for instant payments</li>
    <li>PDFs can be saved locally or shared directly from the app</li>
</ul>
</div>

<div class="section">
<h2>📂 Project Structure</h2>
<pre>
lib/
├── models/          # Hive data models (User, Product, Invoice)
├── screens/         # App screens (Login, Signup, Dashboard, AuthGate, Passcode)
├── widgets/         # Reusable UI components
├── services/        # Business logic (PDF, Invoice generation, UPI QR)
└── main.dart        # App entry point
android/
ios/
web/
assets/              # Images, icons, fonts
</pre>
</div>

<div class="section">
<h2>🐝 Local Storage with Hive</h2>
<p>Hive is used for offline-first, fast local storage.</p>
<ul>
    <li>Stored data includes users, sessions, products, customers, and invoices</li>
    <li>Advantages: Fast key-value storage, offline operation, secure and optionally encrypted, no backend required</li>
</ul>
</div>

<div class="section">
<h2>📷 Screens & UI Flow</h2>
<ul>
    <li><strong>Login & Signup:</strong> Login with email/phone & password, signup with role selection, forgot password flow, passcode lock, biometric authentication.</li>
    <li><strong>Dashboard/AuthGate:</strong> Manages session and redirects to main dashboard, shows user info, products, invoices, quick actions.</li>
    <li><strong>Invoice Management:</strong> Create invoices with products, taxes, discounts, generate PDF with UPI QR, view invoice history.</li>
</ul>
</div>

<div class="section">
<h2>📦 Getting Started</h2>
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
<h2>📌 Roadmap</h2>
<ul>
    <li>Dark mode support</li>
    <li>Multi-user support</li>
    <li>Cloud sync and backup (optional)</li>
    <li>Analytics dashboard for invoices and revenue</li>
    <li>Custom themes and branding options</li>
</ul>
</div>

<div class="section">
<h2>👨‍💻 Author</h2>
<ul>
    <li>Vishnu Chandan</li>
    <li>GitHub: <a href="https://github.com/Vishnu1017">Vishnu1017</a></li>
    <li>Email: (add your email here)</li>
</ul>
</div>

<div class="section">
<h2>📝 License</h2>
<p>MIT License – see LICENSE file for details.</p>
</div>

<div class="section">
<h2>🔗 Useful Links</h2>
<ul>
    <li><a href="https://flutter.dev/">Flutter</a></li>
    <li><a href="https://pub.dev/packages/hive">Hive</a></li>
    <li><a href="https://pub.dev/packages/pdf">PDF package for Flutter</a></li>
</ul>
</div>

</body>
</html>
