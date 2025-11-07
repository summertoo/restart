// 多币种锁仓使用示例
module locked_object::examples {
    use sui::coin::{Self, Coin};
    use sui::sui::SUI;
    use sui::tx_context::{Self, TxContext};
    use std::string::String;
    use locked_object::core;
    use locked_object::multi_currency;

    /// 创建SUI锁仓示例
    public fun create_sui_vault_example(ctx: &mut TxContext) {
        let name = std::string::utf8(b"My SUI Vault");
        let description = std::string::utf8(b"A vault for locking SUI tokens");
        
        // 创建SUI锁仓对象
        multi_currency::create_sui_locked_object(
            name,
            description,
            86400, // 1天锁仓期
            1000000000, // 每日最大提取1 SUI
            false, // 不自动再投资
            true, // 允许紧急提取
            100, // 1%手续费
            ctx
        );
    }

    /// 创建USDC锁仓示例（需要USDC代币类型）
    public fun create_usdc_vault_example<USDC>(ctx: &mut TxContext) {
        let name = std::string::utf8(b"My USDC Vault");
        let description = std::string::utf8(b"A vault for locking USDC stablecoins");
        
        // 创建USDC锁仓对象
        multi_currency::create_usdc_locked_object<USDC>(
            name,
            description,
            604800, // 7天锁仓期
            5000000000, // 每日最大提取5000 USDC (6 decimals)
            false, // 不自动再投资
            true, // 允许紧急提取
            50, // 0.5%手续费
            ctx
        );
    }

    /// 创建USDT锁仓示例（需要USDT代币类型）
    public fun create_usdt_vault_example<USDT>(ctx: &mut TxContext) {
        let name = std::string::utf8(b"My USDT Vault");
        let description = std::string::utf8(b"A vault for locking USDT stablecoins");
        
        // 创建USDT锁仓对象
        multi_currency::create_usdt_locked_object<USDT>(
            name,
            description,
            2592000, // 30天锁仓期
            10000000000, // 每日最大提取10000 USDT (6 decimals)
            true, // 自动再投资
            false, // 不允许紧急提取
            200, // 2%手续费
            ctx
        );
    }

    /// SUI存款示例
    public fun deposit_sui_example(
        locked_object: &mut core::LockedObject<SUI>,
        payment: Coin<SUI>,
        ctx: &mut TxContext
    ) {
        // 使用便捷函数存入SUI
        core::deposit_sui(locked_object, payment, ctx);
    }

    /// USDC存款示例
    public fun deposit_usdc_example<USDC>(
        locked_object: &mut core::LockedObject<USDC>,
        payment: Coin<USDC>,
        ctx: &mut TxContext
    ) {
        // 使用多币种模块存入USDC
        multi_currency::deposit_usdc(locked_object, payment, ctx);
    }

    /// USDT存款示例
    public fun deposit_usdt_example<USDT>(
        locked_object: &mut core::LockedObject<USDT>,
        payment: Coin<USDT>,
        ctx: &mut TxContext
    ) {
        // 使用多币种模块存入USDT
        multi_currency::deposit_usdt(locked_object, payment, ctx);
    }

    /// 获取代币信息示例
    public fun get_token_info_example() {
        // 获取SUI信息
        let sui_symbol = multi_currency::get_coin_symbol(multi_currency::SupportedCoin::SUI);
        let sui_name = multi_currency::get_coin_name(multi_currency::SupportedCoin::SUI);
        let sui_decimals = multi_currency::get_coin_decimals(multi_currency::SupportedCoin::SUI);
        
        // 获取USDC信息
        let usdc_symbol = multi_currency::get_coin_symbol(multi_currency::SupportedCoin::USDC);
        let usdc_name = multi_currency::get_coin_name(multi_currency::SupportedCoin::USDC);
        let usdc_decimals = multi_currency::get_coin_decimals(multi_currency::SupportedCoin::USDC);
        
        // 获取USDT信息
        let usdt_symbol = multi_currency::get_coin_symbol(multi_currency::SupportedCoin::USDT);
        let usdt_name = multi_currency::get_coin_name(multi_currency::SupportedCoin::USDT);
        let usdt_decimals = multi_currency::get_coin_decimals(multi_currency::SupportedCoin::USDT);
        
        // 格式化金额示例
        let formatted_sui = multi_currency::format_token_amount(1500000000, sui_decimals); // 1.5 SUI
        let formatted_usdc = multi_currency::format_token_amount(2500000000, usdc_decimals); // 2500 USDC
        let formatted_usdt = multi_currency::format_token_amount(500000000, usdt_decimals); // 500 USDT
        
        // 在实际应用中，这些信息可以用于UI显示或日志记录
    }

    /// 通用代币操作示例
    public fun generic_token_operations<T>(
        locked_object: &mut core::LockedObject<T>,
        payment: Coin<T>,
        withdraw_amount: u64,
        ctx: &mut TxContext
    ): Coin<T> {
        // 存入代币
        core::deposit(locked_object, payment, ctx);
        
        // 提取代币
        core::withdraw(locked_object, withdraw_amount, ctx)
    }

    /// 查询锁仓信息示例
    public fun query_vault_info<T>(locked_object: &core::LockedObject<T>): (String, String, u64, u64, u64) {
        // 获取基本信息
        let (name, description, owner, created_at, updated_at) = 
            core::get_object_info(locked_object);
        
        // 获取余额信息
        let (current_balance, total_deposited, total_withdrawn) = 
            core::get_balances(locked_object);
        
        // 获取锁仓规则
        let lock_rules = core::get_lock_rules(locked_object);
        
        // 返回汇总信息
        (name, description, current_balance, total_deposited, total_withdrawn)
    }
}
