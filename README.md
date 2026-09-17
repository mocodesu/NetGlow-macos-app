
<div align="center">

<img src="docs/icon.png" width="140" alt="NetGlow icon">

# 🟢 NetGlow 🔴

**A macOS network status indicator that flashes the screen edges red when you lose connection — and green when you're back.**

[![Platform](https://img.shields.io/badge/platform-macOS%2013%2B-black?style=flat-square&logo=apple)](https://www.apple.com/macos/)
[![Swift](https://img.shields.io/badge/Swift-5.10-orange?style=flat-square&logo=swift)](https://swift.org)
[![SwiftUI](https://img.shields.io/badge/SwiftUI-blue?style=flat-square&logo=swift)](https://developer.apple.com/xcode/swiftui/)
[![Network](https://img.shields.io/badge/Network.framework-4ADE80?style=flat-square&logo=apple)](https://developer.apple.com/documentation/network)
[![License](https://img.shields.io/badge/license-MIT-green?style=flat-square)](LICENSE)

You're deep in a video call. Wi-Fi drops. NetGlow paints a **red border** around your screen.
You notice instantly. You fix it. The moment you're back, the border flashes **green** and fades away.

*Not a ping monitor. Not a log viewer. A signal you can't miss.*

</div>

---

## ✨ Features

<table>
<tr>
<td width="50%" valign="top">

### 🌐 Real-time detection
- **Event-driven** — uses `NWPathMonitor`, no polling, no CPU churn
- **Instant reaction** — path updates land within milliseconds
- **Multi-monitor aware** — all screens tint together
- **Grace period** — configurable debounce for Wi-Fi handoffs so you don't get false positives
- **Captive portal detection** — flashes **orange** when the network is up but you're stuck behind a login page

</td>
<td width="50%" valign="top">

### 🎨 Visual feedback
- **Click-through overlay** — a borderless `NSWindow` at the highest level, so you can keep working while the tint is on screen
- **Red stays until fixed** — the offline border persists
- **Green fades after 2s** — the "back online" flash is a punctuation, not a distraction
- **Customizable** — color, border thickness, fade duration, and pulse all adjustable
- **Multi-display support** — every attached screen gets its own border

</td>
</tr>
<tr>
<td width="50%" valign="top">

### 🔔 Multiple alert channels
- **Native notifications** — banner in Notification Center
- **Sound alerts** — Glass on connect, Funk ×2 on disconnect
- **Menu bar presence** — wifi icon with a color that reflects current state
- **Status menu** — shows current state and quick access to Preferences
- **All toggles in Preferences** — turn off what you don't want

</td>
<td width="50%" valign="top">

### 📊 History & stats
- **Every state change logged** with a timestamp
- **Uptime percentage** for today
- **Outage count** for today
- **Full event log** — the last 100 events, scrollable
- **Clear history** button when you want a clean slate

</td>
</tr>
</table>

---

## 🎨 How It Looks

<p align="center">
  <em>A calm macOS utility that speaks only when something's wrong.</em>
</p>

| State | Border | Menu Bar | Sound | Notification |
|:--:|:---|:---|:---|:---|
| 🟢 **Connected** | Green, flashes 2s | Green wifi icon | Glass | "Internet Restored" |
| 🔴 **Disconnected** | Red, persists | Red wifi-slash icon | Funk ×2 | "Internet Lost" |
| 🟠 **Captive Portal** | Orange, persists | Orange wifi-exclamation icon | Ping | "Captive Portal Detected" |

The red border stays on screen until the connection returns. You'll see it whether you're in Safari, Terminal, or a fullscreen video — it floats above everything, ignores clicks, and doesn't interrupt.

---

## 📋 Requirements

| | |
|:--|:--|
| ![macOS](https://img.shields.io/badge/-macOS%2013%2B-black?style=flat-square&logo=apple) | Ventura or later |
| ![Xcode](https://img.shields.io/badge/-Xcode%2015%2B-147EFB?style=flat-square&logo=xcode) | To build from source |
| ![Network](https://img.shields.io/badge/-No%20special%20permissions-4ADE80?style=flat-square) | Unlike most utilities, NetGlow needs nothing |

Unlike DailyForge, NetGlow needs no microphone, no accessibility, and no speech recognition. It monitors the network path and draws a window. That's it.

---

## 🚀 Installation

### 📦 Build from source

**1.** Clone the repository
```bash
git clone https://github.com/yourusername/NetGlow.git
cd NetGlow
