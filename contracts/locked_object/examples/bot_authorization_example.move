module locked_object::bot_example {
    use sui::coin::{Self, Coin};
    use sui::sui::SUI;
    use sui::tx_context::{Self, TxContext};
    use std::string;
    use locked_object::enhanced::{Self, EnhancedLockedObject};
    use locked_object::utils;

    /// 创建支持 bot 操作的自锁仓
    public fun create_bot_enabled_locked_object(
        ctx: &mut TxContext
    ) {
        let name = string::utf8(b"Bot Enabled Locked Object");
        let description = string::utf8(b"Locked object with bot authorization support");
        
        // 创建增强版自锁仓，启用授权模式
        enhanced::create_enhanced_locked_object(
            name,
            description,
            2592000, // 30天锁仓期
            1000000000, // 每日最大提取 1 SUI
            false, // 不自动再投资
            true, // 允许紧急提取
            100, // 1% 手续费
            true, // 启用授权模式
            ctx
        );
    }

    /// 为 bot 授权操作权限
    public fun authorize_bot(
        locked_object: &mut EnhancedLockedObject,
        bot_address: address,
        ctx: &TxContext
    ) {
        let current_time = tx_context::epoch(ctx);
        let expires_at = current_time + 31536000; // 1年后过期

        // 授权 bot 权限：
        // - 可以存款
        // - 可以提取（单次最大 0.5 SUI）
        // - 不能更新规则
        // - 每日提取限额 0.5 SUI
        enhanced::authorize_operator(
            locked_object,
            bot_address,
            true,  // can_deposit
            true,  // can_withdraw
            false, // can_update_rules
            500000000, // max_withdrawal_amount (0.5 SUI)
            500000000, // daily_withdrawal_limit (0.5 SUI)
            expires_at,
            ctx
        );
    }

    /// 为高级 bot 授权更多权限
    public fun authorize_advanced_bot(
        locked_object: &mut EnhancedLockedObject,
        bot_address: address,
        ctx: &TxContext
    ) {
        let current_time = tx_context::epoch(ctx);
        let expires_at = current_time + 31536000; // 1年后过期

        // 授权高级 bot 权限：
        // - 可以存款
        // - 可以提取（单次最大 2 SUI）
        // - 可以更新规则
        // - 每日提取限额 2 SUI
        enhanced::authorize_operator(
            locked_object,
            bot_address,
            true,  // can_deposit
            true,  // can_withdraw
            true,  // can_update_rules
            2000000000, // max_withdrawal_amount (2 SUI)
            2000000000, // daily_withdrawal_limit (2 SUI)
            expires_at,
            ctx
        );
    }

    /// Bot 存款操作示例
    public fun bot_deposit(
        locked_object: &mut EnhancedLockedObject,
        payment: Coin<SUI>,
        ctx: &mut TxContext
    ) {
        // Bot 调用存款函数
        enhanced::deposit(locked_object, payment, ctx);
    }

    /// Bot 提取操作示例
    public fun bot_withdraw(
        locked_object: &mut EnhancedLockedObject,
        amount: u64,
        ctx: &mut TxContext
    ): Coin<SUI> {
        // Bot 调用提取函数
        enhanced::withdraw(locked_object, amount, ctx)
    }

    /// Bot 更新锁仓规则示例（仅高级 bot）
    public fun bot_update_rules(
        locked_object: &mut EnhancedLockedObject,
        min_lock_period: u64,
        max_withdrawal_per_day: u64,
        withdrawal_fee_rate: u64,
        ctx: &TxContext
    ) {
        enhanced::update_lock_rules(
            locked_object,
            min_lock_period,
            max_withdrawal_per_day,
            false, // auto_reinvest
            true,  // emergency_withdrawal
            withdrawal_fee_rate,
            ctx
        );
    }

    /// 检查 bot 权限
    public fun check_bot_permissions(
        locked_object: &EnhancedLockedObject,
        bot_address: address,
        ctx: &TxContext
    ): (bool, bool, bool, u64, u64, u64) {
        let current_time = tx_context::epoch(ctx);
        
        // 检查存款权限
        let can_deposit = enhanced::check_operator_permission(
            locked_object,
            bot_address,
            1, // deposit permission
            0,
            current_time
        );
        
        // 检查提取权限
        let can_withdraw = enhanced::check_operator_permission(
            locked_object,
            bot_address,
            2, // withdraw permission
            1000000000, // 1 SUI
            current_time
        );
        
        // 检查更新规则权限
        let can_update_rules = enhanced::check_operator_permission(
            locked_object,
            bot_address,
            3, // update_rules permission
            0,
            current_time
        );

        // 获取详细权限信息
        let (deposit_perm, withdraw_perm, update_perm, max_amount, daily_limit, expires_at) = 
            enhanced::get_operator_permission(locked_object, bot_address);

        (can_deposit, can_withdraw, can_update_rules, max_amount, daily_limit, expires_at)
    }

    /// 撤销 bot 权限
    public fun revoke_bot_authorization(
        locked_object: &mut EnhancedLockedObject,
        bot_address: address,
        ctx: &TxContext
    ) {
        enhanced::revoke_operator(locked_object, bot_address, ctx);
    }

    /// 切换授权模式（禁用后只有所有者可以操作）
    public fun toggle_authorization_mode(
        locked_object: &mut EnhancedLockedObject,
        enable: bool,
        ctx: &TxContext
    ) {
        enhanced::toggle_authorization_mode(locked_object, enable, ctx);
    }
}
