#!/bin/bash

# Fix PDFUploadStep.jsx to properly analyze PDF files and pass page count
echo "Fixing PDFUploadStep.jsx to properly analyze PDF files..."
cat > src/components/tools/pdf/PDFUploadStep.jsx << 'EOF'
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
EOF

# Fix PDFPreview.jsx to use fileInfo for page count
echo "Fixing PDFPreview.jsx to use fileInfo from data prop..."
cat > src/components/tools/pdf/PDFPreview.jsx << 'EOF'
// src/components/tools/pdf/PDFPreview.jsx
import PDFWebViewer from "./PDFWebViewer";
import { useState, useEffect, useRef } from 'react';
import { motion } from 'framer-motion';
import { useOS } from '../../../context/OSContext';

const PDFPreview = ({ files, options, isLoading }) => {
  const { osType, isMobile } = useOS();
  
  // Use PDFWebViewer for actual PDF rendering
  if (files && files.length > 0 && !isLoading) {
    return <PDFWebViewer file={files[0]} />;
  }
  
  const [preview, setPreview] = useState(null);
  const [currentPage, setCurrentPage] = useState(1);
  const [totalPages, setTotalPages] = useState(0);
  const [scale, setScale] = useState(1.0);
  const canvasRef = useRef(null);
  const [renderTask, setRenderTask] = useState(null);
  
  // PDF.js check
  useEffect(() => {
    if (!window.pdfjsLib) {
      console.error("PDF.js library not found. Make sure it's loaded in index.html");
    }
  }, []);
  
  // Load PDF preview when file changes
  useEffect(() => {
    if (!files || files.length === 0 || !window.pdfjsLib) return;
    
    // Clear previous preview
    if (preview) {
      preview.destroy();
      setPreview(null);
    }
    
    const loadPdfPreview = async () => {
      try {
        // Use the first file for preview
        const file = files[0];
        
        // Read file as ArrayBuffer
        const arrayBuffer = await new Promise((resolve, reject) => {
          const reader = new FileReader();
          reader.onload = () => resolve(reader.result);
          reader.onerror = reject;
          reader.readAsArrayBuffer(file);
        });
        
        // Load PDF with PDF.js
        const loadingTask = window.pdfjsLib.getDocument({ data: arrayBuffer });
        const pdfDocument = await loadingTask.promise;
        
        setPreview(pdfDocument);
        setTotalPages(pdfDocument.numPages);
        setCurrentPage(1);
        
      } catch (error) {
        console.error('Error loading PDF preview:', error);
      }
    };
    
    loadPdfPreview();
    
    // Cleanup
    return () => {
      if (preview) {
        preview.destroy();
      }
      
      if (renderTask) {
        renderTask.cancel();
      }
    };
  }, [files]);
  
  // Render current page
  useEffect(() => {
    if (!preview || !canvasRef.current) return;
    
    const renderPage = async () => {
      try {
        // Cancel any existing render task
        if (renderTask) {
          renderTask.cancel();
          setRenderTask(null);
        }
        
        // Get the page
        const page = await preview.getPage(currentPage);
        
        // Calculate appropriate scale
        const canvas = canvasRef.current;
        const viewport = page.getViewport({ scale });
        
        // Set canvas dimensions
        canvas.height = viewport.height;
        canvas.width = viewport.width;
        
        // Clear canvas before rendering new content
        const ctx = canvas.getContext('2d');
        ctx.clearRect(0, 0, canvas.width, canvas.height);
        
        // Render the page
        const renderContext = {
          canvasContext: ctx,
          viewport: viewport
        };
        
        const task = page.render(renderContext);
        setRenderTask(task);
        
        await task.promise;
        setRenderTask(null);
      } catch (error) {
        if (error.name === 'RenderingCancelledException') {
          console.log('Rendering was cancelled');
        } else {
          console.error('Error rendering PDF page:', error);
        }
      }
    };
    
    renderPage();
    
    // Cleanup function
    return () => {
      if (renderTask) {
        renderTask.cancel();
        setRenderTask(null);
      }
    };
  }, [preview, currentPage, scale]);
  
  // Change page
  const changePage = (delta) => {
    const newPage = currentPage + delta;
    if (newPage >= 1 && newPage <= totalPages) {
      setCurrentPage(newPage);
    }
  };
  
  // Change zoom
  const changeZoom = (delta) => {
    const newScale = Math.max(0.5, Math.min(2.0, scale + delta));
    setScale(newScale);
  };
  
  // Get preview style
  const getPreviewStyle = () => {
    return {
      maxHeight: isMobile ? '300px' : '400px',
      overflow: 'auto',
      backgroundColor: '#f5f5f5',
      borderRadius: '6px',
      display: 'flex',
      justifyContent: 'center',
      alignItems: 'flex-start'
    };
  };
  
  // Animation variants
  const controlsVariants = {
    hidden: { opacity: 0, y: 10 },
    visible: { opacity: 1, y: 0, transition: { duration: 0.3 } }
  };
  
  // Render loading state
  if (isLoading) {
    return (
      <div className="flex flex-col items-center justify-center h-64 bg-gray-100 dark:bg-gray-800 rounded-lg">
        <div className="animate-spin rounded-full h-10 w-10 border-t-2 border-b-2 border-red-500 mb-4"></div>
        <p className="text-gray-600 dark:text-gray-400">Loading preview...</p>
      </div>
    );
  }
  
  // Render message if no files
  if (!files || files.length === 0) {
    return (
      <div className="flex flex-col items-center justify-center h-64 bg-gray-100 dark:bg-gray-800 rounded-lg">
        <svg className="w-16 h-16 text-gray-400 mb-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z" />
        </svg>
        <p className="text-gray-600 dark:text-gray-400">Upload a PDF file to see preview</p>
      </div>
    );
  }
  
  // Render PDF
  return (
    <div>
      <div className="flex justify-center mb-3">
        <motion.div
          className="inline-flex items-center bg-gray-100 dark:bg-gray-800 rounded-full px-3 py-1"
          variants={controlsVariants}
          initial="hidden"
          animate="visible"
        >
          <button
            className="p-1 focus:outline-none disabled:opacity-50"
            onClick={() => changeZoom(-0.1)}
            disabled={scale <= 0.5}
          >
            <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M15 12H9" />
            </svg>
          </button>
          
          <span className="mx-2 text-sm">{Math.round(scale * 100)}%</span>
          
          <button
            className="p-1 focus:outline-none disabled:opacity-50"
            onClick={() => changeZoom(0.1)}
            disabled={scale >= 2.0}
          >
            <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 6v6m0 0v6m0-6h6m-6 0H6" />
            </svg>
          </button>
        </motion.div>
      </div>
      
      <div style={getPreviewStyle()}>
        <canvas ref={canvasRef} className="shadow-md"></canvas>
      </div>
      
      <motion.div
        className="flex justify-center items-center mt-3"
        variants={controlsVariants}
        initial="hidden"
        animate="visible"
      >
        <button
          className="p-1 rounded-full hover:bg-gray-200 dark:hover:bg-gray-700 focus:outline-none disabled:opacity-50"
          onClick={() => changePage(-1)}
          disabled={currentPage <= 1}
        >
          <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M15 19l-7-7 7-7" />
          </svg>
        </button>
        
        <span className="mx-3 text-sm">
          Page {currentPage} of {totalPages || "?"}
        </span>
        
        <button
          className="p-1 rounded-full hover:bg-gray-200 dark:hover:bg-gray-700 focus:outline-none disabled:opacity-50"
          onClick={() => changePage(1)}
          disabled={currentPage >= totalPages}
        >
          <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 5l7 7-7 7" />
          </svg>
        </button>
      </motion.div>
    </div>
  );
};

export default PDFPreview;
EOF

# Fix the wizard flow to ensure processing happens after configuration
echo "Fixing the wizard flow in ToolWizard.jsx..."
cat > src/components/wizard/ToolWizard.jsx << 'EOF'
// src/components/wizard/ToolWizard.jsx
import { useState, useEffect } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import StepIndicator from '../ui/StepIndicator';
import { useOS } from '../../context/OSContext';

const ToolWizard = ({ title, description, steps, toolId, themeColor }) => {
  const [currentStep, setCurrentStep] = useState(0);
  const [wizardData, setWizardData] = useState({});
  const [result, setResult] = useState(null);
  const { osType, isMobile } = useOS();
  
  // Reset wizard when tool changes
  useEffect(() => {
    setCurrentStep(0);
    setWizardData({});
    setResult(null);
  }, [toolId]);
  
  // Navigate between steps
  const goToNextStep = () => {
    if (currentStep < steps.length - 1) {
      setCurrentStep(currentStep + 1);
      window.scrollTo({ top: 0, behavior: 'smooth' });
    }
  };
  
  const goToPreviousStep = () => {
    if (currentStep > 0) {
      setCurrentStep(currentStep - 1);
      window.scrollTo({ top: 0, behavior: 'smooth' });
    }
  };
  
  // Update wizard data
  const updateWizardData = (newData) => {
    setWizardData(prevData => ({
      ...prevData,
      ...newData
    }));
  };
  
  // Set final result
  const setProcessResult = (processedResult) => {
    setResult(processedResult);
  };
  
  // Get step names for the indicator
  const stepNames = steps.map(step => step.title);
  
  // Animation based on operating system
  const getAnimationVariants = () => {
    // More fluid animations for iOS and macOS, more functional for other OS
    if (osType === 'ios' || osType === 'macos') {
      return {
        initial: { opacity: 0, x: 20, scale: 0.95 },
        animate: { opacity: 1, x: 0, scale: 1 },
exit: { opacity: 0, x: -20, scale: 0.95 },
        transition: { type: "spring", stiffness: 300, damping: 30 }
      };
    } else {
      return {
        initial: { opacity: 0, y: 10 },
        animate: { opacity: 1, y: 0 },
        exit: { opacity: 0, y: -10 },
        transition: { duration: 0.3 }
      };
    }
  };
  
  const animationVariants = getAnimationVariants();
  
  // Handle wizard completion (force next step to work)
  const forceComplete = () => {
    if (currentStep === steps.length - 2) { // If on the second-to-last step
      setCurrentStep(steps.length - 1); // Force to last step
      window.scrollTo({ top: 0, behavior: 'smooth' });
    }
  };
  
  return (
    <div className="container mx-auto px-4 py-8">
      <div className="max-w-4xl mx-auto">
        <div className="text-center mb-8">
          <h1 className={`text-3xl font-bold mb-2 ${isMobile ? 'text-2xl' : ''}`} style={{ color: themeColor }}>
            {title}
          </h1>
          {description && (
            <p className="text-gray-600 dark:text-gray-400">
              {description}
            </p>
          )}
        </div>
        
        <StepIndicator steps={stepNames} currentStep={currentStep} />
        
        <AnimatePresence mode="wait">
          <motion.div
            key={currentStep}
            initial={animationVariants.initial}
            animate={animationVariants.animate}
            exit={animationVariants.exit}
            transition={animationVariants.transition}
          >
            {steps[currentStep].component({
              data: wizardData,
              updateData: updateWizardData,
              goNext: goToNextStep,
              goBack: goToPreviousStep,
              result: result,
              setResult: setProcessResult,
              toolId,
              themeColor,
              forceComplete
            })}
          </motion.div>
        </AnimatePresence>
      </div>
    </div>
  );
};

export default ToolWizard;
EOF

# Fix PDFConfigurationStep to use forceComplete to ensure progression
echo "Fixing PDFConfigurationStep to ensure progression to the result step..."
cat > src/components/tools/pdf/PDFConfigurationStep.jsx << 'EOF'
// Componente per configurare le opzioni di conversione PDF
import React, { useState, useEffect } from 'react';
import { motion } from 'framer-motion';
import AdaptiveButton from '../../ui/AdaptiveButton';
import AdaptiveInput from '../../ui/AdaptiveInput';
import AdaptiveSelect from '../../ui/AdaptiveSelect';
import AdaptiveSwitch from '../../ui/AdaptiveSwitch';
import PDFPreview from './PDFPreview';
import { useOS } from '../../../context/OSContext';

const PDFConfigurationStep = ({ data, updateData, goNext, goBack, themeColor, conversionType, forceComplete }) => {
  const { osType, isMobile } = useOS();
  const [isGeneratingPreview, setIsGeneratingPreview] = useState(false);
  const [options, setOptions] = useState({
    // Opzioni di conversione
    targetFormat: 'docx',
    quality: 'high',
    dpi: 150,
    pageRange: 'all',
    customPages: '1-5',
    preserveLinks: true,
    preserveFormatting: true,
    
    // Opzioni di protezione
    password: '',
    permissions: {
      printing: true,
      copying: true,
      modifying: false
    },
    
    // Altre opzioni
    operation: data.conversionType || 'convert'
  });
  
  // Inizializza le opzioni dai dati esistenti
  useEffect(() => {
    if (data.options) {
      setOptions(prevOptions => ({
        ...prevOptions,
        ...data.options
      }));
    }
    
    if (data.conversionType) {
      setOptions(prevOptions => ({
        ...prevOptions,
        operation: data.conversionType
      }));
    }
  }, [data]);
  
  // Formati disponibili per la conversione
  const availableFormats = [
    { value: 'docx', label: 'Word (DOCX)' },
    { value: 'jpg', label: 'Immagine (JPG)' },
    { value: 'png', label: 'Immagine (PNG)' },
    { value: 'txt', label: 'Testo semplice (TXT)' },
    { value: 'html', label: 'HTML' }
  ];
  
  // Opzioni di qualità
  const qualityOptions = [
    { value: 'low', label: 'Bassa (file più piccolo)' },
    { value: 'medium', label: 'Media' },
    { value: 'high', label: 'Alta (migliore qualità)' }
  ];
  
  // Gestione dei cambiamenti delle opzioni
  const handleOptionChange = (option, value) => {
    setOptions(prevOptions => ({
      ...prevOptions,
      [option]: value
    }));
  };
  
  // Gestione dei cambiamenti dei permessi
  const handlePermissionChange = (permission) => {
    setOptions(prevOptions => ({
      ...prevOptions,
      permissions: {
        ...prevOptions.permissions,
        [permission]: !prevOptions.permissions[permission]
      }
    }));
  };
  
  // Continua alla prossima fase
  const handleContinue = () => {
    // Validazione
    if (options.operation === 'protect' && !options.password) {
      alert('Inserisci una password per proteggere il PDF');
      return;
    }
    
    updateData({ options: {...options, operation: options.operation || data.conversionType} });
    
    // Use forceComplete to ensure progression to the result step
    if (typeof forceComplete === 'function') {
      forceComplete();
    } else {
      goNext();
    }
  };
  
  // Renderizza le opzioni di conversione
  const renderConversionOptions = () => (
    <div className="space-y-4">
      <div>
        <AdaptiveSelect
          label="Formato di destinazione"
          value={options.targetFormat}
          onChange={(e) => handleOptionChange('targetFormat', e.target.value)}
          options={availableFormats}
          fullWidth
        />
      </div>
      
      {(options.targetFormat === 'jpg' || options.targetFormat === 'png') && (
        <div>
          <AdaptiveInput
            type="number"
            label="DPI (Qualità Immagine)"
            value={options.dpi}
            onChange={(e) => handleOptionChange('dpi', parseInt(e.target.value))}
            min="72"
            max="600"
            fullWidth
          />
          <div className="mt-1 text-xs text-gray-500">
            Valori più alti = immagini più grandi e di migliore qualità
          </div>
        </div>
      )}
      
      <div>
        <AdaptiveSelect
          label="Qualità"
          value={options.quality}
          onChange={(e) => handleOptionChange('quality', e.target.value)}
          options={qualityOptions}
          fullWidth
        />
      </div>
      
      <div>
        <p className="text-sm font-medium mb-2">Intervallo pagine</p>
        <div className="space-y-2">
          <div className="flex items-center space-x-2">
            <input
              type="radio"
              id="all-pages"
              checked={options.pageRange === 'all'}
              onChange={() => handleOptionChange('pageRange', 'all')}
            />
            <label htmlFor="all-pages">Tutte le pagine</label>
          </div>
          
          <div className="flex items-center space-x-2">
            <input
              type="radio"
              id="custom-pages"
              checked={options.pageRange === 'custom'}
              onChange={() => handleOptionChange('pageRange', 'custom')}
            />
            <label htmlFor="custom-pages">Pagine personalizzate</label>
          </div>
          
          {options.pageRange === 'custom' && (
            <div className="pl-6 mt-2">
              <AdaptiveInput
                type="text"
                value={options.customPages}
                onChange={(e) => handleOptionChange('customPages', e.target.value)}
                placeholder="es. 1-5, 8, 11-13"
                fullWidth
              />
              <p className="text-xs text-gray-500 mt-1">
                Usa virgole per separare le pagine e trattini per gli intervalli
              </p>
            </div>
          )}
        </div>
      </div>
      
      {(options.targetFormat === 'docx' || options.targetFormat === 'html') && (
        <div>
          <p className="text-sm font-medium mb-2">Opzioni aggiuntive</p>
          <div className="space-y-3">
            <AdaptiveSwitch
              label="Mantieni link"
              checked={options.preserveLinks}
              onChange={() => handleOptionChange('preserveLinks', !options.preserveLinks)}
            />
            
            <AdaptiveSwitch
              label="Mantieni formattazione"
              checked={options.preserveFormatting}
              onChange={() => handleOptionChange('preserveFormatting', !options.preserveFormatting)}
            />
          </div>
        </div>
      )}
    </div>
  );
  
  // Renderizza le opzioni di compressione
  const renderCompressionOptions = () => (
    <div className="space-y-4">
      <div>
        <AdaptiveSelect
          label="Livello di compressione"
          value={options.quality}
          onChange={(e) => handleOptionChange('quality', e.target.value)}
          options={[
            { value: 'high', label: 'Lieve - Qualità ottimale' },
            { value: 'medium', label: 'Media - Buon equilibrio' },
            { value: 'low', label: 'Massima - File più piccolo' }
          ]}
          fullWidth
        />
        <div className="mt-1 text-xs text-gray-500">
          Una compressione maggiore può ridurre la qualità delle immagini e del testo.
        </div>
      </div>
    </div>
  );
  
  // Renderizza le opzioni di protezione
  const renderProtectionOptions = () => (
    <div className="space-y-4">
      <div>
        <AdaptiveInput
          type="password"
          label="Password di protezione"
          value={options.password}
          onChange={(e) => handleOptionChange('password', e.target.value)}
          placeholder="Inserisci una password sicura"
          fullWidth
        />
        <div className="mt-1 text-xs text-gray-500">
          La password proteggerà il tuo PDF dall'apertura non autorizzata.
        </div>
      </div>
      
      <div>
        <p className="text-sm font-medium mb-2">Permessi</p>
        <div className="space-y-3 pl-1">
          <AdaptiveSwitch
            label="Consenti stampa"
            checked={options.permissions.printing}
            onChange={() => handlePermissionChange('printing')}
          />
          
          <AdaptiveSwitch
            label="Consenti copia di testo e immagini"
            checked={options.permissions.copying}
            onChange={() => handlePermissionChange('copying')}
          />
          
          <AdaptiveSwitch
            label="Consenti modifiche al documento"
            checked={options.permissions.modifying}
            onChange={() => handlePermissionChange('modifying')}
          />
        </div>
      </div>
      
      <div className="p-3 bg-yellow-50 dark:bg-yellow-900 dark:bg-opacity-20 text-yellow-800 dark:text-yellow-300 rounded-md">
        <p className="text-sm flex items-start">
          <svg className="w-5 h-5 mr-2 mt-0.5 flex-shrink-0" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M13 16h-1v-4h-1m1-4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
          </svg>
          <span>Importante: assicurati di ricordare questa password. Se la dimentichi, non potrai più accedere al documento protetto.</span>
        </p>
      </div>
    </div>
  );
  
  // Renderizza le opzioni di divisione
  const renderSplitOptions = () => (
    <div className="space-y-4">
      <div>
        <p className="text-sm font-medium mb-2">Modalità di divisione</p>
        <div className="space-y-2">
          <div className="flex items-center space-x-2">
            <input
              type="radio"
              id="split-all"
              checked={options.pageRange === 'all'}
              onChange={() => handleOptionChange('pageRange', 'all')}
            />
            <label htmlFor="split-all">Una pagina per file</label>
          </div>
          
          <div className="flex items-center space-x-2">
            <input
              type="radio"
              id="split-custom"
              checked={options.pageRange === 'custom'}
              onChange={() => handleOptionChange('pageRange', 'custom')}
            />
            <label htmlFor="split-custom">Intervalli personalizzati</label>
          </div>
          
          {options.pageRange === 'custom' && (
            <div className="pl-6 mt-2">
              <AdaptiveInput
                type="text"
                value={options.customPages}
                onChange={(e) => handleOptionChange('customPages', e.target.value)}
                placeholder="es. 1-5, 6-10, 11-15"
                fullWidth
              />
              <p className="text-xs text-gray-500 mt-1">
                Ogni intervallo diventerà un file PDF separato. Esempio: "1-5, 6-10" creerà 2 file PDF.
              </p>
            </div>
          )}
        </div>
      </div>
    </div>
  );
  
  // Renderizza le opzioni di unione
  const renderMergeOptions = () => (
    <div className="space-y-4">
      <div className="p-3 bg-blue-50 dark:bg-blue-900 dark:bg-opacity-20 text-blue-800 dark:text-blue-300 rounded-md">
        <p className="text-sm flex items-start">
          <svg className="w-5 h-5 mr-2 mt-0.5 flex-shrink-0" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M13 16h-1v-4h-1m1-4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
          </svg>
          <span>I file PDF verranno uniti nell'ordine in cui sono stati caricati. Puoi tornare indietro per modificare o riordinare i file.</span>
        </p>
      </div>
    </div>
  );
  
  // Determina le opzioni da mostrare in base al tipo di operazione
  const renderOptionsBasedOnOperation = () => {
    const operation = options.operation || data.conversionType || 'convert';
    
    switch (operation) {
      case 'convert':
        return renderConversionOptions();
      case 'compress':
        return renderCompressionOptions();
      case 'protect':
        return renderProtectionOptions();
      case 'split':
        return renderSplitOptions();
      case 'merge':
        return renderMergeOptions();
      default:
        return renderConversionOptions();
    }
  };
  
  // Ottieni il titolo appropriato per il tipo di operazione
  const getOperationTitle = () => {
    const operation = options.operation || data.conversionType || 'convert';
    
    switch (operation) {
      case 'convert':
        return 'Opzioni di conversione';
      case 'compress':
        return 'Opzioni di compressione';
      case 'protect':
        return 'Impostazioni di protezione';
      case 'split':
        return 'Opzioni di divisione';
      case 'merge':
        return 'Opzioni di unione';
      default:
        return 'Opzioni';
    }
  };
  
  // Effetto di apertura per il contenitore
  const containerVariants = {
    hidden: { opacity: 0, y: 20 },
    visible: { 
      opacity: 1, 
      y: 0,
      transition: { 
        duration: 0.4,
        when: "beforeChildren",
        staggerChildren: 0.1
      }
    }
  };
  
  // Effetto per gli elementi interni
  const itemVariants = {
    hidden: { opacity: 0, y: 10 },
    visible: { opacity: 1, y: 0 }
  };
  
  return (
    <div className="step-container">
      <motion.div
        variants={containerVariants}
        initial="hidden"
        animate="visible"
      >
        <motion.h2 
          className="text-xl font-semibold mb-4"
          variants={itemVariants}
        >
          {getOperationTitle()}
        </motion.h2>
        
        <div className={`flex ${isMobile ? 'flex-col' : 'flex-row'} gap-6`}>
          <motion.div 
            className={isMobile ? 'w-full' : 'w-2/5'}
            variants={itemVariants}
          >
            <div className="glass-card p-5 h-full">
              {renderOptionsBasedOnOperation()}
            </div>
          </motion.div>
          
          <motion.div 
            className={isMobile ? 'w-full' : 'w-3/5'}
            variants={itemVariants}
          >
            <div className="glass-card p-5 h-full">
              <h3 className="text-lg font-medium mb-3">Anteprima</h3>
              
              <PDFPreview 
                files={data.files}
                options={options}
                isLoading={isGeneratingPreview}
              />
              
              <div className="mt-4 p-3 bg-gray-50 dark:bg-gray-800 rounded-md">
                <h4 className="font-medium text-sm mb-1">Riepilogo</h4>
                <ul className="text-sm text-gray-600 dark:text-gray-400 space-y-1">
                  {options.operation === 'convert' || (!options.operation && data.conversionType === 'convert') && (
                    <>
                      <li>• Conversione da PDF a {options.targetFormat.toUpperCase()}</li>
                      <li>• Qualità: {options.quality}</li>
                      {(options.targetFormat === 'jpg' || options.targetFormat === 'png') && (
                        <li>• DPI: {options.dpi}</li>
                      )}
                      <li>• Pagine: {options.pageRange === 'all' ? 'Tutte' : options.customPages}</li>
                    </>
                  )}
                  
                  {options.operation === 'compress' || (!options.operation && data.conversionType === 'compress') && (
                    <>
                      <li>• Compressione PDF</li>
                      <li>• Livello: {options.quality === 'low' ? 'Massimo' : options.quality === 'medium' ? 'Medio' : 'Lieve'}</li>
                      <li>• La dimensione finale dipenderà dal contenuto del PDF</li>
                    </>
                  )}
                  
                  {options.operation === 'protect' || (!options.operation && data.conversionType === 'protect') && (
                    <>
                      <li>• Protezione con password</li>
                      <li>• Stampa: {options.permissions.printing ? 'Consentita' : 'Non consentita'}</li>
                      <li>• Copia: {options.permissions.copying ? 'Consentita' : 'Non consentita'}</li>
                      <li>• Modifica: {options.permissions.modifying ? 'Consentita' : 'Non consentita'}</li>
                    </>
                  )}
                  
                  {options.operation === 'split' || (!options.operation && data.conversionType === 'split') && (
                    <>
                      <li>• Divisione PDF</li>
                      <li>• Modalità: {options.pageRange === 'all' ? 'Una pagina per file' : 'Intervalli personalizzati'}</li>
                      {options.pageRange === 'custom' && (
                        <li>• Intervalli: {options.customPages}</li>
                      )}
                    </>
                  )}
                  
                  {options.operation === 'merge' || (!options.operation && data.conversionType === 'merge') && (
                    <>
                      <li>• Unione PDF</li>
                      <li>• File da unire: {data.files ? data.files.length : 0}</li>
                    </>
                  )}
                </ul>
              </div>
            </div>
          </motion.div>
        </div>
        
        <motion.div 
          className="flex justify-between mt-6"
          variants={itemVariants}
        >
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
            className="bg-red-500 hover:bg-red-600"
          >
            Elabora PDF
            <svg className="ml-2 w-5 h-5 inline" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 5l7 7-7 7" />
            </svg>
          </AdaptiveButton>
        </motion.div>
      </motion.div>
    </div>
  );
};

export default PDFConfigurationStep;
EOF

# Fix PDFWebViewer.jsx to use correct page count information
echo "Fixing PDFWebViewer.jsx to use correct page count..."
cat > src/components/tools/pdf/PDFWebViewer.jsx << 'EOF'
// src/components/tools/pdf/PDFWebViewer.jsx
import { useState, useEffect, useRef } from 'react';

const PDFWebViewer = ({ file, pageNumber = 1, scale = 1.0 }) => {
  const canvasRef = useRef(null);
  const [numPages, setNumPages] = useState(0);
  const [currentPage, setCurrentPage] = useState(pageNumber);
  const [pdfDoc, setPdfDoc] = useState(null);
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState(null);
  const [renderTask, setRenderTask] = useState(null);

  // Load PDF
  useEffect(() => {
    if (!file || !(file instanceof File || file instanceof Blob)) return;
    
    const loadPDF = async () => {
      setIsLoading(true);
      try {
        // Check if PDF.js is available
        if (!window.pdfjsLib) {
          throw new Error("PDF.js library not found");
        }
        
        // Read file
        const fileReader = new FileReader();
        
        fileReader.onload = async (event) => {
          try {
            // Clean up previous PDF document
            if (pdfDoc) {
              pdfDoc.destroy();
            }
            
            // Load PDF document
            const loadingTask = window.pdfjsLib.getDocument({
              data: new Uint8Array(event.target.result)
            });
            
            const pdf = await loadingTask.promise;
            
            // Set document and update page count
            setPdfDoc(pdf);
            setNumPages(pdf.numPages);
            setCurrentPage(1);
            setIsLoading(false);
          } catch (err) {
            console.error("Failed to load PDF document:", err);
            setError("Unable to load PDF document: " + err.message);
            setIsLoading(false);
          }
        };
        
        fileReader.onerror = (err) => {
          console.error("FileReader error:", err);
          setError("Error reading file");
          setIsLoading(false);
        };
        
        fileReader.readAsArrayBuffer(file);
      } catch (err) {
        console.error("PDF loading error:", err);
        setError("Error loading PDF: " + err.message);
        setIsLoading(false);
      }
    };
    
    loadPDF();
    
    // Cleanup
    return () => {
      // Cancel any pending render task
      if (renderTask) {
        renderTask.cancel();
      }
      
      // Cleanup PDF document
      if (pdfDoc) {
        pdfDoc.destroy();
      }
    };
  }, [file]);

  // Render page
  useEffect(() => {
    if (!pdfDoc || !canvasRef.current) return;
    
    const renderPage = async () => {
      try {
        // Cancel any existing render task
        if (renderTask) {
          renderTask.cancel();
          setRenderTask(null);
        }
        
        const page = await pdfDoc.getPage(currentPage);
        const viewport = page.getViewport({ scale });
        
        const canvas = canvasRef.current;
        const context = canvas.getContext('2d');
        
        canvas.height = viewport.height;
        canvas.width = viewport.width;
        
        // Clear canvas before rendering
        context.clearRect(0, 0, canvas.width, canvas.height);
        
        const renderContext = {
          canvasContext: context,
          viewport: viewport
        };
        
        const task = page.render(renderContext);
        setRenderTask(task);
        
        await task.promise;
        setRenderTask(null);
      } catch (err) {
        if (err.name === 'RenderingCancelledException') {
          console.log('Rendering was cancelled');
        } else {
          console.error("Error rendering page:", err);
          setError("Error rendering page");
        }
      }
    };
    
    renderPage();
    
    // Cleanup function
    return () => {
      if (renderTask) {
        renderTask.cancel();
        setRenderTask(null);
      }
    };
  }, [pdfDoc, currentPage, scale]);

  // Change page
  const changePage = (offset) => {
    const newPage = currentPage + offset;
    if (newPage >= 1 && newPage <= numPages) {
      setCurrentPage(newPage);
    }
  };

  // Render loading state
  if (isLoading) {
    return (
      <div className="flex items-center justify-center h-64 bg-gray-100 dark:bg-gray-800 rounded-lg">
        <div className="animate-spin rounded-full h-10 w-10 border-t-2 border-b-2 border-red-500 mb-4"></div>
        <p className="text-gray-600 dark:text-gray-400 ml-3">Loading document...</p>
      </div>
    );
  }

  // Render error state
  if (error) {
    return (
      <div className="flex flex-col items-center justify-center h-64 bg-red-50 dark:bg-red-900 dark:bg-opacity-20 text-red-700 dark:text-red-300 rounded-lg p-4">
        <svg className="w-12 h-12 mb-3" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 8v4m0 4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
        </svg>
        <p className="text-center">{error}</p>
      </div>
    );
  }

  return (
    <div className="pdf-web-viewer">
      <div className="flex justify-center mb-3">
        <div className="inline-flex items-center bg-gray-100 dark:bg-gray-800 rounded-full px-3 py-1">
          <button
            className="p-1 focus:outline-none disabled:opacity-50"
            onClick={() => changePage(-1)}
            disabled={currentPage <= 1}
          >
            <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M15 19l-7-7 7-7" />
            </svg>
          </button>
          
          <span className="mx-2 text-sm">
            Page {currentPage} of {numPages}
          </span>
          
          <button
            className="p-1 focus:outline-none disabled:opacity-50"
            onClick={() => changePage(1)}
            disabled={currentPage >= numPages}
          >
            <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 5l7 7-7 7" />
            </svg>
          </button>
        </div>
      </div>
      
      <div className="bg-white dark:bg-gray-800 rounded-lg overflow-auto max-h-96 flex justify-center">
        <canvas ref={canvasRef} className="shadow-md" />
      </div>
    </div>
  );
};

export default PDFWebViewer;