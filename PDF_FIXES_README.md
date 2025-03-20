# PDF.js Integration Fixes for StrumentiRapidi.it

Questo file contiene istruzioni aggiuntive per risolvere problemi di integrazione di PDF.js su StrumentiRapidi.it.

## Correzioni Automatiche Applicate

Le seguenti correzioni sono state applicate automaticamente dallo script:

1. Configurazione del worker PDF.js corretta: true
2. Percorso del worker PDF.js aggiornato: true
3. Gestione degli errori aggiunta: true
4. File PDF.js scaricati/verificati
5. Index.html aggiornato con inclusione corretta di PDF.js
6. Avvisi React Router corretti (se applicabile): true
7. Componenti React per PDF corretti (se applicabile): false

## Verifica delle Correzioni

Dopo aver applicato queste correzioni, è possibile verificare se il problema è stato risolto:

1. Riavvia il server web
2. Apri la console del browser (F12)
3. Cancella la cache del browser
4. Verifica che non ci siano errori nella console durante il caricamento del sito
5. Prova a caricare e convertire un file PDF
6. Controlla se i messaggi di errore di PDF.js sono scomparsi

## Correzioni Manuali Aggiuntive (se le correzioni automatiche non risolvono tutti i problemi)

### 1. Verifica delle Impostazioni CORS

Se vedi errori di CORS nella console del browser durante il caricamento dei worker PDF.js:

#### Per Apache:
Aggiungi queste righe al file  o alla configurazione del server:

```
<IfModule mod_headers.c>
  Header set Access-Control-Allow-Origin "*"
  Header set Access-Control-Allow-Methods "GET, POST, OPTIONS"
  Header set Access-Control-Allow-Headers "Content-Type"
</IfModule>
```

#### Per Nginx:
Aggiungi queste righe alla configurazione del server:

```
location ~ \.(js|pdf|worker)$ {
  add_header Access-Control-Allow-Origin "*";
  add_header Access-Control-Allow-Methods "GET, POST, OPTIONS";
  add_header Access-Control-Allow-Headers "Content-Type";
}
```

### 2. Verifica Tipi MIME

Assicurati che il server stia servendo i file con i tipi MIME corretti:

#### Per Apache:
Aggiungi queste righe al file :

```
AddType application/javascript .js
AddType application/javascript .mjs
AddType application/octet-stream .pdf
```

#### Per Nginx:
Aggiungi queste righe alla configurazione:

```
types {
  application/javascript js;
  application/javascript mjs;
  application/octet-stream pdf;
}
```

### 3. Verifica Percorsi dei File PDF.js

Controlla che i file PDF.js siano nella posizione corretta:

- `js/pdf.js`
- `js/pdf.worker.js`

Se ti ritrovi a dover modificare i percorsi, aggiorna anche i riferimenti nel codice.

### 4. Problemi di Bundler (Webpack, Rollup, ecc.)

Se stai utilizzando un bundler, potresti dover configurare specificamente PDF.js:

#### Per Webpack:
```javascript
// webpack.config.js
module.exports = {
  // ...
  resolve: {
    alias: {
      'pdfjs-dist': path.resolve(__dirname, 'node_modules/pdfjs-dist/build/pdf'),
    },
  },
  // ...
  module: {
    rules: [
      {
        test: /pdf\.worker\.js$/,
        use: {
          loader: 'file-loader',
          options: {
            name: '[name].[ext]',
            outputPath: 'js/'
          }
        }
      }
    ]
  }
};
```

### 5. Problemi di Architettura React

Se stai utilizzando React e continui a vedere problemi:

1. Assicurati che il worker sia configurato nel componente giusto (HOC o component di livello più alto)
2. Potrebbe essere necessario utilizzare `useEffect` per inizializzare PDF.js dopo il montaggio del componente:

```javascript
useEffect(() => {
  // Configura PDF.js dopo che il componente è montato
  try {
    const pdfjsLib = require('pdfjs-dist');
    pdfjsLib.GlobalWorkerOptions.workerSrc = new URL('/js/pdf.worker.js', window.location.origin).href;
  } catch (e) {
    console.warn('PDF.js worker setup error:', e);
  }
}, []);
```

## Gestione Cache Service Worker

Se utilizzi service worker per la cache, assicurati che non interferiscano con il caricamento di PDF.js:

```javascript
// In service-worker.js
self.addEventListener('fetch', (event) => {
  // Non intercettare le richieste per i worker PDF.js
  if (event.request.url.includes('pdf.worker.js')) {
    return;
  }
  
  // Resto della logica di cache
});
```

## Segnalazione di Problemi

Se i problemi persistono dopo aver applicato queste correzioni, raccogli le seguenti informazioni:

1. Screenshot della console del browser con gli errori
2. Versione del browser utilizzato
3. Le specifiche tecnologie del tuo progetto (React, Vue, plain JS, ecc.)
4. Eventuali modifiche personalizzate che hai apportato a PDF.js

## Risorse Utili

- [Documentazione ufficiale di PDF.js](https://mozilla.github.io/pdf.js/getting_started/)
- [Problemi comuni e soluzioni](https://github.com/mozilla/pdf.js/wiki/Frequently-Asked-Questions)
- [Esempi di integrazione](https://github.com/mozilla/pdf.js/tree/master/examples)
