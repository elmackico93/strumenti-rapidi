// src/services/smartDetection.js

// Detect file properties for smart suggestions
export const detectFileProperties = async (file) => {
  if (!file) return null;
  
  // Get file details
  const fileType = file.type;
  const fileExtension = file.name.split('.').pop().toLowerCase();
  const fileSize = file.size;
  
  // Basic detection result
  let result = {
    fileType,
    fileExtension,
    fileSize,
    detectedInfo: [],
    suggestions: []
  };
  
  // Add basic file info
  result.detectedInfo.push(`File type: ${fileType || 'Unknown'}`);
  result.detectedInfo.push(`File size: ${formatFileSize(fileSize)}`);
  
  // Detect based on file type
  if (fileType.startsWith('image/')) {
    await detectImageProperties(file, result);
  } else if (fileType === 'application/pdf' || fileExtension === 'pdf') {
    detectPDFProperties(file, result);
  } else if (
    fileType.includes('word') || 
    ['doc', 'docx'].includes(fileExtension)
  ) {
    detectDocumentProperties(file, result);
  } else if (
    fileType.includes('text/') || 
    ['txt', 'csv', 'json'].includes(fileExtension)
  ) {
    detectTextProperties(file, result);
  }
  
  return result;
};

// Detect image properties
const detectImageProperties = async (file, result) => {
  return new Promise((resolve) => {
    const img = new Image();
    
    img.onload = () => {
      // Get dimensions
      const width = img.width;
      const height = img.height;
      
      result.dimensions = { width, height };
      result.detectedInfo.push(`Dimensions: ${width}×${height} pixels`);
      
      // Check if image is large
      if (width > 2000 || height > 2000) {
        result.suggestions.push('Image is large. Consider resizing for better performance.');
      }
      
      // Check format based on transparency
      if (file.type === 'image/png' && file.size > 1000000) {
        result.suggestions.push('Consider converting to JPEG for smaller file size if transparency is not needed.');
      } else if (file.type === 'image/jpeg' && (width > 3000 || height > 3000)) {
        result.suggestions.push('Consider compressing this image to reduce file size.');
      }
      
      resolve(result);
    };
    
    img.onerror = () => {
      result.detectedInfo.push('Could not analyze image details.');
      resolve(result);
    };
    
    img.src = URL.createObjectURL(file);
  });
};

// Detect PDF properties
const detectPDFProperties = (file, result) => {
  // Check file size for compression recommendations
  if (file.size > 5 * 1024 * 1024) {
    result.suggestions.push('This PDF is large. Consider compressing it for easier sharing.');
  }
  
  // Add recommendations based on common PDF uses
  result.suggestions.push('You can convert this PDF to Word, Image, or Text.');
  
  return result;
};

// Detect document properties
const detectDocumentProperties = (file, result) => {
  const fileExtension = file.name.split('.').pop().toLowerCase();
  
  result.detectedInfo.push(`Document format: ${fileExtension.toUpperCase()}`);
  
  if (fileExtension === 'doc') {
    result.suggestions.push('Consider converting to DOCX for better compatibility.');
  } else {
    result.suggestions.push('You can convert this document to PDF for sharing.');
  }
  
  return result;
};

// Detect text properties
const detectTextProperties = (file, result) => {
  const fileExtension = file.name.split('.').pop().toLowerCase();
  
  if (fileExtension === 'csv') {
    result.suggestions.push('You can process this CSV data or convert it to Excel.');
  } else if (fileExtension === 'txt') {
    result.suggestions.push('You can convert this text file to PDF or analyze its content.');
  }
  
  return result;
};

// Format file size to human-readable format
const formatFileSize = (bytes) => {
  if (bytes < 1024) {
    return `${bytes} B`;
  } else if (bytes < 1024 * 1024) {
    return `${(bytes / 1024).toFixed(1)} KB`;
  } else {
    return `${(bytes / (1024 * 1024)).toFixed(1)} MB`;
  }
};
