// StrumentiRapidi.it PDF Worker Module
// Fixed implementation using classic worker mode with importScripts

// This worker is intentionally NOT a module to allow importScripts usage
// Load required libraries
importScripts('https://cdnjs.cloudflare.com/ajax/libs/pdf.js/3.11.174/pdf.min.js');
importScripts('https://cdnjs.cloudflare.com/ajax/libs/pdf.js/3.11.174/pdf.worker.min.js');
importScripts('https://unpkg.com/pdf-lib@1.17.1/dist/pdf-lib.min.js');

// Initialize PDF.js
var pdfjsLib = self.pdfjsLib;

// Check if we're in a worker context (no window object) and use self instead
if (typeof self !== 'undefined') {
  // Worker context - use worker-specific initialization
  pdfjsLib.GlobalWorkerOptions.workerSrc = 'https://cdnjs.cloudflare.com/ajax/libs/pdf.js/3.11.174/pdf.worker.min.js';
} else {
  console.error("Neither window nor self is defined. PDF.js initialization failed.");
}

// Get PDF-lib references from the global self object in the worker
var PDFLib = self.PDFLib;
var PDFDocument = PDFLib.PDFDocument;
var StandardFonts = PDFLib.StandardFonts;
var rgb = PDFLib.rgb;

// Set up error handling
self.onerror = function(message, source, lineno, colno, error) {
  console.error('Worker error:', message, 'at', source, lineno, colno, error);
  self.postMessage({
    status: 'error',
    error: message,
    source: source,
    lineno: lineno
  });
  return true; // Prevent default handling
};

// Rest of the worker code remains the same
// Listen for messages from the main thread
self.onmessage = async function(e) {
  const { task, fileData, options, taskId } = e.data;
  
  try {
    let result;
    
    // Process based on the requested task
    switch (task) {
      case 'convertToImages':
        result = await handleConvertToImages(fileData, options);
        break;
        
      case 'extractText':
        result = await handleExtractText(fileData, options);
        break;
        
      case 'compressPDF':
        result = await handleCompressPDF(fileData, options);
        break;
        
      case 'protectPDF':
        result = await handleProtectPDF(fileData, options);
        break;
        
      case 'splitPDF':
        result = await handleSplitPDF(fileData, options);
        break;
        
      case 'mergePDFs':
        result = await handleMergePDFs(fileData, options);
        break;
        
      default:
        throw new Error(`Unknown task: ${task}`);
    }
    
    // Send successful result back to main thread
    self.postMessage({
      status: 'success',
      taskId,
      result
    });
  } catch (error) {
    // Log error details
    console.error(`Worker error in task ${task}:`, error);
    
    // Send error back to main thread
    self.postMessage({
      status: 'error',
      taskId,
      error: error.message || 'An unknown error occurred'
    });
  }
};

/**
 * Converts PDF pages to images
 */
async function handleConvertToImages(fileData, options) {
  // Load the PDF document
  const loadingTask = pdfjsLib.getDocument({ data: new Uint8Array(fileData) });
  const pdfDocument = await loadingTask.promise;
  const numPages = pdfDocument.numPages;
  
  // Get format and quality settings
  const format = options.format || 'png';
  const quality = options.quality === 'low' ? 0.6 : 
                 options.quality === 'medium' ? 0.8 : 0.95;
  
  // Calculate DPI scaling (default 150 DPI)
  const dpi = parseInt(options.dpi) || 150;
  const scale = dpi / 72; // PDF points to pixels conversion
  
  // Process pages
  const pagesToProcess = options.pageRange === 'custom' && options.customPages 
    ? parsePageRanges(options.customPages, numPages)
    : Array.from({ length: numPages }, (_, i) => i + 1);
  
  // Create a canvas for rendering
  const canvas = new OffscreenCanvas(1, 1);
  const ctx = canvas.getContext('2d');
  
  // Process each page
  const images = [];
  for (const pageNum of pagesToProcess) {
    try {
      // Get the page
      const page = await pdfDocument.getPage(pageNum);
      
      // Get the viewport at the desired scale
      const viewport = page.getViewport({ scale });
      
      // Set canvas dimensions
      canvas.width = Math.floor(viewport.width);
      canvas.height = Math.floor(viewport.height);
      
      // Render the page
      const renderContext = {
        canvasContext: ctx,
        viewport: viewport
      };
      
      // Wait for rendering to complete
      await page.render(renderContext).promise;
      
      // Convert to data URL with the desired format
      let dataUrl;
      if (format === 'jpg' || format === 'jpeg') {
        dataUrl = canvas.toDataURL('image/jpeg', quality);
      } else {
        dataUrl = canvas.toDataURL('image/png');
      }
      
      // Add to the results array
      images.push({
        pageNumber: pageNum,
        width: canvas.width,
        height: canvas.height,
        dataUrl: dataUrl,
        size: Math.round(dataUrl.length * 0.75) // Estimate size
      });
    } catch (error) {
      console.error(`Error processing page ${pageNum}:`, error);
    }
  }
  
  return {
    success: true,
    images,
    format,
    totalPages: numPages,
    processedPages: images.length
  };
}

/**
 * Parses page ranges like "1-5,8,11-13" into an array of page numbers
 */
function parsePageRanges(rangeStr, totalPages) {
  const result = [];
  const ranges = rangeStr.split(',');
  
  for (const range of ranges) {
    const trimmed = range.trim();
    if (trimmed.includes('-')) {
      const [startStr, endStr] = trimmed.split('-');
      const start = parseInt(startStr.trim());
      const end = parseInt(endStr.trim());
      
      if (!isNaN(start) && !isNaN(end) && start > 0 && end <= totalPages) {
        for (let i = start; i <= end; i++) {
          if (!result.includes(i)) {
            result.push(i);
          }
        }
      }
    } else {
      const pageNum = parseInt(trimmed);
      if (!isNaN(pageNum) && pageNum > 0 && pageNum <= totalPages && !result.includes(pageNum)) {
        result.push(pageNum);
      }
    }
  }
  
  return result.sort((a, b) => a - b);
}

/* 
 * The rest of the PDF worker functions follow below.
 * They remain unchanged but would be included in the full worker file.
 */
