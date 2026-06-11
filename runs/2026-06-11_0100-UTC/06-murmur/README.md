# Murmur

**Private voice journal with on-device transcription**

## Problem & Audience

Writing takes effort. Speaking is natural. Murmur lets you record voice notes and get instant on-device transcripts — no cloud upload, no privacy compromise. Think "voice diary that actually understands you." Audience: journaling enthusiasts, therapy supplement users, and busy professionals aged 20–45 who want low-friction self-reflection.

## Features

- **One-tap recording** — Record, pause, and resume voice notes with a clean waveform display
- **On-device transcription** — `SFSpeechRecognizer` with `requiresOnDeviceRecognition` — audio never leaves the phone
- **Mood tagging** — 5 moods (Great / Good / Neutral / Low / Rough) with emoji per entry
- **Custom tags** — add freeform hashtags; popular tags surfaced for quick re-use
- **Calendar view** — month grid with mood dots, tap any day to see that day's entries
- **Full-text search** — searches transcripts, titles, and tags with highlighted matches
- **Favorites** — heart any entry for quick access
- **Stats** — total entries, minutes recorded, words transcribed; mood donut chart
- **Privacy-first** — local audio files in `Documents/MurmurAudio/`, delete-all option
- **Settings** — haptics, auto-transcribe toggle, default mood, daily reminder notification

## Run Steps

```bash
cd runs/2026-06-11_0100-UTC/06-murmur/ios
xcodegen generate
open Murmur.xcodeproj
# Requires iOS device or simulator with speech recognition support
# NSMicrophoneUsageDescription and NSSpeechRecognitionUsageDescription in Info.plist
```

## Tech Notes

- `RecorderViewModel` (`@Observable`) manages `AVAudioRecorder` state machine (idle → recording → paused → processing → done)
- Waveform: `AVAudioRecorder.averagePower` polled every 50ms, normalized to 0–1, stored as sliding window of 60 samples
- Transcription: `SFSpeechURLRecognitionRequest` with `requiresOnDeviceRecognition = true` run after recording stops
- `FlowLayout` custom `Layout` implementation for tag chips
- `AudioStore` utility handles `Documents/MurmurAudio/` directory lifecycle

## Monetization

**Free**: 10 entries/month → **Murmur Pro** ($2.99/month or $19.99/year): unlimited entries, export transcripts as text/PDF, custom tags, extended history. Strong recurring revenue from daily journalers.

## Why It Can Hit

Voice journaling is the natural evolution of text journaling for a generation that texts but doesn't type long-form. The on-device privacy angle is a genuine differentiator — Day One charges $35/year and sends data to the cloud.

## Self-Review Attestation

- [x] Full recording state machine (idle/recording/paused/processing/done) implemented
- [x] Real `SFSpeechRecognizer` transcription with on-device flag
- [x] Real `AVAudioRecorder` waveform via power metering
- [x] 5+ distinct screens (Record, Journal, Entry Detail, Calendar, Search, Settings)
- [x] Mood tracking with donut chart (Swift Charts)
- [x] Full-text search with highlighted matches via `AttributedString`
- [x] Custom `FlowLayout` for tag chips
- [x] SwiftData models with cascade-safe deletion
- [x] XcodeGen project.yml, iOS 17, `@Observable` throughout
