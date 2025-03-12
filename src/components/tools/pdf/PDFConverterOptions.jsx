// src/components/tools/pdf/PDFConverterOptions.jsx
import { useState, useEffect } from 'react';

const PDFConverterOptions = ({ data, options, onChange, smartSuggestions }) => {
  const [conversionParams, setConversionParams] = useState({
    targetFormat: 'docx',
    quality: 'high',
    pageRange: 'all',
    preserveLinks: true,
    preserveFormatting: true,
    customPages: '1-5'
  });
  
  // Initialize with smart suggestions if available
  useEffect(() => {
    if (smartSuggestions?.recommendedFormat) {
      setConversionParams(prev => ({
        ...prev,
        targetFormat: smartSuggestions.recommendedFormat
      }));
    } else if (Object.keys(options || {}).length > 0) {
      setConversionParams(options);
    }
  }, [smartSuggestions, options]);
  
  // Update parent when params change
  useEffect(() => {
    onChange(conversionParams);
  }, [conversionParams, onChange]);
  
  // Handle format change
  const handleFormatChange = (format) => {
    setConversionParams(prev => ({
      ...prev,
      targetFormat: format
    }));
  };
  
  // Handle quality change
  const handleQualityChange = (quality) => {
    setConversionParams(prev => ({
      ...prev,
      quality
    }));
  };
  
  // Handle page range change
  const handlePageRangeChange = (range) => {
    setConversionParams(prev => ({
      ...prev,
      pageRange: range
    }));
  };
  
  // Handle custom pages input
  const handleCustomPagesChange = (pages) => {
    setConversionParams(prev => ({
      ...prev,
      customPages: pages
    }));
  };
  
  // Toggle options
  const toggleOption = (option) => {
    setConversionParams(prev => ({
      ...prev,
      [option]: !prev[option]
    }));
  };
  
  return (
    <div className="pdf-converter-options space-y-6">
      <div>
        <h3 className="text-lg font-medium mb-3">Output Format</h3>
        <div className="grid grid-cols-2 md:grid-cols-3 gap-2">
          {[
            { id: 'docx', label: 'Word', icon: 'word-icon' },
            { id: 'jpg', label: 'JPG', icon: 'jpg-icon' },
            { id: 'png', label: 'PNG', icon: 'png-icon' },
            { id: 'txt', label: 'Text', icon: 'txt-icon' },
            { id: 'html', label: 'HTML', icon: 'html-icon' },
            { id: 'xlsx', label: 'Excel', icon: 'excel-icon' }
          ].map(format => (
            <button
              key={format.id}
              className={`p-3 rounded-lg flex flex-col items-center justify-center ${
                conversionParams.targetFormat === format.id
                  ? 'bg-red-100 text-red-700 dark:bg-red-900 dark:bg-opacity-30 dark:text-red-300'
                  : 'bg-gray-100 dark:bg-gray-700'
              }`}
              onClick={() => handleFormatChange(format.id)}
            >
              <span className="text-sm font-medium">{format.label}</span>
            </button>
          ))}
        </div>
        
        {smartSuggestions?.recommendedFormat && (
          <div className="mt-2 text-xs text-blue-600 dark:text-blue-400">
            <span className="font-medium">Recommended:</span> {smartSuggestions.recommendedFormat.toUpperCase()}
          </div>
        )}
      </div>
      
      <div>
        <h3 className="text-lg font-medium mb-3">Quality</h3>
        <div className="flex justify-between space-x-2">
          {['low', 'medium', 'high'].map(quality => (
            <button
              key={quality}
              className={`flex-1 p-2 rounded-lg text-center capitalize ${
                conversionParams.quality === quality
                  ? 'bg-red-100 text-red-700 dark:bg-red-900 dark:bg-opacity-30 dark:text-red-300'
                  : 'bg-gray-100 dark:bg-gray-700'
              }`}
              onClick={() => handleQualityChange(quality)}
            >
              {quality}
            </button>
          ))}
        </div>
        <div className="flex justify-between mt-1 text-xs text-gray-500">
          <span>Smaller Size</span>
          <span>Better Quality</span>
        </div>
      </div>
      
      <div>
        <h3 className="text-lg font-medium mb-3">Page Range</h3>
        <div className="space-y-2">
          <div className="flex items-center space-x-2">
            <input
              type="radio"
              id="all-pages"
              checked={conversionParams.pageRange === 'all'}
              onChange={() => handlePageRangeChange('all')}
            />
            <label htmlFor="all-pages">All pages</label>
          </div>
          
          <div className="flex items-center space-x-2">
            <input
              type="radio"
              id="custom-pages"
              checked={conversionParams.pageRange === 'custom'}
              onChange={() => handlePageRangeChange('custom')}
            />
            <label htmlFor="custom-pages">Custom pages</label>
          </div>
          
          {conversionParams.pageRange === 'custom' && (
            <div className="pl-6 mt-2">
              <input
                type="text"
                value={conversionParams.customPages}
                onChange={(e) => handleCustomPagesChange(e.target.value)}
                placeholder="e.g. 1-5, 8, 11-13"
                className="w-full px-3 py-2 border rounded-md dark:bg-gray-700 dark:border-gray-600"
              />
              <p className="text-xs text-gray-500 mt-1">
                Use commas to separate pages and hyphens for ranges
              </p>
            </div>
          )}
        </div>
      </div>
      
      <div>
        <h3 className="text-lg font-medium mb-3">Additional Options</h3>
        <div className="space-y-3">
          <div className="flex items-center">
            <input
              type="checkbox"
              id="preserve-links"
              checked={conversionParams.preserveLinks}
              onChange={() => toggleOption('preserveLinks')}
              className="mr-2"
            />
            <label htmlFor="preserve-links">Preserve hyperlinks</label>
          </div>
          
          <div className="flex items-center">
            <input
              type="checkbox"
              id="preserve-formatting"
              checked={conversionParams.preserveFormatting}
              onChange={() => toggleOption('preserveFormatting')}
              className="mr-2"
            />
            <label htmlFor="preserve-formatting">Preserve formatting</label>
          </div>
        </div>
      </div>
    </div>
  );
};

export default PDFConverterOptions;
