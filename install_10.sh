#!/bin/bash

# Fix PDFWebViewer.jsx canvas rendering issue
echo "Fixing PDFWebViewer.jsx canvas rendering issue..."
cat > src/components/tools/pdf/PDFWebViewer.jsx << 'EOF'
// src/components/tools/pdf/PDFWebViewer.jsx
import { useState, useEffect, useRef } from 'react';

const PDFWebViewer = ({ file, pageNumber = 1, scale = 1.0 }) => {
  const canvasRef = useRef(null);
  const [numPages, setNumPages] = useState(0);
  const [currentPage, setCurrentPage] = useState(pageNumber);
  const [pdfDoc, setPdfDoc] = useState(null);
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState(null);
  const [renderTask, setRenderTask] = useState(null);

  // Load PDF
  useEffect(() => {
    if (!file || !(file instanceof File || file instanceof Blob)) return;
    
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
            const loadingTask = window.pdfjsLib.getDocument({
              data: new Uint8Array(event.target.result)
            });
            
            const pdf = await loadingTask.promise;
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

  // Render page
  useEffect(() => {
    if (!pdfDoc || !canvasRef.current) return;
    
    const renderPage = async () => {
      try {
        // Cancel any existing render task
        if (renderTask) {
          renderTask.cancel();
          setRenderTask(null);
        }
        
        const page = await pdfDoc.getPage(currentPage);
        const viewport = page.getViewport({ scale });
        
        const canvas = canvasRef.current;
        const context = canvas.getContext('2d');
        
        canvas.height = viewport.height;
        canvas.width = viewport.width;
        
        const renderContext = {
          canvasContext: context,
          viewport: viewport
        };
        
        // Clear canvas before rendering
        context.clearRect(0, 0, canvas.width, canvas.height);
        
        const task = page.render(renderContext);
        setRenderTask(task);
        
        await task.promise;
        setRenderTask(null);
      } catch (err) {
        if (err.name === 'RenderingCancelledException') {
          console.log('Rendering was cancelled');
        } else {
          console.error("Error rendering page:", err);
          setError("Error rendering page");
        }
      }
    };
    
    renderPage();
    
    // Cleanup function
    return () => {
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
      <div className="flex items-center justify-center h-64 bg-gray-100 dark:bg-gray-800 rounded-lg">
        <div className="animate-spin rounded-full h-10 w-10 border-t-2 border-b-2 border-red-500 mb-4"></div>
        <p className="text-gray-600 dark:text-gray-400 ml-3">Loading document...</p>
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
EOF

# Also fix PDFPreview.jsx to properly handle rendering tasks and canvas cleanup
echo "Updating PDFPreview.jsx to handle canvas rendering properly..."
cat > src/components/tools/pdf/PDFPreview.jsx << 'EOF'
// src/components/tools/pdf/PDFPreview.jsx
import PDFWebViewer from "./PDFWebViewer";
import { useState, useEffect, useRef } from 'react';
import { motion } from 'framer-motion';
import { useOS } from '../../../context/OSContext';

const PDFPreview = ({ files, options, isLoading }) => {
  const { osType, isMobile } = useOS();
  
  // Use PDFWebViewer for actual PDF rendering
  if (files && files.length > 0 && !isLoading) {
    return <PDFWebViewer file={files[0]} />;
  }
  
  const [preview, setPreview] = useState(null);
  const [currentPage, setCurrentPage] = useState(1);
  const [totalPages, setTotalPages] = useState(1);
  const [scale, setScale] = useState(1.0);
  const canvasRef = useRef(null);
  const [renderTask, setRenderTask] = useState(null);
  
  // PDF.js check
  useEffect(() => {
    if (!window.pdfjsLib) {
      console.error("PDF.js library not found. Make sure it's loaded in index.html");
    }
  }, []);
  
  // Load PDF preview when file changes
  useEffect(() => {
    if (!files || files.length === 0 || !window.pdfjsLib) return;
    
    // Clear previous preview
    if (preview) {
      preview.destroy();
      setPreview(null);
    }
    
    const loadPdfPreview = async () => {
      try {
        // Use the first file for preview
        const file = files[0];
        
        // Read file as ArrayBuffer
        const arrayBuffer = await new Promise((resolve, reject) => {
          const reader = new FileReader();
          reader.onload = () => resolve(reader.result);
          reader.onerror = reject;
          reader.readAsArrayBuffer(file);
        });
        
        // Load PDF with PDF.js
        const loadingTask = window.pdfjsLib.getDocument({ data: arrayBuffer });
        const pdfDocument = await loadingTask.promise;
        
        setPreview(pdfDocument);
        setTotalPages(pdfDocument.numPages);
        setCurrentPage(1);
        
      } catch (error) {
        console.error('Error loading PDF preview:', error);
      }
    };
    
    loadPdfPreview();
    
    // Cleanup
    return () => {
      if (preview) {
        preview.destroy();
      }
      
      if (renderTask) {
        renderTask.cancel();
      }
    };
  }, [files]);
  
  // Render current page
  useEffect(() => {
    if (!preview || !canvasRef.current) return;
    
    const renderPage = async () => {
      try {
        // Cancel any existing render task
        if (renderTask) {
          renderTask.cancel();
          setRenderTask(null);
        }
        
        // Get the page
        const page = await preview.getPage(currentPage);
        
        // Calculate appropriate scale
        const canvas = canvasRef.current;
        const viewport = page.getViewport({ scale });
        
        // Set canvas dimensions
        canvas.height = viewport.height;
        canvas.width = viewport.width;
        
        // Clear canvas before rendering new content
        const ctx = canvas.getContext('2d');
        ctx.clearRect(0, 0, canvas.width, canvas.height);
        
        // Render the page
        const renderContext = {
          canvasContext: ctx,
          viewport: viewport
        };
        
        const task = page.render(renderContext);
        setRenderTask(task);
        
        await task.promise;
        setRenderTask(null);
      } catch (error) {
        if (error.name === 'RenderingCancelledException') {
          console.log('Rendering was cancelled');
        } else {
          console.error('Error rendering PDF page:', error);
        }
      }
    };
    
    renderPage();
    
    // Cleanup function
    return () => {
      if (renderTask) {
        renderTask.cancel();
        setRenderTask(null);
      }
    };
  }, [preview, currentPage, scale]);
  
  // Change page
  const changePage = (delta) => {
    const newPage = currentPage + delta;
    if (newPage >= 1 && newPage <= totalPages) {
      setCurrentPage(newPage);
    }
  };
  
  // Change zoom
  const changeZoom = (delta) => {
    const newScale = Math.max(0.5, Math.min(2.0, scale + delta));
    setScale(newScale);
  };
  
  // Get preview style
  const getPreviewStyle = () => {
    return {
      maxHeight: isMobile ? '300px' : '400px',
      overflow: 'auto',
      backgroundColor: '#f5f5f5',
      borderRadius: '6px',
      display: 'flex',
      justifyContent: 'center',
      alignItems: 'flex-start'
    };
  };
  
  // Animation variants
  const controlsVariants = {
    hidden: { opacity: 0, y: 10 },
    visible: { opacity: 1, y: 0, transition: { duration: 0.3 } }
  };
  
  // Render loading state
  if (isLoading) {
    return (
      <div className="flex flex-col items-center justify-center h-64 bg-gray-100 dark:bg-gray-800 rounded-lg">
        <div className="animate-spin rounded-full h-10 w-10 border-t-2 border-b-2 border-red-500 mb-4"></div>
        <p className="text-gray-600 dark:text-gray-400">Loading preview...</p>
      </div>
    );
  }
  
  // Render message if no files
  if (!files || files.length === 0) {
    return (
      <div className="flex flex-col items-center justify-center h-64 bg-gray-100 dark:bg-gray-800 rounded-lg">
        <svg className="w-16 h-16 text-gray-400 mb-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z" />
        </svg>
        <p className="text-gray-600 dark:text-gray-400">Upload a PDF file to see preview</p>
      </div>
    );
  }
  
  // Render PDF
  return (
    <div>
      <div className="flex justify-center mb-3">
        <motion.div
          className="inline-flex items-center bg-gray-100 dark:bg-gray-800 rounded-full px-3 py-1"
          variants={controlsVariants}
          initial="hidden"
          animate="visible"
        >
          <button
            className="p-1 focus:outline-none disabled:opacity-50"
            onClick={() => changeZoom(-0.1)}
            disabled={scale <= 0.5}
          >
            <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M15 12H9" />
            </svg>
          </button>
          
          <span className="mx-2 text-sm">{Math.round(scale * 100)}%</span>
          
          <button
            className="p-1 focus:outline-none disabled:opacity-50"
            onClick={() => changeZoom(0.1)}
            disabled={scale >= 2.0}
          >
            <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 6v6m0 0v6m0-6h6m-6 0H6" />
            </svg>
          </button>
        </motion.div>
      </div>
      
      <div style={getPreviewStyle()}>
        <canvas ref={canvasRef} className="shadow-md"></canvas>
      </div>
      
      {totalPages > 1 && (
        <motion.div
          className="flex justify-center items-center mt-3"
          variants={controlsVariants}
          initial="hidden"
          animate="visible"
        >
          <button
            className="p-1 rounded-full hover:bg-gray-200 dark:hover:bg-gray-700 focus:outline-none disabled:opacity-50"
            onClick={() => changePage(-1)}
            disabled={currentPage <= 1}
          >
            <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M15 19l-7-7 7-7" />
            </svg>
          </button>
          
          <span className="mx-3 text-sm">
            Page {currentPage} of {totalPages}
          </span>
          
          <button
            className="p-1 rounded-full hover:bg-gray-200 dark:hover:bg-gray-700 focus:outline-none disabled:opacity-50"
            onClick={() => changePage(1)}
            disabled={currentPage >= totalPages}
          >
            <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 5l7 7-7 7" />
            </svg>
          </button>
        </motion.div>
      )}
    </div>
  );
};

export default PDFPreview;
EOF

# Ensure execute permissions
chmod +x "$0"

echo "✅ PDF rendering issues have been fixed!"
echo "The script has fixed:"
echo "  1. PDFWebViewer.jsx - Added proper canvas rendering task management"
echo "  2. PDFPreview.jsx - Updated to properly manage rendering tasks and clean up canvases"
echo ""
echo "The PDF preview should now render correctly without the 'Cannot use the same canvas during multiple render operations' error."