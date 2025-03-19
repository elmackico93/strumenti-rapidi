// PDF Functionality Test Script
// Run this in browser console to verify PDF functionality

async function testPDFFunctionality() {
  console.log("==== StrumentiRapidi.it PDF Functionality Test ====");
  
  // Verify PDF.js is loaded
  console.log("1. Testing PDF.js availability...");
  if (window.pdfjsLib) {
    console.log("✓ PDF.js is available");
    console.log("   Version:", window.pdfjsLib.version || "Unknown");
    console.log("   Worker source:", window.pdfjsLib.GlobalWorkerOptions?.workerSrc || "Not configured");
  } else {
    console.error("✗ PDF.js is not available!");
    return;
  }
  
  // Test PDFService is initialized
  console.log("2. Testing PDFService initialization...");
  
  try {
    const pdfServiceModule = await import('./src/services/pdfService.js');
    const pdfService = pdfServiceModule.pdfService;
    
    if (pdfService.workerInitialized) {
      console.log("✓ PDFService worker is initialized");
    } else {
      console.error("✗ PDFService worker is not initialized!");
      console.log("Error:", pdfService.workerInitError);
    }
    
    // Test basic PDF functionality if available
    if (pdfService.workerInitialized) {
      console.log("3. Testing PDFService worker communication...");
      try {
        // Create a small dummy PDF
        const { PDFDocument } = await import('https://unpkg.com/pdf-lib@1.17.1/dist/pdf-lib.esm.min.js');
        const pdfDoc = await PDFDocument.create();
        pdfDoc.addPage([350, 400]);
        const pdfBytes = await pdfDoc.save();
        
        // Create a blob from the bytes
        const testPdfBlob = new Blob([pdfBytes], { type: 'application/pdf' });
        
        // Extract text from the PDF (should be empty but valid)
        console.log("   Attempting to extract text from test PDF...");
        const textResult = await pdfService.extractText(testPdfBlob, {});
        
        if (textResult.success) {
          console.log("✓ PDFService worker communication works correctly");
        } else {
          console.error("✗ PDFService worker communication failed");
        }
      } catch (err) {
        console.error("✗ PDFService basic functionality test failed:", err);
      }
    }
    
  } catch (error) {
    console.error("✗ Error importing PDFService:", error);
  }
  
  console.log("4. To complete testing:");
  console.log("   a. Upload a PDF file to the converter");
  console.log("   b. Verify preview appears correctly");
  console.log("   c. Try each conversion option");
  console.log("==== Test Complete ====");
}

testPDFFunctionality();
