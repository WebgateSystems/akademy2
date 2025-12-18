/**
 * E2E Test: Superadmin CRUD Subject
 */

const browser = require('../helpers/browser');
const config = require('../config');

async function runTest() {
  let testPassed = false;

  console.log('🚀 Starting Subject CRUD Test...\n');

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
    // Step 2: Go to /admin/subjects
    // ========================================
    console.log('📍 Step 2: Navigate to /admin/subjects');

    await browser.goto('/admin/subjects');
    await page.waitForSelector('a[href="/admin/subjects/new"]');

    console.log('   ✓ Subjects page loaded');

    // ========================================
    // Step 3: Create subject
    // ========================================
    console.log('📍 Step 3: Create subject');

    await Promise.all([
      browser.waitForNavigation(),
      page.click('a[href="/admin/subjects/new"]'),
    ]);

    const subjectTitle = `E2E Subject ${Date.now()}`;
    const updatedTitle = `${subjectTitle} UPDATED`;

    await page.type('#subject_title', subjectTitle);
    await page.type('#subject_description', 'E2E subject description');

    await Promise.all([
      browser.waitForNavigation(),
      page.click('input[type="submit"][value="Utwórz"]'),
    ]);

    console.log(`   ✓ Subject created: ${subjectTitle}`);

    // ========================================
    // Step 4: Search subject
    // ========================================
    console.log('📍 Step 4: Search subject');

    await page.type('#subjects-search-input', subjectTitle);

    await page.waitForFunction(
      (title) =>
        [...document.querySelectorAll('.schools-page__table tbody tr')]
          .some(tr => tr.innerText.includes(title)),
      {},
      subjectTitle
    );

    console.log('   ✓ Subject found');

    // ========================================
    // Step 5: Edit subject
    // ========================================
    console.log('📍 Step 5: Edit subject');

    await page.evaluate((title) => {
    const rows = [...document.querySelectorAll('.schools-page__table tbody tr')];
    const row = rows.find(tr => tr.innerText.includes(title));

    if (!row) throw new Error('Subject row not found');

    const editBtn = row.querySelector('.subject-action--edit');
    if (!editBtn) throw new Error('Edit button not found');

    editBtn.scrollIntoView({ block: 'center' });
    editBtn.click();
    }, subjectTitle);

    await page.waitForSelector('#subject_title', { visible: true });

    await page.evaluate(() => {
    document.querySelector('#subject_title').value = '';
    });
    await page.type('#subject_title', updatedTitle);

    const saveBtnSelector =
    'button.schools-page__add[form="subject-form"][type="submit"]';
  
    await page.waitForSelector(saveBtnSelector, { visible: true });
    
    await page.evaluate((selector) => {
        const btn = document.querySelector(selector);
        btn.scrollIntoView({ block: 'center' });
    }, saveBtnSelector);
    
    await Promise.all([
        browser.waitForNavigation(),
        page.click(saveBtnSelector),
    ]);

    console.log(`   ✓ Subject updated: ${updatedTitle}`);

    // ========================================
    // Step 6: Search updated subject
    // ========================================
    console.log('📍 Step 6: Search updated subject');

    await page.evaluate(() => {
      document.querySelector('#subjects-search-input').value = '';
    });
    await page.type('#subjects-search-input', updatedTitle);

    await page.waitForFunction(
      (title) =>
        [...document.querySelectorAll('.schools-page__table tbody tr')]
          .some(tr => tr.innerText.includes(title)),
      {},
      updatedTitle
    );

    console.log('   ✓ Updated subject found');

    // ========================================
    // Step 7: Show subject
    // ========================================
    console.log('📍 Step 7: Show subject');

    await page.waitForFunction(
    (title) => {
        const rows = [...document.querySelectorAll('.schools-page__table tbody tr')];
        const row = rows.find(tr => tr.innerText.includes(title));
        if (!row) return false;

        return !!row.querySelector('.subject-action--show');
    },
    { timeout: 7000 },
    updatedTitle
    );

    await page.evaluate((title) => {
    const rows = [...document.querySelectorAll('.schools-page__table tbody tr')];
    const row = rows.find(tr => tr.innerText.includes(title));
    if (!row) throw new Error('Subject row not found');

    const showBtn = row.querySelector('.subject-action--show');
    if (!showBtn) throw new Error('Show button not found');

    showBtn.scrollIntoView({ block: 'center' });
    showBtn.click();
    }, updatedTitle);

    await page.waitForNavigation();

    console.log('   ✓ Subject show page opened');

    // ========================================
    // Step 8: Back to list
    // ========================================
    console.log('📍 Step 8: Back to subjects list');

    await Promise.all([
      browser.waitForNavigation(),
      page.click('a[href="/admin/subjects"]'),
    ]);

    await page.waitForSelector('#subjects-search-input');

    // ========================================
    // Step 9: Delete subject
    // ========================================
    console.log('📍 Step 9: Delete subject');

    await page.waitForFunction(
    (title) => {
        const rows = [...document.querySelectorAll('.schools-page__table tbody tr')];
        const row = rows.find(tr => tr.innerText.includes(title));
        if (!row) return false;

        return !!row.querySelector(
        'button.subject-action--delete[data-action="delete-subject"]'
        );
    },
    { timeout: 7000 },
    updatedTitle
    );

    await page.evaluate((title) => {
    const rows = [...document.querySelectorAll('.schools-page__table tbody tr')];
    const row = rows.find(tr => tr.innerText.includes(title));
    if (!row) throw new Error('Subject row not found');

    const deleteBtn = row.querySelector(
        'button.subject-action--delete[data-action="delete-subject"]'
    );
    if (!deleteBtn) throw new Error('Delete button not found');

    deleteBtn.scrollIntoView({ block: 'center' });
    deleteBtn.click();
    }, updatedTitle);

    console.log('   ✓ Delete modal opened');

    // ========================================
    // Step 10: Confirm delete
    // ========================================
    console.log('📍 Step 10: Confirm delete');

    await page.waitForSelector('#delete-subject-confirm-btn', {
    visible: true,
    timeout: 5000,
    });

    await page.click('#delete-subject-confirm-btn');

    await page.waitForFunction(
    (title) =>
        ![...document.querySelectorAll('.schools-page__table tbody tr')]
        .some(tr => tr.innerText.includes(title)),
    { timeout: 7000 },
    updatedTitle
    );

    console.log('   ✓ Subject deleted');

    console.log('\n✅ SUBJECT CRUD TEST PASSED\n');
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
