/**
 * E2E Test: Principal Management Dashboard — Classes
 */

const browser = require('../helpers/browser');
const config = require('../config');

async function runTest() {
  let testPassed = true;
  console.log('🚀 Starting Classes Management Test...\n');

  try {
    await browser.launch();
    const page = browser.getPage();

    // ==============================
    // Step 1: Login as principal
    // ==============================
    console.log('📍 Step 1: Login as principal');
    await loginAsPrincipal();

    // ==============================
    // Step 2: Navigate to classes page
    // ==============================
    console.log('📍 Step 2: Navigate to /management/classes');
    await browser.goto('/management/classes');
    await page.waitForSelector('button.class-card__add-button[data-open-modal="add-class-modal"]');
    console.log('   ✓ Classes page loaded');

    // ==============================
    // Step 3: Open create modal
    // ==============================
    console.log('📍 Step 3: Open create class modal');
    await page.click('button.class-card__add-button[data-open-modal="add-class-modal"]');
    await page.waitForSelector('#add-class-form', { visible: true });
    console.log('   ✓ Modal opened');

    // ==============================
    // Step 4: Fill form and create class
    // ==============================
    console.log('📍 Step 4: Fill form and create class');

    const className = `E2EClass${Date.now()}`;

    await page.type('#add-class-name', className);

    await page.click('#add-class-form button[type="submit"]');
    await page.waitForSelector('button.class-card__add-button[data-open-modal="add-class-modal"]', { visible: true });

    console.log(`   ✓ Class created: ${className}`);

    // ==============================
    // Step 5: Edit class
    // ==============================
    console.log('📍 Step 5: Edit class');

    const updatedClassName = `${className} UPDATED`;

    // Wait for edit button to appear (may take time in headless mode)
    const editButtonSelector = `button.class-card__edit[data-action="edit-class"][data-class-name="${className}"]`;
    
    await page.waitForSelector(editButtonSelector, { 
      visible: true, 
      timeout: 10000 // 10 seconds timeout for headless mode
    });
    
    // Scroll button into view before clicking (helps in headless mode)
    await page.evaluate((selector) => {
      const btn = document.querySelector(selector);
      if (btn) btn.scrollIntoView({ block: 'center', behavior: 'smooth' });
    }, editButtonSelector);
    
    await browser.sleep(200); // Small delay for scroll
    
    await page.click(editButtonSelector);

    // Wait for modal to open with longer timeout for headless mode
    await page.waitForSelector('#edit-class-form', { 
      visible: true, 
      timeout: 10000 // 10 seconds timeout
    });
    
    // Wait for form input field to be ready (more reliable check)
    await page.waitForFunction(
      () => {
        const form = document.getElementById('edit-class-form');
        const input = document.getElementById('edit-class-name');
        return form && 
               form.offsetParent !== null && // Form is visible
               input && 
               input.offsetParent !== null; // Input is visible
      },
      { timeout: 5000 }
    );
    
    // Additional wait for form to be fully rendered and interactive
    await browser.sleep(300);

    await page.evaluate(() => {
      document.querySelector('#edit-class-name').value = '';
    });

    await page.type('#edit-class-name', updatedClassName);

    await page.click('#edit-class-form button[type="submit"]');
    await page.waitForSelector('button.class-card__add-button[data-open-modal="add-class-modal"]', { visible: true });

    console.log(`   ✓ Class updated: ${updatedClassName}`);

    console.log('\n✅ CLASSES Management TEST PASSED\n');

  } catch (error) {
    console.error('\n❌ TEST ERROR:', error.message);
    testPassed = false;
  } finally {
    await browser.close();
  }

  return testPassed;
}

// ==============================
// Login helper
// ==============================
async function loginAsPrincipal() {
  const page = browser.getPage();
  await browser.goto('/login/administration');
  await browser.sleep(1000);

  const user = config.users.principal;
  await page.type('input[name="user[email]"], input#user_email', user.email);
  await page.type('input[name="user[password]"], input#user_password', user.password);

  await Promise.all([
    browser.waitForNavigation(),
    page.click('input[type="submit"], button[type="submit"]'),
  ]);

  await browser.sleep(2000);
  console.log(`   ✓ Logged in as ${user.email}\n`);
}

runTest()
  .then(passed => process.exit(passed ? 0 : 1))
  .catch(err => {
    console.error('Fatal:', err);
    process.exit(1);
  });

