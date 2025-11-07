#[allow(unused_use,duplicate_alias,unused_const)]
module locked_object::types {
    use std::string::String;

    // === 重新导出核心类型 ===

    /// 代币类型
    public enum TokenType has copy, drop, store {
        SUI,
        USDC,
    }

    /// 锁仓规则
    public struct LockRules has copy, drop, store {
        min_lock_period: u64,        // 最小锁仓时间(秒)
        max_withdrawal_per_day: u64, // 每日最大提取限额
        auto_reinvest: bool,         // 自动再投资
        emergency_withdrawal: bool,  // 紧急提取
        withdrawal_fee_rate: u64,    // 提取手续费率(基点)
    }

    /// 存款记录
    public struct DepositRecord has copy, drop, store {
        timestamp: u64,
        amount: u64,
        depositor: address,
    }

    // === 辅助函数 ===

    /// 创建锁仓规则
    public fun create_lock_rules(
        min_lock_period: u64,
        max_withdrawal_per_day: u64,
        auto_reinvest: bool,
        emergency_withdrawal: bool,
        withdrawal_fee_rate: u64
    ): LockRules {
        LockRules {
            min_lock_period,
            max_withdrawal_per_day,
            auto_reinvest,
            emergency_withdrawal,
            withdrawal_fee_rate,
        }
    }

    /// 创建存款记录
    public fun create_deposit_record(
        timestamp: u64,
        amount: u64,
        depositor: address
    ): DepositRecord {
        DepositRecord {
            timestamp,
            amount,
            depositor
        }
    }

    // === LockRules 访问器函数 ===

    /// 获取最小锁仓时间
    public fun get_min_lock_period(rules: &LockRules): u64 {
        rules.min_lock_period
    }

    /// 获取每日最大提取限额
    public fun get_max_withdrawal_per_day(rules: &LockRules): u64 {
        rules.max_withdrawal_per_day
    }

    /// 获取是否自动再投资
    public fun get_auto_reinvest(rules: &LockRules): bool {
        rules.auto_reinvest
    }

    /// 获取是否允许紧急提取
    public fun get_emergency_withdrawal(rules: &LockRules): bool {
        rules.emergency_withdrawal
    }

    /// 获取提取手续费率
    public fun get_withdrawal_fee_rate(rules: &LockRules): u64 {
        rules.withdrawal_fee_rate
    }
}
