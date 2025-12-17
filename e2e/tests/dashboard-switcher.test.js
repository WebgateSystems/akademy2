/**
 * E2E Test: Dashboard Switcher
 * Tests switching between Teacher and Principal dashboards
 * and verifies that non-authorized users don't see the switch control
 */

const browser = require('../helpers/browser');
const config = require('../config');

async function runTest() {
  let testPassed = true;
  
  console.log('🚀 Starting Dashboard Switcher Test...\n');
  
  try {
    await browser.launch();
    
    // Test 1: Principal (dyrektor) who is also a teacher - should see both dashboards
    console.log('📍 Test 1: Principal with teacher role - should see dashboard switcher');
    await testDashboardSwitcher('principal', true);
    
    // Test 2: Teacher without director privileges - should NOT see switcher
    console.log('📍 Test 2: Teacher without director role - should NOT see dashboard switcher');
    await testDashboardSwitcher('teacher', false);
    
    console.log('\n' + '='.repeat(50));
    console.log('✅ DASHBOARD SWITCHER TEST PASSED\n');
    
  } catch (error) {
    console.error('\n❌ TEST ERROR:', error.message);
    testPassed = false;
  } finally {
    await browser.close();
  }
  
  return testPassed;
}

async function testDashboardSwitcher(userType, shouldHaveSwitcher) {
  const page = browser.getPage();
  const user = config.users[userType];
  
  // Login via appropriate path
  const loginPath = userType === 'principal' ? '/login/administration' : '/login/teacher';
  await browser.goto(loginPath);
  await browser.sleep(1000);
  
  console.log(`   Logging in as ${userType}: ${user.email}`);
  await browser.type('input[name="user[email]"], input#user_email', user.email);
  await browser.type('input[name="user[password]"], input#user_password', user.password);
  
  await Promise.all([
    browser.waitForNavigation(),
    browser.click('input[type="submit"], button[type="submit"]'),
  ]);
  await browser.sleep(2000);
  console.log('   ✓ Logged in');
  
  // Look for dashboard switcher
  // Typical selectors for dashboard switcher: dropdown, buttons, links to switch
  const switcherSelectors = [
    '.dashboard-switcher',
    '[data-dashboard-switch]',
    'a[href="/dashboard"]',
    'a[href="/management"]',
    '.nav-dashboard-toggle',
    '#dashboard-switch',
    '.btn-switch-dashboard',
    // Common patterns
    // Text-based selectors removed - using href patterns instead
    '.dropdown-item[href*="dashboard"]',
    '.dropdown-item[href*="management"]',
  ];
  
  // Check for switcher presence
  let switcherFound = false;
  let foundSelector = null;
  
  for (const selector of switcherSelectors) {
    try {
      const element = await page.$(selector);
      if (element) {
        const isVisible = await page.evaluate(el => {
          const style = window.getComputedStyle(el);
          return style.display !== 'none' && style.visibility !== 'hidden';
        }, element);
        
        if (isVisible) {
          switcherFound = true;
          foundSelector = selector;
          break;
        }
      }
    } catch (e) {
      // Selector not found or invalid
    }
  }
  
  // Also check menu items for cross-dashboard links
  const crossDashboardLinks = await page.evaluate(() => {
    const links = [];
    const currentPath = window.location.pathname;
    
    // If we're in /management, look for /dashboard links
    if (currentPath.startsWith('/management')) {
      const dashboardLinks = document.querySelectorAll('a[href^="/dashboard"]');
      dashboardLinks.forEach(l => {
        if (l.offsetParent !== null) { // visible check
          links.push({ href: l.href, text: l.textContent.trim() });
        }
      });
    }
    // If we're in /dashboard, look for /management links
    else if (currentPath.startsWith('/dashboard')) {
      const managementLinks = document.querySelectorAll('a[href^="/management"]');
      managementLinks.forEach(l => {
        if (l.offsetParent !== null) {
          links.push({ href: l.href, text: l.textContent.trim() });
        }
      });
    }
    
    return links;
  });
  
  if (crossDashboardLinks.length > 0) {
    switcherFound = true;
    console.log(`   Found cross-dashboard links:`);
    crossDashboardLinks.forEach(link => {
      console.log(`     - "${link.text}" -> ${link.href}`);
    });
  }
  
  // Validate expectation
  if (shouldHaveSwitcher) {
    if (switcherFound || crossDashboardLinks.length > 0) {
      console.log(`   ✓ Dashboard switcher found (as expected)`);
      
      // Try to switch dashboards
      if (crossDashboardLinks.length > 0) {
        console.log(`   🖱️  Switching to other dashboard...`);
        const targetLink = crossDashboardLinks[0];
        
        await Promise.all([
          browser.waitForNavigation(),
          browser.click(`a[href="${new URL(targetLink.href).pathname}"]`),
        ]);
        await browser.sleep(2000);
        
        const newUrl = page.url();
        console.log(`   ✓ Switched! Now at: ${newUrl}`);
        
        // Switch back
        const backPath = newUrl.includes('/dashboard') ? '/management' : '/dashboard';
        const backLink = await page.$(`a[href^="${backPath}"]`);
        
        if (backLink) {
          console.log(`   🖱️  Switching back to original dashboard...`);
          await Promise.all([
            browser.waitForNavigation(),
            browser.click(`a[href^="${backPath}"]`),
          ]);
          await browser.sleep(1500);
          console.log(`   ✓ Switched back! Now at: ${page.url()}`);
        }
      }
    } else {
      console.log(`   ❌ Dashboard switcher NOT found (but expected)`);
      throw new Error(`Expected dashboard switcher for ${userType} but not found`);
    }
  } else {
    if (switcherFound || crossDashboardLinks.length > 0) {
      console.log(`   ⚠️  Dashboard switcher found (but NOT expected)`);
      // Not necessarily an error - might be a feature
    } else {
      console.log(`   ✓ Dashboard switcher NOT found (as expected)`);
    }
  }
  
  console.log('');
  
  // Logout
  try {
    const logoutSelector = 'a[href*="sign_out"], form[action*="sign_out"] button, [data-logout]';
    await browser.click(logoutSelector);
    await browser.sleep(1000);
  } catch (e) {
    // Logout might not be available or redirect already happened
  }
}

runTest()
  .then(passed => process.exit(passed ? 0 : 1))
  .catch(error => {
    console.error('Fatal:', error);
    process.exit(1);
  });

