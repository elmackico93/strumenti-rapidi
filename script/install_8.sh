#!/bin/bash

set -e

echo "🔧 Starting to fix StrumentiRapidi.it portal issues..."

# Create backups before making changes
echo "💾 Creating backups of original files..."
cp src/components/tools/pdf/PDFPreview.jsx src/components/tools/pdf/PDFPreview.jsx.bak
cp src/components/tools/pdf/PDFUploadStep.jsx src/components/tools/pdf/PDFUploadStep.jsx.bak
cp index.html index.html.bak
cp vite.config.js vite.config.js.bak

# Fix PDFPreview.jsx - Main issue with syntax errors
echo "📄 Fixing src/components/tools/pdf/PDFPreview.jsx..."

cat > src/components/tools/pdf/PDFPreview.jsx << 'EOL'
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
  const [totalPages, setTotalPages] = useState(1);
  const [scale, setScale] = useState(1.0);
  const canvasRef = useRef(null);
  
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
    };
  }, [files, preview]);
  
  // Render current page
  useEffect(() => {
    if (!preview || !canvasRef.current) return;
    
    const renderPage = async () => {
      try {
        // Get the page
        const page = await preview.getPage(currentPage);
        
        // Calculate appropriate scale
        const canvas = canvasRef.current;
        const viewport = page.getViewport({ scale });
        
        // Set canvas dimensions
        canvas.height = viewport.height;
        canvas.width = viewport.width;
        
        // Render the page
        const renderContext = {
          canvasContext: canvas.getContext('2d'),
          viewport: viewport
        };
        
        await page.render(renderContext).promise;
      } catch (error) {
        console.error('Error rendering PDF page:', error);
      }
    };
    
    renderPage();
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
      
      {totalPages > 1 && (
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
            Page {currentPage} of {totalPages}
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
      )}
    </div>
  );
};

export default PDFPreview;
EOL

# Fix PDFUploadStep.jsx - Issue with files.map
echo "📄 Fixing src/components/tools/pdf/PDFUploadStep.jsx..."

cat > src/components/tools/pdf/PDFUploadStep.jsx << 'EOL'
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
    
    if (data.conversionType) {
      onConversionTypeChange(data.conversionType);
    }
  }, [data, onConversionTypeChange]);
  
  // Gestisci il caricamento dei file
  const handleFileChange = async (selectedFiles) => {
    setError(null);
    
    // Verifica se sono PDF
    const nonPdfFiles = Array.from(selectedFiles).filter(file => 
      file.type !== 'application/pdf' && !file.name.toLowerCase().endsWith('.pdf')
    );
    
    if (nonPdfFiles.length > 0) {
      setError('Sono accettati solo file PDF. Riprova con file PDF validi.');
      return;
    }
    
    // Per l'unione, accetta più file
    if (conversionType === 'merge') {
      setFiles(prevFiles => [...prevFiles, ...selectedFiles]);
    } else {
      // Per altre operazioni, usa solo il primo file
      setFiles([selectedFiles[0]]);
    }
    
    // Analisi del file (semplificata)
    setIsAnalyzing(true);
    
    try {
      setTimeout(() => {
        const fileInfos = Array.from(selectedFiles).map(file => ({
          name: file.name,
          size: file.size,
          pages: Math.floor(Math.random() * 20) + 1, // Simulazione
          format: 'PDF'
        }));
        
        setFileInfo(fileInfos);
        setIsAnalyzing(false);
      }, 500);
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
                    onChange={(e) => handleFileChange(e.target.files)}
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
EOL

# Fix duplicate script tags in index.html
echo "📄 Fixing duplicate script tags in index.html..."

cat > index.html << 'EOL'
<!DOCTYPE html>
<html lang="it">
  <head>
    <meta charset="UTF-8" />
    <link rel="icon" type="image/svg+xml" href="/favicon.svg" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no" />
    <meta name="description" content="StrumentiRapidi.it - Strumenti online gratuiti per convertire, comprimere e modificare PDF" />
    <title>StrumentiRapidi.it - Strumenti PDF Online Gratuiti</title>
    <!-- PDF.js library for PDF rendering --> 
    <script src="https://cdnjs.cloudflare.com/ajax/libs/pdf.js/3.11.174/pdf.min.js"></script> 
    <script> 
      window.pdfjsLib = window.pdfjsLib || {}; 
      window.pdfjsLib.GlobalWorkerOptions = window.pdfjsLib.GlobalWorkerOptions || {}; 
      window.pdfjsLib.GlobalWorkerOptions.workerSrc = "https://cdnjs.cloudflare.com/ajax/libs/pdf.js/3.11.174/pdf.worker.min.js"; 
    </script>
    <script>
      // Rilevamento preferenze tema dall'utente
      const isDarkMode = window.matchMedia && window.matchMedia('(prefers-color-scheme: dark)').matches;
      const savedTheme = localStorage.getItem('theme');
      if (savedTheme) {
        document.documentElement.classList.toggle('dark', savedTheme === 'dark');
      } else if (isDarkMode) {
        document.documentElement.classList.add('dark');
      }
      
      // Meta viewport dinamico per dispositivi molto piccoli
      (function() {
        if (window.innerWidth < 350) {
          var metaViewport = document.querySelector('meta[name="viewport"]');
          if (metaViewport) {
            metaViewport.content = 'width=350, user-scalable=no';
          }
        }
      })();
    </script>
  </head>
  <body>
    <div id="root"></div>
    <script type="module" src="/src/main.jsx"></script>
  </body>
</html>
EOL

# Fix vite.config.js to add hmr overlay config
echo "📄 Updating vite.config.js with hmr overlay config..."

cat > vite.config.js << 'EOL'
import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react';

export default defineConfig({
  plugins: [react()],
  server: {
    port: 3000,
    open: true,
    hmr: {
      overlay: false
    }
  },
  build: {
    outDir: 'dist',
    sourcemap: true,
    minify: 'esbuild'
  }
});
EOL

# Create a restore script for safety
echo "📄 Creating restore script (restore-backup.sh)..."

cat > restore-backup.sh << 'EOL'
#!/bin/bash

set -e

echo "🔄 Restoring original files from backup..."

# Restore PDFPreview.jsx if backup exists
if [ -f "src/components/tools/pdf/PDFPreview.jsx.bak" ]; then
  echo "🔄 Restoring src/components/tools/pdf/PDFPreview.jsx"
  cp src/components/tools/pdf/PDFPreview.jsx.bak src/components/tools/pdf/PDFPreview.jsx
fi

# Restore PDFUploadStep.jsx if backup exists
if [ -f "src/components/tools/pdf/PDFUploadStep.jsx.bak" ]; then
  echo "🔄 Restoring src/components/tools/pdf/PDFUploadStep.jsx"
  cp src/components/tools/pdf/PDFUploadStep.jsx.bak src/components/tools/pdf/PDFUploadStep.jsx
fi

# Restore index.html if backup exists
if [ -f "index.html.bak" ]; then
  echo "🔄 Restoring index.html"
  cp index.html.bak index.html
fi

# Restore vite.config.js if backup exists
if [ -f "vite.config.js.bak" ]; then
  echo "🔄 Restoring vite.config.js"
  cp vite.config.js.bak vite.config.js
fi

echo "✅ Restoration complete!"

chmod +x restore-backup.sh
EOL

chmod +x restore-backup.sh

# Install required dependencies and run the development server
echo "📦 Ensuring all dependencies are installed..."
npm install

# Set executable permissions for this script
chmod +x "$0"

echo "✅ All fixes applied! Now you can run the development server with:"
echo "   npm run dev"
echo ""
echo "💡 If needed, you can restore original files using:"
echo "   ./restore-backup.sh"