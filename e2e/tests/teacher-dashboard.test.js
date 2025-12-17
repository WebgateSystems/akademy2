/**
 * E2E Test: Teacher Login and Dashboard Navigation
 * Note: Teacher dashboard menu shows assigned CLASSES, not fixed menu items
 */

const browser = require('../helpers/browser');
const auth = require('../helpers/auth');

const pause = () => browser.getSpeed();

async function runTest() {
  let testPassed = false;
  
  console.log('🚀 Starting Teacher Dashboard Test...\n');
  
  try {
    await browser.launch();
    
    // Step 1: Login as teacher
    console.log('📍 Step 1: Login as teacher');
    await auth.loginAsTeacher();
    console.log('   ✓ Successfully logged in');
    
    await browser.sleep(pause().mediumPause);
    
    // Step 2: Verify dashboard loaded
    console.log('📍 Step 2: Verify dashboard');
    const page = browser.getPage();
    
    const hasSidebar = await browser.exists('.dashboard-sidebar', 2000);
    console.log(`   Sidebar: ${hasSidebar ? '✓' : '✗'}`);
    
    const hasNav = await browser.exists('.dashboard-nav', 2000);
    console.log(`   Navigation: ${hasNav ? '✓' : '✗'}`);
    
    // Step 3: Check for classes in sidebar (teacher menu shows classes)
    console.log('📍 Step 3: Check classes in sidebar');
    
    const classLinks = await page.$$('.dashboard-nav__button[data-class-id]');
    console.log(`   ✓ Found ${classLinks.length} class(es) in navigation`);
    
    if (classLinks.length > 0) {
      // List class names
      const classNames = await page.$$eval('.dashboard-nav__button[data-class-id] .dashboard-nav__label', 
        els => els.map(el => el.textContent.trim())
      );
      classNames.slice(0, 5).forEach(name => console.log(`     - ${name}`));
      if (classNames.length > 5) console.log(`     ... and ${classNames.length - 5} more`);
    }
    
    // Step 4: Click first class and check page elements
    console.log('📍 Step 4: Navigate to class');
    
    if (classLinks.length > 0) {
      console.log('   🖱️  Clicking first class...');
      await browser.click('.dashboard-nav__button[data-class-id]');
      await browser.sleep(pause().mediumPause);
      
      const currentUrl = browser.url();
      console.log(`   ✓ URL: ${currentUrl}`);
      
      // Check for subject cards
      const subjectCards = await page.$$('.class-result, .subject-card');
      console.log(`   ✓ Subject cards: ${subjectCards.length}`);
      
      // Check for stats
      const statsCards = await page.$$('.school-profile-hero__stat-card');
      console.log(`   ✓ Stats cards: ${statsCards.length}`);
    }
    
    // Step 5: Test top bar links
    console.log('📍 Step 5: Test top bar navigation');
    
    // Check for students link
    const studentsLink = await browser.exists('a[href*="/students"]', 1000);
    if (studentsLink) {
      console.log('   🖱️  Clicking Students link...');
      await Promise.all([
        browser.waitForNavigation().catch(() => {}),
        browser.click('a[href*="/students"]'),
      ]);
      await browser.sleep(pause().shortPause);
      console.log(`   ✓ Students page: ${browser.url()}`);
    }
    
    // Go back to dashboard
    await browser.goto('/dashboard');
    await browser.sleep(pause().shortPause);
    
    // Check for quiz results (via subject card)
    const quizResultsLink = await browser.exists('a[href*="/quiz_results"]', 1000);
    if (quizResultsLink) {
      console.log('   🖱️  Clicking Quiz Results link...');
      await Promise.all([
        browser.waitForNavigation().catch(() => {}),
        browser.click('a[href*="/quiz_results"]'),
      ]);
      await browser.sleep(pause().shortPause);
      console.log(`   ✓ Quiz results page: ${browser.url()}`);
    }
    
    testPassed = hasSidebar && hasNav;
    
    console.log('\n' + '='.repeat(50));
    console.log('RESULTS');
    console.log('='.repeat(50));
    console.log(`Sidebar: ${hasSidebar ? '✓' : '✗'}`);
    console.log(`Navigation: ${hasNav ? '✓' : '✗'}`);
    console.log(`Classes: ${classLinks.length}`);
    
    if (testPassed) {
      console.log('\n✅ TEST PASSED\n');
    } else {
      console.log('\n❌ TEST FAILED\n');
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

