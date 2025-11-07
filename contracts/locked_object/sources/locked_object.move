#[allow(unused_use,unused_const,unused_variable,lint(self_transfer))]
module locked_object::core {
    use sui::balance::{Self, Balance};
    use sui::coin::{Self, Coin};
    use sui::sui::SUI;
    use sui::event;
    use std::string::String;
    use locked_object::utils;
    use locked_object::types::{Self, LockRules, DepositRecord};

    // === 错误码定义 ===
    const E_NOT_OWNER: u64 = 0;
    const E_INSUFFICIENT_BALANCE: u64 = 1;
    const E_LOCK_PERIOD_NOT_MET: u64 = 2;
    const E_WITHDRAWAL_LIMIT_EXCEEDED: u64 = 3;
    const E_INVALID_PARAMETERS: u64 = 5;

    /// 提供基本的自锁仓功能：
    /// 1. 创建自锁仓object
    /// 2. 存入任意代币
    /// 3. 基本的锁仓规则
    public struct LockedObject<phantom T> has key, store {
        id: UID,
        
        // === 基础信息 ===
        owner: address,
        name: String,
        description: String,
        created_at: u64,
        updated_at: u64,
        
        // === 资金管理 ===
        balance: Balance<T>,
        total_deposited: u64,
        total_withdrawn: u64,
        lock_rules: LockRules,
        deposit_history: vector<DepositRecord>,
    }

    // === 核心函数 ===

    /// 创建新的自锁仓Object
    /// 
    /// # 参数
    /// * `name` - Object名称
    /// * `description` - 描述信息
    /// * `min_lock_period` - 最小锁仓时间(秒)
    /// * `max_withdrawal_per_day` - 每日最大提取限额
    /// * `auto_reinvest` - 是否自动再投资
    /// * `emergency_withdrawal` - 是否允许紧急提取
    /// * `withdrawal_fee_rate` - 提取手续费率(基点)
    /// * `ctx` - 交易上下文
    /// 
    /// # 返回
    /// 创建并转移LockedObject给创建者
    public fun create_locked_object<T>(
        name: String,
        description: String,
        min_lock_period: u64,
        max_withdrawal_per_day: u64,
        auto_reinvest: bool,
        emergency_withdrawal: bool,
        withdrawal_fee_rate: u64,
        ctx: &mut TxContext
    ) {
        let current_time = tx_context::epoch(ctx);
        let sender = tx_context::sender(ctx);

        // 验证参数
        assert!(utils::is_valid_amount(min_lock_period), E_INVALID_PARAMETERS);
        assert!(utils::is_valid_amount(max_withdrawal_per_day), E_INVALID_PARAMETERS);
        assert!(utils::is_valid_basis_points(withdrawal_fee_rate), E_INVALID_PARAMETERS);

        let lock_rules = types::create_lock_rules(
            min_lock_period,
            max_withdrawal_per_day,
            auto_reinvest,
            emergency_withdrawal,
            withdrawal_fee_rate
        );

        let locked_object = LockedObject<T> {
            id: object::new(ctx),
            owner: sender,
            name,
            description,
            created_at: current_time,
            updated_at: current_time,
            
            // 资金管理初始化
            balance: balance::zero<T>(),
            total_deposited: 0,
            total_withdrawn: 0,
            lock_rules,
            deposit_history: vector::empty(),
        };

        // 发出创建事件
        event::emit(ObjectCreated {
            object_id: object::uid_to_inner(&locked_object.id),
            owner: sender,
            name: locked_object.name,
            timestamp: current_time,
        });

        // 作为共享对象转移
        transfer::public_share_object(locked_object);
        
        // 返回空值，因为函数已经转移了对象
        ()
    }

    /// 测试专用的创建函数，创建共享对象
    #[test_only]
    public fun create_locked_object_for_test<T>(
        name: String,
        description: String,
        min_lock_period: u64,
        max_withdrawal_per_day: u64,
        auto_reinvest: bool,
        emergency_withdrawal: bool,
        withdrawal_fee_rate: u64,
        ctx: &mut TxContext
    ) {
        let current_time = tx_context::epoch(ctx);
        let sender = tx_context::sender(ctx);

        // 验证参数
        assert!(utils::is_valid_amount(min_lock_period), E_INVALID_PARAMETERS);
        assert!(utils::is_valid_amount(max_withdrawal_per_day), E_INVALID_PARAMETERS);
        assert!(utils::is_valid_basis_points(withdrawal_fee_rate), E_INVALID_PARAMETERS);

        let lock_rules = types::create_lock_rules(
            min_lock_period,
            max_withdrawal_per_day,
            auto_reinvest,
            emergency_withdrawal,
            withdrawal_fee_rate
        );

        let locked_object = LockedObject<T> {
            id: object::new(ctx),
            owner: sender,
            name,
            description,
            created_at: current_time,
            updated_at: current_time,
            
            // 资金管理初始化
            balance: balance::zero<T>(),
            total_deposited: 0,
            total_withdrawn: 0,
            lock_rules,
            deposit_history: vector::empty(),
        };

        // 发出创建事件
        event::emit(ObjectCreated {
            object_id: object::uid_to_inner(&locked_object.id),
            owner: sender,
            name: locked_object.name,
            timestamp: current_time,
        });

        // 作为共享对象转移
        transfer::public_share_object(locked_object);
    }

    /// 存入代币
    public fun deposit<T>(
        locked_object: &mut LockedObject<T>,
        payment: Coin<T>,
        ctx: &mut TxContext
    ) {
        let amount = coin::value(&payment);
        let sender = tx_context::sender(ctx);
        let current_time = tx_context::epoch(ctx);

        // 验证金额
        assert!(utils::is_valid_amount(amount), E_INVALID_PARAMETERS);

        // 更新余额
        balance::join(&mut locked_object.balance, coin::into_balance(payment));
        locked_object.total_deposited = locked_object.total_deposited + amount;

        // 记录存款历史
        let deposit_record = types::create_deposit_record(
            current_time,
            amount,
            sender
        );
        vector::push_back(&mut locked_object.deposit_history, deposit_record);

        // 更新时间戳
        locked_object.updated_at = current_time;

        // 发出存款事件
        event::emit(DepositEvent {
            object_id: object::uid_to_inner(&locked_object.id),
            owner: locked_object.owner,
            amount,
            timestamp: current_time,
        });
    }

    /// 提取代币
    public fun withdraw<T>(
        locked_object: &mut LockedObject<T>,
        amount: u64,
        ctx: &mut TxContext
    ): Coin<T> {
        let sender = tx_context::sender(ctx);
        let current_time = tx_context::epoch(ctx);
        let time_elapsed = current_time - locked_object.created_at;
        let today_withdrawn = calculate_today_withdrawn(locked_object, current_time);
        let remaining_daily_limit = types::get_max_withdrawal_per_day(&locked_object.lock_rules) - today_withdrawn;
        let fee = utils::basis_points_to_value(amount, types::get_withdrawal_fee_rate(&locked_object.lock_rules));
        let withdraw_amount = amount - fee;
        let withdrawn_balance = balance::split(&mut locked_object.balance, withdraw_amount);
        let withdrawn_coin = coin::from_balance(withdrawn_balance, ctx);

        // 验证权限
        assert!(locked_object.owner == sender, E_NOT_OWNER);

        // 验证金额
        assert!(utils::is_valid_amount(amount), E_INVALID_PARAMETERS);
        assert!(balance::value(&locked_object.balance) >= amount, E_INSUFFICIENT_BALANCE);

        // 检查锁仓时间
        if (time_elapsed < types::get_min_lock_period(&locked_object.lock_rules) && !types::get_emergency_withdrawal(&locked_object.lock_rules)) {
            abort E_LOCK_PERIOD_NOT_MET
        };

        // 检查每日提取限额
        if (amount > remaining_daily_limit) {
            abort E_WITHDRAWAL_LIMIT_EXCEEDED
        };

        // 更新统计
        locked_object.total_withdrawn = locked_object.total_withdrawn + amount;
        locked_object.updated_at = current_time;

        // 发出提取事件
        event::emit(WithdrawalEvent {
            object_id: object::uid_to_inner(&locked_object.id),
            owner: locked_object.owner,
            amount: withdraw_amount,
            fee,
            timestamp: current_time,
        });

        withdrawn_coin
    }

    /// 存入SUI代币（便捷函数）
    public fun deposit_sui(
        locked_object: &mut LockedObject<SUI>,
        payment: Coin<SUI>,
        ctx: &mut TxContext
    ) {
        deposit(locked_object, payment, ctx);
    }

    /// 提取SUI代币（便捷函数）
    public fun withdraw_sui(
        locked_object: &mut LockedObject<SUI>,
        amount: u64,
        ctx: &mut TxContext
    ): Coin<SUI> {
        withdraw(locked_object, amount, ctx)
    }

    /// 更新锁仓规则（仅所有者）
    public fun update_lock_rules<T>(
        locked_object: &mut LockedObject<T>,
        min_lock_period: u64,
        max_withdrawal_per_day: u64,
        auto_reinvest: bool,
        emergency_withdrawal: bool,
        withdrawal_fee_rate: u64,
        ctx: &TxContext
    ) {
        assert!(locked_object.owner == tx_context::sender(ctx), E_NOT_OWNER);
        
        // 验证参数
        assert!(utils::is_valid_amount(min_lock_period), E_INVALID_PARAMETERS);
        assert!(utils::is_valid_amount(max_withdrawal_per_day), E_INVALID_PARAMETERS);
        assert!(utils::is_valid_basis_points(withdrawal_fee_rate), E_INVALID_PARAMETERS);

        locked_object.lock_rules = types::create_lock_rules(
            min_lock_period,
            max_withdrawal_per_day,
            auto_reinvest,
            emergency_withdrawal,
            withdrawal_fee_rate
        );
    }

    /// 转移所有权
    public fun transfer_ownership<T>(
        locked_object: LockedObject<T>,
        new_owner: address,
        ctx: &TxContext
    ) {
        assert!(locked_object.owner == tx_context::sender(ctx), E_NOT_OWNER);
        transfer::public_transfer(locked_object, new_owner);
    }

    // === 查询函数 ===

    /// 获取Object信息
    public fun get_object_info<T>(locked_object: &LockedObject<T>): (String, String, address, u64, u64) {
        (
            locked_object.name,
            locked_object.description,
            locked_object.owner,
            locked_object.created_at,
            locked_object.updated_at
        )
    }

    /// 获取余额信息
    public fun get_balances<T>(locked_object: &LockedObject<T>): (u64, u64, u64) {
        (
            balance::value(&locked_object.balance),
            locked_object.total_deposited,
            locked_object.total_withdrawn
        )
    }

    /// 获取锁仓规则
    public fun get_lock_rules<T>(locked_object: &LockedObject<T>): LockRules {
        locked_object.lock_rules
    }

    /// 获取存款历史数量
    public fun get_deposit_history_count<T>(locked_object: &LockedObject<T>): u64 {
        vector::length(&locked_object.deposit_history)
    }

    /// 检查是否为所有者
    public fun is_owner<T>(locked_object: &LockedObject<T>, addr: address): bool {
        locked_object.owner == addr
    }

    // === 内部辅助函数 ===

    /// 计算今日已提取金额
    fun calculate_today_withdrawn<T>(locked_object: &LockedObject<T>, current_time: u64): u64 {
        // 简化实现：假设每日重置
        // 实际应该根据具体日期计算
        0
    }

    // === 事件定义 ===

    /// Object创建事件
    public struct ObjectCreated has copy, drop {
        object_id: ID,
        owner: address,
        name: String,
        timestamp: u64,
    }

    /// 存款事件
    public struct DepositEvent has copy, drop {
        object_id: ID,
        owner: address,
        amount: u64,
        timestamp: u64,
    }

    /// 提取事件
    public struct WithdrawalEvent has copy, drop {
        object_id: ID,
        owner: address,
        amount: u64,
        fee: u64,
        timestamp: u64,
    }
}
