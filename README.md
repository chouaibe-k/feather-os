# FeatherOS — Simple Windows-Style Edition for Old Laptops

Welcome! This repository powers **FeatherOS**, custom-built for your old laptop so you **never have to write code**.

## What This Gives You
1. **Installs right inside Windows (Dual-Boot with 0 hassle)**: Keep your existing Windows 100% untouched and choose between **Windows** or **FeatherOS (Q4OS Windows Edition)** every time you turn on the laptop.
2. **Looks & Feels Like Windows**: Start Menu in the bottom-left, Taskbar at the bottom, My Computer, Control Panel, and familiar icons—while using only **~140 MB of RAM**.
3. **5-Layer Security Fortress**:
   - **Immune to Windows `.exe` Viruses & Trojans** by design.
   - **Strict Anti-Hacker Firewall (`UFW`)**: Blocks all incoming hacker probes on Wi-Fi.
   - **Anti-Malware & Anti-Phishing DNS Shield (`1.1.1.2` & `9.9.9.9`)**: Blocks malicious websites, spyware, and scam pages before they even load.
   - **ClamAV Antivirus Guard**: Automatically scans your `Downloads` and `Desktop` folders daily and quarantines any infected attachments.
   - **Browser SafeBrowsing & Popup Shield**: Automatically blocks dangerous downloads and pop-ups.
4. **100% Automatic Updates + AI Remote Auto-Pilot**:
   - Your laptop updates its own security patches automatically in the background.
   - Even better: it checks [`remote-updates.sh`](./remote-updates.sh) in this repository every 15 minutes. **Whenever you want a new app or change on your laptop, just tell your AI assistant in chat—and your laptop will install it automatically!**

---

## Step-by-Step Installation (No Coding Required)

### Step 1: Install the Base Windows-Style OS (Dual-Boot directly from Windows!)
Because you already have Windows on the laptop, you don't even need to create a bootable USB drive or touch the BIOS:
1. On your old laptop in Windows, open your browser and go to the official **Q4OS for Windows** download page:
   👉 **[Download Q4OS Windows Setup (`q4os-winsetup.exe`)](https://www.q4os.org/downloads1.html)** *(Click **"Q4OS Aquarius, WinSetup.exe"**)*
2. Double-click the downloaded `q4os-winsetup.exe` file—just like installing any normal Windows program.
3. Choose how much disk space to give it (e.g., **20 GB**), enter a password, and click **Install**.
4. When you restart your laptop, a menu will appear asking whether you want to start **Windows** or **Q4OS**. Choose **Q4OS** and pick the **"Basic / Plasma or Trinity"** Windows-style layout!

### Step 2: Activate Your Custom Speed Booster, Antivirus & AI Auto-Pilot
Once you are on your new desktop, open the terminal **just once** (press `Ctrl + Alt + T` or click **Start -> Terminal**) and paste this single line:

```bash
curl -fsSL https://raw.githubusercontent.com/chouaibe-k/feather-os/main/setup.sh | sudo bash
```

**That's it—you will never need to touch a command again!** From that moment on, your laptop is linked to your AI assistant for automatic updates, security, and maintenance.
