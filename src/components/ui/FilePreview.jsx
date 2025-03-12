// src/components/ui/FilePreview.jsx
import { useState, useEffect } from 'react';

const FilePreview = ({ file, onRemove }) => {
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
    if (!file) return;
    
    if (file.type.startsWith('image/')) {
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
    if (file.type.includes('pdf')) {
      return (
        <svg className="w-10 h-10 text-pdf-500" fill="currentColor" viewBox="0 0 20 20">
          <path fillRule="evenodd" d="M4 4a2 2 0 012-2h4.586A2 2 0 0112 2.586L15.414 6A2 2 0 0116 7.414V16a2 2 0 01-2 2H6a2 2 0 01-2-2V4zm2 6a1 1 0 011-1h6a1 1 0 110 2H7a1 1 0 01-1-1zm1 3a1 1 0 100 2h6a1 1 0 100-2H7z" clipRule="evenodd" />
        </svg>
      );
    } else if (file.type.includes('word') || file.name.endsWith('.doc') || file.name.endsWith('.docx')) {
      return (
        <svg className="w-10 h-10 text-blue-600" fill="currentColor" viewBox="0 0 20 20">
          <path fillRule="evenodd" d="M4 4a2 2 0 012-2h4.586A2 2 0 0112 2.586L15.414 6A2 2 0 0116 7.414V16a2 2 0 01-2 2H6a2 2 0 01-2-2V4z" clipRule="evenodd" />
        </svg>
      );
    } else if (file.type.includes('text') || file.name.endsWith('.txt')) {
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
          <h3 className="text-lg font-medium truncate">{file.name}</h3>
          <p className="text-sm text-gray-500 dark:text-gray-400">
            {file.type || 'Unknown type'} • {formatFileSize(file.size)}
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
