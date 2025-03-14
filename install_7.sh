#!/bin/bash

# fix-file-preview.sh - Fix undefined file errors in the FilePreview component
# Created on: March 13, 2025

echo "Starting FilePreview component fixes..."

# Create backup directory if it doesn't exist
mkdir -p backups

# 1. Fix FilePreview.jsx component
echo "Creating backup of FilePreview.jsx..."
cp src/components/ui/FilePreview.jsx backups/FilePreview.jsx.bak.$(date +%Y%m%d%H%M%S)

echo "Modifying FilePreview.jsx to handle undefined files..."

# Create a temporary file with the fixed content
cat > tmp_FilePreview.jsx << 'EOF'
// src/components/ui/FilePreview.jsx
import { useState, useEffect } from 'react';

const FilePreview = ({ file, onRemove }) => {
  // Guard against undefined file
  if (!file) {
    return (
      <div className="p-4 border rounded-lg bg-white dark:bg-gray-800">
        <div className="flex items-center">
          <svg className="w-10 h-10 text-gray-400" fill="currentColor" viewBox="0 0 20 20">
            <path fillRule="evenodd" d="M4 4a2 2 0 012-2h4.586A2 2 0 0112 2.586L15.414 6A2 2 0 0116 7.414V16a2 2 0 01-2 2H6a2 2 0 01-2-2V4z" clipRule="evenodd" />
          </svg>
          <div className="ml-4 flex-1">
            <h3 className="text-lg font-medium truncate">No file selected</h3>
          </div>
        </div>
      </div>
    );
  }

  const [preview, setPreview] = useState(null);
  
  // Format file size
  const formatFileSize = (bytes) => {
    if (bytes < 1024) {
      return `${bytes} B`;
    } else if (bytes < 1024 * 1024) {
      return `${(bytes / 1024).toFixed(1)} KB`;
    } else {
      return `${(bytes / (1024 * 1024)).toFixed(1)} MB`;
    }
  };
  
  // Generate preview based on file type
  useEffect(() => {
    if (!file) {
      setPreview(null);
      return;
    }
    
    if (file.type && file.type.startsWith('image/')) {
      const reader = new FileReader();
      reader.onload = () => {
        setPreview(reader.result);
      };
      reader.readAsDataURL(file);
    } else {
      // For non-image files, set preview to null
      setPreview(null);
    }
  }, [file]);
  
  // Get appropriate icon based on file type
  const getFileIcon = () => {
    // Guard against undefined file
    if (!file) {
      return (
        <svg className="w-10 h-10 text-gray-500" fill="currentColor" viewBox="0 0 20 20">
          <path fillRule="evenodd" d="M4 4a2 2 0 012-2h4.586A2 2 0 0112 2.586L15.414 6A2 2 0 0116 7.414V16a2 2 0 01-2 2H6a2 2 0 01-2-2V4z" clipRule="evenodd" />
        </svg>
      );
    }
    
    const fileType = file.type || '';
    const fileName = file.name || 'unknown';
    
    if (fileType.includes('pdf') || fileName.toLowerCase().endsWith('.pdf')) {
      return (
        <svg className="w-10 h-10 text-pdf-500" fill="currentColor" viewBox="0 0 20 20">
          <path fillRule="evenodd" d="M4 4a2 2 0 012-2h4.586A2 2 0 0112 2.586L15.414 6A2 2 0 0116 7.414V16a2 2 0 01-2 2H6a2 2 0 01-2-2V4zm2 6a1 1 0 011-1h6a1 1 0 110 2H7a1 1 0 01-1-1zm1 3a1 1 0 100 2h6a1 1 0 100-2H7z" clipRule="evenodd" />
        </svg>
      );
    } else if (fileType.includes('word') || fileName.toLowerCase().endsWith('.doc') || fileName.toLowerCase().endsWith('.docx')) {
      return (
        <svg className="w-10 h-10 text-blue-600" fill="currentColor" viewBox="0 0 20 20">
          <path fillRule="evenodd" d="M4 4a2 2 0 012-2h4.586A2 2 0 0112 2.586L15.414 6A2 2 0 0116 7.414V16a2 2 0 01-2 2H6a2 2 0 01-2-2V4z" clipRule="evenodd" />
        </svg>
      );
    } else if (fileType.includes('text') || fileName.toLowerCase().endsWith('.txt')) {
      return (
        <svg className="w-10 h-10 text-gray-500" fill="currentColor" viewBox="0 0 20 20">
          <path fillRule="evenodd" d="M4 4a2 2 0 012-2h8a2 2 0 012 2v12a2 2 0 01-2 2H6a2 2 0 01-2-2V4zm3 1h6v4H7V5zm8 8v-1H5v1h10zm0 3v-1H5v1h10z" clipRule="evenodd" />
        </svg>
      );
    } else {
      return (
        <svg className="w-10 h-10 text-gray-500" fill="currentColor" viewBox="0 0 20 20">
          <path fillRule="evenodd" d="M4 4a2 2 0 012-2h4.586A2 2 0 0112 2.586L15.414 6A2 2 0 0116 7.414V16a2 2 0 01-2 2H6a2 2 0 01-2-2V4z" clipRule="evenodd" />
        </svg>
      );
    }
  };
  
  return (
    <div 
      className="p-4 border rounded-lg bg-white dark:bg-gray-800"
      style={{ 
        opacity: 0,
        transform: 'translateY(10px)',
        animation: 'fadeIn 0.3s forwards',
      }}
    >
      <style>
        {`
          @keyframes fadeIn {
            to {
              opacity: 1;
              transform: translateY(0);
            }
          }
        `}
      </style>
      <div className="flex items-center">
        {preview ? (
          <img src={preview} alt="File preview" className="w-16 h-16 object-cover rounded" />
        ) : (
          getFileIcon()
        )}
        
        <div className="ml-4 flex-1">
          <h3 className="text-lg font-medium truncate">{file.name || 'Unnamed file'}</h3>
          <p className="text-sm text-gray-500 dark:text-gray-400">
            {file.type || 'Unknown type'} • {formatFileSize(file.size || 0)}
          </p>
        </div>
        
        {onRemove && (
          <button 
            onClick={onRemove}
            className="p-2 text-red-500 hover:bg-red-50 dark:hover:bg-red-900 dark:hover:bg-opacity-30 rounded-full"
            aria-label="Remove file"
          >
            <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M6 18L18 6M6 6l12 12" />
            </svg>
          </button>
        )}
      </div>
    </div>
  );
};

export default FilePreview;
EOF

# Replace the original file with our fixed version
mv tmp_FilePreview.jsx src/components/ui/FilePreview.jsx

# 2. Fix PDFUploadStep.jsx to properly handle file mapping
echo "Creating backup of PDFUploadStep.jsx..."
cp src/components/tools/pdf/PDFUploadStep.jsx backups/PDFUploadStep.jsx.bak.$(date +%Y%m%d%H%M%S)

echo "Modifying PDFUploadStep.jsx to handle file mapping safely..."

# Update file mapping to check for file existence
sed -i 's/{files.map((file, index) => (/{files && files.length > 0 && files.map((file, index) => file && (/' src/components/tools/pdf/PDFUploadStep.jsx

# 3. Check if we need to fix PDFPreview.jsx to handle file access safely
echo "Creating backup of PDFPreview.jsx..."
cp src/components/tools/pdf/PDFPreview.jsx backups/PDFPreview.jsx.bak.$(date +%Y%m%d%H%M%S)

echo "Ensuring PDFPreview handles files safely..."

# Update file access in PDFPreview to check for existence first
sed -i 's/if (files && files.length > 0 && !isLoading) {/if (files && Array.isArray(files) && files.length > 0 && files[0] && !isLoading) {/' src/components/tools/pdf/PDFPreview.jsx

# Also fix the PDFWebViewer component if it exists
if [ -f "src/components/tools/pdf/PDFWebViewer.jsx" ]; then
  echo "Creating backup of PDFWebViewer.jsx..."
  cp src/components/tools/pdf/PDFWebViewer.jsx backups/PDFWebViewer.jsx.bak.$(date +%Y%m%d%H%M%S)
  
  echo "Modifying PDFWebViewer.jsx to handle file safety..."
  
  # Add additional checks at the beginning of the useEffect that loads the PDF
  sed -i '/useEffect(() => {/,+2s/if (!file) return;/if (!file || !(file instanceof File || file instanceof Blob)) return;/' src/components/tools/pdf/PDFWebViewer.jsx
fi

# 4. Fix any file and folder handling in PDFUploadStep to ensure files state is properly initialized
echo "Adding additional safety checks to PDFUploadStep initialization..."

sed -i '/const PDFUploadStep/,/const \[files, setFiles\]/s/const \[files, setFiles\] = useState(\[\]);/const \[files, setFiles\] = useState(data.files || []);/' src/components/tools/pdf/PDFUploadStep.jsx

# 5. Create additional empty workers directory if it doesn't exist (just to be safe)
echo "Ensuring workers directory exists..."
mkdir -p src/workers

echo "All file preview fixes have been applied successfully!"
echo "Backups of the original files were created in the ./backups directory."
echo "Please restart your development server to see the changes."
echo ""
echo "If you still encounter issues, please check the browser console for error messages."