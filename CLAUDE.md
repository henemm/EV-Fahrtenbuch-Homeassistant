# Fahrtenbuch-Enyaq-HomeAssistant - Project Guide

**Project-specific context for Claude Code. See `~/.claude/CLAUDE.md` for global collaboration rules.**

---

## Overview

**Projekt:** Fahrtenbuch-App für Škoda Enyaq (Elektroauto)
**Ziel:** Automatisches Tracking von Fahrten via Home Assistant → Kostenabrechnung
**Primärer Nutzer:** Hennings Sohn (privater Enyaq-Nutzer)
**Technologie:** Python-Prototyp → später iOS App (SwiftUI)

**Aktuelle Phase:** Prototyp - Validierung der Home Assistant API Integration

**Core Features (geplant):**
- Fahrt starten/beenden via Button (trackt Batterie% + km-Stand)
- Monatliche Auswertung: Verbrauch (kWh) + Kosten (€)
- Export-Funktion für Abrechnung
- Einstellbare Parameter: Strompreis, Batteriekapazität

**Vollständige Spezifikation:** Siehe [DOCS/project-spec.md](DOCS/project-spec.md)

---

## Architecture Overview

### Phase 1: Prototyp (aktuell)
- **Technologie:** Python + requests
- **API:** Home Assistant REST API (Cloud)
- **Daten:** JSON-basiertes Speichern von Test-Fahrten
- **Ziel:** Validierung der API-Integration

### Phase 2: iOS App (geplant)
- **Framework:** SwiftUI (iOS 17+)
- **Design:** iOS 18 "Liquid Glass" Design Language
- **Backend:** Home Assistant REST API (direkt aus Swift)
- **Datenspeicherung:** Core Data (lokal)
- **Authentifizierung:** Langlebiger Home Assistant Token

**Datenfluss:**
```
App → Home Assistant Cloud API → Škoda Connect → Enyaq
```

---

## Build Commands

### Prototyp (Python)
```bash
cd prototype
source venv/bin/activate
python ha_api_test.py
```

### iOS App
```bash
# In Xcode öffnen:
open ios/HomeAssistentFahrtenbuch.xcodeproj

# Build: ⌘ + B
# Run: ⌘ + R
# Tests: ⌘ + U
```

**Setup-Anleitung:** Siehe [DOCS/ios-setup.md](DOCS/ios-setup.md)

---

## Project Structure

```
Fahrtenbuch-Enyaq-HomeAssistant/
├── DOCS/
│   ├── home-assistant-setup.md    # Anleitung: Token + Entity-IDs
│   ├── project-spec.md             # Vollständige Projekt-Spezifikation
│   ├── core-data-model.md          # Core Data Entity Definition
│   └── ios-setup.md                # Xcode Setup-Anleitung
├── prototype/
│   ├── ha_api_test.py              # Python-Prototyp
│   ├── quick_test.py               # Schneller Test (nicht-interaktiv)
│   ├── config.example.json         # Template für Konfiguration
│   ├── config.json                 # User-Config (gitignored)
│   ├── trips.json                  # Gespeicherte Test-Fahrten
│   ├── venv/                       # Python Virtual Environment
│   └── README.md                   # Prototyp-Dokumentation
├── ios/
│   ├── HomeAssistentFahrtenbuch/   # iOS App Code
│   │   ├── Models/                 # Core Data + Settings
│   │   ├── Services/               # API-Client, Keychain, Persistence
│   │   ├── ViewModels/             # Business Logic
│   │   ├── Views/                  # SwiftUI Views
│   │   └── HomeAssistentFahrtenbuchApp.swift
│   └── README.md                   # iOS App Dokumentation
├── .gitignore
└── CLAUDE.md                       # Dieses Dokument
```

---

## Core Components

### Prototyp (Python)
- **HomeAssistantClient:** API-Client für Home Assistant
  - `test_connection()` - Verbindungstest
  - `get_entity_state(entity_id)` - Entity-Status abrufen
  - `get_vehicle_data()` - Batterie% + km-Stand
  - `simulate_trip()` - Fahrt-Simulation (Start → Ende → Kosten)

### iOS App (Swift)
- **Services:**
  - `HomeAssistantService` - API-Client (async/await)
  - `KeychainService` - Sichere Token-Speicherung
  - `PersistenceController` - Core Data Stack
- **Models:**
  - `Trip` (Core Data) - Fahrt-Entity mit computed properties
  - `AppSettings` - App-Einstellungen (AppStorage + Keychain)
- **ViewModels:**
  - `TripsViewModel` - Fahrt-Tracking Logic (start/end)
  - `SettingsViewModel` - Verbindungstest & Validation
- **Views:**
  - `TripsListView` - Hauptscreen mit Fahrten-Liste
  - `ActiveTripView` - Laufende Fahrt (Fullscreen)
  - `SettingsView` - Home Assistant Konfiguration

### Home Assistant Entities (Enyaq)
- `sensor.enyaq_battery_level` - Batteriestand in %
- `sensor.enyaq_odometer` - Kilometerstand

### Datenmodell (Core Data)
- **Trip Entity:**
  - Attributes: id, startDate, endDate, startBatteryPercent, endBatteryPercent, startOdometer, endOdometer
  - Computed: distance, batteryUsed, kwhUsed(), cost(), averageConsumption
- **AppSettings:** Strompreis, Batteriekapazität, HA-Credentials (URL, Token, Entity-IDs)

---

## Critical Development Principles

### Git Merge Safety Protocol

**Problem:** Feature specifications and documentation can be lost during git merges, especially when files exist only in feature branches.

**Mandatory Post-Merge Checklist:**
1. **Immediately after any merge**: Run `git status` and verify no important files are missing
2. **Check for deleted files**: `git log -1 --stat` to see what was added/removed
3. **Verify DOCS/ directory**: Ensure all spec files, todo lists, and feature documentation are present
4. **If files are missing**: Check `git log --diff-filter=D` to find deleted files and restore them

**Prevention:**
- Always check `git diff --name-status HEAD@{1} HEAD` after merge
- Keep critical specs in DOCS/ committed on main branch, not just feature branches
- Use `git merge --no-commit` to review changes before finalizing merge

### Spec-First Implementation Rule

**CRITICAL:** Never implement features without complete written specification.

**If spec is missing:**
1. ❌ **DO NOT** speculate or build "what seems right"
2. ❌ **DO NOT** infer requirements from existing code alone
3. ✅ **STOP immediately** and ask user for complete spec
4. ✅ **Document spec** in DOCS/ before writing any code

**Why this matters:**
- User has specific vision that may not match "obvious" implementation
- Breaking changes to existing UX have serious consequences
- Wasted time building wrong feature that must be reverted

### Understanding Existing UI Behavior

**Before modifying ANY user interaction:**
1. Read the CURRENT code to understand what it does
2. Test the CURRENT behavior yourself (or ask user)
3. Document WHY the change is needed
4. Get explicit approval for breaking changes

### Clean Rollback Strategy

**When implementation is wrong:**
1. Don't try to "fix forward" - this compounds errors
2. Use `git reset --hard <commit>` to clean rollback point
3. Start fresh with correct specification
4. Document what went wrong

### Automated Testing Protocol

**MANDATORY:** Run tests before every commit that touches business logic.

**When to run tests:**
1. ✅ **Always** before committing changes to core logic/services
2. ✅ **Always** after fixing deprecated APIs or refactoring
3. ✅ **Optional** for pure UI changes (but recommended)

**If tests fail:**
- ❌ **DO NOT** commit broken code
- Fix the regression immediately
- Re-run tests until green

### Trace Complete Data Flow - Don't Analyze Fragments

**CRITICAL:** Always trace the COMPLETE "Entstehungsgeschichte" (origin story), not just isolated code fragments.

**5-Step Analysis Framework:**
1. WHERE is data created/loaded?
2. HOW is data transformed?
3. WHERE is data displayed?
4. WHERE is data used for calculations?
5. **Are steps 3 and 4 using THE SAME data?** (If NO → inconsistency!)

**Lesson:**
```
❌ DON'T: Look at isolated code fragments
✅ DO: Trace complete data flow from source to consumption
✅ DO: Map ALL usages before making changes
```

### Data Source Consistency

**CRITICAL:** Visualization and calculation MUST use the SAME data source.

**Lesson:** What you see = What gets counted

```
✅ DO: Use same data for visualization AND calculation
❌ DON'T: Query separately for display vs. calculation
```

### Analysis-First Principle (MUST FOLLOW!)

**Problem:** Multiple trial-and-error attempts instead of root cause analysis.

**Lesson:** Identify root cause with CERTAINTY before implementing fix. No speculative fixes!

Reference: Global CLAUDE.md "Analysis-First Prinzip"

### CRITICAL: Always Check for Existing Systems Before Building New Ones

**The Rule:**
```
❌ DON'T: See feature request → immediately start coding new system
✅ DO: Search for existing systems → understand pattern → extend/integrate → test
```

**Why this is CRITICAL:**
- Duplicate systems = double maintenance burden
- User expects integration with existing UI/Settings
- Wasted time building wrong architecture that must be deleted

**Checklist before building ANY new system:**
1. ✅ Grep for keywords related to the feature
2. ✅ Read existing architecture documentation
3. ✅ Check if existing modules have related code
4. ✅ Ask user: "I see [existing system X], should I extend that or build new?"
5. ✅ ONLY proceed after confirming approach

### CRITICAL: Never Use ✅ Checkmarks Without User Verification

**The Rule:**
```
❌ NEVER: Use ✅ or "Complete" for implementation status
✅ ALWAYS: Describe what was DONE, not what is "finished"
✅ ALWAYS: Only USER can declare something "complete" after testing
```

**What I CAN say:**
- "Implemented X in file Y"
- "Added X functionality"
- "Built successfully"
- "Unit tests passing"

**What I CANNOT say:**
- "✅ Complete"
- "✅ Feature X done"
- "✅ Working"
- Any green checkmarks implying completeness

**Why this matters:**
- False "Complete" status wastes user's time (they assume it works)
- Breaks trust (user sees feature "done" → tests → doesn't work)
- I can only verify: builds, compiles, unit tests pass
- I CANNOT verify: full integration, UI correctness, actual behavior
- Only USER can verify end-to-end functionality

### CRITICAL: Never Simplify Away the Feature Intent

**Problem:** When facing implementation challenges, suggesting "simplifying" the feature by removing its core value proposition.

**The Rule:**
```
❌ DON'T: Change feature goal to simplify implementation
❌ DON'T: Remove core value to avoid technical challenges
✅ DO: Research how successful apps solve the SAME problem
✅ DO: Ask user if feature goal can be adjusted (don't decide alone)
```

**Why this is CRITICAL:**
- Implementation complexity is MY problem, not the user's
- User wants the FEATURE, not "whatever is easiest to build"
- Removing core functionality = deleting the feature entirely

**The Right Approach:**
1. **Verify Feature Intent:** What is the core value?
2. **Research Best Practices:** How do successful apps solve this?
3. **Propose Solutions:** "Option A: X, Option B: Y" - let USER choose tradeoffs
4. **NEVER decide alone** to remove core functionality

### Debugging Protocol

**When stuck after multiple attempts:**

**Solution:** Build minimal reproducible test FIRST:
1. Create debug/test with simplest possible case
2. Test system works isolated from complex code
3. If debug works → problem is in app code, not system
4. Rewrite complex code based on working minimal example

**The Rule:**
```
❌ DON'T: Delete features when stuck - fix the actual problem
✅ DO: Create minimal test, identify root cause, fix systematically
✅ DO: Preserve existing features while fixing bugs
```

**Lesson:** Stick to Analysis-First principle. Never remove features without user approval, even under time pressure.

---

**For global collaboration rules and workflow, see `~/.claude/CLAUDE.md`**
