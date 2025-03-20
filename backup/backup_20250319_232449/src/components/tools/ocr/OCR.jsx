import { useState } from 'react';
import { createWorker } from 'tesseract.js';
import FileDropZone from '../../ui/FileDropZone';
import FilePreview from '../../ui/FilePreview';
import AdaptiveButton from '../../ui/AdaptiveButton';
import AdaptiveSelect from '../../ui/AdaptiveSelect';

const OCR = () => {
  const [file, setFile] = useState(null);
  const [isProcessing, setIsProcessing] = useState(false);
  const [result, setResult] = useState(null);
  const [language, setLanguage] = useState('ita');
  
  const languageOptions = [
    { value: 'ita', label: 'Italiano' },
    { value: 'eng', label: 'Inglese' },
    { value: 'fra', label: 'Francese' },
    { value: 'deu', label: 'Tedesco' },
    { value: 'spa', label: 'Spagnolo' }
  ];
  
  const handleFileChange = (selectedFile) => {
    setFile(selectedFile);
    setResult(null);
  };
  
  const processImage = async () => {
    if (!file) return;
    setIsProcessing(true);
    
    try {
      const worker = await createWorker();
      await worker.loadLanguage(language);
      await worker.initialize(language);
      const { data } = await worker.recognize(file);
      setResult({
        text: data.text,
        confidence: data.confidence
      });
      await worker.terminate();
    } catch (err) {
      console.error('OCR failed:', err);
    } finally {
      setIsProcessing(false);
    }
  };
  
  return (
    <div className="container mx-auto px-4 py-8">
      <div className="max-w-2xl mx-auto">
        <h1 className="text-3xl font-bold mb-6 text-center text-text-500">Estrazione Testo (OCR)</h1>
        
        <div className="glass-card p-6">
          {!file ? (
            <FileDropZone 
              onFileSelect={handleFileChange}
              acceptedFormats={['.jpg', '.jpeg', '.png', '.pdf']}
              maxSize={10 * 1024 * 1024}
            />
          ) : (
            <div className="space-y-4">
              <FilePreview file={file} onRemove={() => setFile(null)} />
              
              <div>
                <AdaptiveSelect
                  label="Lingua"
                  value={language}
                  onChange={(e) => setLanguage(e.target.value)}
                  options={languageOptions}
                  fullWidth
                />
              </div>
              
              <AdaptiveButton 
                variant="primary"
                onClick={processImage}
                disabled={isProcessing}
                fullWidth
                className="bg-text-500 hover:bg-text-600 text-white flex justify-center items-center"
              >
                {isProcessing ? (
                  <>
                    <svg className="animate-spin -ml-1 mr-2 h-5 w-5 text-white" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24">
                      <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4"></circle>
                      <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
                    </svg>
                    Elaborazione...
                  </>
                ) : "Estrai Testo"}
              </AdaptiveButton>
              
              {result && (
                <div className="mt-4">
                  <h3 className="font-bold mb-2">Testo Estratto:</h3>
                  <div className="p-4 bg-gray-50 dark:bg-gray-800 rounded-lg max-h-64 overflow-y-auto whitespace-pre-wrap">
                    {result.text || "Nessun testo rilevato"}
                  </div>
                  <div className="mt-2 text-sm text-gray-500">
                    Confidenza: {Math.round(result.confidence)}%
                  </div>
                </div>
              )}
            </div>
          )}
        </div>
      </div>
    </div>
  );
};

export default OCR;
