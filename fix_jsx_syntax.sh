#!/bin/bash

# Set file path
APP_FILE="/home/ubuntu/Documenti/GitHub/strumenti-rapidi/src/App.jsx"
BACKUP_FILE="$APP_FILE.backup_$(date +%Y%m%d%H%M%S)"

# Create backup
cp "$APP_FILE" "$BACKUP_FILE"
echo "✅ Created backup at $BACKUP_FILE"

# The corrected App.jsx content
cat > "$APP_FILE" << 'END_CONTENT'
import React, { startTransition } from "react";
// src/App.jsx
import { BrowserRouter, Routes, Route } from 'react-router-dom';
import { ThemeProvider } from './context/ThemeContext';
import { OSProvider } from './context/OSContext';
import MainLayout from './components/layout/MainLayout';
import Home from './pages/Home';
import ToolsPage from './pages/ToolsPage';

// Create global registry for tools
window.toolRegistry = {
  'image-editor': {
    acceptedFormats: ['.jpg', '.jpeg', '.png', '.webp', '.gif', '.bmp'],
    maxFileSize: 50 * 1024 * 1024 // 50MB
  },
  'pdf-converter': {
    acceptedFormats: ['.pdf', '.docx', '.doc', '.jpg', '.jpeg', '.png'],
    maxFileSize: 100 * 1024 * 1024 // 100MB
  },
  'ocr': {
    acceptedFormats: ['.jpg', '.jpeg', '.png', '.bmp', '.gif', '.webp', '.pdf'],
    maxFileSize: 10 * 1024 * 1024 // 10MB
  },
  'video-downloader': {
    acceptedFormats: [],
    maxFileSize: 0
  },
  'calculator': {
    acceptedFormats: [],
    maxFileSize: 0
  },
  'meme-creator': {
    acceptedFormats: ['.jpg', '.jpeg', '.png', '.webp', '.gif'],
    maxFileSize: 10 * 1024 * 1024 // 10MB
  }
};

function App() {
  return (
    <ThemeProvider>
      <OSProvider>
        <BrowserRouter>
          <React.Suspense fallback={<div>Loading...</div>}>
            {startTransition(() => (
              <Routes>
                <Route 
                  path="/" 
                  element={<MainLayout />} 
                  future={{ v7_relativeSplatPath: true }}
                >
                  <Route index element={<Home />} />
                  <Route 
                    path="tools/:toolId" 
                    element={<ToolsPage />} 
                    future={{ v7_relativeSplatPath: true }} 
                  />
                </Route>
              </Routes>
            ))}
          </React.Suspense>
        </BrowserRouter>
      </OSProvider>
    </ThemeProvider>
  );
}

export default App;
END_CONTENT

echo "✅ Fixed JSX syntax in $APP_FILE"
echo "   - Corrected the closing tag for <ToolsPage>"
echo "   - Moved 'future' prop from element to Route component"
echo "   - Added proper React import"
echo "   - Improved code formatting for clarity"
echo ""
echo "You can now run 'npm run dev' to verify the fix"
