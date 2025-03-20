// StrumentiRapidi.it PDF Worker Module
// Fixed implementation using classic worker mode with importScripts

// This worker is intentionally NOT a module to allow importScripts usage
// Load required libraries
importScripts('https://cdnjs.cloudflare.com/ajax/libs/pdf.js/3.11.174/pdf.min.js');
importScripts('https://cdnjs.cloudflare.com/ajax/libs/pdf.js/3.11.174/pdf.worker.min.js');
importScripts('https://unpkg.com/pdf-lib@1.17.1/dist/pdf-lib.min.js');

// Initialize PDF.js
var pdfjsLib = self.pdfjsLib;
pdfjsLib.GlobalWorkerOptions.workerSrc = 'https://cdnjs.cloudflare.com/ajax/libs/pdf.js/3.11.174/pdf.worker.min.js';

// Get PDF-lib references
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

/**
 * Extracts text content from PDF
 */
async function handleExtractText(fileData, options) {
  try {
    // Load the PDF document
    const loadingTask = pdfjsLib.getDocument({ data: new Uint8Array(fileData) });
    const pdfDocument = await loadingTask.promise;
    const numPages = pdfDocument.numPages;
    
    // Determine which pages to extract
    let pagesToExtract = [];
    if (options.pageRange === 'custom' && options.customPages) {
      pagesToExtract = parsePageRanges(options.customPages, numPages);
    } else {
      // All pages
      pagesToExtract = Array.from({ length: numPages }, (_, i) => i + 1);
    }
    
    // Extract text from selected pages
    const pages = [];
    let fullText = '';
    
    // Configuration for text extraction
    const preserveFormatting = options.preserveFormatting !== false;
    
    // Process each page
    for (const pageNum of pagesToExtract) {
      try {
        const page = await pdfDocument.getPage(pageNum);
        
        // Get text content with proper parameters
        const textContent = await page.getTextContent({
          normalizeWhitespace: !preserveFormatting,
          disableCombineTextItems: preserveFormatting
        });
        
        // Process text items
        let pageText = '';
        
        if (preserveFormatting) {
          // More sophisticated text extraction with layout preservation
          const items = textContent.items;
          const lastY = {};
          
          for (let i = 0; i < items.length; i++) {
            const item = items[i];
            const str = item.str;
            const x = item.transform[4];
            const y = item.transform[5];
            
            if (lastY[y] !== undefined) {
              // Same line
              pageText += str;
            } else {
              // New line
              if (i > 0) pageText += '\n';
              pageText += str;
            }
            
            lastY[y] = x + item.width;
          }
        } else {
          // Simple text extraction
          pageText = textContent.items
            .map(item => item.str)
            .join(' ')
            .replace(/\s+/g, ' ');
        }
        
        // Add page info
        pages.push({
          pageNumber: pageNum,
          text: pageText.trim()
        });
        
        fullText += pageText.trim() + '\n\n';
      } catch (error) {
        console.error(`Error extracting text from page ${pageNum}:`, error);
      }
    }
    
    return {
      success: true,
      pages,
      fullText: fullText.trim(),
      totalPages: numPages,
      extractedPages: pages.length
    };
  } catch (error) {
    console.error('Error in text extraction:', error);
    throw error;
  }
}

/**
 * Compresses a PDF document
 */
async function handleCompressPDF(fileData, options) {
  try {
    // Get original size
    const originalSize = fileData.byteLength;
    
    // Create a new PDF document
    const pdfBytes = new Uint8Array(fileData);
    const pdfDoc = await PDFDocument.load(pdfBytes);
    
    // Save with compression options
    let compressedPdfBytes;
    
    // Adjust compression level based on quality setting
    if (options.quality === 'low') {
      // Maximum compression
      compressedPdfBytes = await pdfDoc.save({
        useObjectStreams: true,
        addDefaultPage: false,
        updateFieldAppearances: false
      });
    } else if (options.quality === 'medium') {
      // Balanced compression
      compressedPdfBytes = await pdfDoc.save({
        useObjectStreams: true,
        addDefaultPage: false
      });
    } else {
      // Light compression
      compressedPdfBytes = await pdfDoc.save();
    }
    
    // Calculate compression results
    const compressedSize = compressedPdfBytes.length;
    const compressionRate = Math.round((1 - (compressedSize / originalSize)) * 100);
    
    return {
      success: true,
      data: compressedPdfBytes.buffer,
      originalSize,
      compressedSize,
      compressionRate: Math.max(0, compressionRate) // Ensure non-negative
    };
  } catch (error) {
    console.error('Error in PDF compression:', error);
    throw error;
  }
}

/**
 * Protects a PDF with password
 */
async function handleProtectPDF(fileData, options) {
  try {
    if (!options.password) {
      throw new Error('Password is required');
    }
    
    // Load the PDF document
    const pdfBytes = new Uint8Array(fileData);
    const pdfDoc = await PDFDocument.load(pdfBytes);
    
    // Set up permissions
    const permissions = {
      printing: 'highResolution',
      modifying: false,
      copying: true,
      annotating: false,
      fillingForms: true,
      contentAccessibility: true,
      documentAssembly: false
    };
    
    // Apply custom permissions if provided
    if (options.permissions) {
      if (options.permissions.printing !== undefined) {
        permissions.printing = options.permissions.printing ? 'highResolution' : 'none';
      }
      
      if (options.permissions.copying !== undefined) {
        permissions.copying = options.permissions.copying;
      }
      
      if (options.permissions.modifying !== undefined) {
        permissions.modifying = options.permissions.modifying;
        permissions.annotating = options.permissions.modifying;
        permissions.fillingForms = options.permissions.modifying;
        permissions.documentAssembly = options.permissions.modifying;
      }
    }
    
    // Encrypt the document
    pdfDoc.encrypt({
      userPassword: options.password,
      ownerPassword: options.password + '_owner',
      permissions
    });
    
    // Save the protected PDF
    const protectedPdfBytes = await pdfDoc.save();
    
    return {
      success: true,
      data: protectedPdfBytes.buffer,
      size: protectedPdfBytes.length,
      isProtected: true,
      permissions: options.permissions || {}
    };
  } catch (error) {
    console.error('Error in PDF protection:', error);
    throw error;
  }
}

/**
 * Splits a PDF into multiple files
 */
async function handleSplitPDF(fileData, options) {
  try {
    // Load the PDF document
    const pdfBytes = new Uint8Array(fileData);
    const sourcePdfDoc = await PDFDocument.load(pdfBytes);
    const totalPages = sourcePdfDoc.getPageCount();
    
    // Determine the page ranges to split
    let pageRanges = [];
    
    if (options.pageRange === 'custom' && options.customPages) {
      // Parse ranges like "1-5,8,11-13"
      const customRanges = options.customPages.split(',');
      
      for (const range of customRanges) {
        const trimmed = range.trim();
        if (trimmed.includes('-')) {
          const [startStr, endStr] = trimmed.split('-');
          const start = parseInt(startStr.trim());
          const end = parseInt(endStr.trim());
          
          if (!isNaN(start) && !isNaN(end) && start > 0 && end <= totalPages && start <= end) {
            pageRanges.push({ start, end });
          }
        } else {
          const pageNum = parseInt(trimmed);
          if (!isNaN(pageNum) && pageNum > 0 && pageNum <= totalPages) {
            pageRanges.push({ start: pageNum, end: pageNum });
          }
        }
      }
    } else {
      // Split into individual pages
      for (let i = 1; i <= totalPages; i++) {
        pageRanges.push({ start: i, end: i });
      }
    }
    
    // Process each range
    const files = [];
    
    for (const range of pageRanges) {
      try {
        // Create a new document for this range
        const newPdfDoc = await PDFDocument.create();
        
        // Add pages from the range (adjusting for 0-based index)
        const pageIndexes = [];
        for (let i = range.start - 1; i < range.end; i++) {
          pageIndexes.push(i);
        }
        
        // Copy the pages
        const copiedPages = await newPdfDoc.copyPages(sourcePdfDoc, pageIndexes);
        
        // Add each copied page
        for (const page of copiedPages) {
          newPdfDoc.addPage(page);
        }
        
        // Save the new PDF
        const newPdfBytes = await newPdfDoc.save();
        
        // Add to result
        files.push({
          name: `split_${range.start}${range.end !== range.start ? `-${range.end}` : ''}.pdf`,
          data: newPdfBytes.buffer,
          range: `${range.start}-${range.end}`,
          size: newPdfBytes.length
        });
      } catch (error) {
        console.error(`Error processing page range ${range.start}-${range.end}:`, error);
      }
    }
    
    return {
      success: true,
      files,
      totalFiles: files.length
    };
  } catch (error) {
    console.error('Error in PDF splitting:', error);
    throw error;
  }
}

/**
 * Merges multiple PDF documents
 */
async function handleMergePDFs(filesData, options) {
  try {
    if (!Array.isArray(filesData) || filesData.length === 0) {
      throw new Error('No PDF files provided for merging');
    }
    
    // Create a new document for the merged PDF
    const mergedPdfDoc = await PDFDocument.create();
    
    // Track total pages
    let totalPages = 0;
    
    // Process each PDF file
    for (let i = 0; i < filesData.length; i++) {
      const fileData = filesData[i];
      
      try {
        // Load the PDF document
        const pdfBytes = new Uint8Array(fileData);
        const sourcePdfDoc = await PDFDocument.load(pdfBytes);
        
        // Get all pages from this document
        const pageCount = sourcePdfDoc.getPageCount();
        const pageIndexes = Array.from({ length: pageCount }, (_, i) => i);
        
        // Copy all pages
        const copiedPages = await mergedPdfDoc.copyPages(sourcePdfDoc, pageIndexes);
        
        // Add all copied pages to the merged document
        for (const page of copiedPages) {
          mergedPdfDoc.addPage(page);
        }
        
        // Update total pages count
        totalPages += pageCount;
      } catch (error) {
        console.error(`Error processing PDF ${i + 1}:`, error);
        // Continue with other files
      }
    }
    
    // Save the merged PDF
    const mergedPdfBytes = await mergedPdfDoc.save();
    
    return {
      success: true,
      data: mergedPdfBytes.buffer,
      size: mergedPdfBytes.length,
      pageCount: totalPages,
      totalMergedFiles: filesData.length
    };
  } catch (error) {
    console.error('Error in PDF merging:', error);
    throw error;
  }
}
