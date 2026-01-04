const DEFAULT_TIMEOUT = 10000;
const MAX_SCROLL_ATTEMPTS = 10;

export async function waitForAccessibilityId(
  accessibilityId: string,
  timeout: number = DEFAULT_TIMEOUT
) {
  const selector = `~${accessibilityId}`;
  const element = await $(selector);

  // First wait for element to exist
  await element.waitForExist({ timeout });

  // Quick check if element is already displayed
  try {
    const isDisplayed = await element.isDisplayed();
    if (isDisplayed) return element;
  } catch {
    // Element may not be ready yet
  }

  // Scroll to top first (direction: 'down' = finger swipes down = content moves up = shows top)
  for (let i = 0; i < 3; i++) {
    try {
      await driver.execute('mobile: scroll', { direction: 'down' });
      await driver.pause(150);
      const isDisplayed = await element.isDisplayed();
      if (isDisplayed) return element;
    } catch {
      break;
    }
  }

  // Now scroll down to find element (direction: 'up' = finger swipes up = content moves down = shows bottom)
  for (let attempt = 0; attempt < MAX_SCROLL_ATTEMPTS; attempt++) {
    try {
      await driver.execute('mobile: scroll', { direction: 'up' });
      await driver.pause(150);
      const isDisplayed = await element.isDisplayed();
      if (isDisplayed) return element;
    } catch {
      break;
    }
  }

  // Final wait for displayed with short timeout (element should exist by now)
  await element.waitForDisplayed({ timeout: 5000 });
  return element;
}

export async function waitForElement(
  selector: string,
  timeout: number = DEFAULT_TIMEOUT
) {
  const element = await $(selector);
  await element.waitForDisplayed({ timeout });
  return element;
}

export async function waitForElementNotPresent(
  selector: string,
  timeout: number = DEFAULT_TIMEOUT
): Promise<void> {
  const element = await $(selector);
  await element.waitForDisplayed({ timeout, reverse: true });
}
