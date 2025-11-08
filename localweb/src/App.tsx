import React from 'react';
import WalletConnect from './components/WalletConnect';
import CreateLockedObject from './components/CreateLockedObject';

function App() {
  return (
    <div className="min-h-screen bg-gray-100">
      {/* Header */}
      <header className="bg-gray-900 text-white shadow-lg">
        <div className="container mx-auto px-4 py-6">
          <div className="flex justify-between items-center">
            <h1 className="text-3xl font-bold">restart</h1>
            <WalletConnect />
          </div>
        </div>
      </header>

      {/* Main Content */}
      <main className="container mx-auto px-4 py-8">
        <div className="max-w-4xl mx-auto">
          {/* Hero Section */}
          <section className="text-center mb-12">
            <h2 className="text-4xl font-bold text-gray-800 mb-4">
              欢迎使用 Restart 自锁仓平台
            </h2>
            <p className="text-xl text-gray-600 mb-8">
              基于 Sui 区块链的去中心化自锁仓解决方案
            </p>
          </section>

          {/* Create Locked Object Section */}
          <section className="mb-12">
            <CreateLockedObject />
          </section>

          {/* Features Section */}
          <section className="grid md:grid-cols-3 gap-6 mb-12">
            <div className="bg-white rounded-lg shadow-lg p-6">
              <div className="text-blue-600 text-3xl mb-4">🔒</div>
              <h3 className="text-xl font-bold text-gray-800 mb-2">安全锁仓</h3>
              <p className="text-gray-600">
                使用智能合约确保资金安全，支持自定义锁仓时间和提取规则
              </p>
            </div>
            <div className="bg-white rounded-lg shadow-lg p-6">
              <div className="text-green-600 text-3xl mb-4">⚡</div>
              <h3 className="text-xl font-bold text-gray-800 mb-2">快速交易</h3>
              <p className="text-gray-600">
                基于 Sui 高性能区块链，交易确认速度快，手续费低
              </p>
            </div>
            <div className="bg-white rounded-lg shadow-lg p-6">
              <div className="text-purple-600 text-3xl mb-4">🛡️</div>
              <h3 className="text-xl font-bold text-gray-800 mb-2">灵活控制</h3>
              <p className="text-gray-600">
                支持紧急提取、自动再投资等高级功能，满足不同需求
              </p>
            </div>
          </section>

          {/* Info Section */}
          <section className="bg-blue-50 rounded-lg p-6 text-center">
            <h3 className="text-2xl font-bold text-gray-800 mb-4">关于 Sui 测试网</h3>
            <p className="text-gray-600 mb-4">
              当前应用连接到 Sui 测试网络，所有交易使用测试代币，无实际价值。
            </p>
            <div className="flex justify-center space-x-4 text-sm text-gray-500">
              <span>网络: Sui Testnet</span>
              <span>•</span>
              <span>代币: SUI</span>
              <span>•</span>
              <span>状态: 测试环境</span>
            </div>
          </section>
        </div>
      </main>

      {/* Footer */}
      <footer className="bg-gray-800 text-white py-6 mt-12">
        <div className="container mx-auto px-4 text-center">
          <p className="text-gray-400">
            © 2024 Restart. 基于 Sui 区块链构建的去中心化应用
          </p>
        </div>
      </footer>
    </div>
  );
}

export default App;
