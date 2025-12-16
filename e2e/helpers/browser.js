/**
 * Puppeteer Browser Helper
 * Simpler alternative to Selenium - has bundled Chromium
 */

const puppeteer = require('puppeteer');
const config = require('../config');

let browser = null;
let page = null;
let mousePos = { x: 960, y: 540 }; // Track mouse position

/**
 * Launch browser and create page
 */
async function launch() {
  const isHeadless = config.browser.headless;
  
  browser = await puppeteer.launch({
    headless: isHeadless,
    slowMo: isHeadless ? 0 : 50, // Slow down actions in GUI mode
    args: [
      `--window-size=${config.browser.windowSize.width},${config.browser.windowSize.height}`,
      '--no-sandbox',
      '--disable-setuid-sandbox',
    ],
    defaultViewport: {
      width: config.browser.windowSize.width,
      height: config.browser.windowSize.height,
    },
  });
  
  page = await browser.newPage();
  page.setDefaultTimeout(config.timeouts.implicit);
  
  // Add visual cursor indicator in GUI mode
  if (!isHeadless) {
    await installMouseHelper(page);
    // Initialize mouse position to center
    mousePos = { x: config.browser.windowSize.width / 2, y: config.browser.windowSize.height / 2 };
    await page.mouse.move(mousePos.x, mousePos.y);
  }
  
  return { browser, page };
}

/**
 * Install visual mouse cursor helper
 * Shows an arrow cursor that follows mouse position
 */
async function installMouseHelper(page) {
  await page.evaluateOnNewDocument(() => {
    const init = () => {
      // Check if cursor already exists (page reload)
      if (document.getElementById('puppeteer-cursor')) return;
      
      // Create cursor element (arrow shape using SVG)
      const cursor = document.createElement('div');
      cursor.id = 'puppeteer-cursor';
      cursor.innerHTML = `
        <svg width="28" height="28" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
          <path d="M4 4L10.5 20L12.5 13.5L19 11.5L4 4Z" fill="#FFD700" stroke="#000" stroke-width="1.5" stroke-linejoin="round"/>
        </svg>
      `;
      cursor.style.cssText = `
        pointer-events: none;
        position: fixed;
        z-index: 999999;
        filter: drop-shadow(2px 2px 3px rgba(0,0,0,0.5));
        transition: transform 0.05s ease-out, left 0.02s linear, top 0.02s linear;
      `;
      
      // Get saved position from sessionStorage or use center
      const savedX = sessionStorage.getItem('cursorX');
      const savedY = sessionStorage.getItem('cursorY');
      cursor.style.left = (savedX || window.innerWidth / 2) + 'px';
      cursor.style.top = (savedY || window.innerHeight / 2) + 'px';
      
      document.body.appendChild(cursor);
      
      // Track mouse movement and save position
      document.addEventListener('mousemove', (e) => {
        cursor.style.left = e.clientX + 'px';
        cursor.style.top = e.clientY + 'px';
        sessionStorage.setItem('cursorX', e.clientX);
        sessionStorage.setItem('cursorY', e.clientY);
      }, true);
      
      // Visual feedback on click
      document.addEventListener('mousedown', () => {
        cursor.style.transform = 'scale(0.8)';
      }, true);
      
      document.addEventListener('mouseup', () => {
        cursor.style.transform = 'scale(1)';
      }, true);
    };
    
    if (document.body) {
      init();
    } else {
      document.addEventListener('DOMContentLoaded', init);
    }
  });
}

/**
 * Restore mouse position after navigation
 */
async function restoreMousePosition() {
  if (!config.browser.headless) {
    await page.mouse.move(mousePos.x, mousePos.y, { steps: 1 });
  }
}

/**
 * Navigate to path
 */
async function goto(path) {
  const url = path.startsWith('http') ? path : `${config.baseUrl}${path}`;
  await page.goto(url, { waitUntil: 'networkidle2' });
  
  // Restore mouse to last known position after page load
  await showCursorAt(mousePos.x, mousePos.y);
  
  return url;
}

/**
 * Show cursor at position (ensures cursor is visible)
 */
async function showCursorAt(x, y) {
  if (config.browser.headless) return;
  
  // Small movement to trigger mousemove event and make cursor visible
  await page.mouse.move(x - 1, y - 1, { steps: 1 });
  await page.mouse.move(x, y, { steps: 1 });
}

/**
 * Wait for selector
 */
async function waitFor(selector, options = {}) {
  return page.waitForSelector(selector, { timeout: config.timeouts.implicit, ...options });
}

/**
 * Click element with smooth mouse movement
 */
async function click(selector) {
  await waitFor(selector);
  
  // Get element position
  const element = await page.$(selector);
  const box = await element.boundingBox();
  
  if (box) {
    // Target: center of element
    const targetX = box.x + box.width / 2;
    const targetY = box.y + box.height / 2;
    
    // Smooth move to element (in GUI mode)
    if (!config.browser.headless) {
      await smoothMoveTo(targetX, targetY);
    }
    
    // Click
    await page.mouse.click(targetX, targetY);
  } else {
    // Fallback to regular click
    await page.click(selector);
  }
}

/**
 * Smoothly move mouse from current position to target
 */
async function smoothMoveTo(targetX, targetY) {
  const distance = Math.sqrt(
    Math.pow(targetX - mousePos.x, 2) + Math.pow(targetY - mousePos.y, 2)
  );
  
  // Faster movement: fewer steps (min 5, max 15)
  const steps = Math.min(15, Math.max(5, Math.floor(distance / 80)));
  
  // Move in steps
  await page.mouse.move(targetX, targetY, { steps });
  
  // Update tracked position
  mousePos.x = targetX;
  mousePos.y = targetY;
}

/**
 * Type into input with smooth mouse movement
 */
async function type(selector, text) {
  await waitFor(selector);
  
  // Get element position and move smoothly
  const element = await page.$(selector);
  const box = await element.boundingBox();
  
  if (box && !config.browser.headless) {
    const targetX = box.x + box.width / 2;
    const targetY = box.y + box.height / 2;
    await smoothMoveTo(targetX, targetY);
  }
  
  await page.click(selector, { clickCount: 3 }); // Select all
  await page.type(selector, text, { delay: config.browser.headless ? 0 : 30 }); // Typing delay in GUI mode
}

/**
 * Get text content
 */
async function getText(selector) {
  await waitFor(selector);
  return page.$eval(selector, el => el.textContent.trim());
}

/**
 * Check if element exists
 */
async function exists(selector, timeout = 2000) {
  try {
    await page.waitForSelector(selector, { timeout });
    return true;
  } catch {
    return false;
  }
}

/**
 * Get current URL
 */
function url() {
  return page.url();
}

/**
 * Wait for navigation
 */
async function waitForNavigation() {
  await page.waitForNavigation({ waitUntil: 'networkidle2' });
  
  // Restore cursor at last known position
  await showCursorAt(mousePos.x, mousePos.y);
}

/**
 * Take screenshot
 */
async function screenshot(name) {
  const fs = require('fs');
  const path = require('path');
  
  const dir = path.join(__dirname, '..', 'screenshots');
  if (!fs.existsSync(dir)) {
    fs.mkdirSync(dir, { recursive: true });
  }
  
  const filename = `${name}-${Date.now()}.png`;
  await page.screenshot({ path: path.join(dir, filename), fullPage: true });
  console.log(`📸 Screenshot: ${filename}`);
  return filename;
}

/**
 * Close browser
 */
async function close() {
  if (browser) {
    await browser.close();
    browser = null;
    page = null;
  }
}

/**
 * Sleep
 */
function sleep(ms) {
  return new Promise(resolve => setTimeout(resolve, ms));
}

/**
 * Get page instance (for advanced operations)
 */
function getPage() {
  return page;
}

module.exports = {
  launch,
  goto,
  waitFor,
  click,
  type,
  getText,
  exists,
  url,
  waitForNavigation,
  screenshot,
  close,
  sleep,
  getPage,
};

