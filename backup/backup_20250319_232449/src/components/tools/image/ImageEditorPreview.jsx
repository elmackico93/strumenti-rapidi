// src/components/tools/image/ImageEditorPreview.jsx
import { useState, useEffect } from 'react';

const ImageEditorPreview = ({ file, options, preview }) => {
  const [originalPreview, setOriginalPreview] = useState(null);
  
  // Generate preview of original image for comparison
  useEffect(() => {
    if (file) {
      const reader = new FileReader();
      reader.onload = (e) => {
        setOriginalPreview(e.target.result);
      };
      reader.readAsDataURL(file);
    }
  }, [file]);
  
  // Format file size
  const formatFileSize = (bytes) => {
    if (!bytes) return '0 B';
    
    if (bytes < 1024) {
      return `${bytes} B`;
    } else if (bytes < 1024 * 1024) {
      return `${(bytes / 1024).toFixed(1)} KB`;
    } else {
      return `${(bytes / (1024 * 1024)).toFixed(1)} MB`;
    }
  };
  
  return (
    <div className="image-preview-container">
      {preview?.url ? (
        <div className="space-y-4">
          <div className="flex flex-col md:flex-row gap-4">
            <div className="flex-1">
              <h4 className="text-sm font-medium mb-2">Original</h4>
              <div className="border rounded-md overflow-hidden bg-gray-100 dark:bg-gray-800 relative">
                {originalPreview && (
                  <img 
                    src={originalPreview} 
                    alt="Original image" 
                    className="max-w-full max-h-64 mx-auto"
                  />
                )}
                <div className="absolute bottom-0 left-0 right-0 bg-black bg-opacity-60 text-white text-xs p-1 text-center">
                  {file && file.width && file.height ? 
                    `${file.width}×${file.height}px` : 
                    'Original size'
                  } • {formatFileSize(file?.size)}
                </div>
              </div>
            </div>
            
            <div className="flex-1">
              <h4 className="text-sm font-medium mb-2">Processed</h4>
              <div className="border rounded-md overflow-hidden bg-gray-100 dark:bg-gray-800 relative">
                <img 
                  src={preview.url} 
                  alt="Processed image preview" 
                  className="max-w-full max-h-64 mx-auto"
                />
                <div className="absolute bottom-0 left-0 right-0 bg-black bg-opacity-60 text-white text-xs p-1 text-center">
                  {preview.width}×{preview.height}px • ~{formatFileSize(preview.estimatedSize)}
                </div>
              </div>
            </div>
          </div>
          
          <div className="p-3 bg-blue-50 dark:bg-blue-900 dark:bg-opacity-20 rounded-md text-sm">
            <h4 className="font-medium mb-1">Output Information</h4>
            <div className="space-y-1">
              <p>
                <span className="font-medium">Format:</span> {options.format.toUpperCase()}
              </p>
              {options.format !== 'png' && (
                <p>
                  <span className="font-medium">Quality:</span> {options.quality}%
                </p>
              )}
              {preview.estimatedSize && file?.size && (
                <p>
                  <span className="font-medium">Size reduction:</span> {' '}
                  {Math.round((1 - (preview.estimatedSize * 1024) / file.size) * 100)}%
                </p>
              )}
              <p>
                <span className="font-medium">Dimensions:</span> {' '}
                {preview.width}×{preview.height}px
              </p>
            </div>
          </div>
        </div>
      ) : (
        <div className="flex items-center justify-center h-64 bg-gray-100 dark:bg-gray-800 rounded-md">
          <p className="text-gray-500">
            {file ? 'Generating preview...' : 'Upload an image to see preview'}
          </p>
        </div>
      )}
    </div>
  );
};

export default ImageEditorPreview;
