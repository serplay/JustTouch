# JustTouch
<img src="assets/images/logo.png" alt="Logo" width="120" align="left" style="margin-right: 20px;"/>


**JustTouch** is a simple mobile app for Android and iOS that lets you send files with just a tap, literally. Pick one or more files, generate a web link, and send it to another device via NFC. The other person gets the link and downloads the file directly. No pairing, no logins, no cloud, no app installation required.
* For now, users need to be connected to the same WIFI network.

## What It Does

- Lets you choose one or more files from your phone
- Creates a web link for the selected files
- Sends that web link via NFC to the other device
- The receiving device uses the link to download the file(s)

## How It Works

1. **Sender:**
   - Open the app
   - Select the file(s) you want to share
   - Tap your phone to another device - the web link is sent via NFC
   - The receiver gets the link open in their browser and downloads the file(s)

2. **Receiver:**
   - Just Touch.

## Why Web Links?

We use web links because they’re lightweight, fast to share, and work great with peer-to-peer protocols. The actual files aren’t sent over NFC — just the link. File transfer happens over the internet using the web link, similar to how torrents work.
