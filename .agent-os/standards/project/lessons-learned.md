# Lessons Learned - Fahrtenbuch Project

Projektspezifische Erkenntnisse aus vergangenen Sessions.

---

## Git Merge Safety Protocol

**Problem:** Feature specifications and documentation can be lost during git merges.

**Mandatory Post-Merge Checklist:**
1. Run `git status` and verify no important files are missing
2. Check for deleted files: `git log -1 --stat`
3. Verify DOCS/ directory contains all specs

---

## Xcode Project Files Must Be Registered

**Problem:** Creating Swift files doesn't automatically add them to the Xcode project.

**The Rule:**
```
❌ DON'T: Create files and assume they're part of the project
✅ DO: Create files AND edit project.pbxproj to register them
✅ DO: Verify files appear in project.pbxproj after adding
```

**Verification:**
```bash
grep "YourFile.swift" HomeAssistentFahrtenbuch.xcodeproj/project.pbxproj
```

---

## Never Overwrite Git Tags

**Problem:** Überschreiben eines existierenden Git Tags statt neuen Patch Release zu erstellen.

**The Rule:**
```
❌ DON'T: Overwrite existing tags (git tag -d, git push -f)
✅ DO: Create NEW patch version (1.0.2 exists → create 1.0.3)
```

---

## Core Data Reactivity

**Problem:** UI nicht aktualisiert nach Trip-Edits.

**Root Cause:** `let trip: Trip` statt `@ObservedObject var trip: Trip`

**The Rule:**
```swift
❌ DON'T: let trip: Trip  // View sees initial snapshot only
✅ DO: @ObservedObject var trip: Trip  // View observes Core Data changes
```

---

## ForEach Identity with Core Data

**Problem:** Tapping a trip sometimes opened wrong trip.

**The Rule:**
```swift
❌ DON'T: ForEach(trips) { trip in  // Implicit identity
✅ DO: ForEach(trips, id: \.id) { trip in  // Explicit UUID identity
```

---

## Swift 6 Concurrency for AppIntents

**Error:** `Static property 'title' is not concurrency-safe...`

**The Rule:**
```swift
❌ DON'T: static let title: LocalizedStringResource = "..."
✅ DO: static var title: LocalizedStringResource { "..." }
```

---

## Version Management Fallback

**Problem:** `agvtool new-marketing-version` may not update project.pbxproj.

**The Rule:**
```
✅ DO: Always verify version in project.pbxproj after agvtool
✅ DO: Manually edit project.pbxproj if agvtool fails
```

---

## Dynamic Island Best Practices

**The Rules:**
```
✅ DO: Define ALL three compact regions (compactLeading, compactTrailing, minimal)
✅ DO: Use .bottom region for main content in expanded view
✅ DO: Set fixed width for compactTrailing text
❌ DON'T: Leave any compact region undefined
```

---

## Lock Screen LiveActivity Timer (UNGELÖST)

**Problem:** Lock Screen timer zeigt statischen Wert, Dynamic Island funktioniert.

**Status:** Problem bleibt ungelöst. Identischer Code funktioniert in Dynamic Island aber nicht auf Lock Screen.

**Code Locations:**
- FahrtenbuchWidget/FahrtenbuchWidget.swift:89-147 (Lock Screen - broken)
- FahrtenbuchWidget/FahrtenbuchWidget.swift:149-222 (Dynamic Island - works)

---

## Data Latency Limitation

**WICHTIG - Škoda Connect:**
- Daten werden nur alle 5-10 Minuten aktualisiert (nicht real-time)
- Start/Stop Button Konzept ist optimal
- LiveActivity verwendet nur System-Timer (keine API-Calls)
- Offline-Modus für manuelle Batterie%-Eingabe implementiert
