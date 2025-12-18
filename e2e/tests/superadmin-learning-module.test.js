/**
 * E2E Test: Superadmin creates Learning Module, edits, shows, and deletes it
 */

const browser = require('../helpers/browser');
const config = require('../config');

async function runTest() {
  let testPassed = false;
  console.log('🚀 Starting Create Learning Module Test...\n');

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
    // Step 2: Go to /admin/learning_modules
    // ========================================
    console.log('📍 Step 2: Navigate to /admin/learning_modules');
    await browser.goto('/admin/learning_modules');
    await page.waitForSelector('a[href="/admin/learning_modules/new"]');
    console.log('   ✓ Learning Modules page loaded');

    // ========================================
    // Step 3: Open create learning module page
    // ========================================
    console.log('📍 Step 3: Open create learning module page');
    await Promise.all([
      browser.waitForNavigation(),
      page.click('a[href="/admin/learning_modules/new"]'),
    ]);
    await page.waitForSelector('form[action="/admin/learning_modules"]');
    console.log('   ✓ Create learning module page opened');

    // ========================================
    // Step 4: Create learning module
    // ========================================
    console.log('📍 Step 4: Create learning module');
    const moduleTitle = `E2E Module ${Date.now()}`;
    const unitId = 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa'; // пример

    await page.type('#learning_module_title', moduleTitle);
    await page.select('#learning_module_unit_id', unitId);
    await page.click('#learning_module_published'); // если хотим опубликовать
    await page.click('#learning_module_single_flow'); // включаем/выключаем последовательный режим

    await Promise.all([
      browser.waitForNavigation(),
      page.click('input[type="submit"][value="Utwórz"]'),
    ]);
    console.log(`   ✓ Learning module created: ${moduleTitle}`);

    // ========================================
    // Step 5: Search module
    // ========================================
    console.log('📍 Step 5: Search module');
    await page.waitForSelector('#learning-modules-search-input', { visible: true });

    await page.evaluate(() => {
      document.querySelector('#learning-modules-search-input').value = '';
    });
    await page.type('#learning-modules-search-input', moduleTitle);

    await page.waitForFunction(
      (title) =>
        [...document.querySelectorAll('.schools-page__table tbody tr')]
          .some(tr => tr.innerText.includes(title)),
      {},
      moduleTitle
    );
    console.log('   ✓ Learning module found');

    // ========================================
    // Step 6: Edit module
    // ========================================
    console.log('📍 Step 6: Edit module');
    const updatedTitle = `${moduleTitle} UPDATED`;

    await page.evaluate((title) => {
      const rows = [...document.querySelectorAll('.schools-page__table tbody tr')];
      const row = rows.find(tr => tr.innerText.includes(title));
      if (!row) throw new Error('Module row not found');
      const editBtn = row.querySelector('a.learning_module-action--edit');
      if (!editBtn) throw new Error('Edit button not found');
      editBtn.scrollIntoView({ block: 'center' });
      editBtn.click();
    }, moduleTitle);

    await page.waitForSelector('#learning_module_title', { visible: true });
    await page.evaluate(() => { document.querySelector('#learning_module_title').value = ''; });
    await page.type('#learning_module_title', updatedTitle);

    await Promise.all([
      browser.waitForNavigation(),
      page.click('button[type="submit"].schools-page__add'),
    ]);
    console.log(`   ✓ Learning module updated: ${updatedTitle}`);

    // ========================================
    // Step 7: Search updated module
    // ========================================
    console.log('📍 Step 7: Search updated module');
    await page.evaluate(() => { document.querySelector('#learning-modules-search-input').value = ''; });
    await page.type('#learning-modules-search-input', updatedTitle);

    await page.waitForFunction(
      (title) =>
        [...document.querySelectorAll('.schools-page__table tbody tr')]
          .some(tr => tr.innerText.includes(title)),
      {},
      updatedTitle
    );
    console.log('   ✓ Updated module found');

    // ========================================
    // Step 8: Show module
    // ========================================
    console.log('📍 Step 8: Show module');
    await page.evaluate((title) => {
      const rows = [...document.querySelectorAll('.schools-page__table tbody tr')];
      const row = rows.find(tr => tr.innerText.includes(title));
      const showBtn = row.querySelector('a.learning_module-action--show');
      if (!showBtn) throw new Error('Show button not found');
      showBtn.scrollIntoView({ block: 'center' });
      showBtn.click();
    }, updatedTitle);

    await page.waitForNavigation();
    console.log('   ✓ Learning module show page opened');

    // ========================================
    // Step 9: Back to modules list
    // ========================================
    console.log('📍 Step 9: Back to modules list');
    await Promise.all([
      browser.waitForNavigation(),
      page.click('a[href="/admin/learning_modules"]'),
    ]);
    await page.waitForSelector('#learning-modules-search-input');
    console.log('   ✓ Back to learning modules list');

    // ========================================
    // Step 10: Delete module
    // ========================================
    console.log('📍 Step 10: Delete module');
    await page.evaluate((title) => {
      const rows = [...document.querySelectorAll('.schools-page__table tbody tr')];
      const row = rows.find(tr => tr.innerText.includes(title));
      if (!row) throw new Error('Module row not found');
      const deleteBtn = row.querySelector('button.learning_module-action--delete[data-action="delete-learning-module"]');
      if (!deleteBtn) throw new Error('Delete button not found');
      deleteBtn.scrollIntoView({ block: 'center' });
      deleteBtn.click();
    }, updatedTitle);

    await page.waitForSelector('#delete-learning-module-confirm-btn', { visible: true });
    await page.click('#delete-learning-module-confirm-btn');

    await page.waitForFunction(
      (title) =>
        ![...document.querySelectorAll('.schools-page__table tbody tr')]
          .some(tr => tr.innerText.includes(title)),
      {},
      updatedTitle
    );
    console.log('   ✓ Learning module deleted');

    console.log('\n✅ CREATE LEARNING MODULE TEST PASSED\n');
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
