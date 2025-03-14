// Basic PDF worker that responds to messages
// This is a placeholder - in production you would implement actual PDF processing here

// Listen for messages from the main thread
self.onmessage = function(e) {
  const { task, fileData, options, taskId } = e.data;
  
  // Respond with success for now
  self.postMessage({
    status: 'success',
    taskId,
    result: {
      success: true,
      message: 'PDF worker received task: ' + task
    }
  });
};
