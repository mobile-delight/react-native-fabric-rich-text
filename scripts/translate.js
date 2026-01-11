const { TranslationServiceClient } = require('@google-cloud/translate');
const fs = require('fs');
const path = require('path');

// Configuration
const projectId =
  process.env.GOOGLE_CLOUD_PROJECT_ID || process.env.GCLOUD_PROJECT;
if (!projectId) {
  console.error(
    'ERROR: Google Cloud Project ID is required.\n' +
      'Please set GOOGLE_CLOUD_PROJECT_ID or GCLOUD_PROJECT environment variable.\n' +
      'Example: export GOOGLE_CLOUD_PROJECT_ID=your-project-id'
  );
  process.exit(1);
}
const location = 'global';
const translationClient = new TranslationServiceClient();

// Paths
const rootDir = path.join(__dirname, '..');
const stringsJsonPath = path.join(rootDir, 'src/strings.json');
const translationsJsonPath = path.join(__dirname, 'translations.json');

// Security: Escape special characters for iOS .strings files
function escapeIosString(str) {
  return str.replace(/\\/g, '\\\\').replace(/"/g, '\\"');
}

// Security: Escape special characters for Android XML files
function escapeXml(str) {
  return str
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;')
    .replace(/'/g, '&apos;');
}

// Load source strings and translation tracking with error handling
let sourceData;
let translationsData;

try {
  if (!fs.existsSync(stringsJsonPath)) {
    throw new Error(`Source strings file not found: ${stringsJsonPath}`);
  }
  const sourceContent = fs.readFileSync(stringsJsonPath, 'utf8');
  sourceData = JSON.parse(sourceContent);
} catch (error) {
  console.error(`ERROR: Failed to load source strings from ${stringsJsonPath}`);
  console.error(error.message);
  process.exit(1);
}

try {
  if (!fs.existsSync(translationsJsonPath)) {
    throw new Error(
      `Translation tracking file not found: ${translationsJsonPath}`
    );
  }
  const translationsContent = fs.readFileSync(translationsJsonPath, 'utf8');
  translationsData = JSON.parse(translationsContent);
} catch (error) {
  console.error(
    `ERROR: Failed to load translation tracking from ${translationsJsonPath}`
  );
  console.error(error.message);
  process.exit(1);
}

const sourceVersion = sourceData.version;
const sourceStrings = sourceData.strings;
const comments = sourceData.comments;

async function translateText(text, targetLanguage) {
  // Regex to find format specifiers: %1$d, %2$d, etc.
  const placeholderRegex = /(%\d+\$[ds@]|%[ds@])/g;

  // Wrap placeholders in notranslate tags
  const protectedText = text.replace(
    placeholderRegex,
    '<span class="notranslate">$1</span>'
  );

  const request = {
    parent: `projects/${projectId}/locations/${location}`,
    contents: [protectedText],
    mimeType: 'text/html',
    sourceLanguageCode: 'en',
    targetLanguageCode: targetLanguage,
  };

  try {
    const [response] = await translationClient.translateText(request);
    let translatedText = response.translations[0].translatedText;
    // Strip the protective tags
    return translatedText.replace(/<\/?span[^>]*>/g, '');
  } catch (error) {
    console.error(
      `Translation error for "${text}" to ${targetLanguage}:`,
      error.message
    );
    throw error;
  }
}

async function translateStrings(targetLanguage) {
  const translated = {};

  for (const [key, value] of Object.entries(sourceStrings)) {
    console.log(`  Translating "${key}": "${value}"`);
    translated[key] = await translateText(value, targetLanguage);
    // Small delay to avoid rate limiting
    await new Promise((resolve) => setTimeout(resolve, 50));
  }

  return translated;
}

function writeAndroidStrings(androidLocale, strings) {
  const dirPath = path.join(
    rootDir,
    `android/src/main/res/values-${androidLocale}`
  );
  const filePath = path.join(dirPath, 'strings.xml');

  fs.mkdirSync(dirPath, { recursive: true });

  let content = '<?xml version="1.0" encoding="utf-8"?>\n<resources>\n';

  // Group strings by comment
  const grouped = {};
  for (const [key, value] of Object.entries(strings)) {
    const comment = comments[key] || 'Other';
    if (!grouped[comment]) grouped[comment] = [];
    grouped[comment].push({ key, value });
  }

  let first = true;
  for (const [comment, items] of Object.entries(grouped)) {
    if (!first) content += '\n';
    content += `    <!-- ${escapeXml(comment)} -->\n`;
    for (const { key, value } of items) {
      content += `    <string name="${escapeXml(key)}">${escapeXml(
        value
      )}</string>\n`;
    }
    first = false;
  }

  content += '</resources>\n';
  fs.writeFileSync(filePath, content);
}

function writeIOSStrings(iosLocale, strings) {
  const dirPath = path.join(rootDir, `ios/Resources/${iosLocale}.lproj`);
  const filePath = path.join(dirPath, 'Localizable.strings');

  fs.mkdirSync(dirPath, { recursive: true });

  // Group strings by comment
  const grouped = {};
  for (const [key, value] of Object.entries(strings)) {
    const comment = comments[key] || 'Other';
    if (!grouped[comment]) grouped[comment] = [];
    grouped[comment].push({ key, value });
  }

  let content = '';
  let first = true;
  for (const [comment, items] of Object.entries(grouped)) {
    if (!first) content += '\n';
    content += `/* ${comment} */\n`;
    for (const { key, value } of items) {
      content += `"${escapeIosString(key)}" = "${escapeIosString(value)}";\n`;
    }
    first = false;
  }

  fs.writeFileSync(filePath, content);
}

async function generateAllTranslations() {
  console.log(`Source version: ${sourceVersion}`);
  console.log(`Loaded ${Object.keys(sourceStrings).length} source strings\n`);

  // First, generate English files
  console.log('Generating English source files...');
  writeAndroidStrings('', sourceStrings); // values/ (no locale suffix)
  writeIOSStrings('en', sourceStrings);
  console.log('✓ English files generated\n');

  // Translate other languages
  for (const [iosLocale, localeInfo] of Object.entries(
    translationsData.localeMapping
  )) {
    const currentVersion = translationsData.languages[iosLocale]?.version || 0;

    if (currentVersion >= sourceVersion) {
      console.log(
        `Skipping ${iosLocale} (already at version ${currentVersion})\n`
      );
      continue;
    }

    console.log('='.repeat(60));
    console.log(
      `Translating to ${iosLocale} (Google: ${localeInfo.google}, Android: ${localeInfo.android})`
    );
    console.log(
      `Current version: ${currentVersion} -> Target version: ${sourceVersion}`
    );
    console.log('='.repeat(60));

    try {
      // Translate all strings
      const translated = await translateStrings(localeInfo.google);

      // Write platform files
      writeAndroidStrings(localeInfo.android, translated);
      writeIOSStrings(iosLocale, translated);

      // Update version
      translationsData.languages[iosLocale].version = sourceVersion;

      // Atomic write: write to temp file, then rename
      // This prevents partial/inconsistent state if the process crashes
      const tempPath = translationsJsonPath + '.tmp';
      fs.writeFileSync(tempPath, JSON.stringify(translationsData, null, 2));
      fs.renameSync(tempPath, translationsJsonPath);

      console.log(`✓ Completed ${iosLocale}\n`);
    } catch (error) {
      console.error(`✗ Failed ${iosLocale}:`, error.message);
      console.log('Continuing with next language...\n');
    }
  }

  console.log('='.repeat(60));
  console.log('Translation complete!');
  console.log('='.repeat(60));
}

generateAllTranslations().catch(console.error);
