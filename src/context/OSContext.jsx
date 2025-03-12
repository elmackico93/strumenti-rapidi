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
