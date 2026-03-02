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

- **Zero-Footprint Idle State:** When collapsed, the notch maintains a `90x15` footprint at `0.001` opacity. It remains fully interactive without obstructing browser tabs or standard menu bar operations.
- **Fluid UI Dynamics:** Utilizes native SwiftUI spring animations (`.spring(response: 0.4, dampingFraction: 0.6)`) for seamless expansion and retraction.
- **Native SF Symbols:** Implements Apple's native vector graphics for crisp, retina-ready media controls.
- **Real-Time Spotify Engine:** Uses the `Combine` framework to run a 1-second polling timer, leveraging an `NSAppleScript` bridge to bypass complex OAuth flows. It fetches live track data, artist information, and high-resolution album artwork directly from the local Spotify client.
- **Global System Overlay:** Runs as a system accessory (`.accessory`), bypassing the standard Dock and floating above all full-screen applications and desktop spaces.

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
