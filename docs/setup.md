# AGV Nexus - Setup & Execution Guide (Phase 1)

## 1. Prerequisites

* **Flutter SDK**: 3.35.7+ (compatible with Dart 3.9.2)
* **Dart SDK**: 3.9.2+
* **Supported Host Platforms**: Windows 10/11 x64, macOS, Linux, Chrome (Web), Edge (Web)
* **IDE**: VS Code or Android Studio with Flutter and Dart extensions

---

## 2. Workspace Layout

The AGV Nexus project structure is organized as follows:
```
Agv Nexus/
├── agvnexus/                # Flutter frontend application (Phase 1)
│   ├── lib/
│   │   ├── app/             # Application entry point, router, and theme
│   │   ├── core/            # Tokens, configuration, state views, and shell
│   │   └── features/        # Feature modules: auth, overview, robots, maps, missions, digital_twin, telemetry, settings
│   ├── test/                # Unit and widget test suite
│   └── pubspec.yaml         # Dependencies and metadata
├── docs/                    # Architecture, setup, and specification documentation
│   ├── architecture.md
│   └── setup.md
```

---

## 3. Installation & Dependency Resolution

Navigate to the Flutter project directory and resolve dependencies:

```bash
cd agvnexus
flutter pub get
```

---

## 4. Running the Application

### Running on Chrome (Web)
```bash
flutter run -d chrome
```

### Running on Windows Desktop
```bash
flutter run -d windows
```

### Running with Device Preview
Device Preview is configured to inspect responsive layouts across simulated mobile, tablet, and desktop viewports. To toggle Device Preview during development, review `lib/main.dart`.

---

## 5. Verification & Testing

### Running Static Analysis
Ensure zero lint or type errors:
```bash
flutter analyze
```

### Running Automated Test Suite
Execute all unit and widget tests:
```bash
flutter test
```

### Code Formatting
Ensure strict adherence to Dart styling conventions:
```bash
dart format .
```

---

## 6. Phase 2 Supabase Database & Auth Connectivity

AGV Nexus is connected to live Supabase PostgreSQL and Authentication:

* **Supabase URL**: `https://bphxvupyupfbzmdrcnqs.supabase.co`
* **Configuration Files**:
  * `agvnexus/.env` / `.env`
  * `agvnexus/env.json` (for `--dart-define-from-file=env.json`)
  * `agvnexus/lib/core/config/app_config.dart` (pre-configured with project defaults)

### Running with Connected Supabase
```bash
cd agvnexus
flutter run -d chrome
```
Or explicitly passing the configuration:
```bash
flutter run -d chrome --dart-define-from-file=env.json
```

### Running in Offline / Simulated Fallback Mode
To bypass Supabase and run in isolated mock mode:
```bash
flutter run -d chrome --dart-define=SUPABASE_URL="" --dart-define=SUPABASE_ANON_KEY="" --dart-define=SIMULATED_MODE=true
```
