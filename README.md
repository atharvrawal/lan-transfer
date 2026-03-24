# 🚀 lan-transfer

Fast, minimal-setup local file transfer over LAN using SSH + rsync.

> Achieve near hardware limits (~70+ MB/s) by removing unnecessary layers.

---

## 🧠 Why this exists

Most local file transfer tools (LocalSend, Nearby Share, etc.) prioritize convenience over performance.

They introduce:
- custom protocols  
- extra abstraction layers  
- inefficient transfer pipelines  

Result: ~20 MB/s on networks capable of much more.

---

## ⚡ What this does

This project strips things down to the minimum:

- SSH → secure transport (encrypted)
- rsync → efficient transfer
- nc → fast device discovery
- fzf → interactive navigation

No cloud. No UI. No unnecessary layers.

---

## 📊 Performance

| Method        | Speed       |
|---------------|-------------|
| LocalSend     | ~20 MB/s    |
| lan-transfer  | ~70+ MB/s   |

*(Same hardware, same network)*
> Near saturation of WiFi hotspot bandwidth in real-world use.

---

## ✨ Features

- 🔍 Auto-discovery of device on LAN (no IP typing)
- ⚡ High-speed transfer using rsync
- 🔐 Fully encrypted (SSH)
- 📂 Interactive file browser (fzf)
- 📦 Works with files and folders
- 🧠 Handles Android hotspot quirks

---

## 📦 Requirements

Install on your laptop:

```bash
sudo pacman -S rsync fzf openssh netcat iproute2
```

On your phone (Termux):

```bash
pkg install openssh rsync
```

---

## ⚙️ Setup

### 1. Start SSH on phone

```bash
sshd
```

(Optional: keep it running with `tmux`)

---

### 2. Clone repo

```bash
git clone https://github.com/atharvrawal/lan-transfer
cd lan-transfer
```

---

### 3. Add to your shell

```bash
source lan-transfer.sh
```

Or add to `~/.bashrc`

---

### 4. Set up passwordless SSH (required)

This tool requires SSH key-based authentication.

#### On your laptop:

Generate a key (if you don’t have one):

```bash
ssh-keygen -t ed25519
```

Copy it to your phone:

```bash
ssh-copy-id -p 42069 u0_aXXX@<phone-ip>
```

> Replace `u0_aXXX` with your Termux username and `<phone-ip>` with your phone’s IP.

---

#### If `ssh-copy-id` is not available:

Manually copy the key:

```bash
cat ~/.ssh/id_ed25519.pub | ssh -p 42069 u0_aXXX@<phone-ip> "mkdir -p ~/.ssh && cat >> ~/.ssh/authorized_keys"
```

---

Once this is set up, you should be able to run:

```bash
ssh -p 42069 u0_aXXX@<phone-ip>
```

without being prompted for a password.

This is required for `lan-transfer` to work properly.

## ⚠️ Shell Support
This tool is designed for **bash** and integrates with `~/.bashrc`.

If you are using another shell (fish, zsh, etc.), you can still use it by running:

```bash
./droidpush.sh <file_or_folder>
./droidpull.sh
```

Or manually adapt the functions for your shell.

## 🚀 Usage

### Push (laptop → phone)

```bash
droidpush file.txt
droidpush folder/
```

Files will be sent to:

```bash
/storage/emulated/0/Download
```

---

### Pull (phone → laptop)

```bash
droidpull
```

- `Enter` → go inside folder  
- `Ctrl+D` → download file/folder  
- `..` → go back  

---

## 🧠 How it works

1. Scan LAN for device with open SSH port  
2. Verify it's an Android/Termux device  
3. Connect via SSH  
4. Transfer using rsync (no delta, full speed)  

---

## ⚠️ Notes

- Android hotspot blocks some TCP directions  
  → this tool works around it by using pull-based transfers  
- First run may take ~1–2 seconds (IP scan)  
- Setup takes ~2 minutes once  

---

## 🎯 Philosophy

> Don’t rebuild everything. Remove what’s slowing you down.

---

## 📣 Try it

If you’ve ever been frustrated with slow local transfers, you might want to try this.

---

## 🛠️ Future ideas

- IP caching (instant reconnect)  
- multi-select downloads  
- preview support  
- packaging as installable CLI  
