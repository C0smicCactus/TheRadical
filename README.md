# The Radical

A high-performance news aggregator centralized for Australian political and social perspectives — built for rapid information scanning and independent media discovery.

<div align="center">

<a href="https://c0smiccactus.github.io/TheRadical/">
  <img src="https://img.shields.io/badge/Live_Demo-Visit_The_Radical-red?style=for-the-badge&logo=rocket" alt="Live Site">
</a>

</div>

-----

> [!IMPORTANT]
> **Beta Disclaimer:** The Radical is currently in active development. As a centralized hub for independent media, it relies on direct RSS/Atom feeds. You may encounter incomplete metadata as we refine our custom regex-based parsing engines.

-----

## 💡 Motivation

The Radical was born out of a need to centralize news from leftist and independent perspectives without the friction of checking dozens of separate websites. In the current media landscape, independent voices are often scattered; this dashboard brings them into a single, cohesive interface.

**Learning Journey:**
This project serves as my primary vehicle for learning **Flutter**. While I utilize AI to assist in complex architecture and debugging, the goal is to create a functional tool that serves the community while I refine my skills as a developer.

-----

## ✨ Features

### Content Management

| Feature | Description | Source/Tech |
| :--- | :--- | :--- |
| **Real-time Aggregation** | Direct fetching from 37+ independent sources via CORS proxying. | `html` Parser + Regex |
| **Topic Classification** | Automatic sorting into Economy, Labour, First Nations, Environment, and more. | Weighted Keyword Matching |
| **Media Proxying** | Optimized image delivery and CORS handling for web browsers. | `images.weserv.nl` Proxy |
| **Source Filtering** | Toggle between core and extended coverage modes. | 30 Core + 4 Extended Sources |
| **Theory Filter** | Hide book reviews, essays, and archival content. | Keyword Detection |

### UI & Personalization

| Feature | Description | Requirements |
| :--- | :--- | :--- |
| **Persistent Themes** | Choice of 6 high-contrast palettes + custom color picker saved to local device storage. | `SharedPreferences` |
| **Typography** | Optimized for readability using Space Grotesk and Manrope. | `Google Fonts` |
| **Responsive Grid** | Adaptive layout that shifts from 1 to 3 columns based on width. | `MediaQuery / GridView` |
| **Topic Filtering** | Filter feed by: Economy, Environment, First Nations, International, Labour, Mutual Aid, Parliament, Praxis, Technology. | `Keyword Matching Logic` |

### Controls

| Feature | Description |
| :--- | :--- |
| **Extended Coverage** | Toggle to include broader independent sources beyond the core 30. |
| **Custom Color Picker** | Pick any accent color beyond the 6 preset palettes. |
| **Reset Feed** | Clear all cached articles and viewed story tracking. |
| **Signal Sources** | View all configured RSS/Atom feed sources. |

-----

## 🛠 Tech Stack

* **Framework:** [Flutter](https://flutter.dev) (Web target)
* **Data Handling:** Custom RSS/Atom XML parsing engine using `html` package
* **Networking:** [http](https://pub.dev/packages/http) with [corsproxy.io](https://corsproxy.io/) (primary) and [allorigins.win](https://allorigins.win) (fallback)
* **Image Proxy:** [images.weserv.nl](https://images.weserv.nl) for CORS-safe thumbnail delivery
* **Storage:** [shared_preferences](https://pub.dev/packages/shared_preferences) for user settings
* **Icons:** [Font Awesome Flutter](https://pub.dev/packages/font_awesome_flutter)
* **Fonts:** Space Grotesk & Manrope via [Google Fonts](https://fonts.google.com/)

-----

## 📊 Feed Sources

The Radical aggregates from **37 independent news sources** organized into three categories:

### Core Sources (30)
Picket Line, Green Left, Red Flag, Red Spark, Socialism Today, Solidarity, Labor Tribune, World Socialist Web Site, The Anvil, Vanguard, Partisan!, Red Ant, Temokalati, Co-Op News, IWW (South East Queensland), Freedom, Disputes Report, Overland, Spirit of Eureka, Black Peoples Union, IndigenousX, Red Black Notes, The Guardian (CPA), Arena, The Communist, Militant Worker, Koori Mail, 3CR

### Global Sources (3)
Jacobin, The Militant, Counter Punch

### Extended Sources (4)
Michael West, Independent Australia, The Conversation, The Guardian (GNM)

-----

## 🚀 Roadmap & Known Issues

### Known Bugs

- Some RSS feeds return non-standard date formats, occasionally defaulting to "Recent".
- Large XML payloads can cause a brief UI stutter on initial parse in lower-end browsers.

-----

Don't wanna this app and have your own RSS app you prefer already? No dramas! All the RSS feeds used can be found [here](https://github.com/C0smicCactus/TheRadical/blob/main/lib/core/app_config.dart).