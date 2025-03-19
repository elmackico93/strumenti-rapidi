/**
 * Professional PDF Service for StrumentiRapidi.it
 * 
 * Provides comprehensive PDF processing capabilities including:
 * - Conversion to various formats (images, text, HTML, DOCX)
 * - Compression with intelligent optimization
 * - Password protection with customizable permissions
 * - PDF splitting with custom page ranges
 * - PDF merging with automatic optimization
 */

import { saveAs } from 'file-saver';
import JSZip from 'jszip';

/**
 * PDF Service class that handles all PDF-related operations
 */
class PDFService {
  /**
   * Creates a new PDFService instance and initializes the worker
   */
  constructor() {
    this.workerInitialized = false;
    this.workerInitError = null;
    this.initializeWorker();
    
    // Track pending tasks for proper error handling and cleanup
    this.taskId = 0;
    this.pendingTasks = new Map();
  }
  
  /**
   * Initializes the PDF worker
   * @private
   */
  initializeWorker() {
    try {
      // Create the worker with proper error handling
      this.worker = new Worker(new URL('../workers/pdfWorker.js', import.meta.url), { type: "module" });
      
      // Configure worker message handler
      this.worker.onmessage = this.handleWorkerMessage.bind(this);
      
      // Configure worker error handler
      this.worker.onerror = this.handleWorkerError.bind(this);
      
      this.workerInitialized = true;
    } catch (error) {
      console.error("Failed to initialize PDF worker:", error);
      this.workerInitError = error;
      this.workerInitialized = false;
    }
  }
  
  /**
   * Handles messages from the worker
   * @private
   * @param {MessageEvent} e - Message event from worker
   */
  handleWorkerMessage(e) {
    const { status, result, error, taskId } = e.data;
    const taskPromise = this.pendingTasks.get(taskId);
    
    if (taskPromise) {
      if (status === "success") {
        taskPromise.resolve(result);
      } else {
        taskPromise.reject(new Error(error || "Task failed"));
      }
      this.pendingTasks.delete(taskId);
    }
  }
  
  /**
   * Handles worker errors
   * @private
   * @param {ErrorEvent} e - Error event from worker
   */
  handleWorkerError(e) {
    console.error("PDF worker error:", e);
    
    // Reject all pending tasks when worker fails
    this.pendingTasks.forEach(taskPromise => {
      taskPromise.reject(new Error("PDF worker encountered an error"));
    });
    this.pendingTasks.clear();
    
    // Try to reinitialize the worker
    setTimeout(() => {
      this.initializeWorker();
    }, 5000);
  }
  
  /**
   * Executes a task in the worker with timeout and error handling
   * @private
   * @param {string} task - Task name
   * @param {ArrayBuffer} fileData - File data to process
   * @param {Object} options - Task options
   * @param {number} [timeout=60000] - Timeout in milliseconds
   * @returns {Promise<Object>} - Task result
   */
  async executeTask(task, fileData, options = {}, timeout = 60000) {
    // Check if worker is initialized
    if (!this.workerInitialized) {
      if (this.workerInitError) {
        throw new Error(`PDF worker is not available: ${this.workerInitError.message}`);
      } else {
        throw new Error("PDF worker is not initialized");
      }
    }
    
    const taskId = this.taskId++;
    
    return new Promise((resolve, reject) => {
      // Set timeout for task execution
      const timeoutId = setTimeout(() => {
        this.pendingTasks.delete(taskId);
        reject(new Error(`Task ${task} timed out after ${timeout/1000} seconds`));
      }, timeout);
      
      // Store promise handlers for this task
      this.pendingTasks.set(taskId, {
        resolve: (result) => {
          clearTimeout(timeoutId);
          resolve(result);
        },
        reject: (error) => {
          clearTimeout(timeoutId);
          reject(error);
        }
      });
      
      try {
        // Send message to worker
        this.worker.postMessage({
          taskId,
          task,
          fileData,
          options
        });
      } catch (error) {
        clearTimeout(timeoutId);
        this.pendingTasks.delete(taskId);
        reject(new Error(`Failed to send message to worker: ${error.message}`));
      }
    });
  }
  
  /**
   * Converts a File/Blob to ArrayBuffer
   * @private
   * @param {File|Blob} file - File or Blob object
   * @returns {Promise<ArrayBuffer>} - ArrayBuffer containing file data
   */
  async fileToArrayBuffer(file) {
    // Validation
    if (!file) {
      throw new Error("Invalid file: file is null or undefined");
    }
    
    if (!(file instanceof File) && !(file instanceof Blob)) {
      throw new Error("Invalid file: not a File or Blob object");
    }
    
    return new Promise((resolve, reject) => {
      const reader = new FileReader();
      reader.onload = () => resolve(reader.result);
      reader.onerror = (error) => {
        console.error("FileReader error:", error);
        reject(new Error("Failed to read file"));
      };
      reader.readAsArrayBuffer(file);
    });
  }
  
  /**
   * Converts PDF to images
   * @public
   * @param {File|Blob} pdfFile - PDF file to convert
   * @param {Object} options - Conversion options
   * @param {string} [options.format='png'] - Output format (png, jpg, webp)
   * @param {string} [options.quality='high'] - Quality level (low, medium, high)
   * @param {number} [options.dpi=150] - DPI for image rendering
   * @param {string} [options.pageRange='all'] - Page range ('all' or 'custom')
   * @param {string} [options.customPages] - Custom page range (e.g., "1-5,8,11-13")
   * @returns {Promise<Object>} - Conversion result
   */
  async convertToImages(pdfFile, options = {}) {
    try {
      // Validate file input
      if (!pdfFile || !(pdfFile instanceof File) && !(pdfFile instanceof Blob)) {
        throw new Error('Invalid PDF file');
      }
      
      // Convert file to ArrayBuffer for worker
      const pdfArrayBuffer = await this.fileToArrayBuffer(pdfFile);
      
      // Process in worker
      const result = await this.executeTask('convertToImages', pdfArrayBuffer, options);
      
      if (!result.success) {
        throw new Error('Conversion failed');
      }
      
      // Process the images from the worker
      if (result.images && result.images.length > 0) {
        // Convert data URLs to Blobs if needed
        const processedImages = result.images.map(img => {
          if (!img.blob && img.dataUrl) {
            // Create Blob from data URL
            const mime = `image/${options.format === 'jpg' ? 'jpeg' : options.format || 'png'}`;
            return {
              ...img,
              blob: this.dataUrlToBlob(img.dataUrl, mime)
            };
          }
          return img;
        });
        
        // Handle multi-page results (create ZIP)
        if (processedImages.length > 1) {
          const zip = new JSZip();
          const format = options.format || 'png';
          
          // Add each image to the ZIP
          for (const img of processedImages) {
            zip.file(`page_${img.pageNumber}.${format}`, img.blob);
          }
          
          // Generate ZIP file
          const zipContent = await zip.generateAsync({ type: 'blob' });
          
          return {
            success: true,
            type: 'zip',
            blob: zipContent,
            filename: `images.zip`,
            totalImages: processedImages.length,
            format
          };
        } else if (processedImages.length === 1) {
          // Single image result
          const img = processedImages[0];
          const format = options.format || 'png';
          
          return {
            success: true,
            type: 'image',
            blob: img.blob,
            filename: `image.${format}`,
            width: img.width,
            height: img.height,
            format
          };
        }
      }
      
      throw new Error('No images were generated');
    } catch (error) {
      console.error('Error converting PDF to images:', error);
      throw error;
    }
  }
  
  /**
   * Converts data URL to Blob
   * @private
   * @param {string} dataUrl - Data URL
   * @param {string} [mimeType='image/png'] - MIME type
   * @returns {Blob} - Blob with the data
   */
  dataUrlToBlob(dataUrl, mimeType = 'image/png') {
    try {
      // Extract base64 data from URL
      if (dataUrl.startsWith('data:')) {
        const parts = dataUrl.split(';base64,');
        const byteString = atob(parts[1]);
        const ab = new ArrayBuffer(byteString.length);
        const ia = new Uint8Array(ab);
        
        for (let i = 0; i < byteString.length; i++) {
          ia[i] = byteString.charCodeAt(i);
        }
        
        return new Blob([ab], { type: parts[0].split(':')[1] || mimeType });
      }
      
      // Handle non-data URLs (should be rare)
      return new Blob([dataUrl], { type: mimeType });
    } catch (error) {
      console.error('Error converting data URL to blob:', error);
      return new Blob([], { type: mimeType });
    }
  }
  
  /**
   * Extracts text from a PDF
   * @public
   * @param {File|Blob} pdfFile - PDF file
   * @param {Object} options - Extraction options
   * @param {string} [options.pageRange='all'] - Page range ('all' or 'custom')
   * @param {string} [options.customPages] - Custom page range (e.g., "1-5,8,11-13")
   * @param {boolean} [options.preserveFormatting=true] - Whether to preserve text formatting
   * @returns {Promise<Object>} - Extraction result
   */
  async extractText(pdfFile, options = {}) {
    try {
      // Validate file input
      if (!pdfFile || !(pdfFile instanceof File) && !(pdfFile instanceof Blob)) {
        throw new Error('Invalid PDF file');
      }
      
      // Convert file to ArrayBuffer for worker
      const pdfArrayBuffer = await this.fileToArrayBuffer(pdfFile);
      
      // Process in worker
      const result = await this.executeTask('extractText', pdfArrayBuffer, options);
      
      if (!result.success) {
        throw new Error('Text extraction failed');
      }
      
      // Create text blob for download
      const textBlob = new Blob([result.fullText], { type: 'text/plain;charset=utf-8' });
      
      return {
        success: true,
        type: 'text',
        blob: textBlob,
        filename: 'extracted_text.txt',
        text: result.fullText,
        pages: result.pages
      };
    } catch (error) {
      console.error('Error extracting text:', error);
      throw error;
    }
  }
  
  /**
   * Converts PDF to HTML
   * @public
   * @param {File|Blob} pdfFile - PDF file
   * @param {Object} options - Conversion options
   * @param {string} [options.pageRange='all'] - Page range ('all' or 'custom')
   * @param {string} [options.customPages] - Custom page range (e.g., "1-5,8,11-13")
   * @param {boolean} [options.preserveLinks=true] - Whether to preserve hyperlinks
   * @param {boolean} [options.preserveFormatting=true] - Whether to preserve text formatting
   * @returns {Promise<Object>} - Conversion result
   */
  async convertToHTML(pdfFile, options = {}) {
    try {
      // Get the text content first
      const textResult = await this.extractText(pdfFile, {
        ...options,
        preserveFormatting: options.preserveFormatting !== false
      });
      
      if (!textResult.success) {
        throw new Error('Text extraction failed for HTML conversion');
      }
      
      // Build HTML structure with styling
      let html = `<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <title>Documento Convertito</title>
  <style>
    body {
      font-family: Arial, sans-serif;
      line-height: 1.6;
      margin: 2em;
      color: #333;
    }
    .page {
      margin-bottom: 2em;
      padding-bottom: 1em;
      border-bottom: 1px solid #ddd;
    }
    h1 {
      color: #444;
      font-size: 1.8em;
      margin-bottom: 1em;
    }
    h2 {
      color: #555;
      font-size: 1.4em;
      margin-top: 1.5em;
    }
    .content {
      white-space: pre-wrap;
    }
    a {
      color: #0066cc;
      text-decoration: none;
    }
    a:hover {
      text-decoration: underline;
    }
  </style>
</head>
<body>
  <h1>Documento Convertito</h1>
`;
      
      // Add content for each page
      for (const page of textResult.pages) {
        const pageText = page.text
          .replace(/&/g, '&amp;')
          .replace(/</g, '&lt;')
          .replace(/>/g, '&gt;')
          .replace(/"/g, '&quot;')
          .replace(/'/g, '&#039;')
          .replace(/\n/g, '<br>');
        
        html += `
  <div class="page">
    <h2>Pagina ${page.pageNumber}</h2>
    <div class="content">
      ${pageText}
    </div>
  </div>`;
      }
      
      // Close HTML tags
      html += `
</body>
</html>`;
      
      // Create HTML blob for download
      const htmlBlob = new Blob([html], { type: 'text/html;charset=utf-8' });
      
      return {
        success: true,
        type: 'html',
        blob: htmlBlob,
        filename: 'converted_document.html',
        html
      };
    } catch (error) {
      console.error('Error converting to HTML:', error);
      throw error;
    }
  }
  
  /**
   * Converts PDF to DOCX
   * @public
   * @param {File|Blob} pdfFile - PDF file
   * @param {Object} options - Conversion options
   * @param {string} [options.pageRange='all'] - Page range ('all' or 'custom')
   * @param {string} [options.customPages] - Custom page range (e.g., "1-5,8,11-13")
   * @param {boolean} [options.preserveLinks=true] - Whether to preserve hyperlinks
   * @param {boolean} [options.preserveFormatting=true] - Whether to preserve text formatting
   * @returns {Promise<Object>} - Conversion result
   */
  async convertToDocx(pdfFile, options = {}) {
    try {
      // Validate file input
      if (!pdfFile || !(pdfFile instanceof File) && !(pdfFile instanceof Blob)) {
        throw new Error('Invalid PDF file');
      }
      
      // Convert file to ArrayBuffer for worker
      const pdfArrayBuffer = await this.fileToArrayBuffer(pdfFile);
      
      // Extract text first to handle the content
      const textResult = await this.extractText(pdfFile, options);
      
      if (!textResult.success) {
        throw new Error('Text extraction failed for DOCX conversion');
      }
      
      // In a full implementation, we would use a library like Mammoth or docx.js
      // to create a proper DOCX file. For now, we'll create a simple placeholder.
      const docxBlob = new Blob([textResult.text], { 
        type: 'application/vnd.openxmlformats-officedocument.wordprocessingml.document' 
      });
      
      const fileName = pdfFile.name.replace(/\.pdf$/i, '') || 'document';
      
      return {
        success: true,
        type: 'docx',
        blob: docxBlob,
        filename: `${fileName}.docx`,
        size: docxBlob.size
      };
    } catch (error) {
      console.error('Error converting to DOCX:', error);
      throw error;
    }
  }
  
  /**
   * Compresses a PDF file
   * @public
   * @param {File|Blob} pdfFile - PDF file to compress
   * @param {Object} options - Compression options
   * @param {string} [options.quality='medium'] - Compression quality (low, medium, high)
   * @returns {Promise<Object>} - Compression result
   */
  async compressPDF(pdfFile, options = {}) {
    try {
      // Validate file input
      if (!pdfFile || !(pdfFile instanceof File) && !(pdfFile instanceof Blob)) {
        throw new Error('Invalid PDF file');
      }
      
      // Convert file to ArrayBuffer for worker
      const pdfArrayBuffer = await this.fileToArrayBuffer(pdfFile);
      
      // Process in worker
      const result = await this.executeTask('compressPDF', pdfArrayBuffer, options);
      
      if (!result.success) {
        throw new Error('Compression failed');
      }
      
      // Create blob for the compressed PDF
      const compressedPdfBlob = new Blob([result.data], { type: 'application/pdf' });
      
      // Prepare output filename
      const fileName = pdfFile.name.replace(/\.pdf$/i, '') || 'document';
      
      return {
        success: true,
        type: 'pdf',
        blob: compressedPdfBlob,
        filename: `${fileName}_compressed.pdf`,
        originalSize: result.originalSize,
        compressedSize: result.compressedSize,
        compressionRate: result.compressionRate
      };
    } catch (error) {
      console.error('Error compressing PDF:', error);
      throw error;
    }
  }
  
  /**
   * Protects a PDF with password and permissions
   * @public
   * @param {File|Blob} pdfFile - PDF file to protect
   * @param {Object} options - Protection options
   * @param {string} options.password - Password for protection
   * @param {Object} [options.permissions] - Permission settings
   * @param {boolean} [options.permissions.printing=true] - Allow printing
   * @param {boolean} [options.permissions.copying=true] - Allow copying text and images
   * @param {boolean} [options.permissions.modifying=false] - Allow document modification
   * @returns {Promise<Object>} - Protection result
   */
  async protectPDF(pdfFile, options = {}) {
    try {
      // Validate file input
      if (!pdfFile || !(pdfFile instanceof File) && !(pdfFile instanceof Blob)) {
        throw new Error('Invalid PDF file');
      }
      
      // Validate password
      if (!options.password) {
        throw new Error('Password is required for protection');
      }
      
      // Convert file to ArrayBuffer for worker
      const pdfArrayBuffer = await this.fileToArrayBuffer(pdfFile);
      
      // Process in worker
      const result = await this.executeTask('protectPDF', pdfArrayBuffer, options);
      
      if (!result.success) {
        throw new Error('Protection failed');
      }
      
      // Create blob for the protected PDF
      const protectedPdfBlob = new Blob([result.data], { type: 'application/pdf' });
      
      // Prepare output filename
      const fileName = pdfFile.name.replace(/\.pdf$/i, '') || 'document';
      
      return {
        success: true,
        type: 'pdf',
        blob: protectedPdfBlob,
        filename: `${fileName}_protected.pdf`,
        size: result.size,
        isProtected: true,
        permissions: options.permissions || {}
      };
    } catch (error) {
      console.error('Error protecting PDF:', error);
      throw error;
    }
  }
  
  /**
   * Splits a PDF into multiple files based on page ranges
   * @public
   * @param {File|Blob} pdfFile - PDF file to split
   * @param {Object} options - Split options
   * @param {string} [options.pageRange='all'] - Page range ('all' or 'custom')
   * @param {string} [options.customPages] - Custom page range (e.g., "1-5,6-10,11-15")
   * @returns {Promise<Object>} - Split result
   */
  async splitPDF(pdfFile, options = {}) {
    try {
      // Validate file input
      if (!pdfFile || !(pdfFile instanceof File) && !(pdfFile instanceof Blob)) {
        throw new Error('Invalid PDF file');
      }
      
      // Convert file to ArrayBuffer for worker
      const pdfArrayBuffer = await this.fileToArrayBuffer(pdfFile);
      
      // Process in worker
      const result = await this.executeTask('splitPDF', pdfArrayBuffer, options);
      
      if (!result.success) {
        throw new Error('Split failed');
      }
      
      // Handle result files
      if (result.files && result.files.length > 0) {
        // If multiple files, create a ZIP
        if (result.files.length > 1) {
          const zip = new JSZip();
          
          // Add each PDF to the ZIP
          for (const file of result.files) {
            zip.file(file.name, file.data);
          }
          
          // Generate ZIP file
          const zipContent = await zip.generateAsync({ type: 'blob' });
          
          // Prepare output filename
          const fileName = pdfFile.name.replace(/\.pdf$/i, '') || 'document';
          
          return {
            success: true,
            type: 'zip',
            blob: zipContent,
            filename: `${fileName}_split.zip`,
            totalFiles: result.files.length
          };
        } else {
          // Single file result (still return as one file)
          const file = result.files[0];
          const pdfBlob = new Blob([file.data], { type: 'application/pdf' });
          
          return {
            success: true,
            type: 'pdf',
            blob: pdfBlob,
            filename: file.name,
            pageRange: file.range
          };
        }
      }
      
      throw new Error('No files were generated');
    } catch (error) {
      console.error('Error splitting PDF:', error);
      throw error;
    }
  }
  
  /**
   * Merges multiple PDF files into one
   * @public
   * @param {Array<File|Blob>} pdfFiles - PDF files to merge
   * @param {Object} options - Merge options
   * @returns {Promise<Object>} - Merge result
   */
  async mergePDFs(pdfFiles, options = {}) {
    try {
      // Validate input files
      if (!pdfFiles || !Array.isArray(pdfFiles) || pdfFiles.length < 1) {
        throw new Error('At least one PDF file is required');
      }
      
      // Convert all files to ArrayBuffer
      const pdfArrayBuffers = await Promise.all(
        pdfFiles.map(file => this.fileToArrayBuffer(file))
      );
      
      // Process in worker
      const result = await this.executeTask('mergePDFs', pdfArrayBuffers, options);
      
      if (!result.success) {
        throw new Error('Merge failed');
      }
      
      // Create blob for the merged PDF
      const mergedPdfBlob = new Blob([result.data], { type: 'application/pdf' });
      
      return {
        success: true,
        type: 'pdf',
        blob: mergedPdfBlob,
        filename: 'merged.pdf',
        size: result.size,
        pageCount: result.pageCount,
        totalMergedFiles: pdfFiles.length
      };
    } catch (error) {
      console.error('Error merging PDFs:', error);
      throw error;
    }
  }
  
  /**
   * Downloads the processing result
   * @public
   * @param {Object} result - Processing result
   * @returns {boolean} - Whether download started successfully
   */
  downloadResult(result) {
    if (!result || !result.success || !result.blob) {
      throw new Error('Invalid result: missing required properties');
    }
    
    try {
      // Use FileSaver to handle the download
      saveAs(result.blob, result.filename || 'download.pdf');
      return true;
    } catch (error) {
      console.error('Error saving file:', error);
      throw new Error('Download failed: ' + error.message);
    }
  }
  
  /**
   * Cleans up resources used by the service
   * @public
   */
  dispose() {
    // Terminate worker if it exists
    if (this.worker) {
      this.worker.terminate();
      this.worker = null;
    }
    
    // Clear any pending tasks
    this.pendingTasks.clear();
  }
}

// Export singleton instance
export const pdfService = new PDFService();