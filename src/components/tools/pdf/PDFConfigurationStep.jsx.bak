// Componente per configurare le opzioni di conversione PDF
import React, { useState, useEffect } from 'react';
import { motion } from 'framer-motion';
import AdaptiveButton from '../../ui/AdaptiveButton';
import AdaptiveInput from '../../ui/AdaptiveInput';
import AdaptiveSelect from '../../ui/AdaptiveSelect';
import AdaptiveSwitch from '../../ui/AdaptiveSwitch';
import PDFPreview from './PDFPreview';
import { useOS } from '../../../context/OSContext';

const PDFConfigurationStep = ({ data, updateData, goNext, goBack, themeColor, conversionType, forceComplete }) => {
  const { osType, isMobile } = useOS();
  const [isGeneratingPreview, setIsGeneratingPreview] = useState(false);
  const [options, setOptions] = useState({
    // Opzioni di conversione
    targetFormat: 'docx',
    quality: 'high',
    dpi: 150,
    pageRange: 'all',
    customPages: '1-5',
    preserveLinks: true,
    preserveFormatting: true,
    
    // Opzioni di protezione
    password: '',
    permissions: {
      printing: true,
      copying: true,
      modifying: false
    },
    
    // Altre opzioni
    operation: data.conversionType || 'convert'
  });
  
  // Inizializza le opzioni dai dati esistenti
  useEffect(() => {
    if (data.options) {
      setOptions(prevOptions => ({
        ...prevOptions,
        ...data.options
      }));
    }
    
    if (data.conversionType) {
      setOptions(prevOptions => ({
        ...prevOptions,
        operation: data.conversionType
      }));
    }
  }, [data]);
  
  // Formati disponibili per la conversione
  const availableFormats = [
    { value: 'docx', label: 'Word (DOCX)' },
    { value: 'jpg', label: 'Immagine (JPG)' },
    { value: 'png', label: 'Immagine (PNG)' },
    { value: 'txt', label: 'Testo semplice (TXT)' },
    { value: 'html', label: 'HTML' }
  ];
  
  // Opzioni di qualità
  const qualityOptions = [
    { value: 'low', label: 'Bassa (file più piccolo)' },
    { value: 'medium', label: 'Media' },
    { value: 'high', label: 'Alta (migliore qualità)' }
  ];
  
  // Gestione dei cambiamenti delle opzioni
  const handleOptionChange = (option, value) => {
    setOptions(prevOptions => ({
      ...prevOptions,
      [option]: value
    }));
  };
  
  // Gestione dei cambiamenti dei permessi
  const handlePermissionChange = (permission) => {
    setOptions(prevOptions => ({
      ...prevOptions,
      permissions: {
        ...prevOptions.permissions,
        [permission]: !prevOptions.permissions[permission]
      }
    }));
  };
  
  // Continua alla prossima fase
  const handleContinue = () => {
    // Validazione
    if (options.operation === 'protect' && !options.password) {
      alert('Inserisci una password per proteggere il PDF');
      return;
    }
    
    updateData({ options: {...options, operation: options.operation || data.conversionType} });
    
    // Use forceComplete to ensure progression to the result step
    if (typeof forceComplete === 'function') {
      typeof forceComplete === "function" && forceComplete();
    } else {
      goNext();
    }
  };
  
  // Renderizza le opzioni di conversione
  const renderConversionOptions = () => (
    <div className="space-y-4">
      <div>
        <AdaptiveSelect
          label="Formato di destinazione"
          value={options.targetFormat}
          onChange={(e) => handleOptionChange('targetFormat', e.target.value)}
          options={availableFormats}
          fullWidth
        />
      </div>
      
      {(options.targetFormat === 'jpg' || options.targetFormat === 'png') && (
        <div>
          <AdaptiveInput
            type="number"
            label="DPI (Qualità Immagine)"
            value={options.dpi}
            onChange={(e) => handleOptionChange('dpi', parseInt(e.target.value))}
            min="72"
            max="600"
            fullWidth
          />
          <div className="mt-1 text-xs text-gray-500">
            Valori più alti = immagini più grandi e di migliore qualità
          </div>
        </div>
      )}
      
      <div>
        <AdaptiveSelect
          label="Qualità"
          value={options.quality}
          onChange={(e) => handleOptionChange('quality', e.target.value)}
          options={qualityOptions}
          fullWidth
        />
      </div>
      
      <div>
        <p className="text-sm font-medium mb-2">Intervallo pagine</p>
        <div className="space-y-2">
          <div className="flex items-center space-x-2">
            <input
              type="radio"
              id="all-pages"
              checked={options.pageRange === 'all'}
              onChange={() => handleOptionChange('pageRange', 'all')}
            />
            <label htmlFor="all-pages">Tutte le pagine</label>
          </div>
          
          <div className="flex items-center space-x-2">
            <input
              type="radio"
              id="custom-pages"
              checked={options.pageRange === 'custom'}
              onChange={() => handleOptionChange('pageRange', 'custom')}
            />
            <label htmlFor="custom-pages">Pagine personalizzate</label>
          </div>
          
          {options.pageRange === 'custom' && (
            <div className="pl-6 mt-2">
              <AdaptiveInput
                type="text"
                value={options.customPages}
                onChange={(e) => handleOptionChange('customPages', e.target.value)}
                placeholder="es. 1-5, 8, 11-13"
                fullWidth
              />
              <p className="text-xs text-gray-500 mt-1">
                Usa virgole per separare le pagine e trattini per gli intervalli
              </p>
            </div>
          )}
        </div>
      </div>
      
      {(options.targetFormat === 'docx' || options.targetFormat === 'html') && (
        <div>
          <p className="text-sm font-medium mb-2">Opzioni aggiuntive</p>
          <div className="space-y-3">
            <AdaptiveSwitch
              label="Mantieni link"
              checked={options.preserveLinks}
              onChange={() => handleOptionChange('preserveLinks', !options.preserveLinks)}
            />
            
            <AdaptiveSwitch
              label="Mantieni formattazione"
              checked={options.preserveFormatting}
              onChange={() => handleOptionChange('preserveFormatting', !options.preserveFormatting)}
            />
          </div>
        </div>
      )}
    </div>
  );
  
  // Renderizza le opzioni di compressione
  const renderCompressionOptions = () => (
    <div className="space-y-4">
      <div>
        <AdaptiveSelect
          label="Livello di compressione"
          value={options.quality}
          onChange={(e) => handleOptionChange('quality', e.target.value)}
          options={[
            { value: 'high', label: 'Lieve - Qualità ottimale' },
            { value: 'medium', label: 'Media - Buon equilibrio' },
            { value: 'low', label: 'Massima - File più piccolo' }
          ]}
          fullWidth
        />
        <div className="mt-1 text-xs text-gray-500">
          Una compressione maggiore può ridurre la qualità delle immagini e del testo.
        </div>
      </div>
    </div>
  );
  
  // Renderizza le opzioni di protezione
  const renderProtectionOptions = () => (
    <div className="space-y-4">
      <div>
        <AdaptiveInput
          type="password"
          label="Password di protezione"
          value={options.password}
          onChange={(e) => handleOptionChange('password', e.target.value)}
          placeholder="Inserisci una password sicura"
          fullWidth
        />
        <div className="mt-1 text-xs text-gray-500">
          La password proteggerà il tuo PDF dall'apertura non autorizzata.
        </div>
      </div>
      
      <div>
        <p className="text-sm font-medium mb-2">Permessi</p>
        <div className="space-y-3 pl-1">
          <AdaptiveSwitch
            label="Consenti stampa"
            checked={options.permissions.printing}
            onChange={() => handlePermissionChange('printing')}
          />
          
          <AdaptiveSwitch
            label="Consenti copia di testo e immagini"
            checked={options.permissions.copying}
            onChange={() => handlePermissionChange('copying')}
          />
          
          <AdaptiveSwitch
            label="Consenti modifiche al documento"
            checked={options.permissions.modifying}
            onChange={() => handlePermissionChange('modifying')}
          />
        </div>
      </div>
      
      <div className="p-3 bg-yellow-50 dark:bg-yellow-900 dark:bg-opacity-20 text-yellow-800 dark:text-yellow-300 rounded-md">
        <p className="text-sm flex items-start">
          <svg className="w-5 h-5 mr-2 mt-0.5 flex-shrink-0" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M13 16h-1v-4h-1m1-4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
          </svg>
          <span>Importante: assicurati di ricordare questa password. Se la dimentichi, non potrai più accedere al documento protetto.</span>
        </p>
      </div>
    </div>
  );
  
  // Renderizza le opzioni di divisione
  const renderSplitOptions = () => (
    <div className="space-y-4">
      <div>
        <p className="text-sm font-medium mb-2">Modalità di divisione</p>
        <div className="space-y-2">
          <div className="flex items-center space-x-2">
            <input
              type="radio"
              id="split-all"
              checked={options.pageRange === 'all'}
              onChange={() => handleOptionChange('pageRange', 'all')}
            />
            <label htmlFor="split-all">Una pagina per file</label>
          </div>
          
          <div className="flex items-center space-x-2">
            <input
              type="radio"
              id="split-custom"
              checked={options.pageRange === 'custom'}
              onChange={() => handleOptionChange('pageRange', 'custom')}
            />
            <label htmlFor="split-custom">Intervalli personalizzati</label>
          </div>
          
          {options.pageRange === 'custom' && (
            <div className="pl-6 mt-2">
              <AdaptiveInput
                type="text"
                value={options.customPages}
                onChange={(e) => handleOptionChange('customPages', e.target.value)}
                placeholder="es. 1-5, 6-10, 11-15"
                fullWidth
              />
              <p className="text-xs text-gray-500 mt-1">
                Ogni intervallo diventerà un file PDF separato. Esempio: "1-5, 6-10" creerà 2 file PDF.
              </p>
            </div>
          )}
        </div>
      </div>
    </div>
  );
  
  // Renderizza le opzioni di unione
  const renderMergeOptions = () => (
    <div className="space-y-4">
      <div className="p-3 bg-blue-50 dark:bg-blue-900 dark:bg-opacity-20 text-blue-800 dark:text-blue-300 rounded-md">
        <p className="text-sm flex items-start">
          <svg className="w-5 h-5 mr-2 mt-0.5 flex-shrink-0" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M13 16h-1v-4h-1m1-4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
          </svg>
          <span>I file PDF verranno uniti nell'ordine in cui sono stati caricati. Puoi tornare indietro per modificare o riordinare i file.</span>
        </p>
      </div>
    </div>
  );
  
  // Determina le opzioni da mostrare in base al tipo di operazione
  const renderOptionsBasedOnOperation = () => {
    const operation = options.operation || data.conversionType || 'convert';
    
    switch (operation) {
      case 'convert':
        return renderConversionOptions();
      case 'compress':
        return renderCompressionOptions();
      case 'protect':
        return renderProtectionOptions();
      case 'split':
        return renderSplitOptions();
      case 'merge':
        return renderMergeOptions();
      default:
        return renderConversionOptions();
    }
  };
  
  // Ottieni il titolo appropriato per il tipo di operazione
  const getOperationTitle = () => {
    const operation = options.operation || data.conversionType || 'convert';
    
    switch (operation) {
      case 'convert':
        return 'Opzioni di conversione';
      case 'compress':
        return 'Opzioni di compressione';
      case 'protect':
        return 'Impostazioni di protezione';
      case 'split':
        return 'Opzioni di divisione';
      case 'merge':
        return 'Opzioni di unione';
      default:
        return 'Opzioni';
    }
  };
  
  // Effetto di apertura per il contenitore
  const containerVariants = {
    hidden: { opacity: 0, y: 20 },
    visible: { 
      opacity: 1, 
      y: 0,
      transition: { 
        duration: 0.4,
        when: "beforeChildren",
        staggerChildren: 0.1
      }
    }
  };
  
  // Effetto per gli elementi interni
  const itemVariants = {
    hidden: { opacity: 0, y: 10 },
    visible: { opacity: 1, y: 0 }
  };
  
  return (
    <div className="step-container">
      <motion.div
        variants={containerVariants}
        initial="hidden"
        animate="visible"
      >
        <motion.h2 
          className="text-xl font-semibold mb-4"
          variants={itemVariants}
        >
          {getOperationTitle()}
        </motion.h2>
        
        <div className={`flex ${isMobile ? 'flex-col' : 'flex-row'} gap-6`}>
          <motion.div 
            className={isMobile ? 'w-full' : 'w-2/5'}
            variants={itemVariants}
          >
            <div className="glass-card p-5 h-full">
              {renderOptionsBasedOnOperation()}
            </div>
          </motion.div>
          
          <motion.div 
            className={isMobile ? 'w-full' : 'w-3/5'}
            variants={itemVariants}
          >
            <div className="glass-card p-5 h-full">
              <h3 className="text-lg font-medium mb-3">Anteprima</h3>
              
              <PDFPreview 
                files={data.files}
                options={options}
                isLoading={isGeneratingPreview}
              />
              
              <div className="mt-4 p-3 bg-gray-50 dark:bg-gray-800 rounded-md">
                <h4 className="font-medium text-sm mb-1">Riepilogo</h4>
                <ul className="text-sm text-gray-600 dark:text-gray-400 space-y-1">
                  {options.operation === 'convert' || (!options.operation && data.conversionType === 'convert') && (
                    <>
                      <li>• Conversione da PDF a {options.targetFormat.toUpperCase()}</li>
                      <li>• Qualità: {options.quality}</li>
                      {(options.targetFormat === 'jpg' || options.targetFormat === 'png') && (
                        <li>• DPI: {options.dpi}</li>
                      )}
                      <li>• Pagine: {options.pageRange === 'all' ? 'Tutte' : options.customPages}</li>
                    </>
                  )}
                  
                  {options.operation === 'compress' || (!options.operation && data.conversionType === 'compress') && (
                    <>
                      <li>• Compressione PDF</li>
                      <li>• Livello: {options.quality === 'low' ? 'Massimo' : options.quality === 'medium' ? 'Medio' : 'Lieve'}</li>
                      <li>• La dimensione finale dipenderà dal contenuto del PDF</li>
                    </>
                  )}
                  
                  {options.operation === 'protect' || (!options.operation && data.conversionType === 'protect') && (
                    <>
                      <li>• Protezione con password</li>
                      <li>• Stampa: {options.permissions.printing ? 'Consentita' : 'Non consentita'}</li>
                      <li>• Copia: {options.permissions.copying ? 'Consentita' : 'Non consentita'}</li>
                      <li>• Modifica: {options.permissions.modifying ? 'Consentita' : 'Non consentita'}</li>
                    </>
                  )}
                  
                  {options.operation === 'split' || (!options.operation && data.conversionType === 'split') && (
                    <>
                      <li>• Divisione PDF</li>
                      <li>• Modalità: {options.pageRange === 'all' ? 'Una pagina per file' : 'Intervalli personalizzati'}</li>
                      {options.pageRange === 'custom' && (
                        <li>• Intervalli: {options.customPages}</li>
                      )}
                    </>
                  )}
                  
                  {options.operation === 'merge' || (!options.operation && data.conversionType === 'merge') && (
                    <>
                      <li>• Unione PDF</li>
                      <li>• File da unire: {data.files ? data.files.length : 0}</li>
                    </>
                  )}
                </ul>
              </div>
            </div>
          </motion.div>
        </div>
        
        <motion.div 
          className="flex justify-between mt-6"
          variants={itemVariants}
        >
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
            className="bg-red-500 hover:bg-red-600"
          >
            Elabora PDF
            <svg className="ml-2 w-5 h-5 inline" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 5l7 7-7 7" />
            </svg>
          </AdaptiveButton>
        </motion.div>
      </motion.div>
    </div>
  );
};

export default PDFConfigurationStep;
