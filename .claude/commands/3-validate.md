# Spezifikation validieren

Starte den `spec-validator` Agenten aus `.agent-os/agents/spec-validator.md`.

**Spec:** $ARGUMENTS

---

## Wann nutzen?

| Situation | Beispiel |
|-----------|----------|
| Nach Spec-Erstellung | `/3-validate offline-mode` |
| Vor Feature-Start | `/3-validate` (alle Specs) |
| Bei TODO-Warnungen | `/3-validate [name]` |

---

## Injizierte Standards

- `.agent-os/standards/global/documentation-rules.md`

---

## Was wird geprueft?

### Pflicht-Checks

| Check | Beschreibung |
|-------|--------------|
| Frontmatter | Status, Version, Datum vorhanden? |
| Sektionen | Alle Pflicht-Sektionen ausgefuellt? |
| Platzhalter | Keine TODOs, TBDs, FIXME? |
| Konsistenz | Dateiname passt zu Inhalt? |
| Approval | Checkbox-Status korrekt? |

### Fehler-Typen

| Typ | Bedeutung |
|-----|-----------|
| **Error** | Blockiert Approval - MUSS behoben werden |
| **Warning** | Qualitaetsproblem - SOLLTE behoben werden |
| **Suggestion** | Verbesserung - KANN behoben werden |

---

## Ausgabe

```markdown
## Spec Validation Report: [name].md

### Ergebnis: PASS / FAIL / WARNINGS

### Errors
- ...

### Warnings
- ...

### Suggestions
- ...
```

---

## Batch-Modus

Ohne Argument werden ALLE Specs validiert:
```
/3-validate
```

Prueft: `openspec/specs/**/*.md` (ausser _template.md)

---

## Nach Validierung

| Ergebnis | Naechster Schritt |
|----------|-------------------|
| PASS | Spec kann approved werden → Implementierung |
| FAIL | Errors beheben mit `/2-spec`, erneut validieren |
| WARNINGS | Optional beheben, dann approven |

**Workflow:** `/1-analyse` → `/2-spec` → `/3-validate` → Implementierung
