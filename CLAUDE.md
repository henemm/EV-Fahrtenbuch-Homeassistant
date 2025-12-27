# Fahrtenbuch - Project Guide

**Project-specific context for Claude Code. See `~/.claude/CLAUDE.md` for global collaboration rules.**

---

## Overview

**Fahrtenbuch** is a trip tracking app for Škoda Enyaq (EV) via Home Assistant integration, built with SwiftUI for iOS 17+.

**Features:**
- Trip start/end tracking (battery% + odometer)
- Monthly consumption analysis (kWh + costs)
- Export for billing (business/private trips)
- Live Activity + Dynamic Island support
- Siri Shortcuts integration
- Offline mode for manual battery input

**Current Version:** 1.0.7

**Development Target:**
- **Xcode 16 / Swift 6**
- **Minimum Deployment:** iOS 17.0
- **Testing:** Unit Tests in Tests/

---

## Agent OS + OpenSpec Integration

This project uses **Agent OS** for standards and **OpenSpec** for spec-driven development.

### Standards (`.agent-os/standards/`)

All coding standards and lessons learned are in:
- `global/` - Analysis-First, Scoping Limits, Documentation Rules
- `swiftui/` - Lifecycle Patterns, Localization, State Management
- `project/` - Project-specific lessons learned

### Agents (`.agent-os/agents/`)

Specialized agents with injected standards:
- `bug-investigator.md` - Bug analysis (Analysis-First)
- `feature-planner.md` - Feature planning (Spec-First)
- `spec-writer.md` - Automated spec creation from template
- `spec-validator.md` - Spec quality and completeness checks
- `localizer.md` - Localization
- `test-runner.md` - Unit test execution

### Workflows (`.agent-os/workflows/`)

- `bug-fix-workflow.md` - Full bug fix process
- `feature-workflow.md` - Feature development with OpenSpec
- `release-workflow.md` - Version bump and deploy

### Feature Specs (`openspec/specs/`)

- `features/` - Feature specifications
- `integrations/` - Integration specs (Home Assistant)

---

## Slash Commands

### Workflow-Phasen (nummeriert)

| Phase | Command | Agent | Purpose |
|-------|---------|-------|---------|
| 1 | `/1-analyse [query]` | - | Gruendliche Analyse VOR Code-Aenderungen |
| 2 | `/2-spec [entity]` | spec-writer | Spec aus Template erstellen |
| 3 | `/3-validate [name]` | spec-validator | Spec auf Vollstaendigkeit pruefen |

### Task-Commands

| Command | Agent | Purpose |
|---------|-------|---------|
| `/bug [desc]` | bug-investigator | Bug analysieren (nutzt intern /1-analyse) |
| `/feature [name]` | feature-planner | Feature planen (nutzt intern /1-analyse) |
| `/test` | test-runner | Unit Tests ausfuehren |
| `/localize` | localizer | Lokalisierung pruefen

---

## Bug-Fixing Pflicht

**Bei JEDEM Bug-Fix MUSS der `bug-investigator` Agent verwendet werden:**

- Aufruf: `/bug [Beschreibung]`
- Der Agent analysiert erst vollstaendig, dann wird (nach Freigabe) gefixt
- **Ausnahme:** Triviale Typos (1 Zeile, offensichtlich)
- **Standards:** Siehe `.agent-os/standards/global/analysis-first.md`

---

## Dokumentations-Pflicht

**SOFORT aktualisieren wenn Arbeit erledigt ist:**

1. Nach jedem Fix: ACTIVE-todos.md aktualisieren
2. Nach jedem Test: Ergebnis dokumentieren
3. Nach Feature: ACTIVE-roadmap.md aktualisieren

**Standards:** Siehe `.agent-os/standards/global/documentation-rules.md`

---

## Architecture Overview

```
iOS App (UI)
    |
    v
Service Layer (Services/)
    - HomeAssistantService (API client)
    - KeychainService (Token storage)
    - PersistenceController (Core Data)
    |
    v
External APIs
    - Home Assistant Cloud API → Škoda Connect → Enyaq
```

### Key Design Principles

1. **Offline-First:** Manual battery input when no network
2. **Privacy:** Token stored in Keychain, no cloud sync
3. **Data Latency Aware:** Škoda Connect updates only every 5-10 min

### Home Assistant Entities

- `sensor.enyaq_battery_level` - Batteriestand in %
- `sensor.enyaq_odometer` - Kilometerstand

---

## Build Commands

**Build iOS app:**
```bash
xcodebuild -project ios/HomeAssistentFahrtenbuch.xcodeproj \
  -scheme "HomeAssistentFahrtenbuch" \
  -configuration Debug \
  -destination 'platform=iOS Simulator,name=iPhone 15 Pro' \
  build
```

**Open in Xcode:**
```bash
open ios/HomeAssistentFahrtenbuch.xcodeproj
```

**Create Archive:**
```bash
xcodebuild archive \
  -scheme "HomeAssistentFahrtenbuch" \
  -configuration Release \
  -sdk iphoneos \
  -archivePath "./build/HomeAssistentFahrtenbuch.xcarchive" \
  CODE_SIGN_STYLE=Automatic \
  DEVELOPMENT_TEAM=XK87E2B3VR
```

---

## Project Structure

```
Fahrtenbuch-Enyaq-HomeAssistant/
├── .agent-os/               # Standards, Agents, Workflows
├── .claude/commands/        # Slash commands
├── openspec/                # Feature Specifications
├── DOCS/                    # Setup guides, specs
├── prototype/               # Python prototype (validation)
├── ios/
│   └── HomeAssistentFahrtenbuch/
│       ├── Models/          # Core Data + Settings
│       ├── Services/        # API, Keychain, Persistence
│       ├── ViewModels/      # Business Logic
│       ├── Views/           # SwiftUI Views
│       └── Intents/         # Siri Shortcuts
└── FahrtenbuchWidget/       # Widget + LiveActivity
```

---

## Core Components

| Component | File | Purpose |
|-----------|------|---------|
| HomeAssistantService | Services/ | API client (async/await) |
| Trip | Models/ | Core Data entity |
| TripsViewModel | ViewModels/ | Trip tracking logic |
| FahrtenbuchWidget | FahrtenbuchWidget/ | LiveActivity + Widget |

---

## Quick Reference

**Version:** 1.0.7

**Main Schemes:**
- "HomeAssistentFahrtenbuch" - iOS App
- "FahrtenbuchWidgetExtension" - Widget

**Key Files:**
- `Services/HomeAssistantService.swift`
- `ViewModels/TripsViewModel.swift`
- `Models/Trip+CoreDataClass.swift`

**Dependencies:**
- None (pure SwiftUI + system frameworks)

---

## Documentation Structure

| Location | Content |
|----------|---------|
| `.agent-os/standards/` | Coding standards |
| `.agent-os/standards/project/` | Project lessons learned |
| `.agent-os/agents/` | Specialized agents |
| `.agent-os/workflows/` | Bug fix, feature, release workflows |
| `openspec/specs/` | Feature specifications |
| `DOCS/` | Setup guides, release notes |

---

## Localization

- **Primary:** German (de)
- **Files:** Hardcoded strings (single-language app)

---

**For global collaboration rules, see `~/.claude/CLAUDE.md`**
