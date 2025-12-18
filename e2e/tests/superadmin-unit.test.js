/**
 * E2E Test: Superadmin creates Unit, edits, shows, and deletes it
 */

const browser = require('../helpers/browser');
const config = require('../config');

async function runTest() {
  let testPassed = false;
  console.log('🚀 Starting Create Unit Test...\n');

  try {
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
    // Step 2: Go to /admin/units
    // ========================================
    console.log('📍 Step 2: Navigate to /admin/units');
    await browser.goto('/admin/units');
    await page.waitForSelector('a[href="/admin/units/new"]');
    console.log('   ✓ Units page loaded');

    // ========================================
    // Step 3: Open create unit page
    // ========================================
    console.log('📍 Step 3: Open create unit page');
    await Promise.all([
      browser.waitForNavigation(),
      page.click('a[href="/admin/units/new"]'),
    ]);
    await page.waitForSelector('form[action="/admin/units"]');
    console.log('   ✓ Create unit page opened');

    // ========================================
    // Step 4: Create unit
    // ========================================
    console.log('📍 Step 4: Create unit');
    const unitTitle = `E2E Unit ${Date.now()}`;
    const unitSubjectId = '77777777-7777-7777-7777-777777777777'; // пример
    await page.type('#unit_title', unitTitle);
    await page.select('#unit_subject_id', unitSubjectId);

    await Promise.all([
      browser.waitForNavigation(),
      page.click('input[type="submit"][value="Utwórz"]'),
    ]);
    console.log(`   ✓ Unit created: ${unitTitle}`);

    // ========================================
    // Step 5: Search unit
    // ========================================
    console.log('📍 Step 5: Search unit');
    await page.waitForSelector('#units-search-input', { visible: true });

    await page.evaluate(() => {
      document.querySelector('#units-search-input').value = '';
    });
    await page.type('#units-search-input', unitTitle);

    await page.waitForFunction(
      (title) =>
        [...document.querySelectorAll('.schools-page__table tbody tr')]
          .some(tr => tr.innerText.includes(title)),
      {},
      unitTitle
    );
    console.log('   ✓ Unit found');

    // ========================================
    // Step 6: Edit unit
    // ========================================
    console.log('📍 Step 6: Edit unit');
    const updatedTitle = `${unitTitle} UPDATED`;

    await page.evaluate((title, updatedTitle) => {
      const rows = [...document.querySelectorAll('.schools-page__table tbody tr')];
      const row = rows.find(tr => tr.innerText.includes(title));
      if (!row) throw new Error('Unit row not found');
      const editBtn = row.querySelector('a.unit-action--edit');
      if (!editBtn) throw new Error('Edit button not found');
      editBtn.scrollIntoView({ block: 'center' });
      editBtn.click();
    }, unitTitle, updatedTitle);

    await page.waitForSelector('#unit_title', { visible: true });
    await page.evaluate(() => {
      document.querySelector('#unit_title').value = '';
    });
    await page.type('#unit_title', updatedTitle);

    await Promise.all([
      browser.waitForNavigation(),
      page.click('button[type="submit"].schools-page__add'),
    ]);
    console.log(`   ✓ Unit updated: ${updatedTitle}`);

    // ========================================
    // Step 7: Search updated unit
    // ========================================
    console.log('📍 Step 7: Search updated unit');
    await page.evaluate(() => {
      document.querySelector('#units-search-input').value = '';
    });
    await page.type('#units-search-input', updatedTitle);

    await page.waitForFunction(
      (title) =>
        [...document.querySelectorAll('.schools-page__table tbody tr')]
          .some(tr => tr.innerText.includes(title)),
      {},
      updatedTitle
    );
    console.log('   ✓ Updated unit found');

    // ========================================
    // Step 8: Show unit
    // ========================================
    console.log('📍 Step 8: Show unit');
    await page.evaluate((title) => {
      const rows = [...document.querySelectorAll('.schools-page__table tbody tr')];
      const row = rows.find(tr => tr.innerText.includes(title));
      const showBtn = row.querySelector('a.unit-action--show');
      if (!showBtn) throw new Error('Show button not found');
      showBtn.scrollIntoView({ block: 'center' });
      showBtn.click();
    }, updatedTitle);

    await page.waitForNavigation();
    console.log('   ✓ Unit show page opened');

    // ========================================
    // Step 9: Back to units list
    // ========================================
    console.log('📍 Step 9: Back to units list');
    await Promise.all([
      browser.waitForNavigation(),
      page.click('a[href="/admin/units"]'),
    ]);
    await page.waitForSelector('#units-search-input');
    console.log('   ✓ Back to units list');

    // ========================================
    // Step 10: Delete unit
    // ========================================
    console.log('📍 Step 10: Delete unit');
    await page.evaluate((title) => {
      const rows = [...document.querySelectorAll('.schools-page__table tbody tr')];
      const row = rows.find(tr => tr.innerText.includes(title));
      if (!row) throw new Error('Unit row not found');
      const deleteBtn = row.querySelector('button.unit-action--delete[data-action="delete-unit"]');
      if (!deleteBtn) throw new Error('Delete button not found');
      deleteBtn.scrollIntoView({ block: 'center' });
      deleteBtn.click();
    }, updatedTitle);

    await page.waitForSelector('#delete-unit-confirm-btn', { visible: true });
    await page.click('#delete-unit-confirm-btn');

    await page.waitForFunction(
      (title) =>
        ![...document.querySelectorAll('.schools-page__table tbody tr')]
          .some(tr => tr.innerText.includes(title)),
      {},
      updatedTitle
    );
    console.log('   ✓ Unit deleted');

    console.log('\n✅ CREATE UNIT TEST PASSED\n');
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
