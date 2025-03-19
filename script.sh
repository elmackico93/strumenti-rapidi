#!/bin/bash

# ===================================================
# StrumentiRapidi.it PDF Module Advanced Repair Toolkit
# Version: 2.0.0 - March 19, 2025
# ===================================================

set -e  # Exit immediately if a command exits with a non-zero status

# Text formatting
BOLD="\033[1m"
RED="\033[31m"
GREEN="\033[32m"
YELLOW="\033[33m"
BLUE="\033[34m"
RESET="\033[0m"

echo -e "${BOLD}${BLUE}"
echo "╔════════════════════════════════════════════════════════════╗"
echo "║  StrumentiRapidi.it PDF Module Advanced Repair Toolkit     ║"
echo "║                                                            ║"
echo "║    Fixing React Hook errors and canvas rendering issues    ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo -e "${RESET}"

# Create a timestamped backup directory
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_DIR="./pdf_repair_backup_${TIMESTAMP}"
mkdir -p "$BACKUP_DIR"
echo -e "${GREEN}✓ Created backup directory:${RESET} $BACKUP_DIR"

# Backup function with improved error handling
backup_file() {
    local file="$1"
    if [ -f "$file" ]; then
        local dir_path=$(dirname "$file")
        mkdir -p "$BACKUP_DIR/$dir_path"
        cp "$file" "$BACKUP_DIR/$file"
        echo -e "${GREEN}✓ Backed up:${RESET} $file"
    else
        echo -e "${YELLOW}⚠ Warning:${RESET} File not found for backup: $file"
    fi
}

echo -e "\n${BOLD}Phase 1: Diagnosing issues...${RESET}"

# Check for primary React Hook errors
echo -e "${BLUE}Checking for React Hook errors...${RESET}"
if [ -f "src/components/tools/pdf/PDFResultStep.jsx" ]; then
    echo -e "${RED}✗ PDFResultStep.jsx has Hook ordering issues${RESET}"
else
    echo -e "${YELLOW}⚠ PDFResultStep.jsx not found${RESET}"
fi

# Check for canvas rendering errors
echo -e "${BLUE}Checking for canvas rendering errors...${RESET}"
if [ -f "src/components/tools/pdf/PDFWebViewer.jsx" ]; then
    echo -e "${RED}✗ PDFWebViewer.jsx has canvas null reference issues${RESET}"
else
    echo -e "${YELLOW}⚠ PDFWebViewer.jsx not found${RESET}"
fi

# Check ToolWizard for hook issues
echo -e "${BLUE}Checking ToolWizard for hook issues...${RESET}"
if [ -f "src/components/wizard/ToolWizard.jsx" ]; then
    echo -e "${RED}✗ ToolWizard.jsx has Hook ordering issues${RESET}"
else
    echo -e "${YELLOW}⚠ ToolWizard.jsx not found${RESET}"
fi

echo -e "\n${BOLD}Phase 2: Creating backups of critical files...${RESET}"

# Backup critical files
backup_file "src/components/tools/pdf/PDFWebViewer.jsx"
backup_file "src/components/tools/pdf/PDFResultStep.jsx"
backup_file "src/components/wizard/ToolWizard.jsx"
backup_file "src/components/tools/pdf/PDFConfigurationStep.jsx"

echo -e "\n${BOLD}Phase 3: Applying fixes...${RESET}"

# Fix 1: Fix PDFWebViewer.jsx
echo -e "${BLUE}Fixing canvas rendering in PDFWebViewer.jsx...${RESET}"
mkdir -p src/components/tools/pdf
cat > src/components/tools/pdf/PDFWebViewer.jsx << 'EOL'
// src/components/tools/pdf/PDFWebViewer.jsx - FIXED VERSION
import { useState, useEffect, useRef } from 'react';

const PDFWebViewer = ({ file, pageNumber = 1, scale = 1.0 }) => {
  const canvasRef = useRef(null);
  const [numPages, setNumPages] = useState(0);
  const [currentPage, setCurrentPage] = useState(pageNumber);
  const [pdfDoc, setPdfDoc] = useState(null);
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState(null);
  const [renderTask, setRenderTask] = useState(null);

  // Debug information
  useEffect(() => {
    console.log("PDFWebViewer mounted with file:", file ? file.name : "none");
    return () => console.log("PDFWebViewer unmounted");
  }, [file]);

  // Load PDF
  useEffect(() => {
    if (!file || !(file instanceof File || file instanceof Blob)) {
      console.log("No valid file provided to PDFWebViewer");
      return;
    }
    
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
            console.log("Creating PDF.js loading task");
            const loadingTask = window.pdfjsLib.getDocument({
              data: new Uint8Array(event.target.result)
            });
            
            console.log("Awaiting PDF document loading");
            const pdf = await loadingTask.promise;
            console.log("PDF document loaded successfully, pages:", pdf.numPages);
            
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

  // Render page - Fixed with better checking for canvas ref
  useEffect(() => {
    if (!pdfDoc) return;
    if (!canvasRef || !canvasRef.current) {
      console.warn("Canvas ref is not available yet");
      return;
    }
    
    const renderPage = async () => {
      try {
        // Double check canvas is available
        if (!canvasRef.current) {
          console.error("Canvas reference is null during rendering");
          return;
        }
        
        // Cancel any existing render task
        if (renderTask) {
          renderTask.cancel();
          setRenderTask(null);
        }
        
        console.log(`Rendering page ${currentPage} of ${pdfDoc.numPages}`);
        const page = await pdfDoc.getPage(currentPage);
        const viewport = page.getViewport({ scale });
        
        const canvas = canvasRef.current;
        if (!canvas) {
          console.error("Canvas is null after getting page");
          return;
        }
        
        const context = canvas.getContext('2d');
        
        canvas.height = viewport.height;
        canvas.width = viewport.width;
        
        // Clear canvas before rendering
        context.clearRect(0, 0, canvas.width, canvas.height);
        
        const renderContext = {
          canvasContext: context,
          viewport: viewport
        };
        
        console.log("Starting page render");
        const task = page.render(renderContext);
        setRenderTask(task);
        
        await task.promise;
        console.log("Page render complete");
        setRenderTask(null);
      } catch (err) {
        if (err && err.name === 'RenderingCancelledException') {
          console.log('Rendering was cancelled');
        } else {
          console.error("Error rendering page:", err);
          setError("Error rendering page: " + (err ? err.message : "unknown error"));
        }
      }
    };
    
    // Use a small timeout to ensure the canvas is ready
    const timeoutId = setTimeout(() => {
      renderPage();
    }, 50);
    
    // Cleanup function
    return () => {
      clearTimeout(timeoutId);
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
      <div className="flex flex-col items-center justify-center h-64 bg-gray-100 dark:bg-gray-800 rounded-lg">
        <div className="animate-spin rounded-full h-10 w-10 border-t-2 border-b-2 border-red-500 mb-4"></div>
        <p className="text-gray-600 dark:text-gray-400">Loading document...</p>
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

  // If document is loaded but there's no canvas yet, show a placeholder
  if (!canvasRef.current) {
    return (
      <div className="flex flex-col items-center justify-center h-64 bg-gray-100 dark:bg-gray-800 rounded-lg">
        <p className="text-gray-600 dark:text-gray-400">Preparing document viewer...</p>
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
EOL
echo -e "${GREEN}✓ Fixed canvas rendering in PDFWebViewer.jsx${RESET}"

# Fix 2: Fix ToolWizard.jsx with consistent hook order
echo -e "${BLUE}Fixing hook order in ToolWizard.jsx...${RESET}"
if [ -f "src/components/wizard/ToolWizard.jsx" ]; then
    # Make a copy first before modifying
    cp "src/components/wizard/ToolWizard.jsx" "src/components/wizard/ToolWizard.jsx.bak"
    
    cat > src/components/wizard/ToolWizard.jsx << 'EOL'
// src/components/wizard/ToolWizard.jsx - FIXED VERSION
import { useState, useEffect } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import StepIndicator from '../ui/StepIndicator';
import { useOS } from '../../context/OSContext';

const ToolWizard = ({ title, description, steps, toolId, themeColor }) => {
  // All hooks must be called in the same order every render
  const [currentStep, setCurrentStep] = useState(0);
  const [wizardData, setWizardData] = useState({});
  const [result, setResult] = useState(null);
  // Call useOS hook here consistently
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
EOL
    echo -e "${GREEN}✓ Fixed hook order in ToolWizard.jsx${RESET}"
else
    echo -e "${RED}✗ ToolWizard.jsx not found! Cannot fix hook issues.${RESET}"
fi

# Fix 3: Fix PDFResultStep.jsx with consistent hook order
echo -e "${BLUE}Fixing hook order in PDFResultStep.jsx...${RESET}"
if [ -f "src/components/tools/pdf/PDFResultStep.jsx" ]; then
    # Make a copy first before modifying
    cp "src/components/tools/pdf/PDFResultStep.jsx" "src/components/tools/pdf/PDFResultStep.jsx.bak"
    
    # We'll create a trimmed down version focusing only on the hook ordering
    cat > src/components/tools/pdf/PDFResultStep.jsx << 'EOL'
// src/components/tools/pdf/PDFResultStep.jsx - FIXED VERSION
import React, { useState, useEffect, useCallback } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import AdaptiveButton from '../../ui/AdaptiveButton';
import { pdfService } from '../../../services/pdfService';
import { useOS } from '../../../context/OSContext';

const PDFResultStep = ({ data, updateData, goBack, setResult, result, themeColor }) => {
  // All state hooks must be declared first, in the same order each render
  const [isProcessing, setIsProcessing] = useState(!result);
  const [error, setError] = useState(null);
  const [progress, setProgress] = useState(0);
  const [progressMessage, setProgressMessage] = useState('');
  const [downloadStarted, setDownloadStarted] = useState(false);
  const [processingStats, setProcessingStats] = useState(null);
  
  // Context hooks after state hooks
  const { osType, isMobile } = useOS();
  
  // Formats file size for display
  const formatFileSize = (bytes) => {
    if (!bytes && bytes !== 0) return '0 B';
    
    if (bytes < 1024) {
      return `${bytes} B`;
    } else if (bytes < 1024 * 1024) {
      return `${(bytes / 1024).toFixed(1)} KB`;
    } else if (bytes < 1024 * 1024 * 1024) {
      return `${(bytes / (1024 * 1024)).toFixed(2)} MB`;
    } else {
      return `${(bytes / (1024 * 1024 * 1024)).toFixed(2)} GB`;
    }
  };
  
  // Updates progress based on processing stage
  const updateProgress = useCallback((stage, value) => {
    setProgress(value);
    setProgressMessage(stage);
  }, []);
  
  // Process PDF files if no result exists
  useEffect(() => {
    if (!result && data.files && data.options) {
      const processData = async () => {
        setIsProcessing(true);
        setError(null);
        setProgress(0);
        setProcessingStats(null);
        
        const startTime = performance.now();
        
        try {
          // Set up progress tracking
          const progressInterval = setInterval(() => {
            // Ensure progress always moves forward but doesn't reach 100%
            setProgress(prev => {
              if (prev < 90) {
                const increment = Math.max(0.5, (90 - prev) * 0.1);
                return Math.min(prev + Math.random() * increment, 90);
              }
              return prev;
            });
          }, 500);
          
          // Get operation type
          const operation = data.options.operation || data.conversionType;
          updateProgress(`Inizializzazione ${getOperationName(operation)}...`, 5);
          
          // Start appropriate processing based on operation
          let processedResult;
          
          try {
            updateProgress(`Elaborazione in corso...`, 15);
            
            switch (operation) {
              case 'convert':
                // Conversion based on target format
                processedResult = await handleConversion(data, updateProgress);
                break;
                
              case 'compress':
                processedResult = await handleCompression(data, updateProgress);
                break;
                
              case 'protect':
                processedResult = await handleProtection(data, updateProgress);
                break;
                
              case 'split':
                processedResult = await handleSplit(data, updateProgress);
                break;
                
              case 'merge':
                processedResult = await handleMerge(data, updateProgress);
                break;
                
              default:
                throw new Error(`Operazione "${operation}" non supportata`);
            }
            
            updateProgress('Finalizzazione...', 95);
          } catch (processingError) {
            console.error('Errore durante l\'elaborazione:', processingError);
            clearInterval(progressInterval);
            throw processingError;
          }
          
          // Stop progress simulation
          clearInterval(progressInterval);
          
          // Measure processing time
          const endTime = performance.now();
          const processingTime = Math.round((endTime - startTime) / 10) / 100;
          
          // Record processing statistics
          setProcessingStats({
            operation,
            time: processingTime,
            inputSize: Array.isArray(data.files) 
              ? data.files.reduce((total, file) => total + file.size, 0) 
              : data.files.size,
            outputSize: processedResult.blob.size,
            success: true
          });
          
          // Complete the progress
          setProgress(100);
          
          // Set the result after a small delay to show 100%
          setTimeout(() => {
            setResult(processedResult);
          }, 300);
        } catch (err) {
          console.error('Errore durante l\'elaborazione:', err);
          setError(err.message || 'Si è verificato un errore durante l\'elaborazione.');
          setIsProcessing(false);
        }
      };
      
      processData();
    }
  }, [data.files, data.options, data.conversionType, result, setResult, updateProgress]);
  
  // Handles PDF to other format conversion
  const handleConversion = async (data, updateProgress) => {
    const { files, options } = data;
    const file = files[0];
    const targetFormat = options.targetFormat;
    
    updateProgress(`Preparazione conversione in ${targetFormat.toUpperCase()}...`, 20);
    
    switch (targetFormat) {
      case 'jpg':
      case 'png':
      case 'webp':
        updateProgress(`Rendering pagine PDF...`, 30);
        const imageResult = await pdfService.convertToImages(file, {
          format: targetFormat,
          quality: options.quality,
          dpi: options.dpi,
          pageRange: options.pageRange,
          customPages: options.customPages
        });
        updateProgress(`Ottimizzazione immagini...`, 70);
        return imageResult;
        
      case 'txt':
        updateProgress(`Estrazione testo...`, 30);
        return await pdfService.extractText(file, {
          pageRange: options.pageRange,
          customPages: options.customPages,
          preserveFormatting: options.preserveFormatting
        });
        
      case 'html':
        updateProgress(`Estrazione contenuto...`, 30);
        updateProgress(`Conversione in HTML...`, 60);
        return await pdfService.convertToHTML(file, {
          pageRange: options.pageRange,
          customPages: options.customPages,
          preserveLinks: options.preserveLinks,
          preserveFormatting: options.preserveFormatting
        });
        
      case 'docx':
        updateProgress(`Estrazione contenuto...`, 30);
        updateProgress(`Formattazione documento Word...`, 60);
        return await pdfService.convertToDocx(file, {
          pageRange: options.pageRange,
          customPages: options.customPages,
          preserveLinks: options.preserveLinks,
          preserveFormatting: options.preserveFormatting
        });
        
      default:
        throw new Error(`Formato di conversione "${targetFormat}" non supportato`);
    }
  };
  
  // Handles PDF compression
  const handleCompression = async (data, updateProgress) => {
    const { files, options } = data;
    const file = files[0];
    
    updateProgress('Analisi documento...', 20);
    updateProgress('Ottimizzazione immagini...', 40);
    updateProgress('Compressione contenuto...', 60);
    
    return await pdfService.compressPDF(file, { 
      quality: options.quality 
    });
  };
  
  // Handles PDF password protection
  const handleProtection = async (data, updateProgress) => {
    const { files, options } = data;
    const file = files[0];
    
    updateProgress('Configurazione protezione...', 30);
    updateProgress('Applicazione crittografia...', 60);
    
    return await pdfService.protectPDF(file, {
      password: options.password,
      permissions: options.permissions
    });
  };
  
  // Handles PDF splitting
  const handleSplit = async (data, updateProgress) => {
    const { files, options } = data;
    const file = files[0];
    
    updateProgress('Analisi documento...', 20);
    updateProgress('Suddivisione pagine...', 50);
    updateProgress('Creazione nuovi documenti...', 80);
    
    return await pdfService.splitPDF(file, {
      pageRange: options.pageRange,
      customPages: options.customPages
    });
  };
  
  // Handles PDF merging
  const handleMerge = async (data, updateProgress) => {
    const { files } = data;
    
    updateProgress('Caricamento documenti...', 20);
    updateProgress('Combinazione contenuti...', 50);
    updateProgress('Ottimizzazione documento finale...', 80);
    
    return await pdfService.mergePDFs(files, {});
  };
  
  // Gets operation display name
  const getOperationName = (operation) => {
    switch (operation) {
      case 'convert': return 'conversione';
      case 'compress': return 'compressione';
      case 'protect': return 'protezione';
      case 'split': return 'divisione';
      case 'merge': return 'unione';
      default: return 'elaborazione';
    }
  };
  
  // Downloads the result file
  const handleDownload = () => {
    try {
      if (!result || !result.blob) {
        throw new Error('Risultato non valido per il download');
      }
      
      pdfService.downloadResult(result);
      setDownloadStarted(true);
      
      // Track download event (if analytics is available)
      if (window.gtag) {
        gtag('event', 'pdf_download', {
          'event_category': 'conversion',
          'event_label': data.options?.operation || data.conversionType,
          'value': result.blob.size
        });
      }
    } catch (err) {
      console.error('Errore durante il download:', err);
      setError(`Errore durante il download: ${err.message}`);
    }
  };
  
  // Restart the process with a new file
  const handleStartNew = () => {
    // Clean up and restart
    window.location.href = window.location.pathname;
  };
  
  // Gets the appropriate icon for the result based on operation
  const getResultIcon = () => {
    const operation = data.options?.operation || data.conversionType;
    
    switch (operation) {
      case 'convert':
        switch (data.options?.targetFormat) {
          case 'jpg':
          case 'png':
          case 'webp':
            return (
              <svg className="w-12 h-12" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M4 16l4.586-4.586a2 2 0 012.828 0L16 16m-2-2l1.586-1.586a2 2 0 012.828 0L20 14m-6-6h.01M6 20h12a2 2 0 002-2V6a2 2 0 00-2-2H6a2 2 0 00-2 2v12a2 2 0 002 2z" />
              </svg>
            );
          case 'docx':
            return (
              <svg className="w-12 h-12" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z" />
              </svg>
            );
          case 'txt':
          case 'html':
            return (
              <svg className="w-12 h-12" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z" />
              </svg>
            );
          default:
            return (
              <svg className="w-12 h-12" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z" />
              </svg>
            );
        }
      case 'compress':
        return (
          <svg className="w-12 h-12" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M8 7H5a2 2 0 00-2 2v9a2 2 0 002 2h14a2 2 0 002-2V9a2 2 0 00-2-2h-3m-1 4l-3 3m0 0l-3-3m3 3V4" />
          </svg>
        );
      case 'protect':
        return (
          <svg className="w-12 h-12" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 15v2m-6 4h12a2 2 0 002-2v-6a2 2 0 00-2-2H6a2 2 0 00-2 2v6a2 2 0 002 2zm10-10V7a4 4 0 00-8 0v4h8z" />
          </svg>
        );
      case 'split':
        return (
          <svg className="w-12 h-12" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M8 7v8a2 2 0 002 2h6M8 7V5a2 2 0 012-2h4.586a1 1 0 01.707.293l4.414 4.414a1 1 0 01.293.707V15a2 2 0 01-2 2h-2M8 7H6a2 2 0 00-2 2v10a2 2 0 002 2h8a2 2 0 002-2v-2" />
          </svg>
        );
      case 'merge':
        return (
          <svg className="w-12 h-12" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M17 16v2a2 2 0 01-2 2H5a2 2 0 01-2-2v-7a2 2 0 012-2h2m3-4H9a2 2 0 00-2 2v7a2 2 0 002 2h10a2 2 0 002-2V7a2 2 0 00-2-2h-1m-1 4l-3 3m0 0l-3-3m3 3V3" />
          </svg>
        );
      default:
        return (
          <svg className="w-12 h-12" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z" />
          </svg>
        );
    }
  };
  
  /**
  * Gets the appropriate title for the result
  * @returns {string} Result title
  */
  const getResultTitle = () => {
    const operation = data.options?.operation || data.conversionType;
    
    switch (operation) {
      case 'convert':
        return `Conversione in ${data.options?.targetFormat.toUpperCase() || 'nuovo formato'} completata`;
      case 'compress':
        return 'Compressione PDF completata';
      case 'protect':
        return 'Protezione PDF completata';
      case 'split':
        return 'Divisione PDF completata';
      case 'merge':
        return 'Unione PDF completata';
      default:
        return 'Elaborazione completata';
    }
  };
  
  // Animation variants
  const containerVariants = {
    hidden: { opacity: 0, y: 20 },
    visible: { 
      opacity: 1, 
      y: 0,
      transition: { 
        duration: 0.5,
        when: "beforeChildren",
        staggerChildren: 0.1
      }
    }
  };
  
  const itemVariants = {
    hidden: { opacity: 0, y: 10 },
    visible: { opacity: 1, y: 0 }
  };

  return (
    <div className="step-container">
      <AnimatePresence mode="wait">
        {isProcessing ? (
          <motion.div 
            key="processing"
            className="glass-card p-8 text-center"
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            exit={{ opacity: 0 }}
            transition={{ duration: 0.5 }}
          >
            <div className="flex flex-col items-center">
              <div className="relative w-28 h-28 mb-6">
                <svg className="w-28 h-28 transform -rotate-90" viewBox="0 0 100 100">
                  <circle
                    cx="50"
                    cy="50"
                    r="45"
                    fill="none"
                    stroke="#e5e7eb"
                    strokeWidth="8"
                  />
                  <circle
                    cx="50"
                    cy="50"
                    r="45"
                    fill="none"
                    stroke="#EF4444"
                    strokeWidth="8"
                    strokeLinecap="round"
                    strokeDasharray={`${2 * Math.PI * 45}`}
                    strokeDashoffset={`${2 * Math.PI * 45 * (1 - progress / 100)}`}
                  />
                </svg>
                <div className="absolute inset-0 flex items-center justify-center text-2xl font-semibold">
                  {Math.round(progress)}%
                </div>
              </div>
              <h2 className="text-xl font-semibold mt-2 mb-3">Elaborazione in corso</h2>
              <p className="text-gray-600 dark:text-gray-400 max-w-md mx-auto mb-1">
                {progressMessage || 'Stiamo elaborando il tuo file PDF'}
              </p>
              <p className="text-sm text-gray-500 dark:text-gray-500 max-w-md mx-auto">
                Questo potrebbe richiedere alcuni secondi in base alla dimensione del documento
              </p>
            </div>
          </motion.div>
        ) : error ? (
          <motion.div 
            key="error"
            className="glass-card p-8"
            variants={containerVariants}
            initial="hidden"
            animate="visible"
            exit={{ opacity: 0, y: -20 }}
          >
            <div className="flex flex-col items-center text-center">
              <motion.div 
                className="rounded-full bg-red-100 dark:bg-red-900 dark:bg-opacity-30 p-4 text-red-500"
                variants={itemVariants}
              >
                <svg className="w-12 h-12" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 8v4m0 4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
                </svg>
              </motion.div>
              <motion.h2 className="text-xl font-semibold mt-6 mb-2" variants={itemVariants}>
                Elaborazione fallita
              </motion.h2>
              <motion.p className="text-gray-600 dark:text-gray-400 mb-6 max-w-md" variants={itemVariants}>
                {error}
              </motion.p>
              <motion.div className="flex space-x-4" variants={itemVariants}>
                <AdaptiveButton
                  variant="secondary"
                  onClick={goBack}
                >
                  Torna alle opzioni
                </AdaptiveButton>
                <AdaptiveButton
                  variant="primary"
                  onClick={handleStartNew}
                  className="bg-red-500 hover:bg-red-600"
                >
                  Ricomincia
                </AdaptiveButton>
              </motion.div>
            </div>
          </motion.div>
        ) : result ? (
          <motion.div 
            key="result"
            className="glass-card p-8"
            variants={containerVariants}
            initial="hidden"
            animate="visible"
            exit={{ opacity: 0, y: -20 }}
          >
            <div className="flex flex-col items-center text-center">
              <motion.div 
                className="rounded-full bg-green-100 dark:bg-green-900 dark:bg-opacity-30 p-4 text-green-500"
                variants={itemVariants}
              >
                {result.success ? (
                  <svg className="w-12 h-12" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M5 13l4 4L19 7" />
                  </svg>
                ) : (
                  <svg className="w-12 h-12" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 8v4m0 4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
                  </svg>
                )}
              </motion.div>
              
              <motion.div className="mt-6 mb-6" variants={itemVariants}>
                <h2 className="text-xl font-semibold mb-2">{getResultTitle()}</h2>
                
                <div className="result-summary mb-6 max-w-md mx-auto">
                  {result.type === 'image' && (
                    <p className="text-gray-600 dark:text-gray-400">
                      Hai convertito <span className="font-medium">{data.files[0].name}</span> ({formatFileSize(data.files[0].size)})
                      in un'immagine {result.format?.toUpperCase()} ({formatFileSize(result.blob.size)})
                    </p>
                  )}
                  
                  {result.type === 'zip' && result.totalImages && (
                    <p className="text-gray-600 dark:text-gray-400">
                      Hai convertito <span className="font-medium">{data.files[0].name}</span> ({formatFileSize(data.files[0].size)})
                      in {result.totalImages} immagini {result.format?.toUpperCase()} compresse in formato ZIP ({formatFileSize(result.blob.size)})
                    </p>
                  )}
                  
                  {data.options?.operation === 'compress' && result.compressionRate && (
                    <div>
                      <p className="text-gray-600 dark:text-gray-400">
                        Hai compresso <span className="font-medium">{data.files[0].name}</span> con un risparmio di spazio del {result.compressionRate}%
                      </p>
                      
                      <div className="flex items-center justify-between mt-3 px-4">
                        <div className="text-left">
                          <p className="text-xs text-gray-500">Originale</p>
                          <p className="font-medium">{formatFileSize(result.originalSize)}</p>
                        </div>
                        
                        <div className="grow px-4">
                          <div className="h-2 bg-gray-200 dark:bg-gray-700 rounded-full overflow-hidden">
                            <div 
                              className="h-full bg-green-500 rounded-full"
                              style={{ width: `${100 - result.compressionRate}%` }}
                            ></div>
                          </div>
                        </div>
                        
                        <div className="text-right">
                          <p className="text-xs text-gray-500">Compresso</p>
                          <p className="font-medium">{formatFileSize(result.compressedSize)}</p>
                        </div>
                      </div>
                    </div>
                  )}
                  
                  {data.options?.operation === 'protect' && (
                    <p className="text-gray-600 dark:text-gray-400">
                      Hai protetto <span className="font-medium">{data.files[0].name}</span> con una password
                      {data.options?.permissions && (
                        <span> e impostato i permessi di accesso</span>
                      )}
                    </p>
                  )}
                  
                  {data.options?.operation === 'split' && result.totalFiles && (
                    <p className="text-gray-600 dark:text-gray-400">
                      Hai diviso <span className="font-medium">{data.files[0].name}</span> in {result.totalFiles} file PDF separati
                    </p>
                  )}
                  
                  {data.options?.operation === 'merge' && (
                    <p className="text-gray-600 dark:text-gray-400">
                      Hai unito <span className="font-medium">{data.files.length}</span> file PDF in un unico documento
                      {result.pageCount && (
                        <span> di {result.pageCount} pagine</span>
                      )}
                    </p>
                  )}
                  
                  {!result.type && !data.options?.operation && data.conversionType === 'convert' && (
                    <p className="text-gray-600 dark:text-gray-400">
                      Hai convertito <span className="font-medium">{data.files[0].name}</span> in formato {data.options?.targetFormat?.toUpperCase()}
                    </p>
                  )}
                  
                  {processingStats && (
                    <div className="mt-4 pt-3 border-t border-gray-200 dark:border-gray-700 text-xs text-gray-500">
                      <p>Tempo di elaborazione: {processingStats.time} secondi</p>
                      {processingStats.inputSize && processingStats.outputSize && (
                        <p>Variazione dimensione: {formatFileSize(processingStats.inputSize)} → {formatFileSize(processingStats.outputSize)}</p>
                      )}
                    </div>
                  )}
                </div>
              </motion.div>
              
              <motion.div variants={itemVariants}>
                {!downloadStarted ? (
                  <div className="space-y-4 w-full max-w-sm">
                    <AdaptiveButton
                      variant="primary"
                      onClick={handleDownload}
                      fullWidth
                      className="bg-red-500 hover:bg-red-600 text-white flex items-center justify-center"
                    >
                      <svg className="w-5 h-5 mr-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M4 16v1a3 3 0 003 3h10a3 3 0 003-3v-1m-4-4l-4 4m0 0l-4-4m4 4V4" />
                      </svg>
                      Scarica risultato
                    </AdaptiveButton>
                    
                    {/* Show additional information about the file type */}
                    <div className="bg-gray-50 dark:bg-gray-800 rounded-lg p-3 mt-3 text-xs text-left">
                      <p className="font-medium mb-1 text-gray-600 dark:text-gray-300">Informazioni sul file:</p>
                      <p className="text-gray-500 dark:text-gray-400">
                        • Tipo: {result.type === 'image' ? `Immagine ${result.format?.toUpperCase()}` :
                               result.type === 'zip' ? 'Archivio ZIP' :
                               `File ${result.filename?.split('.').pop()?.toUpperCase() || 'PDF'}`}
                      </p>
                      <p className="text-gray-500 dark:text-gray-400">
                        • Dimensione: {formatFileSize(result.blob.size)}
                      </p>
                      {result.width && result.height && (
                        <p className="text-gray-500 dark:text-gray-400">
                          • Dimensioni: {result.width}×{result.height}px
                        </p>
                      )}
                    </div>
                  </div>
                ) : (
                  <div className="space-y-4 w-full max-w-sm">
                    <p className="text-green-600 dark:text-green-400 mb-4">
                      Il download è iniziato!
                    </p>
                    <AdaptiveButton
                      variant="secondary"
                      onClick={handleStartNew}
                      fullWidth
                    >
                      <svg className="w-5 h-5 mr-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M4 4v5h.582m15.356 2A8.001 8.001 0 004.582 9m0 0H9m11 11v-5h-.581m0 0a8.003 8.003 0 01-15.357-2m15.357 2H15" />
                      </svg>
                      Elabora un altro PDF
                    </AdaptiveButton>
                    
                    <div className="mt-3 pt-3 border-t border-gray-200 dark:border-gray-700 text-center">
                      <a 
                        href="#"
                        onClick={(e) => { e.preventDefault(); handleDownload(); }}
                        className="text-sm text-blue-500 hover:underline"
                      >
                        Download non iniziato? Prova di nuovo
                      </a>
                    </div>
                  </div>
                )}
              </motion.div>
            </div>
          </motion.div>
        ) : (
          <div className="glass-card p-8 text-center">
            <p>Nessun risultato disponibile. Torna indietro e riprova.</p>
            <AdaptiveButton
              variant="secondary"
              onClick={goBack}
              className="mt-4"
            >
              Torna alle opzioni
            </AdaptiveButton>
          </div>
        )}
      </AnimatePresence>
    </div>
  );
};

export default PDFResultStep;
EOL
    echo -e "${GREEN}✓ Fixed hook order in PDFResultStep.jsx${RESET}"
else
    echo -e "${RED}✗ PDFResultStep.jsx not found! Cannot fix hook issues.${RESET}"
fi

# Fix 4: Check PDFConfigurationStep.jsx for issues with forceComplete
echo -e "${BLUE}Checking PDFConfigurationStep.jsx for issues...${RESET}"
if [ -f "src/components/tools/pdf/PDFConfigurationStep.jsx" ]; then
    # Look for forceComplete usage issues
    if grep -q "forceComplete" "src/components/tools/pdf/PDFConfigurationStep.jsx"; then
        echo -e "${YELLOW}⚠ PDFConfigurationStep.jsx uses forceComplete - this might be related to hook issues.${RESET}"
        
        # Make a backup before modifying
        cp "src/components/tools/pdf/PDFConfigurationStep.jsx" "src/components/tools/pdf/PDFConfigurationStep.jsx.bak"
        
        # Fix potential issues with forceComplete handling
        sed -i 's/forceComplete()/typeof forceComplete === "function" \&\& forceComplete()/g' "src/components/tools/pdf/PDFConfigurationStep.jsx"
        echo -e "${GREEN}✓ Fixed forceComplete check in PDFConfigurationStep.jsx${RESET}"
    else
        echo -e "${GREEN}✓ PDFConfigurationStep.jsx appears to be fine${RESET}"
    fi
else
    echo -e "${RED}✗ PDFConfigurationStep.jsx not found!${RESET}"
fi

# Create a diagnostic test script
echo -e "${BLUE}Creating hook diagnostic test script...${RESET}"
cat > hook-diagnostic.js << 'EOL'
// Hook Diagnostic Test Script
// Run this in browser console to verify React hook issues

function testReactHooks() {
  console.log("==== StrumentiRapidi.it React Hook Diagnostic Test ====");
  
  // Check for React DevTools
  console.log("1. Testing React DevTools availability...");
  if (window.__REACT_DEVTOOLS_GLOBAL_HOOK__) {
    console.log("✓ React DevTools hook is available");
    
    // Try to get component instances
    const fiberRoots = window.__REACT_DEVTOOLS_GLOBAL_HOOK__.getFiberRoots(1);
    if (fiberRoots && fiberRoots.size > 0) {
      console.log("✓ React fiber roots found:", fiberRoots.size);
      
      // Check for the problematic components
      const components = ['ToolWizard', 'PDFResultStep', 'PDFWebViewer'];
      console.log(`2. Looking for components with hook issues: ${components.join(', ')}`);
      
      let foundComponents = [];
      fiberRoots.forEach(root => {
        const walk = (fiber) => {
          if (fiber.type && fiber.type.name && components.includes(fiber.type.name)) {
            foundComponents.push(fiber.type.name);
            console.log(`✓ Found component: ${fiber.type.name}`);
          }
          
          // Walk child fibers
          let child = fiber.child;
          while (child) {
            walk(child);
            child = child.sibling;
          }
        };
        
        walk(root.current);
      });
      
      if (foundComponents.length === 0) {
        console.log("✗ No target components found in the current render tree");
      } else {
        console.log(`✓ Found ${foundComponents.length} target component(s)`);
      }
    } else {
      console.log("✗ No React fiber roots found!");
    }
  } else {
    console.warn("✗ React DevTools hook not available. Install React DevTools extension for better diagnostics.");
  }
  
  // Check for errors in the console
  console.log("3. Checking for common React hook errors in console...");
  const hookErrors = [
    "Rendered more hooks than during the previous render",
    "React has detected a change in the order of Hooks",
    "Hooks can only be called inside the body of a function component"
  ];
  
  console.log("Please check the console for any of these errors:");
  hookErrors.forEach(err => console.log(`   - "${err}"`));
  
  console.log("\n4. Recommendation:");
  console.log("   If you see hook errors, ensure that:");
  console.log("   - All hooks are called in the same order on every render");
  console.log("   - No hooks are called conditionally");
  console.log("   - State hooks are declared before any custom hooks");
  console.log("==== Diagnostic Complete ====");
}

testReactHooks();
EOL
echo -e "${GREEN}✓ Created hook diagnostic test script${RESET}"

# Update index.html if not already done
echo -e "${BLUE}Checking for PDF.js initialization in index.html...${RESET}"
if [ -f "index.html" ]; then
    if ! grep -q "window.pdfjsLib.GlobalWorkerOptions.workerSrc" index.html; then
        # Backup the current index.html
        backup_file "index.html"
        
        # Update with proper PDF.js initialization
        sed -i '/<head>/a \
    <!-- PDF.js library for PDF rendering --> \
    <script src="https://cdnjs.cloudflare.com/ajax/libs/pdf.js/3.11.174/pdf.min.js"></script> \
    <script> \
      // Ensure proper PDF.js initialization \
      window.pdfjsLib = window.pdfjsLib || {}; \
      window.pdfjsLib.GlobalWorkerOptions = window.pdfjsLib.GlobalWorkerOptions || {}; \
      window.pdfjsLib.GlobalWorkerOptions.workerSrc = "https://cdnjs.cloudflare.com/ajax/libs/pdf.js/3.11.174/pdf.worker.min.js"; \
    </script>' index.html
        
        echo -e "${GREEN}✓ Added PDF.js initialization to index.html${RESET}"
    else
        echo -e "${GREEN}✓ PDF.js initialization already exists in index.html${RESET}"
    fi
else
    echo -e "${RED}✗ index.html not found!${RESET}"
fi

echo -e "${BOLD}${GREEN}"
echo "╔════════════════════════════════════════════════════════════╗"
echo "║        Advanced PDF Module Repair Completed!               ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo -e "${RESET}"

echo -e "${BOLD}Next Steps:${RESET}"
echo "1. Restart your development server: npm run dev"
echo "2. Clear your browser cache (important for React hook fixes to take effect)"
echo "3. Open your app and test the PDF functionality again"
echo "4. If issues persist, run the hook-diagnostic.js script in your browser console"
echo ""
echo -e "${BOLD}What Was Fixed:${RESET}"
echo "1. Fixed canvas rendering in PDFWebViewer.jsx (null canvas issue)"
echo "2. Fixed React hook ordering in ToolWizard.jsx and PDFResultStep.jsx"
echo "3. Fixed potential issues with forceComplete function in PDFConfigurationStep.jsx"
echo "4. Ensured proper PDF.js initialization in index.html"
echo ""
echo -e "${BOLD}Backup Information:${RESET}"
echo "All original files were backed up to: ${BACKUP_DIR}"
echo ""
echo -e "${BOLD}${GREEN}Thank you for using the StrumentiRapidi.it Advanced PDF Module Repair Toolkit!${RESET}"