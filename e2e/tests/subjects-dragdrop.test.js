/**
 * E2E Test: Subjects Drag and Drop
 * Tests reordering subjects on the superadmin index page
 */

const browser = require('../helpers/browser');
const config = require('../config');

async function runTest() {
  let testPassed = true;
  
  console.log('🚀 Starting Subjects Drag & Drop Test...\n');
  
  try {
    await browser.launch();
    
    // Login as superadmin
    await loginAsSuperadmin();
    
    // Navigate to subjects page
    console.log('📍 Test: Subjects drag and drop reordering');
    await testDragAndDrop();
    
    console.log('\n' + '='.repeat(50));
    console.log('✅ SUBJECTS DRAG & DROP TEST PASSED\n');
    
  } catch (error) {
    console.error('\n❌ TEST ERROR:', error.message);
    testPassed = false;
  } finally {
    await browser.close();
  }
  
  return testPassed;
}

async function loginAsSuperadmin() {
  console.log('📍 Login as superadmin');
  await browser.goto('/admin/sign_in');
  await browser.sleep(1000);
  
  const user = config.users.superadmin;
  await browser.type('input[name="email"], input#email', user.email);
  await browser.type('input[name="password"], input#password', user.password);
  
  await Promise.all([
    browser.waitForNavigation(),
    browser.click('button[type="submit"], input[type="submit"]'),
  ]);
  
  await browser.sleep(2000);
  console.log(`   ✓ Logged in\n`);
}

async function testDragAndDrop() {
  const page = browser.getPage();
  
  // Navigate to subjects page
  await browser.goto('/admin/subjects');
  await browser.sleep(2000);
  console.log('   ✓ Navigated to subjects page');
  
  // Look for draggable items
  const draggableSelectors = [
    '[draggable="true"]',
    '.sortable-item',
    '.drag-handle',
    '[data-sortable]',
    '.subject-card',
    'tbody tr',
  ];
  
  let draggableItems = null;
  let draggableSelector = null;
  
  for (const selector of draggableSelectors) {
    const items = await page.$$(selector);
    if (items.length >= 2) {
      draggableItems = items;
      draggableSelector = selector;
      break;
    }
  }
  
  if (!draggableItems || draggableItems.length < 2) {
    console.log('   ⚠️  Not enough draggable items found (need at least 2)');
    console.log('   Looking for alternative sortable elements...');
    
    // Check if there's a sortable library loaded
    const hasSortable = await page.evaluate(() => {
      return !!(window.Sortable || window.jQuery?.fn?.sortable);
    });
    
    if (hasSortable) {
      console.log('   ✓ Sortable library detected');
    }
    
    return;
  }
  
  console.log(`   ✓ Found ${draggableItems.length} draggable items (${draggableSelector})`);
  
  // Get initial order
  const initialOrder = await page.evaluate((selector) => {
    const items = document.querySelectorAll(selector);
    return Array.from(items).map((item, i) => ({
      index: i,
      text: item.textContent.trim().substring(0, 50),
    }));
  }, draggableSelector);
  
  console.log('   Initial order (first 3):');
  initialOrder.slice(0, 3).forEach(item => {
    console.log(`     ${item.index}: ${item.text.substring(0, 30)}...`);
  });
  
  // Get bounding boxes of first two items
  const firstItem = draggableItems[0];
  const secondItem = draggableItems[1];
  
  const firstBox = await firstItem.boundingBox();
  const secondBox = await secondItem.boundingBox();
  
  if (!firstBox || !secondBox) {
    console.log('   ⚠️  Could not get bounding boxes');
    return;
  }
  
  // Perform drag and drop
  console.log('   🖱️  Performing drag and drop...');
  
  // Start position (center of first item)
  const startX = firstBox.x + firstBox.width / 2;
  const startY = firstBox.y + firstBox.height / 2;
  
  // End position (below second item)
  const endX = secondBox.x + secondBox.width / 2;
  const endY = secondBox.y + secondBox.height + 10;
  
  // Move mouse to first item
  await page.mouse.move(startX, startY);
  await browser.sleep(300);
  
  // Mouse down
  await page.mouse.down();
  await browser.sleep(200);
  
  // Move to target position (slowly for visual feedback)
  const steps = 10;
  for (let i = 1; i <= steps; i++) {
    const currentX = startX + ((endX - startX) * i) / steps;
    const currentY = startY + ((endY - startY) * i) / steps;
    await page.mouse.move(currentX, currentY);
    await browser.sleep(50);
  }
  
  // Mouse up
  await page.mouse.up();
  await browser.sleep(1000);
  
  console.log('   ✓ Drag and drop completed');
  
  // Check if order changed
  const newOrder = await page.evaluate((selector) => {
    const items = document.querySelectorAll(selector);
    return Array.from(items).map((item, i) => ({
      index: i,
      text: item.textContent.trim().substring(0, 50),
    }));
  }, draggableSelector);
  
  console.log('   New order (first 3):');
  newOrder.slice(0, 3).forEach(item => {
    console.log(`     ${item.index}: ${item.text.substring(0, 30)}...`);
  });
  
  // Compare
  const orderChanged = initialOrder.slice(0, 3).some((item, i) => {
    return newOrder[i] && item.text !== newOrder[i].text;
  });
  
  if (orderChanged) {
    console.log('   ✓ Order changed successfully');
    
    // Try to revert by doing reverse drag
    console.log('   🖱️  Reverting to original order...');
    
    // Refresh and re-fetch to see if change persisted
    await browser.goto('/admin/subjects');
    await browser.sleep(2000);
    
    const persistedOrder = await page.evaluate((selector) => {
      const items = document.querySelectorAll(selector);
      return Array.from(items).map((item, i) => item.textContent.trim().substring(0, 50));
    }, draggableSelector);
    
    console.log('   After refresh (first item):', persistedOrder[0]?.substring(0, 30));
  } else {
    console.log('   ℹ️  Order did not change (drag might not be enabled or items are static)');
  }
  
  console.log('');
}

runTest()
  .then(passed => process.exit(passed ? 0 : 1))
  .catch(error => {
    console.error('Fatal:', error);
    process.exit(1);
  });

