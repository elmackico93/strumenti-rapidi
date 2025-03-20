import React from 'react';
import ReactDOM from 'react-dom/client';
import { useWindowSize } from "./hooks/useWindowSize";
import App from './App';
import './index.css';

ReactDOM.createRoot(document.getElementById('root')).render(
  <React.StrictMode>
    <App />
  </React.StrictMode>
);
