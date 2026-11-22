# iOS bridge — foreground connectivity prototype

Only authenticated PING/PONG is enabled. No SMS, calls or cellular audio yet. No root or cloud required for this test.

## Device acceptance
1. Download debug APK and unsigned IPA from GitHub Actions on ios-bridge. Sign IPA using a supported signing method before installing.
2. On Poco in Termux, install openssl if missing and run scripts/pair-local.sh using bash. Keep generated files private.
3. Copy server.p12 and client.pem to local Android storage; transfer client.p12 privately to iPhone Files. Read server-fingerprint.txt. Do not upload credentials to GitHub.
4. Enable Poco hotspot, connect iPhone. Find router IPv4 under the iPhone Wi-Fi network details.
5. Open iOS Bridge Probe launcher on Poco, select server.p12 and client.pem, enter that IP and pairing password, start.
6. Open AntiRegisterProbe on iPhone, enter IP, SHA256 fingerprint and password, import client.p12, tap Test connection.
7. Expect Authenticated probe passed. Repeat with incorrect fingerprint and expect failure. Stop probe after test.

Next gate: real device connectivity before SMS dispatch or telephony work. Cellular audio routing and background incoming notifications remain unverified. Do not root or flash firmware at this stage.
