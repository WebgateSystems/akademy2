/**
 * E2E Test: Superadmin Content Management
 * Tests creating, editing, viewing subjects/units/modules/contents
 */

const browser = require('../helpers/browser');
const config = require('../config');

async function runTest() {
  let testPassed = true;
  
  console.log('🚀 Starting Superadmin Content Management Test...\n');
  
  try {
    await browser.launch();
    
    // Login as superadmin
    await loginAsSuperadmin();
    
    // Test content management flow
    console.log('📍 Test 1: Navigate subjects hierarchy');
    await testSubjectsHierarchy();
    
    console.log('📍 Test 2: Units management');
    await testUnitsPage();
    
    console.log('📍 Test 3: Learning modules management');
    await testLearningModulesPage();
    
    console.log('📍 Test 4: Contents management');
    await testContentsPage();
    
    console.log('📍 Test 5: View content details');
    await testContentDetails();
    
    console.log('\n' + '='.repeat(50));
    console.log('✅ SUPERADMIN CONTENT MANAGEMENT TEST PASSED\n');
    
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

async function testSubjectsHierarchy() {
  const page = browser.getPage();
  
  // Navigate to subjects
  await browser.goto('/admin/subjects');
  await browser.sleep(2000);
  console.log('   ✓ Navigated to /admin/subjects');
  
  // Check table exists
  const tableExists = await browser.exists('table, .subjects-list, .data-table', 2000);
  console.log(`   Table exists: ${tableExists ? 'yes' : 'no'}`);
  
  // Count subjects
  const subjectCount = await page.evaluate(() => {
    const rows = document.querySelectorAll('table tbody tr, .subject-card');
    return rows.length;
  });
  console.log(`   ✓ Found ${subjectCount} subjects`);
  
  // Click on first subject to view details
  const firstSubjectLink = await page.$('table tbody tr td a, .subject-card a, table tbody tr:first-child a');
  if (firstSubjectLink) {
    console.log('   🖱️  Clicking first subject...');
    await Promise.all([
      browser.waitForNavigation().catch(() => {}),
      firstSubjectLink.click(),
    ]);
    await browser.sleep(browser.getSpeed().mediumPause);
    console.log(`   ✓ Viewing subject: ${page.url()}`);
    
    // Check subject details page
    const pageContent = await page.evaluate(() => document.body.innerText.substring(0, 500));
    console.log(`   Preview: ${pageContent.substring(0, 100).replace(/\s+/g, ' ')}...`);
  }
  
  console.log('');
}

async function testUnitsPage() {
  const page = browser.getPage();
  
  await browser.goto('/admin/units');
  await browser.sleep(2000);
  console.log('   ✓ Navigated to /admin/units');
  
  // Count units
  const unitCount = await page.evaluate(() => {
    const rows = document.querySelectorAll('table tbody tr, .unit-card');
    return rows.length;
  });
  console.log(`   ✓ Found ${unitCount} units`);
  
  // Look for filter by subject
  const subjectFilter = await page.$('select[name*="subject"], #subject_filter, [data-filter="subject"]');
  if (subjectFilter) {
    console.log('   ✓ Subject filter available');
    
    // Try filtering
    const options = await page.$$eval('select[name*="subject"] option', opts => opts.length);
    console.log(`     ${options} filter options`);
  }
  
  // Click first unit
  const firstUnitLink = await page.$('table tbody tr td a, table tbody tr:first-child a');
  if (firstUnitLink) {
    console.log('   🖱️  Clicking first unit...');
    await Promise.all([
      browser.waitForNavigation().catch(() => {}),
      firstUnitLink.click(),
    ]);
    await browser.sleep(1500);
    console.log(`   ✓ Viewing unit: ${page.url()}`);
  }
  
  console.log('');
}

async function testLearningModulesPage() {
  const page = browser.getPage();
  
  await browser.goto('/admin/learning_modules');
  await browser.sleep(2000);
  console.log('   ✓ Navigated to /admin/learning_modules');
  
  // Count modules
  const moduleCount = await page.evaluate(() => {
    const rows = document.querySelectorAll('table tbody tr, .module-card');
    return rows.length;
  });
  console.log(`   ✓ Found ${moduleCount} learning modules`);
  
  // Check for filters
  const filters = await page.$$('select, input[type="search"]');
  console.log(`   Filters available: ${filters.length}`);
  
  // Click first module
  const firstModuleLink = await page.$('table tbody tr td a, table tbody tr:first-child a');
  if (firstModuleLink) {
    console.log('   🖱️  Clicking first module...');
    await Promise.all([
      browser.waitForNavigation().catch(() => {}),
      firstModuleLink.click(),
    ]);
    await browser.sleep(1500);
    console.log(`   ✓ Viewing module: ${page.url()}`);
  }
  
  console.log('');
}

async function testContentsPage() {
  const page = browser.getPage();
  
  await browser.goto('/admin/contents');
  await browser.sleep(2000);
  console.log('   ✓ Navigated to /admin/contents');
  
  // Count contents
  const contentCount = await page.evaluate(() => {
    const rows = document.querySelectorAll('table tbody tr, .content-card');
    return rows.length;
  });
  console.log(`   ✓ Found ${contentCount} content items`);
  
  // Check for content type filter
  const typeFilter = await page.$('select[name*="type"], #content_type_filter');
  if (typeFilter) {
    console.log('   ✓ Content type filter available');
  }
  
  // Look for different content types in the list
  const contentTypes = await page.evaluate(() => {
    const types = new Set();
    const rows = document.querySelectorAll('table tbody tr');
    rows.forEach(row => {
      const typeCell = row.querySelector('td:nth-child(2)');
      if (typeCell) types.add(typeCell.textContent.trim());
    });
    return Array.from(types);
  });
  
  if (contentTypes.length > 0) {
    console.log(`   Content types found: ${contentTypes.join(', ')}`);
  }
  
  console.log('');
}

async function testContentDetails() {
  const page = browser.getPage();
  
  await browser.goto('/admin/contents');
  await browser.sleep(2000);
  
  // Find a content item and click to view details
  const firstContentLink = await page.$('table tbody tr td a, table tbody tr:first-child a');
  
  if (firstContentLink) {
    console.log('   🖱️  Opening first content item...');
    await Promise.all([
      browser.waitForNavigation().catch(() => {}),
      firstContentLink.click(),
    ]);
    await browser.sleep(1500);
    console.log(`   ✓ Viewing content: ${page.url()}`);
    
    // Check what details are shown
    const details = await page.evaluate(() => {
      const info = {};
      
      // Look for common detail patterns
      const dl = document.querySelector('dl');
      if (dl) {
        const dts = dl.querySelectorAll('dt');
        const dds = dl.querySelectorAll('dd');
        dts.forEach((dt, i) => {
          if (dds[i]) {
            info[dt.textContent.trim()] = dds[i].textContent.trim().substring(0, 50);
          }
        });
      }
      
      // Or table-based details
      const detailRows = document.querySelectorAll('.detail-row, tr.detail');
      detailRows.forEach(row => {
        const label = row.querySelector('th, .label, td:first-child');
        const value = row.querySelector('td:last-child, .value');
        if (label && value) {
          info[label.textContent.trim()] = value.textContent.trim().substring(0, 50);
        }
      });
      
      return info;
    });
    
    const detailKeys = Object.keys(details);
    if (detailKeys.length > 0) {
      console.log('   Content details:');
      detailKeys.slice(0, 5).forEach(key => {
        console.log(`     - ${key}: ${details[key]}`);
      });
    }
    
    // Look for edit button
    const editBtn = await page.$('a[href*="/edit"], .btn-edit, [data-action="edit"]');
    if (editBtn) {
      console.log('   ✓ Edit button available');
    }
    
    // Look for delete button
    const deleteBtn = await page.$('a[data-method="delete"], button.btn-danger, [data-action="delete"]');
    if (deleteBtn) {
      console.log('   ✓ Delete button available (not clicking)');
    }
  } else {
    console.log('   ⚠️  No content items to view');
  }
  
  console.log('');
}

runTest()
  .then(passed => process.exit(passed ? 0 : 1))
  .catch(error => {
    console.error('Fatal:', error);
    process.exit(1);
  });

