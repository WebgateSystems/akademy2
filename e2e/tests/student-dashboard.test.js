/**
 * E2E Test: Student Login and Dashboard Navigation
 */

const browser = require('../helpers/browser');
const config = require('../config');
const auth = require('../helpers/auth');

// Student menu items (Filmy szkolne only visible if student has approved classes)
const EXPECTED_MENU_ITEMS = [
  { text: 'Kursy', href: '/home', required: true },
  { text: 'Filmy szkolne', href: '/home/videos', required: false }, // Only if has classes
  { text: 'Konto', href: '/home/account', required: true },
];

async function runTest() {
  let testPassed = false;
  
  console.log('🚀 Starting Student Dashboard Test...\n');
  
  try {
    await browser.launch();
  
    // Login as student
    console.log('📍 Step 1: Login as student');
    await auth.loginAsStudent();
    
    const currentUrl = browser.url();
    console.log(`   ✓ Logged in as student`);
    console.log(`   Current URL: ${currentUrl}\n`);
    
    // Verify we're logged in (should be on /home or redirected away from login)
    if (currentUrl.includes('/login/student')) {
      throw new Error('Login failed: Still on login page after login attempt');
    }
    
    // If not on /home, navigate there
    if (!currentUrl.includes('/home')) {
      console.log('   🖱️  Navigating to /home...');
      await browser.goto('/home');
      await browser.sleep(1500);
      console.log(`   Current URL: ${browser.url()}\n`);
    }
    
    // Wait for dashboard to load
    await browser.sleep(500);
    
    await browser.sleep(1000);
    
    // Step 3: Verify menu items
    console.log('📍 Step 2: Verify menu items');
    const menuResults = [];
    
    // // Debug: check page structure
    const page = browser.getPage();
    const pageInfo = await page.evaluate(() => {
      return {
        hasSidebar: !!document.querySelector('.dashboard-sidebar'),
        hasNav: !!document.querySelector('.dashboard-nav'),
        hasApp: !!document.querySelector('.dashboard-app'),
        bodyClasses: document.body.className,
        title: document.title,
      };
    });
    console.log(`   Page structure: sidebar=${pageInfo.hasSidebar}, nav=${pageInfo.hasNav}, app=${pageInfo.hasApp}`);
    console.log(`   Title: ${pageInfo.title}`);
    
    // Check what's visible in sidebar
    const sidebarLinks = await page.$$eval('.dashboard-nav__button, .dashboard-nav a', links => 
      links.map(l => ({ href: l.getAttribute('href'), text: l.textContent.trim() }))
    );
    console.log(`   Found ${sidebarLinks.length} sidebar links`);
    sidebarLinks.forEach(l => console.log(`     - "${l.text}" (${l.href})`));
    
    for (const item of EXPECTED_MENU_ITEMS) {
      const selector = `a.dashboard-nav__button[href*="${item.href}"]`;
      const found = await browser.exists(selector, 1000);
      
      if (found) {
        console.log(`   ✓ Menu: "${item.text}"`);
        menuResults.push({ ...item, found: true });
      } else if (item.required) {
        console.log(`   ✗ MISSING: "${item.text}" (${item.href})`);
        menuResults.push({ ...item, found: false });
      } else {
        console.log(`   ⚠️  Optional not found: "${item.text}" (${item.href})`);
        menuResults.push({ ...item, found: false, optional: true });
      }
    }
    
    // Step 4: Click found menu items
    console.log('📍 Step 3: Navigate through menu\n');
    
    for (const item of menuResults.filter(r => r.found)) {
      try {
        console.log(`   🖱️  Clicking: "${item.text}"`);
        const selector = `a.dashboard-nav__button[href*="${item.href}"]`;
        
        await Promise.all([
          browser.waitForNavigation().catch(() => {}),
          browser.click(selector),
        ]);
        await browser.sleep(500);
        
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
    
    // Step 5: Test subject cards (if on home page)
    console.log('📍 Step 4: Test subject cards');
    await browser.goto('/home');
    await browser.sleep(1500);
    
    const hasSubjects = await browser.exists('.class-result, .subject-card', 2000);
    if (hasSubjects) {
      console.log('   ✓ Subject cards found');
      
      // Try clicking first subject
      try {
        await browser.click('.class-result:first-child, .subject-card:first-child');
        await browser.sleep(1500);
        console.log(`   ✓ Clicked first subject, URL: ${browser.url()}`);
      } catch (e) {
        console.log(`   ⚠️  Could not click subject: ${e.message}`);
      }
    } else {
      console.log('   ⚠️  No subject cards found');
    }
    
    // Results - only required items affect pass/fail
    const missingRequired = menuResults.filter(r => !r.found && r.required);
    testPassed = missingRequired.length === 0;
    
    console.log('\n' + '='.repeat(50));
    console.log('RESULTS');
    console.log('='.repeat(50));
    const foundCount = menuResults.filter(r => r.found).length;
    const requiredCount = EXPECTED_MENU_ITEMS.filter(i => i.required).length;
    console.log(`Menu items: ${foundCount}/${EXPECTED_MENU_ITEMS.length}`);
    console.log(`Required: ${requiredCount - missingRequired.length}/${requiredCount}`);
    
    if (testPassed) {
      console.log('\n✅ TEST PASSED\n');
    } else {
      console.log('\n❌ TEST FAILED');
      console.log('Missing required items:');
      missingRequired.forEach(item => console.log(`  - ${item.text}`));
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

