# E2E Visual Tests (Selenium + Applitools)

Automatyczne testy wizualne aplikacji AKAdemy używające Selenium WebDriver i Applitools Eyes.

## Wymagania

```bash
# Instalacja podstawowa (bez Applitools)
yarn add -D selenium-webdriver

# Opcjonalnie z Applitools (wymaga npm zamiast yarn jeśli są problemy z chromedriver)
yarn add -D selenium-webdriver @applitools/eyes-selenium
```

**Chrome** musi być zainstalowany w systemie. Selenium 4 automatycznie pobiera ChromeDriver.

## Konfiguracja

### Zmienne środowiskowe

| Zmienna | Opis | Domyślnie |
|---------|------|-----------|
| `E2E_BASE_URL` | URL aplikacji | `http://localhost:3000` |
| `E2E_HEADLESS` | Tryb headless | `true` |
| `APPLITOOLS_API_KEY` | Klucz API Applitools | (opcjonalny) |
| `E2E_BATCH_NAME` | Nazwa batcha w Applitools | `E2E Visual Tests` |

### Użytkownicy testowi

Testy używają użytkowników z seeda "Włatcy Móch":

- **Superadmin**: `admin@akademy.edu.pl` / `admin123!`
- **Dyrektor**: `bartus@wlatcy.edu.pl` / `devpass!`
- **Nauczyciel**: `teachertest@gmail.com` / `devpass!`
- **Uczeń**: `+48123234345` / PIN: `0000`

## Uruchamianie testów

```bash
# Uruchom serwer Rails (w osobnym terminalu)
bin/dev

# Uruchom wszystkie testy E2E
yarn e2e:all

# Uruchom pojedynczy test (superadmin menu)
yarn e2e

# Uruchom z widoczną przeglądarką (nie-headless)
yarn e2e:headed
```

## Struktura plików

```
e2e/
├── config.js           # Konfiguracja testów
├── run-all.js          # Runner wszystkich testów
├── README.md           # Ten plik
├── helpers/
│   ├── driver.js       # Helper Selenium WebDriver
│   └── applitools.js   # Helper Applitools Eyes
├── tests/
│   └── superadmin-menu.test.js  # Test menu superadmina
└── screenshots/        # Zrzuty ekranu (generowane)
```

## Pisanie nowych testów

```javascript
// e2e/tests/my-test.test.js

const {
  createDriver,
  navigateTo,
  waitForElement,
  fillInput,
  safeClick,
  takeScreenshot,
} = require('../helpers/driver');

const { openEyes, checkWindow, closeEyes } = require('../helpers/applitools');

async function runTest() {
  const driver = await createDriver();
  
  try {
    await openEyes(driver, 'My Test Name');
    
    // Navigate
    await navigateTo(driver, '/some/path');
    
    // Interact
    await fillInput(driver, '#username', 'test');
    await safeClick(driver, 'button[type="submit"]');
    
    // Visual check
    await checkWindow('Page After Login');
    
    // Assert
    await waitForElement(driver, '.success-message');
    
    console.log('✅ Test passed');
    return true;
    
  } catch (error) {
    console.error('❌ Test failed:', error);
    await takeScreenshot(driver, 'error');
    return false;
    
  } finally {
    await closeEyes();
    await driver.quit();
  }
}

runTest().then(passed => process.exit(passed ? 0 : 1));
```

## Applitools (opcjonalne)

Aby używać wizualnych porównań Applitools:

1. Załóż konto na [applitools.com](https://applitools.com)
2. Skopiuj API key z dashboardu
3. Ustaw zmienną środowiskową:

```bash
export APPLITOOLS_API_KEY="your-api-key-here"
```

Bez klucza API testy nadal działają, ale pomijają wizualne porównania.

## Troubleshooting

### Chrome nie uruchamia się

```bash
# Sprawdź wersję Chrome
/Applications/Google\ Chrome.app/Contents/MacOS/Google\ Chrome --version

# Selenium 4 automatycznie dobiera ChromeDriver
```

### Timeout przy ładowaniu strony

Zwiększ timeout w `config.js`:

```javascript
timeouts: {
  pageLoad: 60000, // 60 sekund
}
```

### Element nie znaleziony

1. Sprawdź czy selektor CSS jest poprawny
2. Dodaj `await driver.sleep(1000)` przed akcją
3. Użyj `takeScreenshot()` do debugowania

