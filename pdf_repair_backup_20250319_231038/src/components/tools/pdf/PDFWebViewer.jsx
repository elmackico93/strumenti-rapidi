// src/components/tools/pdf/PDFWebViewer.jsx - FIXED VERSION
import { useState, useEffect, useRef } from 'react';

const PDFWebViewer = ({ file, pageNumber = 1, scale = 1.0 }) => {
  const canvasRef = useRef(null);
  const [numPages, setNumPages] = useState(0);
  const [currentPage, setCurrentPage] = useState(pageNumber);
  const [pdfDoc, setPdfDoc] = useState(null);
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState(null);
  const [renderTask, setRenderTask] = useState(null);

  // Debug information
  useEffect(() => {
    console.log("PDFWebViewer mounted with file:", file ? file.name : "none");
    return () => console.log("PDFWebViewer unmounted");
  }, [file]);

  // Load PDF
  useEffect(() => {
    if (!file || !(file instanceof File || file instanceof Blob)) {
      console.log("No valid file provided to PDFWebViewer");
      return;
    }
    
    const loadPDF = async () => {
      setIsLoading(true);
      try {
        // Check if PDF.js is available
        if (!window.pdfjsLib) {
          throw new Error("PDF.js library not found");
        }
        
        // Read file
        const fileReader = new FileReader();
        
        fileReader.onload = async (event) => {
          try {
            // Clean up previous PDF document
            if (pdfDoc) {
              pdfDoc.destroy();
            }
            
            // Load PDF document
            console.log("Creating PDF.js loading task");
            const loadingTask = window.pdfjsLib.getDocument({
              data: new Uint8Array(event.target.result)
            });
            
            console.log("Awaiting PDF document loading");
            const pdf = await loadingTask.promise;
            console.log("PDF document loaded successfully, pages:", pdf.numPages);
            
            // Set document and update page count
            setPdfDoc(pdf);
            setNumPages(pdf.numPages);
            setCurrentPage(1);
            setIsLoading(false);
          } catch (err) {
            console.error("Failed to load PDF document:", err);
            setError("Unable to load PDF document: " + err.message);
            setIsLoading(false);
          }
        };
        
        fileReader.onerror = (err) => {
          console.error("FileReader error:", err);
          setError("Error reading file");
          setIsLoading(false);
        };
        
        fileReader.readAsArrayBuffer(file);
      } catch (err) {
        console.error("PDF loading error:", err);
        setError("Error loading PDF: " + err.message);
        setIsLoading(false);
      }
    };
    
    loadPDF();
    
    // Cleanup
    return () => {
      // Cancel any pending render task
      if (renderTask) {
        renderTask.cancel();
      }
      
      // Cleanup PDF document
      if (pdfDoc) {
        pdfDoc.destroy();
      }
    };
  }, [file]);

  // Render page - Fixed with better checking for canvas ref
  useEffect(() => {
    if (!pdfDoc) return;
    if (!canvasRef || !canvasRef.current) {
      console.warn("Canvas ref is not available yet");
      return;
    }
    
    const renderPage = async () => {
      try {
        // Double check canvas is available
        if (!canvasRef.current) {
          console.error("Canvas reference is null during rendering");
          return;
        }
        
        // Cancel any existing render task
        if (renderTask) {
          renderTask.cancel();
          setRenderTask(null);
        }
        
        console.log(`Rendering page ${currentPage} of ${pdfDoc.numPages}`);
        const page = await pdfDoc.getPage(currentPage);
        const viewport = page.getViewport({ scale });
        
        const canvas = canvasRef.current;
        if (!canvas) {
          console.error("Canvas is null after getting page");
          return;
        }
        
        const context = canvas.getContext('2d');
        
        canvas.height = viewport.height;
        canvas.width = viewport.width;
        
        // Clear canvas before rendering
        context.clearRect(0, 0, canvas.width, canvas.height);
        
        const renderContext = {
          canvasContext: context,
          viewport: viewport
        };
        
        console.log("Starting page render");
        const task = page.render(renderContext);
        setRenderTask(task);
        
        await task.promise;
        console.log("Page render complete");
        setRenderTask(null);
      } catch (err) {
        if (err && err.name === 'RenderingCancelledException') {
          console.log('Rendering was cancelled');
        } else {
          console.error("Error rendering page:", err);
          setError("Error rendering page: " + (err ? err.message : "unknown error"));
        }
      }
    };
    
    // Use a small timeout to ensure the canvas is ready
    const timeoutId = setTimeout(() => {
      renderPage();
    }, 50);
    
    // Cleanup function
    return () => {
      clearTimeout(timeoutId);
      if (renderTask) {
        renderTask.cancel();
        setRenderTask(null);
      }
    };
  }, [pdfDoc, currentPage, scale]);

  // Change page
  const changePage = (offset) => {
    const newPage = currentPage + offset;
    if (newPage >= 1 && newPage <= numPages) {
      setCurrentPage(newPage);
    }
  };

  // Render loading state
  if (isLoading) {
    return (
      <div className="flex flex-col items-center justify-center h-64 bg-gray-100 dark:bg-gray-800 rounded-lg">
        <div className="animate-spin rounded-full h-10 w-10 border-t-2 border-b-2 border-red-500 mb-4"></div>
        <p className="text-gray-600 dark:text-gray-400">Loading document...</p>
      </div>
    );
  }

  // Render error state
  if (error) {
    return (
      <div className="flex flex-col items-center justify-center h-64 bg-red-50 dark:bg-red-900 dark:bg-opacity-20 text-red-700 dark:text-red-300 rounded-lg p-4">
        <svg className="w-12 h-12 mb-3" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 8v4m0 4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
        </svg>
        <p className="text-center">{error}</p>
      </div>
    );
  }

  // If document is loaded but there's no canvas yet, show a placeholder
  if (!canvasRef.current) {
    return (
      <div className="flex flex-col items-center justify-center h-64 bg-gray-100 dark:bg-gray-800 rounded-lg">
        <p className="text-gray-600 dark:text-gray-400">Preparing document viewer...</p>
      </div>
    );
  }

  return (
    <div className="pdf-web-viewer">
      <div className="flex justify-center mb-3">
        <div className="inline-flex items-center bg-gray-100 dark:bg-gray-800 rounded-full px-3 py-1">
          <button
            className="p-1 focus:outline-none disabled:opacity-50"
            onClick={() => changePage(-1)}
            disabled={currentPage <= 1}
          >
            <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M15 19l-7-7 7-7" />
            </svg>
          </button>
          
          <span className="mx-2 text-sm">
            Page {currentPage} of {numPages}
          </span>
          
          <button
            className="p-1 focus:outline-none disabled:opacity-50"
            onClick={() => changePage(1)}
            disabled={currentPage >= numPages}
          >
            <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 5l7 7-7 7" />
            </svg>
          </button>
        </div>
      </div>
      
      <div className="bg-white dark:bg-gray-800 rounded-lg overflow-auto max-h-96 flex justify-center">
        <canvas ref={canvasRef} className="shadow-md" />
      </div>
    </div>
  );
};

export default PDFWebViewer;
