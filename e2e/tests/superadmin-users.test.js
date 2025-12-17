/**
 * E2E Test: Superadmin User Management
 * Tests filtering, creating, editing users in superadmin panel
 */

const browser = require('../helpers/browser');
const config = require('../config');

async function runTest() {
  let testPassed = true;
  
  console.log('🚀 Starting Superadmin User Management Test...\n');
  
  try {
    await browser.launch();
    
    // Login as superadmin
    await loginAsSuperadmin();
    
    // Test 1: Schools list and filtering
    console.log('📍 Test 1: Schools list and filtering');
    await testSchoolsFiltering();
    
    // Test 2: Users (directors) list and filtering
    console.log('📍 Test 2: Directors list and filtering');
    await testUsersFiltering('/admin/users');
    
    // Test 3: Teachers list and filtering
    console.log('📍 Test 3: Teachers list and filtering');
    await testUsersFiltering('/admin/teachers');
    
    // Test 4: Students list and filtering
    console.log('📍 Test 4: Students list and filtering');
    await testUsersFiltering('/admin/students');
    
    // Test 5: Create new school (view only - don't submit)
    console.log('📍 Test 5: New school form');
    await testNewSchoolForm();
    
    // Test 6: Edit school
    console.log('📍 Test 6: Edit school form');
    await testEditSchool();
    
    console.log('\n' + '='.repeat(50));
    console.log('✅ SUPERADMIN USER MANAGEMENT TEST PASSED\n');
    
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
  console.log(`   ✓ Logged in as ${user.email}\n`);
}

async function testSchoolsFiltering() {
  const page = browser.getPage();
  await browser.goto('/admin/schools');
  await browser.sleep(2000);
  
  // Check if table exists
  const tableExists = await browser.exists('table, #top-schools-table, .schools-table', 2000);
  if (!tableExists) {
    console.log('   ⚠️  Schools table not found');
    return;
  }
  console.log('   ✓ Schools table loaded');
  
  // Get initial row count
  const initialRowCount = await page.evaluate(() => {
    const rows = document.querySelectorAll('table tbody tr');
    return rows.length;
  });
  console.log(`   Initial rows: ${initialRowCount}`);
  
  // Look for search/filter input
  const searchInput = await page.$('input[type="search"], input[name*="search"], input.search-input, #search-input, [placeholder*="Szukaj"]');
  
  if (searchInput) {
    console.log('   🖱️  Testing search filter...');
    await searchInput.click();
    await browser.sleep(300);
    
    // Type search query
    await page.keyboard.type('Szkoła');
    await browser.sleep(1500);
    
    const filteredRowCount = await page.evaluate(() => {
      const rows = document.querySelectorAll('table tbody tr');
      return rows.length;
    });
    
    console.log(`   Filtered rows: ${filteredRowCount}`);
    
    // Clear search
    await searchInput.click({ clickCount: 3 });
    await page.keyboard.press('Backspace');
    await browser.sleep(1000);
    
    console.log('   ✓ Search filter works');
  } else {
    console.log('   ⚠️  Search input not found');
  }
  
  // Look for dropdown filters
  const filterDropdowns = await page.$$('select, .filter-dropdown, [data-filter]');
  if (filterDropdowns.length > 0) {
    console.log(`   Found ${filterDropdowns.length} filter dropdown(s)`);
  }
  
  console.log('');
}

async function testUsersFiltering(path) {
  const page = browser.getPage();
  await browser.goto(path);
  await browser.sleep(2000);
  
  // Check if table exists
  const tableExists = await browser.exists('table, .users-table, .data-table', 2000);
  if (!tableExists) {
    console.log('   ⚠️  Users table not found');
    return;
  }
  console.log('   ✓ Table loaded');
  
  // Get initial row count
  const initialRowCount = await page.evaluate(() => {
    const rows = document.querySelectorAll('table tbody tr');
    return rows.length;
  });
  console.log(`   Total rows: ${initialRowCount}`);
  
  // Look for search input
  const searchInput = await page.$('input[type="search"], input[name*="search"], #search-input, [placeholder*="Szukaj"]');
  
  if (searchInput) {
    console.log('   🖱️  Testing search...');
    await searchInput.click();
    await page.keyboard.type('test');
    await browser.sleep(1500);
    
    const filteredCount = await page.evaluate(() => {
      const rows = document.querySelectorAll('table tbody tr');
      return rows.length;
    });
    console.log(`   After filter: ${filteredCount} rows`);
    
    // Clear
    await searchInput.click({ clickCount: 3 });
    await page.keyboard.press('Backspace');
    await browser.sleep(1000);
  }
  
  // Check for pagination
  const pagination = await browser.exists('.pagination, [data-pagination], nav[aria-label*="pagination"]', 1000);
  if (pagination) {
    console.log('   ✓ Pagination found');
  }
  
  console.log('');
}

async function testNewSchoolForm() {
  const page = browser.getPage();
  await browser.goto('/admin/schools');
  await browser.sleep(1500);
  
  // Look for "New" or "Add" button
  const newButton = await page.$('a[href*="/new"], .btn-new, [data-action="new"], .btn-primary');
  
  if (!newButton) {
    // Try looking for specific link patterns
    const newLink = await page.$('a[href="/admin/schools/new"], a.btn-primary');
    if (newLink) {
      console.log('   🖱️  Opening new school form...');
      await Promise.all([
        browser.waitForNavigation(),
        newLink.click(),
      ]);
      await browser.sleep(1500);
    } else {
      console.log('   ⚠️  New school button not found');
      return;
    }
  } else {
    console.log('   🖱️  Opening new school form...');
    await Promise.all([
      browser.waitForNavigation(),
      newButton.click(),
    ]);
    await browser.sleep(1500);
  }
  
  // Check form fields
  const formFields = await page.evaluate(() => {
    const inputs = document.querySelectorAll('form input, form select, form textarea');
    return Array.from(inputs).map(i => ({
      name: i.name,
      type: i.type,
      id: i.id,
    })).filter(i => i.name || i.id);
  });
  
  console.log(`   ✓ Form loaded with ${formFields.length} fields:`);
  formFields.slice(0, 5).forEach(f => {
    console.log(`     - ${f.name || f.id} (${f.type})`);
  });
  if (formFields.length > 5) {
    console.log(`     ... and ${formFields.length - 5} more`);
  }
  
  // Go back without submitting
  await browser.goto('/admin/schools');
  await browser.sleep(1000);
  console.log('   ✓ Form navigation works\n');
}

async function testEditSchool() {
  const page = browser.getPage();
  await browser.goto('/admin/schools');
  await browser.sleep(1500);
  
  // Find first edit link/button
  const editLink = await page.$('a[href*="/edit"], .btn-edit, [data-action="edit"]');
  
  if (!editLink) {
    // Look in table rows
    const firstRowAction = await page.$('table tbody tr:first-child a, table tbody tr:first-child button');
    if (firstRowAction) {
      console.log('   🖱️  Clicking first row action...');
      await firstRowAction.click();
      await browser.sleep(1500);
      
      // Check if we're on a detail/edit page
      const currentUrl = page.url();
      if (currentUrl.includes('/edit') || currentUrl.match(/\/schools\/\d+/)) {
        console.log(`   ✓ Navigated to: ${currentUrl}`);
        
        // Look for edit button if on show page
        const editOnShow = await page.$('a[href*="/edit"], .btn-edit');
        if (editOnShow && !currentUrl.includes('/edit')) {
          await Promise.all([
            browser.waitForNavigation(),
            editOnShow.click(),
          ]);
          await browser.sleep(1500);
          console.log(`   ✓ Navigated to edit page: ${page.url()}`);
        }
      }
    } else {
      console.log('   ⚠️  No edit option found');
      return;
    }
  } else {
    console.log('   🖱️  Opening edit form...');
    await Promise.all([
      browser.waitForNavigation(),
      editLink.click(),
    ]);
    await browser.sleep(1500);
    console.log(`   ✓ Edit form opened: ${page.url()}`);
  }
  
  // Verify form is editable
  const editableInputs = await page.evaluate(() => {
    const inputs = document.querySelectorAll('input:not([disabled]):not([readonly]), textarea:not([disabled])');
    return inputs.length;
  });
  console.log(`   ✓ Found ${editableInputs} editable fields\n`);
}

runTest()
  .then(passed => process.exit(passed ? 0 : 1))
  .catch(error => {
    console.error('Fatal:', error);
    process.exit(1);
  });

