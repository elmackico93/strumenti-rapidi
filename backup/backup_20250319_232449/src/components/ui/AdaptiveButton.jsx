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
