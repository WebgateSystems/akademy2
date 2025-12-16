/**
 * E2E Test Runner
 * Runs all tests in the e2e/tests directory
 */

const { execSync } = require('child_process');
const fs = require('fs');
const path = require('path');

const testsDir = path.join(__dirname, 'tests');
const testFiles = fs.readdirSync(testsDir).filter(f => f.endsWith('.test.js'));

console.log('🧪 AKAdemy E2E Test Suite');
console.log('='.repeat(50));
console.log(`Found ${testFiles.length} test file(s)\n`);

let passed = 0;
let failed = 0;

for (const testFile of testFiles) {
  console.log(`\n📋 Running: ${testFile}`);
  console.log('-'.repeat(50));
  
  try {
    execSync(`node ${path.join(testsDir, testFile)}`, {
      stdio: 'inherit',
      env: process.env,
    });
    passed++;
    console.log(`✅ ${testFile} - PASSED`);
  } catch (error) {
    failed++;
    console.log(`❌ ${testFile} - FAILED`);
  }
}

console.log('\n' + '='.repeat(50));
console.log('SUMMARY');
console.log('='.repeat(50));
console.log(`Total:  ${testFiles.length}`);
console.log(`Passed: ${passed}`);
console.log(`Failed: ${failed}`);
console.log('='.repeat(50));

process.exit(failed > 0 ? 1 : 0);

