// src/components/tools/image/ImageEditorOptions.jsx
import { useState, useEffect } from 'react';

const ImageEditorOptions = ({ data, options, onChange, smartSuggestions }) => {
  const [imageParams, setImageParams] = useState({
    resize: { width: null, height: null, maintainRatio: true },
    format: 'jpg',
    quality: 80,
    filters: {
      brightness: 0,
      contrast: 0,
      saturation: 0
    }
  });
  
  // Initialize with smart suggestions if available
  useEffect(() => {
    if (smartSuggestions) {
      const updatedParams = { ...imageParams };
      
      if (smartSuggestions.recommendedFormat) {
        updatedParams.format = smartSuggestions.recommendedFormat;
      }
      
      if (smartSuggestions.recommendedQuality) {
        updatedParams.quality = smartSuggestions.recommendedQuality;
      }
      
      if (smartSuggestions.recommendedSize) {
        updatedParams.resize = {
          ...updatedParams.resize,
          ...smartSuggestions.recommendedSize
        };
      }
      
      setImageParams(updatedParams);
      onChange(updatedParams);
    } else if (Object.keys(options || {}).length > 0) {
      // Use provided options if available
      setImageParams(options);
    } else if (data.file) {
      // Initialize with file dimensions if available
      const img = new Image();
      img.onload = () => {
        setImageParams(prev => ({
          ...prev,
          resize: {
            ...prev.resize,
            width: img.width,
            height: img.height,
            original: { width: img.width, height: img.height }
          }
        }));
      };
      img.src = URL.createObjectURL(data.file);
    }
  }, [smartSuggestions, options, data.file, onChange]);
  
  // Update parent when any param changes
  useEffect(() => {
    onChange(imageParams);
  }, [imageParams, onChange]);
  
  // Handle dimension changes while maintaining aspect ratio
  const handleDimensionChange = (dimension, value) => {
    const numValue = value === '' ? null : parseInt(value, 10);
    
    const updatedResize = { ...imageParams.resize };
    updatedResize[dimension] = numValue;
    
    // Calculate other dimension if maintaining ratio
    if (numValue && updatedResize.maintainRatio && updatedResize.original) {
      const ratio = updatedResize.original.width / updatedResize.original.height;
      
      if (dimension === 'width') {
        updatedResize.height = Math.round(numValue / ratio);
      } else {
        updatedResize.width = Math.round(numValue * ratio);
      }
    }
    
    setImageParams(prev => ({
      ...prev,
      resize: updatedResize
    }));
  };
  
  // Toggle aspect ratio maintenance
  const toggleMaintainRatio = () => {
    setImageParams(prev => ({
      ...prev,
      resize: {
        ...prev.resize,
        maintainRatio: !prev.resize.maintainRatio
      }
    }));
  };
  
  // Handle format change
  const handleFormatChange = (format) => {
    setImageParams(prev => ({
      ...prev,
      format
    }));
  };
  
  // Handle quality change
  const handleQualityChange = (quality) => {
    setImageParams(prev => ({
      ...prev,
      quality: parseInt(quality, 10)
    }));
  };
  
  // Handle filter change
  const handleFilterChange = (filter, value) => {
    setImageParams(prev => ({
      ...prev,
      filters: {
        ...prev.filters,
        [filter]: parseInt(value, 10)
      }
    }));
  };
  
  return (
    <div className="image-editor-options space-y-6">
      <div>
        <h3 className="text-lg font-medium mb-3">Resize</h3>
        <div className="space-y-3">
          <div className="grid grid-cols-2 gap-4">
            <div>
              <label className="block text-sm font-medium mb-1" htmlFor="width">
                Width (px)
              </label>
              <input
                type="number"
                id="width"
                value={imageParams.resize.width || ''}
                onChange={(e) => handleDimensionChange('width', e.target.value)}
                className="w-full px-3 py-2 border rounded-md dark:bg-gray-700 dark:border-gray-600"
                placeholder="Width"
                min="1"
              />
            </div>
            <div>
              <label className="block text-sm font-medium mb-1" htmlFor="height">
                Height (px)
              </label>
              <input
                type="number"
                id="height"
                value={imageParams.resize.height || ''}
                onChange={(e) => handleDimensionChange('height', e.target.value)}
                className="w-full px-3 py-2 border rounded-md dark:bg-gray-700 dark:border-gray-600"
                placeholder="Height"
                min="1"
              />
            </div>
          </div>
          
          <div className="flex items-center">
            <input
              type="checkbox"
              id="maintain-ratio"
              checked={imageParams.resize.maintainRatio}
              onChange={toggleMaintainRatio}
              className="mr-2"
            />
            <label htmlFor="maintain-ratio" className="text-sm">
              Maintain aspect ratio
            </label>
          </div>
        </div>
      </div>
      
      <div>
        <h3 className="text-lg font-medium mb-3">Format & Quality</h3>
        <div className="space-y-4">
          <div>
            <label className="block text-sm font-medium mb-2">
              Format
            </label>
            <div className="grid grid-cols-4 gap-2">
              {['jpg', 'png', 'webp', 'gif'].map((format) => (
                <button
                  key={format}
                  className={`px-3 py-2 rounded-md text-center text-sm uppercase ${
                    imageParams.format === format 
                      ? 'bg-blue-500 text-white' 
                      : 'bg-gray-100 dark:bg-gray-700'
                  }`}
                  onClick={() => handleFormatChange(format)}
                >
                  {format}
                </button>
              ))}
            </div>
          </div>
          
          {imageParams.format !== 'png' && (
            <div>
              <label className="block text-sm font-medium mb-2">
                Quality: {imageParams.quality}%
              </label>
              <input
                type="range"
                min="1"
                max="100"
                value={imageParams.quality}
                onChange={(e) => handleQualityChange(e.target.value)}
                className="w-full"
              />
              <div className="flex justify-between text-xs text-gray-500">
                <span>Lower quality, smaller file</span>
                <span>Best quality</span>
              </div>
            </div>
          )}
        </div>
      </div>
      
      <div>
        <h3 className="text-lg font-medium mb-3">Adjustments</h3>
        <div className="space-y-4">
          <div>
            <label className="block text-sm font-medium mb-1">
              Brightness: {imageParams.filters.brightness}
            </label>
            <input
              type="range"
              min="-100"
              max="100"
              value={imageParams.filters.brightness}
              onChange={(e) => handleFilterChange('brightness', e.target.value)}
              className="w-full"
            />
          </div>
          
          <div>
            <label className="block text-sm font-medium mb-1">
              Contrast: {imageParams.filters.contrast}
            </label>
            <input
              type="range"
              min="-100"
              max="100"
              value={imageParams.filters.contrast}
              onChange={(e) => handleFilterChange('contrast', e.target.value)}
              className="w-full"
            />
          </div>
          
          <div>
            <label className="block text-sm font-medium mb-1">
              Saturation: {imageParams.filters.saturation}
            </label>
            <input
              type="range"
              min="-100"
              max="100"
              value={imageParams.filters.saturation}
              onChange={(e) => handleFilterChange('saturation', e.target.value)}
              className="w-full"
            />
          </div>
        </div>
      </div>
    </div>
  );
};

export default ImageEditorOptions;
