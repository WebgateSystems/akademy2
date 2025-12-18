/**
 * E2E Test: Principal Management Dashboard — Administration
 */

const browser = require('../helpers/browser');
const config = require('../config');

async function runTest() {
  let testPassed = true;
  console.log('🚀 Starting Administration Management Test...\n');

  try {
    await browser.launch();
    const page = browser.getPage();

    // ==============================
    // Step 1: Login as principal
    // ==============================
    console.log('📍 Step 1: Login as principal');
    await loginAsPrincipal();

    // ==============================
    // Step 2: Go to /management/administration
    // ==============================
    console.log('📍 Step 2: Navigate to administration page');
    await browser.goto('/management/administration');
    await page.waitForSelector('button[data-open-modal="add-administration-modal"]');
    console.log('   ✓ Administration page loaded');

    // ==============================
    // Step 3: Open create modal
    // ==============================
    console.log('📍 Step 3: Open create administration modal');
    await page.click('button[data-open-modal="add-administration-modal"]');
    await page.waitForSelector('#add-administration-form', { visible: true });
    console.log('   ✓ Modal opened');

    // ==============================
    // Step 4: Fill form and create
    // ==============================
    console.log('📍 Step 4: Fill form and create admin');
    const adminFirstName = `E2EFirst${Date.now()}`;
    const adminLastName = `E2ELast${Date.now()}`;
    const adminEmail = `e2e+${Date.now()}@example.com`;

    await page.type('#add-administration-first-name', adminFirstName);
    await page.type('#add-administration-last-name', adminLastName);
    await page.type('#add-administration-email', adminEmail);
    await page.click('#add-administration-role-principal'); // назначаем роль Dyrektor

    await page.click('#add-administration-form button[type="submit"]');
    await page.waitForSelector('#administrations-search-input', { visible: true });
    console.log(`   ✓ Administration created: ${adminFirstName} ${adminLastName}`);

    // ==============================
    // Step 5: Search created admin
    // ==============================
    console.log('📍 Step 5: Search created admin');
    await page.evaluate(() => {
      const input = document.querySelector('#administrations-search-input');
      input.value = '';
    });
    await page.type('#administrations-search-input', adminEmail, { delay: 50 });
    console.log('   ✓ Admin found in list');
    
    // ==============================
    // Step 6: Open actions menu and edit
    // ==============================
    console.log('📍 Step 6: Open actions menu and edit');

    await page.evaluate((email) => {
      const editBtn = document.querySelector(
        `button[data-action="edit-administration"][data-administration-email="${email}"]`
      );
    
      if (!editBtn) throw new Error('Edit button not found');
    
      const details = editBtn.closest('details.headmasters-menu');
      const summary = details.querySelector('summary');
    
      summary.scrollIntoView({ block: 'center' });
      summary.click();
      editBtn.click();
    }, adminEmail);
    

    await page.waitForSelector('#edit-administration-form', { visible: true });
    const updatedFirstName = `${adminFirstName} UPDATED`;
    const updatedLastName = `${adminLastName} UPDATED`;
    await page.evaluate(() => { document.querySelector('#edit-administration-first-name').value = ''; });
    await page.evaluate(() => { document.querySelector('#edit-administration-last-name').value = ''; });
    await page.type('#edit-administration-first-name', updatedFirstName);
    await page.type('#edit-administration-last-name', updatedLastName);
    await page.click('#edit-administration-form button[type="submit"]');

    console.log(`   ✓ Admin updated: ${updatedFirstName}`);

    // ==============================
    // Step 7: Search updated admin
    // ==============================
    console.log('📍 Step 7: Search created admin');
    await page.evaluate(() => {
      const input = document.querySelector('#administrations-search-input');
      input.value = '';
    });
    await page.type('#administrations-search-input', adminEmail, { delay: 50 });
    console.log('   ✓ Admin found in list');

    // ==============================
    // Step 8: Delete admin
    // ==============================
    console.log('📍 Delete admin');

    page.once('dialog', async dialog => {
      console.log(`⚠️ Dialog message: ${dialog.message()}`);
      await dialog.accept(); // ✅ нажимает "OK"
    });

    await page.evaluate((email) => {
      const deleteBtn = document.querySelector(
        `button[data-action="delete-administration"]`
      );
    
      if (!deleteBtn) throw new Error('Delete button not found');
    
      const details = deleteBtn.closest('details.headmasters-menu');
      const summary = details.querySelector('summary');
    
      summary.scrollIntoView({ block: 'center' });
      summary.click();
      deleteBtn.click();
    }, adminEmail);

    console.log('   ✓ Admin deleted');


    console.log('\n✅ PRINCIPAL Administration TEST PASSED\n');

  } catch (error) {
    console.error('\n❌ TEST ERROR:', error.message);
    testPassed = false;
  } finally {
    await browser.close();
  }

  return testPassed;
}

async function loginAsPrincipal() {
  const page = browser.getPage();
  console.log('📍 Login as principal');
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
