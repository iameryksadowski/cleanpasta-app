# Cleanpasta - plan od A do Z

Stan: 29.09.2026, uzupełniony 07.11.2026. Autor planu: Eryk Sadowski. Ten plik jest źródłem prawdy dla prac nad apką Cleanpasta (zmiana nazwy w 1.1.0: sekcja 6a; rezygnacja z nazwy "ES Tools" w 1.2.0: sekcja 6b); statusy faz aktualizujemy tutaj.

07.11.2026: nazwa ES Tools porzucona (decyzja Eryka); nowy identyfikator pakietu, certyfikat i nazwa repo; nie ma jeszcze użytkowników poza Erykiem, więc bez migracji poza skopiowaniem jego własnych ustawień.

## 0. Cel

- **Dziś:** Maciek dostaje działającą apkę Cleanpasta. Instalacja bez terminala: plik DMG, przeciągnij do Aplikacji, jedno kliknięcie w uprawnienia.
- **Szerzej:** Cleanpasta to samodzielny produkt, podpisany nazwiskiem autora (Eryk Sadowski), bez wspólnej nazwy-parasola. Ewentualne kolejne narzędzia dostają własne nazwy.

## 1. Decyzje architektoniczne

| # | Decyzja | Dlaczego | Odrzucone |
|---|---|---|---|
| D1 | Jedno repo na produkt (`cleanpasta-app`) | każdy produkt ma własne wydania i aktualizacje; `eryksadowski-tools` to katalog na jednorazowe zadania | wspólne repo na wszystkie narzędzia |
| D2 | Osobne apki, nie launcher z pluginami | różne narzędzia, różne uprawnienia; launcherem jest już Raycast | własny launcher |
| D3 | Cleanpasta = natywna apka AppKit + SwiftUI, w pasku menu; ikona w Docku tylko przy otwartym oknie ustawień lub aktualizacji | lekka, zawsze pod ręką, nie zaśmieca Docka | Electron, sam Raycast |
| D4 | Konwersja: jedno źródło `converter/src/convert.ts` (do 15.10.2026 w repo Raycasta, R5), w apce przez JavaScriptCore z pliku `Resources/convert.js` (esbuild) | jedna logika i jedne testy dla Raycasta i apki | port do Swift (dwie implementacje do utrzymania) |
| D5 | Schowek natywnie: NSPasteboard (HTML, web archive, RTF, tekst), wklejanie przez CGEvent Cmd+V po puszczeniu modyfikatorów | ten sam algorytm co w rozszerzeniu, sprawdzony w Mailu | Raycast Clipboard API |
| D6 | Skróty globalne przez Carbon `RegisterEventHotKey`, własne pole do nagrywania skrótu | działa bez Dostępności i bez zależności | biblioteki zewnętrzne |
| D7 | Start przy logowaniu przez `SMAppService.mainApp` | systemowy sposób od macOS 13 | LaunchAgent w plist |
| D8 | Aktualizacje bez żadnych licencji: Sparkle 2 z darmowym podpisem EdDSA, `appcast.xml` jako asset GitHub Release, changelog w oknie aktualizacji, instalacja po zgodzie użytkownika (szczegóły w sekcji 2c) | aktualizacja pobrana przez samą apkę nie dostaje flagi kwarantanny, więc macOS jej nie blokuje; Apple Developer niepotrzebny | notaryzacja (płatna), ręczne pobieranie każdej wersji |
| D9 | Repo apki publiczne | Cleanpasta jest open source; pliki aktualizacji muszą być do pobrania bez logowania | prywatne repo + osobny hosting |
| D10 | Podpis darmowym, stałym certyfikatem "Eryk Sadowski Code Signing" (samopodpisany, ważny 10 lat, zrobiony lokalnie) | stały podpis = uprawnienie Dostępność przetrwa aktualizacje, a Sparkle sprawdza, że aktualizacja pochodzi od tego samego autora | podpis ad-hoc (Dostępność do ponownego włączenia po każdej wersji), Developer ID (płatne) |
| D11 | Build: Swift Package Manager + skrypt składający `.app` (Command Line Tools, Swift 5.10, SDK 14.4) | licencja Xcode nie jest zaakceptowana, a to wymaga `sudo` | projekt Xcode |
| D12 | Minimum macOS 14 | JavaScriptCore z macOS 14 obsługuje wszystkie wyrażenia regularne konwertera (lookbehind, `\p{L}`) | macOS 13 |
| D13 | UI po angielsku (brand Eryk Sadowski jako podpis), instrukcja dla Maćka po polsku | zasada brandu; polska lokalizacja później | - |
| D14 | (zastąpione przez D20) | | |
| D16 | Uniwersalność: jedna biblioteka `CleanpastaCore` (konwerter, schowek, opcje) używana przez apkę i przez CLI `cleanpasta`; testy wklejania nie tylko w Mailu, także Gmail (Chrome), Slack, Notatki, Pages, Word | narzędzie ma działać wszędzie, gdzie się wkleja, i w automatyzacji | logika zaszyta w apce |
| D17 | CLI `cleanpasta` w paczce apki (`Contents/Helpers/cleanpasta`), instalowane z ustawień jednym kliknięciem jako link w `~/.local/bin` (bez hasła administratora) | Eryk, skrypty, Raycast Script Commands i agenci AI mogą czyścić i kopiować tekst bez klikania | osobna instalacja przez Homebrew (później) |
| D18 | Skill AI `cleanpasta`: uczy Claude'a pisać drafty w Markdown i oddawać je przez `cleanpasta --copy`, żeby Eryk wklejał gotowy, sformatowany tekst; źródło prawdy od 26.10.2026 w osobnym repo skilli, kopia do dystrybucji w repo apki (`skills/cleanpasta`) | AI przygotowuje maile i wiadomości gotowe do wklejenia, bez ręcznego formatowania | instrukcje w CLAUDE.md |
| D19 | (zastąpione 07.11.2026) Jedna ikona wspólna dla wielu narzędzi odpada razem z nazwą-parasolem: ikona w pasku menu to prosty znak schowka | Cleanpasta jest samodzielnym produktem | wspólny rejestr i menu wielu narzędzi |
| D20 | Ikona apki: zielony schowek na jasnym (domyślnie) lub ciemnym tle zaokrąglonego kwadratu, ciemna wersja podmieniana w locie; od 1.2.0 bez sygnetu w tle; propozycje w `design/proposals` | prosta, czytelna ikona | napis w ikonie |
| D15 | Integracja z Raycastem: apka ma schemat URL `cleanpasta://paste`, `://repair`, `://settings`, `://about` (stary schemat z 1.0.x usunięty w 1.2.0, 6b); rozszerzenie Raycasta zarchiwizowane (R5, R7) | Raycast może wywołać apkę jednym deeplinkiem | - |

## 2. Specyfikacja: Cleanpasta (apka, od 1.0.0)

- **Pasek menu:** ikona schowka. Menu: Paste Clean (skrót), Repair Clipboard (skrót), Settings..., Check for Updates..., About Cleanpasta, Quit.
- **Paste Clean** (domyślnie ⌃⌥⌘V): czyta schowek, czyści formatowanie, zapisuje wynik i sam wciska Cmd+V. Pusty schowek albo sam obraz lub plik: zwykłe Cmd+V. Brak Dostępności: czysty tekst zostaje w schowku i pojawia się podpowiedź.
- **Repair Clipboard** (bez domyślnego skrótu): czyści schowek w miejscu, bez wklejania. Podpowiedź: "Clipboard repaired - paste with Cmd+V". Nazwa zamiast "Clean Clipboard", bo nie kasuje schowka.
- **Czyszczenie:** zostają pogrubienia, kursywa, podkreślenia, linki, entery, twarde spacje, listy i proste tabele; znikają tła, kolory i fonty. Markdown zamienia się na tekst sformatowany. Myślniki i cudzysłowy typograficzne zamieniają się na znaki z klawiatury.
- **Ustawienia** (okno, ikona w Docku tylko wtedy):
  - Shortcuts: Paste Clean, Repair Clipboard (kliknij i naciśnij klawisze, Delete czyści).
  - Formatting: Replace dashes, Replace quotes, Font size: 12 px (domyślnie, jak Apple Mail), 11, 13, 14, 16 px albo rozmiar aplikacji docelowej.
  - General: Open at login, Show confirmation (podpowiedź na ekranie).
  - Updates: Check automatically, Check now, wersja.
  - Permission: status Dostępności i przycisk do Ustawień systemowych.
  - Stopka: Eryk Sadowski · eryksadowski.com.
- **Pierwsze uruchomienie:** otwiera ustawienia z sekcją powitalną i krokiem "Allow Accessibility".
- **Prywatność:** brak telemetrii; sieć tylko do sprawdzania aktualizacji.
- **General w ustawieniach:** także "Install command line tool" (link `cleanpasta` w `~/.local/bin`, z informacją o PATH).

## 2a. Specyfikacja: CLI `cleanpasta`

```
cleanpasta [FILE] [options]
  wejście: FILE, albo stdin (gdy jest), albo schowek
  --markdown | --html | --text   typ wejścia (domyślnie: auto, jak w apce)
  --copy                         wynik do schowka (HTML + tekst)
  --paste                        do schowka i Cmd+V w aktywnej apce (wymaga Dostępności)
  --repair                       wyczyść schowek w miejscu (= Repair Clipboard)
  --print html|text|json         co wypisać na stdout (domyślnie html; przy --copy nic)
  --body                         tylko treść draftu: bez front matter i notatek po pierwszym ---
  --keep-dashes --keep-quotes    wyłącz zamiany
  --font-size N                  0 = bez rozmiaru; domyślnie wartość z ustawień apki (12)
  --version, --help
```

Kody wyjścia: 0 ok, 1 błąd użycia, 2 nic do wyczyszczenia, 3 brak Dostępności przy --paste.

## 2b. Skill AI `cleanpasta`

- Kiedy: Eryk prosi o maila, wiadomość albo odpowiedź do wklejenia (Mail, Gmail, Slack, WhatsApp), albo o "skopiuj mi to sformatowane".
- Jak: Claude pisze treść w Markdown (pogrubienia, listy, linki), zapisuje do pliku tymczasowego i uruchamia `cleanpasta --markdown --copy PLIK`; mówi Erykowi "w schowku, wklej Cmd+V". Bez apki (czat w przeglądarce): oddaje czysty Markdown i przypomina o Paste Clean.
- Zasady: proste cudzysłowy i krótki myślnik już w treści; nic nie wysyła sam.

## 2c. Instalacja i aktualizacje bez licencji

- **Pierwsza instalacja, sposób 1 (polecany):** jedna komenda w Terminalu, skopiowana z README albo od Eryka:
  `curl -fsSL https://github.com/iameryksadowski/cleanpasta-app/releases/latest/download/install.sh | sh`.
  Skrypt pobiera najnowszy zip, rozpakowuje do Aplikacji i uruchamia apkę. curl nie nadaje flagi kwarantanny, więc nie ma żadnego ostrzeżenia.
- **Pierwsza instalacja, sposób 2:** DMG z przeglądarki, przeciągnij do Aplikacji, przy pierwszym uruchomieniu raz "Otwórz mimo to" w Ustawieniach systemowych (Prywatność i ochrona). Instrukcja ze zrzutami w DMG i w `docs/instalacja.md`.
- **Aktualizacje:** apka raz dziennie sprawdza `appcast.xml`. Gdy jest nowa wersja, pokazuje okno z changelogiem i przyciskiem Install Update; pobiera, sprawdza podpis EdDSA, podmienia się i uruchamia ponownie. Bez ostrzeżeń macOS i bez ponownego nadawania Dostępności (stały certyfikat).
- **Awaryjnie:** menu "Check for Updates..." i link do strony wydań; ręczna aktualizacja = przeciągnięcie nowej wersji do Aplikacji.
- **Klucze:** prywatny klucz EdDSA i certyfikat "Eryk Sadowski Code Signing" żyją w pęku kluczy Eryka; kopie do 1Password (Eryk). Bez nich nie da się wydać aktualizacji, którą przyjmą zainstalowane apki.
- **Wydanie:** `scripts/release.sh` (lokalnie): build, podpis, zip, DMG, `install.sh`, appcast z changelogiem, GitHub Release. Później GitHub Actions po push na `main` z nową wersją (klucze jako sekrety repo).
- **Wtyczka do Illustratora:** osobne, proste sprawdzanie wersji (plik z numerem wersji w GitHub Release i komunikat "jest nowa wersja, pobierz").

## 3. Repo `cleanpasta-app`

```
Package.swift                 SPM, zależność Sparkle
Sources/CleanpastaCore/       biblioteka: Converter, Clipboard, Options, Markdown body, CLI installation
Sources/CleanpastaApp/        apka: main, AppDelegate, HotKeys, Preferences, ShortcutField,
                              SettingsView, AboutView, HUD, Updater, CLI installer
Sources/CLI/                  CLI cleanpasta
converter/                    konwerter TypeScript (convert.ts), testy jednostkowe i wklejania, lab WebKit
skills/cleanpasta/            skill AI (kopia; źródło prawdy w osobnym repo skilli)
Resources/convert.js          generowany z converter/ (scripts/build-converter.sh), commitowany
Resources/AppIcon.icns        z design/icon.svg (scripts/make-icon.sh)
Resources/Info.plist          szablon (wersja wstawiana przy budowie)
design/icon.svg               źródło ikony
scripts/build-app.sh          .app + podpis + zip + dmg
scripts/release.sh            wydanie: build, podpis EdDSA, appcast.xml, GitHub Release
tests/                        zgodność JavaScriptCore z TypeScript, CLI, instalacja CLI, paczka
windows/                      wersja Windows (Tauri 2, podgląd, docs/windows.md)
docs/plan.md                  ten plik
docs/instalacja.md            instrukcja po polsku (dla Maćka)
README.md, CHANGELOG.md, CLAUDE.md, LICENSE
```

## 4. Fazy

Każda faza kończy się commitem na `development` i spełnionymi kryteriami odbioru.

### F1. Szkielet i konwerter
- Repo, Package.swift, skrypt `build-converter.sh`, `Resources/convert.js`.
- Test: konwerter w JavaScriptCore daje dokładnie te same wyniki co testy jednostkowe Raycasta (fixture'y: czat, VS Code, Mail, cudzysłowy, rozmiar fontu).
- **Odbiór:** `scripts/test.sh` przechodzi.

### F2. Rdzeń
- Biblioteka `CleanpastaCore`: Converter, Clipboard (odczyt HTML, web archive, RTF, tekst; zapis; Cmd+V po puszczeniu modyfikatorów), Options.
- CLI `cleanpasta` wg specyfikacji 2a.
- Apka: HotKeys, Preferences.
- **Odbiór:** `cleanpasta` czyści plik, stdin i schowek; wynik identyczny z testami Raycasta; skrót w apce czyści schowek.

### F3. Interfejs
- Menu w pasku, okno ustawień (SwiftUI), zmiana ikony w Docku przy oknie, pole skrótu, podpowiedź HUD, pierwsze uruchomienie, schemat URL.
- **Odbiór:** ikona w Docku pojawia się tylko przy otwartym oknie i znika po zamknięciu; każda opcja zapisuje się i działa od razu.

### F4. Ikona i brand
- `design/icon.svg`, `AppIcon.icns` (16-1024 px), ikona w pasku menu jako template.
- **Odbiór:** ikona czytelna w 16, 32, 128 i 512 px; zgodna z BRAND.md (jeden akcent, bez gradientów).

### F5. Paczka
- `build-app.sh`: `Cleanpasta.app` (Info.plist, LSUIElement, ikona, convert.js, Sparkle.framework), podpis ad-hoc, zip i DMG.
- Test wklejania przez lab WebKit z repo Raycasta i ręcznie w TextEdit.
- `docs/instalacja.md` po polsku: instalacja, "Otwórz mimo to", Dostępność, skrót, co robi każda opcja.
- **Odbiór:** DMG instaluje się na czystym koncie; Paste Clean działa w Mailu.

### F6. Aktualizacje
- Certyfikat "Eryk Sadowski Code Signing" (samopodpisany), Sparkle 2, klucz EdDSA, `release.sh`, `install.sh`, appcast z changelogiem.
- Repo na GitHubie (publiczne), Release 1.0.0 z DMG, zipem i appcast.xml.
- GitHub Actions: wydanie po zmianie wersji na `main` (wymaga sekretu z kluczem EdDSA).
- **Odbiór:** wersja 1.0.0 wykrywa testowe wydanie 1.0.1 i pokazuje changelog.

### F6b. Skill AI
- `skills/cleanpasta/SKILL.md` (źródło prawdy: osobne repo skilli), kopia w repo apki.
- **Odbiór:** w nowej sesji Claude na prośbę "napisz maila do X i daj mi do wklejenia" kładzie sformatowany tekst do schowka przez `cleanpasta`.

### F7. Przekazanie Maćkowi
- Paczka: DMG + instrukcja. Wysyła Eryk.

### F8. Porządki repozytoriów
- Repo docs z brandem, katalogiem produktów i zasadami wspólnymi (dziś bez nazwy-parasola).
- Wtyczka Illustrator Logo Export: przeniesienie z historią (`git subtree split`).
- Wpisy w rejestrze nazw (`eryksadowski-docs`), README w `eryksadowski-tools` wskazuje nowe repo, PR `development` -> `main`.
- Rozszerzenie Raycasta: link do apki w README.

### F9. Później
- Wspólny pakiet Swift przy drugiej apce: ustawienia, aktualizacje, skróty, O aplikacji.
- Developer ID i notaryzacja, polska lokalizacja, Raycast Store, strona produktu na eryksadowski.com.

## 5. Ryzyka

| Ryzyko | Skutek | Co robimy |
|---|---|---|
| Brak notaryzacji | DMG z przeglądarki trzeba raz otworzyć przez "Otwórz mimo to" | instalacja komendą curl (bez ostrzeżeń); instrukcja dla DMG |
| Utrata klucza EdDSA albo certyfikatu | zainstalowane apki nie przyjmą kolejnych aktualizacji | kopie w 1Password zaraz po utworzeniu |
| Konflikt skrótu z inną apką | skrót nie działa | ustawienia pokazują błąd rejestracji, skrót można zmienić |
| Stare macOS u odbiorcy | apka się nie uruchomi | minimum macOS 14, informacja w instrukcji |

## 6. Decyzje dla Eryka (nie blokują pracy)

1. Kopie klucza EdDSA i certyfikatu do 1Password (po F6).
2. Publiczne repo apki: zgodne z zasadą open source; bez tego aktualizacje u Maćka nie zadziałają.
3. Domyślny skrót Paste Clean ⌃⌥⌘V.
4. Polska lokalizacja interfejsu.

## 6a. F10 - Cleanpasta (15.10.2026)

Eryk: cała apka nazywa się "Cleanpasta", aktualizacja ma przenieść istniejące instalacje; numerowane punkty wklejamy jako tekst; Raycast włączany z ustawień; skróty można usunąć; porządek na Macu.

| # | Decyzja | Dlaczego |
|---|---|---|
| R1 | Nazwa wszędzie: apka "Cleanpasta", plik `Cleanpasta.app`, CLI `cleanpasta`, link `cleanpasta://`, repo `cleanpasta-app` (od 1.2.0; wcześniej `estools-app-cleanpasta`), skill `cleanpasta` | jedna nazwa produktu od A do Z |
| R2 | (zastąpione w 1.2.0, 6b) Identyfikator pakietu bez zmian, stary link `estools-clean-paste://` nadal działa | Sparkle podmienia apkę tylko przy tym samym identyfikatorze; zostają Dostępność, ustawienia i skróty; stare Quicklinki w Raycaście dalej działają |
| R3 | Po aktualizacji apka sama zmienia nazwę pliku z `Clean Paste.app` na `Cleanpasta.app` i przepina link CLI | Sparkle zostawia starą nazwę pliku |
| R4 | GitHub przekierowuje stare adresy po zmianie nazwy repo, więc zainstalowane 1.0.x znajdą aktualizację; nowa wersja ma już nowy adres appcastu | brak ręcznej reinstalacji u prezesa |
| R5 | Konwerter (`convert.ts`, testy, fixture'y, lab WebKit) przenosi się do repo apki (`converter/`, pnpm); rozszerzenie Raycasta zostaje zarchiwizowane | jeden produkt, jedno źródło logiki |
| R6 | Listy numerowane wklejamy jako zwykłe linie tekstu "1. ...", bez wcięcia; tylko listy punktowane są listami | numeracja w mailach się nie rozjeżdża, tekst wygląda jak wpisany ręcznie (przykład: wycena dla Hadat) |
| R7 | Raycast w ustawieniach: sekcja z przyciskiem dodania komend (Quicklinki z importu), statusem i instrukcją usunięcia; żadnej osobnej wtyczki do instalowania | Raycast nie pozwala dodać komend inaczej bez sklepu Raycast |
| R8 | Każdy skrót ma przycisk usunięcia; brak skrótu jest poprawnym stanem | Eryk: "trzeba móc usunąć i nie ustawiać żadnego" |

Wydanie: 1.1.0. Sprzątanie na Macu Eryka: stare rozszerzenie Raycasta (do Kosza), stary link `cleanpaste`, plik importu w Pobranych, stary skill `clean-paste` na claude.ai wyłączony.

## 6b. 1.2.0 - rezygnacja z nazwy ES Tools (07.11.2026)

Eryk: nazwa-parasol "ES Tools" odpada wszędzie, także z identyfikatorów technicznych. Aplikacja to po prostu "Cleanpasta", a "Eryk Sadowski" jest podpisem (O aplikacji, stopka), nigdy częścią nazwy. Nikt poza Erykiem nie dostał jeszcze Cleanpasty, więc zmieniamy wszystko bez zgodności wstecznej dla innych użytkowników.

| # | Decyzja | Dlaczego |
|---|---|---|
| N1 | Identyfikator pakietu `com.eryksadowski.cleanpasta` (CLI: `com.eryksadowski.cleanpasta.cli`); przy starcie apka raz kopiuje ustawienia ze starej domeny `com.eryksadowski.estools.cleanpaste` (komentarz "legacy migration"), starej domeny nie kasuje | ustawienia Eryka zostają; inni użytkownicy nie istnieją |
| N2 | Schemat `estools-clean-paste://` usunięty, zostaje `cleanpasta://` | brak starych linków poza Erykiem |
| N3 | Certyfikat "Eryk Sadowski Code Signing", folder kluczy `~/.config/eryksadowski/signing`, wpis 1Password "Cleanpasta signing"; klucz publiczny EdDSA bez zmian | spójna nazwa bez ES Tools; certyfikat tworzy Eryk (`scripts/setup-signing.sh`) |
| N4 | Repo `iameryksadowski/cleanpasta-app` (zmiana nazwy z `estools-app-cleanpasta`) | nazwa wg konwencji `[produkt]-[typ]` |
| N5 | Windows: identyfikator `com.eryksadowski.cleanpasta`, ustawienia w `%APPDATA%\cleanpasta`, CLI w `%LOCALAPPDATA%\Cleanpasta\bin`, nagłówek bez wordmarku | Windows nigdy nie wydany |
| N6 | Ikona apki bez sygnetu w tle, ikona w pasku menu to schowek; z O aplikacji znika sekcja nazwy-parasola | brak wspólnej marki narzędzi |

Wydanie: 1.2.0 (pierwsze z nowym identyfikatorem i certyfikatem; na Macu Eryka lepiej zainstalować je ręcznie niż liczyć na aktualizację z 1.1.x, bo zmieniają się identyfikator i podpis).

## 7. Status (01.10.2026)

- [x] F0 Plan
- [x] F1 Szkielet i konwerter (20/20 testów zgodności JavaScriptCore z TypeScript)
- [x] F2 Rdzeń (biblioteka, CLI, skróty, ustawienia)
- [x] F3 Interfejs (pasek menu z sygnetem ES, okno ustawień, Dock tylko przy oknie - sprawdzone, HUD, schemat URL - Repair sprawdzony na żywo)
- [x] F4 Ikona i brand (wariant E: sygnet w tle, zielony schowek; jasna domyślnie, ciemna w locie)
- [x] F5 Paczka (universal .app, zip, DMG, instrukcja PL; podpis ad-hoc do czasu F6)
- [x] F6 Aktualizacje - repo publiczne, certyfikat "Eryk Sadowski Code Signing" (od 1.2.0; wcześniej inna nazwa) w pęku kluczy, klucz EdDSA w pliku, kopie w 1Password (Sadowscy > Work > "Cleanpasta signing", ta sama nazwa co w `scripts/release.sh`); Release v1.0.0 opublikowany, komenda instalacyjna sprawdzona; aktualizacja 1.0.0 -> 1.0.1 sprawdzona lokalnie. Do zrobienia: wydanie automatycznie z GitHub Actions po zmianie wersji na `main`
- [x] F6b Skill AI (wgrany na claude.ai; od 1.1.0 jako `cleanpasta`, od 26.10.2026 w osobnym repo skilli)
- [x] F7 Przekazanie Maćkowi - DMG 1.0.0 z PDF "Jak zainstalować" oddany Erykowi (01.10)
- [x] F8 Porządki repozytoriów (repo docs z historią brandu, Logo Export z historią z powrotem w swoim repo, rejestr nazw) - PR-y zmergowane
- [x] F10 Cleanpasta (zmiana nazwy, listy numerowane, Raycast z ustawień, skróty do usunięcia, porządek) - 1.1.0, migracja instalacji 1.0.x sprawdzona lokalnie
- [ ] F9 Później


### F-Windows. Tauri 2 and shared converter (2026-10-21)

- Status: implementation preview in temporary `feature/windows`, PR to `development`; no release or merge authorized.
- Architecture proposed for Eryk's acceptance: one product repository and shared history, native Swift stays at root, Windows app/CLI under `windows/`, common `Resources/convert.js` embedded in QuickJS through Rust core.
- Core and CLI: exact 18-case TypeScript parity matrix, CLI flags and exit codes from `Sources/CLI/main.swift`, CF_HTML + Unicode clipboard, SendInput after modifiers release.
- App: tray, editable shortcuts, nonfocusable HUD, branded settings, per-user autostart/PATH, deep links, updater with explicit install and public-key placeholder.
- CI: Windows tests, release CLI and NSIS artifact; macOS core/CLI tests and Tauri check. Details and acceptance gates: [windows.md](windows.md).
- Remaining release gates: architecture acceptance, manual Windows clipboard/focus tests, Eryk-generated Ed25519 key and update feed, decision on Authenticode signing. No keys or paid services provisioned.
