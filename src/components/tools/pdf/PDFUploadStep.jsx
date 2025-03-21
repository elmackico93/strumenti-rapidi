// src/components/tools/pdf/PDFUploadStep.jsx
import { useState, useEffect } from 'react';
import { motion } from 'framer-motion';
import FileDropZone from '../../ui/FileDropZone';
import FilePreview from '../../ui/FilePreview';
import AdaptiveButton from '../../ui/AdaptiveButton';
import { useOS } from '../../../context/OSContext';

const PDFUploadStep = ({ data, updateData, goNext, toolId, themeColor, conversionType, onConversionTypeChange }) => {
  const { osType, isMobile } = useOS();
  const [files, setFiles] = useState(data.files || []);
  const [isAnalyzing, setIsAnalyzing] = useState(false);
  const [fileInfo, setFileInfo] = useState(null);
  const [error, setError] = useState(null);
  
  // Opzioni di tipo di conversione
  const conversionTypes = [
    { id: 'convert', label: 'Converti PDF', icon: 'transform', description: 'Converti PDF in altri formati' },
    { id: 'compress', label: 'Comprimi PDF', icon: 'compress', description: 'Riduci la dimensione del file PDF' },
    { id: 'protect', label: 'Proteggi PDF', icon: 'lock', description: 'Aggiungi password al tuo PDF' },
    { id: 'split', label: 'Dividi PDF', icon: 'scissors', description: 'Dividi il PDF in file separati' },
    { id: 'merge', label: 'Unisci PDF', icon: 'merge', description: 'Combina più PDF in un unico file' }
  ];
  
  // Inizializza lo stato dai dati esistenti
  useEffect(() => {
    if (data.files) {
      setFiles(data.files);
    }
    
    if (data.fileInfo) {
      setFileInfo(data.fileInfo);
    }
    
    if (data.conversionType) {
      onConversionTypeChange(data.conversionType);
    }
  }, [data, onConversionTypeChange]);
  
  // Analyze a PDF file to get its page count
  const analyzePDF = async (file) => {
    return new Promise((resolve, reject) => {
      try {
        // Use PDF.js to analyze the PDF
        const reader = new FileReader();
        reader.onload = async function(event) {
          try {
            const typedArray = new Uint8Array(event.target.result);
            const loadingTask = window.pdfjsLib.getDocument(typedArray);
            const pdf = await loadingTask.promise;
            const numPages = pdf.numPages;
            
            resolve({
              name: file.name,
              size: file.size,
              pages: numPages,
              format: 'PDF'
            });
          } catch (err) {
            console.error('Error analyzing PDF with PDF.js:', err);
            // Fallback to a default page count
            resolve({
              name: file.name,
              size: file.size,
              pages: 1, // Default fallback
              format: 'PDF'
            });
          }
        };
        reader.onerror = () => {
          reject(new Error('Could not read the file'));
        };
        reader.readAsArrayBuffer(file);
      } catch (err) {
        console.error('Error in analyzePDF:', err);
        reject(err);
      }
    });
  };
  
  // Gestisci il caricamento dei file
  const handleFileChange = async (selectedFiles) => {
    setError(null);
    
    // Convert single file to array if needed
    const fileArray = Array.isArray(selectedFiles) ? selectedFiles : [selectedFiles];
    
    // Verifica se sono PDF
    const nonPdfFiles = fileArray.filter(file => 
      file.type !== 'application/pdf' && !file.name.toLowerCase().endsWith('.pdf')
    );
    
    if (nonPdfFiles.length > 0) {
      setError('Sono accettati solo file PDF. Riprova con file PDF validi.');
      return;
    }
    
    // Per l'unione, accetta più file
    if (conversionType === 'merge') {
      setFiles(prevFiles => [...prevFiles, ...fileArray]);
    } else {
      // Per altre operazioni, usa solo il primo file
      setFiles([fileArray[0]]);
    }
    
    // Analisi del file
    setIsAnalyzing(true);
    
    try {
      // Analyze each PDF file to get page count
      const fileInfos = await Promise.all(
        fileArray.map(file => analyzePDF(file))
      );
      
      setFileInfo(fileInfos);
      setIsAnalyzing(false);
    } catch (err) {
      console.error('Errore durante l\'analisi del PDF:', err);
      setError('Impossibile analizzare il file PDF.');
      setIsAnalyzing(false);
    }
  };
  
  // Rimuovi un file dall'elenco
  const handleRemoveFile = (index) => {
    setFiles(prevFiles => prevFiles.filter((_, i) => i !== index));
    setFileInfo(prevInfo => prevInfo ? prevInfo.filter((_, i) => i !== index) : null);
  };
  
  // Cambia il tipo di conversione
  const handleTypeChange = (type) => {
    onConversionTypeChange(type);
    
    // Se passiamo a "merge" e abbiamo già un file, mantienilo
    if (type === 'merge' && files.length === 1) {
      // Non facciamo nulla, manteniamo il file
    } else if (type !== 'merge' && files.length > 1) {
      // Se passiamo da "merge" a un'altra modalità e abbiamo più file, teniamo solo il primo
      setFiles([files[0]]);
      setFileInfo(fileInfo ? [fileInfo[0]] : null);
    }
  };
  
  // Continua alla prossima fase
  const handleContinue = () => {
    // Verifica i requisiti per ciascun tipo di conversione
    if (conversionType === 'merge' && files.length < 2) {
      setError('Sono necessari almeno due file PDF per l\'unione.');
      return;
    }
    
    if (files.length === 0) {
      setError('Carica almeno un file PDF per continuare.');
      return;
    }
    
    // Aggiorna i dati e procedi
    updateData({
      files,
      fileInfo,
      conversionType
    });
    
    goNext();
  };
  
  // Formatta la dimensione del file
  const formatFileSize = (bytes) => {
    if (bytes < 1024) {
      return `${bytes} B`;
    } else if (bytes < 1024 * 1024) {
      return `${(bytes / 1024).toFixed(1)} KB`;
    } else {
      return `${(bytes / (1024 * 1024)).toFixed(1)} MB`;
    }
  };
  
  // Renderizza l'icona per il tipo di conversione
  const renderTypeIcon = (iconName) => {
    switch (iconName) {
      case 'transform':
        return (
          <svg className="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M7 16V4m0 0L3 8m4-4l4 4m6 0v12m0 0l4-4m-4 4l-4-4" />
          </svg>
        );
      case 'compress':
        return (
          <svg className="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M8 7H5a2 2 0 00-2 2v9a2 2 0 002 2h14a2 2 0 002-2V9a2 2 0 00-2-2h-3m-1 4l-3 3m0 0l-3-3m3 3V4" />
          </svg>
        );
      case 'lock':
        return (
          <svg className="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 15v2m-6 4h12a2 2 0 002-2v-6a2 2 0 00-2-2H6a2 2 0 00-2 2v6a2 2 0 002 2zm10-10V7a4 4 0 00-8 0v4h8z" />
          </svg>
        );
      case 'scissors':
        return (
          <svg className="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M14.121 14.121L19 19m-7-7l7-7m-7 7l-2.879 2.879M12 12L9.121 9.121m0 5.758a3 3 0 10-4.243 4.243 3 3 0 004.243-4.243zm0-5.758a3 3 0 10-4.243-4.243 3 3 0 004.243 4.243z" />
          </svg>
        );
      case 'merge':
        return (
          <svg className="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M8 7v8a2 2 0 002 2h6M8 7V5a2 2 0 012-2h4.586a1 1 0 01.707.293l4.414 4.414a1 1 0 01.293.707V15a2 2 0 01-2 2h-2M8 7H6a2 2 0 00-2 2v10a2 2 0 002 2h8a2 2 0 002-2v-2" />
          </svg>
        );
      default:
        return null;
    }
  };
  
  return (
    <div className="step-container space-y-6">
      <motion.div 
        initial={{ opacity: 0 }}
        animate={{ opacity: 1 }}
        transition={{ duration: 0.5 }}
      >
        <div className="glass-card p-4 md:p-6 mb-6">
          <h3 className="text-lg font-medium mb-4">
            {conversionType === "merge" ? "Carica i file PDF da unire" : "Carica il tuo PDF"}
          </h3>
          
          {files.length === 0 ? (
            <FileDropZone 
              onFileSelect={handleFileChange}
              acceptedFormats={[".pdf"]}
              maxSize={100 * 1024 * 1024}
              multiple={conversionType === "merge"}
            />
          ) : (
            <div className="space-y-3">
              {files.map((file, index) => (
                <motion.div
                  key={index}
                  initial={{ opacity: 0, y: 10 }}
                  animate={{ opacity: 1, y: 0 }}
                  transition={{ duration: 0.3, delay: index * 0.1 }}
                >
                  <FilePreview 
                    file={file} 
                    onRemove={() => handleRemoveFile(index)} 
                  />
                  
                  {fileInfo && fileInfo[index] && (
                    <div className="mt-2 ml-2 text-sm text-gray-600 dark:text-gray-400">
                      <span className="font-medium">Pagine:</span> {fileInfo[index].pages} • 
                      <span className="font-medium"> Dimensione:</span> {formatFileSize(file.size)}
                    </div>
                  )}
                </motion.div>
              ))}
              
              {conversionType === "merge" && (
                <motion.div
                  initial={{ opacity: 0 }}
                  animate={{ opacity: 1 }}
                  transition={{ duration: 0.3, delay: 0.2 }}
                >
                  <AdaptiveButton
                    variant="secondary"
                    onClick={() => document.getElementById("add-more-files").click()}
                    className="mt-3"
                  >
                    <svg className="w-5 h-5 mr-2 inline" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 6v6m0 0v6m0-6h6m-6 0H6" />
                    </svg>
                    Aggiungi altro PDF
                  </AdaptiveButton>
                  <input
                    id="add-more-files"
                    type="file"
                    accept=".pdf"
                    multiple
                    className="hidden"
                    onChange={(e) => handleFileChange(Array.from(e.target.files))}
                  />
                </motion.div>
              )}
            </div>
          )}
          
          {error && (
            <motion.div 
              className="mt-4 p-3 bg-red-100 dark:bg-red-900 dark:bg-opacity-20 text-red-700 dark:text-red-300 rounded-lg"
              initial={{ opacity: 0, y: 10 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ duration: 0.3 }}
            >
              <p className="flex items-start text-sm">
                <svg className="w-5 h-5 mr-2 mt-0.5 flex-shrink-0" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 8v4m0 4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
                </svg>
                <span>{error}</span>
              </p>
            </motion.div>
          )}
        </div>
        
        <h2 className="text-xl font-semibold mb-4">Cosa vuoi fare con il PDF?</h2>
        
        <div className="feature-grid">
          {conversionTypes.map((type) => (
            <motion.div
              key={type.id}
              className={`feature-card cursor-pointer p-4 rounded-lg border-2 ${
                conversionType === type.id 
                  ? "border-red-500 bg-red-50 dark:bg-red-900 dark:bg-opacity-10" 
                  : "border-gray-200 dark:border-gray-700 hover:border-red-300 dark:hover:border-red-700"
              }`}
              onClick={() => handleTypeChange(type.id)}
              whileHover={{ scale: 1.02 }}
              whileTap={{ scale: 0.98 }}
            >
              <div className="feature-card-content">
                <div>
                  <div className={`feature-card-icon rounded-full ${
                    conversionType === type.id 
                      ? "bg-red-500 text-white" 
                      : "bg-gray-100 dark:bg-gray-800 text-gray-600 dark:text-gray-400"
                  }`}>
                    {renderTypeIcon(type.icon)}
                  </div>
                  <h3 className="feature-card-title">{type.label}</h3>
                  <p className="feature-card-description">{type.description}</p>
                </div>
              </div>
            </motion.div>
          ))}
        </div>
      </motion.div>
      
      <div className="flex justify-end">
        <AdaptiveButton
          variant="primary"
          onClick={handleContinue}
          disabled={files.length === 0 || isAnalyzing}
          className="bg-red-500 hover:bg-red-600"
        >
          {isAnalyzing ? (
            <>
              <svg className="animate-spin -ml-1 mr-2 h-5 w-5 text-white" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24">
                <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4"></circle>
                <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
              </svg>
              Analisi...
            </>
          ) : (
            <>
              Continua
              <svg className="ml-2 w-5 h-5 inline" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 5l7 7-7 7" />
              </svg>
            </>
          )}
        </AdaptiveButton>
      </div>
    </div>
  );
};

export default PDFUploadStep;
