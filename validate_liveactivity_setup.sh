#!/bin/bash
#
# LiveActivity Setup Validation Script
# Prüft alle kritischen Konfigurationen für LiveActivity
#

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo "🔍 Validiere LiveActivity Setup..."
echo ""

ERRORS=0
WARNINGS=0

# 1. Prüfe Widget Extension Deployment Target
echo "📱 Prüfe Widget Extension Deployment Target..."
WIDGET_DEPLOYMENT=$(grep -A 5 "FahrtenbuchWidgetExtension.*Debug" ios/HomeAssistentFahrtenbuch.xcodeproj/project.pbxproj | grep "IPHONEOS_DEPLOYMENT_TARGET" | head -1 | sed 's/.*= \(.*\);/\1/')

if [ "$WIDGET_DEPLOYMENT" = "16.1" ] || [ "$WIDGET_DEPLOYMENT" = "16.0" ]; then
    echo -e "${GREEN}✅ Widget Extension Deployment Target: $WIDGET_DEPLOYMENT (korrekt)${NC}"
else
    echo -e "${RED}❌ Widget Extension Deployment Target: $WIDGET_DEPLOYMENT (sollte 16.1 sein)${NC}"
    ERRORS=$((ERRORS + 1))
fi

# 2. Prüfe NSSupportsLiveActivities in Haupt-App Info.plist
echo ""
echo "📄 Prüfe NSSupportsLiveActivities in Haupt-App..."
if grep -q "NSSupportsLiveActivities" ios/HomeAssistentFahrtenbuch/Info.plist; then
    echo -e "${GREEN}✅ NSSupportsLiveActivities in Haupt-App Info.plist vorhanden${NC}"
else
    echo -e "${RED}❌ NSSupportsLiveActivities fehlt in Haupt-App Info.plist${NC}"
    ERRORS=$((ERRORS + 1))
fi

# 3. Prüfe NSSupportsLiveActivities in Widget Extension Info.plist
echo ""
echo "📄 Prüfe NSSupportsLiveActivities in Widget Extension..."
if grep -q "NSSupportsLiveActivities" ios/FahrtenbuchWidget/Info.plist; then
    echo -e "${GREEN}✅ NSSupportsLiveActivities in Widget Extension Info.plist vorhanden${NC}"
else
    echo -e "${RED}❌ NSSupportsLiveActivities fehlt in Widget Extension Info.plist${NC}"
    ERRORS=$((ERRORS + 1))
fi

# 4. Prüfe ob kritische Dateien existieren
echo ""
echo "📁 Prüfe kritische Dateien..."

FILES=(
    "ios/HomeAssistentFahrtenbuch/Services/LiveActivityManager.swift"
    "ios/HomeAssistentFahrtenbuch/Services/WidgetDataService.swift"
    "ios/FahrtenbuchWidget/Models/TripActivityAttributes.swift"
    "ios/FahrtenbuchWidget/Views/TripWidgetView.swift"
    "ios/FahrtenbuchWidget/Providers/TripWidgetProvider.swift"
    "ios/FahrtenbuchWidget/FahrtenbuchWidget.swift"
)

for file in "${FILES[@]}"; do
    if [ -f "$file" ]; then
        echo -e "${GREEN}✅ $file${NC}"
    else
        echo -e "${RED}❌ $file fehlt${NC}"
        ERRORS=$((ERRORS + 1))
    fi
done

# 5. Prüfe @available Annotationen
echo ""
echo "🔧 Prüfe @available Annotationen..."

# LiveActivityManager sollte iOS 16.1+ sein
if grep -q "@available(iOS 16.1, \*)" ios/HomeAssistentFahrtenbuch/Services/LiveActivityManager.swift; then
    echo -e "${GREEN}✅ LiveActivityManager hat korrekte @available(iOS 16.1)${NC}"
else
    echo -e "${YELLOW}⚠️  LiveActivityManager @available Annotation prüfen${NC}"
    WARNINGS=$((WARNINGS + 1))
fi

# TripLiveActivity sollte iOS 16.1+ sein
if grep -q "@available(iOS 16.1, \*)" ios/FahrtenbuchWidget/FahrtenbuchWidget.swift | grep -q "TripLiveActivity"; then
    echo -e "${GREEN}✅ TripLiveActivity hat korrekte @available(iOS 16.1)${NC}"
else
    echo -e "${YELLOW}⚠️  TripLiveActivity @available Annotation prüfen${NC}"
    WARNINGS=$((WARNINGS + 1))
fi

# 6. Prüfe ob alte generierte Dateien gelöscht wurden
echo ""
echo "🗑️  Prüfe auf alte generierte Dateien..."

OLD_FILES=(
    "ios/FahrtenbuchWidget/AppIntent.swift"
    "ios/FahrtenbuchWidget/FahrtenbuchWidgetControl.swift"
    "ios/FahrtenbuchWidget/FahrtenbuchWidgetLiveActivity.swift"
)

for file in "${OLD_FILES[@]}"; do
    if [ -f "$file" ]; then
        echo -e "${YELLOW}⚠️  Alte Datei sollte gelöscht werden: $file${NC}"
        WARNINGS=$((WARNINGS + 1))
    fi
done

# 7. Build Test
echo ""
echo "🔨 Führe Build-Test durch..."
cd ios
if xcodebuild -scheme HomeAssistentFahrtenbuch -destination 'generic/platform=iOS' clean build > /dev/null 2>&1; then
    echo -e "${GREEN}✅ Build erfolgreich${NC}"
else
    echo -e "${RED}❌ Build fehlgeschlagen${NC}"
    ERRORS=$((ERRORS + 1))
fi
cd ..

# Zusammenfassung
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📊 ZUSAMMENFASSUNG"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

if [ $ERRORS -eq 0 ]; then
    echo -e "${GREEN}✅ Alle kritischen Tests bestanden${NC}"
else
    echo -e "${RED}❌ $ERRORS Fehler gefunden${NC}"
fi

if [ $WARNINGS -gt 0 ]; then
    echo -e "${YELLOW}⚠️  $WARNINGS Warnungen${NC}"
fi

echo ""

if [ $ERRORS -eq 0 ]; then
    echo "✅ LiveActivity Setup ist korrekt konfiguriert!"
    echo ""
    echo "🧪 Nächster Schritt: Manuelle Tests"
    echo "   1. App auf Device installieren"
    echo "   2. Fahrt starten"
    echo "   3. Lock Screen prüfen → LiveActivity sollte erscheinen"
    echo "   4. Console Logs prüfen für '✅ LiveActivity ERFOLGREICH gestartet'"
    exit 0
else
    echo "❌ Bitte behebe die Fehler und führe das Script erneut aus."
    exit 1
fi
