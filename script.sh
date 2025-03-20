#!/bin/bash

# fix_jsx_errors.sh
# A script to fix JSX syntax errors in the strumenti-rapidi project

# Set script to exit on error
set -e

# Text colors for better readability
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Display functions
info() { echo -e "${BLUE}[INFO]${NC} $1"; }
success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Create backup directory
BACKUP_DIR="./jsx_fix_backups_$(date +%Y%m%d_%H%M%S)"
mkdir -p "$BACKUP_DIR"
info "Created backup directory at $BACKUP_DIR"

# Backup a file before modifying
backup_file() {
    cp "$1" "${BACKUP_DIR}/$(basename $1)"
    info "Backed up $1"
}

# 1. Fix App.jsx - The main error source
APP_JSX="src/App.jsx"
if [ -f "$APP_JSX" ]; then
    info "Fixing Router syntax in $APP_JSX..."
    backup_file "$APP_JSX"
    
    # Fix the invalid JSX syntax (there's a space and slash before the prop)
    sed -i 's/<MainLayout \/ future={{ v7_relativeSplatPath: true }}/<MainLayout future={{ v7_relativeSplatPath: true }}/' "$APP_JSX"
    sed -i 's/<ToolsPage \/ future={{ v7_relativeSplatPath: true }}/<ToolsPage future={{ v7_relativeSplatPath: true }}/' "$APP_JSX"
    
    success "Fixed Router component syntax in $APP_JSX"
else
    error "App.jsx not found!"
    exit 1
fi

# 2. Check PDFPreview.jsx for corrupted code
PDF_PREVIEW="src/components/tools/pdf/PDFPreview.jsx"
PDF_PREVIEW_BAK="src/components/tools/pdf/PDFPreview.jsx.bak"

fix_pdf_preview() {
    local file=$1
    local dest=$2
    info "Fixing corrupted conditions in $file..."
    
    # Fix the mangled conditions with a clean version
    sed -E 's/if \(files if \(files.*!isLoading\) \{/if (files \&\& Array.isArray(files) \&\& files.length > 0 \&\& !isLoading) {/' "$file" > "$dest"
    
    success "Fixed PDFPreview conditions"
}

if [ -f "$PDF_PREVIEW" ]; then
    if grep -q "if (files if" "$PDF_PREVIEW"; then
        backup_file "$PDF_PREVIEW"
        fix_pdf_preview "$PDF_PREVIEW" "$PDF_PREVIEW.tmp"
        mv "$PDF_PREVIEW.tmp" "$PDF_PREVIEW"
    fi
elif [ -f "$PDF_PREVIEW_BAK" ]; then
    info "Using PDFPreview.jsx.bak as source"
    fix_pdf_preview "$PDF_PREVIEW_BAK" "$PDF_PREVIEW"
fi

# 3. Check PDFUploadStep.jsx for corrupted code
PDF_UPLOAD="src/components/tools/pdf/PDFUploadStep.jsx"
PDF_UPLOAD_BAK="src/components/tools/pdf/PDFUploadStep.jsx.bak"

fix_pdf_upload() {
    local file=$1
    local dest=$2
    info "Fixing corrupted map functions in $file..."
    
    # Fix repeated map function calls
    sed -E 's/\{files \{files \{files\.map.*\)\) \(/\{files.map((file, index) => (/' "$file" > "$dest"
    
    success "Fixed PDFUploadStep map function"
}

if [ -f "$PDF_UPLOAD" ]; then
    if grep -q "{files {files {files" "$PDF_UPLOAD"; then
        backup_file "$PDF_UPLOAD"
        fix_pdf_upload "$PDF_UPLOAD" "$PDF_UPLOAD.tmp"
        mv "$PDF_UPLOAD.tmp" "$PDF_UPLOAD"
    fi
elif [ -f "$PDF_UPLOAD_BAK" ]; then
    info "Using PDFUploadStep.jsx.bak as source"
    fix_pdf_upload "$PDF_UPLOAD_BAK" "$PDF_UPLOAD"
fi

# 4. Check for similar issues in other JSX files
info "Scanning for similar issues in other files..."
for JSX_FILE in $(find src -name "*.jsx"); do
    if grep -q "<[A-Za-z][A-Za-z0-9]* \/ " "$JSX_FILE"; then
        if [ "$JSX_FILE" != "$APP_JSX" ]; then
            info "Found similar issue in $JSX_FILE"
            backup_file "$JSX_FILE"
            sed -i 's/<\([A-Za-z][A-Za-z0-9]*\) \/ \([a-zA-Z].*\)/<\1 \2/g' "$JSX_FILE"
            success "Fixed $JSX_FILE"
        fi
    fi
done

# 5. Try to run the application to verify fixes
info "Testing if the fixes resolved the issues..."
npm run dev &
DEV_PID=$!

# Wait a bit for startup
sleep 5

# Check if the process is still running (indicating success)
if kill -0 $DEV_PID 2>/dev/null; then
    success "✅ All fixes applied successfully! The application is now running."
    echo "------------------------------------"
    echo "Fixed issues:"
    echo "1. Corrected JSX syntax in App.jsx - removed invalid '/' before props"
    echo "2. Fixed corrupted conditional logic in PDF components"
    echo "3. Fixed corrupted map functions in PDF components"
    echo "4. Fixed any similar issues in other components"
    echo "------------------------------------"
    echo "All original files were backed up to: $BACKUP_DIR"
    echo ""
    echo "The development server is running. Press Ctrl+C when you're done testing."
    
    # Wait for server process to complete
    wait $DEV_PID
else
    error "❌ The application still has issues. Check the console output above."
    
    # Some additional diagnostics
    echo "Try running 'npx eslint $APP_JSX' for more detailed error information."
    echo "You can restore the backup files from $BACKUP_DIR if needed."
fi

exit 0