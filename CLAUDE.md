# cleanpasta-app - zasady pracy

Cleanpasta: apka macOS w pasku menu + CLI `cleanpasta` + skill AI, podgląd Windows w `windows/`. Decyzje, wydanie i plan: `docs/plan.md`.

- Marka: nazwa produktu **Cleanpasta**, podpis **Eryk Sadowski** (O aplikacji, stopki), nigdy część nazwy. Bez nazwy linii produktów, bez Profitway, bez emoji, tylko krótki myślnik "-" i proste cudzysłowy " i ' (`scripts/check-text.py` w `scripts/test.sh` pilnuje). Interfejs, README, CHANGELOG i komentarze po angielsku; `docs/instalacja.md`, ten plik i rozmowa z Erykiem po polsku. Źródło brandu: `~/Development/eryksadowski-site`; zasady aplikacji: `~/Development/eryksadowski-docs/aplikacje/standardy.md`.
- Identyfikatory: pakiet `com.eryksadowski.cleanpasta`, CLI `com.eryksadowski.cleanpasta.cli`, certyfikat "Eryk Sadowski". Stare nazwy (`com.eryksadowski.estools.cleanpaste`, `Clean Paste.app`, `cleanpaste`) tylko w kodzie migracji z komentarzem "legacy migration" i we wpisach historycznych `CHANGELOG.md`.
- Bez integracji z Raycastem i bez schematów URL (usunięte w 1.2.0): automatyzacja tylko przez CLI.
- Logika czyszczenia: `converter/src/convert.ts` (TypeScript, pnpm, Node 24; testy jednostkowe i testy wklejania do WebKit w `converter/tests`, lab w `converter/lab`), bundlowana do `Resources/convert.js` (`scripts/build-converter.sh`) i uruchamiana w JavaScriptCore (macOS) i QuickJS (Windows). Zmiana zachowania = zmiana i testy w `converter/`, potem `scripts/build-converter.sh`, `node windows/scripts/generate-parity.mjs` i `scripts/test.sh`.
- Listy: numerowane punkty wklejamy jako zwykłe akapity "1. ..." bez wcięcia; listą (MailOutline) są tylko punkty z kropkami, przyklejone pod linią z dwukropkiem. Powitanie w pierwszej linii = osobny akapit.
- Build na Command Line Tools (bez projektu Xcode). Targety: `CleanpastaCore` (biblioteka), `CleanpastaApp` (apka), `cleanpasta` (CLI, folder `Sources/CLI`; system plików nie rozróżnia wielkości liter).
- Apka: `LSUIElement`, ikona w Docku tylko przy otwartym oknie (`DockIcon.show/hide`). Ikona jasna domyślnie, ciemna podmieniana w locie (`AppIcon`); źródła w `design/`, render `scripts/make-icon.sh`.
- Aktualizacje: Sparkle 2 + EdDSA, appcast jako asset GitHub Release. Certyfikat i klucze tworzy i trzyma Eryk (`scripts/setup-signing.sh` zmienia pęk kluczy; kopie w 1Password "Cleanpasta signing", lokalnie `~/.config/eryksadowski/signing`). Agent nie tworzy certyfikatów i nie podpisuje nimi.
- Skill: `skills/cleanpasta` = ta sama treść co w `~/Development/eryksadowski-skills/plugins/eryksadowski/skills/cleanpasta`; zmiana w jednym miejscu = kopia w drugim.
- Przed commitem: `scripts/test.sh` i `CODE_SIGN_IDENTITY=- DIST=<katalog tymczasowy> scripts/build-app.sh`. Zmiana w `windows/`: CI (workflow Windows) albo `cargo test` lokalnie.
- Git: `main` = wydane wersje, praca na `development`, PR `development` -> `main`, wydanie `scripts/release.sh` na `main`. Conventional Commits po angielsku, zero atrybucji AI.
