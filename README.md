# MacNotch: Dynamic Island for macOS

![macOS Requirement](https://img.shields.io/badge/macOS-12.0%2B-blue?logo=apple)
![SwiftUI](https://img.shields.io/badge/SwiftUI-Framework-orange)
![License](https://img.shields.io/badge/License-MIT-green)

A native, floating "Dynamic Island" designed specifically for macOS. Built entirely from scratch using SwiftUI and AppKit, MacNotch hovers transparently over your display and expands into a rich control center with live Spotify integration on mouse hover.

<img width="2880" height="1800" alt="image" src="https://github.com/user-attachments/assets/f92b5c2b-189e-4c74-bbfe-7380f39da684" />


## 📋 Table of Contents
- [Features](#-features)
- [Prerequisites](#-prerequisites)
- [Installation & Export](#-installation--export)
- [Auto-Start at Login](#-auto-start-at-login)
- [Architecture](#-architecture)
- [Contributing](#-contributing)
- [License](#-license)

## ✨ Features

* **Smart Drop Engine:** Effortlessly stash files, web links, and raw images. The app intelligently handles raw image data from Chrome and Safari, automatically converting them into temporary files for seamless stashing.
* **Intelligent Drag-Out:** Dragging stashed items back out adapts to your needs. Files drag as actual files, while web links drag out as raw text (perfect for dropping directly into WhatsApp, Slack, or iMessage text fields).
* **Frictionless Vault UI:** A beautiful, responsive grid system to hold your stashed items. Features iOS-style individual delete badges and a full-row click toggle for a satisfying user experience.
* **Quick-Launch Integration:** Click any stashed icon to instantly open it in your default browser or native macOS application without removing it from the vault.
* **Non-Intrusive Hitboxes:** The Notch dynamically scales its physics. It only blocks mouse clicks exactly where the visible UI is, ensuring your browser tabs and macOS menu bar remain completely accessible when the notch is idle.
* **Live Spotify Controls:** Integrated premium media controls to play, pause, and skip tracks with live album artwork and track metadata.

## ⚙️ Prerequisites

- **OS:** macOS 12.0 or later.
- **IDE:** Xcode 13.0+ (for building from source).
- **Dependencies:** The official Spotify Desktop application.

## 🚀 Installation & Export

Due to macOS App Sandboxing restrictions regarding cross-application AppleEvents, you must build this project from source with specific entitlements.

1. **Clone the repository:**
   ```bash
   git clone [https://github.com/pashyatidar/MacNotch.git](https://github.com/pashyatidar/MacNotch.git)
   cd MacNotch
   ```

2. **Configure Xcode Settings:**
   - Open the project in Xcode.
   - Navigate to your Target settings -> **Signing & Capabilities**.
   - **Remove** the `App Sandbox` capability entirely (click the `X` icon).
   
3. **Set Privacy Entitlements:**
   - Navigate to the **Info** tab.
   - Add the key: `Privacy - AppleEvents Sending Usage Description`.
   - Set the string value to: `Required to control Spotify playback and fetch live media data.`

4. **Export the App:**
   - Press `Cmd + R` to compile and test.
   - To run the app independently of Xcode, go to the top menu bar and select **Product > Show Build Folder in Finder**.
   - Navigate to `Products > Debug` and drag `MacNotch.app` directly into your Mac's **Applications** folder.

## ⚙️ Auto-Start at Login

To make MacNotch feel like a native, permanent piece of Mac hardware, you should set it to launch automatically when you turn on your computer:

1. Open macOS **System Settings**.
2. Navigate to **General > Login Items**.
3. Under "Open at Login", click the **+** button.
4. Select `MacNotch.app` from your Applications folder. 

*(Note: On the first independent launch, macOS will prompt you to grant the application permission to control Spotify. You must accept this prompt for the media controls to function).*

## 🏗 Architecture

MacNotch bypasses standard API rate limits and authentication by tunneling directly into the local application state using a live timer engine and the following AppleScript pipeline:

```applescript
if application "Spotify" is running then
    tell application "Spotify"
        if player state is playing or player state is paused then
            set tName to name of current track
            set tArtist to artist of current track
            set aUrl to artwork url of current track
            return tName & "|||" & tArtist & "|||" & aUrl
        end if
    end tell
end if
return "Not Playing|||---|||"
```

## 🤝 Contributing

Contributions, issues, and feature requests are welcome. Feel free to check the issues page if you want to contribute.

## 📄 License

This project is licensed under the MIT License.
