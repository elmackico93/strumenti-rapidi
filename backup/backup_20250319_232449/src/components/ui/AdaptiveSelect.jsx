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
