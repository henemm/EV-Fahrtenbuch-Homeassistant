# Spezifikation schreiben

Starte den `spec-writer` Agenten aus `.agent-os/agents/spec-writer.md`.

**Entity:** $ARGUMENTS

---

## Wann nutzen?

| Situation | Beispiel |
|-----------|----------|
| Neues Feature dokumentieren | `/2-spec Offline-Modus` |
| Integration spezifizieren | `/2-spec Home-Assistant-API` |
| Komponente beschreiben | `/2-spec TripCard-View` |

---

## Injizierte Standards

- `.agent-os/standards/global/analysis-first.md`
- `.agent-os/standards/global/documentation-rules.md`

---

## Workflow

1. **Template laden:** `openspec/specs/_template.md`
2. **Bestehende Specs pruefen:** Keine Duplikate!
3. **Codebase analysieren:** Relevante Dateien finden
4. **Spec schreiben:** Alle Pflichtfelder ausfuellen
5. **Validieren:** Keine TODOs, keine Platzhalter

---

## Spec-Kategorien

| Kategorie | Pfad |
|-----------|------|
| Features | `openspec/specs/features/[name].md` |
| Integrations | `openspec/specs/integrations/[name].md` |
| Components | `openspec/specs/components/[name].md` |

---

## Pflicht-Output

Spec-Datei mit:
- Vollstaendigem Frontmatter (Status, Version, Datum)
- Problem-Beschreibung mit User Story
- Loesung mit betroffenen Dateien
- Implementierungs-Details
- Testing-Anweisungen
- Approval-Checkbox (unchecked)
- Changelog

---

## Nach Spec-Erstellung

Naechster Schritt: `/3-validate [name]` um Vollstaendigkeit zu pruefen.

**Workflow:** `/1-analyse` → `/2-spec` → `/3-validate` → Implementierung

**KEINE Implementierung ohne approved Spec!**
