/**
 * Puppeteer Browser Helper
 * Simpler alternative to Selenium - has bundled Chromium
 */

const puppeteer = require('puppeteer');
const config = require('../config');

let browser = null;
let page = null;
let mousePos = { x: 960, y: 540 }; // Track mouse position

// Speed settings based on mode
const SPEED = {
  headless: {
    slowMo: 0,
    typeDelay: 0,        // Instant typing
    mouseSteps: 1,       // Instant mouse move
    shortPause: 100,     // Minimal pause
    mediumPause: 300,
    longPause: 500,
  },
  gui: {
    slowMo: 20,          // Reduced from 50
    typeDelay: 10,       // Reduced from 30
    mouseSteps: 5,       // Reduced from 15
    shortPause: 200,
    mediumPause: 500,
    longPause: 1000,
  }
};

function getSpeed() {
  return config.browser.headless ? SPEED.headless : SPEED.gui;
}

/**
 * Launch browser and create page
 */
async function launch() {
  const isHeadless = config.browser.headless;
  const speed = getSpeed();
  
  browser = await puppeteer.launch({
    headless: isHeadless,
    slowMo: speed.slowMo,
    args: [
      `--window-size=${config.browser.windowSize.width},${config.browser.windowSize.height}`,
      '--no-sandbox',
      '--disable-setuid-sandbox',
      '--disable-dev-shm-usage', // Faster in Docker/CI
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
  // Use domcontentloaded for speed, networkidle2 is too slow
  await page.goto(url, { waitUntil: 'domcontentloaded' });
  
  // Brief wait for JS to initialize
  await sleep(getSpeed().shortPause);
  
  // Restore mouse to last known position after page load
  if (!config.browser.headless) {
    await showCursorAt(mousePos.x, mousePos.y);
  }
  
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
  const speed = getSpeed();
  
  // In headless mode: instant move
  // In GUI mode: smooth but fast
  await page.mouse.move(targetX, targetY, { steps: speed.mouseSteps });
  
  // Update tracked position
  mousePos.x = targetX;
  mousePos.y = targetY;
}

/**
 * Type into input with smooth mouse movement
 */
async function type(selector, text) {
  await waitFor(selector);
  const speed = getSpeed();
  
  // Get element position and move smoothly (GUI only)
  if (!config.browser.headless) {
    const element = await page.$(selector);
    const box = await element.boundingBox();
    if (box) {
      await smoothMoveTo(box.x + box.width / 2, box.y + box.height / 2);
    }
  }
  
  await page.click(selector, { clickCount: 3 }); // Select all
  await page.type(selector, text, { delay: speed.typeDelay });
}

/**
 * Fast type - instant text input (bypass character-by-character)
 */
async function fastType(selector, text) {
  await waitFor(selector);
  await page.$eval(selector, (el, value) => {
    el.value = value;
    el.dispatchEvent(new Event('input', { bubbles: true }));
    el.dispatchEvent(new Event('change', { bubbles: true }));
  }, text);
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
  await page.waitForNavigation({ waitUntil: 'domcontentloaded' });
  
  // Brief wait for JS
  await sleep(getSpeed().shortPause);
  
  // Restore cursor at last known position (GUI only)
  if (!config.browser.headless) {
    await showCursorAt(mousePos.x, mousePos.y);
  }
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
  fastType,  // Instant text input
  getText,
  exists,
  url,
  waitForNavigation,
  screenshot,
  close,
  sleep,
  getPage,
  getSpeed,  // Access speed settings
};

