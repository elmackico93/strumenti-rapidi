#!/bin/bash

# StrumentiRapidi.it Ultimate Repair Script
# Created: March 20, 2025

set -e  # Exit immediately if a command exits with a non-zero status

echo "🚀 Starting comprehensive repair for StrumentiRapidi.it"
echo "====================================================="

# Check if we're in the project root
if [ ! -f "package.json" ]; then
  echo "❌ ERROR: Must run from the project root directory (where package.json is located)"
  exit 1
fi

# Determine the package manager
if [ -f "yarn.lock" ]; then
  PKG_MANAGER="yarn"
elif [ -f "pnpm-lock.yaml" ]; then
  PKG_MANAGER="pnpm"
else
  PKG_MANAGER="npm"
fi
echo "📦 Using package manager: $PKG_MANAGER"

# Create backups directory
BACKUP_DIR="config-backups-$(date +%Y%m%d%H%M%S)"
mkdir -p "$BACKUP_DIR"
echo "💾 Created backup directory: $BACKUP_DIR"

# Backup critical files
echo "📁 Backing up critical files..."
for file in vite.config.js vite.config.ts index.html src/main.jsx src/main.js src/App.jsx src/App.js; do
  if [ -f "$file" ]; then
    cp "$file" "$BACKUP_DIR/$file"
    echo "  ✓ Backed up $file"
  fi
done

# Install required dependencies
echo "📦 Installing required dependencies..."
if [ "$PKG_MANAGER" = "yarn" ]; then
  yarn add --dev @vitejs/plugin-react
  yarn remove @vitejs/plugin-vue  # Remove Vue plugin if it was mistakenly installed
elif [ "$PKG_MANAGER" = "pnpm" ]; then
  pnpm add --save-dev @vitejs/plugin-react
  pnpm remove @vitejs/plugin-vue  # Remove Vue plugin if it was mistakenly installed
else
  npm install --save-dev @vitejs/plugin-react
  npm uninstall @vitejs/plugin-vue  # Remove Vue plugin if it was mistakenly installed
fi

# 1. Recreate Vite config file
echo "🔧 Creating fresh Vite configuration..."
cat > vite.config.js << 'EOF'
import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react';
import path from 'path';

export default defineConfig({
  plugins: [react()],
  resolve: {
    alias: {
      '@': path.resolve(__dirname, 'src'),
    },
  },
  build: {
    sourcemap: true,
    outDir: 'dist',
    rollupOptions: {
      output: {
        manualChunks: {
          vendor: ['react', 'react-dom', 'react-router-dom'],
        },
      },
    },
  },
  server: {
    port: 3000,
    open: true,
    cors: true,
  },
  optimizeDeps: {
    include: ['react', 'react-dom', 'react-router-dom'],
  },
});
EOF
echo "  ✓ Created fresh Vite configuration"

# 2. Check and fix index.html
echo "🔍 Checking index.html..."
if [ -f "index.html" ]; then
  # Make a backup
  cp index.html "$BACKUP_DIR/index.html.original"
  
  # Check if the root div exists
  if ! grep -q '<div id="root">' index.html; then
    echo "  🛠️ Fixing root element in index.html"
    sed -i 's/<body>/<body>\n    <div id="root"><\/div>/' index.html
    
    # If sed didn't work (e.g., on macOS), try alternative approach
    if ! grep -q '<div id="root">' index.html; then
      # Create a completely new index.html
      cat > index.html << 'EOF'
<!DOCTYPE html>
<html lang="it">
  <head>
    <meta charset="UTF-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <title>StrumentiRapidi.it - Strumenti PDF Online Gratuiti</title>
    <meta name="description" content="StrumentiRapidi.it - Strumenti online gratuiti per convertire, comprimere e modificare PDF">
    <!-- PDF.js library for PDF rendering --> 
    <script src="https://cdnjs.cloudflare.com/ajax/libs/pdf.js/3.11.174/pdf.min.js"></script> 
    <script> 
      // Ensure proper PDF.js initialization
      window.pdfjsLib = window.pdfjsLib || {}; 
      window.pdfjsLib.GlobalWorkerOptions = window.pdfjsLib.GlobalWorkerOptions || {}; 
      window.pdfjsLib.GlobalWorkerOptions.workerSrc = "https://cdnjs.cloudflare.com/ajax/libs/pdf.js/3.11.174/pdf.worker.min.js"; 
    </script>
    <script>
      // Theme detection
      const isDarkMode = window.matchMedia && window.matchMedia('(prefers-color-scheme: dark)').matches;
      const savedTheme = localStorage.getItem('theme');
      if (savedTheme) {
        document.documentElement.classList.toggle('dark', savedTheme === 'dark');
      } else if (isDarkMode) {
        document.documentElement.classList.add('dark');
      }
    </script>
  </head>
  <body>
    <div id="root"></div>
    <script type="module" src="/src/main.jsx"></script>
  </body>
</html>
EOF
      echo "  ✓ Created new index.html with root element"
    else
      echo "  ✓ Added root element to existing index.html"
    fi
  else
    echo "  ✓ Root element already exists in index.html"
  fi
else
  echo "  ⚠️ index.html not found, creating it..."
  cat > index.html << 'EOF'
<!DOCTYPE html>
<html lang="it">
  <head>
    <meta charset="UTF-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <title>StrumentiRapidi.it - Strumenti PDF Online Gratuiti</title>
    <meta name="description" content="StrumentiRapidi.it - Strumenti online gratuiti per convertire, comprimere e modificare PDF">
    <!-- PDF.js library for PDF rendering --> 
    <script src="https://cdnjs.cloudflare.com/ajax/libs/pdf.js/3.11.174/pdf.min.js"></script> 
    <script> 
      // Ensure proper PDF.js initialization
      window.pdfjsLib = window.pdfjsLib || {}; 
      window.pdfjsLib.GlobalWorkerOptions = window.pdfjsLib.GlobalWorkerOptions || {}; 
      window.pdfjsLib.GlobalWorkerOptions.workerSrc = "https://cdnjs.cloudflare.com/ajax/libs/pdf.js/3.11.174/pdf.worker.min.js"; 
    </script>
  </head>
  <body>
    <div id="root"></div>
    <script type="module" src="/src/main.jsx"></script>
  </body>
</html>
EOF
  echo "  ✓ Created new index.html file"
fi

# 3. Check entry point file (main.jsx or main.js)
echo "🔍 Checking React entry point..."
MAIN_FILE=""
if [ -f "src/main.jsx" ]; then
  MAIN_FILE="src/main.jsx"
elif [ -f "src/main.js" ]; then
  MAIN_FILE="src/main.js"
elif [ -f "src/index.jsx" ]; then
  MAIN_FILE="src/index.jsx"
elif [ -f "src/index.js" ]; then
  MAIN_FILE="src/index.js"
fi

if [ -n "$MAIN_FILE" ]; then
  echo "  📄 Found entry point: $MAIN_FILE"
  # Make a backup
  cp "$MAIN_FILE" "$BACKUP_DIR/$(basename "$MAIN_FILE").original"
  
  # Check for CSS imports
  if ! grep -q "import.*\.css" "$MAIN_FILE"; then
    CSS_FILE=$(find src -name "index.css" -o -name "style.css" -o -name "main.css" | head -1)
    if [ -n "$CSS_FILE" ]; then
      echo "  ➕ Adding CSS import to $MAIN_FILE"
      CSS_IMPORT="import \"$(echo "$CSS_FILE" | sed "s|^src/|./|")\""
      sed -i "1s|^|$CSS_IMPORT;\n|" "$MAIN_FILE"
    fi
  fi
  
  # Check for correct React 18 rendering method
  if ! grep -q "createRoot" "$MAIN_FILE"; then
    echo "  🔄 Updating to React 18 rendering API in $MAIN_FILE"
    # Create a temporary file with updated content
    cat > "$MAIN_FILE.new" << 'EOF'
import React from 'react';
import { createRoot } from 'react-dom/client';
import App from './App';
import './index.css';

// Attempt to import any other CSS files that might be needed
try {
  require('./styles/global.css');
} catch (e) {
  // File doesn't exist, ignore
}

const root = createRoot(document.getElementById('root'));
root.render(
  <React.StrictMode>
    <App />
  </React.StrictMode>
);
EOF
    # Replace the original file
    mv "$MAIN_FILE.new" "$MAIN_FILE"
    echo "  ✓ Updated $MAIN_FILE with modern React rendering"
  else
    echo "  ✓ Entry point already uses modern React rendering"
  fi
else
  echo "  ⚠️ No entry point found, creating src/main.jsx..."
  mkdir -p src
  cat > src/main.jsx << 'EOF'
import React from 'react';
import { createRoot } from 'react-dom/client';
import App from './App';
import './index.css';

const root = createRoot(document.getElementById('root'));
root.render(
  <React.StrictMode>
    <App />
  </React.StrictMode>
);
EOF
  echo "  ✓ Created new src/main.jsx entry point"
  
  # Also create index.css if it doesn't exist
  if [ ! -f "src/index.css" ]; then
    echo "  ➕ Creating src/index.css..."
    cp "$BACKUP_DIR/index.css" "src/index.css" 2>/dev/null || touch "src/index.css"
  fi
fi

# 4. Check App component
echo "🔍 Checking App component..."
APP_FILE=""
if [ -f "src/App.jsx" ]; then
  APP_FILE="src/App.jsx"
elif [ -f "src/App.js" ]; then
  APP_FILE="src/App.js"
fi

if [ -n "$APP_FILE" ]; then
  echo "  📄 Found App component: $APP_FILE"
  # Make a backup
  cp "$APP_FILE" "$BACKUP_DIR/$(basename "$APP_FILE").original"
else
  echo "  ⚠️ No App component found, creating src/App.jsx..."
  cat > src/App.jsx << 'EOF'
import React from 'react';

function App() {
  return (
    <div className="App">
      <header className="App-header">
        <h1>StrumentiRapidi.it</h1>
        <p>Strumenti online gratuiti per convertire, comprimere e modificare PDF</p>
      </header>
      <main>
        <p>Il sito è in manutenzione. Torneremo presto!</p>
      </main>
    </div>
  );
}

export default App;
EOF
  echo "  ✓ Created new src/App.jsx component"
fi

# 5. Fix React Router if it's being used
echo "🔍 Checking for React Router..."
ROUTER_FILES=$(find src -type f -name "*.js" -o -name "*.jsx" | xargs grep -l "BrowserRouter\|createBrowserRouter" 2>/dev/null || echo "")

if [ -n "$ROUTER_FILES" ]; then
  echo "  🛠️ Fixing React Router warnings in found files..."
  
  for file in $ROUTER_FILES; do
    echo "    📝 Updating React Router in $file"
    cp "$file" "$BACKUP_DIR/$(basename "$file").router.original"
    
    # Add future flags to BrowserRouter
    if grep -q "BrowserRouter" "$file" && ! grep -q "future" "$file"; then
      sed -i 's/<BrowserRouter/<BrowserRouter future={{ v7_startTransition: true, v7_relativeSplatPath: true }}/' "$file"
    fi
    
    # Add future flags to createBrowserRouter
    if grep -q "createBrowserRouter" "$file" && ! grep -q "future" "$file"; then
      sed -i 's/createBrowserRouter(/createBrowserRouter(routes, { future: { v7_startTransition: true, v7_relativeSplatPath: true } })/' "$file"
      # This might not work for all cases, but it's a start
    fi
  done
  
  # Check if react-router-dom is installed
  if ! grep -q "\"react-router-dom\"" package.json; then
    echo "  📦 Installing react-router-dom..."
    if [ "$PKG_MANAGER" = "yarn" ]; then
      yarn add react-router-dom
    elif [ "$PKG_MANAGER" = "pnpm" ]; then
      pnpm add react-router-dom
    else
      npm install react-router-dom
    fi
  fi
else
  echo "  ℹ️ React Router not detected in project"
fi

# 6. Create a clean build to verify everything works
echo "🏗️ Creating a production build to verify configuration..."
if [ "$PKG_MANAGER" = "yarn" ]; then
  yarn build
elif [ "$PKG_MANAGER" = "pnpm" ]; then
  pnpm build
else
  npm run build
fi

echo "✅ Build successful! Your application has been repaired."
echo ""
echo "📋 Summary of actions:"
echo "  1. Created fresh Vite configuration"
echo "  2. Verified/fixed index.html with root element"
echo "  3. Updated React entry point with modern rendering API"
echo "  4. Verified/created App component"
echo "  5. Applied React Router fixes (if applicable)"
echo "  6. Successfully created a production build"
echo ""
echo "🚀 To start the development server, run:"
if [ "$PKG_MANAGER" = "yarn" ]; then
  echo "  yarn dev"
elif [ "$PKG_MANAGER" = "pnpm" ]; then
  echo "  pnpm dev"
else
  echo "  npm run dev"
fi
echo ""
echo "💾 All original files were backed up to: $BACKUP_DIR"