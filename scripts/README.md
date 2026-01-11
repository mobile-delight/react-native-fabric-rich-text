# Translation Scripts

Automated translation system using Google Cloud Translation API v3.

## How It Works

### Source of Truth

All strings are defined in `src/strings.json`:

```json
{
  "version": 1,  // Increment when strings change
  "strings": { ... },
  "comments": { ... }
}
```

### Version Tracking

`scripts/translations.json` tracks which languages are up-to-date:

- Each language has a `version` number
- Script only translates languages where `version < source version`
- Efficient: Only re-translates when strings change

### Workflow

1. **Add/modify strings**: Edit `src/strings.json`
2. **Increment version**: Bump the `version` number
3. **Run script**: `node scripts/translate.js`
4. **Automatic**:
   - Generates English files from JSON
   - Translates only outdated languages
   - Updates version tracking

## Setup

1. **Install dependencies:**

   ```bash
   npm install @google-cloud/translate
   ```

2. **Set up Google Cloud authentication:**

   ```bash
   # Login with your Google Cloud user account
   gcloud auth application-default login

   # Set your project
   gcloud config set project your-project-id
   ```

3. **Enable the Cloud Translation API:**
   - Go to Google Cloud Console
   - Enable the Cloud Translation API
   - Ensure your account has "Cloud Translation API User" role

## Usage

Run the translation script:

```bash
node scripts/translate.js
```

The script will:

1. Generate English files from `src/strings.json`
2. Check each language's version in `translations.json`
3. Skip languages already at current version
4. Translate and update only outdated languages

## Adding New Strings

1. Edit `src/strings.json`:

   ```json
   {
     "version": 2,  // Increment!
     "strings": {
       "new_key": "new value"
     },
     "comments": {
       "new_key": "Description"
     }
   }
   ```

2. Run `node scripts/translate.js`
3. All 60+ language files regenerate automatically

## Supported Languages

60+ languages including: ar, bg, bn, bs, ca, cs, cy, da, de, el, es, fi, fil, fr, ga, gd, haw, he, hi, hmn, ht, hu, hy, id, it, iu, ja, jam, kn, ko, lb, lt, ms, mt, my, ne, nl, no, pl, pt, pt-BR, pt-PT, ro, ru, sk, so, sr, sv, ta, th, tr, uk, ur, vi, zh, zh-Hans, zh-Hant, zh-HK

## Format Specifiers

Both iOS and Android use positional format: `%1$d`, `%2$d`

The script protects placeholders during translation using `<span class="notranslate">` tags.
