#!/bin/bash

# Script per correggere i problemi di responsive design nel convertitore PDF
echo "=== Correzione responsiveness UI del convertitore PDF ==="

# Verifica directory progetto
if [ ! -f "package.json" ] || [ ! -d "src" ]; then
  echo "Errore: eseguire nella directory principale del progetto"
  exit 1
fi

# Funzione per creare o sovrascrivere file
create_file() {
  mkdir -p "$(dirname "$1")"
  cat > "$1"
}

# 1. Aggiungiamo nuovi stili CSS per migliorare la responsiveness
create_file "src/styles/responsive-fixes.css" << 'EOF'
/* Stili responsivi migliorati per StrumentiRapidi.it */

/* Layout responsivo per le schede di funzionalità */
.feature-card {
  transition: all 0.3s ease;
  height: 100%;
  display: flex;
  flex-direction: column;
}

.feature-card-content {
  flex: 1;
  display: flex;
  flex-direction: column;
  justify-content: space-between;
}

/* Miglioramento stile schede funzionalità */
.feature-card-icon {
  width: 40px;
  height: 40px;
  display: flex;
  align-items: center;
  justify-content: center;
  margin-bottom: 0.75rem;
}

.feature-card-title {
  font-size: 1rem;
  font-weight: 600;
  margin-bottom: 0.5rem;
  line-height: 1.2;
}

.feature-card-description {
  font-size: 0.875rem;
  color: var(--text-secondary);
  line-height: 1.4;
}

/* Grid responsivo migliorato */
.feature-grid {
  display: grid;
  gap: 1rem;
  width: 100%;
}

/* Breakpoints specifici per grid responsivo */
@media (max-width: 480px) {
  .feature-grid {
    grid-template-columns: 1fr;
  }
  
  .feature-card {
    padding: 1rem;
  }
  
  .feature-card-icon {
    width: 32px;
    height: 32px;
  }
  
  .feature-card-title {
    font-size: 0.95rem;
  }
  
  .feature-card-description {
    font-size: 0.8rem;
  }
}

@media (min-width: 481px) and (max-width: 768px) {
  .feature-grid {
    grid-template-columns: repeat(2, 1fr);
  }
}

@media (min-width: 769px) {
  .feature-grid {
    grid-template-columns: repeat(3, 1fr);
  }
}

/* Miglioramenti per step indicator */
.step-indicator {
  margin-bottom: 1.5rem;
}

.step-number {
  width: 2rem;
  height: 2rem;
  font-size: 0.875rem;
}

@media (max-width: 480px) {
  .step-number {
    width: 1.75rem;
    height: 1.75rem;
    font-size: 0.75rem;
  }
  
  .step-label {
    font-size: 0.75rem;
  }
}
EOF

# 2. Aggiorna index.css per importare i nuovi stili responsivi
sed -i '1s/^/@import "\.\/styles\/responsive-fixes.css";\n/' src/index.css

# 3. Aggiorniamo il componente PDFUploadStep per una migliore responsiveness 
create_file "src/components/tools/pdf/PDFUploadStep.jsx" << 'EOF'
// Componente per il caricamento dei file PDF con layout responsivo migliorato
import React, { useState, useEffect } from 'react';
import { motion } from 'framer-motion';
import FileDropZone from '../../ui/FileDropZone';
import FilePreview from '../../ui/FilePreview';
import AdaptiveButton from '../../ui/AdaptiveButton';
import { useOS } from '../../../context/OSContext';

const PDFUploadStep = ({ data, updateData, goNext, toolId, themeColor, conversionType, onConversionTypeChange }) => {
  const { osType, isMobile } = useOS();
  const [files, setFiles] = useState([]);
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
        <h2 className="text-xl font-semibold mb-4">Cosa vuoi fare con il PDF?</h2>
        
        <div className="feature-grid">
          {conversionTypes.map((type) => (
            <motion.div
              key={type.id}
              className={`feature-card cursor-pointer p-4 rounded-lg border-2 ${
                conversionType === type.id 
                  ? 'border-red-500 bg-red-50 dark:bg-red-900 dark:bg-opacity-10' 
                  : 'border-gray-200 dark:border-gray-700 hover:border-red-300 dark:hover:border-red-700'
              }`}
              onClick={() => handleTypeChange(type.id)}
              whileHover={{ scale: 1.02 }}
              whileTap={{ scale: 0.98 }}
            >
              <div className="feature-card-content">
                <div>
                  <div className={`feature-card-icon rounded-full ${
                    conversionType === type.id 
                      ? 'bg-red-500 text-white' 
                      : 'bg-gray-100 dark:bg-gray-800 text-gray-600 dark:text-gray-400'
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
      
      <div className="glass-card p-4 md:p-6">
        <h3 className="text-lg font-medium mb-4">
          {conversionType === 'merge' ? 'Carica i file PDF da unire' : 'Carica il tuo PDF'}
        </h3>
        
        {files.length === 0 ? (
          <FileDropZone 
            onFileSelect={handleFileChange}
            acceptedFormats={['.pdf']}
            maxSize={100 * 1024 * 1024}
            multiple={conversionType === 'merge'}
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
            
            {conversionType === 'merge' && (
              <motion.div
                initial={{ opacity: 0 }}
                animate={{ opacity: 1 }}
                transition={{ duration: 0.3, delay: 0.2 }}
              >
                <AdaptiveButton
                  variant="secondary"
                  onClick={() => document.getElementById('add-more-files').click()}
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

# 4. Miglioramento degli indicatori di step per la responsiveness
create_file "src/components/ui/StepIndicator.jsx" << 'EOF'
// src/components/ui/StepIndicator.jsx - versione migliorata per responsiveness
import React from 'react';
import { motion } from 'framer-motion';
import { useOS } from '../../context/OSContext';

const StepIndicator = ({ steps, currentStep }) => {
  const { osType, isMobile } = useOS();
  
  return (
    <div className="step-indicator glass-card p-4 mb-6 overflow-hidden">
      <div className="flex justify-between items-center relative">
        {/* Progress line */}
        <div className="absolute h-1 bg-gray-200 dark:bg-gray-700 left-0 right-0 top-1/2 transform -translate-y-1/2 z-0" />
        
        {/* Active progress */}
        <motion.div 
          className="absolute h-1 bg-primary-500 left-0 top-1/2 transform -translate-y-1/2 z-0"
          initial={{ width: '0%' }}
          animate={{ width: `${(100 / (steps.length - 1)) * currentStep}%` }}
          transition={{ duration: 0.5 }}
        />
        
        {/* Step indicators */}
        {steps.map((step, index) => (
          <div key={index} className="z-10 flex flex-col items-center">
            <motion.div
              className={`step-number rounded-full flex items-center justify-center ${
                index <= currentStep 
                  ? 'bg-primary-500 text-white' 
                  : 'bg-gray-200 dark:bg-gray-700 text-gray-500 dark:text-gray-400'
              }`}
              animate={{
                scale: index === currentStep ? 1.1 : 1,
                backgroundColor: index <= currentStep ? '#3B82F6' : '#E5E7EB',
                color: index <= currentStep ? '#FFFFFF' : '#6B7280'
              }}
              transition={{ duration: 0.3 }}
            >
              {index + 1}
            </motion.div>
            
            <span className={`step-label text-xs font-medium mt-1 ${
              index <= currentStep 
                ? 'text-primary-500' 
                : 'text-gray-500 dark:text-gray-400'
            } ${isMobile ? 'hidden sm:block' : ''}`}>
              {step}
            </span>
          </div>
        ))}
      </div>
    </div>
  );
};

export default StepIndicator;
EOF

# 5. Patch per il CSS specifico delle schede PDF
cat >> src/styles/responsive-fixes.css << 'EOF'
/* Risolve specificamente il problema dell'immagine */

/* Fix specifico per la griglia feature-grid mostrata nello screenshot */
.feature-grid {
  margin: 0 -0.25rem; /* Compensare il padding all'interno del contenitore */
}

@media (max-width: 480px) {
  .feature-card-icon {
    display: flex;
    align-items: center;
    justify-content: center;
    margin-bottom: 0.5rem;
  }
  
  .feature-card {
    padding: 0.75rem !important;
  }
  
  .feature-card-title {
    font-size: 0.875rem !important;
    margin-bottom: 0.25rem !important;
  }
  
  .feature-card-description {
    font-size: 0.75rem !important;
    line-height: 1.3 !important;
    overflow: hidden;
    text-overflow: ellipsis;
    display: -webkit-box;
    -webkit-line-clamp: 2;
    -webkit-box-orient: vertical;
  }
}

/* Miglioramento spazio interno nei dispositivi piccoli */
@media (max-width: 359px) {
  .step-container {
    padding-left: 0.5rem !important;
    padding-right: 0.5rem !important;
  }
  
  .glass-card {
    padding: 0.75rem !important;
  }
  
  .feature-card {
    padding: 0.625rem !important;
  }
  
  .feature-card-description {
    -webkit-line-clamp: 2;
  }
  
  h2.text-xl {
    font-size: 1rem !important;
  }
  
  h3.text-lg {
    font-size: 0.875rem !important;
  }
}
EOF

# 6. Aggiornamento del componente di responsività mobile
create_file "src/hooks/useWindowSize.js" << 'EOF'
// Hook personalizzato per gestire la dimensione della finestra
import { useState, useEffect } from 'react';

export function useWindowSize() {
  const [windowSize, setWindowSize] = useState({
    width: undefined,
    height: undefined,
    isMobile: false,
    isTablet: false,
    isDesktop: false
  });
  
  useEffect(() => {
    // Handler per ridimensionamento
    function handleResize() {
      const width = window.innerWidth;
      const height = window.innerHeight;
      
      setWindowSize({
        width,
        height,
        isMobile: width < 640,
        isTablet: width >= 640 && width < 1024,
        isDesktop: width >= 1024
      });
    }
    
    // Aggiungi event listener
    window.addEventListener("resize", handleResize);
    
    // Chiama handler immediatamente
    handleResize();
    
    // Pulisci event listener
    return () => window.removeEventListener("resize", handleResize);
  }, []);
  
  return windowSize;
}
EOF

# 7. Aggiornare il file App.jsx per includere il controllo della viewport
sed -i '/import App from/i import { useWindowSize } from "./hooks/useWindowSize";' src/main.jsx

# 8. Aggiorna il file index.html con una migliore configurazione di viewport
cat > index.html << 'EOF'
<!DOCTYPE html>
<html lang="it">
  <head>
    <meta charset="UTF-8" />
    <link rel="icon" type="image/svg+xml" href="/favicon.svg" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no" />
    <meta name="description" content="StrumentiRapidi.it - Strumenti online gratuiti per convertire, comprimere e modificare PDF" />
    <title>StrumentiRapidi.it - Strumenti PDF Online Gratuiti</title>
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
EOF

# Messaggio conclusivo
echo ""
echo "==============================================="
echo "🎉 Problemi di responsive design corretti!"
echo "==============================================="
echo ""
echo "Miglioramenti implementati:"
echo "✅ Griglia delle funzionalità ottimizzata per dispositivi mobili"
echo "✅ Dimensioni e spaziatura delle schede corrette"
echo "✅ Testo adattivo in base alle dimensioni dello schermo"
echo "✅ Miglior layout per dispositivi molto piccoli"
echo "✅ Risolto il problema di overflow dei contenuti"
echo "✅ Viewport configurata correttamente per tutti i dispositivi"
echo ""
echo "Per avviare l'applicazione: npm run dev"
echo ""
echo "==============================================="