// src/services/previewService.js

// Generate preview based on file type and options
export const generatePreview = async (file, options) => {
  if (!file) return null;
  
  const fileType = file.type;
  const fileExtension = file.name.split('.').pop().toLowerCase();
  
  // Generate preview based on file type
  if (fileType.startsWith('image/')) {
    return generateImagePreview(file, options);
  } else if (fileType === 'application/pdf' || fileExtension === 'pdf') {
    return generatePDFPreview(file, options);
  } else if (
    fileType.includes('word') || 
    ['doc', 'docx'].includes(fileExtension)
  ) {
    return generateDocumentPreview(file, options);
  } else if (
    fileType.includes('text/') || 
    ['txt', 'csv', 'json'].includes(fileExtension)
  ) {
    return generateTextPreview(file, options);
  }
  
  // Generic fallback preview
  return {
    type: 'generic',
    name: file.name,
    size: file.size,
    icon: getIconForFileType(fileType, fileExtension)
  };
};

// Generate image preview
const generateImagePreview = async (file, options) => {
  return new Promise((resolve) => {
    const img = new Image();
    
    img.onload = () => {
      // Create canvas for manipulation
      const canvas = document.createElement('canvas');
      const ctx = canvas.getContext('2d');
      
      // Apply resize if specified
      let width = img.width;
      let height = img.height;
      
      if (options?.resize?.width && options?.resize?.height) {
        width = options.resize.width;
        height = options.resize.height;
      } else if (options?.resize?.width) {
        width = options.resize.width;
        height = (img.height / img.width) * options.resize.width;
      } else if (options?.resize?.height) {
        height = options.resize.height;
        width = (img.width / img.height) * options.resize.height;
      }
      
      // Set canvas dimensions
      canvas.width = width;
      canvas.height = height;
      
      // Draw resized image
      ctx.drawImage(img, 0, 0, width, height);
      
      // Apply filters if specified
      if (options?.filters) {
        applyImageFilters(ctx, canvas.width, canvas.height, options.filters);
      }
      
      // Convert to specified format with quality
      const format = options?.format || 'jpeg';
      const quality = options?.quality ? options.quality / 100 : 0.9;
      
      let previewUrl;
      try {
        previewUrl = canvas.toDataURL(`image/${format}`, quality);
      } catch (e) {
        // Fallback to JPEG if format not supported
        previewUrl = canvas.toDataURL('image/jpeg', quality);
      }
      
      resolve({
        type: 'image',
        url: previewUrl,
        width,
        height,
        format,
        estimatedSize: estimateFileSize(previewUrl)
      });
    };
    
    img.onerror = () => {
      resolve({
        type: 'error',
        message: 'Could not generate image preview'
      });
    };
    
    img.src = URL.createObjectURL(file);
  });
};

// Apply filters to image canvas
const applyImageFilters = (ctx, width, height, filters) => {
  // Get image data
  const imageData = ctx.getImageData(0, 0, width, height);
  const data = imageData.data;
  
  // Apply brightness
  if (filters.brightness !== undefined && filters.brightness !== 0) {
    const brightness = filters.brightness;
    for (let i = 0; i < data.length; i += 4) {
      data[i] = Math.max(0, Math.min(255, data[i] + brightness));
      data[i + 1] = Math.max(0, Math.min(255, data[i + 1] + brightness));
      data[i + 2] = Math.max(0, Math.min(255, data[i + 2] + brightness));
    }
  }
  
  // Apply contrast
  if (filters.contrast !== undefined && filters.contrast !== 0) {
    const contrast = filters.contrast * 2.55;
    const factor = (259 * (contrast + 255)) / (255 * (259 - contrast));
    
    for (let i = 0; i < data.length; i += 4) {
      data[i] = Math.max(0, Math.min(255, factor * (data[i] - 128) + 128));
      data[i + 1] = Math.max(0, Math.min(255, factor * (data[i + 1] - 128) + 128));
      data[i + 2] = Math.max(0, Math.min(255, factor * (data[i + 2] - 128) + 128));
    }
  }
  
  // Apply saturation
  if (filters.saturation !== undefined && filters.saturation !== 0) {
    const saturation = 1 + filters.saturation / 100;
    
    for (let i = 0; i < data.length; i += 4) {
      const gray = 0.3 * data[i] + 0.59 * data[i + 1] + 0.11 * data[i + 2];
      
      data[i] = Math.max(0, Math.min(255, gray + saturation * (data[i] - gray)));
      data[i + 1] = Math.max(0, Math.min(255, gray + saturation * (data[i + 1] - gray)));
      data[i + 2] = Math.max(0, Math.min(255, gray + saturation * (data[i + 2] - gray)));
    }
  }
  
  // Update canvas with filtered image
  ctx.putImageData(imageData, 0, 0);
};

// Generate PDF preview
const generatePDFPreview = async (file, options) => {
  // This would use pdf.js in a real implementation
  // For this example, returning a placeholder
  return {
    type: 'pdf',
    pages: 1,
    format: options?.format || 'pdf',
    previewText: 'PDF preview would be generated here',
    icon: 'pdf-icon'
  };
};

// Generate document preview
const generateDocumentPreview = async (file, options) => {
  // This would use document processing libraries in a real implementation
  // For this example, returning a placeholder
  return {
    type: 'document',
    format: options?.format || 'docx',
    previewText: 'Document preview would be generated here',
    icon: 'document-icon'
  };
};

// Generate text preview
const generateTextPreview = async (file, options) => {
  return new Promise((resolve) => {
    const reader = new FileReader();
    
    reader.onload = (e) => {
      const text = e.target.result;
      // Limit preview to first 1000 characters
      const previewText = text.slice(0, 1000) + (text.length > 1000 ? '...' : '');
      
      resolve({
        type: 'text',
        text: previewText,
        fullTextLength: text.length,
        format: options?.format || 'txt'
      });
    };
    
    reader.onerror = () => {
      resolve({
        type: 'error',
        message: 'Could not read text file'
      });
    };
    
    reader.readAsText(file);
  });
};

// Get icon based on file type
const getIconForFileType = (fileType, fileExtension) => {
  if (fileType.includes('pdf') || fileExtension === 'pdf') {
    return 'pdf-icon';
  } else if (fileType.includes('word') || ['doc', 'docx'].includes(fileExtension)) {
    return 'word-icon';
  } else if (fileType.includes('image')) {
    return 'image-icon';
  } else if (fileType.includes('text')) {
    return 'text-icon';
  } else {
    return 'file-icon';
  }
};

// Estimate file size from data URL
const estimateFileSize = (dataUrl) => {
  // Rough estimation: data URL length * 0.75 (base64 to binary ratio) / 1024 for KB
  return Math.round((dataUrl.length * 0.75) / 1024);
};
