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
