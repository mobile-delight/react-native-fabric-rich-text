const fs = require('fs');
const path = require('path');

module.exports = (request, options) => {
  if (request.startsWith('.') || request.startsWith('/')) {
    const basePath = path.resolve(options.basedir, request);

    const webPath = basePath.endsWith('.web')
      ? `${basePath}.ts`
      : `${basePath}.web.ts`;
    if (fs.existsSync(webPath)) {
      return webPath;
    }

    const webTsxPath = basePath.endsWith('.web')
      ? `${basePath}.tsx`
      : `${basePath}.web.tsx`;
    if (fs.existsSync(webTsxPath)) {
      return webTsxPath;
    }
  }

  return options.defaultResolver(request, options);
};
