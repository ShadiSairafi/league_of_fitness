# ⚡ League of Fitness

A premium, cyberpunk-themed fitness tracker and AI coaching application built with Flutter.

---

## 🚀 Key Systems & Features

### 🤖 1. The AI Nutrition & Chef Engine ("Chief Tank")
*   **Multimodal Specimen Scanning**: Scan up to **4 ingredient photos** simultaneously inside a glowing grid analyzer to identify raw foods and design recipes.
*   **Interactive Specimen Zoom**: Pinch-to-zoom and pan across ingredient photos to inspect what the AI coach is analyzing.
*   **Dietary Preference Bios**: Configure likes, dislikes, and allergies directly in your user profile. The AI automatically parses these rules to filter out unwanted ingredients.
*   **Iterative Recipe Refinements**: Refine and scale recipes dynamically using natural feedback loops before logging or saving them.

### ⚡ 2. Supercharge Dashboard Engine
*   **Instant Logging Drawer**: Tap the dashboard's neon pink lightning bolt to trigger one-tap quick logs for daily high-frequency metrics:
    *   💧 **Hydrate**: Fast hydration tracking (+500ml Water).
    *   🥛 **Whey Shake**: Post-workout protein infusion (+120 kcal | +25g Protein).
    *   ☕ **Pre-Workout Stim**: Log energy focus drinks (+100 kcal).
    *   🍎 **Fruit Snack**: Hydrating whole foods energy boost (+80 kcal | +200ml H2O).
    *   🍫 **Cheat Snack**: High-density treats (+350 kcal).
    *   🧠 **AI Motivation Pep Talk**: Dynamic quote loader fetching raw motivators from the coach engine.

### 🏋️‍♂️ 3. Training Protocol Engine
*   **Smart Backups**: Select manual swaps for workouts, backed by at least 5 customized alternatives with individual illustrations.
*   **Streak & Progress Badges**: Earn rank progression indicators (Iron Initiate, Bronze Beast, Golden Unit, Titanium Tank, and Zenith Eternal).
*   **Reshuffle Mechanic**: Missed a workout? Shuffles remaining exercises dynamically into available training slots while keeping rest days locked.

### 🔋 4. Foreground LifeCycle Sync
*   Monitors app resume events using `WidgetsBindingObserver` to instantly sync calendar timelines, daily intake targets, active streaks, and metrics whenever the app wakes up from the background.

---

## 🛠️ Getting Started

### 📋 Prerequisites
*   [Flutter SDK](https://docs.flutter.dev/get-started/install) (channel stable)
*   Android Studio / Xcode (for emulation/deployment)

### 🗝️ Configuration Setup

For security, API keys are hidden from version control. Follow these steps to configure your environment:

1. Copy the example config file:
   ```bash
   cp lib/config.dart.example lib/config.dart
   ```
2. Open `lib/config.dart` and insert your Gemini API gateway key:
   ```dart
   const String geminiApiKey = "YOUR_API_KEY_HERE";
   ```

### 🏃 Running the Application

1. Connect your device (emulated or physical)
2. Run clean to sync caches:
   ```bash
   flutter clean
   ```
3. Run the compiler:
   ```bash
   flutter run
   ```
