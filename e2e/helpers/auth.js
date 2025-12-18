/**
 * Authentication helpers for E2E tests
 * Provides fast login functions for all user types
 */

const browser = require('./browser');
const config = require('../config');

/**
 * Login as superadmin (admin panel)
 */
async function loginAsSuperadmin() {
  const { email, password } = config.users.superadmin;
  
  await browser.goto('/admin/sign_in');
  await browser.waitFor('input#email, input[name="email"]');
  await browser.fastType('input#email, input[name="email"]', email);
  await browser.fastType('input#password, input[name="password"]', password);
  
  await Promise.all([
    browser.waitForNavigation().catch(() => {}),
    browser.click('input[type="submit"], button[type="submit"]'),
  ]);
  
  await browser.sleep(browser.getSpeed().mediumPause);
  return email;
}

/**
 * Login as teacher (teacher dashboard)
 */
async function loginAsTeacher() {
  const { email, password } = config.users.teacher;
  
  await browser.goto('/login/teacher');
  await browser.waitFor('input[name="user[email]"], input#user_email');
  await browser.fastType('input[name="user[email]"], input#user_email', email);
  await browser.fastType('input[name="user[password]"], input#user_password', password);
  
  await Promise.all([
    browser.waitForNavigation().catch(() => {}),
    browser.click('input[type="submit"], button[type="submit"]'),
  ]);
  
  await browser.sleep(browser.getSpeed().mediumPause);
  return email;
}

/**
 * Login as principal/director (management panel)
 */
async function loginAsPrincipal() {
  const { email, password } = config.users.principal;
  
  await browser.goto('/login/administration');
  
  // Wait for page to load and form to be ready
  await browser.waitFor('input[name="user[email]"], input#user_email', { timeout: 10000 });
  
  // Additional wait to ensure form is fully interactive
  await browser.sleep(browser.getSpeed().shortPause);
  
  await browser.fastType('input[name="user[email]"], input#user_email', email);
  await browser.fastType('input[name="user[password]"], input#user_password', password);
  
  await Promise.all([
    browser.waitForNavigation().catch(() => {}),
    browser.click('input[type="submit"], button[type="submit"]'),
  ]);
  
  await browser.sleep(browser.getSpeed().mediumPause);
  return email;
}

/**
 * Login as student (phone + PIN)
 */
async function loginAsStudent() {
  const { phone, pin } = config.users.student;
  const page = browser.getPage();
  
  await browser.goto('/login/student');
  
  // Wait for phone input to be ready
  await browser.waitFor('#phone-display');
  await browser.sleep(browser.getSpeed().mediumPause);
  
  // Phone input: #phone-display is the visible input
  const phoneDigits = phone.replace('+48', '');
  
  // Use browser.type which handles clicking and typing
  await browser.type('#phone-display', '+48' + phoneDigits);
  
  await browser.sleep(browser.getSpeed().shortPause);
  
  // Wait for PIN inputs
  await browser.waitFor('.login-pin-digit');
  
  // PIN inputs: 4 separate .login-pin-digit inputs
  const pinInputs = await page.$$('.login-pin-digit');
  
  if (pinInputs.length >= 4) {
    for (let i = 0; i < 4; i++) {
      // Wait for element to be visible and clickable
      await browser.sleep(50);
      await pinInputs[i].focus();
      await page.keyboard.type(pin[i]);
    }
  }
  
  // Wait a bit for PIN to be processed and form to auto-submit
  await browser.sleep(browser.getSpeed().shortPause);
  
  // Wait for navigation after PIN entry (form auto-submits when PIN is complete)
  // In headless mode, navigation might take longer
  try {
    // Wait for navigation with timeout
    await Promise.race([
      browser.waitForNavigation(),
      new Promise((_, reject) => setTimeout(() => reject(new Error('Navigation timeout')), 10000))
    ]);
  } catch (e) {
    // Navigation might have already completed or timed out, check current URL
    const currentUrl = browser.url();
    if (!currentUrl.includes('/home') && currentUrl.includes('/login/student')) {
      // Still on login page, wait a bit more and check for errors
      await browser.sleep(browser.getSpeed().mediumPause);
      
      // Check if there's an error message
      const hasError = await browser.exists('.alert-danger, .error-message, .flash-alert', 1000);
      if (hasError) {
        const errorText = await browser.getText('.alert-danger, .error-message, .flash-alert').catch(() => 'Unknown error');
        throw new Error(`Login failed: ${errorText}`);
      }
      
      // Try waiting for navigation one more time
      try {
        await Promise.race([
          browser.waitForNavigation(),
          new Promise((_, reject) => setTimeout(() => reject(new Error('Navigation timeout')), 5000))
        ]);
      } catch (e2) {
        // If still on login page, something went wrong
        const finalUrl = browser.url();
        if (finalUrl.includes('/login/student')) {
          throw new Error('Login failed: Still on login page after PIN entry. Navigation did not occur.');
        }
      }
    }
  }
  
  // Additional wait for page to stabilize
  await browser.sleep(browser.getSpeed().mediumPause);
  
  // Final verification - make sure we're not on login page
  const finalUrl = browser.url();
  if (finalUrl.includes('/login/student')) {
    throw new Error('Login failed: Did not redirect to home page');
  }
  
  return phone;
}

module.exports = {
  loginAsSuperadmin,
  loginAsTeacher,
  loginAsPrincipal,
  loginAsStudent,
};

