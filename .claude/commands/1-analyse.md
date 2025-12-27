# Analyse-Phase starten

Fuehre eine gruendliche Analyse durch BEVOR Code geschrieben wird.

**Anfrage:** $ARGUMENTS

---

## Wann nutzen?

| Situation | Beispiel |
|-----------|----------|
| Bug-Analyse | `/1-analyse Warum wird der Batteriestand nicht aktualisiert?` |
| Feature-Vorbereitung | `/1-analyse Wie funktioniert aktuell die Trip-Berechnung?` |
| Codebase verstehen | `/1-analyse Welche Services gibt es und wie haengen sie zusammen?` |

---

## Injizierte Standards

- `.agent-os/standards/global/analysis-first.md`
- `.agent-os/standards/global/documentation-rules.md`

---

## Pflicht-Vorgehen

### 1. Anforderungen klaeren

- Was genau soll analysiert werden?
- Warum ist diese Analyse noetig?
- Welches Ergebnis wird erwartet?

### 2. Codebase durchsuchen

```bash
# Relevante Dateien finden
# Grep fuer Keywords
# Glob fuer Patterns
```

**Systematisch vorgehen:**
- Alle relevanten Dateien identifizieren
- Datenfluss nachvollziehen
- Abhaengigkeiten verstehen

### 3. Impact-Mapping

Dokumentiere:
- Welche Dateien sind betroffen?
- Welche Systeme haengen zusammen?
- Wo koennten Seiteneffekte entstehen?

### 4. Bestehende Specs pruefen

- `openspec/specs/` durchsuchen
- Gibt es bereits Dokumentation?
- Was muss aktualisiert werden?

---

## Pflicht-Output

Fasse die Analyse zusammen:

1. **Was wurde untersucht?** (Scope)
2. **Was wurde gefunden?** (Erkenntnisse)
3. **Betroffene Dateien** (Liste mit Pfaden)
4. **Abhaengigkeiten** (Welche Systeme haengen zusammen?)
5. **Naechster Schritt** (Empfehlung: `/bug`, `/feature`, oder weitere Analyse)

---

## Naechste Schritte

Nach Analyse-Abschluss:

| Ergebnis | Naechster Command |
|----------|-------------------|
| Bug gefunden | `/bug [Beschreibung]` |
| Feature noetig | `/feature [Name]` |
| Spec fehlt | `/2-spec [Entity]` |
| Alles klar | Direkt implementieren |

---

**Workflow:** `/1-analyse` → `/2-spec` → `/3-validate` → Implementierung

**KEINE Implementierung ohne abgeschlossene Analyse!**
