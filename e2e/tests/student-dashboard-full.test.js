/**
 * E2E Test: Student Dashboard Full Functionality
 * Tests learning modules, quizzes, videos, progress tracking
 */

const browser = require('../helpers/browser');
const auth = require('../helpers/auth');

async function runTest() {
  let testPassed = true;
  
  console.log('🚀 Starting Student Dashboard Full Test...\n');
  
  try {
    await browser.launch();
    
    // Login as student
    console.log('📍 Login as student (via phone + PIN)');
    await auth.loginAsStudent();
    console.log('   ✓ Logged in as student\n');
    
    // Test 1: Dashboard overview (subjects)
    console.log('📍 Test 1: Dashboard overview');
    await testDashboardOverview();
    
    // Test 2: Subject modules
    console.log('📍 Test 2: Subject modules');
    await testSubjectModules();
    
    // Test 3: Learning module content
    console.log('📍 Test 3: Learning module content');
    await testLearningModuleContent();
    
    // Test 4: Videos section
    console.log('📍 Test 4: Videos section');
    await testVideosSection();
    
    // Test 5: Quiz functionality
    console.log('📍 Test 5: Quiz functionality');
    await testQuizFunctionality();
    
    console.log('\n' + '='.repeat(50));
    console.log('✅ STUDENT DASHBOARD FULL TEST PASSED\n');
    
  } catch (error) {
    console.error('\n❌ TEST ERROR:', error.message);
    testPassed = false;
  } finally {
    await browser.close();
  }
  
  return testPassed;
}

async function testDashboardOverview() {
  const page = browser.getPage();
  
  await browser.goto('/home');
  await browser.sleep(2000);
  console.log('   ✓ On student dashboard (/home)');
  
  // Count subject cards
  const subjectCount = await page.evaluate(() => {
    const cards = document.querySelectorAll('.subject-card, .course-card, [data-subject], .class-result');
    return cards.length;
  });
  console.log(`   ✓ Subject cards: ${subjectCount}`);
  
  // Check for progress indicators
  const hasProgress = await page.evaluate(() => {
    const progressBars = document.querySelectorAll('.progress, .progress-bar, [data-progress]');
    return progressBars.length;
  });
  console.log(`   Progress indicators: ${hasProgress}`);
  
  // Check for navigation menu
  const navItems = await page.evaluate(() => {
    const items = document.querySelectorAll('nav a, .nav-item, .menu-item');
    return items.length;
  });
  console.log(`   Nav items: ${navItems}`);
  
  console.log('');
}

async function testSubjectModules() {
  const page = browser.getPage();
  
  // Click on first subject
  await browser.goto('/home');
  await browser.sleep(1500);
  
  const firstSubject = await page.$('.subject-card a, .course-card a, [data-subject] a, .class-result');
  if (firstSubject) {
    console.log('   🖱️  Clicking first subject...');
    await Promise.all([
      browser.waitForNavigation(),
      firstSubject.click(),
    ]);
    await browser.sleep(2000);
    
    console.log(`   ✓ Subject page: ${page.url()}`);
    
    // Count modules
    const moduleCount = await page.evaluate(() => {
      const modules = document.querySelectorAll('.module-card, .module-item, [data-module], .lesson-card');
      return modules.length;
    });
    console.log(`   ✓ Modules: ${moduleCount}`);
    
    // Check for description
    const hasDescription = await browser.exists('.subject-description, .description, [data-description]', 1000);
    console.log(`   Has description: ${hasDescription ? '✓' : '✗'}`);
    
    // Check for progress
    const subjectProgress = await page.evaluate(() => {
      const progressEl = document.querySelector('.progress-value, .progress-text, [data-progress-value]');
      return progressEl ? progressEl.textContent.trim() : null;
    });
    if (subjectProgress) {
      console.log(`   Progress: ${subjectProgress}`);
    }
  } else {
    console.log('   ⚠️  No subjects found');
  }
  
  console.log('');
}

async function testLearningModuleContent() {
  const page = browser.getPage();
  
  // Navigate to a module
  const firstModule = await page.$('.module-card a, .module-item a, [data-module] a, .lesson-card a');
  if (firstModule) {
    console.log('   🖱️  Clicking first module...');
    await Promise.all([
      browser.waitForNavigation(),
      firstModule.click(),
    ]);
    await browser.sleep(2000);
    
    console.log(`   ✓ Module page: ${page.url()}`);
    
    // Check content types available
    const contentInfo = await page.evaluate(() => {
      return {
        hasVideo: !!document.querySelector('video, .video-player, iframe[src*="youtube"]'),
        hasText: !!document.querySelector('.content-text, .lesson-content, article'),
        hasQuiz: !!document.querySelector('.quiz, .quiz-button, a[href*="quiz"], [data-quiz]'),
        hasInfographic: !!document.querySelector('img.infographic, .infographic, [data-infographic]'),
        hasSubtitles: !!document.querySelector('.video-subtitles-btn, #subtitles-toggle, track'),
      };
    });
    
    console.log('   Content available:');
    Object.entries(contentInfo).forEach(([key, value]) => {
      console.log(`     ${key}: ${value ? '✓' : '✗'}`);
    });
    
    // If video exists, test player controls
    if (contentInfo.hasVideo) {
      const videoEl = await page.$('video');
      if (videoEl) {
        console.log('   🎬 Testing video player...');
        
        // Try play/pause
        await videoEl.click();
        await browser.sleep(1000);
        
        const isPlaying = await page.evaluate(() => {
          const video = document.querySelector('video');
          return video && !video.paused;
        });
        console.log(`   Video playing: ${isPlaying ? '✓' : '✗'}`);
        
        // Pause
        await videoEl.click();
        await browser.sleep(500);
      }
    }
    
    // Check for certificate button (if quiz passed)
    const hasCertificate = await browser.exists('.certificate-btn, a[href*="certificate"], [data-certificate]', 1000);
    console.log(`   Certificate available: ${hasCertificate ? '✓' : '✗'}`);
  }
  
  console.log('');
}

async function testVideosSection() {
  const page = browser.getPage();
  
  await browser.goto('/home/videos');
  await browser.sleep(2000);
  console.log('   ✓ Navigated to videos (/home/videos)');
  
  // Check for view toggle (grid/list)
  const viewToggle = await browser.exists('[data-view="grid"], [data-view="list"], .view-toggle, .btn-group', 1000);
  console.log(`   View toggle: ${viewToggle ? '✓' : '✗'}`);
  
  // Count videos
  const videoCount = await page.evaluate(() => {
    const videos = document.querySelectorAll('.video-card, .video-item, [data-video]');
    return videos.length;
  });
  console.log(`   ✓ Videos: ${videoCount}`);
  
  // Test view switch
  if (viewToggle) {
    const listBtn = await page.$('[data-view="list"], .btn-list, button[title*="List"]');
    if (listBtn) {
      console.log('   🖱️  Switching to list view...');
      await listBtn.click();
      await browser.sleep(1000);
      
      const isListView = await page.evaluate(() => {
        return document.querySelector('.video-list, .list-view, [data-current-view="list"]') !== null;
      });
      console.log(`   List view active: ${isListView ? '✓' : '✗'}`);
    }
    
    const gridBtn = await page.$('[data-view="grid"], .btn-grid, button[title*="Grid"]');
    if (gridBtn) {
      console.log('   🖱️  Switching to grid view...');
      await gridBtn.click();
      await browser.sleep(1000);
    }
  }
  
  // Look for upload button
  const uploadBtn = await browser.exists('input[type="file"], .upload-btn, [data-upload]', 1000);
  console.log(`   Upload available: ${uploadBtn ? '✓' : '✗'}`);
  
  console.log('');
}

async function testQuizFunctionality() {
  const page = browser.getPage();
  
  // Go back to a module with quiz
  await browser.goto('/home');
  await browser.sleep(1500);
  
  // Find a subject/module with quiz
  const firstSubject = await page.$('.subject-card a, .class-result');
  if (firstSubject) {
    await Promise.all([
      browser.waitForNavigation(),
      firstSubject.click(),
    ]);
    await browser.sleep(1500);
    
    // Find module with quiz indicator
    const moduleWithQuiz = await page.$('[data-has-quiz] a, .module-card a, .lesson-card a');
    if (moduleWithQuiz) {
      await Promise.all([
        browser.waitForNavigation(),
        moduleWithQuiz.click(),
      ]);
      await browser.sleep(1500);
      
      // Look for quiz start button
      const quizBtn = await page.$('a[href*="quiz"], button[data-quiz], .quiz-start, .start-quiz');
      if (quizBtn) {
        console.log('   🖱️  Opening quiz...');
        await Promise.all([
          browser.waitForNavigation(),
          quizBtn.click(),
        ]);
        await browser.sleep(2000);
        
        console.log(`   ✓ Quiz page: ${page.url()}`);
        
        // Check quiz elements
        const quizInfo = await page.evaluate(() => {
          return {
            hasQuestions: document.querySelectorAll('.question, [data-question], .quiz-question').length,
            hasAnswers: document.querySelectorAll('.answer, .option, [data-answer], input[type="radio"]').length,
            hasSubmit: !!document.querySelector('button[type="submit"], .submit-quiz, .finish-quiz'),
            hasProgress: !!document.querySelector('.quiz-progress, .question-counter'),
          };
        });
        
        console.log('   Quiz elements:');
        console.log(`     Questions visible: ${quizInfo.hasQuestions}`);
        console.log(`     Answer options: ${quizInfo.hasAnswers}`);
        console.log(`     Submit button: ${quizInfo.hasSubmit ? '✓' : '✗'}`);
        console.log(`     Progress: ${quizInfo.hasProgress ? '✓' : '✗'}`);
        
        // Try selecting an answer (without submitting)
        const firstAnswer = await page.$('.answer:first-child, .option:first-child, input[type="radio"]:first-child');
        if (firstAnswer) {
          console.log('   🖱️  Selecting first answer...');
          await firstAnswer.click();
          await browser.sleep(500);
          
          const isSelected = await page.evaluate(() => {
            const selected = document.querySelector('.answer.selected, .option.selected, input[type="radio"]:checked');
            return !!selected;
          });
          console.log(`   Answer selected: ${isSelected ? '✓' : '✗'}`);
        }
        
        // Go back without submitting
        console.log('   ⬅️  Going back (not submitting quiz)');
        await browser.goto('/home');
        await browser.sleep(1000);
      } else {
        console.log('   ⚠️  No quiz button found in this module');
      }
    }
  }
  
  console.log('');
}

runTest()
  .then(passed => process.exit(passed ? 0 : 1))
  .catch(error => {
    console.error('Fatal:', error);
    process.exit(1);
  });

