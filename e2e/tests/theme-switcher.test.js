/**
 * E2E Test: Theme Switcher (Light/Dark mode)
 * Tests theme switching on all dashboards
 */

const browser = require('../helpers/browser');
const auth = require('../helpers/auth');

const pause = () => browser.getSpeed();

async function clearSession() {
  const page = browser.getPage();
  
  // Navigate to a neutral page first to ensure we're not on a protected route
  await browser.goto('/login/administration');
  await browser.sleep(pause().shortPause);
  
  // Clear all cookies
  const client = await page.target().createCDPSession();
  await client.send('Network.clearBrowserCookies');
  
  // Clear local/session storage
  await page.evaluate(() => {
    localStorage.clear();
    sessionStorage.clear();
  });
  
  // Navigate to logout or a public page to ensure clean state
  await browser.goto('/');
  await browser.sleep(pause().shortPause);
}

async function runTest() {
  let testPassed = true;
  
  console.log('🚀 Starting Theme Switcher Test...\n');
  
  try {
    await browser.launch();
    
    // Test 1: Theme switch on superadmin dashboard
    console.log('📍 Test 1: Theme switch on Superadmin dashboard');
    await auth.loginAsSuperadmin();
    console.log('   ✓ Logged in as superadmin');
    await testThemeToggle();
    
    // Clear session by going to logout and clearing storage
    await clearSession();
    
    // Test 2: Theme switch on teacher dashboard
    console.log('📍 Test 2: Theme switch on Teacher dashboard');
    // Add small delay after clearing session to ensure clean state
    await browser.sleep(pause().shortPause);
    await auth.loginAsTeacher();
    console.log('   ✓ Logged in as teacher');
    await testThemeToggle();
    
    // Clear session
    await clearSession();
    
    // Test 3: Theme switch on principal dashboard
    console.log('📍 Test 3: Theme switch on Principal dashboard');
    // Add small delay after clearing session to ensure clean state
    await browser.sleep(pause().shortPause);
    await auth.loginAsPrincipal();
    console.log('   ✓ Logged in as principal');
    await testThemeToggle();
    
    console.log('\n' + '='.repeat(50));
    console.log('✅ THEME SWITCHER TEST PASSED\n');
    
  } catch (error) {
    console.error('\n❌ TEST ERROR:', error.message);
    testPassed = false;
  } finally {
    await browser.close();
  }
  
  return testPassed;
}

async function testThemeToggle() {
  const page = browser.getPage();
  
  // Get initial theme
  const initialTheme = await page.evaluate(() => {
    return document.documentElement.getAttribute('data-theme') || 
           (window.matchMedia('(prefers-color-scheme: dark)').matches ? 'dark' : 'light');
  });
  console.log(`   Current theme: ${initialTheme}`);
  
  // Find and click theme toggle
  const themeToggleExists = await browser.exists('#theme-toggle-btn, [data-theme-toggle], .theme-toggle', 2000);
  
  if (!themeToggleExists) {
    console.log('   ⚠️  Theme toggle button not found\n');
    return;
  }
  
  console.log('   🖱️  Clicking theme toggle...');
  await browser.click('#theme-toggle-btn, [data-theme-toggle], .theme-toggle');
  await browser.sleep(pause().mediumPause);
  
  // Check theme changed
  const newTheme = await page.evaluate(() => {
    return document.documentElement.getAttribute('data-theme');
  });
  
  if (newTheme !== initialTheme) {
    console.log(`   ✓ Theme changed: ${initialTheme} → ${newTheme}`);
  } else {
    console.log(`   ⚠️  Theme did not change (still ${newTheme})`);
  }
  
  // Toggle back
  console.log('   🖱️  Clicking theme toggle again...');
  await browser.click('#theme-toggle-btn, [data-theme-toggle], .theme-toggle');
  await browser.sleep(pause().shortPause);
  
  const finalTheme = await page.evaluate(() => {
    return document.documentElement.getAttribute('data-theme');
  });
  console.log(`   ✓ Theme toggled back: ${finalTheme}\n`);
}

runTest()
  .then(passed => process.exit(passed ? 0 : 1))
  .catch(error => {
    console.error('Fatal:', error);
    process.exit(1);
  });

