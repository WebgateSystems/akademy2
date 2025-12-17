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
  
  await browser.sleep(browser.getSpeed().mediumPause);
  
  // Form may auto-submit or need button click
  const submitBtn = await page.$('button[type="submit"], input[type="submit"], .login-btn');
  if (submitBtn) {
    try {
      await Promise.all([
        browser.waitForNavigation().catch(() => {}),
        submitBtn.click(),
      ]);
    } catch (e) {
      // May already have navigated
    }
  }
  
  await browser.sleep(browser.getSpeed().mediumPause);
  return phone;
}

module.exports = {
  loginAsSuperadmin,
  loginAsTeacher,
  loginAsPrincipal,
  loginAsStudent,
};

