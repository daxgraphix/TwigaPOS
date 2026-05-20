# 🛒 TwigaPOS - Complete POS & Business Management System

**TwigaPOS** is a modern, fully-featured, offline-first Point of Sale and Business Management application built with Flutter. Designed for retail shops, it offers complete manual operations, advanced reporting, shift management, customer relationship tools, and an integrated planner — all with beautiful responsive design that works seamlessly on **Android** and **Windows**.

---

## 📸 Screenshots & Demo

### Placeholder

Add your latest screenshots here.

---

## ✨ Latest Features (2026)

### Core POS & Sales

- **Manual Product Entry**: Add products to cart by searching name — no barcode scanner required
- **Smart Cart System**: Real-time cart updates, quantity control, and automatic stock validation
- **Checkout & Payments**: Complete sales with customer credit support and receipt generation
- **Thermal Printing**: Bluetooth thermal printer integration for instant receipts

### Business Operations

- **Shift Management**: Open/close shifts, track daily performance, cash drops
- **End-of-Day Reporting**: Comprehensive shift reports and reconciliation
- **Operations Dashboard**: Quick actions for common tasks

### Finance & Reporting

- **Finance Hub**: 5 powerful tabs (Transactions, Reports, Accounts, Budgets, Categories)
- **Advanced Reports**: Sales, Products, Finance, and Customer analytics with charts
- **Export & Share**: One-click PDF/CSV export, printing, and native sharing
- **Custom Reports**: Flexible date ranges and report types

### Customer & User Management

- **Complete Customer CRUD**: Add, edit, delete, search, and view transaction history
- **Debt Tracking**: Credit limits, current balance, debt status indicators
- **User Management**: Role-based access (Admin, Manager, Cashier)

### Productivity Tools

- **Integrated Planner & Calendar**: Full calendar view inside the Finance Hub
- **Event Management**: Add, view, and delete events per day
- **Quick Notes**: Persistent notes system with Hive storage
- **Accessible from**: Dashboard, Operations, Customers, and Settings

### Settings & Customization

- **Dark Mode**: Instant theme switching across the entire app
- **Language Support**: English & Swahili with live locale updates
- **Printer Setup**: Scan, connect, and manage Bluetooth thermal printers
- **Backup & Restore**: Full JSON backup with confirmation dialogs and restore
- **Data Export**: Invoice PDF and CSV data export with sharing
- **Cache Management**: One-tap temporary file cleanup

### Cross-Platform & Responsive

- **Android**: Optimized mobile experience with touch-friendly UI
- **Windows**: Native desktop app with larger layouts and keyboard support
- **Responsive Design**: Adaptive grids, fonts, padding, and card layouts
- **Performance**: 10-second initialization timeout, lazy loading, efficient state management

---

## 🏗 Architecture & Tech Stack

**Clean Architecture + Feature-First Design** with strict separation of concerns.

### Core Technologies

|Layer|Technology|Purpose|
|-----|----------|-------|
|**Framework**|Flutter 3.1+|Cross-platform UI|
|**State Management**|`flutter_bloc` + Cubits|Predictable state|
|**Dependency Injection**|`get_it`|Service locator|
|**Routing**|`go_router`|Declarative navigation|
|**Local Database**|`hive` + `hive_flutter`|Fast NoSQL storage|
|**Authentication**|`supabase_flutter`|Secure user auth|
|**Charts**|`fl_chart`|Beautiful analytics|
|**PDF/CSV**|`pdf`, `csv`, `share_plus`|Export & sharing|
|**Icons**|`flutter_launcher_icons`|Platform icons|

### Project Structure

```text
lib/
├── main.dart                          # App entry + initialization + theme/locale notifiers
├── core/
│   ├── data/hive_database.dart        # All 14 Hive boxes + export/import logic
│   ├── error/failure.dart             # fpdart-compatible error handling
│   ├── theme/app_theme.dart           # Light/Dark themes + ValueNotifiers
│   ├── utils/responsive.dart          # Cross-device responsive helpers
│   ├── widgets/                       # Reusable UI components
│   └── service_locator.dart           # get_it registrations
└── features/
    ├── auth/                          # Login, Signup, User management
    ├── billing/                       # POS, Cart, Checkout, Reports, Settings, Operations
    ├── finance/                       # Transactions, Budgets, Accounts, Categories
    ├── product/                       # Inventory CRUD
    ├── customer/                      # Customer management
    ├── planner/                       # Calendar + Events + Notes (integrated in Home)
    ├── shop/                          # Shop details configuration
    ├── settings/                      # Printer, theme, language
    ├── onboarding/
    └── splash/
```

---

## 🚀 How the App Works — Step by Step

### 1. Launch & Initialization (All Platforms)

1. App starts with beautiful gradient splash screen
2. Initializes Hive (14 boxes) and Supabase
3. Loads default categories and accounts if first run
4. **10-second timeout protection** — app never hangs
5. Falls back to offline mode if services are slow/unavailable
6. Proceeds to Onboarding → Auth → Main App

### 2. Authentication

- Secure login/signup via Supabase
- Role-based access (Admin, Manager, Cashier)
- Automatic session handling and PIN lock support

### 3. Main Dashboard

- Welcome message with shop name (from ShopBloc)
- Key performance indicators (Revenue, Profit, Transactions)
- Quick action grid (New Sale, Reports, Products, Customers, Users, Settings, Operations)
- Alerts for low stock and outstanding debt
- Direct access to Planner & Calendar

### 4. Sales Flow (Manual)

1. Navigate to **New Sale**
2. Search products by name (real-time filtering)
3. Select product → set quantity → Add to Cart
4. Review cart summary with live totals
5. Proceed to Checkout
6. Select customer (optional) or cash sale
7. Complete sale → stock deducted automatically
8. Optional: Print thermal receipt

### 5. Finance Hub (6 Tabs)

- **Transactions**: View, add, edit, delete financial transactions
- **Reports**: Interactive charts + export/print/share
- **Accounts**: Manage multiple bank/cash accounts
- **Budgets**: Create and track spending limits with progress bars
- **Categories**: Organize transactions
- **Planner & Notes**: Full calendar + events + quick notes

### 6. Operations

- Start/End Shift toggle with persistence
- Cash Drop recording
- End-of-Day reporting
- Quick links to Reports, Users, Planner, Customers

### 7. Reports & Analytics

- Filter by custom date ranges
- Export to PDF or CSV
- Print directly
- Share via native share dialog
- Generate custom reports on demand

### 8. Settings (All Working)

- Toggle Dark Mode → instant app-wide theme change
- Switch Language → live locale update (English/Swahili)
- Printer Setup → scan, connect, disconnect, test print
- Backup Data → full JSON export + share
- Restore Data → find backup, confirm, import
- Export Invoices → PDF generation
- Share Data → CSV export
- Clear Cache, About, Terms, Privacy, Help

---

## 📱 Platform Support

|Platform|Status|Optimizations|
|--------|------|-------------|
|**Android**|✅ Full|Touch-friendly, compact layouts, mobile navigation|
|**Windows**|✅ Full|Larger fonts, desktop grids, keyboard support, native window controls|
|**Responsive**|✅|Adaptive cards, grids (2/3/4 columns), padding, elevation|

---

## 🛠 Getting Started

### Prerequisites

- Flutter SDK `>= 3.1.0`
- Android Studio / Visual Studio Code
- For Windows: Visual Studio 2022 with Desktop development workload

### Installation Steps

1. **Clone the repository**

   ```bash
   git clone <repository_url>
   cd twigapos
   ```

2. **Install dependencies**

   ```bash
   flutter pub get
   ```

3. **Generate code** (Hive adapters, JSON serialization, icons)

   ```bash
   dart run build_runner build --delete-conflicting-outputs
   flutter pub run flutter_launcher_icons
   ```

4. **Run the app**

   ```bash
   # Android
   flutter run

   # Windows
   flutter run -d windows
   ```

5. **Build for production**

   ```bash
   # Android APK
   flutter build apk --release

   # Windows executable
    flutter build windows --release
    ```

---

## 🔐 Configuration

### Supabase (Authentication)

Update `lib/core/supabase/supabase_config.dart` with your credentials:

```dart
static const String supabaseUrl = 'YOUR_SUPABASE_URL';
static const String supabaseAnonKey = 'YOUR_ANON_KEY';
```

### Default Data

On first launch, the app automatically creates:

- 7 default transaction categories
- 1 default account ("Main Account")

---

## 📊 Data & Backup

- **Local Storage**: All data stored in Hive (14 boxes)
- **Backup**: Full JSON export via Settings → Backup Data
- **Restore**: Automatic detection of latest backup file
- **Export Formats**: PDF (invoices), CSV (raw data)

---

## 🐛 Troubleshooting

|Issue|Solution|
|-----|--------|
|App stuck on loading (Windows)|Fixed — 10-second timeout now active|
|Icons not updating|Run `flutter pub run flutter_launcher_icons`|
|Windows build fails|Run `flutter create --platforms=windows .`|
|Dark mode not applying|Toggle in Settings — uses `themeModeNotifier`|
|Language not changing|Select in Settings — updates `localeNotifier`|

---

## 📈 Current Status (May 2026)

- ✅ **Zero Errors / Zero Warnings** — `flutter analyze` clean
- ✅ **Fully Functional** — All screens, dialogs, and features working
- ✅ **Responsive** — Excellent experience on Android & Windows
- ✅ **Offline-First** — Complete functionality without internet
- ✅ **Production Ready** — Stable, performant, and well-architected

---

## 🤝 Contributing

Contributions are welcome! Please follow the existing Clean Architecture patterns and ensure all changes pass `flutter analyze`.

---

## 📄 License

This project is proprietary. All rights reserved.

---

**TwigaPOS** — Modern Retail Made Simple 🚀
