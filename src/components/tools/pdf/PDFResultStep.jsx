// Componente per mostrare i risultati della conversione/elaborazione PDF
import React, { useState, useEffect } from 'react';
import { motion } from 'framer-motion';
import AdaptiveButton from '../../ui/AdaptiveButton';
import { pdfService } from '../../../services/pdfService';
import { useOS } from '../../../context/OSContext';

const PDFResultStep = ({ data, updateData, goBack, setResult, result, themeColor }) => {
  const { osType, isMobile } = useOS();
  const [isProcessing, setIsProcessing] = useState(!result);
  const [error, setError] = useState(null);
  const [progress, setProgress] = useState(0);
  const [downloadStarted, setDownloadStarted] = useState(false);
  
  // Formatta la dimensione del file
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
  
  // Elabora il file se non ci sono risultati
  useEffect(() => {
    if (!result && data.files && data.options) {
      const processData = async () => {
        setIsProcessing(true);
        setError(null);
        setProgress(0);
        
        try {
          // Simuliamo l'avanzamento
          const progressInterval = setInterval(() => {
            setProgress(prev => {
              const nextProgress = prev + Math.random() * 5;
              return nextProgress >= 90 ? 90 : nextProgress;
            });
          }, 300);
          
          // Ottieni il tipo di operazione
          const operation = data.options.operation || data.conversionType;
          
          let processedResult;
          
          switch (operation) {
            case 'convert':
              // Conversione in base al formato target
              switch (data.options.targetFormat) {
                case 'jpg':
                case 'png':
                  processedResult = await pdfService.convertToImages(
                    data.files[0],
                    {
                      format: data.options.targetFormat,
                      quality: data.options.quality,
                      dpi: data.options.dpi
                    }
                  );
                  break;
                case 'txt':
                  processedResult = await pdfService.extractText(
                    data.files[0],
                    {
                      pageRange: data.options.pageRange,
                      customPages: data.options.customPages
                    }
                  );
                  break;
                case 'html':
                  processedResult = await pdfService.convertToHTML(
                    data.files[0],
                    {
                      pageRange: data.options.pageRange,
                      customPages: data.options.customPages,
                      preserveLinks: data.options.preserveLinks
                    }
                  );
                  break;
                case 'docx':
                  processedResult = await pdfService.convertToDocx(
                    data.files[0],
                    {
                      pageRange: data.options.pageRange,
                      customPages: data.options.customPages,
                      preserveLinks: data.options.preserveLinks,
                      preserveFormatting: data.options.preserveFormatting
                    }
                  );
                  break;
                default:
                  throw new Error(`Formato di conversione non supportato: ${data.options.targetFormat}`);
              }
              break;
              
            case 'compress':
              processedResult = await pdfService.compressPDF(
                data.files[0],
                { quality: data.options.quality }
              );
              break;
              
            case 'protect':
              processedResult = await pdfService.protectPDF(
                data.files[0],
                {
                  password: data.options.password,
                  permissions: data.options.permissions
                }
              );
              break;
              
            case 'split':
              processedResult = await pdfService.splitPDF(
                data.files[0],
                {
                  pageRange: data.options.pageRange,
                  customPages: data.options.customPages
                }
              );
              break;
              
            case 'merge':
              processedResult = await pdfService.mergePDFs(
                data.files,
                {}
              );
              break;
              
            default:
              throw new Error(`Operazione non supportata: ${operation}`);
          }
          
          // Ferma l'intervallo di progresso
          clearInterval(progressInterval);
          
          // Completa il progresso
          setProgress(100);
          
          // Piccolo ritardo per mostrare il 100%
          setTimeout(() => {
            setResult(processedResult);
          }, 300);
        } catch (err) {
          console.error('Errore durante l\'elaborazione:', err);
          setError(err.message || 'Si è verificato un errore durante l\'elaborazione.');
        } finally {
          setIsProcessing(false);
        }
      };
      
      processData();
    }
  }, [data.files, data.options, result, setResult]);
  
  // Scarica il risultato
  const handleDownload = () => {
    try {
      pdfService.downloadResult(result);
      setDownloadStarted(true);
    } catch (err) {
      console.error('Errore durante il download:', err);
      setError(`Errore durante il download: ${err.message}`);
    }
  };
  
  // Riavvia il processo
  const handleStartNew = () => {
    window.location.reload();
  };
  
  // Determina l'icona appropriata per il risultato
  const getResultIcon = () => {
    const operation = data.options?.operation || data.conversionType;
    
    switch (operation) {
      case 'convert':
        switch (data.options?.targetFormat) {
          case 'jpg':
          case 'png':
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
  
  // Ottieni il titolo appropriato per il risultato
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
  
  // Animazione del contenitore
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
  
  // Animazione degli elementi
  const itemVariants = {
    hidden: { opacity: 0, y: 10 },
    visible: { opacity: 1, y: 0 }
  };

  return (
    <div className="step-container">
      {isProcessing ? (
        <motion.div 
          className="glass-card p-8 text-center"
          initial={{ opacity: 0 }}
          animate={{ opacity: 1 }}
          transition={{ duration: 0.5 }}
        >
          <div className="flex flex-col items-center">
            <div className="relative w-24 h-24 mb-4">
              <svg className="w-24 h-24 transform -rotate-90" viewBox="0 0 100 100">
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
              <div className="absolute inset-0 flex items-center justify-center text-xl font-semibold">
                {Math.round(progress)}%
              </div>
            </div>
            <h2 className="text-xl font-semibold mt-2 mb-2">Elaborazione in corso</h2>
            <p className="text-gray-600 dark:text-gray-400 max-w-md mx-auto">
              Stiamo elaborando il tuo file PDF. Questo potrebbe richiedere alcuni secondi in base alla dimensione del documento.
            </p>
          </div>
        </motion.div>
      ) : error ? (
        <motion.div 
          className="glass-card p-8"
          variants={containerVariants}
          initial="hidden"
          animate="visible"
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
          className="glass-card p-8"
          variants={containerVariants}
          initial="hidden"
          animate="visible"
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
                    in un'immagine {result.format.toUpperCase()} ({formatFileSize(result.blob.size)})
                  </p>
                )}
                
                {result.type === 'zip' && result.totalImages && (
                  <p className="text-gray-600 dark:text-gray-400">
                    Hai convertito <span className="font-medium">{data.files[0].name}</span> ({formatFileSize(data.files[0].size)})
                    in {result.totalImages} immagini {result.format.toUpperCase()} compresse in formato ZIP ({formatFileSize(result.blob.size)})
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
                  </p>
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
    </div>
  );
};

export default PDFResultStep;
