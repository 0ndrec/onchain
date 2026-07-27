# onchain

A landing page and conceptual pipeline for a real-time blockchain event delivery system. This project aims to eliminate the need for teams to build and maintain custom blockchain indexing infrastructure by providing a reliable pipeline from onchain events to webhook receivers.

## 🚀 Overview

The "onchain" project is currently in the "Building" phase. Its primary goal is to solve the "undifferentiated heavy lifting" of node management, RPC costs, and event parsing.

### Key Features (Planned)
- **Real-time Delivery:** Instant webhook notifications for onchain events.
- **Reliable Pipeline:** Built-in retry logic and delivery guarantees.
- **Simple Integration:** Easy setup with any standard webhook receiver.

## 🛠️ Technical Stack

- **Frontend:** HTML5, CSS3, JavaScript.
- **Styling:** [Tailwind CSS](https://tailwindcss.com/) and custom CSS.
- **Animations:** [anime.js](https://animejs.com/) (included as `anime.min.js`).
- **Deployment:** Automated via GitHub Actions to GitHub Pages.

## 📦 Installation & Local Development

Since this is a static site, no complex build process is required.

1. **Clone the repository:**
   ```bash
   git clone https://github.com/0ndrec/onchain.git
   cd onchain
   ```

2. **Run locally:**
   Simply open `index.html` in any modern web browser, or use a local server (e.g., Live Server extension in VS Code or `python -m http.server`).

## 🌐 Deployment

This repository is configured for automatic deployment to **GitHub Pages**. 

- **Workflow:** The `.github/workflows/static.yml` file triggers a deployment whenever changes are pushed to the `main` branch.
- **404 Page:** A custom glitch-effect 404 page is included in the root directory.

## 📄 Project Structure

- `index.html` - Main landing page featuring a dynamic SVG pipeline animation.
- `style.css` - Global styles and responsive design layouts.
- `anime.min.js` - Library used for high-performance JavaScript animations.
- `404.html` - Custom error page.
- `.github/workflows/` - CI/CD configuration for GitHub Pages.
