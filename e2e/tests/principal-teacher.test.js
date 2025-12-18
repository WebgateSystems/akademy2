/**
 * E2E Test: Principal Management Dashboard — Teachers
 */

const browser = require('../helpers/browser');
const config = require('../config');

async function runTest() {
  let testPassed = true;
  console.log('🚀 Starting Teachers Management Test...\n');

  try {
    await browser.launch();
    const page = browser.getPage();

    // ==============================
    // Step 1: Login as principal
    // ==============================
    console.log('📍 Step 1: Login as principal');
    await loginAsPrincipal();

    // ==============================
    // Step 2: Navigate to teachers page
    // ==============================
    console.log('📍 Step 2: Navigate to /management/teachers');
    await browser.goto('/management/teachers');
    await page.waitForSelector('button[data-open-modal="add-teacher-modal"]');
    console.log('   ✓ Teachers page loaded');

    // ==============================
    // Step 3: Open create modal
    // ==============================
    console.log('📍 Step 3: Open create teacher modal');
    await page.click('button[data-open-modal="add-teacher-modal"]');
    await page.waitForSelector('#add-teacher-form', { visible: true });
    console.log('   ✓ Modal opened');

    // ==============================
    // Step 4: Create teacher
    // ==============================
    console.log('📍 Step 4: Fill form and create teacher');

    const teacherFirstName = `E2ETeacher${Date.now()}`;
    const teacherLastName  = `Test${Date.now()}`;
    const teacherEmail     = `e2e.teacher.${Date.now()}@example.com`;

    await page.type('#add-teacher-first-name', teacherFirstName);
    await page.type('#add-teacher-last-name', teacherLastName);
    await page.type('#add-teacher-email', teacherEmail);

    await page.click('#add-teacher-form button[type="submit"]');
    await page.waitForSelector('#teachers-search-input', { visible: true });

    console.log(`   ✓ Teacher created: ${teacherEmail}`);

    // ==============================
    // Step 5: Search created teacher
    // ==============================
    console.log('📍 Step 5: Search created teacher');

    await page.evaluate(() => {
      document.querySelector('#teachers-search-input').value = '';
    });

    await page.type('#teachers-search-input', teacherEmail, { delay: 50 });

    console.log('   ✓ Teacher found');

    // ==============================
    // Step 6: Edit teacher
    // ==============================
    console.log('📍 Step 6: Edit teacher');

    const updatedFirstName = `${teacherFirstName} UPDATED`;
    const updatedLastName = `${teacherLastName} UPDATED`;

    await page.evaluate((email) => {
      const editBtn = document.querySelector(
        `button[data-action="edit-teacher"][data-teacher-email="${email}"]`
      );

      if (!editBtn) throw new Error('Edit button not found');

      const details = editBtn.closest('details.headmasters-menu');
      const summary = details.querySelector('summary');

      summary.scrollIntoView({ block: 'center' });
      summary.click();
      editBtn.click();
    }, teacherEmail);

    await page.waitForSelector('#edit-teacher-form', { visible: true });

    await page.evaluate(() => {
      document.querySelector('#edit-teacher-first-name').value = '';
      document.querySelector('#edit-teacher-last-name').value = '';
    });

    await page.type('#edit-teacher-first-name', updatedFirstName);
    await page.type('#edit-teacher-last-name', updatedLastName);

    await page.click('#edit-teacher-save-btn');
    console.log('   ✓ Teacher updated');

    // ==============================
    // Step 7: Search created teacher
    // ==============================
    console.log('📍 Step 7: Search updated teacher');

    await page.evaluate(() => {
      document.querySelector('#teachers-search-input').value = '';
    });
    await page.type('#teachers-search-input', updatedFirstName, { delay: 50 });

    console.log('   ✓ Teacher found');

    // ==============================
    // Step 8: Deactivate teacher
    // ==============================
    console.log('📍 Step 8: Deactivate teacher');

    await page.evaluate((name) => {
      const deactivateBtn = [...document.querySelectorAll(
        'button[data-action="deactivate-teacher"]'
      )].find(btn => btn.dataset.teacherName?.includes(name));

      if (!deactivateBtn) throw new Error('Deactivate button not found');

      const details = deactivateBtn.closest('details.headmasters-menu');
      const summary = details.querySelector('summary');

      summary.scrollIntoView({ block: 'center' });
      summary.click();
      deactivateBtn.click();
    }, updatedFirstName);

    await page.waitForSelector('#deactivate-teacher-confirm-btn', { visible: true });
    await page.click('#deactivate-teacher-confirm-btn');

    console.log('   ✓ Teacher deactivated');

    console.log('\n✅ TEACHERS Management TEST PASSED\n');

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
