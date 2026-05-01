# 💰 Furanku Gold Sync

[![Download on CurseForge](https://img.shields.io/badge/CurseForge-Download-orange)](https://www.curseforge.com/wow/addons/furanku-gold-sync)

Automatically keeps your character gold at a defined amount by syncing with the Warband Bank.

---

## ✨ Features

- 🔄 Automatic gold synchronization when opening the Warband Bank
- 🧠 Smart balancing:
  - Deposits excess gold
  - Withdraws missing gold
- 🧩 Category system:
  - Assign characters to categories
  - Each category has its own target gold
  - Global fallback if no category is assigned
- ⚙️ In-game configuration via Options Panel
- 🗂 Unlimited custom categories
- 🔒 Built-in categories (Main, Twink, Inactive) are protected

---

## ⚙️ How it works

When the Warband Bank is opened:

- If you have **more gold than your target**, excess gold is deposited.
- If you have **less gold than your target**, missing gold is withdrawn.
- If you are exactly at your target, nothing happens.

---

## 🧠 Category System

Each character can either:

- Use **Global Settings**
- Or be assigned to a **Category**

Categories define:

- Target Gold
- Auto Sync behavior

### Default Categories

| Category | Target Gold | Auto Sync |
|---|---:|---|
| Main | 50000g | Enabled |
| Twink | 30000g | Enabled |
| Inactive | 10000g | Disabled |

---

## 🖥 Configuration

Open the options panel via:

```text
/fgs
```

From there you can:

- Select a category per character
- Adjust target gold
- Enable or disable auto sync
- Create and delete categories

---

## 💬 Chat Commands

```text
/fgs
/fgs status
/fgs set <gold>
/fgs auto on|off

/fgs category list
/fgs category set <key>
/fgs category set global
/fgs category create <key> <gold>
/fgs category target <key> <gold>
/fgs category delete <key>
```

---

## 📦 Installation

1. Download the latest release.
2. Extract the folder into:

```text
World of Warcraft/_retail_/Interface/AddOns/
```

3. Restart the game or reload the UI:

```text
/reload
```

---

## 🔧 Development

### Structure

```text
FurankuGoldSync/
├── Core.lua
├── Options.lua
├── FurankuGoldSync.toc
└── media/
```

### Notes

- Uses SavedVariables: `FGS_DB`
- Categories are account-wide
- Character assignments are per-character

---

## 🔮 Roadmap

- 🌍 Multi-language support (EN/DE)
- 👤 Per-character overrides for target gold and auto sync
- 🧩 Advanced options panel
- 🎯 More fine-grained sync control

---

## 📜 License

All Rights Reserved