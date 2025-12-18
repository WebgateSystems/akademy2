/**
 * E2E Test: Student Quiz Flow
 * Tests the complete flow: login -> select subject -> navigate through module -> start quiz
 */

const browser = require('../helpers/browser');
const config = require('../config');
const auth = require('../helpers/auth');

async function runTest() {
  let testPassed = false;
  
  console.log('🚀 Starting Student Quiz Test...\n');
  
  try {
    await browser.launch();
    const page = browser.getPage(); // Get page instance for scrolling
  
    // Step 1: Login as student
    console.log('📍 Step 1: Login as student');
    await auth.loginAsStudent();
    console.log('   ✓ Logged in as student\n');
    
    // Wait for page to load after login
    await browser.sleep(1000);
    
    const currentUrl = browser.url();
    console.log(`   Current URL: ${currentUrl}`);
    
    // Navigate to /home if not already there
    if (!currentUrl.includes('/home')) {
      console.log('   🖱️  Navigating to /home...');
      await browser.goto('/home');
      await browser.sleep(1500);
      console.log(`   Current URL: ${browser.url()}\n`);
    }
    
    // Step 2: Click on subject "Polska i geopolityka"
    console.log('📍 Step 2: Click on subject "Polska i geopolityka"');
    const subjectSelector = 'a.class-result[data-subject-id="11111111-1111-1111-1111-111111111111"]';
    
    const subjectExists = await browser.exists(subjectSelector, 3000);
    if (!subjectExists) {
      throw new Error(`Subject link not found: ${subjectSelector}`);
    }
    
    await Promise.all([
      browser.waitForNavigation().catch(() => {}),
      browser.click(subjectSelector),
    ]);
    await browser.sleep(1500);
    
    const subjectUrl = browser.url();
    console.log(`   ✓ Clicked subject, URL: ${subjectUrl}\n`);
    
    // Step 3: Click "Next" button (step 2)
    console.log('📍 Step 3: Navigate to step 2');
    const step2Selector = 'a.module-nav-btn--next[href*="step=2"]';
    
    // Scroll to bottom to make button visible
    await page.evaluate(() => window.scrollTo(0, document.body.scrollHeight));
    await browser.sleep(500);
    
    const step2Exists = await browser.exists(step2Selector, 3000);
    if (!step2Exists) {
      throw new Error(`Step 2 navigation button not found: ${step2Selector}`);
    }
    
    await Promise.all([
      browser.waitForNavigation().catch(() => {}),
      browser.click(step2Selector),
    ]);
    await browser.sleep(1500);
    
    const step2Url = browser.url();
    console.log(`   ✓ Navigated to step 2, URL: ${step2Url}\n`);
    
    // Step 4: Click "Next" button (step 3)
    console.log('📍 Step 4: Navigate to step 3');
    const step3Selector = 'a.module-nav-btn--next[href*="step=3"]';
    
    // Scroll to bottom to make button visible
    await page.evaluate(() => window.scrollTo(0, document.body.scrollHeight));
    await browser.sleep(500);
    
    const step3Exists = await browser.exists(step3Selector, 3000);
    if (!step3Exists) {
      throw new Error(`Step 3 navigation button not found: ${step3Selector}`);
    }
    
    await Promise.all([
      browser.waitForNavigation().catch(() => {}),
      browser.click(step3Selector),
    ]);
    await browser.sleep(1500);
    
    const step3Url = browser.url();
    console.log(`   ✓ Navigated to step 3, URL: ${step3Url}\n`);
    
    // Step 5: Click "Rozpocznij Quiz" button
    console.log('📍 Step 5: Start quiz');
    const quizStartSelector = 'a.quiz-start-btn[href*="quiz"]';
    
    // Scroll to bottom to make button visible
    await page.evaluate(() => window.scrollTo(0, document.body.scrollHeight));
    await browser.sleep(500);
    
    const quizStartExists = await browser.exists(quizStartSelector, 3000);
    if (!quizStartExists) {
      throw new Error(`Quiz start button not found: ${quizStartSelector}`);
    }
    
    await Promise.all([
      browser.waitForNavigation().catch(() => {}),
      browser.click(quizStartSelector),
    ]);
    await browser.sleep(1500);
    
    const quizUrl = browser.url();
    console.log(`   ✓ Quiz started, URL: ${quizUrl}\n`);
    
    // Step 6: Answer quiz questions
    console.log('📍 Step 6: Answer quiz questions');
    let questionNumber = 0;
    const maxQuestions = 20; // Safety limit to avoid infinite loop
    
    while (questionNumber < maxQuestions) {
      // Check if we've reached the results page
      const hasResults = await browser.exists('h2.quiz-result-title', 1000);
      if (hasResults) {
        console.log(`   ✓ Reached quiz results after ${questionNumber} questions\n`);
        break;
      }
      
      // Wait for question options to appear
      const questionExists = await browser.exists('button.quiz-option', 3000);
      if (!questionExists) {
        console.log(`   ⚠️  No question options found, assuming quiz completed\n`);
        break;
      }
      
      questionNumber++;
      console.log(`   📝 Answering question ${questionNumber}...`);
      
      // Wait a bit more to ensure page is fully loaded after previous question
      await browser.sleep(500);
      
      // Scroll to top first, then find the option
      await page.evaluate(() => window.scrollTo(0, 0));
      await browser.sleep(200);
      
      // Find and click the option with data-option-id="b" for current question
      // Use data-question attribute to ensure we're clicking the right question
      const currentQuestionIndex = questionNumber - 1;
      const optionSelector = `button.quiz-option[data-option-id="b"][data-question="${currentQuestionIndex}"]`;
      
      // Try with specific question index first, fallback to just data-option-id="b"
      let optionExists = await browser.exists(optionSelector, 2000);
      let finalSelector = optionSelector;
      
      if (!optionExists) {
        // Fallback: try without data-question attribute
        finalSelector = `button.quiz-option[data-option-id="b"]`;
        optionExists = await browser.exists(finalSelector, 2000);
      }
      
      if (!optionExists) {
        throw new Error(`Option with data-option-id="b" not found for question ${questionNumber}`);
      }
      
      // Wait for element to be ready and scroll into view
      await browser.waitFor(finalSelector);
      await page.evaluate((selector) => {
        const element = document.querySelector(selector);
        if (element) {
          element.scrollIntoView({ behavior: 'smooth', block: 'center' });
        }
      }, finalSelector);
      await browser.sleep(400);
      
      // Check if element is visible and clickable
      const isClickable = await page.evaluate((selector) => {
        const element = document.querySelector(selector);
        if (!element) return false;
        const style = window.getComputedStyle(element);
        const rect = element.getBoundingClientRect();
        return style.display !== 'none' && 
               style.visibility !== 'hidden' &&
               style.pointerEvents !== 'none' &&
               rect.width > 0 &&
               rect.height > 0;
      }, finalSelector);
      
      if (!isClickable) {
        throw new Error(`Option with data-option-id="b" is not clickable for question ${questionNumber}`);
      }
      
      await browser.click(finalSelector);
      console.log(`      ✓ Selected option "b"`);
      await browser.sleep(800); // Wait for button to appear
      
      // Check if this is the last question (10th question)
      const isLastQuestion = questionNumber === 10;
      
      if (isLastQuestion) {
        // Last question: look for "Zakończ Quiz" button
        console.log(`      🏁 Last question - looking for submit button...`);
        const submitButtonSelector = 'button.quiz-submit-btn';
        
        // Check if submit button is visible
        const isSubmitButtonVisible = await page.evaluate((selector) => {
          const btn = document.querySelector(selector);
          if (!btn) return false;
          const style = window.getComputedStyle(btn);
          return style.display !== 'none' && style.visibility !== 'hidden';
        }, submitButtonSelector);
        
        if (!isSubmitButtonVisible) {
          // Wait a bit more
          await browser.sleep(500);
          const stillNotVisible = await page.evaluate((selector) => {
            const btn = document.querySelector(selector);
            if (!btn) return false;
            const style = window.getComputedStyle(btn);
            return style.display !== 'none' && style.visibility !== 'hidden';
          }, submitButtonSelector);
          
          if (!stillNotVisible) {
            throw new Error(`"Zakończ Quiz" button is not visible after last question`);
          }
        }
        
        await browser.click(submitButtonSelector);
        console.log(`      ✓ Clicked "Zakończ Quiz"`);
        
        // Wait for results page to load
        await browser.sleep(1500);
      } else {
        // Not last question: click "Dalej" button
        const nextButtonSelector = 'button.quiz-next-btn';
        
        // Check if button is visible using page.evaluate
        const isButtonVisible = await page.evaluate((selector) => {
          const btn = document.querySelector(selector);
          if (!btn) return false;
          const style = window.getComputedStyle(btn);
          return style.display !== 'none' && style.visibility !== 'hidden';
        }, nextButtonSelector);
        
        if (!isButtonVisible) {
          // Wait a bit more and check again
          await browser.sleep(500);
          const stillHasResults = await browser.exists('h2.quiz-result-title', 1000);
          if (stillHasResults) {
            console.log(`   ✓ Quiz completed\n`);
            break;
          }
          throw new Error(`"Dalej" button is not visible after question ${questionNumber}`);
        }
        
        await browser.click(nextButtonSelector);
        console.log(`      ✓ Clicked "Dalej"`);
        
        // Wait for next question to load
        await browser.sleep(500);
        
        // Wait for new question options to appear (with retry logic)
        let nextQuestionReady = false;
        for (let retry = 0; retry < 5; retry++) {
          await browser.sleep(400);
          
          // Check if we've reached results
          const hasResultsNow = await browser.exists('h2.quiz-result-title', 500);
          if (hasResultsNow) {
            nextQuestionReady = true;
            break;
          }
          
          // Check if new question options are visible and ready
          const hasNewOptions = await page.evaluate(() => {
            const options = document.querySelectorAll('button.quiz-option[data-option-id="b"]');
            if (options.length === 0) return false;
            
            // Check if at least one option is visible and clickable
            return Array.from(options).some(opt => {
              const style = window.getComputedStyle(opt);
              const rect = opt.getBoundingClientRect();
              return style.display !== 'none' &&
                     style.visibility !== 'hidden' &&
                     rect.width > 0 &&
                     rect.height > 0;
            });
          });
          
          if (hasNewOptions) {
            nextQuestionReady = true;
            break;
          }
        }
        
        if (!nextQuestionReady) {
          // Final check if we reached results
          const finalCheck = await browser.exists('h2.quiz-result-title', 1000);
          if (!finalCheck) {
            console.log(`      ⚠️  Next question may not be fully loaded, continuing...`);
          }
        }
      }
    }
    
    if (questionNumber >= maxQuestions) {
      throw new Error(`Reached maximum number of questions (${maxQuestions}) without reaching results`);
    }
    
    // Step 7: Verify quiz completion
    console.log('📍 Step 7: Verify quiz completion');
    await browser.sleep(1500); // Wait for results page to fully load
    
    const resultTitleExists = await browser.exists('h2.quiz-result-title', 3000);
    if (!resultTitleExists) {
      throw new Error('Quiz result title not found');
    }
    
    const resultText = await browser.getText('h2.quiz-result-title');
    if (resultText.includes('Gratulacje!')) {
      console.log(`   ✓ Quiz completed successfully!`);
      console.log(`   ✓ Result text: "${resultText}"\n`);
    } else {
      throw new Error(`Expected "Gratulacje!" but found: "${resultText}"`);
    }
    
    testPassed = true;
    
    console.log('\n' + '='.repeat(50));
    console.log('RESULTS');
    console.log('='.repeat(50));
    console.log('✅ TEST PASSED');
    console.log(`Final URL: ${quizUrl}`);
    console.log('All steps completed successfully!\n');
    
  } catch (error) {
    console.error('\n❌ TEST ERROR:', error.message);
    console.error('Stack:', error.stack);
    testPassed = false;
    
    // Try to take a screenshot for debugging
    // try {
    //   // await browser.screenshot('quiz-test-error');
    // } catch (screenshotError) {
    //   console.error('Could not take screenshot:', screenshotError.message);
    // }
  } finally {
    await browser.close();
  }
  
  return testPassed;
}

runTest()
  .then(passed => process.exit(passed ? 0 : 1))
  .catch(error => {
    console.error('Fatal:', error);
    process.exit(1);
  });

