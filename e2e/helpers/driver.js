/**
 * Selenium WebDriver Helper
 */

const { Builder, By, until } = require('selenium-webdriver');
const chrome = require('selenium-webdriver/chrome');
const config = require('../config');

/**
 * Create and configure WebDriver instance
 * Uses Selenium Manager (built into Selenium 4.6+) to auto-download correct ChromeDriver
 */
async function createDriver() {
  const options = new chrome.Options();
  
  if (config.browser.headless) {
    options.addArguments('--headless=new');
  }
  
  options.addArguments(
    `--window-size=${config.browser.windowSize.width},${config.browser.windowSize.height}`,
    '--disable-gpu',
    '--no-sandbox',
    '--disable-dev-shm-usage',
    '--disable-extensions',
    '--disable-infobars',
  );
  
  // Let Selenium Manager handle ChromeDriver automatically
  // Clear any cached driver path to force fresh detection
  const service = new chrome.ServiceBuilder();
  
  const driver = await new Builder()
    .forBrowser('chrome')
    .setChromeOptions(options)
    .setChromeService(service)
    .build();
  
  // Set timeouts
  await driver.manage().setTimeouts({
    implicit: config.timeouts.implicit,
    pageLoad: config.timeouts.pageLoad,
    script: config.timeouts.script,
  });
  
  return driver;
}

/**
 * Navigate to a path relative to base URL
 */
async function navigateTo(driver, path) {
  const url = `${config.baseUrl}${path}`;
  await driver.get(url);
  return url;
}

/**
 * Wait for element to be visible and return it
 */
async function waitForElement(driver, selector, timeout = config.timeouts.implicit) {
  const locator = typeof selector === 'string' 
    ? By.css(selector) 
    : selector;
  
  return driver.wait(until.elementLocated(locator), timeout);
}

/**
 * Wait for element to be clickable
 */
async function waitForClickable(driver, selector, timeout = config.timeouts.implicit) {
  const element = await waitForElement(driver, selector, timeout);
  await driver.wait(until.elementIsVisible(element), timeout);
  await driver.wait(until.elementIsEnabled(element), timeout);
  return element;
}

/**
 * Safe click with retry
 */
async function safeClick(driver, selector, retries = 3) {
  for (let i = 0; i < retries; i++) {
    try {
      const element = await waitForClickable(driver, selector);
      await element.click();
      return true;
    } catch (error) {
      if (i === retries - 1) throw error;
      await driver.sleep(500);
    }
  }
}

/**
 * Fill input field
 */
async function fillInput(driver, selector, value) {
  const element = await waitForElement(driver, selector);
  await element.clear();
  await element.sendKeys(value);
}

/**
 * Get text content of element
 */
async function getText(driver, selector) {
  const element = await waitForElement(driver, selector);
  return element.getText();
}

/**
 * Check if element exists
 */
async function elementExists(driver, selector, timeout = 2000) {
  try {
    await driver.wait(
      until.elementLocated(typeof selector === 'string' ? By.css(selector) : selector),
      timeout
    );
    return true;
  } catch {
    return false;
  }
}

/**
 * Take screenshot
 */
async function takeScreenshot(driver, name) {
  const screenshot = await driver.takeScreenshot();
  const fs = require('fs');
  const path = require('path');
  
  const dir = path.join(__dirname, '..', 'screenshots');
  if (!fs.existsSync(dir)) {
    fs.mkdirSync(dir, { recursive: true });
  }
  
  const filename = `${name}-${Date.now()}.png`;
  fs.writeFileSync(path.join(dir, filename), screenshot, 'base64');
  console.log(`Screenshot saved: ${filename}`);
  return filename;
}

module.exports = {
  createDriver,
  navigateTo,
  waitForElement,
  waitForClickable,
  safeClick,
  fillInput,
  getText,
  elementExists,
  takeScreenshot,
  By,
  until,
};

