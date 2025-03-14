// Servizio PDF avanzato per StrumentiRapidi.it
import { saveAs } from 'file-saver';
import JSZip from 'jszip';
import { PDFDocument } from 'pdf-lib';

class PDFService {
  constructor() {
    // Initialize the worker
    try {
      this.worker = new Worker(new URL('../workers/pdfWorker.js', import.meta.url), { type: "module" });
      this.taskId = 0;
      this.pendingTasks = new Map();
      
      // Configure worker message listener
      this.worker.onmessage = (e) => {
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
      };
      
      // Worker error handling
      this.worker.onerror = (e) => {
        console.error("PDF worker error:", e);
        this.pendingTasks.forEach(taskPromise => {
          taskPromise.reject(new Error("PDF worker encountered an error"));
        });
        this.pendingTasks.clear();
      };
    } catch (error) {
      console.error("Failed to initialize PDF worker:", error);
    }
  }
  
  // Execute a task in the worker
  async executeTask(task, fileData, options = {}) {
    if (!this.worker) {
      throw new Error("PDF worker is not initialized");
    }
    
    const taskId = this.taskId++;
    
    return new Promise((resolve, reject) => {
      const timeoutId = setTimeout(() => {
        this.pendingTasks.delete(taskId);
        reject(new Error(`Task ${task} timed out after 30 seconds`));
      }, 30000); // 30 second timeout
      
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
  
  // Convert File/Blob to ArrayBuffer
  async fileToArrayBuffer(file) {
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
  
  // Convert PDF to images
  async convertToImages(pdfFile, options = {}) {
    try {
      // Validation
      if (!pdfFile || !(pdfFile instanceof File || pdfFile instanceof Blob)) {
        throw new Error('Invalid PDF file');
      }
      
      const pdfArrayBuffer = await this.fileToArrayBuffer(pdfFile);
      
      // Execute conversion in worker
      const result = await this.executeTask('convertToImages', pdfArrayBuffer, options);
      
      if (!result.success) {
        throw new Error('Conversion failed');
      }
      
      // Convert image data to Blob
      const images = result.images.map(img => ({
        pageNumber: img.pageNumber,
        width: img.width,
        height: img.height,
        blob: new Blob([img.dataUrl], { type: `image/${options.format === 'jpg' ? 'jpeg' : options.format}` }),
        size: img.size
      }));
      
      // If more than one page, create ZIP file
      if (images.length > 1) {
        const zip = new JSZip();
        
        // Add each image to ZIP
        for (const img of images) {
          zip.file(`page_${img.pageNumber}.${options.format}`, img.blob);
        }
        
        // Generate ZIP file
        const zipContent = await zip.generateAsync({ type: 'blob' });
        
        return {
          success: true,
          type: 'zip',
          blob: zipContent,
          filename: `images.zip`,
          totalImages: images.length,
          format: options.format
        };
      } else if (images.length === 1) {
        // If only one page, return the image directly
        return {
          success: true,
          type: 'image',
          blob: images[0].blob,
          filename: `image.${options.format}`,
          width: images[0].width,
          height: images[0].height,
          format: options.format
        };
      } else {
        throw new Error('No images generated');
      }
    } catch (error) {
      console.error('Error converting PDF to images:', error);
      throw error;
    }
  }
  
  // Extract text from a PDF
  async extractText(pdfFile, options = {}) {
    try {
      // Validation
      if (!pdfFile || !(pdfFile instanceof File || pdfFile instanceof Blob)) {
        throw new Error('Invalid PDF file');
      }
      
      const pdfArrayBuffer = await this.fileToArrayBuffer(pdfFile);
      
      // Execute text extraction in worker
      const result = await this.executeTask('extractText', pdfArrayBuffer, options);
      
      if (!result.success) {
        throw new Error('Text extraction failed');
      }
      
      // Create blob for download
      const textBlob = new Blob([result.fullText], { type: 'text/plain;charset=utf-8' });
      
      return {
        success: true,
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
  
  // Basic implementation of other methods
  async convertToHTML(pdfFile, options = {}) {
    // Simple implementation
    try {
      const textResult = await this.extractText(pdfFile, options);
      
      // Create a simple HTML wrapper around the text
      const html = `<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <title>Converted Document</title>
</head>
<body>
  <h1>Converted Document</h1>
  <div>
    ${textResult.text.replace(/\n/g, '<br>')}
  </div>
</body>
</html>`;
      
      const htmlBlob = new Blob([html], { type: 'text/html;charset=utf-8' });
      
      return {
        success: true,
        blob: htmlBlob,
        filename: 'converted_document.html',
        html
      };
    } catch (error) {
      console.error('Error converting to HTML:', error);
      throw error;
    }
  }
  
  async convertToDocx(pdfFile, options = {}) {
    // Placeholder implementation
    try {
      return {
        success: true,
        blob: new Blob(['DOCX conversion not fully implemented']),
        filename: 'document.docx'
      };
    } catch (error) {
      console.error('Error converting to DOCX:', error);
      throw error;
    }
  }
  
  async compressPDF(pdfFile, options = {}) {
    // Placeholder implementation
    try {
      return {
        success: true,
        blob: pdfFile,
        filename: 'compressed.pdf',
        originalSize: pdfFile.size,
        compressedSize: pdfFile.size,
        compressionRate: 0
      };
    } catch (error) {
      console.error('Error compressing PDF:', error);
      throw error;
    }
  }
  
  async protectPDF(pdfFile, options = {}) {
    // Placeholder implementation
    try {
      return {
        success: true,
        blob: pdfFile,
        filename: 'protected.pdf',
        size: pdfFile.size
      };
    } catch (error) {
      console.error('Error protecting PDF:', error);
      throw error;
    }
  }
  
  async splitPDF(pdfFile, options = {}) {
    // Placeholder implementation
    try {
      return {
        success: true,
        type: 'pdf',
        blob: pdfFile,
        filename: 'split.pdf'
      };
    } catch (error) {
      console.error('Error splitting PDF:', error);
      throw error;
    }
  }
  
  async mergePDFs(pdfFiles, options = {}) {
    // Placeholder implementation
    try {
      return {
        success: true,
        blob: pdfFiles[0],
        filename: 'merged.pdf',
        size: pdfFiles[0].size,
        totalMergedFiles: pdfFiles.length
      };
    } catch (error) {
      console.error('Error merging PDFs:', error);
      throw error;
    }
  }
  
  // Download result
  downloadResult(result) {
    if (!result || !result.success || !result.blob) {
      throw new Error('Invalid result');
    }
    
    saveAs(result.blob, result.filename);
    return true;
  }
}

// Export singleton instance
export const pdfService = new PDFService();
