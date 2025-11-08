import React, { useState } from 'react';
import { useSuiWallet } from '../hooks/useSuiWallet';

const CreateLockedObject: React.FC = () => {
  const { isConnected, createLockedObject, loading } = useSuiWallet();
  const [formData, setFormData] = useState({
    name: '',
    description: '',
    minLockPeriod: '86400', // 默认24小时
    maxWithdrawalPerDay: '1000000000', // 默认1 SUI
    autoReinvest: false,
    emergencyWithdrawal: false,
    withdrawalFeeRate: '100', // 默认1%
  });
  const [message, setMessage] = useState<{ type: 'success' | 'error'; text: string } | null>(null);

  const handleInputChange = (e: React.ChangeEvent<HTMLInputElement | HTMLTextAreaElement>) => {
    const { name, value, type } = e.target;
    setFormData(prev => ({
      ...prev,
      [name]: type === 'checkbox' ? (e.target as HTMLInputElement).checked : value
    }));
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    
    if (!isConnected) {
      setMessage({ type: 'error', text: '请先连接钱包' });
      return;
    }

    try {
      setMessage(null);
      const result = await createLockedObject(
        formData.name,
        formData.description,
        parseInt(formData.minLockPeriod)
      );
      
      setMessage({ 
        type: 'success', 
        text: `自锁对象创建成功！对象ID: ${result.objectId.slice(0, 10)}...` 
      });
      
      // 重置表单
      setFormData({
        name: '',
        description: '',
        minLockPeriod: '86400',
        maxWithdrawalPerDay: '1000000000',
        autoReinvest: false,
        emergencyWithdrawal: false,
        withdrawalFeeRate: '100',
      });
    } catch (error) {
      setMessage({ 
        type: 'error', 
        text: `创建失败: ${error instanceof Error ? error.message : '未知错误'}` 
      });
    }
  };

  if (!isConnected) {
    return (
      <div className="bg-yellow-50 border border-yellow-200 rounded-lg p-6 text-center">
        <p className="text-yellow-800">请先连接钱包以创建自锁对象</p>
      </div>
    );
  }

  return (
    <div className="bg-white rounded-lg shadow-lg p-6">
      <h2 className="text-2xl font-bold text-gray-800 mb-6">创建自锁对象</h2>
      
      {message && (
        <div className={`mb-4 p-4 rounded-lg ${
          message.type === 'success' 
            ? 'bg-green-100 border border-green-400 text-green-700' 
            : 'bg-red-100 border border-red-400 text-red-700'
        }`}>
          {message.text}
        </div>
      )}

      <form onSubmit={handleSubmit} className="space-y-4">
        <div>
          <label className="block text-sm font-medium text-gray-700 mb-2">
            对象名称
          </label>
          <input
            type="text"
            name="name"
            value={formData.name}
            onChange={handleInputChange}
            required
            className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
            placeholder="输入对象名称"
          />
        </div>

        <div>
          <label className="block text-sm font-medium text-gray-700 mb-2">
            描述信息
          </label>
          <textarea
            name="description"
            value={formData.description}
            onChange={handleInputChange}
            required
            rows={3}
            className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
            placeholder="输入描述信息"
          />
        </div>

        <div>
          <label className="block text-sm font-medium text-gray-700 mb-2">
            最小锁仓时间 (秒)
          </label>
          <input
            type="number"
            name="minLockPeriod"
            value={formData.minLockPeriod}
            onChange={handleInputChange}
            required
            min="1"
            className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
            placeholder="86400 (24小时)"
          />
          <p className="text-xs text-gray-500 mt-1">86400秒 = 24小时</p>
        </div>

        <div>
          <label className="block text-sm font-medium text-gray-700 mb-2">
            每日最大提取限额 (MIST)
          </label>
          <input
            type="number"
            name="maxWithdrawalPerDay"
            value={formData.maxWithdrawalPerDay}
            onChange={handleInputChange}
            required
            min="0"
            className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
            placeholder="1000000000 (1 SUI)"
          />
          <p className="text-xs text-gray-500 mt-1">1 SUI = 1,000,000,000 MIST</p>
        </div>

        <div>
          <label className="block text-sm font-medium text-gray-700 mb-2">
            提取手续费率 (基点)
          </label>
          <input
            type="number"
            name="withdrawalFeeRate"
            value={formData.withdrawalFeeRate}
            onChange={handleInputChange}
            required
            min="0"
            max="10000"
            className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
            placeholder="100 (1%)"
          />
          <p className="text-xs text-gray-500 mt-1">100基点 = 1%</p>
        </div>

        <div className="space-y-2">
          <label className="flex items-center">
            <input
              type="checkbox"
              name="autoReinvest"
              checked={formData.autoReinvest}
              onChange={handleInputChange}
              className="mr-2"
            />
            <span className="text-sm text-gray-700">自动再投资</span>
          </label>

          <label className="flex items-center">
            <input
              type="checkbox"
              name="emergencyWithdrawal"
              checked={formData.emergencyWithdrawal}
              onChange={handleInputChange}
              className="mr-2"
            />
            <span className="text-sm text-gray-700">允许紧急提取</span>
          </label>
        </div>

        <button
          type="submit"
          disabled={loading}
          className="w-full bg-blue-600 hover:bg-blue-700 disabled:bg-blue-400 text-white font-bold py-3 px-4 rounded-lg transition-colors"
        >
          {loading ? '创建中...' : '创建自锁对象'}
        </button>
      </form>
    </div>
  );
};

export default CreateLockedObject;
