/**
 * E2E Test: Principal Management Dashboard — Parents (Full CRUD)
 */

const browser = require('../helpers/browser');
const config = require('../config');

async function runTest() {
  let testPassed = true;
  console.log('🚀 Starting Parents Management Test (Full CRUD)...\n');

  try {
    await browser.launch();
    const page = browser.getPage();

    // ==============================
    // Step 1: Login as principal
    // ==============================
    console.log('📍 Step 1: Login as principal');
    await loginAsPrincipal();

    // ==============================
    // Step 2: Navigate to parents page
    // ==============================
    console.log('📍 Step 2: Navigate to /management/parents');
    await browser.goto('/management/parents');
    await page.waitForSelector('button[data-open-modal="add-parent-modal"]');
    console.log('   ✓ Parents page loaded');

    // ==============================
    // Step 3: Open create parent modal
    // ==============================
    console.log('📍 Step 3: Open create parent modal');
    await page.click('button[data-open-modal="add-parent-modal"]');
    await page.waitForSelector('#add-parent-form', { visible: true });
    console.log('   ✓ Modal opened');

    // ==============================
    // Step 4: Fill form and create parent
    // ==============================
    const parentFirstName = `E2EParent${Date.now()}`;
    const parentLastName  = `Test${Date.now()}`;
    const parentEmail     = `e2e.parent.${Date.now()}@example.com`;

    await page.type('#add-parent-first-name', parentFirstName);
    await page.type('#add-parent-last-name', parentLastName);
    await page.type('#add-parent-email', parentEmail);
    await page.type('#add-parent-phone', '+48111222333');

    await page.select('#add-parent-relation', 'other');
    await page.click('#add-parent-students-search');
    await page.type('#add-parent-students-search', 'Krystyna', { delay: 50 });

    await page.waitForSelector(
      '#add-parent-students-autocomplete div',
      { visible: true, timeout: 20000 }
    );

    await page.evaluate(() => {
      const firstItem = document.querySelector(
        '#add-parent-students-autocomplete div'
      );
      if (!firstItem) throw new Error('Student not found for parent');
      firstItem.click();
    });


    await page.click('#add-parent-form button[type="submit"]');
    await page.waitForSelector('#parents-search-input', { visible: true });

    console.log(`   ✓ Parent created: ${parentEmail}`);

    // ==============================
    // Step 5: Search created parent
    // ==============================
    console.log('📍 Step 5: Search created parent');
    await page.evaluate(() => { document.querySelector('#parents-search-input').value = ''; });
    await page.type('#parents-search-input', parentEmail, { delay: 50 });

    await page.waitForFunction(
      (email) => document.body.innerText.includes(email),
      { timeout: 20000 },
      parentEmail
    );

    console.log('   ✓ Parent found in list');


    // ==============================
    // Step 6: Open actions menu and edit
    // ==============================
    console.log('📍 Step 6: Open actions menu and edit');

    const updatedFirstName = `${parentFirstName} UPDATED`;
    const updatedLastName = `${parentLastName} UPDATED`;

    await page.evaluate((email) => {
      const deactivateBtn = [...document.querySelectorAll(
        'button[data-action="edit-parent"]'
      )].find(btn => btn.dataset.parentEmail?.includes(email));

      if (!deactivateBtn) throw new Error('Deactivate button not found');

      const details = deactivateBtn.closest('details.headmasters-menu');
      const summary = details.querySelector('summary');

      summary.scrollIntoView({ block: 'center' });
      summary.click();
      deactivateBtn.click();
    }, parentEmail);


    await page.waitForSelector('#edit-parent-form', { visible: true });

    await page.evaluate(() => {
    document.querySelector('#edit-parent-first-name').value = '';
    document.querySelector('#edit-parent-last-name').value = '';
    });
    await page.type('#edit-parent-first-name', updatedFirstName);
    await page.type('#edit-parent-last-name', updatedLastName);
    await page.click('#edit-parent-save-btn');


    console.log(`   ✓ Parent updated: ${updatedFirstName}`);



    // ==============================
    // Step 7: Search created parent
    // ==============================
    console.log('📍 Step 7: Search updated parent');
    await page.evaluate(() => { document.querySelector('#parents-search-input').value = ''; });
    await page.type('#parents-search-input', updatedFirstName, { delay: 50 });
    console.log('   ✓ Parent found in list');

    // ==============================
    // Step 8: Deactivate parent
    // ==============================
    console.log('📍 Step 8: Deactivate parent');

    await page.evaluate((name) => {
      const deactivateBtn = document.querySelector(
        `button[data-action="deactivate-parent"]`
      );
      if (!deactivateBtn) throw new Error('Deactivate button not found');

      const details = deactivateBtn.closest('details.headmasters-menu');
      const summary = details.querySelector('summary');
      summary.scrollIntoView({ block: 'center' });
      summary.click();
      deactivateBtn.click();
    }, updatedFirstName);

    const deactivateConfirm = await page.$('#deactivate-parent-confirm-btn');
    if (deactivateConfirm) await deactivateConfirm.click();

    console.log('   ✓ Parent deactivated');

    // ==============================
    // Step 8: Delete parent
    // ==============================
    console.log('📍 Step 8: Delete parent');

    await page.evaluate((name) => {
      const deleteBtn = document.querySelector(
        `button[data-action="delete-parent"]`
      );
      if (!deleteBtn) throw new Error('Delete button not found');

      const details = deleteBtn.closest('details.headmasters-menu');
      const summary = details.querySelector('summary');
      summary.scrollIntoView({ block: 'center' });
      summary.click();
      deleteBtn.click();
    }, updatedFirstName);

    const deleteConfirm = await page.$('#delete-parent-confirm-btn');
    if (deleteConfirm) await deleteConfirm.click();

    await page.waitForFunction(
      (name) => !document.body.innerText.includes(name),
      { timeout: 20000 },
      updatedFirstName
    );

    console.log('   ✓ Parent deleted');

    console.log('\n✅ FULL CRUD PARENTS TEST PASSED\n');

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
