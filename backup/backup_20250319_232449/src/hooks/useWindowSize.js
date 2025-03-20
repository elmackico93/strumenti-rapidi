// Hook personalizzato per gestire la dimensione della finestra
import { useState, useEffect } from 'react';

export function useWindowSize() {
  const [windowSize, setWindowSize] = useState({
    width: undefined,
    height: undefined,
    isMobile: false,
    isTablet: false,
    isDesktop: false
  });
  
  useEffect(() => {
    // Handler per ridimensionamento
    function handleResize() {
      const width = window.innerWidth;
      const height = window.innerHeight;
      
      setWindowSize({
        width,
        height,
        isMobile: width < 640,
        isTablet: width >= 640 && width < 1024,
        isDesktop: width >= 1024
      });
    }
    
    // Aggiungi event listener
    window.addEventListener("resize", handleResize);
    
    // Chiama handler immediatamente
    handleResize();
    
    // Pulisci event listener
    return () => window.removeEventListener("resize", handleResize);
  }, []);
  
  return windowSize;
}
