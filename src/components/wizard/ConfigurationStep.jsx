// src/components/wizard/ConfigurationStep.jsx
import { useState, useEffect } from 'react';
import { generatePreview } from '../../services/previewService';
import AdaptiveButton from '../ui/AdaptiveButton';
import { useOS } from '../../context/OSContext';

const ConfigurationStep = ({ 
  data, 
  updateData, 
  goNext, 
  goBack, 
  themeColor,
  optionsComponent: OptionsComponent,
  previewComponent: PreviewComponent
}) => {
  const [options, setOptions] = useState({});
  const [preview, setPreview] = useState(null);
  const [isGeneratingPreview, setIsGeneratingPreview] = useState(false);
  const { isMobile } = useOS();
  
  // Initialize options
  useEffect(() => {
    const initialOptions = data.options || {};
    setOptions(initialOptions);
  }, [data]);
  
  // Generate preview when options change
  useEffect(() => {
    if (!data.file) return;
    
    const generateFilePreview = async () => {
      setIsGeneratingPreview(true);
      try {
        const previewResult = await generatePreview(data.file, options);
        setPreview(previewResult);
      } catch (error) {
        console.error('Preview generation failed:', error);
      } finally {
        setIsGeneratingPreview(false);
      }
    };
    
    // Debounce preview generation
    const timeoutId = setTimeout(() => {
      generateFilePreview();
    }, 500);
    
    return () => clearTimeout(timeoutId);
  }, [data.file, options]);
  
  // Handle options change
  const handleOptionsChange = (newOptions) => {
    setOptions(newOptions);
  };
  
  // Continue to next step
  const handleContinue = () => {
    updateData({ options });
    goNext();
  };
  
  return (
    <div className="step-container">
      <h2 className="text-xl font-semibold mb-4">Configure Options</h2>
      
      <div className={`flex ${isMobile ? 'flex-col' : 'flex-row'} gap-6`}>
        <div className={isMobile ? 'w-full' : 'md:w-2/5'}>
          <div className="glass-card p-4 h-full">
            {OptionsComponent ? (
              <OptionsComponent 
                data={data}
                options={options}
                onChange={handleOptionsChange}
                smartSuggestions={data.smartSuggestions}
              />
            ) : (
              <div className="p-4 text-center text-gray-500">
                No configuration options available for this tool.
              </div>
            )}
          </div>
        </div>
        
        <div className={isMobile ? 'w-full' : 'md:w-3/5'}>
          <div className="glass-card p-4 h-full">
            <h3 className="text-lg font-medium mb-3">Preview</h3>
            
            {isGeneratingPreview ? (
              <div className="flex justify-center items-center h-64">
                <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-primary-500"></div>
                <span className="ml-2">Generating preview...</span>
              </div>
            ) : (
              <>
                {PreviewComponent ? (
                  <PreviewComponent 
                    file={data.file}
                    options={options}
                    preview={preview}
                  />
                ) : (
                  <div className="p-4 text-center text-gray-500 h-64 flex items-center justify-center">
                    <p>Preview not available for this tool.</p>
                  </div>
                )}
              </>
            )}
          </div>
        </div>
      </div>
      
      <div className="flex justify-between mt-6">
        <AdaptiveButton
          variant="secondary"
          onClick={goBack}
        >
          <svg className="mr-2 w-5 h-5 inline" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M15 19l-7-7 7-7" />
          </svg>
          Indietro
        </AdaptiveButton>
        
        <AdaptiveButton
          variant="primary"
          onClick={handleContinue}
          style={{ backgroundColor: themeColor }}
        >
          Procedi
          <svg className="ml-2 w-5 h-5 inline" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 5l7 7-7 7" />
          </svg>
        </AdaptiveButton>
      </div>
    </div>
  );
};

export default ConfigurationStep;
