// src/components/tools/image/ImageEditor.jsx
import ToolWizard from '../../wizard/ToolWizard';
import FileUploadStep from '../../wizard/FileUploadStep';
import ConfigurationStep from '../../wizard/ConfigurationStep';
import ResultStep from '../../wizard/ResultStep';
import ImageEditorOptions from './ImageEditorOptions';
import ImageEditorPreview from './ImageEditorPreview';

const ImageEditor = () => {
  return (
    <ToolWizard
      title="Image Editor"
      description="Resize, convert and optimize your images"
      toolId="image-editor"
      themeColor="#3498DB"
      steps={[
        {
          title: 'Upload',
          component: FileUploadStep
        },
        {
          title: 'Edit',
          component: (props) => (
            <ConfigurationStep
              {...props}
              optionsComponent={ImageEditorOptions}
              previewComponent={ImageEditorPreview}
            />
          )
        },
        {
          title: 'Download',
          component: ResultStep
        }
      ]}
    />
  );
};

export default ImageEditor;
