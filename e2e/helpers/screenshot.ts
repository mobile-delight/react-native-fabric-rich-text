import path from 'path';

export async function captureScreenshot(testName: string): Promise<string> {
  const timestamp = new Date().toISOString().replace(/[:.]/g, '-');
  const filename = `${testName}-${timestamp}.png`;
  const screenshotPath = path.resolve(__dirname, `../screenshots/${filename}`);

  await browser.saveScreenshot(screenshotPath);

  return screenshotPath;
}

export async function captureScreenshotWithFixture(
  fixtureId: string
): Promise<string> {
  return captureScreenshot(fixtureId);
}
