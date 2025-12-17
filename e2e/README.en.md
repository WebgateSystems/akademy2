# E2E Tests (Puppeteer)

Languages: [Polski (default)](README.md) · English · [Українська](README.ua.md)

---

Automated end-to-end tests for AKAdemy application using Puppeteer.

## Requirements

- Node.js + Yarn
- Puppeteer (installed automatically with `yarn install`)
- Running application on `localhost:3000`
- Test data in database (`rake db:seed`)

## Configuration

### Environment variables

| Variable | Description | Default |
|----------|-------------|---------|
| `E2E_BASE_URL` | Application URL | `http://localhost:3000` |
| `E2E_HEADLESS` | Headless mode | `true` |

### Test users

Tests use users from the "Włatcy Móch" seed:

- **Superadmin**: `sladkowski@webgate.pro` / `devpass!`
- **Principal**: `bartus@wlatcy.edu.pl` / `devpass!`
- **Teacher**: `teachertest@gmail.com` / `devpass!`
- **Student**: `+48123234345` / PIN: `0000`

## Running tests

```bash
# Start Rails server (in separate terminal)
bin/dev

# Run all tests (headless)
rake test

# Run with visible browser
rake test:gui

# Run a single test (headless)
rake test[superadmin-menu]

# Run a single test with GUI
rake test[superadmin-menu,gui]
```

## Available tests

| Test | Description |
|------|-------------|
| `superadmin-menu` | Superadmin panel menu navigation |
| `superadmin-users` | User management (filtering, editing) |
| `superadmin-content` | Content management (subjects, modules) |
| `principal-dashboard` | Principal panel menu |
| `principal-management` | Class, teacher, student management |
| `teacher-dashboard` | Teacher panel menu |
| `teacher-dashboard-full` | Full teacher functionality test |
| `student-dashboard` | Student panel menu |
| `student-dashboard-full` | Full student functionality test |
| `theme-switcher` | Light/dark theme switching |
| `dashboard-switcher` | Teacher↔principal dashboard switching |
| `subjects-dragdrop` | Subject drag & drop |

## File structure

```
e2e/
├── config.js           # Configuration (URL, timeouts, users)
├── run-all.js          # All tests runner
├── README.md           # This file (Polish)
├── README.en.md        # This file (English)
├── helpers/
│   ├── browser.js      # Puppeteer helper (navigation, clicks, forms)
│   └── auth.js         # Login helper (superadmin, teacher, student, principal)
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
└── screenshots/        # Screenshots (generated on errors)
```

## Writing new tests

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
// Navigation
await browser.goto('/path');           // Navigate to path
await browser.waitFor('selector');     // Wait for element
await browser.waitForNavigation();     // Wait for navigation

// Interactions
await browser.click('selector');       // Click element
await browser.type('selector', 'text'); // Type text (with animation)
await browser.fastType('selector', 'text'); // Type text (instantly)

// Checking
await browser.exists('selector', timeout); // Does element exist?
await browser.getText('selector');     // Get element text
browser.url();                         // Current URL

// Utilities
await browser.sleep(ms);               // Pause
await browser.screenshot('name');      // Take screenshot
browser.getPage();                     // Access Puppeteer page
```

### auth.js

```javascript
await auth.loginAsSuperadmin();  // Login as superadmin
await auth.loginAsTeacher();     // Login as teacher
await auth.loginAsPrincipal();   // Login as principal
await auth.loginAsStudent();     // Login as student (phone + PIN)
```

## GUI mode - visual cursor

In `rake test:gui` mode, a visual cursor (golden arrow) is displayed that:
- Smoothly moves to elements before clicking
- Shows click effect (shrinking)
- Remains visible between actions

Speed parameters differ between headless mode (fast) and GUI mode (slower, more visible).

## Troubleshooting

### Test fails only in headless mode

Add more delays:
```javascript
await browser.sleep(browser.getSpeed().mediumPause);
```

### Element not found

1. Check CSS selector
2. Add `await browser.waitFor('selector')` before action
3. Use `await browser.screenshot('debug')` for debugging

### Page load timeout

Increase timeout in `config.js`:
```javascript
timeouts: {
  implicit: 20000,  // 20 seconds
  pageLoad: 60000,  // 60 seconds
}
```

### Login issues

Check if:
1. Application is running (`bin/dev`)
2. Test data is in database (`rake db:seed`)
3. Users in `config.js` are correct

