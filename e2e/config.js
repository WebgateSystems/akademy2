/**
 * E2E Test Configuration
 */

module.exports = {
  // Base URL for the application
  baseUrl: process.env.E2E_BASE_URL || 'http://localhost:3000',
  
  // Timeouts
  timeouts: {
    implicit: 15000,      // Wait for elements (increased)
    pageLoad: 30000,      // Wait for page load
    script: 15000,        // Wait for async scripts
  },
  
  // Browser options
  browser: {
    headless: process.env.E2E_HEADLESS === 'true', // Default: visible browser
    windowSize: { width: 1920, height: 1080 },
  },
  
  // Test users (from seeds)
  users: {
    superadmin: {
      email: 'sladkowski@webgate.pro',
      password: 'devpass!',
    },
    // School director (principal)
    principal: {
      email: 'bartus@wlatcy.edu.pl',
      password: 'devpass!',
    },
    // Teacher
    teacher: {
      email: 'teachertest@gmail.com',
      password: 'devpass!',
    },
    // Student (phone + PIN) - from "Włatcy Móch" school with approved classes
    student: {
      phone: '+48123234345', // Czesio Opania, klasa 2B
      pin: '0000',
    },
  },
  
  // Applitools configuration
  applitools: {
    apiKey: process.env.APPLITOOLS_API_KEY,
    appName: 'AKAdemy 2.0',
    batchName: process.env.E2E_BATCH_NAME || 'E2E Visual Tests',
  },
};

