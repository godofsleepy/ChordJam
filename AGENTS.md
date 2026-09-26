# AGENTS.md

Guidance for AI coding agents working in this repo.

## Project

ChordJam is an iOS/iPadOS SwiftUI game that teaches guitar chords. The mic listens while the player strums, a Core ML sound classifier detects the chord, and the player moves through levels, a song-play level, streaks, badges and a Game Center leaderboard.

- Language: Swift 5, SwiftUI
- Target: iOS 17.2+, iPhone and iPad (`TARGETED_DEVICE_FAMILY = 1,2`)
- Bundle ID: `com.anthony-gufron.ChordJam`
- Dependencies (Swift Package Manager, set up in `ChordJam.xcodeproj`): AudioKit, AudioKitEX, AudioKitUI, SoundpipeAudioKit, Tonic
- Apple frameworks: CoreML, SoundAnalysis, AVFoundation, GameKit

## Build and test

You need Xcode on macOS. There is no Package.swift, Makefile or CI.

```sh
# Build
xcodebuild -project ChordJam.xcodeproj -scheme ChordJam \
  -destination 'platform=iOS Simulator,name=iPhone 15' build

# Test
xcodebuild -project ChordJam.xcodeproj -scheme ChordJam \
  -destination 'platform=iOS Simulator,name=iPhone 15' test
```

- Chord detection needs a real microphone, so test it on a device. The simulator is fine for UI work.
- `ChordJamTests/` and `ChordJamUITests/` only hold the Xcode template tests.
- On Linux you cannot build. Keep changes small and check them by reading the code.

## Layout

```
ChordJam/
  ChordJamApp.swift        App entry. NavigationView > ContentView, injects GameCenterManager
  ContentView.swift        Root switch between Introduction, Onboarding and MainMenu (string state)
  Introduction.swift, Onboarding.swift, OnboardImage.swift   First-run flow
  GameCenterManager.swift  Game Center auth, leaderboard, score reporting (singleton)
  StringDetection.swift    AudioKit pitch tracking (single-note detection)
  LevelController.swift    Older AudioKit pitch controller (LevelsController)
  LearnSong.swift, ProgressBar.swift, SuccessCase.swift
  ML Model/
    ChordDetection.mlmodel Core ML chord classifier
    chordModel.swift       SoundAnalysis wrapper. Publishes predictionResult and points per level
  Models/                  Plain data types: ChordType, ChordModel, LyricModel, MusicModel, MusicPlayerState
  Utils/                   Color helpers, BadgeNotif
  Views/
    MainMenuView.swift     Level map. Uses NavigationLink(isActive:) to push levels
    ChordPracticeView.swift Shared screen for chord levels 1-4 (ChordLevel config: .c, .am, .g, .dm)
    Level1..Level4/        Thin LevelNView wrappers around ChordPracticeView, plus ModalLevelN intros
    CombinedLevels/        Wrappers that chain the level views
    Level 6/               Song-play mode (Level6View, Level6ViewModel, Components/)
    ProfileView, LeaderboardView, CollectionView, ChallengesView, NavBar, FinishLevel
  Assets/                  Audio (for example grikfrik.mp3)
  Assets.xcassets/         Images and colors
```

## How it works

- **Navigation:** `ContentView` picks the screen from a `currentView` string. `unlockedLevel` is a `@Binding` passed down to every level.
- **Chord detection:** `chordModel` runs `AVAudioEngine` into `SNAudioStreamAnalyzer` with `ChordDetection.mlmodel`. It accepts a prediction above 60% confidence. In levels 1-4 each `practiceChord` hit (currently Am for every level) adds 30 points; 90 clears the level. Call `stopAudioEngine()` when leaving a level.
- **Song mode (Level 6):** `Level6ViewModel` uses a `Timer` to scroll the chords and lyrics (`[ChordModel]` and `[LyricModel]` with timestamps) against an `AVAudioPlayer`.
- **Persistence:** `UserDefaults` only. Keys: `LevelSekarang` (current level), `streakDays`, `lastOpenDate`.

## Conventions

- Match the code around you: SwiftUI views, `ObservableObject` with `@Published` for state, and each file starts with the Xcode header comment.
- Put new views in `Views/` and new data types in `Models/`. When you add a file, register it in `project.pbxproj` too (Xcode does this for you; by hand you must add both the file reference and the build phase entries).
- Some names and comments are in Indonesian (for example `LevelSekarang` means "current level"). Keep existing keys the same, or saved progress will break.
- Don't commit `xcuserdata/` or `.DS_Store`.
- Keep diffs small. Don't reformat or rename files you aren't changing.
