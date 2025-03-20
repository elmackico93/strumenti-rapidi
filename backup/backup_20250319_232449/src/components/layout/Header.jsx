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
