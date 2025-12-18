/**
 * E2E Test: Superadmin creates a Headmaster
 *
 * Scenario:
 * 1. Login as superadmin
 * 2. Go to /admin/users
 * 3. Open "Add headmaster" modal
 * 4. Fill form
 * 5. Submit
 * 6. Verify headmaster via search
 */

const browser = require('../helpers/browser');
const config = require('../config');

const pause = () => browser.getSpeed();

async function runTest() {
  let testPassed = false;

  console.log('🚀 Starting Create Headmaster Test...\n');

  try {
    // ========================================
    // Setup
    // ========================================
    await browser.launch();
    const page = browser.getPage();

    // ========================================
    // Step 1: Login
    // ========================================
    console.log('📍 Step 1: Login as super admin');

    const { email, password } = config.users.superadmin;

    await browser.goto('/admin/sign_in');
    await browser.waitFor('input#email, input[name="email"]');

    await browser.type('input#email, input[name="email"]', email);
    await browser.type('input#password, input[name="password"]', password);

    await Promise.all([
      browser.waitForNavigation(),
      browser.click('input[type="submit"], button[type="submit"]'),
    ]);

    await browser.waitFor('.dashboard-sidebar, .dashboard-nav');
    console.log('   ✓ Logged in');

    // ========================================
    // Step 2: Navigate to /admin/users
    // ========================================
    console.log('📍 Step 2: Navigate to /admin/users');

    await Promise.all([
      browser.waitForNavigation().catch(() => {}),
      browser.goto('/admin/users'),
    ]);

    await browser.waitFor(
      'button[data-open-modal="add-headmaster-modal"]',
      5000
    );

    console.log('   ✓ Users page loaded');

    // ========================================
    // Step 3: Open add headmaster modal
    // ========================================
    console.log('📍 Step 3: Open add headmaster modal');

    await page.evaluate(() => {
      document
        .querySelector('button[data-open-modal="add-headmaster-modal"]')
        .dispatchEvent(new MouseEvent('click', { bubbles: true }));
    });

    await page.waitForSelector('#add-headmaster-form', {
      visible: true,
      timeout: 5000,
    });

    console.log('   ✓ Add headmaster modal opened');

    // ========================================
    // Step 4: Fill form
    // ========================================
    console.log('📍 Step 4: Fill add headmaster form');

    const firstName = 'E2E';
    const lastName = `Headmaster ${Date.now()}`;
    const emailHM = `e2e_headmaster_${Date.now()}@example.com`;

    // Select first available school (not empty)
    await page.evaluate(() => {
      const select = document.querySelector('#add-headmaster-school');
      const option = Array.from(select.options).find(o => o.value);
      select.value = option.value;
      select.dispatchEvent(new Event('change', { bubbles: true }));
    });

    await browser.type('#add-headmaster-first-name', firstName);
    await browser.type('#add-headmaster-last-name', lastName);
    await browser.type('#add-headmaster-email', emailHM);
    await browser.type('#add-headmaster-phone', '+48123123123');

    console.log(`   ✓ Form filled (${firstName} ${lastName})`);

    // ========================================
    // Step 5: Submit form
    // ========================================
    console.log('📍 Step 5: Submit form');

    await Promise.all([
      browser.waitForNavigation().catch(() => {}),
      page.click('#add-headmaster-form button[type="submit"]'),
    ]);

    await browser.sleep(pause().mediumPause);

    // ========================================
    // Step 6: Verify search functionality
    // ========================================
    console.log('📍 Step 6: Verify search functionality');

    const searchSelector = '#headmasters-search-input';

    await page.waitForSelector(searchSelector, {
      visible: true,
      timeout: 5000,
    });

    await page.focus(searchSelector);
    await page.evaluate(sel => {
      document.querySelector(sel).value = '';
    }, searchSelector);

    await page.type(searchSelector, lastName);

    await browser.sleep(pause().mediumPause);

    const headmasterExists = await page.evaluate((name) => {
      return document.body.innerText.includes(name);
    }, lastName);

    if (!headmasterExists) {
      throw new Error(`Headmaster "${lastName}" not found via search`);
    }

    console.log('   ✓ Headmaster found via search');

    // ========================================
    // Step 7: Open actions menu for created headmaster
    // ========================================
    console.log('📍 Step 7: Open actions menu for created headmaster');

    const openMenuForHeadmaster = await page.evaluate((lastName) => {
    const rows = Array.from(document.querySelectorAll('tr'));

    for (const row of rows) {
        if (row.innerText.includes(lastName)) {
        const summary = row.querySelector(
            'details.headmasters-menu > summary'
        );
        if (summary) {
            summary.click();
            return true;
        }
        }
    }
    return false;
    }, lastName);

    if (!openMenuForHeadmaster) {
    throw new Error(`Actions menu for headmaster "${lastName}" not found`);
    }

    console.log('   ✓ Actions menu opened');

    // ========================================
    // Step 8: Open edit headmaster modal
    // ========================================
    console.log('📍 Step 8: Open edit headmaster modal');

    const openEditModal = await page.evaluate((lastName) => {
    const buttons = Array.from(
        document.querySelectorAll('button[data-action="edit-headmaster"]')
    );

    const btn = buttons.find(
        b => b.dataset.headmasterLastName === lastName
    );

    if (!btn) return false;

    btn.click();
    return true;
    }, lastName);

    if (!openEditModal) {
    throw new Error(`Edit button for "${lastName}" not found`);
    }

    await page.waitForSelector('#edit-headmaster-form', {
    visible: true,
    timeout: 5000,
    });

    console.log('   ✓ Edit headmaster modal opened');

    // ========================================
    // Step 9: Edit headmaster form
    // ========================================
    console.log('📍 Step 9: Edit headmaster form');

    const updatedFirstName = `${firstName} UPDATED ${Date.now()}`;

    await page.evaluate(() => {
    document.querySelector('#edit-headmaster-first-name').value = '';
    });

    await browser.type('#edit-headmaster-first-name', updatedFirstName);

    console.log(`   ✓ First name updated to "${updatedFirstName}"`);

    // ========================================
    // Step 10: Submit edit headmaster form
    // ========================================
    console.log('📍 Step 10: Submit edit headmaster form');

    await Promise.all([
    browser.waitForNavigation().catch(() => {}),
    page.click('#edit-headmaster-save-btn'),
    ]);

    await browser.sleep(pause().mediumPause);

    console.log('   ✓ Edit form submitted');

    // ========================================
    // Step 11: Verify edited headmaster via search
    // ========================================
    console.log('📍 Step 11: Verify edited headmaster via search');

    await page.focus(searchSelector);
    await page.evaluate(sel => {
    document.querySelector(sel).value = '';
    }, searchSelector);

    await page.type(searchSelector, updatedFirstName);

    await browser.sleep(pause().mediumPause);

    const updatedExists = await page.evaluate((name) => {
    return document.body.innerText.includes(name);
    }, updatedFirstName);

    if (!updatedExists) {
    throw new Error(`Updated headmaster "${updatedFirstName}" not found`);
    }

    console.log('   ✓ Updated headmaster found');

    // ========================================
    // Step 12: Deactivate headmaster
    // ========================================
    console.log('📍 Step 12: Deactivate headmaster');

    // открыть меню ещё раз
    await page.evaluate((name) => {
    const rows = Array.from(document.querySelectorAll('tr'));

    for (const row of rows) {
        if (row.innerText.includes(name)) {
        row.querySelector('details.headmasters-menu > summary')?.click();
        return;
        }
    }
    }, updatedFirstName);

    const deactivateClicked = await page.evaluate((name) => {
    const buttons = Array.from(
        document.querySelectorAll('button[data-action="deactivate-headmaster"]')
    );

    const btn = buttons.find(
        b => b.dataset.headmasterName?.includes(name)
    );

    if (!btn) return false;

    btn.click();
    return true;
    }, updatedFirstName);

    if (!deactivateClicked) {
    throw new Error(`Deactivate button for "${updatedFirstName}" not found`);
    }

    await browser.sleep(pause().mediumPause);

    console.log('   ✓ Headmaster deactivated');

    // ========================================
    // Step 13: Confirm headmaster deactivation
    // ========================================
    console.log('📍 Step 13: Confirm headmaster deactivation');

    // ждём появления confirm-модалки
    await page.waitForSelector('#deactivate-headmaster-confirm-btn', {
    visible: true,
    timeout: 5000,
    });

    // кликаем кнопку подтверждения
    await page.click('#deactivate-headmaster-confirm-btn');

    // даём время UI обновиться
    await browser.sleep(pause().mediumPause);

    console.log('   ✓ Headmaster deactivation confirmed');

    console.log('\n✅ CREATE HEADMASTER TEST PASSED\n');
    testPassed = true;

  } catch (error) {
    console.error('\n❌ TEST ERROR:', error.message);
    testPassed = false;

  } finally {
    await browser.close();
  }

  return testPassed;
}

runTest()
  .then(passed => process.exit(passed ? 0 : 1))
  .catch(err => {
    console.error('Fatal:', err);
    process.exit(1);
  });
