# WoW95 - Windows 95 UI Overhaul for World of Warcraft

![WoW Version](https://img.shields.io/badge/WoW-11.0.2-blue)
![License](https://img.shields.io/badge/license-CC%20BY--NC--SA%204.0-red)
![Platform](https://img.shields.io/badge/platform-Windows%20%7C%20Mac-lightgrey)
![Addon](https://img.shields.io/badge/addon-UI%20Overhaul-purple)

A complete UI overhaul for World of Warcraft that brings the nostalgic Windows 95 aesthetic to Azeroth. Experience your favorite MMORPG with authentic retro computing vibes, complete with custom windows, quest tracking, guild management, and classic Windows 95 styling throughout.

## Features

### Core Framework
- **Windows 95 Color Scheme** - Authentic gray backgrounds with blue title bars
- **Custom Window Creation** - Standardized window system with draggable title bars
- **Button Textures** - Custom close, minimize, and maximize button graphics
- **Module Registration** - Organized, modular architecture for easy development

### Implemented Modules

#### Quest Tracker
- **Custom Windows 95 Styling** - Replaces default Blizzard objective tracker
- **Three-Section Layout** - All Objectives, Campaign, and Quests sections
- **Clickable Quest Icons** - Yellow (active), gray (tracked), dark (untracked)
- **Dynamic Sizing** - Campaign section auto-sizes based on content
- **Minimize/Maximize Controls** - Independent section controls with custom textures

#### Minimap
- **Square Windows 95 Frame** - Authentic retro styling with proper borders
- **Addon Button Collection** - Popup system to organize minimap buttons
- **Lock/Unlock Toggle** - Prevents accidental movement when locked
- **Proper Icon Positioning** - All system buttons correctly spaced (20px)

#### Guild & Communities Window
- **Comprehensive Guild Management** - Full roster with advanced features
- **Class-Colored Backgrounds** - Member rows colored by class (30% alpha online, 15% offline)
- **Death Knight Support** - Manual color fallback for proper DK representation
- **Tabbed Interface** - Roster, Guild Info, News, Perks, Communities
- **Officer Controls** - Invite, promote, demote, remove (permission-based)
- **Member Details Panel** - Selection-based detailed member information
- **Show/Hide Offline** - Filter controls for member visibility

#### Windows Core
- **Frame Lifecycle Management** - Proper window creation and cleanup
- **Blizzard UI Integration** - Hooks into existing game windows
- **Toggle Behavior** - Hotkeys work to open and close windows
- **Program Window Tracking** - Maintains state of all open windows

### Current Status
- **Quest Tracker**: Complete with enhanced features
- **Minimap**: Complete (minimize removed to prevent outline issues)
- **Guild Window**: Complete with advanced guild management
- **Windows Core**: Complete with frame hooking system
- **Other Modules**: Various stages of development

## Installation

1. Download the latest release from the [Releases](https://github.com/OwenModsTW/WoW95/releases) page
2. Extract the `WoW95` folder to your WoW AddOns directory:
   - **Windows**: `C:\Program Files\World of Warcraft\_retail_\Interface\AddOns\`
   - **Mac**: `/Applications/World of Warcraft/_retail_/Interface/AddOns/`
3. Launch World of Warcraft
4. The addon should be enabled by default in your AddOns list

## Usage

Once installed, WoW95 enhances your UI with Windows 95 styling:

- **Quest Tracker**: Automatically replaces the default objective tracker
- **Guild Window**: Opens when accessing guild features with enhanced management
- **Minimap**: Square frame with Windows 95 styling and button organization
- **Window Management**: All custom windows can be dragged by their title bars

### Slash Commands
- `/wow95test` - Test core addon functionality and modules
- `/wow95guildtest` - Debug guild window and class colors
- `/wow95windebug` - Check window system status

## Configuration

WoW95 saves your settings in the `WoW95DB` saved variable. Window positions and settings persist between sessions.

### Guild Window Settings
- **Show Offline Members**: Toggle to display offline guild members
- **Class Colors**: Automatically applied to member row backgrounds
- **Officer Controls**: Available based on your guild permissions

## Development

### File Structure
```
WoW95/
├── WoW95.lua                    # Core addon framework
├── WoW95.toc                    # Table of contents
├── CLAUDE.md                    # Development documentation
├── Modules/
│   ├── QuestTracker.lua         # Enhanced quest tracking system
│   ├── Minimap.lua              # Square minimap with Windows 95 styling
│   ├── Windows/
│   │   ├── WindowsCore.lua      # Core window management
│   │   ├── GuildWindow.lua      # Guild & Communities interface
│   │   ├── SocialWindows.lua    # Social window delegation
│   │   └── MapWindow.lua        # Map window integration
│   ├── ActionBars.lua           # Action bar styling (in development)
│   ├── Bags.lua                 # Inventory windows (in development)
│   ├── Chat.lua                 # Chat frame styling (in development)
│   ├── StartMenu.lua            # Start menu system (in development)
│   ├── Taskbar.lua              # Taskbar implementation (in development)
│   └── Tooltip.lua              # Tooltip styling (in development)
└── Media/
    ├── xclose.tga               # Close button texture
    ├── minimise.tga             # Minimize button texture
    ├── maximize.tga             # Maximize button texture
    └── startbutton.tga          # Start button texture
```

### Key APIs Used
- **C_SuperTrack** - Modern quest tracking API
- **C_GuildInfo** - Guild roster management
- **RAID_CLASS_COLORS** - WoW class color definitions
- **Frame Hooking** - Integration with Blizzard UI

### Contributing
Contributions are welcome! Please feel free to submit pull requests or open issues for bugs and feature requests.

## License

This project is licensed under the Creative Commons Attribution-NonCommercial-ShareAlike 4.0 International License - see the [LICENSE](LICENSE) file for details.

**Note**: This addon is free for personal use but cannot be sold or used commercially. Any modifications must be shared under the same license.

## Acknowledgments

- Inspired by Microsoft Windows 95
- Built for the World of Warcraft community
- Special thanks to all contributors and testers

## Support

- **Issues**: [GitHub Issues](https://github.com/OwenModsTW/WoW95/issues)
- **Discussions**: [GitHub Discussions](https://github.com/OwenModsTW/WoW95/discussions)

---

*Bringing 1995 to Azeroth, one window at a time!*