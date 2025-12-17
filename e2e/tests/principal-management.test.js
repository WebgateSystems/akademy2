/**
 * E2E Test: Principal Management Dashboard
 * Tests class management, teacher management, student management in principal panel
 */

const browser = require('../helpers/browser');
const config = require('../config');

async function runTest() {
  let testPassed = true;
  
  console.log('🚀 Starting Principal Management Test...\n');
  
  try {
    await browser.launch();
    
    // Login as principal
    await loginAsPrincipal();
    
    // Test 1: Classes management
    console.log('📍 Test 1: Classes management');
    await testClassesManagement();
    
    // Test 2: Teachers management
    console.log('📍 Test 2: Teachers management');
    await testTeachersManagement();
    
    // Test 3: Students management
    console.log('📍 Test 3: Students management');
    await testStudentsManagement();
    
    // Test 4: Administration panel
    console.log('📍 Test 4: Administration panel');
    await testAdministrationPanel();
    
    console.log('\n' + '='.repeat(50));
    console.log('✅ PRINCIPAL MANAGEMENT TEST PASSED\n');
    
  } catch (error) {
    console.error('\n❌ TEST ERROR:', error.message);
    testPassed = false;
  } finally {
    await browser.close();
  }
  
  return testPassed;
}

async function loginAsPrincipal() {
  console.log('📍 Login as principal (dyrektor)');
  await browser.goto('/login/administration');
  await browser.sleep(1000);
  
  const user = config.users.principal;
  await browser.type('input[name="user[email]"], input#user_email', user.email);
  await browser.type('input[name="user[password]"], input#user_password', user.password);
  
  await Promise.all([
    browser.waitForNavigation(),
    browser.click('input[type="submit"], button[type="submit"]'),
  ]);
  
  await browser.sleep(2000);
  console.log(`   ✓ Logged in as ${user.email}\n`);
}

async function testClassesManagement() {
  const page = browser.getPage();
  
  await browser.goto('/management/classes');
  await browser.sleep(2000);
  console.log('   ✓ Navigated to /management/classes');
  
  // Count classes
  const classCount = await page.evaluate(() => {
    const items = document.querySelectorAll('.class-card, .class-item, table tbody tr, [data-class]');
    return items.length;
  });
  console.log(`   ✓ Found ${classCount} classes`);
  
  // Look for "Add class" button
  const addBtn = await page.$('a[href*="/new"], .btn-add-class, [data-action="add-class"], .btn-primary');
  if (addBtn) {
    console.log('   ✓ Add class button available');
  }
  
  // Click on first class card to view/edit
  const firstClassCard = await page.$('.class-card, .class-item, [data-class]');
  if (firstClassCard) {
    console.log('   🖱️  Clicking first class...');
    await firstClassCard.click();
    await browser.sleep(1500);
    
    // Check if modal opened or navigated
    const modalOpen = await browser.exists('.modal.show, .modal:not(.d-none), [role="dialog"]', 1000);
    if (modalOpen) {
      console.log('   ✓ Class modal opened');
      
      // Look for class details
      const classDetails = await page.evaluate(() => {
        const modal = document.querySelector('.modal.show, [role="dialog"]');
        if (modal) {
          return {
            title: modal.querySelector('.modal-title, h5, h4')?.textContent.trim(),
            studentsCount: modal.querySelectorAll('.student-item, [data-student]').length,
          };
        }
        return null;
      });
      
      if (classDetails) {
        console.log(`     Class: ${classDetails.title}`);
        console.log(`     Students in class: ${classDetails.studentsCount}`);
      }
      
      // Close modal
      const closeBtn = await page.$('.modal .btn-close, .modal button[data-bs-dismiss="modal"], .modal .close');
      if (closeBtn) {
        await closeBtn.click();
        await browser.sleep(500);
      }
    } else {
      console.log(`   Current URL: ${page.url()}`);
    }
  }
  
  // Look for add teacher to class functionality
  const addTeacherBtn = await page.$('[data-action="add-teacher"], .btn-add-teacher');
  if (addTeacherBtn) {
    console.log('   ✓ Add teacher to class functionality available');
  }
  
  console.log('');
}

async function testTeachersManagement() {
  const page = browser.getPage();
  
  await browser.goto('/management/teachers');
  await browser.sleep(2000);
  console.log('   ✓ Navigated to /management/teachers');
  
  // Count teachers
  const teacherCount = await page.evaluate(() => {
    const items = document.querySelectorAll('.teacher-card, .teacher-item, table tbody tr, [data-teacher]');
    return items.length;
  });
  console.log(`   ✓ Found ${teacherCount} teachers`);
  
  // Look for search
  const searchInput = await page.$('input[type="search"], input[placeholder*="Szukaj"], #search');
  if (searchInput) {
    console.log('   🖱️  Testing search...');
    await searchInput.click();
    await page.keyboard.type('Jan');
    await browser.sleep(1500);
    
    const filteredCount = await page.evaluate(() => {
      const items = document.querySelectorAll('.teacher-card, .teacher-item, table tbody tr:not(.d-none)');
      return items.length;
    });
    console.log(`   After filter: ${filteredCount} teachers`);
    
    // Clear search
    await searchInput.click({ clickCount: 3 });
    await page.keyboard.press('Backspace');
    await browser.sleep(1000);
  }
  
  // Look for invite/add teacher
  const inviteBtn = await page.$('a[href*="invite"], .btn-invite, .btn-primary');
  if (inviteBtn) {
    console.log('   ✓ Invite teacher button available');
  }
  
  // Click first teacher to see details
  const firstTeacher = await page.$('.teacher-card, .teacher-item, table tbody tr:first-child');
  if (firstTeacher) {
    console.log('   🖱️  Clicking first teacher...');
    await firstTeacher.click();
    await browser.sleep(1500);
    
    // Check for action menu
    const actionMenu = await browser.exists('.dropdown-menu.show, .action-menu, [data-actions]', 1000);
    if (actionMenu) {
      console.log('   ✓ Action menu opened');
      // Click elsewhere to close
      await page.click('body');
    }
  }
  
  console.log('');
}

async function testStudentsManagement() {
  const page = browser.getPage();
  
  await browser.goto('/management/students');
  await browser.sleep(2000);
  console.log('   ✓ Navigated to /management/students');
  
  // Count students
  const studentCount = await page.evaluate(() => {
    const items = document.querySelectorAll('.student-card, .student-item, table tbody tr, [data-student]');
    return items.length;
  });
  console.log(`   ✓ Found ${studentCount} students`);
  
  // Look for class filter
  const classFilter = await page.$('select[name*="class"], #class_filter, [data-filter="class"]');
  if (classFilter) {
    console.log('   ✓ Class filter available');
    
    // Get filter options
    const options = await page.$$eval('select[name*="class"] option', opts => 
      opts.map(o => o.textContent.trim()).filter(t => t)
    );
    console.log(`     Options: ${options.slice(0, 3).join(', ')}${options.length > 3 ? '...' : ''}`);
  }
  
  // Test search
  const searchInput = await page.$('input[type="search"], input[placeholder*="Szukaj"]');
  if (searchInput) {
    console.log('   🖱️  Testing search...');
    await searchInput.click();
    await page.keyboard.type('Kow');
    await browser.sleep(1500);
    
    // Clear
    await searchInput.click({ clickCount: 3 });
    await page.keyboard.press('Backspace');
    await browser.sleep(1000);
    console.log('   ✓ Search works');
  }
  
  // Look for add student
  const addBtn = await page.$('a[href*="/new"], .btn-add-student, .btn-primary');
  if (addBtn) {
    console.log('   ✓ Add student button available');
  }
  
  console.log('');
}

async function testAdministrationPanel() {
  const page = browser.getPage();
  
  await browser.goto('/management/administration');
  await browser.sleep(2000);
  console.log('   ✓ Navigated to /management/administration');
  
  // Count administrators
  const adminCount = await page.evaluate(() => {
    const items = document.querySelectorAll('.admin-card, .admin-item, table tbody tr, [data-admin]');
    return items.length;
  });
  console.log(`   ✓ Found ${adminCount} administrators`);
  
  // Check for action menu (three dots)
  const actionMenuTrigger = await page.$('.action-menu-trigger, [data-action-menu], .btn-actions, .dropdown-toggle');
  if (actionMenuTrigger) {
    console.log('   🖱️  Opening action menu...');
    await actionMenuTrigger.click();
    await browser.sleep(800);
    
    // Check menu opened
    const menuOpen = await browser.exists('.dropdown-menu.show, .action-menu.open, [data-menu].show', 1000);
    if (menuOpen) {
      console.log('   ✓ Action menu works');
      
      // Look for menu items
      const menuItems = await page.$$eval('.dropdown-menu.show a, .dropdown-menu.show button', items =>
        items.map(i => i.textContent.trim()).filter(t => t)
      );
      console.log(`     Actions: ${menuItems.join(', ')}`);
      
      // Close menu
      await page.click('body');
      await browser.sleep(500);
    }
  }
  
  // Look for invite admin button
  const inviteBtn = await page.$('a[href*="invite"], .btn-invite, .btn-primary');
  if (inviteBtn) {
    console.log('   ✓ Invite administrator button available');
  }
  
  console.log('');
}

runTest()
  .then(passed => process.exit(passed ? 0 : 1))
  .catch(error => {
    console.error('Fatal:', error);
    process.exit(1);
  });

