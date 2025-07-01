# JustTouch
<img src="assets/images/logo.jpg" alt="Logo" width="120" align="left" style="margin-right: 20px;"/>


**JustTouch** is a simple mobile app for Android and iOS that lets you send files with just a tap - literally. Pick one or more files, generate a magnet link, and send it to another device via NFC. The other person gets the link and downloads the file directly. No pairing, no logins, no cloud.

## What It Does

- Lets you choose one or more files from your phone
- Creates a magnet link for the selected files
- Sends that magnet link via NFC to the other device
- The receiving device uses the link to download the file(s)

## How It Works

1. **Sender:**
   - Open the app
   - Select the file(s) you want to share
   - Tap your phone to another device — the magnet link is sent via NFC

2. **Receiver:**
   - Open the app and wait in “listening” mode
   - Tap your phone with the sender’s — the magnet link is received
   - The app downloads the file(s) using that link

## Why Magnet Links?

We use magnet links because they’re lightweight, fast to share, and work great with peer-to-peer protocols. The actual files aren’t sent over NFC — just the link. File transfer happens over the internet using the magnet link, similar to how torrents work.
