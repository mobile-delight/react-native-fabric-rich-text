import { fileURLToPath } from 'url';
import { mkdir } from 'fs/promises';
import path from 'path';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

export async function captureScreenshot(testName: string): Promise<string> {
  const timestamp = new Date().toISOString().replace(/[:.]/g, '-');
  const filename = `${testName}-${timestamp}.png`;
  const screenshotsDir = path.resolve(__dirname, '../screenshots');
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
