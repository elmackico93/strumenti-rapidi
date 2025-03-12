// Componente PDF Converter principale
import React, { useState } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import ToolWizard from '../../wizard/ToolWizard';
import PDFUploadStep from './PDFUploadStep';
import PDFConfigurationStep from './PDFConfigurationStep';
import PDFResultStep from './PDFResultStep';
import { useOS } from '../../../context/OSContext';

const PDFConverter = () => {
  const { osType } = useOS();
  const [conversionType, setConversionType] = useState('convert');
  
  // Animazioni adattive per il sistema operativo
  const getAnimationProps = () => {
    // Animazioni più eleganti per macOS e iOS
    if (osType === 'macos' || osType === 'ios') {
      return {
        initial: { opacity: 0, y: 20, scale: 0.98 },
        animate: { opacity: 1, y: 0, scale: 1 },
        exit: { opacity: 0, y: -10, scale: 0.98 },
        transition: { type: "spring", stiffness: 300, damping: 25 }
      };
    }
    
    // Animazioni più semplici per altri sistemi
    return {
      initial: { opacity: 0, y: 10 },
      animate: { opacity: 1, y: 0 },
      exit: { opacity: 0 },
      transition: { duration: 0.3 }
    };
  };
  
  // Gestione del cambio di tipo di conversione
  const handleConversionTypeChange = (type) => {
    setConversionType(type);
  };
  
  return (
    <motion.div {...getAnimationProps()}>
      <ToolWizard
        title="Convertitore PDF Professionale"
        description="Converti, modifica e ottimizza i tuoi documenti PDF"
        toolId="pdf-converter"
        themeColor="#E74C3C"
        steps={[
          {
            title: 'Carica',
            component: (props) => (
              <PDFUploadStep 
                {...props} 
                onConversionTypeChange={handleConversionTypeChange}
                conversionType={conversionType}
              />
            )
          },
          {
            title: 'Configura',
            component: (props) => (
              <PDFConfigurationStep
                {...props}
                conversionType={conversionType}
              />
            )
          },
          {
            title: 'Risultato',
            component: PDFResultStep
          }
        ]}
      />
    </motion.div>
  );
};

export default PDFConverter;
