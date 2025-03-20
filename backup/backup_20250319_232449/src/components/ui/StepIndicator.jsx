// src/components/ui/StepIndicator.jsx - versione migliorata per responsiveness
import React from 'react';
import { motion } from 'framer-motion';
import { useOS } from '../../context/OSContext';

const StepIndicator = ({ steps, currentStep }) => {
  const { osType, isMobile } = useOS();
  
  return (
    <div className="step-indicator glass-card p-4 mb-6 overflow-hidden">
      <div className="flex justify-between items-center relative">
        {/* Progress line */}
        <div className="absolute h-1 bg-gray-200 dark:bg-gray-700 left-0 right-0 top-1/2 transform -translate-y-1/2 z-0" />
        
        {/* Active progress */}
        <motion.div 
          className="absolute h-1 bg-primary-500 left-0 top-1/2 transform -translate-y-1/2 z-0"
          initial={{ width: '0%' }}
          animate={{ width: `${(100 / (steps.length - 1)) * currentStep}%` }}
          transition={{ duration: 0.5 }}
        />
        
        {/* Step indicators */}
        {steps.map((step, index) => (
          <div key={index} className="z-10 flex flex-col items-center">
            <motion.div
              className={`step-number rounded-full flex items-center justify-center ${
                index <= currentStep 
                  ? 'bg-primary-500 text-white' 
                  : 'bg-gray-200 dark:bg-gray-700 text-gray-500 dark:text-gray-400'
              }`}
              animate={{
                scale: index === currentStep ? 1.1 : 1,
                backgroundColor: index <= currentStep ? '#3B82F6' : '#E5E7EB',
                color: index <= currentStep ? '#FFFFFF' : '#6B7280'
              }}
              transition={{ duration: 0.3 }}
            >
              {index + 1}
            </motion.div>
            
            <span className={`step-label text-xs font-medium mt-1 ${
              index <= currentStep 
                ? 'text-primary-500' 
                : 'text-gray-500 dark:text-gray-400'
            } ${isMobile ? 'hidden sm:block' : ''}`}>
              {step}
            </span>
          </div>
        ))}
      </div>
    </div>
  );
};

export default StepIndicator;
