import { useState } from 'react';
import { evaluate } from 'mathjs';
import AdaptiveButton from '../../ui/AdaptiveButton';
import AdaptiveInput from '../../ui/AdaptiveInput';
import AdaptiveSelect from '../../ui/AdaptiveSelect';

const Calculator = () => {
  const [input, setInput] = useState('');
  const [result, setResult] = useState('');
  const [tab, setTab] = useState('standard');
  
  // Funzioni calcolatrice standard
  const handleButtonClick = (value) => {
    if (value === 'C') {
      setInput('');
      setResult('');
    } else if (value === '=') {
      try {
        const calculatedResult = evaluate(input);
        setResult(calculatedResult);
      } catch (error) {
        setResult('Error');
      }
    } else if (value === '←') {
      setInput(input.slice(0, -1));
    } else {
      setInput(input + value);
    }
  };
  
  // Renderizza la calcolatrice standard
  const renderStandard = () => (
    <div>
      <div className="mb-4 p-4 bg-white dark:bg-gray-800 rounded-lg text-right">
        <div className="text-gray-600 dark:text-gray-400 text-sm">{input}</div>
        <div className="text-2xl font-bold">{result}</div>
      </div>
      
      <div className="grid grid-cols-4 gap-2">
        {['C', '←', '%', '/'].map(btn => (
          <AdaptiveButton 
            key={btn} 
            variant="secondary" 
            onClick={() => handleButtonClick(btn)}
          >
            {btn}
          </AdaptiveButton>
        ))}
        
        {[7, 8, 9, '*'].map(btn => (
          <AdaptiveButton 
            key={btn} 
            variant={typeof btn === 'number' ? 'secondary' : 'primary'} 
            onClick={() => handleButtonClick(btn.toString())}
          >
            {btn}
          </AdaptiveButton>
        ))}
        
        {[4, 5, 6, '-'].map(btn => (
          <AdaptiveButton 
            key={btn} 
            variant={typeof btn === 'number' ? 'secondary' : 'primary'} 
            onClick={() => handleButtonClick(btn.toString())}
          >
            {btn}
          </AdaptiveButton>
        ))}
        
        {[1, 2, 3, '+'].map(btn => (
          <AdaptiveButton 
            key={btn} 
            variant={typeof btn === 'number' ? 'secondary' : 'primary'} 
            onClick={() => handleButtonClick(btn.toString())}
          >
            {btn}
          </AdaptiveButton>
        ))}
        
        <AdaptiveButton
          className="col-span-2"
          variant="secondary"
          onClick={() => handleButtonClick('0')}
        >
          0
        </AdaptiveButton>
        <AdaptiveButton
          variant="secondary"
          onClick={() => handleButtonClick('.')}
        >
          .
        </AdaptiveButton>
        <AdaptiveButton
          variant="primary"
          onClick={() => handleButtonClick('=')}
          className="bg-calc-500 hover:bg-calc-600"
        >
          =
        </AdaptiveButton>
      </div>
    </div>
  );
  
  // Calcolo IVA
  const [amount, setAmount] = useState('');
  const [vat, setVat] = useState(22);
  const [vatResult, setVatResult] = useState(null);
  
  const calcVat = () => {
    if (!amount) return;
    const amt = parseFloat(amount);
    const vatAmount = (amt * vat) / 100;
    setVatResult({
      net: amt,
      vat: vatAmount,
      total: amt + vatAmount
    });
  };
  
  // Renderizza calcolatrice IVA
  const renderVat = () => (
    <div className="space-y-4">
      <AdaptiveInput
        type="number" 
        label="Importo (€)"
        value={amount} 
        onChange={e => setAmount(e.target.value)} 
        fullWidth
      />
      
      <div>
        <label className="block mb-1 text-sm font-medium text-gray-700 dark:text-gray-300">
          Aliquota IVA (%)
        </label>
        <div className="flex space-x-2">
          {[4, 10, 22].map(rate => (
            <AdaptiveButton 
              key={rate}
              variant={vat === rate ? 'primary' : 'secondary'}
              onClick={() => setVat(rate)}
              className={vat === rate ? 'bg-calc-500 hover:bg-calc-600' : ''}
            >
              {rate}%
            </AdaptiveButton>
          ))}
          <AdaptiveInput
            type="number" 
            value={vat} 
            onChange={e => setVat(parseInt(e.target.value))} 
            className="w-24" 
          />
        </div>
      </div>
      
      <AdaptiveButton
        variant="primary"
        onClick={calcVat}
        fullWidth
        className="bg-calc-500 hover:bg-calc-600"
      >
        Calcola
      </AdaptiveButton>
      
      {vatResult && (
        <div className="mt-4 p-4 bg-white dark:bg-gray-800 rounded-lg">
          <div className="grid grid-cols-2 gap-2">
            <span>Imponibile:</span><span className="text-right">{vatResult.net.toFixed(2)} €</span>
            <span>IVA ({vat}%):</span><span className="text-right">{vatResult.vat.toFixed(2)} €</span>
            <div className="col-span-2 border-t my-1"></div>
            <span className="font-bold">Totale:</span><span className="text-right font-bold">{vatResult.total.toFixed(2)} €</span>
          </div>
        </div>
      )}
    </div>
  );
  
  return (
    <div className="container mx-auto px-4 py-8">
      <div className="max-w-md mx-auto">
        <h1 className="text-3xl font-bold mb-6 text-center text-calc-500">Calcolatrice</h1>
        
        <div className="flex mb-4 border-b">
          <button 
            className={`py-2 px-4 ${tab === 'standard' ? 'border-b-2 border-calc-500 font-bold' : ''}`}
            onClick={() => setTab('standard')}>Standard</button>
          <button 
            className={`py-2 px-4 ${tab === 'vat' ? 'border-b-2 border-calc-500 font-bold' : ''}`}
            onClick={() => setTab('vat')}>IVA</button>
        </div>
        
        <div className="glass-card p-6">
          {tab === 'standard' ? renderStandard() : renderVat()}
        </div>
      </div>
    </div>
  );
};

export default Calculator;
