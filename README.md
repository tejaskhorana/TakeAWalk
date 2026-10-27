# TakeAWalk

An iOS app (with a 1×1 home-screen widget) that answers one question: **are conditions ideal to be outside right now?**

Product direction and decisions are kept locally (not in this repo).

## Setup (local only)

1. Copy `Config/Secrets.xcconfig.example` to `Config/Secrets.xcconfig` and fill in your values.
2. Keep your WeatherKit `.p8` key **outside** this repository (see the example file for the expected path).
3. Never commit `.p8`, `.mobileprovision`, `.env`, or `Secrets.xcconfig`. `.gitignore` blocks these by pattern, but check `git status` before every push.

## Status

Pre-code. Project scaffolding and product definition only.
