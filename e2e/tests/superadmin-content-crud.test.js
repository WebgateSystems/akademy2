/**
 * E2E Test: Superadmin creates Content, edits, shows, and deletes it
 */

const browser = require('../helpers/browser');
const config = require('../config');

async function runTest() {
  let testPassed = false;
  console.log('🚀 Starting Create Content Test...\n');

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
    // Step 2: Go to /admin/contents
    // ========================================
    console.log('📍 Step 2: Navigate to /admin/contents');
    await browser.goto('/admin/contents');
    await page.waitForSelector('a[href="/admin/contents/new"]');
    console.log('   ✓ Contents page loaded');

    // ========================================
    // Step 3: Open create content page
    // ========================================
    console.log('📍 Step 3: Open create content page');
    await Promise.all([
      browser.waitForNavigation(),
      page.click('a[href="/admin/contents/new"]'),
    ]);
    await page.waitForSelector('form#content-form');
    console.log('   ✓ Create content page opened');

    // ========================================
    // Step 4: Create content
    // ========================================
    console.log('📍 Step 4: Create content');
    const contentTitle = `E2E Content ${Date.now()}`;
    const moduleId = 'a1a1a1a1-a1a1-a1a1-a1a1-a1a1a1a1a1a1'; // пример
    const contentType = 'video';

    await page.select('#content-type-select', contentType);
    await page.type('#content_title', contentTitle);
    await page.select('#content_learning_module_id', moduleId);

    // если есть специфические поля видео
    await page.type('#content_youtube_url', 'https://youtube.com/watch?v=dQw4w9WgXcQ');
    await page.type('#content_duration_sec', '120');

    await Promise.all([
      browser.waitForNavigation(),
      page.click('input[type="submit"][value="Utwórz"]'),
    ]);
    console.log(`   ✓ Content created: ${contentTitle}`);

    // ========================================
    // Step 5: Search content
    // ========================================
    console.log('📍 Step 5: Search content');
    await page.waitForSelector('#contents-search-input', { visible: true });
    await page.evaluate(() => { document.querySelector('#contents-search-input').value = ''; });
    await page.type('#contents-search-input', contentTitle);

    await page.waitForFunction(
      (title) =>
        [...document.querySelectorAll('.schools-page__table tbody tr')]
          .some(tr => tr.innerText.includes(title)),
      {},
      contentTitle
    );
    console.log('   ✓ Content found');

    // ========================================
    // Step 6: Edit content
    // ========================================
    console.log('📍 Step 6: Edit content');
    const updatedTitle = `${contentTitle} UPDATED`;

    await page.evaluate((title) => {
      const rows = [...document.querySelectorAll('.schools-page__table tbody tr')];
      const row = rows.find(tr => tr.innerText.includes(title));
      if (!row) throw new Error('Content row not found');
      const editBtn = row.querySelector('a.content-action--edit');
      if (!editBtn) throw new Error('Edit button not found');
      editBtn.scrollIntoView({ block: 'center' });
      editBtn.click();
    }, contentTitle);

    await page.waitForSelector('#content_title', { visible: true });
    await page.evaluate(() => { document.querySelector('#content_title').value = ''; });
    await page.type('#content_title', updatedTitle);

    await Promise.all([
      browser.waitForNavigation(),
      page.click('button[type="submit"].schools-page__add'),
    ]);
    console.log(`   ✓ Content updated: ${updatedTitle}`);

    // ========================================
    // Step 7: Search updated content
    // ========================================
    console.log('📍 Step 7: Search updated content');
    await page.evaluate(() => { document.querySelector('#contents-search-input').value = ''; });
    await page.type('#contents-search-input', updatedTitle);

    await page.waitForFunction(
      (title) =>
        [...document.querySelectorAll('.schools-page__table tbody tr')]
          .some(tr => tr.innerText.includes(title)),
      {},
      updatedTitle
    );
    console.log('   ✓ Updated content found');

    // ========================================
    // Step 8: Show content
    // ========================================
    console.log('📍 Step 8: Show content');
    await page.evaluate((title) => {
      const rows = [...document.querySelectorAll('.schools-page__table tbody tr')];
      const row = rows.find(tr => tr.innerText.includes(title));
      const showBtn = row.querySelector('a.content-action--show');
      if (!showBtn) throw new Error('Show button not found');
      showBtn.scrollIntoView({ block: 'center' });
      showBtn.click();
    }, updatedTitle);

    await page.waitForNavigation();
    console.log('   ✓ Content show page opened');

    // ========================================
    // Step 9: Back to contents list
    // ========================================
    console.log('📍 Step 9: Back to contents list');
    await Promise.all([
      browser.waitForNavigation(),
      page.click('a[href="/admin/contents"]'),
    ]);
    await page.waitForSelector('#contents-search-input');
    console.log('   ✓ Back to contents list');

    // ========================================
    // Step 10: Delete content
    // ========================================
    console.log('📍 Step 10: Delete content');
    await page.evaluate((title) => {
      const rows = [...document.querySelectorAll('.schools-page__table tbody tr')];
      const row = rows.find(tr => tr.innerText.includes(title));
      if (!row) throw new Error('Content row not found');
      const deleteBtn = row.querySelector('button.content-action--delete[data-action="delete-content"]');
      if (!deleteBtn) throw new Error('Delete button not found');
      deleteBtn.scrollIntoView({ block: 'center' });
      deleteBtn.click();
    }, updatedTitle);

    await page.waitForSelector('#delete-content-confirm-btn', { visible: true });
    await page.click('#delete-content-confirm-btn');

    await page.waitForFunction(
      (title) =>
        ![...document.querySelectorAll('.schools-page__table tbody tr')]
          .some(tr => tr.innerText.includes(title)),
      {},
      updatedTitle
    );
    console.log('   ✓ Content deleted');

    console.log('\n✅ CREATE CONTENT TEST PASSED\n');
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
