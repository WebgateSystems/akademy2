/**
 * E2E Test: Principal Management Dashboard — Years
 */

const browser = require('../helpers/browser');
const config = require('../config');

async function runTest() {
  let testPassed = true;
  console.log('🚀 Starting Years Management Test...\n');

  try {
    await browser.launch();
    const page = browser.getPage();

    // ==============================
    // Step 1: Login as principal
    // ==============================
    console.log('📍 Step 1: Login as principal');
    await loginAsPrincipal();

    // ==============================
    // Step 2: Navigate to years page
    // ==============================
    console.log('📍 Step 2: Navigate to /management/years');
    await browser.goto('/management/years');
    await page.waitForSelector('button.class-card__add-button[data-open-modal="add-year-modal"]');
    console.log('   ✓ Years page loaded');

    // ==============================
    // Step 3: Open create modal
    // ==============================
    console.log('📍 Step 3: Open create year modal');
    await page.click('button.class-card__add-button[data-open-modal="add-year-modal"]');
    await page.waitForSelector('#add-year-form', { visible: true });
    console.log('   ✓ Modal opened');

    // ==============================
    // Step 4: Fill form and create year
    // ==============================
    console.log('📍 Step 4: Fill form and create year');

    const currentYear = new Date().getFullYear();
    const uniqueOffset = Math.floor(Date.now() / 1000) % 100;
    const startYear = currentYear + 10 + uniqueOffset;
    const endYear = startYear + 1;
    const yearValue = `${startYear}/${endYear}`;

    await page.type('#add-year-year', yearValue);

    await page.click('#add-year-form button[type="submit"]');
    await page.waitForSelector('button.class-card__add-button[data-open-modal="add-year-modal"]', { visible: true });
    
    await page.waitForSelector(
      `button.class-card__edit[data-action="edit-year"][data-year-value="${yearValue}"]`,
      { visible: true, timeout: 10000 }
    );

    console.log(`   ✓ Year created: ${yearValue}`);

    // ==============================
    // Step 5: Edit year
    // ==============================
    console.log('📍 Step 5: Edit year');

    const updatedYearValue = `${startYear + 1}/${startYear + 2}`;

    const editButtonSelector =
    `button.class-card__edit[data-year-value="${yearValue}"]`;
  
    await page.waitForSelector(editButtonSelector, { visible: true });
    
    const yearId = await page.evaluate((selector) => {
        return document.querySelector(selector)?.dataset.yearId;
    }, editButtonSelector);
    
    if (!yearId) {
        throw new Error('yearId not found on edit button');
    }
    console.log(`   ✓ Year created: ${yearValue} (id=${yearId})`);

    await page.waitForSelector(editButtonSelector, { visible: true });
    
    // Scroll button into view before clicking (helps in headless mode)
    await page.evaluate((selector) => {
      const btn = document.querySelector(selector);
      if (btn) btn.scrollIntoView({ block: 'center', behavior: 'smooth' });
    }, editButtonSelector);
    
    await browser.sleep(200); // Small delay for scroll
    
    await page.click(editButtonSelector);

    // Wait for modal to open with longer timeout for headless mode
    await page.waitForSelector('#edit-year-form', { 
      visible: true, 
      timeout: 10000 // 10 seconds timeout
    });
    
    // Wait for form input field to be ready (more reliable check)
    await page.waitForFunction(
      () => {
        const form = document.getElementById('edit-year-form');
        const input = document.getElementById('edit-year-year');
        return form && 
               form.offsetParent !== null && // Form is visible
               input && 
               input.offsetParent !== null; // Input is visible
      },
      { timeout: 5000 }
    );
    
    // Additional wait for form to be fully rendered and interactive
    await browser.sleep(300);

    await page.click('#edit-year-year', { clickCount: 3 });
    await page.keyboard.press('Backspace');

    await page.type('#edit-year-year', updatedYearValue, { delay: 30 });

    await page.click('#edit-year-form button[type="submit"]');

    await page.waitForSelector('#edit-year-form', { hidden: true });

    await page.waitForFunction(
    (id, expected) => {
        const btn = document.querySelector(
        `button.class-card__edit[data-year-id="${id}"]`
        );
        return btn && btn.dataset.yearValue === expected;
    },
    { timeout: 15000 },
    yearId,
    updatedYearValue
    );

    console.log(`   ✓ Year updated: ${updatedYearValue}`);


    // ==============================
    // Step 6: Delete year
    // ==============================
    console.log('📍 Step 6: Delete year');

    await page.waitForSelector(
      `button.class-card__delete[data-action="delete-year"][data-year-value="${updatedYearValue}"]`,
      { visible: true, timeout: 10000 }
    );

    await page.evaluate((year) => {
      const deleteBtn = document.querySelector(
        `button.class-card__delete[data-action="delete-year"][data-year-value="${year}"]`
      );

      if (!deleteBtn) throw new Error('Delete button not found');

      deleteBtn.scrollIntoView({ block: 'center' });
      deleteBtn.click();
    }, updatedYearValue);

    await page.waitForSelector('#delete-year-confirm-btn', { visible: true });
    await page.click('#delete-year-confirm-btn');
    
    await page.waitForSelector('button.class-card__add-button[data-open-modal="add-year-modal"]', { visible: true });
    await browser.sleep(1000);

    console.log(`   ✓ Year deleted: ${updatedYearValue}`);

    console.log('\n✅ YEARS Management TEST PASSED\n');

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

