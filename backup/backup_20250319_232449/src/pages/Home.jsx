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
