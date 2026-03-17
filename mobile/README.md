# Anchor Mobile App

This is the Flutter mobile application for Anchor, a self-hosted note-taking platform.

## Features

-   **Offline-First**: Create and edit notes without an internet connection.
-   **Attachments**: Attach images and audio recordings to notes.
-   **Rich Text Editor**: Format your thoughts with bold, italic, lists, and more using Flutter Quill.
-   **Sync**: Automatic bidirectional sync with the self-hosted server when online.
-   **Secure**: JWT authentication and secure local storage.
-   **Theming**: Beautiful light and dark mode support.
-   **Search**: Instant local search.

## Tech Stack

-   **Flutter**: UI Framework
-   **Riverpod**: State Management
-   **Drift**: Local SQLite Database
-   **GoRouter**: Navigation
-   **Dio**: HTTP Client
-   **Flutter Quill**: Rich Text Editor

## Getting Started

### Prerequisites

-   [Flutter SDK](https://flutter.dev/docs/get-started/install) installed and configured.
-   An Android or iOS device/emulator.
-   A running instance of the Anchor Server (see root README).

### Installation

1.  Navigate to the mobile directory:
    ```bash
    cd mobile
    ```

2.  Install dependencies:
    ```bash
    flutter pub get
    ```

3.  Run code generation (for Riverpod, Drift, JSON serialization):
    ```bash
    dart run build_runner build --delete-conflicting-outputs
    ```

4.  Run the app:
    ```bash
    flutter run
    ```

### Connecting to Server

On the first launch, the app will ask for your **Server URL**.
-   If running locally on Android Emulator, use `http://10.0.2.2:3000`
-   If running locally on iOS Simulator, use `http://localhost:3000`
-   If self-hosted, use your deployed URL (e.g., `https://anchor.yourdomain.com`)

## Building for Production

### Android APK
```bash
flutter build apk --release
```

### iOS
```bash
flutter build ios --release
```
