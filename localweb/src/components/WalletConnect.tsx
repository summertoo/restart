import React from 'react';
import { useSuiWallet } from '../hooks/useSuiWallet';

const WalletConnect: React.FC = () => {
  const { isConnected, currentAccount, balance, loading, connectWallet, disconnectWallet, fetchBalance } = useSuiWallet();

  const formatBalance = (balance: string) => {
    const mist = parseInt(balance);
    const sui = mist / 1000000000; // 1 SUI = 1,000,000,000 MIST
    return sui.toFixed(4);
  };

  const formatAddress = (address: string) => {
    return `${address.slice(0, 6)}...${address.slice(-4)}`;
  };

  if (!isConnected) {
    return (
      <button
        onClick={connectWallet}
        disabled={loading}
        className="bg-blue-600 hover:bg-blue-700 disabled:bg-blue-400 text-white font-bold py-2 px-4 rounded-lg transition-colors"
      >
        {loading ? '连接中...' : '连接钱包'}
      </button>
    );
  }

  return (
    <div className="flex items-center space-x-4 bg-gray-800 p-4 rounded-lg">
      <div className="text-white">
        <div className="text-sm text-gray-400">钱包地址</div>
        <div className="font-mono text-sm">{formatAddress(currentAccount!)}</div>
      </div>
      <div className="text-white">
        <div className="text-sm text-gray-400">余额</div>
        <div className="font-bold">{formatBalance(balance)} SUI</div>
      </div>
      <button
        onClick={fetchBalance}
        disabled={loading}
        className="bg-green-600 hover:bg-green-700 disabled:bg-green-400 text-white font-bold py-2 px-3 rounded text-sm transition-colors"
      >
        {loading ? '刷新中...' : '刷新'}
      </button>
      <button
        onClick={disconnectWallet}
        className="bg-red-600 hover:bg-red-700 text-white font-bold py-2 px-3 rounded text-sm transition-colors"
      >
        断开
      </button>
    </div>
  );
};

export default WalletConnect;
