import { useState } from 'react';

const VideoDownloader = () => {
  const [url, setUrl] = useState('');
  const [isProcessing, setIsProcessing] = useState(false);
  const [result, setResult] = useState(null);
  const [error, setError] = useState(null);
  
  const handleSubmit = (e) => {
    e.preventDefault();
    if (!url.trim()) return;
    
    setIsProcessing(true);
    setError(null);
    
    // Simulazione API - in produzione integrare con vero servizio
    setTimeout(() => {
      if (url.includes('youtube') || url.includes('youtu.be')) {
        setResult({
          title: 'Video YouTube di esempio',
          thumbnail: 'https://via.placeholder.com/480x360/E74C3C/FFFFFF?text=YouTube',
          formats: [
            { quality: '1080p', size: '24.5 MB', id: 'hd' },
            { quality: '720p', size: '12.2 MB', id: 'md' },
            { quality: '480p', size: '8.1 MB', id: 'sd' },
            { quality: 'MP3', size: '3.4 MB', id: 'audio' }
          ]
        });
      } else if (url.includes('instagram') || url.includes('tiktok')) {
        setResult({
          title: 'Video Social di esempio',
          thumbnail: 'https://via.placeholder.com/400x400/3498DB/FFFFFF?text=Social',
          formats: [
            { quality: 'Alta Qualità', size: '8.2 MB', id: 'hq' },
            { quality: 'Bassa Qualità', size: '4.1 MB', id: 'lq' }
          ]
        });
      } else {
        setError('URL non supportato. Supportiamo YouTube, Instagram e TikTok.');
      }
      setIsProcessing(false);
    }, 1500);
  };
  
  return (
    <div className="container mx-auto px-4 py-8">
      <div className="max-w-2xl mx-auto">
        <h1 className="text-3xl font-bold mb-6 text-center text-file-500">Video Downloader</h1>
        
        <div className="glass-card p-6">
          <form onSubmit={handleSubmit} className="mb-6">
            <div className="flex">
              <input
                type="text"
                value={url}
                onChange={(e) => setUrl(e.target.value)}
                placeholder="Incolla URL YouTube, Instagram o TikTok..."
                className="flex-1 px-4 py-2 rounded-l-lg border dark:bg-gray-700"
              />
              <button
                type="submit"
                className="bg-file-500 text-white px-4 py-2 rounded-r-lg"
                disabled={isProcessing}
              >
                {isProcessing ? 'Analisi...' : 'Scarica'}
              </button>
            </div>
          </form>
          
          {error && (
            <div className="p-4 bg-red-100 text-red-700 rounded-lg mb-4">
              {error}
            </div>
          )}
          
          <div className="flex justify-center space-x-8 mb-6">
            <div className="text-center">
              <div className="w-12 h-12 flex items-center justify-center rounded-full bg-red-100 text-red-600 mx-auto mb-2">
                <svg className="w-6 h-6" fill="currentColor" viewBox="0 0 24 24">
                  <path d="M19.615 3.184c-3.604-.246-11.631-.245-15.23 0-3.897.266-4.356 2.62-4.385 8.816.029 6.185.484 8.549 4.385 8.816 3.6.245 11.626.246 15.23 0 3.897-.266 4.356-2.62 4.385-8.816-.029-6.185-.484-8.549-4.385-8.816zm-10.615 12.816v-8l8 3.993-8 4.007z"/>
                </svg>
              </div>
              <div className="text-sm">YouTube</div>
            </div>
            <div className="text-center">
              <div className="w-12 h-12 flex items-center justify-center rounded-full bg-purple-100 text-purple-600 mx-auto mb-2">
                <svg className="w-6 h-6" fill="currentColor" viewBox="0 0 24 24">
                  <path d="M12 2.163c3.204 0 3.584.012 4.85.07 3.252.148 4.771 1.691 4.919 4.919.058 1.265.069 1.645.069 4.849 0 3.205-.012 3.584-.069 4.849-.149 3.225-1.664 4.771-4.919 4.919-1.266.058-1.644.07-4.85.07-3.204 0-3.584-.012-4.849-.07-3.26-.149-4.771-1.699-4.919-4.92-.058-1.265-.07-1.644-.07-4.849 0-3.204.013-3.583.07-4.849.149-3.227 1.664-4.771 4.919-4.919 1.266-.057 1.645-.069 4.849-.069zm0-2.163c-3.259 0-3.667.014-4.947.072-4.358.2-6.78 2.618-6.98 6.98-.059 1.281-.073 1.689-.073 4.948 0 3.259.014 3.668.072 4.948.2 4.358 2.618 6.78 6.98 6.98 1.281.058 1.689.072 4.948.072 3.259 0 3.668-.014 4.948-.072 4.354-.2 6.782-2.618 6.979-6.98.059-1.28.073-1.689.073-4.948 0-3.259-.014-3.667-.072-4.947-.196-4.354-2.617-6.78-6.979-6.98-1.281-.059-1.69-.073-4.949-.073zm0 5.838c-3.403 0-6.162 2.759-6.162 6.162s2.759 6.163 6.162 6.163 6.162-2.759 6.162-6.163c0-3.403-2.759-6.162-6.162-6.162zm0 10.162c-2.209 0-4-1.79-4-4 0-2.209 1.791-4 4-4s4 1.791 4 4c0 2.21-1.791 4-4 4zm6.406-11.845c-.796 0-1.441.645-1.441 1.44s.645 1.44 1.441 1.44c.795 0 1.439-.645 1.439-1.44s-.644-1.44-1.439-1.44z"/>
                </svg>
              </div>
              <div className="text-sm">Instagram</div>
            </div>
            <div className="text-center">
              <div className="w-12 h-12 flex items-center justify-center rounded-full bg-blue-100 text-blue-600 mx-auto mb-2">
                <svg className="w-6 h-6" fill="currentColor" viewBox="0 0 24 24">
                  <path d="M12.53.02C13.84 0 15.14.01 16.44 0c.08 1.53.63 3.09 1.75 4.17 1.12 1.11 2.7 1.62 4.24 1.79v4.03c-1.44-.05-2.89-.35-4.2-.97-.57-.26-1.1-.59-1.62-.93-.01 2.92.01 5.84-.02 8.75-.08 1.4-.54 2.79-1.35 3.94-1.31 1.92-3.58 3.17-5.91 3.21-1.43.08-2.86-.31-4.08-1.03-2.02-1.19-3.44-3.37-3.65-5.71-.02-.5-.03-1-.01-1.49.18-1.9 1.12-3.72 2.58-4.96 1.66-1.44 3.98-2.13 6.15-1.72.02 1.48-.04 2.96-.04 4.44-.99-.32-2.15-.23-3.02.37-.63.41-1.11 1.04-1.36 1.75-.21.51-.15 1.07-.14 1.61.24 1.64 1.82 3.02 3.5 2.87 1.12-.01 2.19-.66 2.77-1.61.19-.33.4-.67.41-1.06.1-1.79.06-3.57.07-5.36.01-4.03-.01-8.05.02-12.07z"/>
                </svg>
              </div>
              <div className="text-sm">TikTok</div>
            </div>
          </div>
          
          {result && (
            <div className="bg-white dark:bg-gray-800 rounded-lg p-4">
              <div className="flex flex-col md:flex-row gap-4">
                <img src={result.thumbnail} alt={result.title} className="w-full md:w-1/3 rounded-lg" />
                <div className="flex-1">
                  <h3 className="text-lg font-bold mb-3">{result.title}</h3>
                  
                  <div className="space-y-2">
                    {result.formats.map((format, index) => (
                      <div key={index} className="flex justify-between items-center p-3 border rounded-lg hover:bg-gray-50 dark:hover:bg-gray-700">
                        <div>
                          <div className="font-medium">{format.quality}</div>
                          <div className="text-sm text-gray-500">{format.size}</div>
                        </div>
                        <button className="px-3 py-1 bg-file-500 text-white rounded-lg">Scarica</button>
                      </div>
                    ))}
                  </div>
                </div>
              </div>
            </div>
          )}
        </div>
      </div>
    </div>
  );
};

export default VideoDownloader;
