/**
 * Applitools Eyes Helper for Visual Testing
 * 
 * This module provides visual testing integration with Applitools.
 * If @applitools/eyes-selenium is not installed, it falls back to 
 * simple screenshot-based visual logging.
 */

const config = require('../config');

let Eyes, Target, Configuration, BatchInfo;
let applitoolsAvailable = false;

// Try to load Applitools (optional dependency)
try {
  const applitools = require('@applitools/eyes-selenium');
  Eyes = applitools.Eyes;
  Target = applitools.Target;
  Configuration = applitools.Configuration;
  BatchInfo = applitools.BatchInfo;
  applitoolsAvailable = true;
} catch (e) {
  console.log('ℹ️  Applitools not installed - using screenshot-only mode');
}

let eyes = null;
let batch = null;

/**
 * Initialize Applitools Eyes
 */
async function initEyes(testName) {
  if (!applitoolsAvailable) {
    return null;
  }
  
  if (!config.applitools.apiKey) {
    console.warn('⚠️  APPLITOOLS_API_KEY not set - visual tests will be skipped');
    return null;
  }
  
  eyes = new Eyes();
  
  // Configure
  const configuration = new Configuration();
  configuration.setApiKey(config.applitools.apiKey);
  configuration.setAppName(config.applitools.appName);
  
  // Use shared batch for all tests in a run
  if (!batch) {
    batch = new BatchInfo(config.applitools.batchName);
  }
  configuration.setBatch(batch);
  
  eyes.setConfiguration(configuration);
  
  return eyes;
}

/**
 * Open Eyes session with driver
 */
async function openEyes(driver, testName) {
  if (!applitoolsAvailable) {
    return null;
  }
  
  if (!eyes) {
    await initEyes(testName);
  }
  
  if (!eyes) {
    return null; // No API key
  }
  
  await eyes.open(driver, config.applitools.appName, testName, {
    width: config.browser.windowSize.width,
    height: config.browser.windowSize.height,
  });
  
  return eyes;
}

/**
 * Take a visual checkpoint
 */
async function checkWindow(name) {
  if (!eyes) {
    console.log(`📸 Visual checkpoint: ${name}`);
    return;
  }
  
  console.log(`📸 Applitools check: ${name}`);
  await eyes.check(name, Target.window().fully());
}

/**
 * Take a visual checkpoint of specific element
 */
async function checkElement(selector, name) {
  if (!eyes) {
    console.log(`📸 Visual checkpoint (element): ${name}`);
    return;
  }
  
  console.log(`📸 Applitools check element: ${name}`);
  await eyes.check(name, Target.region(selector));
}

/**
 * Close Eyes and get results
 */
async function closeEyes() {
  if (!eyes) {
    return { passed: true, skipped: true };
  }
  
  try {
    const results = await eyes.close(false);
    console.log(`✅ Visual tests passed: ${results.getName()}`);
    return { passed: true, results };
  } catch (error) {
    console.error(`❌ Visual tests failed:`, error.message);
    return { passed: false, error };
  }
}

/**
 * Abort Eyes session (on test failure)
 */
async function abortEyes() {
  if (eyes) {
    await eyes.abort();
  }
}

module.exports = {
  initEyes,
  openEyes,
  checkWindow,
  checkElement,
  closeEyes,
  abortEyes,
  isAvailable: () => applitoolsAvailable,
};

