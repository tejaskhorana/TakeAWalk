# TakeAWalk

An iOS app with a home-screen widget that answers one question: **are conditions good to be outside right now?**

The app checks current weather against ranges you set. A door shows the answer: open with light when conditions are good to go out, closed when they aren't. Use the widget to log how a walk felt.

Product direction and decisions are kept locally (not in this repo).

## Run it on your Mac (first time)

You need Xcode 15+ and an Apple ID signed into Xcode (Xcode → Settings → Accounts). WeatherKit requires a paid Apple Developer membership.

**1. Install XcodeGen (one time)**
```
brew install xcodegen
```
No Homebrew? Install it from https://brew.sh first.

**2. Set your Team ID**
Find your 10-character Team ID at developer.apple.com → Membership, or in Xcode under Settings → Accounts. In `project.yml`, replace `YOUR_TEAM_ID` with it.

**3. Generate the Xcode project**
From the repo folder in Terminal:
```
cd ~/development/TakeAWalk
xcodegen generate
```
This creates `TakeAWalk.xcodeproj`. Run it again after any change to `project.yml`. XcodeGen also writes the entitlements files, so don't edit those by hand.

**4. Open the project, not the folder**
Double-click `TakeAWalk.xcodeproj`. Opening the folder won't run the app.

**5. Check the capabilities (first time)**
Select the **TakeAWalk** target → **Signing & Capabilities**. You should see:
- **WeatherKit**
- **App Groups** with `group.com.tejaskhorana.TakeAWalk`

The **TakeAWalkWidget** target needs the same App Group.

If Xcode says the bundle ID isn't available, change the prefix `com.tejaskhorana` in `project.yml` to one of yours, then run `xcodegen generate` again.

**6. Run**
- Pick an iPhone simulator (or your iPhone connected by cable) at the top of Xcode, then press ▶.
- **Simulator:** WeatherKit and location both work. To set a location, use Features → Location → Custom Location, or a preset like Apple Park.
- **Physical iPhone:** enable Developer Mode (Settings → Privacy & Security → Developer Mode), then trust your Mac when prompted.

Allow notifications and location when asked. The circles fill in after the first fetch.

## Using it

- **Conditions tab:** a door (open = ideal, closed = not) and 12 attribute circles. Active criteria sort to the top. Green is in range, red is out of range, grey is inactive or no data. Tap a circle to change its range or turn it on or off.
- **Logs tab:** each log shows the active criteria that counted, marked ✓ or ✗. Swipe a log to delete it.
- **Widget:** the top shows the door. The bottom has Good and Bad buttons that log the current conditions without opening the app. After a press, the thumb briefly becomes a checkmark.

## Notes

- WeatherKit runs through Apple's framework, authenticated by app signing. No API key ships in the app.
- Background refresh runs about every 30 minutes, but iOS decides when. It uses the last location seen in the foreground.
- Background tasks don't run in the simulator unless you trigger them from Xcode's debugger.
- Logs are stored as a JSON file in the shared App Group container.

## Status

Working on device. Core features are in place: status door, attribute tiles, logs, and the widget.
