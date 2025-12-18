/**
 * E2E Test: Superadmin creates a Student
 *
 * Scenario:
 * 1. Login as superadmin
 * 2. Go to /admin/students
 * 3. Open "Add student" modal
 * 4. Fill form
 * 5. Submit
 * 6. Verify student via search
 * 7. Edit student
 * 8. Verify edited student
 * 9. Deactivate student
 * 10. Confirm deactivation
 */

const browser = require('../helpers/browser');
const config = require('../config');

const pause = () => browser.getSpeed();

async function runTest() {
  let testPassed = false;

  console.log('🚀 Starting Create Student Test...\n');

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
    // Step 2: Go to /admin/students
    // ========================================
    console.log('📍 Step 2: Navigate to /admin/students');

    await Promise.all([
      browser.waitForNavigation().catch(() => {}),
      browser.goto('/admin/students'),
    ]);

    await browser.waitFor(
      '.students-table, button.schools-page__add',
      5000
    );

    console.log('   ✓ Students page loaded');

    // ========================================
    // Step 3: Open add student modal
    // ========================================
    console.log('📍 Step 3: Open add student modal');

    await page.click('button[data-open-modal="add-student-modal"]');

    await page.waitForSelector('#admin-add-student-form', {
      visible: true,
      timeout: 5000,
    });

    console.log('   ✓ Add student modal opened');

    // ========================================
    // Step 4: Fill student form
    // ========================================
    console.log('📍 Step 4: Create student');

    const studentFirstName = 'E2E';
    const studentLastName = `Student ${Date.now()}`;
    const studentEmail = `e2e_student_${Date.now()}@example.com`;

    await page.select('#add-student-school', '77777777-3d96-492d-900e-777777777777');
    await page.type('#add-student-first-name', studentFirstName);
    await page.type('#add-student-last-name', studentLastName);
    await page.type('#add-student-email', studentEmail);
    await page.type('#add-student-phone', '+48123123123');

    await page.click('#admin-add-student-form button[type="submit"]');
    await page.waitForFunction(
      (lastName) => document.body.innerText.includes(lastName),
      { timeout: 5000 },
      studentLastName
    );

    console.log(`   ✓ Student created: ${studentFirstName} ${studentLastName}`);

    // ========================================
    // Step 5: Verify search functionality
    // ========================================
    console.log('📍 Step 5: Verify search functionality');

    await page.waitForSelector('#students-search-input', { visible: true });

    await page.evaluate(() => {
    document.querySelector('#students-search-input').value = '';
    });

    await page.type('#students-search-input', studentLastName);

    await page.waitForFunction(
    (lastName) => {
        const rows = document.querySelectorAll('.students-table tbody tr');
        return Array.from(rows).some(row => row.innerText.includes(lastName));
    },
    { timeout: 5000 },
    studentLastName
    );

    console.log('   ✓ Student found via search');


    // ========================================
    // Step 6: Open edit student modal
    // ========================================
    console.log('📍 Step 6: Open edit student modal');

    await page.waitForFunction(
      (email) => {
        return [...document.querySelectorAll('button[data-action="edit-student"]')]
          .some(btn => btn.dataset.studentEmail === email);
      },
      {},
      studentEmail
    );

    await page.evaluate((email) => {
      const btn = [...document.querySelectorAll('button[data-action="edit-student"]')]
        .find(b => b.dataset.studentEmail === email);

      if (!btn) throw new Error('Edit button not found');
      const details = btn.closest('details');
      details.open = true;
    }, studentEmail);

    await page.click(`button[data-action="edit-student"][data-student-email="${studentEmail}"]`);

    await page.waitForSelector('#admin-edit-student-form', {
      visible: true,
      timeout: 5000,
    });

    console.log('   ✓ Edit student modal opened');

    // ========================================
    // Step 7: Edit student
    // ========================================
    console.log('📍 Step 7: Edit student');

    const updatedLastName = `${studentLastName} UPDATED`;

    await page.evaluate(() => {
      document.querySelector('#edit-student-last-name').value = '';
    });

    await page.type('#edit-student-last-name', updatedLastName);


    await page.click('#edit-student-save-btn');
    await page.waitForFunction(
        (updatedLastName) => document.body.innerText.includes(updatedLastName),
        { timeout: 5000 },
        updatedLastName
    );

    console.log(`   ✓ Student updated: ${updatedLastName}`);

    // ========================================
    // Step 8: Verify edited student
    // ========================================
    console.log('📍 Step 8: Verify edited student');

    await page.evaluate(() => {
    document.querySelector('#students-search-input').value = '';
    });

    await page.type('#students-search-input', updatedLastName);

    await page.waitForFunction(
    (lastName) => {
        const rows = document.querySelectorAll('.students-table tbody tr');
        return Array.from(rows).some(row => row.innerText.includes(lastName));
    },
    { timeout: 5000 },
    updatedLastName
    );

    console.log('   ✓ Edited student found');


    // ========================================
    // Step 9: Deactivate student
    // ========================================
    console.log('📍 Step 9: Deactivate student');

    await page.waitForFunction(
      (name) => {
        return [...document.querySelectorAll('button[data-action="deactivate-student"]')]
          .some(btn => btn.dataset.studentName === name);
      },
      {},
      `${studentFirstName} ${updatedLastName}`
    );

    await page.evaluate((name) => {
      const btn = [...document.querySelectorAll('button[data-action="deactivate-student"]')]
        .find(b => b.dataset.studentName === name);

      if (!btn) throw new Error('Deactivate button not found');
      const details = btn.closest('details');
      details.open = true;
    }, `${studentFirstName} ${updatedLastName}`);

    await page.click(`button[data-action="deactivate-student"][data-student-name="${studentFirstName} ${updatedLastName}"]`);

    console.log('   ✓ Deactivate modal opened');

    // ========================================
    // Step 10: Confirm deactivation
    // ========================================
    console.log('📍 Step 10: Confirm deactivation');

    await page.waitForSelector('#deactivate-student-confirm-btn', {
      visible: true,
      timeout: 5000,
    });

    await page.click('#deactivate-student-confirm-btn');
    await browser.sleep(pause().mediumPause);

    console.log('   ✓ Student deactivated');

    console.log('\n✅ CREATE STUDENT TEST PASSED\n');
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
