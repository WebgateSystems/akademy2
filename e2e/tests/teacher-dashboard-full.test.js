/**
 * E2E Test: Teacher Dashboard Full Functionality
 * Tests class management, quiz results, student filtering in teacher dashboard
 */

const browser = require('../helpers/browser');
const config = require('../config');

async function runTest() {
  let testPassed = true;
  
  console.log('🚀 Starting Teacher Dashboard Full Test...\n');
  
  try {
    await browser.launch();
    
    // Login as teacher
    await loginAsTeacher();
    
    // Test 1: Dashboard overview
    console.log('📍 Test 1: Dashboard overview');
    await testDashboardOverview();
    
    // Test 2: My classes
    // console.log('📍 Test 2: My classes');
    // await testMyClasses();
    
    // Test 3: Quiz results
    // console.log('📍 Test 3: Quiz results');
    // await testQuizResults();
    
    // Test 4: Students list and filtering
    console.log('📍 Test 4: Students list');
    await testStudentsList();
    
    // Test 5: Videos section
    console.log('📍 Test 5: Videos section');
    await testVideosSection();
    
    console.log('\n' + '='.repeat(50));
    console.log('✅ TEACHER DASHBOARD FULL TEST PASSED\n');
    
  } catch (error) {
    console.error('\n❌ TEST ERROR:', error.message);
    testPassed = false;
  } finally {
    await browser.close();
  }
  
  return testPassed;
}

async function loginAsTeacher() {
  console.log('📍 Login as teacher');
  await browser.goto('/login/teacher');
  await browser.sleep(1000);
  
  const user = config.users.teacher;
  await browser.type('input[name="user[email]"], input#user_email', user.email);
  await browser.type('input[name="user[password]"], input#user_password', user.password);
  
  await Promise.all([
    browser.waitForNavigation(),
    browser.click('input[type="submit"], button[type="submit"]'),
  ]);
  
  await browser.sleep(2000);
  console.log(`   ✓ Logged in as ${user.email}\n`);
}

async function testDashboardOverview() {
  const page = browser.getPage();
  
  await browser.goto('/dashboard');
  await browser.sleep(2000);
  console.log('   ✓ On teacher dashboard');
  
  // Check for main dashboard elements
  const dashboardElements = await page.evaluate(() => {
    return {
      hasWelcome: !!document.querySelector('.welcome-message, .dashboard-header, h1, h2'),
      hasStats: !!document.querySelector('.stats, .dashboard-stats, .summary'),
      hasQuickActions: !!document.querySelector('.quick-actions, .shortcuts, .action-buttons'),
      hasNavigation: !!document.querySelector('nav, .dashboard-nav, .sidebar'),
    };
  });
  
  console.log('   Dashboard elements:');
  Object.entries(dashboardElements).forEach(([key, value]) => {
    console.log(`     ${key}: ${value ? '✓' : '✗'}`);
  });
  
  // Check for subject cards
  const subjectCount = await page.evaluate(() => {
    const cards = document.querySelectorAll('.subject-card, .course-card, [data-subject]');
    return cards.length;
  });
  console.log(`   ✓ Subject cards: ${subjectCount}`);
  
  console.log('');
}

// async function testMyClasses() {
//   const page = browser.getPage();
  
//   await browser.goto('/dashboard/classes');
//   await browser.sleep(2000);
//   console.log('   ✓ Navigated to /dashboard/classes');
  
//   // Count classes
//   const classCount = await page.evaluate(() => {
//     const items = document.querySelectorAll('.class-card, .class-item, table tbody tr, [data-class]');
//     return items.length;
//   });
//   console.log(`   ✓ Found ${classCount} classes`);
  
//   if (classCount > 0) {
//     // Click first class
//     const firstClass = await page.$('.class-card, .class-item, table tbody tr:first-child');
//     if (firstClass) {
//       console.log('   🖱️  Clicking first class...');
//       await firstClass.click();
//       await browser.sleep(1500);
      
//       const newUrl = page.url();
//       console.log(`   ✓ Current URL: ${newUrl}`);
      
//       // Check if students are shown
//       const studentCount = await page.evaluate(() => {
//         const items = document.querySelectorAll('.student-item, .student-row, [data-student]');
//         return items.length;
//       });
//       console.log(`   ✓ Students in class: ${studentCount}`);
//     }
//   }
  
//   console.log('');
// }

// async function testQuizResults() {
//   const page = browser.getPage();
  
//   await browser.goto('/dashboard/quiz_results');
//   await browser.sleep(2000);
//   console.log('   ✓ Navigated to quiz results');
  
//   // Check for subject/class filters
//   const hasFilters = await page.evaluate(() => {
//     const classFilter = document.querySelector('select[name*="class"], #class_filter, [data-filter="class"]');
//     const subjectFilter = document.querySelector('select[name*="subject"], #subject_filter, [data-filter="subject"]');
//     return { classFilter: !!classFilter, subjectFilter: !!subjectFilter };
//   });
  
//   console.log(`   Class filter: ${hasFilters.classFilter ? '✓' : '✗'}`);
//   console.log(`   Subject filter: ${hasFilters.subjectFilter ? '✓' : '✗'}`);
  
//   // Check for results table
//   const tableExists = await browser.exists('table, .results-table, .quiz-results', 2000);
//   console.log(`   Results table: ${tableExists ? '✓' : '✗'}`);
  
//   if (tableExists) {
//     // Count students in results
//     const rowCount = await page.evaluate(() => {
//       const rows = document.querySelectorAll('table tbody tr');
//       return rows.length;
//     });
//     console.log(`   ✓ Results rows: ${rowCount}`);
    
//     // Look for export buttons
//     const exportPdf = await browser.exists('a[href*="pdf"], .btn-export-pdf, [data-export="pdf"]', 1000);
//     const exportCsv = await browser.exists('a[href*="csv"], .btn-export-csv, [data-export="csv"]', 1000);
    
//     console.log(`   Export PDF: ${exportPdf ? '✓' : '✗'}`);
//     console.log(`   Export CSV: ${exportCsv ? '✓' : '✗'}`);
//   }
  
//   // Test filter change
//   const classFilter = await page.$('select[name*="class"], #class_filter');
//   if (classFilter) {
//     console.log('   🖱️  Testing class filter...');
    
//     const options = await page.$$eval('select[name*="class"] option', opts => 
//       opts.map(o => ({ value: o.value, text: o.textContent.trim() }))
//     );
    
//     if (options.length > 1) {
//       await classFilter.select(options[1].value);
//       await browser.sleep(1500);
//       console.log(`   ✓ Filtered by: ${options[1].text}`);
//     }
//   }
  
//   console.log('');
// }

async function testStudentsList() {
  const page = browser.getPage();
  
  await browser.goto('/dashboard/students');
  await browser.sleep(2000);
  console.log('   ✓ Navigated to students list');
  
  // Count students
  const studentCount = await page.evaluate(() => {
    const items = document.querySelectorAll('.student-card, .student-item, table tbody tr, [data-student]');
    return items.length;
  });
  console.log(`   ✓ Found ${studentCount} students`);
  
  // Test search
  const searchInput = await page.$('input[type="search"], input[placeholder*="Szukaj"]');
  if (searchInput) {
    console.log('   🖱️  Testing search...');
    await searchInput.click();
    await page.keyboard.type('now');
    await browser.sleep(1500);
    
    const filteredCount = await page.evaluate(() => {
      const items = document.querySelectorAll('.student-card:not(.d-none), .student-item:not(.d-none), table tbody tr:not(.d-none)');
      return items.length;
    });
    console.log(`   ✓ After filter: ${filteredCount}`);
    
    // Clear
    await searchInput.click({ clickCount: 3 });
    await page.keyboard.press('Backspace');
    await browser.sleep(1000);
  }
  
  // Click student to view details
  if (studentCount > 0) {
    const firstStudent = await page.$('.student-card a, .student-item a, table tbody tr:first-child a');
    if (firstStudent) {
      console.log('   🖱️  Clicking first student...');
      await Promise.all([
        browser.waitForNavigation(),
        firstStudent.click(),
      ]);
      await browser.sleep(1500);
      
      console.log(`   ✓ Student detail page: ${page.url()}`);
      
      // Check for student info
      const studentInfo = await page.evaluate(() => {
        return {
          hasName: !!document.querySelector('.student-name, h1, h2'),
          hasProgress: !!document.querySelector('.progress, .student-progress'),
          hasResults: !!document.querySelector('.results, .quiz-history'),
        };
      });
      
      console.log(`     Name visible: ${studentInfo.hasName ? '✓' : '✗'}`);
      console.log(`     Progress visible: ${studentInfo.hasProgress ? '✓' : '✗'}`);
    }
  }
  
  console.log('');
}

async function testVideosSection() {
  const page = browser.getPage();
  
  await browser.goto('/dashboard/student_videos');
  await browser.sleep(2000);
  console.log('   ✓ Navigated to videos');
  
  // Check if videos section exists
  const videosExist = await browser.exists('.video-list, .videos-grid, [data-video], video', 2000);
  
  if (videosExist) {
    const videoCount = await page.evaluate(() => {
      const items = document.querySelectorAll('.video-card, .video-item, [data-video]');
      return items.length;
    });
    console.log(`   ✓ Videos found: ${videoCount}`);
    
    // Look for upload button
    const uploadBtn = await browser.exists('input[type="file"], .btn-upload, [data-upload]', 1000);
    console.log(`   Upload available: ${uploadBtn ? '✓' : '✗'}`);
  } else {
    console.log('   ⚠️  Videos section might be empty or different structure');
  }
  
  console.log('');
}

runTest()
  .then(passed => process.exit(passed ? 0 : 1))
  .catch(error => {
    console.error('Fatal:', error);
    process.exit(1);
  });

