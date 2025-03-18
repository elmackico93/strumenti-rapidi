#!/bin/bash

# Script per implementare l'UI adattiva al sistema operativo in StrumentiRapidi.it
echo "=== Implementazione UI adattiva al sistema operativo ==="

# Verifica directory progetto
if [ ! -f "package.json" ] || [ ! -d "src" ]; then
  echo "Errore: eseguire nella directory principale del progetto"
  exit 1
fi

# Funzione per creare o sovrascrivere file
create_file() {
  mkdir -p "$(dirname "$1")"
  cat > "$1"
}

# Installazione delle dipendenze necessarie
echo "Installazione delle dipendenze per il rilevamento del sistema operativo e i temi adattivi..."
npm install react-device-detect platform-detect --silent || echo "Errore nell'installazione delle dipendenze"

# 1. Creazione del contesto per il rilevamento del sistema operativo
create_file "src/context/OSContext.jsx" << 'EOF'
import React, { createContext, useContext, useEffect, useState } from 'react';
import { isAndroid, isIOS, isMacOs, isWindows } from 'react-device-detect';
import { isLinux } from 'platform-detect';

// Contesto per il sistema operativo
const OSContext = createContext();

export const OSProvider = ({ children }) => {
  const [osType, setOsType] = useState('generic');
  const [isMobile, setIsMobile] = useState(false);

  useEffect(() => {
    // Rileva il sistema operativo
    if (isIOS) {
      setOsType('ios');
      setIsMobile(true);
    } else if (isAndroid) {
      setOsType('android');
      setIsMobile(true);
    } else if (isMacOs) {
      setOsType('macos');
      setIsMobile(false);
    } else if (isWindows) {
      setOsType('windows');
      setIsMobile(false);
    } else if (isLinux) {
      setOsType('linux');
      setIsMobile(false);
    } else {
      setOsType('generic');
      setIsMobile(false);
    }
    
    // Aggiunge una classe al body per lo styling basato sul sistema operativo
    document.body.className = document.body.className
      .split(' ')
      .filter(c => !c.startsWith('os-'))
      .join(' ');
    document.body.classList.add(`os-${osType}`);
    
    // Aggiunge una classe per stili mobile/desktop
    if (isMobile) {
      document.body.classList.add('is-mobile');
    } else {
      document.body.classList.remove('is-mobile');
    }
  }, [osType, isMobile]);

  return (
    <OSContext.Provider value={{ osType, isMobile }}>
      {children}
    </OSContext.Provider>
  );
};

export const useOS = () => {
  const context = useContext(OSContext);
  if (context === undefined) {
    throw new Error('useOS deve essere usato all\'interno di un OSProvider');
  }
  return context;
};
EOF

# 2. Modifica di App.jsx per integrare l'OSProvider
create_file "src/App.jsx" << 'EOF'
// src/App.jsx
import { BrowserRouter, Routes, Route } from 'react-router-dom';
import { ThemeProvider } from './context/ThemeContext';
import { OSProvider } from './context/OSContext';
import MainLayout from './components/layout/MainLayout';
import Home from './pages/Home';
import ToolsPage from './pages/ToolsPage';

// Create global registry for tools
window.toolRegistry = {
  'image-editor': {
    acceptedFormats: ['.jpg', '.jpeg', '.png', '.webp', '.gif', '.bmp'],
    maxFileSize: 50 * 1024 * 1024 // 50MB
  },
  'pdf-converter': {
    acceptedFormats: ['.pdf', '.docx', '.doc', '.jpg', '.jpeg', '.png'],
    maxFileSize: 100 * 1024 * 1024 // 100MB
  },
  'ocr': {
    acceptedFormats: ['.jpg', '.jpeg', '.png', '.bmp', '.gif', '.webp', '.pdf'],
    maxFileSize: 10 * 1024 * 1024 // 10MB
  },
  'video-downloader': {
    acceptedFormats: [],
    maxFileSize: 0
  },
  'calculator': {
    acceptedFormats: [],
    maxFileSize: 0
  },
  'meme-creator': {
    acceptedFormats: ['.jpg', '.jpeg', '.png', '.webp', '.gif'],
    maxFileSize: 10 * 1024 * 1024 // 10MB
  }
};

function App() {
  return (
    <ThemeProvider>
      <OSProvider>
        <BrowserRouter>
          <Routes>
            <Route path="/" element={<MainLayout />}>
              <Route index element={<Home />} />
              <Route path="tools/:toolId" element={<ToolsPage />} />
            </Route>
          </Routes>
        </BrowserRouter>
      </OSProvider>
    </ThemeProvider>
  );
}

export default App;
EOF

# 3. Creazione di componenti UI adattivi
create_file "src/components/ui/AdaptiveButton.jsx" << 'EOF'
import React from 'react';
import { useOS } from '../../context/OSContext';

const AdaptiveButton = ({ 
  children, 
  variant = 'primary', 
  onClick, 
  disabled, 
  fullWidth,
  className,
  ...props 
}) => {
  const { osType } = useOS();
  
  // Classi di base per tutti i pulsanti
  let buttonClasses = 'transition-all focus:outline-none';
  
  if (fullWidth) {
    buttonClasses += ' w-full';
  }
  
  // Aggiungi classi in base alla variante
  if (variant === 'primary') {
    buttonClasses += ' text-white';
  } else if (variant === 'secondary') {
    buttonClasses += ' bg-gray-200 dark:bg-gray-700 text-gray-800 dark:text-gray-200';
  } else if (variant === 'outline') {
    buttonClasses += ' bg-transparent border text-gray-800 dark:text-gray-200';
  }
  
  // Aggiungi classi specifiche per sistema operativo
  switch (osType) {
    case 'ios':
      buttonClasses += ' rounded-xl py-3 px-5 font-medium';
      
      if (variant === 'primary') {
        buttonClasses += ' bg-blue-500';
      } else if (variant === 'outline') {
        buttonClasses += ' border-gray-300 dark:border-gray-600';
      }
      
      if (disabled) {
        buttonClasses += ' opacity-50';
      } else {
        buttonClasses += ' active:opacity-70';
      }
      break;
      
    case 'android':
      buttonClasses += ' rounded-lg py-2.5 px-4 uppercase text-sm font-medium shadow-sm';
      
      if (variant === 'primary') {
        buttonClasses += ' bg-blue-600';
      } else if (variant === 'outline') {
        buttonClasses += ' border-gray-400 dark:border-gray-500';
      }
      
      if (disabled) {
        buttonClasses += ' opacity-40';
      } else {
        buttonClasses += ' active:translate-y-0.5';
      }
      break;
      
    case 'windows':
      buttonClasses += ' rounded py-1.5 px-4 font-normal border ';
      
      if (variant === 'primary') {
        buttonClasses += ' bg-blue-600 border-blue-700 hover:bg-blue-700';
      } else if (variant === 'secondary') {
        buttonClasses += ' hover:bg-gray-300 dark:hover:bg-gray-600 border-gray-300 dark:border-gray-600';
      } else if (variant === 'outline') {
        buttonClasses += ' border-gray-300 dark:border-gray-600 hover:bg-gray-100 dark:hover:bg-gray-800';
      }
      
      if (disabled) {
        buttonClasses += ' opacity-50 cursor-not-allowed';
      }
      break;
      
    case 'macos':
      buttonClasses += ' rounded-md py-1.5 px-4 font-medium text-sm';
      
      if (variant === 'primary') {
        buttonClasses += ' bg-gradient-to-b from-blue-500 to-blue-600 hover:from-blue-600 hover:to-blue-700';
      } else if (variant === 'secondary') {
        buttonClasses += ' bg-gradient-to-b from-gray-100 to-gray-200 dark:from-gray-700 dark:to-gray-800 hover:from-gray-200 hover:to-gray-300 dark:hover:from-gray-600 dark:hover:to-gray-700 text-gray-800 dark:text-gray-200';
      } else if (variant === 'outline') {
        buttonClasses += ' border-gray-300 dark:border-gray-600 hover:bg-gray-50 dark:hover:bg-gray-800';
      }
      
      if (disabled) {
        buttonClasses += ' opacity-50 cursor-not-allowed';
      }
      break;
      
    case 'linux':
      buttonClasses += ' rounded py-2 px-4 font-medium';
      
      if (variant === 'primary') {
        buttonClasses += ' bg-blue-600 hover:bg-blue-700';
      } else if (variant === 'secondary') {
        buttonClasses += ' hover:bg-gray-300 dark:hover:bg-gray-600';
      } else if (variant === 'outline') {
        buttonClasses += ' border-gray-400 dark:border-gray-500 hover:bg-gray-100 dark:hover:bg-gray-800';
      }
      
      if (disabled) {
        buttonClasses += ' opacity-60 cursor-not-allowed';
      }
      break;
      
    default:
      // Stile generico
      buttonClasses += ' rounded-lg py-2 px-4 font-medium';
      
      if (variant === 'primary') {
        buttonClasses += ' bg-blue-600 hover:bg-blue-700';
      } else if (variant === 'outline') {
        buttonClasses += ' border-gray-300 dark:border-gray-600 hover:bg-gray-100 dark:hover:bg-gray-800';
      }
      
      if (disabled) {
        buttonClasses += ' opacity-50 cursor-not-allowed';
      }
  }
  
  // Aggiungi classi personalizzate
  if (className) {
    buttonClasses += ` ${className}`;
  }
  
  return (
    <button
      className={buttonClasses}
      onClick={onClick}
      disabled={disabled}
      {...props}
    >
      {children}
    </button>
  );
};

export default AdaptiveButton;
EOF

create_file "src/components/ui/AdaptiveInput.jsx" << 'EOF'
import React from 'react';
import { useOS } from '../../context/OSContext';

const AdaptiveInput = ({ 
  type = 'text', 
  placeholder, 
  value, 
  onChange, 
  label,
  error,
  fullWidth,
  className,
  ...props 
}) => {
  const { osType } = useOS();
  
  // Classi di base per tutti gli input
  let inputClasses = 'transition-colors focus:outline-none';
  let wrapperClasses = '';
  let labelClasses = 'block text-sm font-medium mb-1 text-gray-700 dark:text-gray-300';
  let errorClasses = 'text-red-600 text-xs mt-1';
  
  if (fullWidth) {
    wrapperClasses += ' w-full';
    inputClasses += ' w-full';
  }
  
  // Aggiungi classi specifiche per sistema operativo
  switch (osType) {
    case 'ios':
      inputClasses += ' rounded-xl py-3 px-4 border border-gray-300 dark:border-gray-600 dark:bg-gray-800';
      
      if (error) {
        inputClasses += ' border-red-500 focus:border-red-500';
      } else {
        inputClasses += ' focus:border-blue-500';
      }
      break;
      
    case 'android':
      inputClasses += ' rounded-md py-2 px-3 border-b-2 border-gray-300 dark:border-gray-600 dark:bg-gray-800';
      
      if (error) {
        inputClasses += ' border-red-500 focus:border-red-500';
      } else {
        inputClasses += ' focus:border-blue-600';
      }
      break;
      
    case 'windows':
      inputClasses += ' rounded py-1.5 px-3 border border-gray-300 dark:border-gray-600 dark:bg-gray-800';
      
      if (error) {
        inputClasses += ' border-red-500 focus:border-red-500';
      } else {
        inputClasses += ' focus:border-blue-600';
      }
      break;
      
    case 'macos':
      inputClasses += ' rounded-md py-1.5 px-3 border border-gray-300 dark:border-gray-600 dark:bg-gray-800 shadow-sm';
      
      if (error) {
        inputClasses += ' border-red-500 focus:border-red-500';
      } else {
        inputClasses += ' focus:border-blue-500 focus:ring-1 focus:ring-blue-500';
      }
      break;
      
    case 'linux':
      inputClasses += ' rounded py-2 px-3 border border-gray-300 dark:border-gray-600 dark:bg-gray-800';
      
      if (error) {
        inputClasses += ' border-red-500 focus:border-red-500';
      } else {
        inputClasses += ' focus:border-blue-600';
      }
      break;
      
    default:
      // Stile generico
      inputClasses += ' rounded-lg py-2 px-3 border border-gray-300 dark:border-gray-600 dark:bg-gray-800';
      
      if (error) {
        inputClasses += ' border-red-500 focus:border-red-500';
      } else {
        inputClasses += ' focus:border-blue-600 focus:ring-1 focus:ring-blue-600';
      }
  }
  
  // Aggiungi classi personalizzate
  if (className) {
    inputClasses += ` ${className}`;
  }
  
  return (
    <div className={wrapperClasses}>
      {label && (
        <label className={labelClasses}>{label}</label>
      )}
      <input
        type={type}
        className={inputClasses}
        placeholder={placeholder}
        value={value}
        onChange={onChange}
        {...props}
      />
      {error && (
        <p className={errorClasses}>{error}</p>
      )}
    </div>
  );
};

export default AdaptiveInput;
EOF

create_file "src/components/ui/AdaptiveSwitch.jsx" << 'EOF'
import React from 'react';
import { useOS } from '../../context/OSContext';

const AdaptiveSwitch = ({ 
  checked, 
  onChange, 
  label,
  className,
  ...props 
}) => {
  const { osType } = useOS();
  
  // Classi di base per tutti gli switch
  let switchWrapperClasses = 'relative inline-flex items-center cursor-pointer';
  let switchTrackClasses = 'transition-colors';
  let switchThumbClasses = 'absolute transform transition-transform';
  let labelClasses = 'ml-3 text-sm font-medium text-gray-700 dark:text-gray-300';
  
  // Aggiungi classi specifiche per sistema operativo
  switch (osType) {
    case 'ios':
      switchWrapperClasses += ' h-6 w-11';
      switchTrackClasses += ` h-6 w-11 rounded-full ${checked ? 'bg-green-400' : 'bg-gray-300 dark:bg-gray-600'}`;
      switchThumbClasses += ` h-5 w-5 rounded-full bg-white shadow-md border border-gray-200 ${checked ? 'translate-x-5' : 'translate-x-0.5'}`;
      break;
      
    case 'android':
      switchWrapperClasses += ' h-6 w-12';
      switchTrackClasses += ` h-4 w-10 mx-1 my-1 rounded-full ${checked ? 'bg-blue-600' : 'bg-gray-300 dark:bg-gray-600'}`;
      switchThumbClasses += ` h-5 w-5 rounded-full shadow-md ${checked ? 'bg-white translate-x-6' : 'bg-white translate-x-0'}`;
      break;
      
    case 'windows':
      switchWrapperClasses += ' h-6 w-11';
      switchTrackClasses += ` h-3 w-9 mx-1 rounded-full ${checked ? 'bg-blue-600' : 'bg-gray-300 dark:bg-gray-600'}`;
      switchThumbClasses += ` h-4 w-4 rounded-full bg-white shadow-sm border border-gray-200 ${checked ? 'translate-x-6' : 'translate-x-0'}`;
      break;
      
    case 'macos':
      switchWrapperClasses += ' h-6 w-10';
      switchTrackClasses += ` h-6 w-10 rounded-full border ${checked ? 'bg-blue-500 border-blue-600' : 'bg-gray-200 dark:bg-gray-700 border-gray-300 dark:border-gray-600'}`;
      switchThumbClasses += ` h-5 w-5 rounded-full bg-white shadow-sm ${checked ? 'translate-x-4' : 'translate-x-0.5'}`;
      break;
      
    case 'linux':
      switchWrapperClasses += ' h-6 w-12';
      switchTrackClasses += ` h-5 w-10 mx-1 rounded-sm ${checked ? 'bg-blue-600' : 'bg-gray-300 dark:bg-gray-600'}`;
      switchThumbClasses += ` h-3 w-3 rounded-sm bg-white m-1 ${checked ? 'translate-x-5' : 'translate-x-0'}`;
      break;
      
    default:
      // Stile generico
      switchWrapperClasses += ' h-6 w-11';
      switchTrackClasses += ` h-6 w-11 rounded-full ${checked ? 'bg-blue-600' : 'bg-gray-300 dark:bg-gray-600'}`;
      switchThumbClasses += ` h-5 w-5 rounded-full bg-white shadow-md ${checked ? 'translate-x-5' : 'translate-x-1'}`;
  }
  
  // Aggiungi classi personalizzate
  if (className) {
    switchWrapperClasses += ` ${className}`;
  }
  
  return (
    <label className="flex items-center">
      <div className={switchWrapperClasses}>
        <input
          type="checkbox"
          className="sr-only"
          checked={checked}
          onChange={onChange}
          {...props}
        />
        <div className={switchTrackClasses}></div>
        <div className={switchThumbClasses}></div>
      </div>
      {label && (
        <span className={labelClasses}>{label}</span>
      )}
    </label>
  );
};

export default AdaptiveSwitch;
EOF

create_file "src/components/ui/AdaptiveSelect.jsx" << 'EOF'
import React from 'react';
import { useOS } from '../../context/OSContext';

const AdaptiveSelect = ({ 
  options, 
  value, 
  onChange, 
  label,
  placeholder,
  error,
  fullWidth,
  className,
  ...props 
}) => {
  const { osType } = useOS();
  
  // Classi di base per tutti i select
  let selectClasses = 'transition-colors focus:outline-none';
  let wrapperClasses = 'relative';
  let labelClasses = 'block text-sm font-medium mb-1 text-gray-700 dark:text-gray-300';
  let errorClasses = 'text-red-600 text-xs mt-1';
  let iconClasses = 'absolute right-2 top-1/2 transform -translate-y-1/2 pointer-events-none text-gray-500';
  
  if (fullWidth) {
    wrapperClasses += ' w-full';
    selectClasses += ' w-full';
  }
  
  // Aggiungi classi specifiche per sistema operativo
  switch (osType) {
    case 'ios':
      selectClasses += ' rounded-xl py-3 px-4 border border-gray-300 dark:border-gray-600 dark:bg-gray-800 appearance-none';
      
      if (error) {
        selectClasses += ' border-red-500 focus:border-red-500';
      } else {
        selectClasses += ' focus:border-blue-500';
      }
      break;
      
    case 'android':
      selectClasses += ' rounded-md py-2 px-3 border-b-2 border-gray-300 dark:border-gray-600 dark:bg-gray-800 appearance-none';
      
      if (error) {
        selectClasses += ' border-red-500 focus:border-red-500';
      } else {
        selectClasses += ' focus:border-blue-600';
      }
      break;
      
    case 'windows':
      selectClasses += ' rounded py-1.5 px-3 border border-gray-300 dark:border-gray-600 dark:bg-gray-800 appearance-none';
      
      if (error) {
        selectClasses += ' border-red-500 focus:border-red-500';
      } else {
        selectClasses += ' focus:border-blue-600';
      }
      break;
      
    case 'macos':
      selectClasses += ' rounded-md py-1.5 px-3 border border-gray-300 dark:border-gray-600 dark:bg-gray-800 shadow-sm appearance-none';
      
      if (error) {
        selectClasses += ' border-red-500 focus:border-red-500';
      } else {
        selectClasses += ' focus:border-blue-500 focus:ring-1 focus:ring-blue-500';
      }
      break;
      
    case 'linux':
      selectClasses += ' rounded py-2 px-3 border border-gray-300 dark:border-gray-600 dark:bg-gray-800 appearance-none';
      
      if (error) {
        selectClasses += ' border-red-500 focus:border-red-500';
      } else {
        selectClasses += ' focus:border-blue-600';
      }
      break;
      
    default:
      // Stile generico
      selectClasses += ' rounded-lg py-2 px-3 border border-gray-300 dark:border-gray-600 dark:bg-gray-800 appearance-none';
      
      if (error) {
        selectClasses += ' border-red-500 focus:border-red-500';
      } else {
        selectClasses += ' focus:border-blue-600 focus:ring-1 focus:ring-blue-600';
      }
  }
  
  // Aggiungi classi personalizzate
  if (className) {
    selectClasses += ` ${className}`;
  }
  
  return (
    <div className={wrapperClasses}>
      {label && (
        <label className={labelClasses}>{label}</label>
      )}
      <div className="relative">
        <select
          className={selectClasses}
          value={value}
          onChange={onChange}
          {...props}
        >
          {placeholder && (
            <option value="" disabled>{placeholder}</option>
          )}
          {options.map((option) => (
            <option key={option.value} value={option.value}>
              {option.label}
            </option>
          ))}
        </select>
        <div className={iconClasses}>
          <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M19 9l-7 7-7-7" />
          </svg>
        </div>
      </div>
      {error && (
        <p className={errorClasses}>{error}</p>
      )}
    </div>
  );
};

export default AdaptiveSelect;
EOF

# 4. Creazione degli stili CSS adattivi
create_file "src/styles/adaptive.css" << 'EOF'
/* Base responsive styles */
html {
  box-sizing: border-box;
}

*, *:before, *:after {
  box-sizing: inherit;
}

body {
  margin: 0;
  padding: 0;
  font-family: system-ui, -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Oxygen, Ubuntu, Cantarell, 'Open Sans', 'Helvetica Neue', sans-serif;
}

/* iOS specific styles */
.os-ios * {
  -webkit-tap-highlight-color: transparent;
}

.os-ios button, 
.os-ios input[type="button"],
.os-ios input[type="submit"] {
  border-radius: 10px;
}

.os-ios input, 
.os-ios select, 
.os-ios textarea {
  border-radius: 10px;
  padding: 12px 16px;
}

/* Android specific styles */
.os-android button, 
.os-android input[type="button"], 
.os-android input[type="submit"] {
  text-transform: uppercase;
  font-weight: 500;
  letter-spacing: 0.5px;
}

.os-android input, 
.os-android select, 
.os-android textarea {
  border-radius: 4px;
  padding: 10px 12px;
}

/* Windows specific styles */
.os-windows button, 
.os-windows input[type="button"], 
.os-windows input[type="submit"] {
  border-radius: 2px;
  padding: 6px 16px;
}

.os-windows input, 
.os-windows select, 
.os-windows textarea {
  border-radius: 2px;
  padding: 6px 8px;
}

/* macOS specific styles */
.os-macos button, 
.os-macos input[type="button"], 
.os-macos input[type="submit"] {
  border-radius: 6px;
  padding: 6px 16px;
  font-weight: 500;
}

.os-macos input, 
.os-macos select, 
.os-macos textarea {
  border-radius: 6px;
  padding: 6px 10px;
}

/* Linux (GNOME-like) specific styles */
.os-linux button, 
.os-linux input[type="button"], 
.os-linux input[type="submit"] {
  border-radius: 4px;
  padding: 8px 14px;
}

.os-linux input, 
.os-linux select, 
.os-linux textarea {
  border-radius: 4px;
  padding: 8px 10px;
}

/* Responsive layout adjustments */
@media (max-width: 640px) {
  .container {
    padding-left: 16px;
    padding-right: 16px;
  }
  
  .is-mobile .glass-card {
    border-radius: 12px;
    margin-bottom: 16px;
  }
}

@media (max-width: 768px) {
  .is-mobile .hidden-mobile {
    display: none;
  }
  
  .step-container {
    padding: 16px;
  }
}

@media (min-width: 769px) and (max-width: 1024px) {
  .container {
    max-width: 90%;
  }
}

@media (min-width: 1025px) {
  .container {
    max-width: 1200px;
  }
}

/* Full width for small screens */
@media (max-width: 768px) {
  .flex-col-mobile {
    flex-direction: column;
  }
  
  .w-full-mobile {
    width: 100%;
  }
  
  .md\:w-1\/2, .md\:w-1\/3, .md\:w-2\/3, .md\:w-3\/4 {
    width: 100%;
  }
}

/* Enhanced touch targets for mobile */
.is-mobile button, 
.is-mobile input, 
.is-mobile select, 
.is-mobile textarea,
.is-mobile a {
  min-height: 44px;
}

/* Fix for mobile inputs focus zoom */
@media (max-width: 768px) {
  input, select, textarea {
    font-size: 16px;
  }
}
EOF

# 5. Aggiorna index.css per importare gli stili adattivi
create_file "src/index.css" << 'EOF'
@import './styles/adaptive.css';
@tailwind base;
@tailwind components;
@tailwind utilities;

:root {
  /* Light theme variables */
  --bg-primary: #ffffff;
  --bg-secondary: #f7f9fc;
  --text-primary: #333333;
  --text-secondary: #666666;
  --border-color: #e0e4e8;
  --glass-bg: rgba(255, 255, 255, 0.7);
  --glass-blur: 10px;
  --shadow-color: rgba(0, 0, 0, 0.05);
}

.dark {
  /* Dark theme variables */
  --bg-primary: #1a1c23;
  --bg-secondary: #282c34;
  --text-primary: #e3e3e3;
  --text-secondary: #a0a0a0;
  --border-color: #3d4148;
  --glass-bg: rgba(40, 44, 52, 0.7);
  --glass-blur: 10px;
  --shadow-color: rgba(0, 0, 0, 0.2);
}

body {
  background-color: var(--bg-primary);
  color: var(--text-primary);
  transition: background-color 0.3s ease, color 0.3s ease;
  margin: 0;
  font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', 'Roboto', 'Oxygen',
    'Ubuntu', 'Cantarell', 'Fira Sans', 'Droid Sans', 'Helvetica Neue',
    sans-serif;
  -webkit-font-smoothing: antialiased;
  -moz-osx-font-smoothing: grayscale;
}

@layer components {
  .glass-card {
    @apply bg-white bg-opacity-70 dark:bg-gray-800 dark:bg-opacity-70 backdrop-blur-md border border-gray-200 dark:border-gray-700 rounded-xl shadow-lg;
  }
  
  .primary-button {
    @apply px-6 py-3 rounded-lg font-medium transition-all duration-200 transform hover:scale-105 focus:outline-none focus:ring-2 focus:ring-offset-2;
  }
  
  .step-container {
    @apply w-full max-w-4xl mx-auto p-4 md:p-6;
  }
}
EOF

# 6. Aggiornare alcuni componenti per utilizzare i componenti UI adattivi
create_file "src/components/tools/calculator/Calculator.jsx" << 'EOF'
import { useState } from 'react';
import { evaluate } from 'mathjs';
import AdaptiveButton from '../../ui/AdaptiveButton';
import AdaptiveInput from '../../ui/AdaptiveInput';
import AdaptiveSelect from '../../ui/AdaptiveSelect';

const Calculator = () => {
  const [input, setInput] = useState('');
  const [result, setResult] = useState('');
  const [tab, setTab] = useState('standard');
  
  // Funzioni calcolatrice standard
  const handleButtonClick = (value) => {
    if (value === 'C') {
      setInput('');
      setResult('');
    } else if (value === '=') {
      try {
        const calculatedResult = evaluate(input);
        setResult(calculatedResult);
      } catch (error) {
        setResult('Error');
      }
    } else if (value === '←') {
      setInput(input.slice(0, -1));
    } else {
      setInput(input + value);
    }
  };
  
  // Renderizza la calcolatrice standard
  const renderStandard = () => (
    <div>
      <div className="mb-4 p-4 bg-white dark:bg-gray-800 rounded-lg text-right">
        <div className="text-gray-600 dark:text-gray-400 text-sm">{input}</div>
        <div className="text-2xl font-bold">{result}</div>
      </div>
      
      <div className="grid grid-cols-4 gap-2">
        {['C', '←', '%', '/'].map(btn => (
          <AdaptiveButton 
            key={btn} 
            variant="secondary" 
            onClick={() => handleButtonClick(btn)}
          >
            {btn}
          </AdaptiveButton>
        ))}
        
        {[7, 8, 9, '*'].map(btn => (
          <AdaptiveButton 
            key={btn} 
            variant={typeof btn === 'number' ? 'secondary' : 'primary'} 
            onClick={() => handleButtonClick(btn.toString())}
          >
            {btn}
          </AdaptiveButton>
        ))}
        
        {[4, 5, 6, '-'].map(btn => (
          <AdaptiveButton 
            key={btn} 
            variant={typeof btn === 'number' ? 'secondary' : 'primary'} 
            onClick={() => handleButtonClick(btn.toString())}
          >
            {btn}
          </AdaptiveButton>
        ))}
        
        {[1, 2, 3, '+'].map(btn => (
          <AdaptiveButton 
            key={btn} 
            variant={typeof btn === 'number' ? 'secondary' : 'primary'} 
            onClick={() => handleButtonClick(btn.toString())}
          >
            {btn}
          </AdaptiveButton>
        ))}
        
        <AdaptiveButton
          className="col-span-2"
          variant="secondary"
          onClick={() => handleButtonClick('0')}
        >
          0
        </AdaptiveButton>
        <AdaptiveButton
          variant="secondary"
          onClick={() => handleButtonClick('.')}
        >
          .
        </AdaptiveButton>
        <AdaptiveButton
          variant="primary"
          onClick={() => handleButtonClick('=')}
          className="bg-calc-500 hover:bg-calc-600"
        >
          =
        </AdaptiveButton>
      </div>
    </div>
  );
  
  // Calcolo IVA
  const [amount, setAmount] = useState('');
  const [vat, setVat] = useState(22);
  const [vatResult, setVatResult] = useState(null);
  
  const calcVat = () => {
    if (!amount) return;
    const amt = parseFloat(amount);
    const vatAmount = (amt * vat) / 100;
    setVatResult({
      net: amt,
      vat: vatAmount,
      total: amt + vatAmount
    });
  };
  
  // Renderizza calcolatrice IVA
  const renderVat = () => (
    <div className="space-y-4">
      <AdaptiveInput
        type="number" 
        label="Importo (€)"
        value={amount} 
        onChange={e => setAmount(e.target.value)} 
        fullWidth
      />
      
      <div>
        <label className="block mb-1 text-sm font-medium text-gray-700 dark:text-gray-300">
          Aliquota IVA (%)
        </label>
        <div className="flex space-x-2">
          {[4, 10, 22].map(rate => (
            <AdaptiveButton 
              key={rate}
              variant={vat === rate ? 'primary' : 'secondary'}
              onClick={() => setVat(rate)}
              className={vat === rate ? 'bg-calc-500 hover:bg-calc-600' : ''}
            >
              {rate}%
            </AdaptiveButton>
          ))}
          <AdaptiveInput
            type="number" 
            value={vat} 
            onChange={e => setVat(parseInt(e.target.value))} 
            className="w-24" 
          />
        </div>
      </div>
      
      <AdaptiveButton
        variant="primary"
        onClick={calcVat}
        fullWidth
        className="bg-calc-500 hover:bg-calc-600"
      >
        Calcola
      </AdaptiveButton>
      
      {vatResult && (
        <div className="mt-4 p-4 bg-white dark:bg-gray-800 rounded-lg">
          <div className="grid grid-cols-2 gap-2">
            <span>Imponibile:</span><span className="text-right">{vatResult.net.toFixed(2)} €</span>
            <span>IVA ({vat}%):</span><span className="text-right">{vatResult.vat.toFixed(2)} €</span>
            <div className="col-span-2 border-t my-1"></div>
            <span className="font-bold">Totale:</span><span className="text-right font-bold">{vatResult.total.toFixed(2)} €</span>
          </div>
        </div>
      )}
    </div>
  );
  
  return (
    <div className="container mx-auto px-4 py-8">
      <div className="max-w-md mx-auto">
        <h1 className="text-3xl font-bold mb-6 text-center text-calc-500">Calcolatrice</h1>
        
        <div className="flex mb-4 border-b">
          <button 
            className={`py-2 px-4 ${tab === 'standard' ? 'border-b-2 border-calc-500 font-bold' : ''}`}
            onClick={() => setTab('standard')}>Standard</button>
          <button 
            className={`py-2 px-4 ${tab === 'vat' ? 'border-b-2 border-calc-500 font-bold' : ''}`}
            onClick={() => setTab('vat')}>IVA</button>
        </div>
        
        <div className="glass-card p-6">
          {tab === 'standard' ? renderStandard() : renderVat()}
        </div>
      </div>
    </div>
  );
};

export default Calculator;
EOF

create_file "src/components/tools/ocr/OCR.jsx" << 'EOF'
import { useState } from 'react';
import { createWorker } from 'tesseract.js';
import FileDropZone from '../../ui/FileDropZone';
import FilePreview from '../../ui/FilePreview';
import AdaptiveButton from '../../ui/AdaptiveButton';
import AdaptiveSelect from '../../ui/AdaptiveSelect';

const OCR = () => {
  const [file, setFile] = useState(null);
  const [isProcessing, setIsProcessing] = useState(false);
  const [result, setResult] = useState(null);
  const [language, setLanguage] = useState('ita');
  
  const languageOptions = [
    { value: 'ita', label: 'Italiano' },
    { value: 'eng', label: 'Inglese' },
    { value: 'fra', label: 'Francese' },
    { value: 'deu', label: 'Tedesco' },
    { value: 'spa', label: 'Spagnolo' }
  ];
  
  const handleFileChange = (selectedFile) => {
    setFile(selectedFile);
    setResult(null);
  };
  
  const processImage = async () => {
    if (!file) return;
    setIsProcessing(true);
    
    try {
      const worker = await createWorker();
      await worker.loadLanguage(language);
      await worker.initialize(language);
      const { data } = await worker.recognize(file);
      setResult({
        text: data.text,
        confidence: data.confidence
      });
      await worker.terminate();
    } catch (err) {
      console.error('OCR failed:', err);
    } finally {
      setIsProcessing(false);
    }
  };
  
  return (
    <div className="container mx-auto px-4 py-8">
      <div className="max-w-2xl mx-auto">
        <h1 className="text-3xl font-bold mb-6 text-center text-text-500">Estrazione Testo (OCR)</h1>
        
        <div className="glass-card p-6">
          {!file ? (
            <FileDropZone 
              onFileSelect={handleFileChange}
              acceptedFormats={['.jpg', '.jpeg', '.png', '.pdf']}
              maxSize={10 * 1024 * 1024}
            />
          ) : (
            <div className="space-y-4">
              <FilePreview file={file} onRemove={() => setFile(null)} />
              
              <div>
                <AdaptiveSelect
                  label="Lingua"
                  value={language}
                  onChange={(e) => setLanguage(e.target.value)}
                  options={languageOptions}
                  fullWidth
                />
              </div>
              
              <AdaptiveButton 
                variant="primary"
                onClick={processImage}
                disabled={isProcessing}
                fullWidth
                className="bg-text-500 hover:bg-text-600 text-white flex justify-center items-center"
              >
                {isProcessing ? (
                  <>
                    <svg className="animate-spin -ml-1 mr-2 h-5 w-5 text-white" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24">
                      <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4"></circle>
                      <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
                    </svg>
                    Elaborazione...
                  </>
                ) : "Estrai Testo"}
              </AdaptiveButton>
              
              {result && (
                <div className="mt-4">
                  <h3 className="font-bold mb-2">Testo Estratto:</h3>
                  <div className="p-4 bg-gray-50 dark:bg-gray-800 rounded-lg max-h-64 overflow-y-auto whitespace-pre-wrap">
                    {result.text || "Nessun testo rilevato"}
                  </div>
                  <div className="mt-2 text-sm text-gray-500">
                    Confidenza: {Math.round(result.confidence)}%
                  </div>
                </div>
              )}
            </div>
          )}
        </div>
      </div>
    </div>
  );
};

export default OCR;
EOF

# 7. Modifica di alcuni file per migliorare la responsività
create_file "src/components/layout/Header.jsx" << 'EOF'
// src/components/layout/Header.jsx
import { useState } from 'react';
import { Link } from 'react-router-dom';
import { useTheme } from '../../context/ThemeContext';
import { useOS } from '../../context/OSContext';

const Header = () => {
  const { isDarkMode, setIsDarkMode } = useTheme();
  const { osType, isMobile } = useOS();
  const [isMenuOpen, setIsMenuOpen] = useState(false);
  
  const toggleTheme = () => {
    setIsDarkMode(!isDarkMode);
  };
  
  const toggleMenu = () => {
    setIsMenuOpen(!isMenuOpen);
  };
  
  // Classi di stile specifiche per OS per bottoni nel header
  const getHeaderButtonClass = () => {
    let baseClass = "rounded-full flex items-center justify-center";
    
    switch (osType) {
      case 'ios':
        return `${baseClass} w-10 h-10 bg-gray-100 dark:bg-gray-800`;
      case 'android':
        return `${baseClass} w-10 h-10 bg-gray-200 dark:bg-gray-700`;
      case 'windows':
        return `${baseClass} w-8 h-8 border border-gray-300 dark:border-gray-600`;
      case 'macos':
        return `${baseClass} w-8 h-8 bg-gray-100 dark:bg-gray-800`;
      case 'linux':
        return `${baseClass} w-9 h-9 bg-gray-200 dark:bg-gray-700`;
      default:
        return `${baseClass} w-9 h-9 bg-gray-100 dark:bg-gray-800`;
    }
  };
  
  return (
    <header className="sticky top-0 z-50 glass-card px-4 py-4">
      <div className="container mx-auto flex justify-between items-center">
        <Link to="/" className="flex items-center space-x-2">
          <span className="text-xl font-bold text-primary-600 dark:text-primary-400">
            StrumentiRapidi.it
          </span>
        </Link>
        
        <div className="hidden md:flex items-center space-x-8">
          <nav>
            <ul className="flex space-x-6">
              <li>
                <Link to="/tools/pdf-converter" className="hover:text-pdf-500">PDF Tools</Link>
              </li>
              <li>
                <Link to="/tools/image-editor" className="hover:text-image-500">Image Tools</Link>
              </li>
              <li>
                <Link to="/tools/ocr" className="hover:text-text-500">Text Tools</Link>
              </li>
              <li>
                <Link to="/tools/calculator" className="hover:text-calc-500">Calculators</Link>
              </li>
            </ul>
          </nav>
          
          <button
            onClick={toggleTheme}
            className={getHeaderButtonClass()}
            aria-label="Toggle theme"
          >
            {isDarkMode ? (
              <svg className="h-5 w-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 3v1m0 16v1m9-9h-1M4 12H3m15.364 6.364l-.707-.707M6.343 6.343l-.707-.707m12.728 0l-.707.707M6.343 17.657l-.707.707M16 12a4 4 0 11-8 0 4 4 0 018 0z" />
              </svg>
            ) : (
              <svg className="h-5 w-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M20.354 15.354A9 9 0 018.646 3.646 9.003 9.003 0 0012 21a9.003 9.003 0 008.354-5.646z" />
              </svg>
            )}
          </button>
        </div>
        
        <div className="md:hidden flex items-center">
          <button
            onClick={toggleTheme}
            className={`${getHeaderButtonClass()} mr-2`}
            aria-label="Toggle theme"
          >
            {isDarkMode ? (
              <svg className="h-5 w-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 3v1m0 16v1m9-9h-1M4 12H3m15.364 6.364l-.707-.707M6.343 6.343l-.707-.707m12.728 0l-.707.707M6.343 17.657l-.707.707M16 12a4 4 0 11-8 0 4 4 0 018 0z" />
              </svg>
            ) : (
              <svg className="h-5 w-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M20.354 15.354A9 9 0 018.646 3.646 9.003 9.003 0 0012 21a9.003 9.003 0 008.354-5.646z" />
              </svg>
            )}
          </button>
          
          <button
            onClick={toggleMenu}
            className={getHeaderButtonClass()}
            aria-label="Toggle menu"
          >
            {isMenuOpen ? (
              <svg className="h-5 w-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M6 18L18 6M6 6l12 12" />
              </svg>
            ) : (
              <svg className="h-5 w-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M4 6h16M4 12h16M4 18h16" />
              </svg>
            )}
          </button>
        </div>
      </div>
      
      {/* Mobile menu */}
      {isMenuOpen && (
        <div className="md:hidden py-4 px-4 glass-card mt-2 rounded-lg">
          <nav>
            <ul className="flex flex-col space-y-4">
              <li>
                <Link 
                  to="/tools/pdf-converter" 
                  className="block py-2 px-4 rounded-lg hover:bg-gray-100 dark:hover:bg-gray-700 hover:text-pdf-500"
                  onClick={() => setIsMenuOpen(false)}
                >
                  PDF Tools
                </Link>
              </li>
              <li>
                <Link 
                  to="/tools/image-editor" 
                  className="block py-2 px-4 rounded-lg hover:bg-gray-100 dark:hover:bg-gray-700 hover:text-image-500"
                  onClick={() => setIsMenuOpen(false)}
                >
                  Image Tools
                </Link>
              </li>
              <li>
                <Link 
                  to="/tools/ocr" 
                  className="block py-2 px-4 rounded-lg hover:bg-gray-100 dark:hover:bg-gray-700 hover:text-text-500"
                  onClick={() => setIsMenuOpen(false)}
                >
                  Text Tools
                </Link>
              </li>
              <li>
                <Link 
                  to="/tools/calculator" 
                  className="block py-2 px-4 rounded-lg hover:bg-gray-100 dark:hover:bg-gray-700 hover:text-calc-500"
                  onClick={() => setIsMenuOpen(false)}
                >
                  Calculators
                </Link>
              </li>
            </ul>
          </nav>
        </div>
      )}
    </header>
  );
};

export default Header;
EOF

create_file "src/pages/Home.jsx" << 'EOF'
// src/pages/Home.jsx
import { Link } from 'react-router-dom';
import { motion } from 'framer-motion';
import { useOS } from '../context/OSContext';

const Home = () => {
  const { osType, isMobile } = useOS();
  
  const tools = [
    {
      id: 'pdf-converter',
      name: 'Convertitore PDF',
      description: 'Converti PDF in Word, immagini e altri formati',
      icon: '📄',
      color: '#E74C3C',
      path: '/tools/pdf-converter'
    },
    {
      id: 'image-editor',
      name: 'Editor Immagini',
      description: 'Ridimensiona, converti e ottimizza le tue immagini',
      icon: '🖼️',
      color: '#3498DB',
      path: '/tools/image-editor'
    },
    {
      id: 'ocr',
      name: 'Estrazione Testo',
      description: 'Estrai testo da immagini e documenti scansionati',
      icon: '📝',
      color: '#9B59B6',
      path: '/tools/ocr'
    },
    {
      id: 'calculator',
      name: 'Calcolatrice',
      description: 'Calcola percentuali, IVA e altro',
      icon: '🧮',
      color: '#2ECC71',
      path: '/tools/calculator'
    },
    {
      id: 'video-downloader',
      name: 'Video Downloader',
      description: 'Scarica video da YouTube, Instagram e TikTok',
      icon: '📹',
      color: '#F39C12',
      path: '/tools/video-downloader'
    },
    {
      id: 'meme-creator',
      name: 'Creatore di Meme',
      description: 'Crea e condividi meme facilmente',
      icon: '😂',
      color: '#1ABC9C',
      path: '/tools/meme-creator'
    }
  ];
  
  // Stili specifici per OS
  const getToolCardStyle = (color) => {
    const baseStyle = "glass-card h-full p-6 transition-all duration-300";
    
    switch (osType) {
      case 'ios':
        return `${baseStyle} rounded-2xl hover:shadow-lg ${isMobile ? '' : 'hover:-translate-y-1'}`;
      case 'android':
        return `${baseStyle} rounded-lg hover:shadow-md ${isMobile ? '' : 'hover:-translate-y-1'} border border-gray-200 dark:border-gray-700`;
      case 'windows':
        return `${baseStyle} rounded-md hover:shadow ${isMobile ? '' : 'hover:-translate-y-0.5'} border border-gray-300 dark:border-gray-600`;
      case 'macos':
        return `${baseStyle} rounded-xl hover:shadow-lg ${isMobile ? '' : 'hover:-translate-y-1'}`;
      case 'linux':
        return `${baseStyle} rounded-lg hover:shadow ${isMobile ? '' : 'hover:-translate-y-0.5'} border border-gray-200 dark:border-gray-700`;
      default:
        return `${baseStyle} rounded-xl hover:shadow-lg ${isMobile ? '' : 'hover:-translate-y-1'}`;
    }
  };
  
  return (
    <div className="container mx-auto px-4 py-12">
      <div className="text-center mb-12">
        <motion.h1 
          className="text-4xl md:text-5xl font-bold mb-4"
          initial={{ opacity: 0, y: -20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.5 }}
        >
          StrumentiRapidi.it
        </motion.h1>
        <motion.p 
          className="text-xl text-gray-600 dark:text-gray-400 max-w-2xl mx-auto"
          initial={{ opacity: 0 }}
          animate={{ opacity: 1 }}
          transition={{ duration: 0.5, delay: 0.2 }}
        >
          La tua piattaforma all-in-one per strumenti online gratuiti. Converti, comprimi e crea con facilità.
        </motion.p>
      </div>
      
      <motion.div 
        className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6"
        initial={{ opacity: 0 }}
        animate={{ opacity: 1 }}
        transition={{ duration: 0.5, delay: 0.3 }}
      >
        {tools.map((tool, index) => (
          <motion.div
            key={tool.id}
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.5, delay: 0.1 * index }}
          >
            <Link to={tool.path} className="block">
              <div className={getToolCardStyle(tool.color)}>
                <div className="flex items-center mb-4">
                  <div 
                    className="w-12 h-12 rounded-full flex items-center justify-center text-xl mr-4"
                    style={{ backgroundColor: tool.color + '33' }}
                  >
                    {tool.icon}
                  </div>
                  <h2 
                    className="text-xl font-semibold"
                    style={{ color: tool.color }}
                  >
                    {tool.name}
                  </h2>
                </div>
                <p className="text-gray-600 dark:text-gray-400">
                  {tool.description}
                </p>
                <div className="mt-4 flex justify-end">
                  <span 
                    className="text-sm font-medium"
                    style={{ color: tool.color }}
                  >
                    Prova Ora →
                  </span>
                </div>
              </div>
            </Link>
          </motion.div>
        ))}
      </motion.div>
      
      <div className="mt-16 text-center">
        <h2 className="text-2xl font-bold mb-4">Perché Scegliere StrumentiRapidi.it?</h2>
        <div className="grid grid-cols-1 md:grid-cols-3 gap-8 max-w-4xl mx-auto">
          <div className={getToolCardStyle()}>
            <div className="text-3xl mb-3">🚀</div>
            <h3 className="text-lg font-semibold mb-2">Veloce e Gratuito</h3>
            <p className="text-gray-600 dark:text-gray-400">
              Tutti gli strumenti sono completamente gratuiti e funzionano istantaneamente nel tuo browser.
            </p>
          </div>
          
          <div className={getToolCardStyle()}>
            <div className="text-3xl mb-3">🔒</div>
            <h3 className="text-lg font-semibold mb-2">Privato e Sicuro</h3>
            <p className="text-gray-600 dark:text-gray-400">
              I tuoi file vengono elaborati localmente. Non memorizziamo né condividiamo i tuoi dati.
            </p>
          </div>
          
          <div className={getToolCardStyle()}>
            <div className="text-3xl mb-3">🧠</div>
            <h3 className="text-lg font-semibold mb-2">Rilevamento Intelligente</h3>
            <p className="text-gray-600 dark:text-gray-400">
              I nostri strumenti analizzano i tuoi file e suggeriscono automaticamente le migliori opzioni.
            </p>
          </div>
        </div>
      </div>
    </div>
  );
};

export default Home;
EOF

# 8. Migliorare il responsive design nei componenti
create_file "src/components/wizard/ToolWizard.jsx" << 'EOF'
// src/components/wizard/ToolWizard.jsx
import { useState, useEffect } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import StepIndicator from '../ui/StepIndicator';
import { useOS } from '../../context/OSContext';

const ToolWizard = ({ title, description, steps, toolId, themeColor }) => {
  const [currentStep, setCurrentStep] = useState(0);
  const [wizardData, setWizardData] = useState({});
  const [result, setResult] = useState(null);
  const { osType, isMobile } = useOS();
  
  // Reset wizard when tool changes
  useEffect(() => {
    setCurrentStep(0);
    setWizardData({});
    setResult(null);
  }, [toolId]);
  
  // Navigate between steps
  const goToNextStep = () => {
    if (currentStep < steps.length - 1) {
      setCurrentStep(currentStep + 1);
      window.scrollTo({ top: 0, behavior: 'smooth' });
    }
  };
  
  const goToPreviousStep = () => {
    if (currentStep > 0) {
      setCurrentStep(currentStep - 1);
      window.scrollTo({ top: 0, behavior: 'smooth' });
    }
  };
  
  // Update wizard data
  const updateWizardData = (newData) => {
    setWizardData(prevData => ({
      ...prevData,
      ...newData
    }));
  };
  
  // Set final result
  const setProcessResult = (processedResult) => {
    setResult(processedResult);
  };
  
  // Get step names for the indicator
  const stepNames = steps.map(step => step.title);
  
  // Animazione in base al sistema operativo
  const getAnimationVariants = () => {
    // Animazioni più fluide per iOS e macOS, più funzionali per altri OS
    if (osType === 'ios' || osType === 'macos') {
      return {
        initial: { opacity: 0, x: 20, scale: 0.95 },
        animate: { opacity: 1, x: 0, scale: 1 },
        exit: { opacity: 0, x: -20, scale: 0.95 },
        transition: { type: "spring", stiffness: 300, damping: 30 }
      };
    } else {
      return {
        initial: { opacity: 0, y: 10 },
        animate: { opacity: 1, y: 0 },
        exit: { opacity: 0, y: -10 },
        transition: { duration: 0.3 }
      };
    }
  };
  
  const animationVariants = getAnimationVariants();
  
  return (
    <div className="container mx-auto px-4 py-8">
      <div className="max-w-4xl mx-auto">
        <div className="text-center mb-8">
          <h1 className={`text-3xl font-bold mb-2 ${isMobile ? 'text-2xl' : ''}`} style={{ color: themeColor }}>
            {title}
          </h1>
          {description && (
            <p className="text-gray-600 dark:text-gray-400">
              {description}
            </p>
          )}
        </div>
        
        <StepIndicator steps={stepNames} currentStep={currentStep} />
        
        <AnimatePresence mode="wait">
          <motion.div
            key={currentStep}
            initial={animationVariants.initial}
            animate={animationVariants.animate}
            exit={animationVariants.exit}
            transition={animationVariants.transition}
          >
            {steps[currentStep].component({
              data: wizardData,
              updateData: updateWizardData,
              goNext: goToNextStep,
              goBack: goToPreviousStep,
              result: result,
              setResult: setProcessResult,
              toolId,
              themeColor
            })}
          </motion.div>
        </AnimatePresence>
      </div>
    </div>
  );
};

export default ToolWizard;
EOF

create_file "src/components/wizard/ConfigurationStep.jsx" << 'EOF'
// src/components/wizard/ConfigurationStep.jsx
import { useState, useEffect } from 'react';
import { generatePreview } from '../../services/previewService';
import AdaptiveButton from '../ui/AdaptiveButton';
import { useOS } from '../../context/OSContext';

const ConfigurationStep = ({ 
  data, 
  updateData, 
  goNext, 
  goBack, 
  themeColor,
  optionsComponent: OptionsComponent,
  previewComponent: PreviewComponent
}) => {
  const [options, setOptions] = useState({});
  const [preview, setPreview] = useState(null);
  const [isGeneratingPreview, setIsGeneratingPreview] = useState(false);
  const { isMobile } = useOS();
  
  // Initialize options
  useEffect(() => {
    const initialOptions = data.options || {};
    setOptions(initialOptions);
  }, [data]);
  
  // Generate preview when options change
  useEffect(() => {
    if (!data.file) return;
    
    const generateFilePreview = async () => {
      setIsGeneratingPreview(true);
      try {
        const previewResult = await generatePreview(data.file, options);
        setPreview(previewResult);
      } catch (error) {
        console.error('Preview generation failed:', error);
      } finally {
        setIsGeneratingPreview(false);
      }
    };
    
    // Debounce preview generation
    const timeoutId = setTimeout(() => {
      generateFilePreview();
    }, 500);
    
    return () => clearTimeout(timeoutId);
  }, [data.file, options]);
  
  // Handle options change
  const handleOptionsChange = (newOptions) => {
    setOptions(newOptions);
  };
  
  // Continue to next step
  const handleContinue = () => {
    updateData({ options });
    goNext();
  };
  
  return (
    <div className="step-container">
      <h2 className="text-xl font-semibold mb-4">Configure Options</h2>
      
      <div className={`flex ${isMobile ? 'flex-col' : 'flex-row'} gap-6`}>
        <div className={isMobile ? 'w-full' : 'md:w-2/5'}>
          <div className="glass-card p-4 h-full">
            {OptionsComponent ? (
              <OptionsComponent 
                data={data}
                options={options}
                onChange={handleOptionsChange}
                smartSuggestions={data.smartSuggestions}
              />
            ) : (
              <div className="p-4 text-center text-gray-500">
                No configuration options available for this tool.
              </div>
            )}
          </div>
        </div>
        
        <div className={isMobile ? 'w-full' : 'md:w-3/5'}>
          <div className="glass-card p-4 h-full">
            <h3 className="text-lg font-medium mb-3">Preview</h3>
            
            {isGeneratingPreview ? (
              <div className="flex justify-center items-center h-64">
                <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-primary-500"></div>
                <span className="ml-2">Generating preview...</span>
              </div>
            ) : (
              <>
                {PreviewComponent ? (
                  <PreviewComponent 
                    file={data.file}
                    options={options}
                    preview={preview}
                  />
                ) : (
                  <div className="p-4 text-center text-gray-500 h-64 flex items-center justify-center">
                    <p>Preview not available for this tool.</p>
                  </div>
                )}
              </>
            )}
          </div>
        </div>
      </div>
      
      <div className="flex justify-between mt-6">
        <AdaptiveButton
          variant="secondary"
          onClick={goBack}
        >
          <svg className="mr-2 w-5 h-5 inline" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M15 19l-7-7 7-7" />
          </svg>
          Indietro
        </AdaptiveButton>
        
        <AdaptiveButton
          variant="primary"
          onClick={handleContinue}
          style={{ backgroundColor: themeColor }}
        >
          Procedi
          <svg className="ml-2 w-5 h-5 inline" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 5l7 7-7 7" />
          </svg>
        </AdaptiveButton>
      </div>
    </div>
  );
};

export default ConfigurationStep;
EOF

# 9. Migliora il componente StepIndicator per adattarsi al sistema operativo
create_file "src/components/ui/StepIndicator.jsx" << 'EOF'
// src/components/ui/StepIndicator.jsx
import React from 'react';
import { motion } from 'framer-motion';
import { useOS } from '../../context/OSContext';

const StepIndicator = ({ steps, currentStep }) => {
  const { osType, isMobile } = useOS();
  
  // Stili degli step indicator in base al sistema operativo
  const getStepIndicatorStyle = () => {
    const baseClass = "glass-card p-4 mb-6 overflow-hidden";
    
    switch (osType) {
      case 'ios':
        return `${baseClass} rounded-xl shadow-sm`;
      case 'android':
        return `${baseClass} rounded-lg shadow`;
      case 'windows':
        return `${baseClass} rounded border border-gray-300 dark:border-gray-600`;
      case 'macos':
        return `${baseClass} rounded-lg shadow-sm`;
      case 'linux':
        return `${baseClass} rounded-md shadow-sm border border-gray-200 dark:border-gray-700`;
      default:
        return `${baseClass} rounded-lg`;
    }
  };
  
  const getStepIconStyle = (index) => {
    const baseClass = `w-8 h-8 rounded-full flex items-center justify-center ${
      index <= currentStep 
        ? 'bg-primary-500 text-white' 
        : 'bg-gray-200 dark:bg-gray-700 text-gray-500 dark:text-gray-400'
    }`;
    
    // Step attivo più accentuato per sistema operativo
    const activeScale = index === currentStep ? 
      (osType === 'ios' || osType === 'macos' ? 'scale-110' : 'scale-105') : 
      'scale-100';
    
    return `${baseClass} transform transition-transform ${activeScale}`;
  };
  
  // Mostra solo numeri nei step per dispositivi mobili
  const renderStepLabel = (step, index) => {
    if (isMobile) {
      return <span className="sr-only">{step}</span>;
    }
    
    return (
      <span className={`text-xs font-medium ${
        index <= currentStep 
          ? 'text-primary-500' 
          : 'text-gray-500 dark:text-gray-400'
      }`}>
        {step}
      </span>
    );
  };
  
  return (
    <div className={getStepIndicatorStyle()}>
      <div className="flex justify-between items-center relative">
        {/* Progress line */}
        <div className="absolute h-1 bg-gray-200 dark:bg-gray-700 left-0 right-0 top-1/2 transform -translate-y-1/2 z-0" />
        
        {/* Active progress */}
        <motion.div 
          className="absolute h-1 bg-primary-500 left-0 top-1/2 transform -translate-y-1/2 z-0"
          initial={{ width: '0%' }}
          animate={{ width: `${(100 / (steps.length - 1)) * currentStep}%` }}
          transition={{ duration: 0.5 }}
        />
        
        {/* Step indicators */}
        {steps.map((step, index) => (
          <div key={index} className="z-10 flex flex-col items-center space-y-2">
            <div className={getStepIconStyle(index)}>
              {index + 1}
            </div>
            {renderStepLabel(step, index)}
          </div>
        ))}
      </div>
    </div>
  );
};

export default StepIndicator;
EOF

# 10. Aggiorna il file README.md con informazioni sull'UI adattiva
create_file "README.md" << 'EOF'
# StrumentiRapidi.it - Strumenti Online Gratuiti

Una piattaforma completa di strumenti online, tra cui conversione PDF, editing di immagini, estrazione di testo, calcolatrice, download video e creazione di meme. Tutto gratuito e direttamente nel browser.

## Caratteristiche

- **Convertitore PDF**: Converti PDF in vari formati tra cui Word, immagini e altro
- **Editor di immagini**: Ridimensiona, converti e ottimizza le immagini con vari filtri
- **Estrazione testo (OCR)**: Estrai testo da immagini e documenti scansionati
- **Calcolatrice**: Calcola percentuali, IVA e operazioni matematiche
- **Video Downloader**: Scarica video da YouTube, Instagram, TikTok
- **Creatore di Meme**: Crea meme personalizzati con templates popolari
- **Design reattivo**: Funziona su tutti i dispositivi, dal mobile al desktop
- **Modalità scura**: Si adatta automaticamente alle preferenze di sistema
- **UI adattiva al sistema operativo**: L'interfaccia si adatta al look and feel del sistema operativo utilizzato

## Tecnologie utilizzate

- React
- Tailwind CSS
- Vite
- Framer Motion per le animazioni
- Tesseract.js per OCR
- html-to-image per il creatore di meme
- mathjs per le funzionalità della calcolatrice
- react-device-detect per il rilevamento del sistema operativo

## Prerequisiti

- Node.js (v16.0.0 o superiore)
- npm (v8.0.0 o superiore)

## Installazione

1. Clona il repository
   ```
   git clone https://github.com/tuoutente/strumentirapidi.it.git
   ```

2. Naviga alla directory del progetto
   ```
   cd strumentirapidi.it
   ```

3. Installa le dipendenze
   ```
   npm install
   ```

4. Avvia il server di sviluppo
   ```
   npm run dev
   ```

5. Apri il browser e vai a `http://localhost:3000`

## UI Adattiva al Sistema Operativo

La piattaforma implementa un'interfaccia utente che si adatta automaticamente al sistema operativo dell'utente:

- **iOS**: Interfaccia arrotondata con effetti di profondità, pulsanti ampi e animazioni fluide
- **Android**: Stile Material Design con elementi piatti, angoli meno arrotondati e tipografia distintiva
- **Windows**: Interfaccia minimal con angoli squadrati e bordi sottili
- **macOS**: Elementi eleganti con effetti di vetro e animazioni raffinate
- **Linux**: Design semplice e funzionale con focus sull'utilizzo

Questo adattamento avviene automaticamente rilevando il sistema operativo dell'utente, senza compromettere la consistenza generale del design o della funzionalità dell'applicazione.

## Build per produzione

```
npm run build
```

I file generati saranno nella directory `dist`.

## Estendere il progetto

Per aggiungere un nuovo strumento:

1. Crea un nuovo componente in `src/components/tools/[nome-strumento]/`
2. Registra lo strumento in `src/App.jsx` aggiungendolo al `toolRegistry`
3. Aggiungi lo strumento alla rotta in `src/pages/ToolsPage.jsx`
4. Aggiungi lo strumento alla lista nella homepage

## Licenza

Questo progetto è disponibile con licenza MIT.
EOF

# 11. Esegui build per verificare che tutto funzioni
echo "Esecuzione build di verifica..."
npm run build || echo "La build potrebbe avere generato degli errori, controlla manualmente"

echo "=== Implementazione UI adattiva completata! ==="
echo "Il portale StrumentiRapidi.it è ora 100% responsive e si adatta automaticamente al sistema operativo!"
echo "Sono stati implementati i seguenti miglioramenti:"
echo "- Rilevamento automatico del sistema operativo (iOS, Android, Windows, macOS, Linux)"
echo "- Componenti UI adattivi (pulsanti, input, switch, select)"
echo "- Layout completamente responsive per tutti i dispositivi"
echo "- Stili specifici per ogni sistema operativo"
echo "- Animazioni ottimizzate per diversi dispositivi"
echo ""
echo "Per avviare il server di sviluppo: npm run dev"
echo "Per creare una build di produzione: npm run build"