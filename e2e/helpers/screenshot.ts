import { mkdir } from 'fs/promises';
import path from 'path';

export async function captureScreenshot(testName: string): Promise<string> {
  const timestamp = new Date().toISOString().replace(/[:.]/g, '-');
  const filename = `${testName}-${timestamp}.png`;
  // Use process.cwd() for CommonJS compatibility
  const screenshotsDir = path.resolve(process.cwd(), 'e2e/screenshots');
  const screenshotPath = path.join(screenshotsDir, filename);

  try {
    await mkdir(screenshotsDir, { recursive: true });
    await browser.saveScreenshot(screenshotPath);
  } catch (error) {
    console.error(`Failed to capture screenshot ${testName}:`, error);
    throw error;
  }

  return screenshotPath;
}

export async function captureScreenshotWithFixture(
  fixtureId: string
): Promise<string> {
  return captureScreenshot(fixtureId);
}
