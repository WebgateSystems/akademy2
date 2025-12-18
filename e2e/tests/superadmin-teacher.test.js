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
    // Step 2: Go to admin/teachers
    // ========================================
    console.log('📍 Step 1: Navigate to /admin/teachers');

    await Promise.all([
    browser.waitForNavigation().catch(() => {}),
    browser.goto('/admin/teachers'),
    ]);

    await browser.waitFor(
    '.teachers-table, button.schools-page__add',
    5000
    );

    console.log('   ✓ Teachers page loaded');

    // ========================================
    // Step 3: Open add teacher modal
    // ========================================

    console.log('📍 Step 3: Open add teacher modal');

    await page.click('button[data-open-modal="add-teacher-modal"]');

    await page.waitForSelector('#add-teacher-form', {
    visible: true,
    timeout: 5000,
    });

    console.log('   ✓ Add teacher modal opened');

    // ========================================
    // Step 4: Open add teacher modal
    // ========================================

    console.log('📍 Step 4: Create teacher');

    const teacherFirstName = 'E2E';
    const teacherLastName = `Teacher ${Date.now()}`;
    const teacherEmail = `e2e_teacher_${Date.now()}@example.com`;

    await page.select('#add-teacher-school', '77777777-3d96-492d-900e-777777777777');
    await page.type('#add-teacher-first-name', teacherFirstName);
    await page.type('#add-teacher-last-name', teacherLastName);
    await page.type('#add-teacher-email', teacherEmail);
    await page.type('#add-teacher-phone', '+48123123123');

    await page.click('#add-teacher-form button[type="submit"]');
    await page.waitForFunction(
        (teacherFirstName) => document.body.innerText.includes(teacherFirstName),
        { timeout: 5000 },
        teacherFirstName
    );

    console.log(`   ✓ Teacher created: ${teacherFirstName} ${teacherLastName}`);


    // ========================================
    // Step 5: Verify search functionality
    // ========================================

    console.log('📍 Step 5: Verify search functionality');

    await page.waitForSelector('#teachers-search-input', { visible: true });

    // Clear search input
    await page.evaluate(() => {
      const input = document.querySelector('#teachers-search-input');
      if (input) {
        input.value = '';
        input.dispatchEvent(new Event('input', { bubbles: true }));
      }
    });

    // Wait a bit for table to reload with all teachers
    await browser.sleep(pause().shortPause);

    // Type search term
    await page.type('#teachers-search-input', teacherLastName);
    
    // Wait for search to trigger (input event with debounce)
    await browser.sleep(500);

    // Wait for loading indicator to disappear (search completed)
    try {
      await page.waitForFunction(
        () => {
          const indicator = document.getElementById('teachers-loading-indicator');
          return !indicator || indicator.style.display === 'none';
        },
        { timeout: 5000 }
      );
    } catch (e) {
      // Indicator might not exist or already hidden, continue
      console.log('   ⚠️  Loading indicator check skipped');
    }

    // Wait for teacher name to appear in the table
    const teacherFound = await page.waitForFunction(
      (name) => {
        // Check in table body specifically
        const tbody = document.getElementById('admin-teachers-table-body');
        if (!tbody) return false;
        return tbody.innerText.includes(name);
      },
      { timeout: 5000 },
      teacherLastName
    ).then(() => true).catch(() => false);

    if (!teacherFound) {
      throw new Error(`Teacher "${teacherLastName}" not found via search`);
    }

    console.log('   ✓ Teacher found via search');

    // ========================================
    // Step 6: Open edit teacher modal
    // ========================================

    console.log('📍 Step 6: Open edit teacher modal');

    await page.waitForFunction(
      (email) => {
        return [...document.querySelectorAll('button[data-action="edit-teacher"]')]
          .some(btn => btn.dataset.teacherEmail === email);
      },
      {},
      teacherEmail
    );
    
    await page.evaluate((email) => {
      const btn = [...document.querySelectorAll('button[data-action="edit-teacher"]')]
        .find(b => b.dataset.teacherEmail === email);
    
      if (!btn) throw new Error('Edit button not found');
    
      const details = btn.closest('details');
      details.open = true;
    }, teacherEmail);
    
    // кликаем edit
    await page.click(
      `button[data-action="edit-teacher"][data-teacher-email="${teacherEmail}"]`
    );
    
    await page.waitForSelector('#edit-teacher-form', {
      visible: true,
      timeout: 5000,
    });
    
    console.log('   ✓ Edit teacher modal opened');
    

    // ========================================
    // Step 7: Edit teacher
    // ========================================

    console.log('📍 Step 7: Edit teacher');

    const updatedLastName = `${teacherLastName} UPDATED`;

    await page.evaluate(() => {
    document.querySelector('#edit-teacher-last-name').value = '';
    });

    await page.type('#edit-teacher-last-name', updatedLastName);

    await page.click('#edit-teacher-save-btn');
    await page.waitForFunction(
        (updatedLastName) => document.body.innerText.includes(updatedLastName),
        { timeout: 5000 },
        updatedLastName
    );

    console.log(`   ✓ Teacher updated: ${updatedLastName}`);


    // ========================================
    // Step 8: Verify edited teacher
    // ========================================

    console.log('📍 Step 8: Verify edited teacher');

    // Clear search input
    await page.evaluate(() => {
      const input = document.querySelector('#teachers-search-input');
      if (input) {
        input.value = '';
        input.dispatchEvent(new Event('input', { bubbles: true }));
      }
    });

    // Wait a bit for table to reload
    await browser.sleep(pause().shortPause);

    // Type updated search term
    await page.type('#teachers-search-input', updatedLastName);
    
    // Wait for search to trigger
    await browser.sleep(500);

    // Wait for loading indicator to disappear
    try {
      await page.waitForFunction(
        () => {
          const indicator = document.getElementById('teachers-loading-indicator');
          return !indicator || indicator.style.display === 'none';
        },
        { timeout: 5000 }
      );
    } catch (e) {
      // Indicator might not exist or already hidden, continue
      console.log('   ⚠️  Loading indicator check skipped');
    }

    // Wait for updated teacher name to appear in the table
    const updatedFound = await page.waitForFunction(
      (name) => {
        const tbody = document.getElementById('admin-teachers-table-body');
        if (!tbody) return false;
        return tbody.innerText.includes(name);
      },
      { timeout: 5000 },
      updatedLastName
    ).then(() => true).catch(() => false);

    if (!updatedFound) {
      throw new Error(`Edited teacher "${updatedLastName}" not found`);
    }

    console.log('   ✓ Edited teacher found');


    // ========================================
    // Step 9: Deactivate teacher
    // ========================================


    console.log('📍 Step 9: Deactivate teacher');

    await page.waitForFunction(
      (name) => {
        return [...document.querySelectorAll('button[data-action="deactivate-teacher"]')]
          .some(btn => btn.dataset.teacherName === name);
      },
      {},
      `${teacherFirstName} ${updatedLastName}`
    );
    
    await page.evaluate((name) => {
      const btn = [...document.querySelectorAll('button[data-action="deactivate-teacher"]')]
        .find(b => b.dataset.teacherName === name);
    
      if (!btn) throw new Error('Deactivate button not found');
    
      const details = btn.closest('details');
      details.open = true;
    }, `${teacherFirstName} ${updatedLastName}`);
    
    await page.click(
      `button[data-action="deactivate-teacher"][data-teacher-name="${teacherFirstName} ${updatedLastName}"]`
    );
    
    console.log('   ✓ Deactivate modal opened');
    

    // ========================================
    // Step 10: Confirm deactivation
    // ========================================

    console.log('📍 Step 10: Confirm deactivation');

    await page.waitForSelector('#deactivate-teacher-confirm-btn', {
    visible: true,
    timeout: 5000,
    });

    await page.click('#deactivate-teacher-confirm-btn');
    await browser.sleep(pause().mediumPause);

    console.log('   ✓ Teacher deactivated');


    // ========================================
    // Success section 
    // ========================================

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
