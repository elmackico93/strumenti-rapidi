// src/components/wizard/ResultStep.jsx
import { useState, useEffect } from 'react';
import { processFile } from '../../services/processingService';

const ResultStep = ({ data, updateData, goBack, setResult, result, themeColor }) => {
  const [isProcessing, setIsProcessing] = useState(!result);
  const [error, setError] = useState(null);
  const [downloadStarted, setDownloadStarted] = useState(false);
  
  // Process the file if no result exists
  useEffect(() => {
    if (!result && data.file && data.options) {
      const processData = async () => {
        setIsProcessing(true);
        setError(null);
        
        try {
          const processedResult = await processFile(data.file, data.options);
          setResult(processedResult);
        } catch (err) {
          console.error('Processing failed:', err);
          setError(err.message || 'Processing failed. Please try again.');
        } finally {
          setIsProcessing(false);
        }
      };
      
      processData();
    }
  }, [data.file, data.options, result, setResult]);
  
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
  
  // Handle download
  const handleDownload = () => {
    if (!result?.outputFile) return;
    
    try {
      // In a real implementation, this would use file-saver
      const url = URL.createObjectURL(result.outputFile);
      const a = document.createElement('a');
      a.href = url;
      a.download = result.outputName || 'download';
      document.body.appendChild(a);
      a.click();
      document.body.removeChild(a);
      URL.revokeObjectURL(url);
      
      setDownloadStarted(true);
      
      // Track download for analytics
      if (window.gtag) {
        window.gtag('event', 'file_download', {
          event_category: 'conversion',
          event_label: result.outputType
        });
      }
    } catch (err) {
      console.error('Download failed:', err);
      setError('Download failed. Please try again.');
    }
  };
  
  // Handle cloud save
  const saveToCloud = (provider) => {
    // Implement cloud save functionality
    alert(`Saving to ${provider} will be implemented soon!`);
  };
  
  // Start new conversion
  const handleStartNew = () => {
    window.location.reload();
  };
  
  // Button styles
  const buttonStyle = {
    backgroundColor: themeColor,
    transform: 'scale(1)',
    transition: 'transform 0.2s, background-color 0.2s'
  };
  
  const buttonHoverStyle = {
    transform: 'scale(1.03)',
    backgroundColor: themeColor
  };
  
  return (
    <div className="step-container">
      {isProcessing ? (
        <div className="glass-card p-8 text-center">
          <div className="flex flex-col items-center">
            <div className="animate-spin rounded-full h-16 w-16 border-b-4 border-primary-500"></div>
            <h2 className="text-xl font-semibold mt-6 mb-2">Processing Your File</h2>
            <p className="text-gray-600 dark:text-gray-400">
              Please wait while we process your file. This may take a moment...
            </p>
          </div>
        </div>
      ) : error ? (
        <div className="glass-card p-8">
          <div className="flex flex-col items-center text-center">
            <div className="rounded-full bg-red-100 dark:bg-red-900 dark:bg-opacity-20 p-4 text-red-500">
              <svg className="w-12 h-12" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 8v4m0 4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
              </svg>
            </div>
            <h2 className="text-xl font-semibold mt-6 mb-2">Processing Failed</h2>
            <p className="text-gray-600 dark:text-gray-400 mb-6">
              {error}
            </p>
            <div className="flex space-x-4">
              <button
                className="secondary-button border border-gray-300 dark:border-gray-600 px-6 py-2 rounded-lg"
                style={{
                  transform: 'scale(1)',
                  transition: 'transform 0.2s'
                }}
                onMouseOver={(e) => e.target.style.transform = 'scale(1.05)'}
                onMouseOut={(e) => e.target.style.transform = 'scale(1)'}
                onClick={goBack}
              >
                Back to Options
              </button>
              <button
                className="primary-button text-white px-6 py-2 rounded-lg"
                style={buttonStyle}
                onMouseOver={(e) => Object.assign(e.target.style, buttonHoverStyle)}
                onMouseOut={(e) => Object.assign(e.target.style, buttonStyle)}
                onClick={handleStartNew}
              >
                Start New Conversion
              </button>
            </div>
          </div>
        </div>
      ) : result ? (
        <div className="glass-card p-8">
          <div className="flex flex-col items-center text-center">
            <div className="rounded-full bg-green-100 dark:bg-green-900 dark:bg-opacity-20 p-4 text-green-500">
              <svg className="w-12 h-12" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M5 13l4 4L19 7" />
              </svg>
            </div>
            <h2 className="text-xl font-semibold mt-6 mb-2">Processing Complete</h2>
            
            <div className="result-summary mb-6">
              <p className="text-gray-600 dark:text-gray-400">
                Converted {data.file.name} ({formatFileSize(data.file.size)})
                to {result.outputType} ({formatFileSize(result.outputSize || 0)})
              </p>
              
              {result.compressionRate && (
                <p className="text-green-600 dark:text-green-400 font-medium mt-1">
                  Reduced file size by {result.compressionRate}%
                </p>
              )}
            </div>
            
            {!downloadStarted ? (
              <div className="space-y-4 w-full max-w-sm">
                <button
                  className="primary-button w-full text-white px-6 py-3 rounded-lg flex items-center justify-center"
                  style={buttonStyle}
                  onMouseOver={(e) => Object.assign(e.target.style, buttonHoverStyle)}
                  onMouseOut={(e) => Object.assign(e.target.style, buttonStyle)}
                  onClick={handleDownload}
                >
                  <svg className="w-5 h-5 mr-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M4 16v1a3 3 0 003 3h10a3 3 0 003-3v-1m-4-4l-4 4m0 0l-4-4m4 4V4" />
                  </svg>
                  Download Result
                </button>
                
                <div className="text-center">
                  <p className="text-sm text-gray-500 dark:text-gray-400 mb-2">
                    Or save directly to cloud:
                  </p>
                  <div className="flex justify-center space-x-4">
                    <button 
                      className="p-2 border rounded-lg hover:bg-gray-50 dark:hover:bg-gray-700"
                      onClick={() => saveToCloud('google-drive')}
                    >
                      <span className="sr-only">Google Drive</span>
                      <svg className="w-6 h-6 text-blue-500" fill="currentColor" viewBox="0 0 24 24">
                        <path d="M12 10L6 18H18L12 10Z" />
                        <path d="M12 2L2 17H8L18 2H12Z" />
                        <path d="M16 17L22 17L16 7L10 7L16 17Z" />
                      </svg>
                    </button>
                    <button 
                      className="p-2 border rounded-lg hover:bg-gray-50 dark:hover:bg-gray-700"
                      onClick={() => saveToCloud('dropbox')}
                    >
                      <span className="sr-only">Dropbox</span>
                      <svg className="w-6 h-6 text-blue-600" fill="currentColor" viewBox="0 0 24 24">
                        <path d="M12 14.5L6 10.5L12 6.5L18 10.5L12 14.5Z" />
                        <path d="M12 14.5L6 18.5L12 22.5L18 18.5L12 14.5Z" />
                        <path d="M6 10.5L0 6.5L6 2.5L12 6.5L6 10.5Z" />
                        <path d="M18 10.5L24 6.5L18 2.5L12 6.5L18 10.5Z" />
                      </svg>
                    </button>
                  </div>
                </div>
              </div>
            ) : (
              <div className="space-y-4 w-full max-w-sm">
                <p className="text-green-600 dark:text-green-400 mb-4">
                  Your download has started!
                </p>
                <button
                  className="secondary-button w-full border border-gray-300 dark:border-gray-600 px-6 py-3 rounded-lg flex items-center justify-center"
                  style={{
                    transform: 'scale(1)',
                    transition: 'transform 0.2s'
                  }}
                  onMouseOver={(e) => e.target.style.transform = 'scale(1.03)'}
                  onMouseOut={(e) => e.target.style.transform = 'scale(1)'}
                  onClick={handleStartNew}
                >
                  <svg className="w-5 h-5 mr-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M4 4v5h.582m15.356 2A8.001 8.001 0 004.582 9m0 0H9m11 11v-5h-.581m0 0a8.003 8.003 0 01-15.357-2m15.357 2H15" />
                  </svg>
                  Convert Another File
                </button>
              </div>
            )}
          </div>
        </div>
      ) : (
        <div className="glass-card p-8 text-center">
          <p>No result available. Please go back and try again.</p>
          <button
            className="secondary-button border border-gray-300 dark:border-gray-600 px-6 py-2 rounded-lg mt-4"
            onClick={goBack}
          >
            Back to Options
          </button>
        </div>
      )}
    </div>
  );
};

export default ResultStep;
