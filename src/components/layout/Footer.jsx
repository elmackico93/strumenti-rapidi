// src/components/layout/Footer.jsx
import { Link } from 'react-router-dom';

const Footer = () => {
  const currentYear = new Date().getFullYear();
  
  return (
    <footer className="bg-gray-100 dark:bg-gray-800 py-8 mt-12">
      <div className="container mx-auto px-4">
        <div className="grid grid-cols-1 md:grid-cols-3 gap-8">
          <div>
            <h3 className="text-lg font-bold mb-4">StrumentiRapidi.it</h3>
            <p className="text-sm text-gray-600 dark:text-gray-400">
              Una raccolta di strumenti online gratuiti per aiutarti nei tuoi compiti quotidiani.
              Converti, comprimi e crea con facilità.
            </p>
          </div>
          
          <div>
            <h3 className="text-lg font-bold mb-4">Link Rapidi</h3>
            <ul className="space-y-2">
              <li>
                <Link to="/" className="text-sm hover:underline">Home</Link>
              </li>
              <li>
                <Link to="/tools" className="text-sm hover:underline">Tutti gli Strumenti</Link>
              </li>
              <li>
                <Link to="/about" className="text-sm hover:underline">Chi Siamo</Link>
              </li>
              <li>
                <Link to="/privacy" className="text-sm hover:underline">Privacy Policy</Link>
              </li>
            </ul>
          </div>
          
          <div>
            <h3 className="text-lg font-bold mb-4">Strumenti Popolari</h3>
            <ul className="space-y-2">
              <li>
                <Link to="/tools/pdf-converter" className="text-sm hover:underline">Convertitore PDF</Link>
              </li>
              <li>
                <Link to="/tools/image-editor" className="text-sm hover:underline">Editor Immagini</Link>
              </li>
              <li>
                <Link to="/tools/ocr" className="text-sm hover:underline">Estrazione Testo</Link>
              </li>
              <li>
                <Link to="/tools/calculator" className="text-sm hover:underline">Calcolatrice</Link>
              </li>
            </ul>
          </div>
        </div>
        
        <div className="mt-8 pt-8 border-t border-gray-200 dark:border-gray-700 text-center">
          <p className="text-sm text-gray-600 dark:text-gray-400">
            © {currentYear} StrumentiRapidi.it. Tutti i diritti riservati.
          </p>
        </div>
      </div>
    </footer>
  );
};

export default Footer;
