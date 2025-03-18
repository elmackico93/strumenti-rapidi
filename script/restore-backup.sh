#!/bin/bash

set -e

echo "🔄 Restoring original files from backup..."

# Restore PDFPreview.jsx if backup exists
if [ -f "src/components/tools/pdf/PDFPreview.jsx.bak" ]; then
  echo "🔄 Restoring src/components/tools/pdf/PDFPreview.jsx"
  cp src/components/tools/pdf/PDFPreview.jsx.bak src/components/tools/pdf/PDFPreview.jsx
fi

# Restore PDFUploadStep.jsx if backup exists
if [ -f "src/components/tools/pdf/PDFUploadStep.jsx.bak" ]; then
  echo "🔄 Restoring src/components/tools/pdf/PDFUploadStep.jsx"
  cp src/components/tools/pdf/PDFUploadStep.jsx.bak src/components/tools/pdf/PDFUploadStep.jsx
fi

# Restore index.html if backup exists
if [ -f "index.html.bak" ]; then
  echo "🔄 Restoring index.html"
  cp index.html.bak index.html
fi

# Restore vite.config.js if backup exists
if [ -f "vite.config.js.bak" ]; then
  echo "🔄 Restoring vite.config.js"
  cp vite.config.js.bak vite.config.js
fi

echo "✅ Restoration complete!"

chmod +x restore-backup.sh
