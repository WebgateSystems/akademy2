/**
 * E2E Test: Principal (School Director) Login and Dashboard Navigation
 */

const browser = require('../helpers/browser');
const config = require('../config');

const EXPECTED_MENU_ITEMS = [
  { text: 'Pulpit', href: '/management' },
  { text: 'Klasy', href: '/management/classes' },
  { text: 'Nauczyciele', href: '/management/teachers' },
  { text: 'Uczniowie', href: '/management/students' },
  { text: 'Administracja', href: '/management/administration' },
  { text: 'Rodzice', href: '/management/parents' },
];

async function runTest() {
  let testPassed = false;
  
  console.log('🚀 Starting Principal Dashboard Test...\n');
  
  try {
    await browser.launch();
    
    // Step 1: Navigate to administration login
    console.log('📍 Step 1: Navigate to administration login');
    await browser.goto('/login/administration');
    await browser.waitFor('input[name="user[email]"], input#user_email');
    console.log('   ✓ Login page loaded');
    
    // Step 2: Login as principal
    console.log('📍 Step 2: Login as principal (school director)');
    const { email, password } = config.users.principal;
    
    await browser.type('input[name="user[email]"], input#user_email', email);
    await browser.type('input[name="user[password]"], input#user_password', password);
    console.log(`   Logging in as: ${email}`);
    
    await Promise.all([
      browser.waitForNavigation(),
      browser.click('input[type="submit"], button[type="submit"], .login-btn'),
    ]);
    
    await browser.waitFor('.dashboard-sidebar, .dashboard-nav');
    console.log('   ✓ Successfully logged in');
    await browser.sleep(1000);
    
    // Step 3: Verify menu items
    console.log('📍 Step 3: Verify menu items');
    const menuResults = [];
    
    for (const item of EXPECTED_MENU_ITEMS) {
      const selector = `a[href*="${item.href}"]`;
      const found = await browser.exists(selector, 2000);
      
      if (found) {
        console.log(`   ✓ Menu: "${item.text}"`);
        menuResults.push({ ...item, found: true });
      } else {
        console.log(`   ✗ MISSING: "${item.text}" (${item.href})`);
        menuResults.push({ ...item, found: false });
      }
    }
    
    // Step 4: Click each menu item
    console.log('📍 Step 4: Navigate through menu\n');
    
    for (const item of EXPECTED_MENU_ITEMS) {
      try {
        console.log(`   🖱️  Clicking: "${item.text}"`);
        await browser.click(`a[href*="${item.href}"]`);
        await browser.sleep(1500);
        
        const currentUrl = browser.url();
        if (currentUrl.includes(item.href)) {
          console.log(`      ✓ Page loaded: ${currentUrl}`);
        } else {
          console.log(`      ⚠️  URL: ${currentUrl}`);
        }
        
        const hasError = await browser.exists('.alert-danger', 500);
        if (hasError) {
          const errorText = await browser.getText('.alert-danger');
          console.log(`      ❌ Error: ${errorText}`);
        }
        console.log('');
      } catch (error) {
        console.log(`      ❌ Failed: ${error.message}\n`);
      }
    }
    
    // Results
    const missingItems = menuResults.filter(r => !r.found);
    testPassed = missingItems.length === 0;
    
    console.log('='.repeat(50));
    console.log('RESULTS');
    console.log('='.repeat(50));
    console.log(`Menu items: ${menuResults.filter(r => r.found).length}/${EXPECTED_MENU_ITEMS.length}`);
    
    if (testPassed) {
      console.log('\n✅ TEST PASSED\n');
    } else {
      console.log('\n❌ TEST FAILED');
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

runTest()
  .then(passed => process.exit(passed ? 0 : 1))
  .catch(error => {
    console.error('Fatal:', error);
    process.exit(1);
  });

