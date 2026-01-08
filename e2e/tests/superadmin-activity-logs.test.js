/**
 * E2E Test: Full Chart Controls (Zoom, Cancel, Reset, Logs)
 */

const browser = require('../helpers/browser');
const config = require('../config');

async function runChartTest() {
  console.log('🚀 Starting Full Chart Controls Test...\n');

  try {
    await browser.launch();
    const page = browser.getPage();

    // Вспомогательная функция для выделения области на графике
    const selectRange = async (xStartPct, xEndPct) => {
      const chartSelector = '.chart__canvas';
      await page.waitForSelector(chartSelector);
      const chartElement = await page.$(chartSelector);
      const box = await chartElement.boundingBox();
      if (!box) throw new Error('Could not find chart bounding box');

      const startX = Math.floor(box.x + box.width * xStartPct);
      const endX = Math.floor(box.x + box.width * xEndPct);
      const centerY = Math.floor(box.y + box.height / 2);

      await page.mouse.move(startX, centerY);
      await page.mouse.down();
      for (let i = startX; i <= endX; i += 20) {
        await page.mouse.move(i, centerY);
      }
      await page.mouse.up();
      await browser.sleep(500); // Небольшая пауза, чтобы UI отрисовал поповер
    };

    // ========================================
    // Step 1: Login
    // ========================================
    console.log('📍 Step 1: Login');
    const { email, password } = config.users.superadmin;
    await browser.goto('/admin/sign_in');
    await browser.type('input#email', email);
    await browser.type('input#password', password);
    await Promise.all([browser.waitForNavigation(), browser.click('.btn-primary')]);

    console.log('📍 Step 2: Navigate to Dashboard');
    await browser.goto('/admin');
    await browser.waitFor('.js-line-chart');

    // ========================================
    // Step 3: Test ZOOM
    // ========================================
    console.log('📍 Step 3: Testing ZOOM');
    await selectRange(0.1, 0.4); // Выделяем начало графика
    const zoomBtn = '[data-selection-zoom=""]';
    await page.waitForSelector(zoomBtn, { visible: true });
    await page.click(zoomBtn);
    console.log('   ✓ Zoom applied');
    await browser.sleep(1000); // Ждем перерисовку

    // ========================================
    // Step 4: Test CANCEL (Anuluj)
    // ========================================
    console.log('📍 Step 4: Testing CANCEL (Anuluj)');
    await selectRange(0.2, 0.5);
    const cancelBtn = '[data-selection-cancel=""]';
    await page.waitForSelector(cancelBtn, { visible: true });
    await page.click(cancelBtn);
    
    // Проверяем, что поповер исчез
    const isPopoverVisible = await page.$eval('[data-selection-popover="true"]', 
      el => window.getComputedStyle(el).display !== 'none'
    ).catch(() => false);
    
    if (isPopoverVisible) throw new Error('Popover should be hidden after Cancel');
    console.log('   ✓ Selection cancelled');

    // ========================================
    // Step 5: Test RESET ZOOM
    // ========================================
    console.log('📍 Step 5: Testing RESET ZOOM');
    await selectRange(0.3, 0.6);
    const resetBtn = '[data-selection-reset=""]';
    await page.waitForSelector(resetBtn, { visible: true });
    await page.click(resetBtn);
    console.log('   ✓ Zoom reset to default');
    await browser.sleep(1000);

    // ========================================
    // Step 6: Test NAVIGATION TO LOGS
    // ========================================
    console.log('📍 Step 6: Testing "Idź do logów"');
    await selectRange(0.4, 0.8);
    const logsBtn = 'a[data-selection-logs=""]';
    await page.waitForSelector(logsBtn, { visible: true });

    // Проверяем наличие дат в href для интереса (опционально)
    const href = await page.$eval(logsBtn, el => el.getAttribute('href'));
    console.log(`   Link detected: ${href}`);

    await Promise.all([
      browser.waitForNavigation(),
      page.click(logsBtn)
    ]);

    // ========================================
    // Step 7: Final Verification
    // ========================================
    console.log('📍 Step 7: Verify Final URL');
    if (page.url().includes('/admin/events')) {
      console.log('   ✓ Successfully arrived at Events page');
    } else {
      throw new Error(`Wrong URL: ${page.url()}`);
    }

    console.log('\n✅ ALL CHART CONTROLS TESTED SUCCESSFULLY\n');

  } catch (error) {
    console.error('\n❌ TEST ERROR:', error.message);
    process.exit(1);
  } finally {
    await browser.close();
  }
}

runChartTest();