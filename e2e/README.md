# E2E Tests (Puppeteer)

Języki: Polski (domyślny) · [English](README.en.md) · [Українська](README.ua.md)

---

Automatyczne testy end-to-end aplikacji AKAdemy używające Puppeteer.

## Wymagania

- Node.js + Yarn
- Puppeteer (instalowany automatycznie z `yarn install`)
- Uruchomiona aplikacja na `localhost:3000`
- Dane testowe w bazie (`rake db:seed`)

## Konfiguracja

### Zmienne środowiskowe

| Zmienna | Opis | Domyślnie |
|---------|------|-----------|
| `E2E_BASE_URL` | URL aplikacji | `http://localhost:3000` |
| `E2E_HEADLESS` | Tryb headless | `true` |

### Użytkownicy testowi

Testy używają użytkowników z seeda "Włatcy Móch":

- **Superadmin**: `sladkowski@webgate.pro` / `devpass!`
- **Dyrektor**: `bartus@wlatcy.edu.pl` / `devpass!`
- **Nauczyciel**: `teachertest@gmail.com` / `devpass!`
- **Uczeń**: `+48123234345` / PIN: `0000`

## Uruchamianie testów

```bash
# Uruchom serwer Rails (w osobnym terminalu)
bin/dev

# Uruchom wszystkie testy (headless)
rake test

# Uruchom z widoczną przeglądarką
rake test:gui

# Uruchom pojedynczy test (headless)
rake test[superadmin-menu]

# Uruchom pojedynczy test z GUI
rake test[superadmin-menu,gui]
```

## Dostępne testy

| Test | Opis |
|------|------|
| `superadmin-menu` | Nawigacja menu panelu superadmina |
| `superadmin-users` | Zarządzanie użytkownikami (filtrowanie, edycja) |
| `superadmin-content` | Zarządzanie treściami (przedmioty, moduły) |
| `principal-dashboard` | Menu panelu dyrektora |
| `principal-management` | Zarządzanie klasami, nauczycielami, uczniami |
| `teacher-dashboard` | Menu panelu nauczyciela |
| `teacher-dashboard-full` | Pełny test funkcji nauczyciela |
| `student-dashboard` | Menu panelu ucznia |
| `student-dashboard-full` | Pełny test funkcji ucznia |
| `theme-switcher` | Przełączanie tematu jasny/ciemny |
| `dashboard-switcher` | Przełączanie nauczyciel↔dyrektor |
| `subjects-dragdrop` | Drag & drop przedmiotów |

## Struktura plików

```
e2e/
├── config.js           # Konfiguracja (URL, timeouty, użytkownicy)
├── run-all.js          # Runner wszystkich testów
├── README.md           # Ten plik
├── helpers/
│   ├── browser.js      # Helper Puppeteer (nawigacja, kliknięcia, formularze)
│   └── auth.js         # Helper logowania (superadmin, teacher, student, principal)
├── tests/
│   ├── superadmin-menu.test.js
│   ├── superadmin-users.test.js
│   ├── superadmin-content.test.js
│   ├── principal-dashboard.test.js
│   ├── principal-management.test.js
│   ├── teacher-dashboard.test.js
│   ├── teacher-dashboard-full.test.js
│   ├── student-dashboard.test.js
│   ├── student-dashboard-full.test.js
│   ├── theme-switcher.test.js
│   ├── dashboard-switcher.test.js
│   └── subjects-dragdrop.test.js
└── screenshots/        # Zrzuty ekranu (generowane przy błędach)
```

## Pisanie nowych testów

```javascript
// e2e/tests/my-test.test.js

const browser = require('../helpers/browser');
const auth = require('../helpers/auth');

async function runTest() {
  let testPassed = false;
  
  console.log('🚀 Starting My Test...\n');
  
  try {
    await browser.launch();
    
    // Login
    await auth.loginAsSuperadmin();
    console.log('   ✓ Logged in');
    
    // Navigate
    await browser.goto('/admin/schools');
    console.log('   ✓ Navigated to schools');
    
    // Interact
    await browser.click('.btn-new');
    await browser.type('#school_name', 'Test School');
    
    // Assert
    const exists = await browser.exists('.success-message', 2000);
    if (exists) {
      console.log('   ✓ Success message shown');
      testPassed = true;
    }
    
  } catch (error) {
    console.error('❌ TEST ERROR:', error.message);
    await browser.screenshot('my-test-error');
    
  } finally {
    await browser.close();
  }
  
  console.log(testPassed ? '\n✅ TEST PASSED\n' : '\n❌ TEST FAILED\n');
  return testPassed;
}

runTest()
  .then(passed => process.exit(passed ? 0 : 1))
  .catch(error => {
    console.error('Fatal:', error);
    process.exit(1);
  });
```

## Helper API

### browser.js

```javascript
// Nawigacja
await browser.goto('/path');           // Przejdź do ścieżki
await browser.waitFor('selector');     // Czekaj na element
await browser.waitForNavigation();     // Czekaj na nawigację

// Interakcje
await browser.click('selector');       // Kliknij element
await browser.type('selector', 'text'); // Wpisz tekst (z animacją)
await browser.fastType('selector', 'text'); // Wpisz tekst (natychmiast)

// Sprawdzanie
await browser.exists('selector', timeout); // Czy element istnieje?
await browser.getText('selector');     // Pobierz tekst elementu
browser.url();                         // Aktualny URL

// Narzędzia
await browser.sleep(ms);               // Pauza
await browser.screenshot('name');      // Zrzut ekranu
browser.getPage();                     // Dostęp do Puppeteer page
```

### auth.js

```javascript
await auth.loginAsSuperadmin();  // Zaloguj jako superadmin
await auth.loginAsTeacher();     // Zaloguj jako nauczyciel
await auth.loginAsPrincipal();   // Zaloguj jako dyrektor
await auth.loginAsStudent();     // Zaloguj jako uczeń (phone + PIN)
```

## Tryb GUI - wizualny kursor

W trybie `rake test:gui` widoczny jest wizualny kursor (złota strzałka), który:
- Płynnie przesuwa się do elementów przed kliknięciem
- Pokazuje efekt kliknięcia (zmniejszenie)
- Pozostaje widoczny między akcjami

Parametry szybkości są różne dla trybu headless (szybki) i GUI (wolniejszy, bardziej widoczny).

## Troubleshooting

### Test failuje tylko w headless mode

Dodaj więcej opóźnień:
```javascript
await browser.sleep(browser.getSpeed().mediumPause);
```

### Element nie znaleziony

1. Sprawdź selektor CSS
2. Dodaj `await browser.waitFor('selector')` przed akcją
3. Użyj `await browser.screenshot('debug')` do debugowania

### Timeout przy ładowaniu strony

Zwiększ timeout w `config.js`:
```javascript
timeouts: {
  implicit: 20000,  // 20 sekund
  pageLoad: 60000,  // 60 sekund
}
```

### Problemy z logowaniem

Sprawdź czy:
1. Aplikacja jest uruchomiona (`bin/dev`)
2. Dane testowe są w bazie (`rake db:seed`)
3. Użytkownicy w `config.js` są poprawni
