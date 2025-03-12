// src/components/ui/FileDropZone.jsx
import { useState, useRef } from 'react';

const FileDropZone = ({ onFileSelect, acceptedFormats, maxSize, icon: Icon }) => {
  const [isDragging, setIsDragging] = useState(false);
  const fileInputRef = useRef(null);
  
  // Format maxSize to human-readable format
  const formatFileSize = (sizeInBytes) => {
    if (sizeInBytes < 1024) {
      return `${sizeInBytes} B`;
    } else if (sizeInBytes < 1024 * 1024) {
      return `${(sizeInBytes / 1024).toFixed(1)} KB`;
    } else {
      return `${(sizeInBytes / (1024 * 1024)).toFixed(1)} MB`;
    }
  };
  
  // Handle drag events
  const handleDragEnter = (e) => {
    e.preventDefault();
    e.stopPropagation();
    setIsDragging(true);
  };
  
  const handleDragLeave = (e) => {
    e.preventDefault();
    e.stopPropagation();
    setIsDragging(false);
  };
  
  const handleDragOver = (e) => {
    e.preventDefault();
    e.stopPropagation();
    setIsDragging(true);
  };
  
  // Handle drop event
  const handleDrop = (e) => {
    e.preventDefault();
    e.stopPropagation();
    setIsDragging(false);
    
    const files = e.dataTransfer.files;
    if (files.length > 0) {
      handleFile(files[0]);
    }
  };
  
  // Handle file input change
  const handleFileSelect = (e) => {
    const files = e.target.files;
    if (files.length > 0) {
      handleFile(files[0]);
    }
  };
  
  // Trigger file input click
  const triggerFileInput = () => {
    fileInputRef.current.click();
  };
  
  // Validate and process the file
  const handleFile = (file) => {
    // Check file type if acceptedFormats provided
    if (acceptedFormats && acceptedFormats.length > 0) {
      const fileExtension = '.' + file.name.split('.').pop().toLowerCase();
      if (!acceptedFormats.includes(fileExtension)) {
        alert(`Invalid file format. Please upload a file with one of these formats: ${acceptedFormats.join(', ')}`);
        return;
      }
    }
    
    // Check file size if maxSize provided
    if (maxSize && file.size > maxSize) {
      alert(`File is too large. Maximum size is ${formatFileSize(maxSize)}`);
      return;
    }
    
    // Pass the file to parent component
    onFileSelect(file);
  };
  
  return (
    <div 
      className={`border-2 border-dashed rounded-lg p-8 text-center cursor-pointer transition-colors duration-300 ${
        isDragging ? 'border-primary-500 bg-primary-50 dark:bg-primary-900 dark:bg-opacity-20' : 'border-gray-300 dark:border-gray-700'
      }`}
      style={{ 
        transform: isDragging ? 'scale(1.01)' : 'scale(1)',
        transition: 'transform 0.3s, border-color 0.3s, background-color 0.3s'
      }}
      onDragEnter={handleDragEnter}
      onDragOver={handleDragOver}
      onDragLeave={handleDragLeave}
      onDrop={handleDrop}
      onClick={triggerFileInput}
    >
      <input 
        type="file" 
        ref={fileInputRef}
        onChange={handleFileSelect} 
        accept={acceptedFormats?.join(',')}
        className="hidden"
      />
      
<div className="flex flex-col items-center">
        {Icon ? (
          <Icon className={`w-16 h-16 mb-4 ${isDragging ? 'text-primary-500' : 'text-gray-400'}`} />
        ) : (
          <svg 
            className={`w-16 h-16 mb-4 ${isDragging ? 'text-primary-500' : 'text-gray-400'}`} 
            fill="none" 
            stroke="currentColor" 
            viewBox="0 0 24 24"
          >
            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M7 16a4 4 0 01-.88-7.903A5 5 0 1115.9 6L16 6a5 5 0 011 9.9M15 13l-3-3m0 0l-3 3m3-3v12" />
          </svg>
        )}
        
        <h3 className="text-lg font-medium mb-1">
          Drop your file here or <span className="text-primary-500">browse</span>
        </h3>
        
        <p className="text-sm text-gray-500 dark:text-gray-400">
          {acceptedFormats ? `Supported formats: ${acceptedFormats.join(', ')}` : 'All file types supported'}
        </p>
        
        {maxSize && (
          <p className="text-sm text-gray-500 dark:text-gray-400 mt-1">
            Maximum size: {formatFileSize(maxSize)}
          </p>
        )}
      </div>
    </div>
  );
};

export default FileDropZone;
