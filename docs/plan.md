# Cleanpasta - decyzje i plan

Stan: 10.11.2026 (wersja 1.2.0). Krótko: co obowiązuje dziś i co jest dalej. Historia zmian jest w [CHANGELOG.md](../CHANGELOG.md) i w historii gita (pełny plan faz F1-F10 do 07.11.2026: `git show e9348e7:docs/plan.md`).

## Produkt

Cleanpasta wkleja sformatowany tekst bez tła, kolorów i fontów źródła. Trzy części, jedna logika czyszczenia:

- **apka macOS** w pasku menu: Paste Clean (skrót), Repair Clipboard, ustawienia, aktualizacje,
- **CLI `cleanpasta`** w paczce apki, dla Terminala, skryptów, launcherów i agentów AI,
- **skill AI `cleanpasta`** (`skills/cleanpasta`), który oddaje drafty przez `cleanpasta --copy`.

Podpis: Eryk Sadowski · eryksadowski.com. Bez nazwy linii produktów i bez integracji z Raycastem (usunięte w 1.2.0; launchery i skrypty używają CLI).

## Decyzje

| # | Decyzja | Dlaczego |
|---|---|---|
| D1 | Jedno publiczne repo `iameryksadowski/cleanpasta-app` (MIT), `main` = wydania, praca na `development` | pliki aktualizacji muszą być do pobrania bez logowania |
| D2 | Natywnie: Swift, AppKit + SwiftUI, Swift Package Manager, Command Line Tools (bez projektu Xcode), minimum macOS 14 | lekka apka; JavaScriptCore z macOS 14 obsługuje wszystkie wyrażenia konwertera |
| D3 | Jedno źródło czyszczenia: `converter/src/convert.ts`, bundlowane do `Resources/convert.js`; macOS uruchamia je w JavaScriptCore, Windows w QuickJS | jedna logika i jedne testy dla apki, CLI i Windows |
| D4 | Schowek natywnie (NSPasteboard: HTML, web archive, RTF, tekst), Cmd+V przez CGEvent po puszczeniu modyfikatorów | Mail nie zamienia tego na "Wklej i dopasuj styl" |
| D5 | Skróty globalne przez Carbon `RegisterEventHotKey`; każdy skrót można usunąć | bez Dostępności i bez zależności |
| D6 | Pasek menu, ikona w Docku tylko przy otwartym oknie; start przy logowaniu przez `SMAppService.mainApp` | nie zaśmieca Docka |
| D7 | Aktualizacje: Sparkle 2 + EdDSA, `appcast.xml` jako asset GitHub Release, changelog w oknie, instalacja po zgodzie | bez płatnego konta Apple |
| D8 | Podpis stałym samopodpisanym certyfikatem "Eryk Sadowski" (tworzy i trzyma Eryk) | Dostępność przetrwa aktualizacje |
| D9 | Identyfikator `com.eryksadowski.cleanpasta` (od 1.2.0); przy starcie apka raz kopiuje ustawienia ze starej domeny `com.eryksadowski.estools.cleanpaste` (`LegacyDefaults`, komentarz "legacy migration") | marka bez nazwy linii, ustawienia Eryka zostają |
| D10 | Migracja z 1.0.x zostaje: zmiana nazwy `Clean Paste.app` -> `Cleanpasta.app` i linku CLI `cleanpaste` -> `cleanpasta` (komentarze "legacy migration") | stare instalacje dalej się aktualizują |
| D11 | CLI instalowane z ustawień jako link w `/opt/homebrew/bin` albo `/usr/local/bin`, gdy są zapisywalne, inaczej w `~/.local/bin`, bez hasła administratora | Terminal, skrypty i AI bez klikania |
| D12 | Listy: numerowane punkty wklejamy jako zwykłe akapity "1. ..."; listą są tylko punkty z kropkami pod linią z dwukropkiem | numeracja w mailach się nie rozjeżdża |
| D13 | Skill: źródło w `skills/cleanpasta` w tym repo, ta sama treść w `eryksadowski-skills` (plugin `eryksadowski`); zmiana w jednym miejscu = kopia w drugim w tym samym dniu | standard aplikacji Eryka; repo apki jest publiczne, repo skilli prywatne |
| D14 | Windows: podgląd w `windows/` (Tauri 2, Rust, QuickJS), CI buduje niepodpisany instalator; bez wydania | szczegóły i bramki: [windows.md](windows.md) |
| D15 | Interfejs, README, CHANGELOG i komentarze po angielsku; instrukcja instalacji po polsku ([instalacja.md](instalacja.md), PDF w DMG z `docs/guide/instalacja.html`) | zasada marki |

## Wydanie

1. PR `development` -> `main`, merge.
2. Na `main`: data wersji w `CHANGELOG.md`, `scripts/release.sh` (build, podpis, zip, DMG, `appcast.xml`, `install.sh`, GitHub Release `vX.Y.Z` z notatkami z CHANGELOG).
3. Wersja jest w jednym miejscu dla apki (`CHANGELOG.md`, czyta ją `build-app.sh`), a w CLI, testach, skillu i plikach Windows (`Cargo.toml`, `Cargo.lock`, `tauri.conf.json`, `windows/app/ui/index.html`) ustawiana ręcznie na tę samą wartość.
4. Po wydaniu: `main` scalony z powrotem do `development`, jeśli coś zmieniło się na `main`.

## Dalej

- Wydanie z GitHub Actions po zmianie wersji na `main` (klucz EdDSA i certyfikat jako sekrety).
- Windows: akceptacja architektury, testy ręczne, klucz aktualizacji, decyzja o podpisie Authenticode (windows.md).
- Później: Developer ID i notaryzacja, polska lokalizacja, strona produktu na `cleanpasta.eryksadowski.com`.

## Ryzyka

| Ryzyko | Co robimy |
|---|---|
| Brak notaryzacji: DMG z przeglądarki trzeba raz otworzyć przez "Otwórz mimo to" | instalacja komendą curl (bez ostrzeżeń), instrukcja dla DMG |
| Utrata klucza EdDSA albo certyfikatu: zainstalowane apki nie przyjmą aktualizacji | kopie w 1Password zaraz po utworzeniu |
| Konflikt skrótu z inną apką | ustawienia pokazują błąd, skrót można zmienić albo usunąć |
