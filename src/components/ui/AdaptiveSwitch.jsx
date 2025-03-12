import React from 'react';
import { useOS } from '../../context/OSContext';

const AdaptiveSwitch = ({ 
  checked, 
  onChange, 
  label,
  className,
  ...props 
}) => {
  const { osType } = useOS();
  
  // Classi di base per tutti gli switch
  let switchWrapperClasses = 'relative inline-flex items-center cursor-pointer';
  let switchTrackClasses = 'transition-colors';
  let switchThumbClasses = 'absolute transform transition-transform';
  let labelClasses = 'ml-3 text-sm font-medium text-gray-700 dark:text-gray-300';
  
  // Aggiungi classi specifiche per sistema operativo
  switch (osType) {
    case 'ios':
      switchWrapperClasses += ' h-6 w-11';
      switchTrackClasses += ` h-6 w-11 rounded-full ${checked ? 'bg-green-400' : 'bg-gray-300 dark:bg-gray-600'}`;
      switchThumbClasses += ` h-5 w-5 rounded-full bg-white shadow-md border border-gray-200 ${checked ? 'translate-x-5' : 'translate-x-0.5'}`;
      break;
      
    case 'android':
      switchWrapperClasses += ' h-6 w-12';
      switchTrackClasses += ` h-4 w-10 mx-1 my-1 rounded-full ${checked ? 'bg-blue-600' : 'bg-gray-300 dark:bg-gray-600'}`;
      switchThumbClasses += ` h-5 w-5 rounded-full shadow-md ${checked ? 'bg-white translate-x-6' : 'bg-white translate-x-0'}`;
      break;
      
    case 'windows':
      switchWrapperClasses += ' h-6 w-11';
      switchTrackClasses += ` h-3 w-9 mx-1 rounded-full ${checked ? 'bg-blue-600' : 'bg-gray-300 dark:bg-gray-600'}`;
      switchThumbClasses += ` h-4 w-4 rounded-full bg-white shadow-sm border border-gray-200 ${checked ? 'translate-x-6' : 'translate-x-0'}`;
      break;
      
    case 'macos':
      switchWrapperClasses += ' h-6 w-10';
      switchTrackClasses += ` h-6 w-10 rounded-full border ${checked ? 'bg-blue-500 border-blue-600' : 'bg-gray-200 dark:bg-gray-700 border-gray-300 dark:border-gray-600'}`;
      switchThumbClasses += ` h-5 w-5 rounded-full bg-white shadow-sm ${checked ? 'translate-x-4' : 'translate-x-0.5'}`;
      break;
      
    case 'linux':
      switchWrapperClasses += ' h-6 w-12';
      switchTrackClasses += ` h-5 w-10 mx-1 rounded-sm ${checked ? 'bg-blue-600' : 'bg-gray-300 dark:bg-gray-600'}`;
      switchThumbClasses += ` h-3 w-3 rounded-sm bg-white m-1 ${checked ? 'translate-x-5' : 'translate-x-0'}`;
      break;
      
    default:
      // Stile generico
      switchWrapperClasses += ' h-6 w-11';
      switchTrackClasses += ` h-6 w-11 rounded-full ${checked ? 'bg-blue-600' : 'bg-gray-300 dark:bg-gray-600'}`;
      switchThumbClasses += ` h-5 w-5 rounded-full bg-white shadow-md ${checked ? 'translate-x-5' : 'translate-x-1'}`;
  }
  
  // Aggiungi classi personalizzate
  if (className) {
    switchWrapperClasses += ` ${className}`;
  }
  
  return (
    <label className="flex items-center">
      <div className={switchWrapperClasses}>
        <input
          type="checkbox"
          className="sr-only"
          checked={checked}
          onChange={onChange}
          {...props}
        />
        <div className={switchTrackClasses}></div>
        <div className={switchThumbClasses}></div>
      </div>
      {label && (
        <span className={labelClasses}>{label}</span>
      )}
    </label>
  );
};

export default AdaptiveSwitch;
