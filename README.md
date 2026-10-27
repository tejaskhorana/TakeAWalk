# TakeAWalk

An iOS app with a 1×1 home-screen widget that answers one question: **are conditions ideal to be outside right now?**

Product direction and decisions are kept locally (not in this repo).

## Build

Requirements: a Mac with Xcode 15+, an Apple Developer account, and [XcodeGen](https://github.com/yonaskolb/XcodeGen).

1. `brew install xcodegen`
2. In `project.yml`, replace `YOUR_TEAM_ID` with your Apple Developer Team ID.
3. In the Apple Developer portal:
   - Create App IDs `com.tejaskhorana.TakeAWalk` and `com.tejaskhorana.TakeAWalk.Widget`.
   - Enable **WeatherKit** and **App Groups** for the app ID. Create the app group `group.com.tejaskhorana.TakeAWalk`.
4. Run `xcodegen generate`, then open `TakeAWalk.xcodeproj`.
5. Select an iPhone and run. WeatherKit and location need a device or simulator with network access.

## Notes

- WeatherKit uses the Apple WeatherKit framework, authenticated by your app's signing. No API key ships in the app, which avoids exposing a private key.
- Background refresh is scheduled about every 30 minutes, but iOS decides the actual timing. It uses the last location seen in the foreground.
- `Config/Secrets.xcconfig.example` is no longer used.

## Status

First build. Not yet compiled or run. Expect minor fixes on first build.
