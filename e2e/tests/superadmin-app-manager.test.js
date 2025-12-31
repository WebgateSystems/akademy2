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
    // Step 6: Verify search functionality
    // ========================================
    console.log('📍 Step 6: Verify search functionality');

    const searchInputSelector = '#app-managers-search-input';
    await page.waitForSelector(searchInputSelector, { visible: true, timeout: 5000 });

    await page.focus(searchInputSelector);
    await page.evaluate((selector) => { document.querySelector(selector).value = ''; }, searchInputSelector);
    await page.type(searchInputSelector, managerEmail);

    await browser.sleep(pause().mediumPause);

    const searchResultExists = await page.evaluate((email) => {
      return Array.from(document.body.innerText.split('\n')).some((text) =>
        text.includes(email)
      );
    }, managerEmail);

    if (!searchResultExists) {
      throw new Error(`App manager with email "${managerEmail}" not found in table after search`);
    }

    console.log('   ✓ App manager found via search input');

    // ========================================
    // Step 7: Open actions menu for created app manager
    // ========================================
    console.log('📍 Step 7: Open actions menu for created app manager');

    const openMenuForManager = await page.evaluate((email) => {
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

    if (!openMenuForManager) {
      throw new Error(`Actions menu for app manager "${managerEmail}" not found`);
    }

    await browser.sleep(pause().smallPause);
    console.log('   ✓ Actions menu opened');

    // ========================================
    // Step 8: Edit app manager
    // ========================================
    console.log('📍 Step 8: Edit app manager');

    const editLinkClicked = await page.evaluate((email) => {
      const rows = Array.from(document.querySelectorAll('tr'));

      for (const row of rows) {
        if (row.innerText.includes(email)) {
          // Ensure menu is open
          const details = row.querySelector('details.headmasters-menu');
          if (details && !details.open) {
            const summary = details.querySelector('summary');
            if (summary) summary.click();
          }
          
          const editLink = row.querySelector('a.dropdown-link[href*="/edit"]');
          if (editLink) {
            editLink.click();
            return true;
          }
        }
      }
      return false;
    }, managerEmail);

    if (!editLinkClicked) {
      throw new Error(`Edit link for app manager "${managerEmail}" not found`);
    }

    await browser.waitForNavigation();
    await browser.waitFor('#app-manager-form', 5000);

    console.log('   ✓ Edit page loaded');

    const updatedFirstName = `${managerFirstName} UPDATED`;
    const updatedPhone = '+48987654321';

    await page.evaluate(() => {
      const firstNameInput = document.querySelector('input[name="user[first_name]"]');
      if (firstNameInput) firstNameInput.value = '';
    });

    await browser.type('input[name="user[first_name]"]', updatedFirstName);
    
    await page.evaluate(() => {
      const phoneInput = document.querySelector('input[name="user[metadata][phone]"]');
      if (phoneInput) phoneInput.value = '';
    });

    await browser.type('input[name="user[metadata][phone]"]', updatedPhone);

    console.log(`   ✓ Form updated (first name: "${updatedFirstName}", phone: "${updatedPhone}")`);

    // Submit edit form
    await Promise.all([
      browser.waitForNavigation().catch(() => {}),
      page.click('button[form="app-manager-form"]'),
    ]);

    await browser.sleep(pause().mediumPause);

    console.log('   ✓ App manager updated');

    // ========================================
    // Step 9: Verify app manager was edited
    // ========================================
    console.log('📍 Step 9: Verify app manager was edited');

    await page.waitForSelector(searchInputSelector, { visible: true, timeout: 5000 });

    await page.focus(searchInputSelector);
    await page.evaluate((selector) => {
      document.querySelector(selector).value = '';
    }, searchInputSelector);
    await page.type(searchInputSelector, managerEmail);
    await browser.sleep(pause().mediumPause);

    const updatedFound = await page.evaluate((email, updatedFirstName) => {
      const rows = Array.from(document.querySelectorAll('tr'));
      for (const row of rows) {
        if (row.innerText.includes(email) && row.innerText.includes(updatedFirstName)) {
          return true;
        }
      }
      return false;
    }, managerEmail, updatedFirstName);

    if (!updatedFound) {
      throw new Error(`Updated app manager with email "${managerEmail}" and name "${updatedFirstName}" not found`);
    }

    console.log('   ✓ Edited app manager found via search');

    // ========================================
    // Step 10: Deactivate app manager
    // ========================================
    console.log('📍 Step 10: Deactivate app manager');

    // Reopen actions menu for the app manager
    const reopenMenuForManager = await page.evaluate((email) => {
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

    if (!reopenMenuForManager) {
      throw new Error(`Actions menu for app manager "${managerEmail}" not found`);
    }

    await browser.sleep(pause().smallPause);

    const deactivateClicked = await page.evaluate((email) => {
      const rows = Array.from(document.querySelectorAll('tr'));

      for (const row of rows) {
        if (row.innerText.includes(email)) {
          // Find the lock/deactivate form (button with text "Zablokuj")
          const forms = row.querySelectorAll('form.inline-form');
          
          for (const form of forms) {
            const button = form.querySelector('button[type="submit"]');
            if (button && (button.textContent.includes('Zablokuj') || button.textContent.includes('Blokuj'))) {
              button.click();
              return true;
            }
          }
        }
      }
      return false;
    }, managerEmail);

    if (!deactivateClicked) {
      throw new Error(`Deactivate button for app manager "${managerEmail}" not found`);
    }

    await Promise.all([
      browser.waitForNavigation().catch(() => {}),
      browser.sleep(pause().smallPause),
    ]);

    await browser.sleep(pause().mediumPause);
    console.log('   ✓ App manager deactivated');

    // ========================================
    // Step 11: Verify app manager was deactivated
    // ========================================
    console.log('📍 Step 11: Verify app manager was deactivated');

    await page.waitForSelector(searchInputSelector, { visible: true, timeout: 5000 });

    await page.focus(searchInputSelector);
    await page.evaluate((selector) => {
      document.querySelector(selector).value = '';
    }, searchInputSelector);
    await page.type(searchInputSelector, managerEmail);
    await browser.sleep(pause().mediumPause);

    const isDeactivated = await page.evaluate((email) => {
      const rows = Array.from(document.querySelectorAll('tr'));

      for (const row of rows) {
        if (row.innerText.includes(email)) {
          // Check if status column shows inactive (in Polish: "Nieaktywny" or similar)
          const statusText = row.innerText;
          // Look for inactive indicators
          if (statusText.match(/nieaktywn|inactive|zablokowan/i)) {
            return true;
          }
        }
      }
      return false;
    }, managerEmail);

    if (!isDeactivated) {
      throw new Error(`App manager with email "${managerEmail}" was not deactivated (status not found as inactive)`);
    }

    console.log('   ✓ App manager status shows as deactivated');

    // ========================================
    // Step 12: Delete app manager
    // ========================================
    console.log('📍 Step 12: Delete app manager');

    // Reopen actions menu for deletion
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

    // Устанавливаем обработчик диалога ДО клика
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
          // Найти все формы внутри этого ряда
          const forms = row.querySelectorAll('form.inline-form');
          
          for (const form of forms) {
            // Проверяем, что это форма удаления (имеет method="delete")
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

    // ========================================
    // Step 13: Verify app manager was deleted
    // ========================================
    console.log('📍 Step 13: Verify app manager was deleted');

    await page.waitForSelector(searchInputSelector, { visible: true, timeout: 5000 });

    await page.focus(searchInputSelector);
    await page.evaluate((selector) => {
      document.querySelector(selector).value = '';
    }, searchInputSelector);
    await page.type(searchInputSelector, managerEmail);
    await browser.sleep(pause().mediumPause);

    const managerStillExists = await page.evaluate((email) => {
      const rows = Array.from(document.querySelectorAll('tr'));
      return rows.some(row => row.innerText.includes(email));
    }, managerEmail);

    if (managerStillExists) {
      throw new Error(`App manager with email "${managerEmail}" still exists after deletion`);
    }

    console.log('   ✓ App manager successfully deleted');
    
    console.log('\n✅ CREATE, EDIT, DEACTIVATE AND DELETE APP MANAGER TEST PASSED\n');
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

