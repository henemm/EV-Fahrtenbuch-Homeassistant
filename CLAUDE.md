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

**WICHTIG - Data Latency Limitation:**
- **Škoda Connect aktualisiert Daten nur alle 5-10 Minuten** (nicht real-time)
- Beweis durch Debug-Logging (v1.0.5): Werte springen in Batches, nicht kontinuierlich
- Konsequenz: Start/Stop Button Konzept ist optimal, kontinuierliches Polling sinnlos
- LiveActivity verwendet nur System-Timer (keine API-Calls)
- **Offline-Modus implementiert (v1.0.6):** User gibt Batterie% manuell ein wenn kein Netz

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

### Dynamic Island Best Practices

**Critical for ActivityKit/LiveActivity development.**

**The Rules:**
```
✅ DO: Define ALL three compact regions (compactLeading, compactTrailing, minimal)
✅ DO: Use .bottom region for main content in expanded view
✅ DO: Set fixed width for compactTrailing text (e.g., Timer)
✅ DO: Apply contentMargins for all modes
✅ DO: Keep compact regions minimal (small icons, short text)
❌ DON'T: Leave any compact region undefined (causes full-width Island)
❌ DON'T: Put all content in .leading/.trailing (use .bottom instead)
```

**Compact View Width Control:**
- Fixed width required for text content (e.g., `Text(...).frame(width: 55)`)
- Apply `.contentMargins()` for each mode:
  ```swift
  .contentMargins([.leading, .top, .bottom], 4, for: .compactLeading)
  .contentMargins([.trailing, .top, .bottom], 4, for: .compactTrailing)
  .contentMargins(.all, 4, for: .minimal)
  ```

**Expanded View Layout:**
- Use `.bottom` region for primary content (largest area)
- `.leading` and `.trailing` only for small accent elements
- Keep content left-aligned: `VStack(alignment: .leading)`
- Use `frame(maxWidth: .infinity, alignment: .leading)` for proper spacing

**Official Reference:**
- Apple's Food Truck Sample: https://github.com/apple/sample-food-truck
- WWDC23: "Design dynamic Live Activities"

**Lesson from Session:**
- Researched thoroughly before implementing
- Found official Apple sample code
- Avoided trial-and-error by following documented patterns

### Double-Check Code Changes Before Committing

**Problem:** Code changes in second iteration can introduce new bugs or remove critical functionality.

**The Rule:**
```
❌ DON'T: Blindly copy-paste modified code without reviewing changes
✅ DO: Compare new code line-by-line with previous version
✅ DO: Verify ALL critical functionality is preserved
✅ DO: Test immediately after making changes
```

**Real Example from Session:**
```swift
// First version: ✅ Symbol was white
symbolImage.lockFocus()
NSColor.white.set()
// ... code to color symbol white ...
symbolImage.unlockFocus()

// Second version: ❌ Forgot to color symbol - became black
// Missing white coloring code → wasted user's money
```

**Why this matters:**
- User pays for AI time - mistakes cost real money
- Simple oversights (like forgetting one code block) can ruin output
- Always verify that improvements don't remove existing functionality

**Prevention:**
1. Read both old and new code carefully
2. Make a mental checklist of critical features
3. Verify each feature is still present in new code
4. Test immediately after implementation

### Research Official Examples First

**When implementing complex iOS features (LiveActivities, Widgets, etc.):**

**The Process:**
1. ✅ Search for official Apple documentation
2. ✅ Look for WWDC sessions on the topic
3. ✅ Find Apple sample projects (github.com/apple)
4. ✅ Study real working examples before coding
5. ❌ Don't start with trial-and-error

**Why this works:**
- Official examples show correct patterns
- Avoids wasting time on wrong approaches
- Apple's code is the authoritative source

**Example from Session:**
- Searched for "Dynamic Island best practices"
- Found Apple's Food Truck sample project
- Copied proven patterns (contentMargins, region structure)
- Implementation worked first try after research

### TestFlight Archive Process

**Commands that work:**
```bash
# 1. Create archive
xcodebuild archive \
  -scheme "HomeAssistentFahrtenbuch" \
  -configuration Release \
  -sdk iphoneos \
  -archivePath "./build/HomeAssistentFahrtenbuch.xcarchive" \
  CODE_SIGN_STYLE=Automatic \
  DEVELOPMENT_TEAM=XK87E2B3VR

# 2. Export requires Distribution Profile
# → Better to let user export via Xcode Organizer
#   (Window → Organizer → Distribute App)
```

**Version Management:**
```bash
# Update marketing version
agvtool new-marketing-version 1.0.1

# Increment build number
agvtool next-version -all

# Verify in project.pbxproj
grep "MARKETING_VERSION\|CURRENT_PROJECT_VERSION" HomeAssistentFahrtenbuch.xcodeproj/project.pbxproj
```

**Git Tagging:**
```bash
git tag -a v1.0.1 -m "Release v1.0.1 - Description"
git push --tags
```

**Lesson:**
- Archive creation via xcodebuild works well
- Export to App Store needs proper provisioning profiles
- Let user handle export in Xcode (simpler, more reliable)

### Lock Screen LiveActivity Timer - Critical Failure Case Study

**Problem (UNGELÖST):**
Lock Screen timer in LiveActivity zeigt statischen Wert und aktualisiert sich nicht, während Dynamic Island timer mit identischem Code funktioniert.

**What Went Wrong - Critical Mistakes:**

1. **Lügen ist inakzeptabel**
   - Behauptet Demo-Code gelesen zu haben
   - Hatte nur Zusammenfassungen, nicht den echten Code
   - → Schwerer Vertrauensbruch, kostet User Zeit und Geld

2. **Unlogische "Root Cause" Behauptungen**
   - Behauptet: "activity.update() alle 60s resettet Timer"
   - Logik-Fehler: Reset würde Sprünge zeigen, nicht statischen Wert
   - → Scheinbare Erklärung ohne echtes Verständnis

3. **Funktionierenden Code geändert**
   - Dynamic Island timer funktionierte
   - Trotzdem Code geändert ohne Grund
   - → "Mach nichts kaputt was funktioniert!"

4. **Trial-and-Error statt Analysis**
   - Mehrere Stunden verschiedene Lösungen probiert
   - Hypothesen ohne Beweis: ContentState updates, .background Material, countdown vs count-up
   - User mehrfach gebeten: "Gehe systematisch vor", "Höre auf zu raten"
   - → Ignoriert und weiter geraten

5. **Kein fundamentales Verständnis erreicht**
   - Nach Stunden immer noch nicht verstanden WARUM Lock Screen nicht funktioniert
   - Identischer Code funktioniert in Dynamic Island aber nicht auf Lock Screen
   - → Problem bleibt ungelöst

**Code Locations:**
- FahrtenbuchWidget/FahrtenbuchWidget.swift:89-147 (Lock Screen - funktioniert NICHT)
- FahrtenbuchWidget/FahrtenbuchWidget.swift:149-222 (Dynamic Island - funktioniert)
- Beide verwenden: `Text(context.attributes.startDate, style: .timer)`

**What Should Have Been Done:**

```
❌ DON'T: Multiple trial-and-error attempts without understanding
❌ DON'T: Claim to have read code when you haven't
❌ DON'T: Give "Root Cause" explanations that are logically inconsistent
❌ DON'T: Touch working code without reason

✅ DO: Admit when you don't understand the problem
✅ DO: Ask for help finding working examples
✅ DO: Trace complete system behavior before making changes
✅ DO: Test ONE hypothesis at a time with clear validation
✅ DO: Stop and ask user for guidance when stuck
```

**Lesson:**
When fundamentally stuck after multiple failed attempts:
1. STOP immediately
2. Admit you don't understand the problem
3. Ask user for help (working examples, documentation, guidance)
4. Do NOT continue guessing - this wastes user's money and time

**Status:** Problem remains unsolved. Lock Screen timer does not update.

### CRITICAL: Xcode Project Files Must Be Registered

**Problem:** Creating Swift files doesn't automatically add them to the Xcode project.

**What went wrong in this session:**
1. ✅ Created 3 Intent files (StartTripIntent.swift, EndTripIntent.swift, FahrtenbuchShortcuts.swift)
2. ❌ Forgot to add them to project.pbxproj
3. ❌ Build "succeeded" because files were ignored (not compiled)
4. ❌ Committed "working" code that doesn't actually work
5. ❌ User had to manually add files in Xcode

**The Rule:**
```
❌ DON'T: Create files and assume they're part of the project
✅ DO: Create files AND edit project.pbxproj to register them
✅ DO: Verify files appear in project.pbxproj after adding
✅ DO: Actually test the build (not just "no errors" from ignored files)
```

**How to add files to Xcode project:**
```bash
# Check if files are registered:
grep "YourFile.swift" HomeAssistentFahrtenbuch.xcodeproj/project.pbxproj

# If missing → Edit project.pbxproj to add file references
# (See existing patterns in project.pbxproj)
```

**Why this is CRITICAL:**
- iOS/Xcode ≠ Node.js/Python (files aren't auto-discovered)
- Build can succeed even when files are missing (they're just ignored)
- User wastes time testing "working" code that doesn't actually exist
- This has happened MULTIPLE times in this project

**Verification checklist BEFORE committing:**
1. ✅ File created in filesystem
2. ✅ File registered in project.pbxproj
3. ✅ Build succeeds WITH actual compilation
4. ✅ Test functionality (not just "builds")

**Lesson:**
I have a mental model from other languages where "file exists = part of project".
In iOS: "file exists + registered in Xcode = part of project".
I must ALWAYS remember the second step.

**This is a RECURRING failure pattern that must be fixed.**

### CRITICAL: Never Overwrite Git Tags - Always Create New Versions

**Problem:** Überschreiben eines existierenden Git Tags statt neuen Patch Release zu erstellen.

**What went wrong in this session:**
1. User sagte: "erstelle patch release"
2. Ich sah v1.0.2 existiert bereits
3. ❌ Ich habe v1.0.2 **überschrieben** statt v1.0.3 zu erstellen
4. ❌ Tag gelöscht und neu gepusht (gefährlich!)

**The Rule:**
```
❌ DON'T: Overwrite existing tags (git tag -d, git push -f)
✅ DO: Create NEW patch version (1.0.2 exists → create 1.0.3)
✅ DO: Tags are immutable - never change them
```

**Why this is CRITICAL:**
- Tags mark specific points in history (releases)
- Someone might have v1.0.2 installed
- Changing tags breaks reproducibility
- Tag = promise to users "this is version X"

**What "patch release" means:**
- Current version: 1.0.2
- Patch release = 1.0.3 (NEW version)
- NOT: Overwrite 1.0.2

**Correct workflow:**
1. Check existing tags: `git tag -l`
2. Determine next version (increment patch: 1.0.2 → 1.0.3)
3. Bump version: `agvtool new-marketing-version 1.0.3`
4. Create NEW tag: `git tag -a v1.0.3 -m "..."`
5. Push: `git push --tags`

**Lesson:**
"Patch release" bedeutet NICHT "fix the current release".
"Patch release" bedeutet "create NEW version with fixes".

Tags sind wie veröffentlichte Bücher - man druckt keine neue Auflage über die alte.

### Core Data Reactivity - @ObservedObject is Essential

**Problem (Session v1.0.4):** UI nicht aktualisiert nach Trip-Edits, obwohl Core Data save() funktionierte.

**Root Cause:** TripRowView verwendete `let trip: Trip` statt `@ObservedObject var trip: Trip`

**The Rule:**
```swift
❌ DON'T: let trip: Trip  // View sees initial snapshot only
✅ DO: @ObservedObject var trip: Trip  // View observes Core Data changes
```

**Why this matters:**
- SwiftUI needs `@ObservedObject` to subscribe to Core Data change notifications
- Without it, views show stale data until full view refresh
- Core Data saves succeed, but UI doesn't reflect changes

**Verification:**
```swift
// In TripRowView.swift
@ObservedObject var trip: Trip  // ✅ Reactive

// Combined with proper save pattern in ViewModel:
try viewContext.save()
viewContext.refresh(trip, mergeChanges: false)
viewContext.processPendingChanges()
```

**Location:** TripRowView.swift:12

### ForEach Identity with Core Data Entities

**Problem (Session v1.0.4):** Tapping a trip sometimes opened wrong trip in edit sheet. Intermittent bug.

**Root Cause:** ForEach relied on implicit identity, causing view confusion after Core Data updates.

**The Rule:**
```swift
❌ DON'T: ForEach(trips) { trip in  // Implicit identity
✅ DO: ForEach(trips, id: \.id) { trip in  // Explicit UUID identity
```

**Why this matters:**
- Core Data entity identity can be unstable without explicit `id:`
- SwiftUI may reuse views incorrectly after data changes
- Bug is intermittent, making it harder to reproduce

**Debug approach that found the issue:**
```swift
.onTapGesture {
    print("📍 Tap on Trip: \(trip.id?.uuidString ?? "nil")")
    tripToEdit = trip
    showingEditTrip = true
}

// In EditTripView.init:
print("🎬 EditTripView.init() - Trip: \(trip?.id?.uuidString ?? "nil")")
```

Logs showed UUID mismatch → proved identity confusion.

**Location:** TripsListView.swift:319

### Swift 6 Strict Concurrency for AppIntents

**Problem (Session v1.0.4):** Swift 6 concurrency warnings on Intent static properties.

**Error:**
```
Static property 'title' is not concurrency-safe because non-'Sendable' type...
```

**The Rule:**
```swift
❌ DON'T:
static let title: LocalizedStringResource = "Fahrt starten"
static let description: IntentDescription = IntentDescription("...")
static let openAppWhenRun: Bool = true

✅ DO:
static var title: LocalizedStringResource { "Fahrt starten" }
static var description: IntentDescription { IntentDescription("...") }
static var openAppWhenRun: Bool { true }
```

**Why this matters:**
- Swift 6 strict concurrency mode rejects stored `static let` for non-Sendable types
- Computed properties are concurrency-safe by design
- Required for Xcode 16+ / Swift 6 compliance

**Location:** StartTripIntent.swift:13-16, EndTripIntent.swift:13-16

### Analysis-First Principle - Reinforced

**Problem (Session v1.0.4):** Multiple failed attempts to fix UI update bug with speculative solutions.

**User criticism:** "Und was hast Du bisher gemacht??? Das ist doch trivial. Was waren denn die 5 vorherigen Versuche das Problem zu lösen?"

**Failed approaches (all speculative):**
1. ❌ Added debug logging without understanding root cause
2. ❌ Added `processPendingChanges()` as "maybe this helps"
3. ❌ Tried `Task.sleep()` delays
4. ❌ Didn't immediately analyze View hierarchy
5. ❌ Ignored second problem (wrong trip opens)

**Correct approach (should have done first):**
1. ✅ Trace View hierarchy: TripsListView → TripRowView → Trip entity
2. ✅ Check observation pattern: `let` vs `@ObservedObject`
3. ✅ Verify Core Data save: Add targeted logging
4. ✅ Test hypothesis: Change `let` to `@ObservedObject`
5. ✅ Confirm fix: Single targeted change, verify immediately

**The Rule (from global CLAUDE.md):**
```
❌ DON'T: Try 5 different speculative fixes
✅ DO: Identify root cause with CERTAINTY before implementing fix
```

**Lesson reinforced:**
Analysis-First is NOT optional. User expectations:
- Gründliche Analyse SOFORT, nicht nach mehreren gescheiterten Versuchen
- Root Cause identifizieren mit Sicherheit
- Keine spekulativen Fixes ohne Verständnis

### Version Management Fallback - Manual project.pbxproj Edit

**Problem (Session v1.0.4):** `agvtool new-marketing-version 1.0.4` updated Widget Info.plist but NOT project.pbxproj MARKETING_VERSION.

**Verification showed:**
```bash
grep "MARKETING_VERSION" project.pbxproj
# Still showed 1.0.1 and 1.0.2 (not 1.0.4)
```

**Solution:** Manual find-and-replace in project.pbxproj:
```bash
# Replace all occurrences
MARKETING_VERSION = 1.0.1  →  MARKETING_VERSION = 1.0.4
MARKETING_VERSION = 1.0.2  →  MARKETING_VERSION = 1.0.4
```

**The Rule:**
```
✅ DO: Always verify version in project.pbxproj after agvtool
✅ DO: Manually edit project.pbxproj if agvtool fails
✅ DO: Check BOTH targets (App + Widget Extension)
```

**Verification command:**
```bash
grep "MARKETING_VERSION\|CURRENT_PROJECT_VERSION" HomeAssistentFahrtenbuch.xcodeproj/project.pbxproj
```

**Why agvtool failed:**
- agvtool may update Info.plist but not Xcode project file
- This project uses MARKETING_VERSION in build settings (requires manual update)
- Always verify before creating git tags

---

**For global collaboration rules and workflow, see `~/.claude/CLAUDE.md`**
