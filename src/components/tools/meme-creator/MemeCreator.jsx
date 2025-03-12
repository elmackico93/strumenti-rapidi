import { useState, useRef } from 'react';
import { toPng } from 'html-to-image';

const MemeCreator = () => {
  const [topText, setTopText] = useState('');
  const [bottomText, setBottomText] = useState('');
  const [memeImg, setMemeImg] = useState('https://i.imgflip.com/30b1gx.jpg'); // Drake template
  const [fontSize, setFontSize] = useState(36);
  const [isDownloading, setIsDownloading] = useState(false);
  const memeRef = useRef(null);
  
  const templates = [
    { id: 'drake', url: 'https://i.imgflip.com/30b1gx.jpg', name: 'Drake' },
    { id: 'doge', url: 'https://i.imgflip.com/4t0m5.jpg', name: 'Doge' },
    { id: 'buttons', url: 'https://i.imgflip.com/1g8my4.jpg', name: 'Two Buttons' },
    { id: 'change', url: 'https://i.imgflip.com/24y43o.jpg', name: 'Change My Mind' }
  ];
  
  const handleImageUpload = (e) => {
    const file = e.target.files[0];
    if (file) {
      const reader = new FileReader();
      reader.onload = (e) => setMemeImg(e.target.result);
      reader.readAsDataURL(file);
    }
  };
  
  const downloadMeme = async () => {
    if (!memeRef.current) return;
    
    setIsDownloading(true);
    try {
      const dataUrl = await toPng(memeRef.current, { quality: 0.95 });
      const link = document.createElement('a');
      link.download = 'meme.png';
      link.href = dataUrl;
      link.click();
    } catch (err) {
      console.error('Error generating meme:', err);
    } finally {
      setIsDownloading(false);
    }
  };
  
  return (
    <div className="container mx-auto px-4 py-8">
      <div className="max-w-3xl mx-auto">
        <h1 className="text-3xl font-bold mb-6 text-center text-indigo-500">Creatore di Meme</h1>
        
        <div className="flex flex-col md:flex-row gap-6">
          <div className="md:w-1/3">
            <div className="glass-card p-6 mb-6">
              <h2 className="text-xl font-semibold mb-4">Configurazione</h2>
              
              <div className="space-y-4">
                <div>
                  <label className="block mb-1">Testo Superiore</label>
                  <input
                    type="text"
                    value={topText}
                    onChange={(e) => setTopText(e.target.value)}
                    className="w-full p-2 border rounded dark:bg-gray-700"
                    placeholder="Testo superiore"
                  />
                </div>
                
                <div>
                  <label className="block mb-1">Testo Inferiore</label>
                  <input
                    type="text"
                    value={bottomText}
                    onChange={(e) => setBottomText(e.target.value)}
                    className="w-full p-2 border rounded dark:bg-gray-700"
                    placeholder="Testo inferiore"
                  />
                </div>
                
                <div>
                  <label className="block mb-1">Dimensione Testo: {fontSize}px</label>
                  <input
                    type="range"
                    min="20"
                    max="60"
                    value={fontSize}
                    onChange={(e) => setFontSize(Number(e.target.value))}
                    className="w-full"
                  />
                </div>
                
                <div>
                  <label className="block mb-1">Template</label>
                  <div className="grid grid-cols-2 gap-2">
                    {templates.map(template => (
                      <div
                        key={template.id}
                        className={`cursor-pointer rounded-lg overflow-hidden border-2 ${memeImg === template.url ? 'border-indigo-500' : 'border-transparent'}`}
                        onClick={() => setMemeImg(template.url)}
                      >
                        <img src={template.url} alt={template.name} className="w-full h-auto" />
                      </div>
                    ))}
                  </div>
                </div>
                
                <div>
                  <label className="block mb-1">O carica la tua immagine</label>
                  <input
                    type="file"
                    accept="image/*"
                    onChange={handleImageUpload}
                    className="w-full"
                  />
                </div>
                
                <button
                  onClick={downloadMeme}
                  disabled={isDownloading}
                  className="w-full bg-indigo-500 text-white py-2 rounded-lg"
                >
                  {isDownloading ? 'Generazione...' : 'Scarica Meme'}
                </button>
              </div>
            </div>
          </div>
          
          <div className="md:w-2/3">
            <div className="glass-card p-6">
              <h2 className="text-xl font-semibold mb-4">Anteprima</h2>
              
              <div
                ref={memeRef}
                className="relative bg-white rounded-lg overflow-hidden max-w-lg mx-auto"
              >
                <img src={memeImg} alt="Meme template" className="w-full h-auto" />
                
                {topText && (
                  <div
                    className="absolute top-0 left-0 right-0 p-4 text-center"
                    style={{
                      fontSize: `${fontSize}px`,
                      fontFamily: 'Impact, sans-serif',
                      color: 'white',
                      textTransform: 'uppercase',
                      textShadow: '-2px -2px 0 #000, 2px -2px 0 #000, -2px 2px 0 #000, 2px 2px 0 #000'
                    }}
                  >
                    {topText}
                  </div>
                )}
                
                {bottomText && (
                  <div
                    className="absolute bottom-0 left-0 right-0 p-4 text-center"
                    style={{
                      fontSize: `${fontSize}px`,
                      fontFamily: 'Impact, sans-serif',
                      color: 'white',
                      textTransform: 'uppercase',
                      textShadow: '-2px -2px 0 #000, 2px -2px 0 #000, -2px 2px 0 #000, 2px 2px 0 #000'
                    }}
                  >
                    {bottomText}
                  </div>
                )}
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
};

export default MemeCreator;
