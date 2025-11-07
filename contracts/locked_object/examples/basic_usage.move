// 基本使用示例
module locked_object::examples {
    use sui::coin::{Self, Coin};
    use sui::sui::SUI;
    use locked_object::core::{Self, LockedObject};
    use std::string;

    /// 创建自锁仓Object的示例
    public fun create_example_locked_object(
        ctx: &mut sui::tx_context::TxContext
    ) {
        let name = string::utf8(b"My Locked Object");
        let description = string::utf8(b"A simple locked object for testing");
        
        // 创建锁仓规则：最小锁仓30天，每日最大提取1 SUI，无自动再投资，允许紧急提取，1%手续费
        core::create_locked_object(
            name,
            description,
            2592000, // 30天 = 30 * 24 * 60 * 60 秒
            1000000000, // 1 SUI (1e9 MIST)
            false, // 不自动再投资
            true, // 允许紧急提取
            100, // 1% 手续费 (100基点)
            ctx
        );
    }

    /// 存款示例
    public fun deposit_example(
        locked_object: &mut LockedObject,
        amount: u64,
        ctx: &mut sui::tx_context::TxContext
    ) {
        // 创建SUI代币用于存款
        let payment = coin::zero<SUI>(ctx);
        // 在实际使用中，这里应该是用户提供的SUI代币
        // coin::mint(&mut treasury_cap, amount, ctx);
        
        core::deposit_sui(locked_object, payment, ctx);
    }

    /// 提取示例
    public fun withdraw_example(
        locked_object: &mut LockedObject,
        amount: u64,
        ctx: &mut sui::tx_context::TxContext
    ): Coin<SUI> {
        core::withdraw_sui(locked_object, amount, ctx)
    }
}
