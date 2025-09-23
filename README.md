<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>ClickAccount - README</title>
<style>
    body {
        font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
        background-color: #f4f7fa;
        color: #2d2d2d;
        margin: 0;
        padding: 0;
    }
    header {
        background: linear-gradient(90deg, #4b6cb7, #182848);
        color: #fff;
        padding: 40px 20px;
        text-align: center;
    }
    header h1 {
        margin: 0;
        font-size: 2.5rem;
    }
    header p {
        margin: 10px 0 0;
        font-size: 1.2rem;
    }
    main {
        max-width: 1000px;
        margin: 30px auto;
        padding: 0 20px;
    }
    section {
        background-color: #fff;
        padding: 25px;
        margin-bottom: 25px;
        border-radius: 12px;
        box-shadow: 0 5px 15px rgba(0,0,0,0.05);
    }
    h2 {
        color: #4b6cb7;
        border-bottom: 2px solid #4b6cb7;
        padding-bottom: 5px;
    }
    h3 {
        color: #182848;
        margin-top: 15px;
    }
    ul {
        list-style-type: disc;
        margin-left: 20px;
    }
    code {
        background-color: #e0e7ff;
        padding: 2px 6px;
        border-radius: 4px;
    }
    a {
        color: #4b6cb7;
        text-decoration: none;
    }
    a:hover {
        text-decoration: underline;
    }
    .highlight {
        background-color: #fffae6;
        border-left: 4px solid #ffcf44;
        padding: 10px;
        margin: 10px 0;
        border-radius: 5px;
    }
</style>
</head>
<body>

<header>
    <h1>📒 ClickAccount</h1>
    <p>A Flutter-based billing and accounting app with offline-first storage and PDF invoicing</p>
</header>

<main>

<section>
    <h2>About the App</h2>
    <p><strong>ClickAccount</strong> is a Flutter application designed for small businesses, freelancers, and entrepreneurs to manage users, roles, customers, products, and invoices efficiently. All data is stored locally using <a href="https://pub.dev/packages/hive">Hive</a> for fast access and offline operation.</p>
    <p>The app also allows creating GST-compliant PDF invoices and embedding UPI QR codes for seamless payment collection.</p>
</section>

<section>
    <h2>Features</h2>

    <h3>Authentication & Security</h3>
    <ul>
        <li>Login with email/phone and passcode</li>
        <li>Android biometric authentication (Fingerprint/Face ID)</li>
        <li>Session management with auto-login</li>
        <li>Forgot password flow</li>
        <li>Role selection during signup (Photographer, Sales, Manager, etc.)</li>
    </ul>

    <h3>User & Session Management</h3>
    <ul>
        <li>Users stored locally in Hive</li>
        <li>Current session stored for auto-login</li>
        <li>Role-based user management</li>
    </ul>

    <h3>Billing & Invoices</h3>
    <ul>
        <li>Create, edit, and manage GST-compliant invoices</li>
        <li>Apply taxes, discounts, and custom charges</li>
        <li>Generate PDF invoices</li>
        <li>Share invoices via WhatsApp, email, or other apps</li>
        <li>Unique invoice numbers for records</li>
    </ul>

    <h3>Products & Customers</h3>
    <ul>
        <li>Manage product catalog and pricing</li>
        <li>Add and edit customer details</li>
        <li>Track customer invoices and payments</li>
    </ul>

    <h3>Offline-first Storage</h3>
    <ul>
        <li>All app data stored locally using Hive</li>
        <li>Fast performance with offline operations</li>
        <li>Optional encryption for sensitive data</li>
    </ul>

    <h3>PDF Invoice & UPI QR</h3>
    <ul>
        <li>Generate professional PDF invoices</li>
        <li>Embed UPI QR codes for instant payments</li>
        <li>Save or share PDFs directly from the app</li>
    </ul>
</section>

<section>
    <h2>Project Structure</h2>
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
</section>

<section>
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
</section>

<section>
    <h2>Roadmap</h2>
    <ul>
        <li>Dark mode support</li>
        <li>Multi-user support</li>
        <li>Cloud sync and backup (optional)</li>
        <li>Analytics dashboard for invoices and revenue</li>
        <li>Custom themes and branding options</li>
    </ul>
</section>

<section>
    <h2>Author</h2>
    <ul>
        <li>Vishnu Chandan</li>
        <li>GitHub: <a href="https://github.com/Vishnu1017">Vishnu1017</a></li>
        <li>Email: (add your email here)</li>
    </ul>
</section>

<section>
    <h2>License</h2>
    <p>MIT License – see LICENSE file for details.</p>
</section>

<section>
    <h2>Useful Links</h2>
    <ul>
        <li><a href="https://flutter.dev/">Flutter</a></li>
        <li><a href="https://pub.dev/packages/hive">Hive</a></li>
        <li><a href="https://pub.dev/packages/pdf">PDF package for Flutter</a></li>
    </ul>
</section>

</main>

</body>
</html>
