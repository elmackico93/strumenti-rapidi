// src/pages/ToolsPage.jsx
import { useParams } from 'react-router-dom';
import PDFConverter from '../components/tools/pdf/PDFConverter';
import ImageEditor from '../components/tools/image/ImageEditor';
import Calculator from '../components/tools/calculator/Calculator';
import OCR from '../components/tools/ocr/OCR';
import VideoDownloader from '../components/tools/video-downloader/VideoDownloader';
import MemeCreator from '../components/tools/meme-creator/MemeCreator';

const ToolsPage = () => {
  const { toolId } = useParams();
  
  // Render the appropriate tool based on the URL parameter
  const renderTool = () => {
    switch (toolId) {
      case 'pdf-converter':
        return <PDFConverter />;
      case 'image-editor':
        return <ImageEditor />;
      case 'calculator':
        return <Calculator />;
      case 'ocr':
        return <OCR />;
      case 'video-downloader':
        return <VideoDownloader />;
      case 'meme-creator':
        return <MemeCreator />;
      default:
        return (
          <div className="text-center py-12">
            <h2 className="text-2xl font-bold">Strumento non trovato</h2>
            <p className="mt-2">Lo strumento richiesto non è disponibile o è in fase di sviluppo.</p>
          </div>
        );
    }
  };
  
  return (
    <div>
      {renderTool()}
    </div>
  );
};

export default ToolsPage;
