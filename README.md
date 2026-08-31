<div align="center">

# 🗓️ LazyCalenderAI

**An ultra-fast, native macOS menu bar AI assistant that manages your Apple Calendar using Google Gemini.**

<br />

[![Download for macOS](https://img.shields.io/badge/⬇️_Download_CalendarAI-macOS_14+-007AFF?style=for-the-badge&logo=apple&logoColor=white)](https://github.com/taksheel-coder/LazyCalenderAI/releases/latest/download/CalendarAI.zip)
[![Release Version](https://img.shields.io/github/v/release/taksheel-coder/LazyCalenderAI?style=for-the-badge&color=purple)](https://github.com/taksheel-coder/LazyCalenderAI/releases/latest)
[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg?style=for-the-badge)](LICENSE)

</div>

---

## ⚡ 1-Click Installation

### Option 1: One-Line Terminal Command (Recommended)
Run this single command in your Terminal:

```bash
curl -fsSL https://raw.githubusercontent.com/taksheel-coder/LazyCalenderAI/main/install.sh | bash
```

*This automatically downloads the latest release, installs `CalendarAI.app` to your `/Applications` folder, and launches it in your menu bar.*

<br />

### Option 2: Direct Download
1. Click [**Download CalendarAI.zip**](https://github.com/taksheel-coder/LazyCalenderAI/releases/latest/download/CalendarAI.zip).
2. Unzip the file and drag **`CalendarAI.app`** into your **`Applications`** folder.
3. Open it from Launchpad or Finder.

---

## ✨ Features

- **🚀 Native macOS Menu Bar App:** Lives strictly in your menu bar (`LSUIElement`). Zero dock clutter.
- **✨ Powered by Google Gemini:** Connects to Google AI Studio with token-optimized Flash models (`gemini-2.0-flash`, `gemini-2.0-flash-lite`, `gemini-2.5-flash`).
- **📅 Apple Calendar Integration:** Reads, creates, updates, and deletes events directly via Apple's native `EventKit`.
- **🎨 Frosted Glass UI:** Polished macOS translucent design with interactive event cards, relative date badges, duration chips, and 1-click open in Apple Calendar.
- **⚙️ Preferences Overlay:** Seamless in-window settings with API key testing, model selection, and permission status.

---

## 🚀 Getting Started

1. **Launch the App:** Click the **CalendarAI** icon in your macOS menu bar.
2. **Add Your Gemini API Key:**
   - Click the **Gear (Preferences)** icon.
   - Get a free key at [Google AI Studio](https://aistudio.google.com/app/apikey) and paste it into the API Key field.
   - Click **Test Connection** to verify.
3. **Grant Calendar Access:** When prompted, grant Calendar permission so CalendarAI can interact with your schedule.
4. **Try Natural Language Commands:**
   - *"What's on my schedule today?"*
   - *"Schedule Team Sync tomorrow at 10 AM for 45 minutes"*
   - *"Find all meetings with John this week"*
   - *"Move my 2 PM meeting tomorrow to 4 PM"*

---

## 🛠️ Build From Source

```bash
# Clone the repository
git clone https://github.com/taksheel-coder/LazyCalenderAI.git
cd LazyCalenderAI

# Build and package the .app bundle
./build.sh

# Open the app
open CalendarAI.app
```

---

## 📄 License

MIT License © 2026 [taksheel-coder](https://github.com/taksheel-coder)
