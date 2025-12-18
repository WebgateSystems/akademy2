/**
 * E2E Test: Superadmin creates a School
 *
 * Scenario:
 * 1. Login as superadmin
 * 2. Go to /admin/schools
 * 3. Open "Add school" modal
 * 4. Fill form
 * 5. Submit
 * 6. Verify school was created
 * 7. Open edit school modal
 * 8. Edit created school
 * 9. Submit edit form
 * 10. Verify Edited school
 * 11. Delete created school
 */

const browser = require('../helpers/browser');
const config = require('../config');

const pause = () => browser.getSpeed();

async function runTest() {
  let testPassed = false;

  console.log('🚀 Starting Create School Test...\n');

  try {
    // ========================================
    // Setup
    // ========================================
    await browser.launch();

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
      browser.click('input[type="submit"], button[type="submit"], .btn-primary'),
    ]);

    await browser.waitFor('.dashboard-sidebar, .dashboard-nav');
    console.log('   ✓ Logged in');

    // ========================================
    // Step 2: Go to Schools page
    // ========================================
    console.log('📍 Step 2: Navigate to /admin/schools');

    await browser.waitFor('.dashboard-sidebar, .dashboard-nav', 5000);
    
    const currentUrl = browser.url();
    if (!currentUrl.includes('/admin')) {
      throw new Error(`Not in admin area, current URL: ${currentUrl}`);
    }
    
    await Promise.all([
      browser.waitForNavigation().catch(() => {}),
      browser.goto('/admin/schools'),
    ]);
    
    await browser.waitFor(
      '.schools-page, table, button.schools-page__add',
      5000
    );
    
    console.log('   ✓ Schools page loaded');

    // ========================================
    // Step 3: Open create school modal
    // ========================================
    
    console.log('📍 Step 3: Open add school modal');

    const page = browser.getPage();
    
    await page.evaluate(() => {
      document
        .querySelector('.schools-page__add')
        .dispatchEvent(new MouseEvent('click', { bubbles: true }));
    });
    
    await page.waitForFunction(() => {
      const modal =
        document.querySelector('[data-modal="add-school-modal"]') ||
        document.querySelector('#add-school-modal');
    
      if (!modal) return false;
    
      const style = window.getComputedStyle(modal);
      return (
        style.display !== 'none' &&
        style.visibility !== 'hidden' &&
        style.opacity !== '0'
      );
    }, { timeout: 5000 });
    
    await page.waitForSelector('#add-school-name', {
      visible: true,
      timeout: 5000,
    });
    
    console.log('   ✓ Add school modal REALLY opened');
    

    // ========================================
    // Step 4: Fill form
    // ========================================
    console.log('📍 Step 4: Fill add school form');

    await browser.waitFor(
      '#add-school-name',
      5000
    );
    
    await browser.waitFor(
      'form#add-school-form input#add-school-name',
      5000
    );

    const schoolName = `E2E School ${Date.now()}`;

    await browser.type('#add-school-name', schoolName);
    await browser.type('#add-school-address', 'Testowa 123');
    await browser.type('#add-school-city', 'Gdynia');
    await browser.type('#add-school-postcode', '81-001');
    await browser.type('#add-school-phone', '+48123123123');
    await browser.type('#add-school-email', 'e2e_school@example.com');
    await browser.type('#add-school-homepage', 'https://e2e-school.example.com');

    console.log(`   ✓ Form filled (school name: "${schoolName}")`);

    // ========================================
    // Step 5: Submit form
    // ========================================
    console.log('📍 Step 5: Submit form');

    await Promise.all([
      browser.waitForNavigation().catch(() => {}),
      browser.click('form#add-school-form button[type="submit"]'),
    ]);

    await browser.sleep(pause().mediumPause);

    // ========================================
    // Step 6: Verify search functionality
    // ========================================
    console.log('📍 Step 5.1: Verify search functionality');

    const searchInputSelector = '#schools-search-input';
    await page.waitForSelector(searchInputSelector, { visible: true, timeout: 5000 });

    await page.focus(searchInputSelector);
    await page.evaluate((selector) => { document.querySelector(selector).value = ''; }, searchInputSelector);
    await page.type(searchInputSelector, schoolName);

    await browser.sleep(pause().mediumPause);

    const searchResultExists = await page.evaluate((name) => {
      return Array.from(document.body.innerText.split('\n')).some((text) =>
        text.includes(name)
      );
    }, schoolName);

    if (!searchResultExists) {
      throw new Error(`School "${schoolName}" not found in table after search`);
    }

    console.log('   ✓ School found via search input');

    // ========================================
    // Step 7: Open edit school modal (BY DATA ATTRIBUTE)
    // ========================================
    console.log('📍 Step 7: Open edit school modal for created school');

    const editButtonSelector = `button[data-action="edit-school"][data-school-name="${schoolName}"]`;

    await page.waitForSelector(editButtonSelector, {
      visible: true,
      timeout: 5000,
    });

    await page.click(editButtonSelector);

    await page.waitForSelector('#edit-school-name', {
      visible: true,
      timeout: 5000,
    });

    console.log('   ✓ Edit school modal opened for correct school');



    // ========================================
    // Step 8: Edit school form
    // ========================================
    console.log('📍 Step 8: Edit school form');

    const updatedSchoolName = `${schoolName} UPDATED`;

    await page.evaluate(() => {
      document.querySelector('#edit-school-name').value = '';
      document.querySelector('#edit-school-address').value = '';
      document.querySelector('#edit-school-phone').value = '';
    });

    await page.type('#edit-school-name', updatedSchoolName);
    await page.type('#edit-school-address', 'Testowa 999');
    await page.type('#edit-school-phone', '+48999999999');

    console.log(`   ✓ School updated to "${updatedSchoolName}"`);

    // ========================================
    // Step 9: Submit edit form
    // ========================================
    console.log('📍 Step 9: Submit edit school form');

    await page.click('#edit-school-save-btn');

    await browser.sleep(pause().mediumPause);

    console.log('   ✓ Edit form submitted');

    // ========================================
    // Step 10: Verify edited school
    // ========================================
    console.log('📍 Step 10: Verify edited school via search');

    await page.focus('#schools-search-input');
    await page.evaluate(() => {
      document.querySelector('#schools-search-input').value = '';
    });
    await page.keyboard.press('Backspace');

    await page.type('#schools-search-input', updatedSchoolName);
    await browser.sleep(pause().mediumPause);

    const updatedSchoolExists = await page.evaluate((name) => {
      return Array.from(document.body.innerText.split('\n')).some((text) =>
        text.includes(name)
      );
    }, schoolName);

    if (!updatedSchoolExists) {
      throw new Error(`Updated school "${updatedSchoolName}" not found in table`);
    }
    console.log('   ✓ Edited school found in table');

    // ========================================
    // Step 11: Delete created school
    // ========================================
    console.log('📍 Step 11: Delete created school');

    const deleteButtonSelector =
      `button[data-action="delete-school"][data-school-name="${updatedSchoolName}"]`;

    await page.waitForSelector(deleteButtonSelector, {
      visible: true,
      timeout: 5000,
    });

    await page.click(deleteButtonSelector);

    await page.waitForSelector('#delete-school-confirm-btn', {
      visible: true,
      timeout: 5000,
    });

    await page.click('#delete-school-confirm-btn');
    await browser.sleep(pause().mediumPause);

    // ========================================
    // Step 12: Verify school was deleted
    // ========================================
    console.log('📍 Step 12: Verify school was deleted');

    const schoolStillExists = await page.evaluate((name) => {
      return Array.from(
        document.querySelectorAll('button[data-action="edit-school"]')
      ).some((btn) => btn.dataset.schoolName === name);
    }, updatedSchoolName);

    if (schoolStillExists) {
      throw new Error(`School "${updatedSchoolName}" still exists after deletion`);
    }

    console.log('   ✓ School successfully deleted');
    
    console.log('\n✅ CREATE SCHOOL TEST PASSED\n');
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
