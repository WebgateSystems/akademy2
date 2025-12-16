/**
 * E2E Test: Superadmin Login and Menu Navigation
 * 
 * Scenario:
 * 1. Navigate to admin login page
 * 2. Login as superadmin
 * 3. Verify all menu items are present
 * 4. Click each menu item and verify it loads correctly
 */

const browser = require('../helpers/browser');
const config = require('../config');

// Expected menu items in superadmin panel (from actual HTML)
const EXPECTED_MENU_ITEMS = [
  { text: 'Pulpit', href: '/admin', exact: true },
  { text: 'Szkoły', href: '/admin/schools' },
  { text: 'Dyrektorzy', href: '/admin/users' },
  { text: 'Nauczyciele', href: '/admin/teachers' },
  { text: 'Uczniowie', href: '/admin/students' },
  { text: 'Dziennik aktywności', href: '/admin/events' },
  { text: 'Przedmioty', href: '/admin/subjects' },
  { text: 'Jednostki', href: '/admin/units' },
  { text: 'Moduły', href: '/admin/learning_modules' },
  { text: 'Treści', href: '/admin/contents' },
];

async function runTest() {
  let testPassed = false;
  
  console.log('🚀 Starting Superadmin Menu Test...\n');
  
  try {
    // ========================================
    // Setup
    // ========================================
    await browser.launch();
    
    // ========================================
    // Step 1: Navigate to admin login
    // ========================================
    console.log('📍 Step 1: Navigate to admin login page');
    await browser.goto('/admin/sign_in');
    
    // Wait for login form
    await browser.waitFor('input#email, input[name="email"]');
    console.log('   ✓ Login page loaded');
    
    // ========================================
    // Step 2: Login as superadmin
    // ========================================
    console.log('📍 Step 2: Login as superadmin');
    
    const { email, password } = config.users.superadmin;
    
    await browser.type('input#email, input[name="email"]', email);
    await browser.type('input#password, input[name="password"]', password);
    
    console.log(`   Logging in as: ${email}`);
    
    // Click login and wait for navigation
    await Promise.all([
      browser.waitForNavigation(),
      browser.click('input[type="submit"], button[type="submit"], .btn-primary'),
    ]);
    
    // Wait for dashboard sidebar
    await browser.waitFor('.dashboard-sidebar, .dashboard-nav');
    console.log('   ✓ Successfully logged in');
    
    // ========================================
    // Step 3: Verify menu items are present
    // ========================================
    console.log('📍 Step 3: Verify menu items');
    
    const menuResults = [];
    
    for (const item of EXPECTED_MENU_ITEMS) {
      const selector = item.exact 
        ? `a.dashboard-nav__button[href="${item.href}"]`
        : `a.dashboard-nav__button[href*="${item.href}"]`;
      
      const found = await browser.exists(selector, 2000);
      
      if (found) {
        console.log(`   ✓ Menu: "${item.text}" (${item.href})`);
        menuResults.push({ ...item, found: true });
      } else {
        console.log(`   ✗ MISSING: "${item.text}" (${item.href})`);
        menuResults.push({ ...item, found: false });
      }
    }
    
    // ========================================
    // Step 4: Click each menu item and verify page loads
    // ========================================
    console.log('📍 Step 4: Clicking menu items...\n');
    
    for (const item of EXPECTED_MENU_ITEMS) {
      try {
        const selector = item.exact 
          ? `a.dashboard-nav__button[href="${item.href}"]`
          : `a.dashboard-nav__button[href*="${item.href}"]`;
        
        console.log(`   🖱️  Clicking: "${item.text}"`);
        
        // Click and wait for navigation
        await browser.click(selector);
        await browser.sleep(2000); // Wait 2s to see the page change
        
        const currentUrl = browser.url();
        const urlMatches = item.exact 
          ? currentUrl.endsWith(item.href) || currentUrl.includes(item.href)
          : currentUrl.includes(item.href);
        
        if (urlMatches) {
          console.log(`      ✓ Page loaded: ${currentUrl}`);
        } else {
          console.log(`      ⚠️  Unexpected URL: ${currentUrl}`);
        }
        
        // Check for errors on page
        const hasError = await browser.exists('.alert-danger', 500);
        if (hasError) {
          const errorText = await browser.getText('.alert-danger');
          console.log(`      ❌ Error on page: ${errorText}`);
        }
        
        // Check page has content (not blank)
        const hasContent = await browser.exists('.dashboard-main', 500);
        if (!hasContent) {
          console.log(`      ⚠️  Page appears empty`);
        }
        
        console.log(''); // Empty line for readability
        
      } catch (error) {
        console.log(`      ❌ Failed: ${error.message}\n`);
      }
    }
    
    // ========================================
    // Step 5: Quick interaction test
    // ========================================
    console.log('📍 Step 5: Testing some interactions...\n');
    
    // Go to Schools page and check table exists
    console.log('   Testing Schools page...');
    await browser.goto('/admin/schools');
    await browser.sleep(1500);
    
    const hasTable = await browser.exists('table, .schools-table, .teachers-table', 2000);
    if (hasTable) {
      console.log('      ✓ Table found on Schools page');
    } else {
      console.log('      ⚠️  No table found');
    }
    
    // Go to Events/Activity log
    console.log('   Testing Activity Log page...');
    await browser.goto('/admin/events');
    await browser.sleep(1500);
    
    const hasLogs = await browser.exists('.activity-log, table, .events-list', 2000);
    if (hasLogs) {
      console.log('      ✓ Activity log loaded');
    } else {
      console.log('      ⚠️  No activity log found');
    }
    
    console.log('');
    
    // ========================================
    // Results
    // ========================================
    const missingItems = menuResults.filter(r => !r.found);
    testPassed = missingItems.length === 0;
    
    console.log('\n' + '='.repeat(50));
    console.log('RESULTS');
    console.log('='.repeat(50));
    console.log(`Menu items: ${menuResults.filter(r => r.found).length}/${EXPECTED_MENU_ITEMS.length}`);
    
    if (testPassed) {
      console.log('\n✅ TEST PASSED\n');
    } else {
      console.log('\n❌ TEST FAILED');
      console.log('Missing:');
      missingItems.forEach(item => console.log(`  - ${item.text}`));
    }
    
  } catch (error) {
    console.error('\n❌ TEST ERROR:', error.message);
    testPassed = false;
    
  } finally {
    await browser.close();
  }
  
  return testPassed;
}

// Run
runTest()
  .then(passed => process.exit(passed ? 0 : 1))
  .catch(error => {
    console.error('Fatal:', error);
    process.exit(1);
  });
