// Professional production-ready PDFResultStep component
// Handles processing results and provides download functionality
import React, { useState, useEffect, useCallback } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import AdaptiveButton from '../../ui/AdaptiveButton';
import { pdfService } from '../../../services/pdfService';
import { useOS } from '../../../context/OSContext';

/**
 * Manages the final step of PDF processing workflow, showing results and providing download options
 */
const PDFResultStep = ({ data, updateData, goBack, setResult, result, themeColor }) => {
 const { osType, isMobile } = useOS();
 const [isProcessing, setIsProcessing] = useState(!result);
 const [error, setError] = useState(null);
 const [progress, setProgress] = useState(0);
 const [progressMessage, setProgressMessage] = useState('');
 const [downloadStarted, setDownloadStarted] = useState(false);
 const [processingStats, setProcessingStats] = useState(null);
 
 /**
  * Formats file size for display
  * @param {number} bytes - Size in bytes
  * @returns {string} Formatted size string
  */
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
 
 /**
  * Updates progress based on processing stage
  * @param {string} stage - Current processing stage
  * @param {number} value - Progress value (0-100)
  */
 const updateProgress = useCallback((stage, value) => {
   setProgress(value);
   setProgressMessage(stage);
 }, []);
 
 /**
  * Process PDF files if no result exists
  */
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
 
 /**
  * Handles PDF to other format conversion
  * @param {Object} data - Processing data
  * @param {Function} updateProgress - Progress update function
  * @returns {Object} Processing result
  */
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
 
 /**
  * Handles PDF compression
  * @param {Object} data - Processing data
  * @param {Function} updateProgress - Progress update function
  * @returns {Object} Processing result
  */
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
 
 /**
  * Handles PDF password protection
  * @param {Object} data - Processing data
  * @param {Function} updateProgress - Progress update function
  * @returns {Object} Processing result
  */
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
 
 /**
  * Handles PDF splitting
  * @param {Object} data - Processing data
  * @param {Function} updateProgress - Progress update function
  * @returns {Object} Processing result
  */
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
 
 /**
  * Handles PDF merging
  * @param {Object} data - Processing data
  * @param {Function} updateProgress - Progress update function
  * @returns {Object} Processing result
  */
 const handleMerge = async (data, updateProgress) => {
   const { files } = data;
   
   updateProgress('Caricamento documenti...', 20);
   updateProgress('Combinazione contenuti...', 50);
   updateProgress('Ottimizzazione documento finale...', 80);
   
   return await pdfService.mergePDFs(files, {});
 };
 
 /**
  * Gets operation display name
  * @param {string} operation - Operation code
  * @returns {string} Display name
  */
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
 
 /**
  * Downloads the result file
  */
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
 
 /**
  * Restart the process with a new file
  */
 const handleStartNew = () => {
   // Clean up and restart
   window.location.href = window.location.pathname;
 };
 
 /**
  * Gets the appropriate icon for the result based on operation
  * @returns {JSX.Element} Icon component
  */
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
                       href="javascript:void(0)" 
                       onClick={() => handleDownload()}
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