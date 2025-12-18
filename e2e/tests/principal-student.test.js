/**
 * E2E Test: Principal Management Dashboard — Students
 */

const browser = require('../helpers/browser');
const config = require('../config');

async function runTest() {
  let testPassed = true;
  console.log('🚀 Starting Students Management Test...\n');

  try {
    await browser.launch();
    const page = browser.getPage();

    // ==============================
    // Step 1: Login as principal
    // ==============================
    console.log('📍 Step 1: Login as principal');
    await loginAsPrincipal();

    // ==============================
    // Step 2: Navigate to students page
    // ==============================
    console.log('📍 Step 2: Navigate to /management/students');
    await browser.goto('/management/students');
    await page.waitForSelector('button[data-open-modal="add-student-modal"]');
    console.log('   ✓ Students page loaded');

    // ==============================
    // Step 3: Open create student modal
    // ==============================
    console.log('📍 Step 3: Open create student modal');
    await page.click('button[data-open-modal="add-student-modal"]');
    await page.waitForSelector('#add-student-form', { visible: true });
    console.log('   ✓ Modal opened');

    // ==============================
    // Step 4: Create student
    // ==============================
    console.log('📍 Step 4: Fill form and create student');

    const studentFirstName = `E2EStudent${Date.now()}`;
    const studentLastName  = `Test${Date.now()}`;
    const studentEmail     = `e2e.student.${Date.now()}@example.com`;

    await page.type('#add-student-first-name', studentFirstName);
    await page.type('#add-student-last-name', studentLastName);
    await page.type('#add-student-email', studentEmail);

    const classSelectExists = await page.$('#add-student-class');
    if (classSelectExists) {
      await page.select('#add-student-class', await page.evaluate(() => {
        const select = document.querySelector('#add-student-class');
        return select.options.length > 1 ? select.options[1].value : '';
      }));
    }

    await page.click('#add-student-form button[type="submit"]');
    await page.waitForSelector('#students-search-input', { visible: true });

    console.log(`   ✓ Student created: ${studentEmail}`);

    // ==============================
    // Step 5: Search created student
    // ==============================
    console.log('📍 Step 5: Search created student');

    await page.evaluate(() => {
      document.querySelector('#students-search-input').value = '';
    });

    await page.type('#students-search-input', studentEmail, { delay: 50 });

    await page.waitForFunction(
      (email) =>
        [...document.querySelectorAll('tbody tr')]
          .some(tr => tr.innerText.includes(email)),
      { timeout: 20000 },
      studentEmail
    );

    console.log('   ✓ Student found in list');

    console.log('\n✅ STUDENTS Management TEST PASSED\n');

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
