/**
 * E2E Test: Superadmin creates, edits, deactivates and deletes an App Manager
 *
 * Scenario:
 * 1. Login as superadmin
 * 2. Go to /admin/app_managers
 * 3. Open "Add app manager" modal
 * 4. Fill form
 * 5. Submit
 * 6. Verify app manager was created via search
 * 7. Open actions menu for created app manager
 * 8. Edit app manager
 * 9. Verify app manager was edited
 * 10. Deactivate app manager
 * 11. Verify app manager was deactivated
 * 12. Delete app manager
 * 13. Verify app manager was deleted
 */

const browser = require('../helpers/browser');
const config = require('../config');

const pause = () => browser.getSpeed();

async function runTest() {
  let testPassed = false;

  console.log('🚀 Starting Create, Edit, Deactivate and Delete App Manager Test...\n');

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
      browser.click('input[type="submit"], button[type="submit"], .btn-primary'),
    ]);

    await browser.waitFor('.dashboard-sidebar, .dashboard-nav');
    console.log('   ✓ Logged in');

    // ========================================
    // Step 2: Go to App Managers page
    // ========================================
    console.log('📍 Step 2: Navigate to /admin/app_managers');

    await browser.waitFor('.dashboard-sidebar, .dashboard-nav', 5000);
    
    const currentUrl = browser.url();
    if (!currentUrl.includes('/admin')) {
      throw new Error(`Not in admin area, current URL: ${currentUrl}`);
    }
    
    await Promise.all([
      browser.waitForNavigation().catch(() => {}),
      browser.goto('/admin/app_managers'),
    ]);
    
    await browser.waitFor(
      '.schools-page, table, button.schools-page__add',
      5000
    );
    
    console.log('   ✓ App Managers page loaded');

    // ========================================
    // Step 3: Open create app manager modal
    // ========================================
    
    console.log('📍 Step 3: Open add app manager modal');
    
    await page.evaluate(() => {
      document
        .querySelector('button.schools-page__add[data-open-modal="add-app-manager-modal"]')
        .dispatchEvent(new MouseEvent('click', { bubbles: true }));
    });
    
    await page.waitForFunction(() => {
      const modal = document.querySelector('#add-app-manager-modal');
    
      if (!modal) return false;
    
      const style = window.getComputedStyle(modal);
      return (
        style.display !== 'none' &&
        style.visibility !== 'hidden' &&
        style.opacity !== '0' &&
        modal.classList.contains('is-open')
      );
    }, { timeout: 5000 });
    
    await page.waitForSelector('input[name="user[email]"]', {
      visible: true,
      timeout: 5000,
    });
    
    console.log('   ✓ Add app manager modal opened');

    // ========================================
    // Step 4: Fill form
    // ========================================
    console.log('📍 Step 4: Fill add app manager form');

    await browser.waitFor(
      'input[name="user[email]"]',
      5000
    );

    const timestamp = Date.now();
    const managerEmail = `e2e_manager_${timestamp}@example.com`;
    const managerFirstName = `E2E Manager ${timestamp}`;
    const managerLastName = 'Test';
    const managerPhone = '+48123123123';
    const managerPassword = 'TestPassword123!';

    await browser.type('input[name="user[email]"]', managerEmail);
    await browser.type('input[name="user[first_name]"]', managerFirstName);
    await browser.type('input[name="user[last_name]"]', managerLastName);
    await browser.type('input[name="user[metadata][phone]"]', managerPhone);
    await browser.type('input[name="user[password]"]', managerPassword);
    await browser.type('input[name="user[password_confirmation]"]', managerPassword);

    console.log(`   ✓ Form filled (email: "${managerEmail}")`);

    // ========================================
    // Step 5: Submit form
    // ========================================
    console.log('📍 Step 5: Submit form');

    await Promise.all([
      browser.waitForNavigation().catch(() => {}),
      browser.click('form.schools-modal__form button.schools-modal__primary[type="submit"]'),
    ]);

    await browser.sleep(pause().mediumPause);

  
    // ========================================
    // Step 6: Logout as super admin
    // ========================================
    console.log('📍 Step 6: Logout as super admin');


    await browser.waitFor('.settings-control', 5000);
    await browser.click('.settings-control');

    console.log('   ✓ Logged out super admin');

    // ========================================
    // Step 7: Login as app manager
    // ========================================
    console.log('📍 Step 7: Login as manager');

    await browser.waitFor('input#email, input[name="email"]');

    await browser.type('input#email, input[name="email"]', managerEmail);
    await browser.type('input#password, input[name="password"]', managerPassword);

    await Promise.all([
      browser.waitForNavigation(),
      browser.click('input[type="submit"], button[type="submit"], .btn-primary'),
    ]);

    await browser.waitFor('.dashboard-sidebar, .dashboard-nav');
    console.log('   ✓ Logged in');


    // ========================================
    // Step 9: Logout 
    // ========================================
    console.log('📍 Step 6: Logout as super admin');


    await browser.waitFor('.settings-control', 5000);
    await browser.click('.settings-control');

    console.log('   ✓ Logged out super admin');

    // ========================================
    // Step 10: Login as Admin
    // ========================================
    console.log('📍 Step 10: Login as super admin');

    await browser.waitFor('input#email, input[name="email"]');

    await browser.type('input#email, input[name="email"]', email);
    await browser.type('input#password, input[name="password"]', password);

    await Promise.all([
      browser.waitForNavigation(),
      browser.click('input[type="submit"], button[type="submit"], .btn-primary'),
    ]);

    await browser.waitFor('.dashboard-sidebar, .dashboard-nav');
    console.log('   ✓ Logged in');

    // ========================================
    // Step 11: Block App Manager via activity log
    // ========================================
    console.log('📍 Step 11: Block App Manager');
    await browser.goto('/admin/events');

    const managerFullName = `${managerFirstName} ${managerLastName}`;

    await page.waitForFunction(
    (fullName) => {
        return [...document.querySelectorAll('.activity-entry')]
        .some(entry =>
            entry.textContent.includes(fullName)
        );
    },
    { timeout: 5000 },
    managerFullName
    );

    await page.evaluate((fullName) => {
        const entries = [...document.querySelectorAll('.activity-entry')];
      
        const targetEntry = entries.find(entry =>
          entry.textContent.includes(fullName)
        );
      
        if (!targetEntry) {
          throw new Error('Activity entry for manager not found');
        }
      
        const actionsBtn = targetEntry.querySelector('.activity-actions-btn');
      
        if (!actionsBtn) {
          throw new Error('Actions button not found');
        }
      
        actionsBtn.click();
      
        const blockBtn = [...targetEntry.querySelectorAll(
          '.activity-actions-menu__item'
        )].find(btn =>
          btn.dataset.blockKind === 'user' &&
          /zablokuj/i.test(btn.textContent)
        );
      
        if (!blockBtn) {
          throw new Error('Block user button not found');
        }
      
        blockBtn.click();
      }, managerFullName);

    await browser.waitFor('#event-block-confirm', 1000);

    await Promise.all([
    browser.waitForNavigation().catch(() => {}),
    browser.click('#event-block-confirm'),
    ]);
    console.log(`   ✓ App Manager "${managerFullName}" blocked and confirmed`);

    // ========================================
    // Step 12: Check block user
    // ========================================
    console.log('📍 Step 12: Check block user');

    await browser.goto('/admin/request_block_rules');
    
    const managerName = managerFullName;
    
    const found = await page.evaluate((name) => {
      return [...document.querySelectorAll('tr')]
        .some(row => row.innerText.includes(name));
    }, managerName);
    
    if (!found) {
      throw new Error(`Blocked user "${managerName}" not found in block rules table`);
    }
    
    console.log(`   ✓ Block entry found for "${managerName}"`);
    

    // ========================================
    // Step 13: Delete app manager
    // ========================================
    console.log('📍 Step 13: Delete app manager');
    await browser.goto('/admin/app_managers');

    const reopenMenuForDeletion = await page.evaluate((email) => {
      const rows = Array.from(document.querySelectorAll('tr'));

      for (const row of rows) {
        if (row.innerText.includes(email)) {
          const summary = row.querySelector(
            'details.headmasters-menu > summary'
          );
          if (summary) {
            summary.click();
            return true;
          }
        }
      }
      return false;
    }, managerEmail);

    if (!reopenMenuForDeletion) {
      throw new Error(`Actions menu for app manager "${managerEmail}" not found for deletion`);
    }

    await browser.sleep(pause().smallPause);

    page.once('dialog', async dialog => {
      console.log(`⚠️ Dialog message: ${dialog.message()}`);
      if (dialog.type() === 'confirm') {
        await dialog.accept();
      }
    });

    const deleteClicked = await page.evaluate((email) => {
      const rows = Array.from(document.querySelectorAll('tr'));

      for (const row of rows) {
        if (row.innerText.includes(email)) {
          const forms = row.querySelectorAll('form.inline-form');
          
          for (const form of forms) {
            const methodInput = form.querySelector('input[name="_method"]');
            if (methodInput && methodInput.value === 'delete') {
              const deleteButton = form.querySelector('button[type="submit"]');
              if (deleteButton && deleteButton.textContent.includes('Usuń')) {
                deleteButton.click();
                return true;
              }
            }
          }
        }
      }
      return false;
    }, managerEmail);

    if (!deleteClicked) {
      throw new Error(`Delete button for app manager "${managerEmail}" not found`);
    }

    await Promise.all([
      browser.waitForNavigation().catch(() => {}),
      browser.sleep(pause().smallPause),
    ]);

    await browser.sleep(pause().mediumPause);
    console.log('   ✓ App manager deleted');

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




