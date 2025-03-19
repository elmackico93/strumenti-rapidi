// Hook Diagnostic Test Script
// Run this in browser console to verify React hook issues

function testReactHooks() {
  console.log("==== StrumentiRapidi.it React Hook Diagnostic Test ====");
  
  // Check for React DevTools
  console.log("1. Testing React DevTools availability...");
  if (window.__REACT_DEVTOOLS_GLOBAL_HOOK__) {
    console.log("✓ React DevTools hook is available");
    
    // Try to get component instances
    const fiberRoots = window.__REACT_DEVTOOLS_GLOBAL_HOOK__.getFiberRoots(1);
    if (fiberRoots && fiberRoots.size > 0) {
      console.log("✓ React fiber roots found:", fiberRoots.size);
      
      // Check for the problematic components
      const components = ['ToolWizard', 'PDFResultStep', 'PDFWebViewer'];
      console.log(`2. Looking for components with hook issues: ${components.join(', ')}`);
      
      let foundComponents = [];
      fiberRoots.forEach(root => {
        const walk = (fiber) => {
          if (fiber.type && fiber.type.name && components.includes(fiber.type.name)) {
            foundComponents.push(fiber.type.name);
            console.log(`✓ Found component: ${fiber.type.name}`);
          }
          
          // Walk child fibers
          let child = fiber.child;
          while (child) {
            walk(child);
            child = child.sibling;
          }
        };
        
        walk(root.current);
      });
      
      if (foundComponents.length === 0) {
        console.log("✗ No target components found in the current render tree");
      } else {
        console.log(`✓ Found ${foundComponents.length} target component(s)`);
      }
    } else {
      console.log("✗ No React fiber roots found!");
    }
  } else {
    console.warn("✗ React DevTools hook not available. Install React DevTools extension for better diagnostics.");
  }
  
  // Check for errors in the console
  console.log("3. Checking for common React hook errors in console...");
  const hookErrors = [
    "Rendered more hooks than during the previous render",
    "React has detected a change in the order of Hooks",
    "Hooks can only be called inside the body of a function component"
  ];
  
  console.log("Please check the console for any of these errors:");
  hookErrors.forEach(err => console.log(`   - "${err}"`));
  
  console.log("\n4. Recommendation:");
  console.log("   If you see hook errors, ensure that:");
  console.log("   - All hooks are called in the same order on every render");
  console.log("   - No hooks are called conditionally");
  console.log("   - State hooks are declared before any custom hooks");
  console.log("==== Diagnostic Complete ====");
}

testReactHooks();
