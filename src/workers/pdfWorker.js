// Worker dedicato alle operazioni PDF pesanti per non bloccare l'UI
self.importScripts(
  'https://unpkg.com/pdfjs-dist@3.11.174/build/pdf.min.js',
  'https://unpkg.com/pdf-lib@1.17.1/dist/pdf-lib.min.js',
  'https://unpkg.com/jszip@3.10.1/dist/jszip.min.js'
);

// Inizializzazione PDF.js
pdfjsLib.GlobalWorkerOptions.workerSrc = 'https://unpkg.com/pdfjs-dist@3.11.174/build/pdf.worker.min.js';

// Funzioni helper
async function blobToArrayBuffer(blob) {
  return new Promise((resolve, reject) => {
    const reader = new FileReader();
    reader.onload = () => resolve(reader.result);
    reader.onerror = reject;
    reader.readAsArrayBuffer(blob);
  });
}

// Gestione dei messaggi
self.onmessage = async function(e) {
  const { task, fileData, options } = e.data;
  
  try {
    let result;
    
    switch (task) {
      case 'extractText':
        result = await extractTextFromPDF(fileData, options);
        break;
      case 'convertToImages':
        result = await convertPDFToImages(fileData, options);
        break;
      case 'compressPDF':
        result = await compressPDF(fileData, options);
        break;
      case 'splitPDF':
        result = await splitPDF(fileData, options);
        break;
      case 'mergePDFs':
        result = await mergePDFs(fileData, options);
        break;
      case 'protectPDF':
        result = await protectPDF(fileData, options);
        break;
      default:
        throw new Error(`Operazione non supportata: ${task}`);
    }
    
    self.postMessage({
      status: 'success',
      result: result
    });
  } catch (error) {
    self.postMessage({
      status: 'error',
      error: error.message || 'Errore sconosciuto'
    });
  }
};

// Estrae il testo da un PDF
async function extractTextFromPDF(pdfData, options) {
  try {
    const { pageRange } = options;
    
    // Carica il PDF
    const loadingTask = pdfjsLib.getDocument({data: pdfData});
    const pdf = await loadingTask.promise;
    
    // Ottieni il numero totale di pagine
    const numPages = pdf.numPages;
    
    // Determina quali pagine elaborare
    let pagesToProcess = [];
    if (pageRange === 'all') {
      pagesToProcess = Array.from({length: numPages}, (_, i) => i + 1);
    } else if (pageRange === 'custom' && options.customPages) {
      // Parse range come "1-5,8,11-13"
      const ranges = options.customPages.split(',');
      for (const range of ranges) {
        if (range.includes('-')) {
          const [start, end] = range.split('-').map(Number);
          for (let i = start; i <= Math.min(end, numPages); i++) {
            pagesToProcess.push(i);
          }
        } else {
          const pageNum = Number(range.trim());
          if (pageNum > 0 && pageNum <= numPages) {
            pagesToProcess.push(pageNum);
          }
        }
      }
    }
    
    if (pagesToProcess.length === 0) {
      pagesToProcess = Array.from({length: numPages}, (_, i) => i + 1);
    }
    
    // Estrazione del testo
    const textContent = [];
    for (const pageNum of pagesToProcess) {
      const page = await pdf.getPage(pageNum);
      const content = await page.getTextContent();
      const text = content.items.map(item => item.str).join(' ');
      textContent.push({
        pageNumber: pageNum,
        text: text
      });
    }
    
    return {
      success: true,
      pages: textContent,
      fullText: textContent.map(page => page.text).join('\n\n')
    };
  } catch (error) {
    console.error('Errore durante l\'estrazione del testo:', error);
    throw error;
  }
}

// Converte un PDF in immagini
async function convertPDFToImages(pdfData, options) {
  try {
    const { format = 'png', quality = 'high', dpi = 150 } = options;
    
    // Carica il PDF
    const loadingTask = pdfjsLib.getDocument({data: pdfData});
    const pdf = await loadingTask.promise;
    
    // Calcola la scala basata sul DPI (PDF ha una risoluzione di base di 72 DPI)
    const scale = dpi / 72;
    
    // Estrai le pagine come immagini
    const numPages = pdf.numPages;
    const images = [];
    
    for (let i = 1; i <= numPages; i++) {
      const page = await pdf.getPage(i);
      const viewport = page.getViewport({scale});
      
      // Crea un canvas off-screen
      const canvas = new OffscreenCanvas(viewport.width, viewport.height);
      const context = canvas.getContext('2d');
      
      // Renderizza la pagina sul canvas
      const renderContext = {
        canvasContext: context,
        viewport: viewport
      };
      
      await page.render(renderContext).promise;
      
      // Converti il canvas in un blob
      const imageQuality = quality === 'high' ? 1.0 : quality === 'medium' ? 0.8 : 0.5;
      const blob = await canvas.convertToBlob({
        type: `image/${format === 'jpg' ? 'jpeg' : format}`,
        quality: format === 'png' ? 1.0 : imageQuality
      });
      
      images.push({
        pageNumber: i,
        width: viewport.width,
        height: viewport.height,
        dataUrl: await blobToArrayBuffer(blob),
        size: blob.size
      });
    }
    
    return {
      success: true,
      images,
      format,
      totalPages: numPages
    };
  } catch (error) {
    console.error('Errore durante la conversione in immagini:', error);
    throw error;
  }
}

// Comprime un PDF
async function compressPDF(pdfData, options) {
  try {
    const { quality = 'medium' } = options;
    
    // Carica il PDF con pdf-lib
    const pdfDoc = await PDFLib.PDFDocument.load(pdfData);
    
    // Impostazioni di compressione in base alla qualità
    let compressionOptions = {};
    
    switch (quality) {
      case 'low':
        compressionOptions = {
          useObjectStreams: true,
          addDefaultPage: false,
          objectCompressionLevel: 9
        };
        break;
      case 'medium':
        compressionOptions = {
          useObjectStreams: true,
          addDefaultPage: false,
          objectCompressionLevel: 7
        };
        break;
      case 'high':
        compressionOptions = {
          useObjectStreams: true,
          addDefaultPage: false,
          objectCompressionLevel: 5
        };
        break;
      default:
        compressionOptions = {
          useObjectStreams: true,
          addDefaultPage: false,
          objectCompressionLevel: 7
        };
    }
    
    // Applica la compressione
    const compressedPdfBytes = await pdfDoc.save(compressionOptions);
    
    return {
      success: true,
      data: compressedPdfBytes,
      originalSize: pdfData.byteLength,
      compressedSize: compressedPdfBytes.length,
      compressionRate: Math.round((1 - (compressedPdfBytes.length / pdfData.byteLength)) * 100)
    };
  } catch (error) {
    console.error('Errore durante la compressione del PDF:', error);
    throw error;
  }
}

// Divide un PDF in più file
async function splitPDF(pdfData, options) {
  try {
    const { pageRanges = [] } = options;
    
    // Carica il PDF con pdf-lib
    const pdfDoc = await PDFLib.PDFDocument.load(pdfData);
    const numPages = pdfDoc.getPageCount();
    
    // Se non sono specificate le pagine, dividi ogni pagina in un file separato
    const ranges = pageRanges.length > 0 ? pageRanges : Array.from({ length: numPages }, (_, i) => ({ start: i + 1, end: i + 1 }));
    
    const splitFiles = [];
    
    for (let i = 0; i < ranges.length; i++) {
      const range = ranges[i];
      const start = Math.max(1, range.start);
      const end = Math.min(numPages, range.end);
      
      // Crea un nuovo documento PDF
      const newPdf = await PDFLib.PDFDocument.create();
      
      // Copia le pagine dal PDF originale
      for (let j = start - 1; j < end; j++) {
        const [copiedPage] = await newPdf.copyPages(pdfDoc, [j]);
        newPdf.addPage(copiedPage);
      }
      
      // Salva il nuovo PDF
      const newPdfBytes = await newPdf.save();
      
      splitFiles.push({
        data: newPdfBytes,
        name: `split_${i + 1}.pdf`,
        range: `${start}-${end}`,
        size: newPdfBytes.length
      });
    }
    
    return {
      success: true,
      files: splitFiles,
      totalFiles: splitFiles.length
    };
  } catch (error) {
    console.error('Errore durante la divisione del PDF:', error);
    throw error;
  }
}

// Unisce più PDF
async function mergePDFs(pdfDataArray, options) {
  try {
    // Crea un nuovo documento PDF
    const mergedPdf = await PDFLib.PDFDocument.create();
    
    // Unisci tutti i PDF
    for (const pdfData of pdfDataArray) {
      const pdf = await PDFLib.PDFDocument.load(pdfData);
      const copiedPages = await mergedPdf.copyPages(pdf, pdf.getPageIndices());
      copiedPages.forEach(page => mergedPdf.addPage(page));
    }
    
    // Salva il PDF unito
    const mergedPdfBytes = await mergedPdf.save();
    
    return {
      success: true,
      data: mergedPdfBytes,
      size: mergedPdfBytes.length
    };
  } catch (error) {
    console.error('Errore durante l\'unione dei PDF:', error);
    throw error;
  }
}

// Protegge un PDF con password
async function protectPDF(pdfData, options) {
  try {
    const { password, permissions = {} } = options;
    
    if (!password) {
      throw new Error('Password non specificata');
    }
    
    // Carica il PDF con pdf-lib
    const pdfDoc = await PDFLib.PDFDocument.load(pdfData);
    
    // Imposta le impostazioni di protezione predefinite
    const encryptOptions = {
      userPassword: password,
      ownerPassword: password,
      permissions: {
        printing: permissions.printing !== false ? 'highResolution' : 'none',
        modifying: permissions.modifying !== false,
        copying: permissions.copying !== false,
        annotating: permissions.annotating !== false,
        fillingForms: permissions.fillingForms !== false,
        contentAccessibility: permissions.contentAccessibility !== false,
        documentAssembly: permissions.documentAssembly !== false
      }
    };
    
    // Applica la protezione
    pdfDoc.encrypt(encryptOptions);
    
    // Salva il PDF protetto
    const protectedPdfBytes = await pdfDoc.save();
    
    return {
      success: true,
      data: protectedPdfBytes,
      size: protectedPdfBytes.length
    };
  } catch (error) {
    console.error('Errore durante la protezione del PDF:', error);
    throw error;
  }
}
