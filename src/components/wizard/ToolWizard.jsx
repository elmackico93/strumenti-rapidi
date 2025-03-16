// src/components/wizard/ToolWizard.jsx
import { useState, useEffect } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import StepIndicator from '../ui/StepIndicator';
import { useOS } from '../../context/OSContext';

const ToolWizard = ({ title, description, steps, toolId, themeColor }) => {
  const [currentStep, setCurrentStep] = useState(0);
  const [wizardData, setWizardData] = useState({});
  const [result, setResult] = useState(null);
  const { osType, isMobile } = useOS();
  
  // Reset wizard when tool changes
  useEffect(() => {
    setCurrentStep(0);
    setWizardData({});
    setResult(null);
  }, [toolId]);
  
  // Navigate between steps
  const goToNextStep = () => {
    if (currentStep < steps.length - 1) {
      setCurrentStep(currentStep + 1);
      window.scrollTo({ top: 0, behavior: 'smooth' });
    }
  };
  
  const goToPreviousStep = () => {
    if (currentStep > 0) {
      setCurrentStep(currentStep - 1);
      window.scrollTo({ top: 0, behavior: 'smooth' });
    }
  };
  
  // Update wizard data
  const updateWizardData = (newData) => {
    setWizardData(prevData => ({
      ...prevData,
      ...newData
    }));
  };
  
  // Set final result
  const setProcessResult = (processedResult) => {
    setResult(processedResult);
  };
  
  // Get step names for the indicator
  const stepNames = steps.map(step => step.title);
  
  // Animation based on operating system
  const getAnimationVariants = () => {
    // More fluid animations for iOS and macOS, more functional for other OS
    if (osType === 'ios' || osType === 'macos') {
      return {
        initial: { opacity: 0, x: 20, scale: 0.95 },
        animate: { opacity: 1, x: 0, scale: 1 },
exit: { opacity: 0, x: -20, scale: 0.95 },
        transition: { type: "spring", stiffness: 300, damping: 30 }
      };
    } else {
      return {
        initial: { opacity: 0, y: 10 },
        animate: { opacity: 1, y: 0 },
        exit: { opacity: 0, y: -10 },
        transition: { duration: 0.3 }
      };
    }
  };
  
  const animationVariants = getAnimationVariants();
  
  // Handle wizard completion (force next step to work)
  const forceComplete = () => {
    if (currentStep === steps.length - 2) { // If on the second-to-last step
      setCurrentStep(steps.length - 1); // Force to last step
      window.scrollTo({ top: 0, behavior: 'smooth' });
    }
  };
  
  return (
    <div className="container mx-auto px-4 py-8">
      <div className="max-w-4xl mx-auto">
        <div className="text-center mb-8">
          <h1 className={`text-3xl font-bold mb-2 ${isMobile ? 'text-2xl' : ''}`} style={{ color: themeColor }}>
            {title}
          </h1>
          {description && (
            <p className="text-gray-600 dark:text-gray-400">
              {description}
            </p>
          )}
        </div>
        
        <StepIndicator steps={stepNames} currentStep={currentStep} />
        
        <AnimatePresence mode="wait">
          <motion.div
            key={currentStep}
            initial={animationVariants.initial}
            animate={animationVariants.animate}
            exit={animationVariants.exit}
            transition={animationVariants.transition}
          >
            {steps[currentStep].component({
              data: wizardData,
              updateData: updateWizardData,
              goNext: goToNextStep,
              goBack: goToPreviousStep,
              result: result,
              setResult: setProcessResult,
              toolId,
              themeColor,
              forceComplete
            })}
          </motion.div>
        </AnimatePresence>
      </div>
    </div>
  );
};

export default ToolWizard;
