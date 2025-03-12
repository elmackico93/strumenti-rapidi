// src/components/wizard/FileUploadStep.jsx
import { useState, useEffect } from 'react';
import FileDropZone from '../ui/FileDropZone';
import FilePreview from '../ui/FilePreview';
import { detectFileProperties } from '../../services/smartDetection';

const FileUploadStep = ({ data, updateData, goNext, toolId, themeColor }) => {
  const [file, setFile] = useState(data.file || null);
  const [isLoading, setIsLoading] = useState(false);
  const [smartDetection, setSmartDetection] = useState(null);
  
  // Reset state if the tool changes
  useEffect(() => {
    setFile(null);
    setSmartDetection(null);
  }, [toolId]);
  
  // Get tool configuration
  const toolConfig = window.toolRegistry?.[toolId] || {
    acceptedFormats: [],
    maxFileSize: 50 * 1024 * 1024, // 50MB default
    fileIcon: null
  };
  
  // Handle file selection
  const handleFileChange = async (selectedFile) => {
    setFile(selectedFile);
    setIsLoading(true);
    
    try {
      // Perform smart detection
      const detectionResult = await detectFileProperties(selectedFile);
      setSmartDetection(detectionResult);
      
      // Update wizard data
      updateData({
        file: selectedFile,
        smartSuggestions: detectionResult
      });
    } catch (error) {
      console.error('Smart detection failed:', error);
    } finally {
      setIsLoading(false);
    }
  };
  
  // Remove selected file
  const handleRemoveFile = () => {
    setFile(null);
    setSmartDetection(null);
    updateData({ file: null, smartSuggestions: null });
  };
  
  // Button animation style
  const buttonStyle = {
    backgroundColor: themeColor,
    transform: 'scale(1)',
    transition: 'transform 0.2s, background-color 0.2s'
  };
  
  const buttonHoverStyle = {
    transform: 'scale(1.05)',
    backgroundColor: themeColor
  };
  
  return (
    <div className="step-container">
      <h2 className="text-xl font-semibold mb-4">Select Your File</h2>
      
      {!file ? (
        <FileDropZone 
          onFileSelect={handleFileChange}
          acceptedFormats={toolConfig.acceptedFormats}
          maxSize={toolConfig.maxFileSize}
          icon={toolConfig.fileIcon}
        />
      ) : (
        <div className="space-y-6">
          <FilePreview 
            file={file}
            onRemove={handleRemoveFile}
          />
          
          {isLoading ? (
            <div className="flex justify-center py-4">
              <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-primary-500"></div>
              <span className="ml-2">Analyzing file...</span>
            </div>
          ) : (
            <>
              {smartDetection && (
                <div 
                  className="p-4 rounded-lg bg-blue-50 dark:bg-blue-900 dark:bg-opacity-20 border border-blue-200 dark:border-blue-800"
                  style={{ 
                    opacity: 0,
                    transform: 'translateY(10px)',
                    animation: 'fadeIn 0.3s forwards',
                    animationDelay: '0.2s'
                  }}
                >
                  <h3 className="text-lg font-medium mb-2">Smart Detection Results</h3>
                  <ul className="space-y-1">
                    {smartDetection.detectedInfo && smartDetection.detectedInfo.map((info, index) => (
                      <li key={index} className="text-sm">{info}</li>
                    ))}
                    
                    {smartDetection.suggestions && smartDetection.suggestions.map((suggestion, index) => (
                      <li key={`suggestion-${index}`} className="text-sm text-blue-700 dark:text-blue-300">
                        <span className="font-medium">Suggestion:</span> {suggestion}
                      </li>
                    ))}
                  </ul>
                </div>
              )}
              
              <div className="flex justify-end">
                <button
                  className="primary-button text-white"
                  style={buttonStyle}
                  onMouseOver={(e) => Object.assign(e.target.style, buttonHoverStyle)}
                  onMouseOut={(e) => Object.assign(e.target.style, buttonStyle)}
                  onClick={goNext}
                >
                  Continue to Options
                  <svg className="ml-2 w-5 h-5 inline" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 5l7 7-7 7" />
                  </svg>
                </button>
              </div>
            </>
          )}
        </div>
      )}
    </div>
  );
};

export default FileUploadStep;
