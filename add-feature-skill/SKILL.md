---
name: add-feature-skill
description: >
  Guide for adding new features to ClipDrop. Covers architecture,
  extension points, patterns, and build process.
---

## Overview

ClipDrop is a macOS menu bar app that reads clipboard text, lets the user edit it in a monospaced TextEditor, and saves it to any of 8 file formats via NSSavePanel. It lives in the menu bar as a clipboard-to-file utility.

## Architecture

ClipDrop is a single-file SwiftUI menu bar app (`ClipDrop.swift`, ~337 lines). It uses the `@main` struct `ClipDropApp` with a `MenuBarExtra(.window)` scene. One `@Observable` class owns all mutable state:

- **`ClipboardManager`** -- reads clipboard text, manages the editor text buffer, handles save-to-file via NSSavePanel, tracks file type selection, and shows status messages with auto-dismiss.

It is held as a `@State` property on `ContentView`.

## Key Types

| Type | Kind | Description |
|------|------|-------------|
| `CDTheme` | enum | Static color constants for the dark UI theme |
| `FileType` | enum | CaseIterable enum with 8 file types (txt, md, swift, json, yaml, html, csv, log), each with extension, label, icon, and UTType |
| `TextStats` | enum | Pure static functions for char/word/line/byte counting and size formatting |
| `ClipboardManager` | @Observable class | All mutable state: text buffer, file type, status messages, save logic |
| `ContentView` | View | Root popup view with header, toolbar, TextEditor, stats bar, status banner, and footer |
| `ClipDropApp` | @main App | MenuBarExtra with .window style and clipboard icon |

## How to Add a Feature

1. **Define any new model types** at the top of `ClipDrop.swift` after the existing `// MARK:` sections. Follow the existing pattern: CaseIterable enums, Identifiable structs.

2. **If the feature needs new state**, add properties to `ClipboardManager`. This is the single source of truth for all app state. Examples:
   - New file operation --> add a method to `ClipboardManager`
   - New UI mode --> add an enum property to `ClipboardManager`
   - New persistent setting --> add `@AppStorage` properties to `ContentView`

3. **If adding a new file type**, add a case to `FileType` and implement all four computed properties: `label`, `ext`, `icon`, and `utType`.

4. **If adding a new toolbar action**, add a `Button` to the toolbar `HStack` in `ContentView` and a corresponding method on `ClipboardManager`.

5. **If adding pure logic** (text processing, formatting, validation), add static functions to `TextStats` or create a new enum namespace. Keep them pure for testability.

6. **If adding a new view section**, insert it in the `ContentView` `VStack` between existing sections, separated by `Divider().overlay(CDTheme.border)`.

7. **Build and test** with `bash build.sh` then `open ClipDrop.app`.

## Extension Points

- **New FileType cases** -- add to the `FileType` enum with all four properties (label, ext, icon, utType)
- **New toolbar buttons** -- add to the toolbar HStack in ContentView (Paste, Clear, Copy row)
- **New stats** -- add static functions to `TextStats`, display in the stats bar HStack
- **New text processing** -- add methods to `ClipboardManager` or static functions to a new enum
- **New footer actions** -- add buttons next to Save As in the footer HStack
- **Persistent settings** -- use `@AppStorage` on ContentView for preferences that survive restarts
- **File type auto-detection** -- add logic to `ClipboardManager.readClipboard()` that inspects content and sets `fileType` automatically

## Conventions

- **Theme**: All colors come from `CDTheme` static properties. Use `CDTheme.bg` for backgrounds, `CDTheme.surface` for editor area, `CDTheme.accent` for interactive elements, `CDTheme.success`/`CDTheme.error` for status messages.
- **Status messages**: Call `showStatus(_:isError:)` on `ClipboardManager`. Messages auto-dismiss after 3 seconds. The generation counter prevents stale dismissals from clearing newer messages.
- **SF Symbols**: Used throughout for icons. Keep the icon style consistent with existing buttons.
- **Stats bar**: Uses `statItem(_:value:)` helper for consistent formatting. All stats are computed live from `manager.text`.
- **File save**: Uses `NSSavePanel.runModal()` directly from button action. `lastSaveDirectory` remembers the last used directory within the session.
- **Pure functions**: `TextStats` methods are pure static functions with no side effects -- easy to test. Follow this pattern for new logic.

## Build & Test

```bash
bash build.sh        # Compiles ClipDrop.swift and creates ClipDrop.app bundle
open ClipDrop.app    # Run the app (appears in menu bar)
swift test_clipdrop.swift  # Run pure function tests (38 tests)
```

Requires macOS 14.0+ and Xcode command-line tools. The app runs as `LSUIElement` (no Dock icon).

## Homebrew Install

```bash
brew tap scasella/tap
brew install --cask clipdrop
```
