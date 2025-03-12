// src/services/processingService.js
import { pdfService } from './pdfService';

// Process files based on options
export const processFile = async (file, options) => {
  if (!file) {
    throw new Error('Nessun file fornito');
  }
  
  // Determine processing type based on file
  const fileType = file.type;
  const fileExtension = file.name.split('.').pop().toLowerCase();
  
  // Process based on file type
  if (fileType.startsWith('image/')) {
    return processImage(file, options);
  } else if (fileType === 'application/pdf' || fileExtension === 'pdf') {
    return processPDF(file, options);
  } else if (
    fileType.includes('word') || 
    ['doc', 'docx'].includes(fileExtension)
  ) {
    return processDocument(file, options);
  } else if (
    fileType.includes('text/') || 
    ['txt', 'csv', 'json'].includes(fileExtension)
  ) {
    return processText(file, options);
  }
  
  throw new Error('Tipo di file non supportato');
};

// Process image files
const processImage = async (file, options) => {
  // Implementazione esistente per le immagini
  return new Promise((resolve, reject) => {
    const img = new Image();
    
    img.onload = () => {
      try {
        // Create canvas for processing
        const canvas = document.createElement('canvas');
        const ctx = canvas.getContext('2d');
        
        // Apply resize if specified
        let width = img.width;
        let height = img.height;
        
        if (options?.resize?.width && options?.resize?.height) {
          width = options.resize.width;
          height = options.resize.height;
        } else if (options?.resize?.width) {
          width = options.resize.width;
          height = Math.round((img.height / img.width) * options.resize.width);
        } else if (options?.resize?.height) {
          height = options.resize.height;
          width = Math.round((img.width / img.height) * options.resize.height);
        }
        
        // Set canvas dimensions
        canvas.width = width;
        canvas.height = height;
        
        // Draw resized image
        ctx.drawImage(img, 0, 0, width, height);
        
        // Apply filters if specified
        if (options?.filters) {
          applyImageFilters(ctx, canvas.width, canvas.height, options.filters);
        }
        
        // Convert to specified format with quality
        const format = options?.format || 'jpeg';
        const quality = options?.quality ? options.quality / 100 : 0.9;
        
        // Generate output type and extension
        const outputType = format === 'jpg' ? 'jpeg' : format;
        const extension = format === 'jpeg' ? 'jpg' : format;
        
        // Convert canvas to blob
        canvas.toBlob((blob) => {
          if (!blob) {
            reject(new Error('Elaborazione immagine fallita'));
            return;
          }
          
          // Create result file
          const fileName = file.name.split('.')[0] + '.' + extension;
          const outputFile = new Blob([blob], { type: `image/${outputType}` });
          
          // Calculate compression rate
          const compressionRate = Math.round((1 - (blob.size / file.size)) * 100);
          
          resolve({
            outputFile,
            outputName: fileName,
            outputType: extension.toUpperCase(),
            outputSize: blob.size,
            compressionRate: compressionRate > 0 ? compressionRate : 0
          });
        }, `image/${outputType}`, quality);
      } catch (error) {
        reject(error);
      }
    };
    
    img.onerror = () => {
      reject(new Error('Caricamento immagine fallito'));
    };
    
    img.src = URL.createObjectURL(file);
  });
};

// Apply filters to image canvas
const applyImageFilters = (ctx, width, height, filters) => {
  // Implementazione esistente per l'applicazione dei filtri
  const imageData = ctx.getImageData(0, 0, width, height);
  const data = imageData.data;
  
  // Apply brightness
  if (filters.brightness !== undefined && filters.brightness !== 0) {
    const brightness = filters.brightness;
    for (let i = 0; i < data.length; i += 4) {
      data[i] = Math.max(0, Math.min(255, data[i] + brightness));
      data[i + 1] = Math.max(0, Math.min(255, data[i + 1] + brightness));
      data[i + 2] = Math.max(0, Math.min(255, data[i + 2] + brightness));
    }
  }
  
  // Apply contrast
  if (filters.contrast !== undefined && filters.contrast !== 0) {
    const contrast = filters.contrast * 2.55;
    const factor = (259 * (contrast + 255)) / (255 * (259 - contrast));
    
    for (let i = 0; i < data.length; i += 4) {
      data[i] = Math.max(0, Math.min(255, factor * (data[i] - 128) + 128));
      data[i + 1] = Math.max(0, Math.min(255, factor * (data[i + 1] - 128) + 128));
      data[i + 2] = Math.max(0, Math.min(255, factor * (data[i + 2] - 128) + 128));
    }
  }
  
  // Apply saturation
  if (filters.saturation !== undefined && filters.saturation !== 0) {
    const saturation = 1 + filters.saturation / 100;
    
    for (let i = 0; i < data.length; i += 4) {
      const gray = 0.3 * data[i] + 0.59 * data[i + 1] + 0.11 * data[i + 2];
      
      data[i] = Math.max(0, Math.min(255, gray + saturation * (data[i] - gray)));
      data[i + 1] = Math.max(0, Math.min(255, gray + saturation * (data[i + 1] - gray)));
      data[i + 2] = Math.max(0, Math.min(255, gray + saturation * (data[i + 2] - gray)));
    }
  }
  
  // Update canvas with filtered image
  ctx.putImageData(imageData, 0, 0);
};

// Process PDF files - utilizzando il nuovo servizio PDF
const processPDF = async (file, options) => {
  try {
    // Ottieni il tipo di operazione
    const operation = options.operation || 'convert';
    
    let result;
    
    switch (operation) {
      case 'convert':
        // Conversione in base al formato target
        switch (options.targetFormat) {
          case 'jpg':
          case 'png':
            result = await pdfService.convertToImages(
              file,
              {
                format: options.targetFormat,
                quality: options.quality,
                dpi: options.dpi
              }
            );
            break;
          case 'txt':
            result = await pdfService.extractText(
              file,
              {
                pageRange: options.pageRange,
                customPages: options.customPages
              }
            );
            break;
          case 'html':
            result = await pdfService.convertToHTML(
              file,
              {
                pageRange: options.pageRange,
                customPages: options.customPages,
                preserveLinks: options.preserveLinks
              }
            );
            break;
          case 'docx':
            result = await pdfService.convertToDocx(
              file,
              {
                pageRange: options.pageRange,
                customPages: options.customPages,
                preserveLinks: options.preserveLinks,
                preserveFormatting: options.preserveFormatting
              }
            );
            break;
          default:
            throw new Error(`Formato di conversione non supportato: ${options.targetFormat}`);
        }
        
        // Restituisci il risultato in un formato compatibile con il componente ResultStep
        return {
          outputFile: result.blob,
          outputName: result.filename,
          outputType: options.targetFormat.toUpperCase(),
          outputSize: result.blob.size,
          success: true,
          ...result // Aggiungi tutte le altre proprietà
        };
        
      case 'compress':
        result = await pdfService.compressPDF(file, { quality: options.quality });
        
        return {
          outputFile: result.blob,
          outputName: result.filename,
          outputType: 'PDF (compresso)',
          outputSize: result.compressedSize,
          originalSize: result.originalSize,
          compressionRate: result.compressionRate,
          success: true,
          ...result
        };
        
      case 'protect':
        result = await pdfService.protectPDF(
          file,
          {
            password: options.password,
            permissions: options.permissions
          }
        );
        
        return {
          outputFile: result.blob,
          outputName: result.filename,
          outputType: 'PDF (protetto)',
          outputSize: result.blob.size,
          success: true,
          ...result
        };
        
      case 'split':
        result = await pdfService.splitPDF(
          file,
          {
            pageRange: options.pageRange,
            customPages: options.customPages
          }
        );
        
        return {
          outputFile: result.type === 'zip' ? result.blob : result.blob,
          outputName: result.filename,
          outputType: result.type === 'zip' ? `ZIP (${result.totalFiles} file PDF)` : 'PDF',
          outputSize: result.blob.size,
          success: true,
          ...result
        };
        
      case 'merge':
        // Non implementato qui, gestito direttamente nel componente ResultStep
        throw new Error('Per unire PDF, utilizza il componente PDFResultStep');
        
      default:
        throw new Error(`Operazione non supportata: ${operation}`);
    }
  } catch (error) {
    console.error('Errore durante il processing del PDF:', error);
    throw error;
  }
};

// Process document files
const processDocument = async (file, options) => {
  // Questa funzione rimarrebbe invariata o potrebbe essere estesa per supportare più formati
  return new Promise((resolve) => {
    setTimeout(() => {
      const fileName = file.name.split('.')[0] + '.' + (options?.targetFormat || 'pdf');
      
      resolve({
        outputFile: file,
        outputName: fileName,
        outputType: (options?.targetFormat || 'PDF').toUpperCase(),
        outputSize: file.size
      });
    }, 1500);
  });
};

// Process text files
const processText = async (file, options) => {
  // Questa funzione rimarrebbe invariata o potrebbe essere estesa per supportare più formati
  return new Promise((resolve) => {
    setTimeout(() => {
      const fileName = file.name.split('.')[0] + '.' + (options?.targetFormat || 'txt');
      
      resolve({
        outputFile: file,
        outputName: fileName,
        outputType: (options?.targetFormat || 'TXT').toUpperCase(),
        outputSize: file.size
      });
    }, 1000);
  });
};

export default {
  processFile,
  processImage,
  processPDF,
  processDocument,
  processText
};
