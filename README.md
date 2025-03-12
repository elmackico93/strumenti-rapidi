# StrumentiRapidi.it - Strumenti Online Gratuiti

Una piattaforma completa di strumenti online, tra cui conversione PDF, editing di immagini, estrazione di testo, calcolatrice, download video e creazione di meme. Tutto gratuito e direttamente nel browser.

## Caratteristiche

- **Convertitore PDF**: Converti PDF in vari formati tra cui Word, immagini e altro
- **Editor di immagini**: Ridimensiona, converti e ottimizza le immagini con vari filtri
- **Estrazione testo (OCR)**: Estrai testo da immagini e documenti scansionati
- **Calcolatrice**: Calcola percentuali, IVA e operazioni matematiche
- **Video Downloader**: Scarica video da YouTube, Instagram, TikTok
- **Creatore di Meme**: Crea meme personalizzati con templates popolari
- **Design reattivo**: Funziona su tutti i dispositivi, dal mobile al desktop
- **Modalità scura**: Si adatta automaticamente alle preferenze di sistema
- **UI adattiva al sistema operativo**: L'interfaccia si adatta al look and feel del sistema operativo utilizzato

## Tecnologie utilizzate

- React
- Tailwind CSS
- Vite
- Framer Motion per le animazioni
- Tesseract.js per OCR
- html-to-image per il creatore di meme
- mathjs per le funzionalità della calcolatrice
- react-device-detect per il rilevamento del sistema operativo

## Prerequisiti

- Node.js (v16.0.0 o superiore)
- npm (v8.0.0 o superiore)

## Installazione

1. Clona il repository
   ```
   git clone https://github.com/tuoutente/strumentirapidi.it.git
   ```

2. Naviga alla directory del progetto
   ```
   cd strumentirapidi.it
   ```

3. Installa le dipendenze
   ```
   npm install
   ```

4. Avvia il server di sviluppo
   ```
   npm run dev
   ```

5. Apri il browser e vai a `http://localhost:3000`

## UI Adattiva al Sistema Operativo

La piattaforma implementa un'interfaccia utente che si adatta automaticamente al sistema operativo dell'utente:

- **iOS**: Interfaccia arrotondata con effetti di profondità, pulsanti ampi e animazioni fluide
- **Android**: Stile Material Design con elementi piatti, angoli meno arrotondati e tipografia distintiva
- **Windows**: Interfaccia minimal con angoli squadrati e bordi sottili
- **macOS**: Elementi eleganti con effetti di vetro e animazioni raffinate
- **Linux**: Design semplice e funzionale con focus sull'utilizzo

Questo adattamento avviene automaticamente rilevando il sistema operativo dell'utente, senza compromettere la consistenza generale del design o della funzionalità dell'applicazione.

## Build per produzione

```
npm run build
```

I file generati saranno nella directory `dist`.

## Estendere il progetto

Per aggiungere un nuovo strumento:

1. Crea un nuovo componente in `src/components/tools/[nome-strumento]/`
2. Registra lo strumento in `src/App.jsx` aggiungendolo al `toolRegistry`
3. Aggiungi lo strumento alla rotta in `src/pages/ToolsPage.jsx`
4. Aggiungi lo strumento alla lista nella homepage

## Licenza

Questo progetto è disponibile con licenza MIT.
