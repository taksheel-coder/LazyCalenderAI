# 🗓️ LazyCalenderAI

> An intelligent, lightning-fast macOS menu bar assistant that seamlessly manages your Apple Calendar with natural language.

---

## 💡 Why I Made This

Managing a calendar manually can be tedious. Opening the app, picking dates, setting times, and dragging blocks around often introduces friction into a busy day. 

I built **LazyCalenderAI** because I wanted a frictionless way to control my schedule directly from the macOS menu bar without keeping an IDE or heavy window open. With a quick shortcut, you can type what you want to do in plain English—whether rescheduling a session or booking a quick slot—and let an LLM handle the coordination natively.

---

## ✨ Features

- **⚡ Menu Bar Native:** Lives quietly in your macOS menu bar (`LSUIElement`) with a clean frosted-glass UI.
- **🗣️ Natural Language Control:** Add, shift, fetch, or delete calendar events just by speaking or typing naturally.
- **📅 Direct Apple Calendar Integration:** Connects directly to Apple Calendar via native macOS system APIs (`EventKit` / AppleScript).
- **🤖 Multi-LLM Function Calling:** Powered by fast structured tool calling via Google Gemini API (or any OpenAI-compatible provider).
- **🔒 Privacy First:** Runs locally on your machine with direct API endpoints. Your personal calendar data is never stored on external third-party database servers.

---

## 🚀 Quick Install (One-Liner)

You can install LazyCalenderAI automatically by running this one-line command in your Terminal:

```bash
curl -fsSL https://raw.githubusercontent.com/<YOUR_GITHUB_USERNAME>/LazyCalenderAI/main/install.sh | bash
```

*(Replace `<YOUR_GITHUB_USERNAME>` with your actual GitHub username).*

---

## 🛠️ Manual Installation & Build

If you prefer building from source:

### Prerequisites
- macOS 13.0+
- Xcode Command Line Tools (or Node/Electron depending on build flavor)

### Steps
1. **Clone the repository:**
   ```bash
   git clone https://github.com/<YOUR_GITHUB_USERNAME>/LazyCalenderAI.git
   cd LazyCalenderAI
   ```

2. **Build the App:**
   ```bash
   # If building Swift version:
   swift build -c release
   # Or if building packaged release:
   xcodebuild -scheme LazyCalenderAI -configuration Release
   ```

3. **Move to Applications:**
   Drag the generated `LazyCalenderAI.app` into your `/Applications` folder.

---

## 🔑 Setup & Configuration

1. Launch **LazyCalenderAI** from Spotlight or Applications.
2. Click the menu bar icon and open **Settings** (⚙️).
3. Enter your **Google Gemini API Key** (available for free at [Google AI Studio](https://aistudio.google.com)).
4. Grant Calendar permissions when macOS prompts you on your first request.

---

## 💬 Example Commands

- *"Schedule math revision tomorrow from 4 PM to 5 PM"*
- *"What do I have planned for this Friday afternoon?"*
- *"Move my 3 PM meeting tomorrow to Thursday at 10 AM"*
- *"Cancel and remove the study session on Monday"*

---

## 📄 License

MIT License © 2026
