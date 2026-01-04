import path from 'path';
import fs from 'fs';

const DEVICE_NAME = process.env.DEVICE_NAME || 'iPhone 16 Pro';
const PLATFORM_VERSION = process.env.PLATFORM_VERSION || '18.5';
const BUNDLE_ID = 'fabrichtmltext.example';

// Paths for iOS build - uses predictable derivedDataPath from build script
// Uses Debug builds with FORCE_BUNDLING=1 (no Metro server required)
const CONFIGURATION = process.env.BUILD_CONFIGURATION || 'Debug';
const IOS_PROJECT_PATH = path.resolve(__dirname, '../example/ios');
const DERIVED_DATA_PATH = path.resolve(IOS_PROJECT_PATH, 'build');
const APP_PATH = path.resolve(
  DERIVED_DATA_PATH,
  `Build/Products/${CONFIGURATION}-iphonesimulator/FabricHtmlTextExample.app`
);

// Verify app exists before running tests
if (
  !fs.existsSync(APP_PATH) ||
  !fs.existsSync(path.join(APP_PATH, 'FabricHtmlTextExample'))
) {
  console.error('\n❌ App not found at:', APP_PATH);
  console.error('\nPlease build the app first:');
  console.error('  cd e2e && yarn build');
  console.error('\nOr from example directory:');
  console.error('  yarn build:ios:release --simulator "iPhone 16 Pro"');
  process.exit(1);
}

export const config = {
  runner: 'local',
  tsConfigPath: './tsconfig.json',

  specs: ['./specs/**/*.spec.ts'],
  exclude: [],

  maxInstances: 1,
  capabilities: [
    {
      'platformName': 'iOS',
      'appium:automationName': 'XCUITest',
      'appium:deviceName': DEVICE_NAME,
      'appium:platformVersion': PLATFORM_VERSION,
      'appium:app': APP_PATH,
      'appium:bundleId': BUNDLE_ID,
      'appium:noReset': false,
      'appium:forceAppLaunch': true,
      'appium:autoGrantPermissions': true,
      'appium:newCommandTimeout': 120000,
      'appium:isHeadless': process.env.CI === 'true',
      'appium:reduceMotion': true,
      'appium:wdaStartupRetries': 3,
      'appium:wdaStartupRetryInterval': 20000,
      'appium:derivedDataPath': DERIVED_DATA_PATH,
    },
  ],

  logLevel: 'info',
  bail: 0,
  waitforTimeout: 10000,
  connectionRetryTimeout: 120000,
  connectionRetryCount: 3,

  services: [
    [
      'appium',
      {
        args: {
          relaxedSecurity: true,
        },
      },
    ],
  ],

  framework: 'mocha',
  reporters: ['spec'],

  mochaOpts: {
    ui: 'bdd',
    timeout: 60000,
  },

  afterTest: async function (
    _test: unknown,
    _context: unknown,
    { error }: { error?: Error; passed: boolean }
  ): Promise<void> {
    if (error) {
      const timestamp = new Date().toISOString().replace(/[:.]/g, '-');
      const screenshotPath = path.resolve(
        __dirname,
        `./screenshots/failure-${timestamp}.png`
      );
      await browser.saveScreenshot(screenshotPath);
      console.log(`Screenshot saved on failure: ${screenshotPath}`);
    }
  },
};
