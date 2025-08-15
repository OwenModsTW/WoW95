# WoW95 - Windows 95 UI Overhaul for World of Warcraft

![WoW Version](https://img.shields.io/badge/WoW-11.0.2-blue)
![License](https://img.shields.io/badge/license-MIT-green)
![Platform](https://img.shields.io/badge/platform-Windows%20%7C%20Mac-lightgrey)
![Addon](https://img.shields.io/badge/addon-UI%20Overhaul-purple)

A complete UI overhaul for World of Warcraft that brings the nostalgic Windows 95 aesthetic to Azeroth. Experience your favorite MMORPG with authentic retro computing vibes!

## 🖼️ Features

### Core UI Elements
- **🖥️ Taskbar** - Fully functional Windows 95-style taskbar with Start button, window management, and system tray
- **📂 Start Menu** - Classic Start menu with organized access to all game functions
- **🪟 Window System** - All UI panels converted to draggable Windows 95 windows with title bars
- **🎨 Authentic Styling** - Pixel-perfect recreation of Windows 95 visual elements

### Modules Included
- **Action Bars** - Retro-styled action bars with classic button appearance
- **Bags** - Inventory management with Windows 95 window styling
- **Chat** - Chat windows with classic borders and styling
- **Minimap** - Square minimap with Windows 95 frame
- **Quest Tracker** - Redesigned quest tracker with expandable/collapsible sections
- **Spellbook** - Classic spellbook interface with tab navigation
- **Tooltips** - Windows 95-styled tooltips
- **Character Panel** - Complete character information window

### Bonus Features
- **🎮 Built-in Games** - Includes classic Minesweeper for those flight path waits!
- **🗺️ Map Overhaul** - World map with Windows 95 styling and navigation
- **⚙️ Micro Menu** - Redesigned system menu with classic styling

## 📦 Installation

1. Download the latest release from the [Releases](https://github.com/OwenModsTW/WoW95/releases) page
2. Extract the `WoW95` folder to your WoW AddOns directory:
   - **Windows**: `C:\Program Files\World of Warcraft\_retail_\Interface\AddOns\`
   - **Mac**: `/Applications/World of Warcraft/_retail_/Interface/AddOns/`
3. Launch World of Warcraft
4. The addon should be enabled by default in your AddOns list

## 🎮 Usage

Once installed, WoW95 automatically replaces your default UI. Key features:

- **Start Menu**: Click the Start button in the bottom-left corner
- **Window Management**: All windows can be dragged by their title bars
- **Taskbar**: Shows all open windows, click to focus/minimize
- **Games**: Access Minesweeper from Start Menu → Games

### Slash Commands
- `/wow95` - Main addon commands
- `/wow95test` - Test window system
- `/wow95map` - Map debugging

## ⚙️ Configuration

WoW95 saves your settings in the `WoW95DB` saved variable. Window positions and settings persist between sessions.

## 🛠️ Development

### File Structure
```
WoW95/
├── WoW95.lua           # Core addon framework
├── WoW95.toc           # Table of contents
├── Modules/
│   ├── ActionBars.lua  # Action bar styling
│   ├── Bags.lua        # Inventory windows
│   ├── Chat.lua        # Chat frame styling
│   ├── Games.lua       # Built-in games
│   ├── Minimap.lua     # Minimap frame
│   ├── QuestTracker.lua # Quest tracking
│   ├── Spellbook.lua   # Spellbook interface
│   ├── StartMenu.lua   # Start menu system
│   ├── Taskbar.lua     # Taskbar implementation
│   ├── Tooltip.lua     # Tooltip styling
│   └── Windows.lua     # Window management
└── Media/
    ├── xclose.tga      # Close button texture
    ├── minimise.tga    # Minimize button texture
    ├── maximize.tga    # Maximize button texture
    └── startbutton.tga # Start button texture
```

### Contributing
Contributions are welcome! Please feel free to submit pull requests or open issues for bugs and feature requests.

## 📝 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- Inspired by Microsoft Windows 95
- Built for the World of Warcraft community
- Special thanks to all contributors and testers

## 📞 Support

- **Issues**: [GitHub Issues](https://github.com/OwenModsTW/WoW95/issues)
- **Discussions**: [GitHub Discussions](https://github.com/OwenModsTW/WoW95/discussions)

---

*Bringing 1995 to Azeroth, one window at a time!* 🪟✨