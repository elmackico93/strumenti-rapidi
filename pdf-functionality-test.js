// PDF Functionality Test Script
// Run this in browser console to verify PDF functionality

async function testPDFFunctionality() {
  console.log("==== StrumentiRapidi.it PDF Functionality Test ====");
  
  // Verify PDF.js is loaded
  console.log("1. Testing PDF.js availability...");
  if (window.pdfjsLib) {
    console.log("✓ PDF.js is available");
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
  } catch (error) {
    console.error("✗ Error importing PDFService:", error);
  }
  
  console.log("3. To complete testing:");
  console.log("   a. Upload a PDF file to the converter");
  console.log("   b. Verify preview appears correctly");
  console.log("   c. Try each conversion option");
  console.log("==== Test Complete ====");
}

testPDFFunctionality();
