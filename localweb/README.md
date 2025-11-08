# Restart - Sui 自锁仓平台

基于 React + Tailwind CSS 构建的 Sui 区块链自锁仓 DApp 前端应用。

## 项目结构

```
localweb/
├── public/
│   ├── demo.html          # 演示页面（可直接在浏览器中打开）
│   └── index.html         # React 应用入口
├── src/
│   ├── components/
│   │   ├── WalletConnect.tsx      # 钱包连接组件
│   │   └── CreateLockedObject.tsx # 创建自锁对象组件
│   ├── hooks/
│   │   └── useSuiWallet.ts        # Sui 钱包 Hook
│   ├── App.tsx             # 主应用组件
│   ├── index.css           # 样式文件（包含 Tailwind）
│   └── index.tsx           # 应用入口
├── package.json
├── tailwind.config.js      # Tailwind 配置
└── postcss.config.js       # PostCSS 配置
```

## 功能特性

### 🎯 核心功能
- **钱包连接**: 模拟 Sui 钱包连接功能
- **余额显示**: 显示钱包 SUI 余额
- **创建自锁对象**: 支持创建自定义规则的自锁仓对象
- **响应式设计**: 适配桌面和移动设备

### 🔧 自锁对象参数
- **对象名称**: 自定义对象名称
- **描述信息**: 对象的详细描述
- **最小锁仓时间**: 以秒为单位的最小锁定期限
- **每日提取限额**: 每日最大可提取金额（MIST）
- **提取手续费率**: 基点表示的手续费率
- **自动再投资**: 是否启用自动再投资功能
- **紧急提取**: 是否允许紧急提取

### 🎨 界面设计
- 使用 Tailwind CSS 构建现代化界面
- 深色主题头部导航
- 卡片式布局设计
- 友好的用户交互反馈

## 快速开始

### 方法一：直接查看演示
1. 打开 `public/demo.html` 文件在浏览器中查看
2. 点击"连接钱包"按钮模拟连接
3. 填写表单创建自锁对象

### 方法二：运行 React 应用
```bash
# 安装依赖
npm install

# 启动开发服务器
npm start
```

应用将在 `http://localhost:3000` 启动。

## 技术栈

- **前端框架**: React 19 + TypeScript
- **样式框架**: Tailwind CSS
- **区块链**: Sui (模拟实现)
- **构建工具**: Create React App

## 智能合约集成

当前版本使用模拟数据，实际集成需要：

1. 安装 Sui SDK:
```bash
npm install @mysten/sui @mysten/dapp-kit
```

2. 更新 `useSuiWallet.ts` 中的实际合约地址和函数调用

3. 配置 Sui 测试网连接

## 合约接口

基于 `contracts/locked_object/sources/locked_object.move` 中的函数：

```move
public fun create_locked_object<T>(
    name: String,
    description: String,
    min_lock_period: u64,
    max_withdrawal_per_day: u64,
    auto_reinvest: bool,
    emergency_withdrawal: bool,
    withdrawal_fee_rate: u64,
    ctx: &mut TxContext,
)
```

## 开发说明

### 环境要求
- Node.js 16+
- npm 或 yarn

### 开发模式
```bash
npm start  # 启动开发服务器
npm run build  # 构建生产版本
npm test  # 运行测试
```

### 样式定制
修改 `tailwind.config.js` 来自定义主题：
```javascript
module.exports = {
  theme: {
    extend: {
      colors: {
        primary: '#3B82F6',
        // 自定义颜色
      }
    }
  }
}
```

## 部署

### 构建生产版本
```bash
npm run build
```

构建文件将输出到 `build/` 目录，可部署到任何静态文件服务器。

## 注意事项

1. **测试环境**: 当前连接到 Sui 测试网，使用测试代币
2. **模拟实现**: 钱包连接和交易功能为模拟实现
3. **安全性**: 生产环境需要集成真实的 Sui 钱包和合约调用

## 未来计划

- [ ] 集成真实 Sui 钱包
- [ ] 添加对象管理功能
- [ ] 支持多币种锁仓
- [ ] 添加交易历史记录
- [ ] 实现移动端适配优化

## 许可证

MIT License
