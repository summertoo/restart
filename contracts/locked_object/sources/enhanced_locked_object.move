#[allow(unused_use, duplicate_alias, unused_const, unused_variable, lint(self_transfer))]
module locked_object::enhanced;

use locked_object::authorization::{Self, Authorization};
use locked_object::utils;
use std::string::String;
use std::vector;
use sui::balance::{Self, Balance};
use sui::coin::{Self, Coin};
use sui::event;
use sui::object::{Self, UID, ID};
use sui::transfer;
use sui::tx_context::{Self, TxContext};

// === 错误码定义 ===
const E_NOT_OWNER: u64 = 0;
const E_NOT_AUTHORIZED: u64 = 1;
const E_INSUFFICIENT_BALANCE: u64 = 2;
const E_LOCK_PERIOD_NOT_MET: u64 = 3;
const E_WITHDRAWAL_LIMIT_EXCEEDED: u64 = 4;
const E_INVALID_PARAMETERS: u64 = 5;
const E_PERMISSION_EXPIRED: u64 = 6;

/// 增强版自锁仓Object，支持授权操作
public struct EnhancedLockedObject<phantom T> has key, store {
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
    // === 授权管理 ===
    authorization: Authorization,
    enable_authorization: bool, // 是否启用授权模式
}

/// 锁仓规则
public struct LockRules has copy, drop, store {
    min_lock_period: u64, // 最小锁仓时间(秒)
    max_withdrawal_per_day: u64, // 每日最大提取限额
    auto_reinvest: bool, // 自动再投资
    emergency_withdrawal: bool, // 紧急提取
    withdrawal_fee_rate: u64, // 提取手续费率(基点)
}

/// 存款记录
public struct DepositRecord has copy, drop, store {
    timestamp: u64,
    amount: u64,
    depositor: address,
}

// === 核心函数 ===

/// 创建新的增强版自锁仓Object
public fun create_enhanced_locked_object<T>(
    name: String,
    description: String,
    min_lock_period: u64,
    max_withdrawal_per_day: u64,
    auto_reinvest: bool,
    emergency_withdrawal: bool,
    withdrawal_fee_rate: u64,
    enable_authorization: bool,
    ctx: &mut TxContext,
) {
    let current_time = tx_context::epoch(ctx);
    let sender = tx_context::sender(ctx);

    // 验证参数
    assert!(utils::is_valid_amount(min_lock_period), E_INVALID_PARAMETERS);
    assert!(utils::is_valid_amount(max_withdrawal_per_day), E_INVALID_PARAMETERS);
    assert!(utils::is_valid_basis_points(withdrawal_fee_rate), E_INVALID_PARAMETERS);

    let lock_rules = LockRules {
        min_lock_period,
        max_withdrawal_per_day,
        auto_reinvest,
        emergency_withdrawal,
        withdrawal_fee_rate,
    };

    let authorization = authorization::create_authorization(sender, ctx);

    let locked_object = EnhancedLockedObject<T> {
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
        // 授权管理
        authorization,
        enable_authorization,
    };

    // 发出创建事件
    event::emit(ObjectCreated {
        object_id: object::uid_to_inner(&locked_object.id),
        owner: sender,
        name: locked_object.name,
        timestamp: current_time,
    });

    // 转移给创建者
    transfer::public_transfer(locked_object, sender);
}

/// 存入代币（支持授权）
public fun deposit<T>(
    locked_object: &mut EnhancedLockedObject<T>,
    payment: Coin<T>,
    ctx: &mut TxContext,
) {
    let amount = coin::value(&payment);
    let sender = tx_context::sender(ctx);
    let current_time = tx_context::epoch(ctx);

    // 验证金额
    assert!(utils::is_valid_amount(amount), E_INVALID_PARAMETERS);

    // 权限检查
    if (locked_object.enable_authorization) {
        if (sender != locked_object.owner) {
            assert!(
                authorization::check_permission(
                    &locked_object.authorization,
                    sender,
                    1, // deposit permission
                    amount,
                    current_time,
                ),
                E_NOT_AUTHORIZED,
            );
        }
    } else {
        // 传统模式：只有所有者可以操作
        assert!(sender == locked_object.owner, E_NOT_OWNER);
    };

    // 更新余额
    balance::join(&mut locked_object.balance, coin::into_balance(payment));
    locked_object.total_deposited = locked_object.total_deposited + amount;

    // 记录存款历史
    let deposit_record = DepositRecord {
        timestamp: current_time,
        amount,
        depositor: sender,
    };
    vector::push_back(&mut locked_object.deposit_history, deposit_record);

    // 更新时间戳
    locked_object.updated_at = current_time;

    // 发出存款事件
    event::emit(DepositEvent {
        object_id: object::uid_to_inner(&locked_object.id),
        owner: locked_object.owner,
        operator: sender,
        amount,
        timestamp: current_time,
    });
}

/// 提取代币（支持授权）
public fun withdraw<T>(
    locked_object: &mut EnhancedLockedObject<T>,
    amount: u64,
    ctx: &mut TxContext,
): Coin<T> {
    let sender = tx_context::sender(ctx);
    let current_time = tx_context::epoch(ctx);
    let time_elapsed = current_time - locked_object.created_at;
    let today_withdrawn = calculate_today_withdrawn(locked_object, current_time);
    let remaining_daily_limit = locked_object.lock_rules.max_withdrawal_per_day - today_withdrawn;
    let fee = utils::basis_points_to_value(amount, locked_object.lock_rules.withdrawal_fee_rate);
    let withdraw_amount = amount - fee;

    // 权限检查
    if (locked_object.enable_authorization) {
        if (sender != locked_object.owner) {
            assert!(
                authorization::check_permission(
                    &locked_object.authorization,
                    sender,
                    2, // withdraw permission
                    amount,
                    current_time,
                ),
                E_NOT_AUTHORIZED,
            );
        }
    } else {
        // 传统模式：只有所有者可以操作
        assert!(sender == locked_object.owner, E_NOT_OWNER);
    };

    // 验证金额
    assert!(utils::is_valid_amount(amount), E_INVALID_PARAMETERS);
    assert!(balance::value(&locked_object.balance) >= amount, E_INSUFFICIENT_BALANCE);

    // 检查锁仓时间
    if (
        time_elapsed < locked_object.lock_rules.min_lock_period && !locked_object.lock_rules.emergency_withdrawal
    ) {
        abort E_LOCK_PERIOD_NOT_MET
    };

    // 检查每日提取限额
    if (amount > remaining_daily_limit) {
        abort E_WITHDRAWAL_LIMIT_EXCEEDED
    };

    // 执行提取
    let withdrawn_balance = balance::split(&mut locked_object.balance, withdraw_amount);
    let withdrawn_coin = coin::from_balance(withdrawn_balance, ctx);

    // 更新统计
    locked_object.total_withdrawn = locked_object.total_withdrawn + amount;
    locked_object.updated_at = current_time;

    // 发出提取事件
    event::emit(WithdrawalEvent {
        object_id: object::uid_to_inner(&locked_object.id),
        owner: locked_object.owner,
        operator: sender,
        amount: withdraw_amount,
        fee,
        timestamp: current_time,
    });

    withdrawn_coin
}

/// 授权操作员
public fun authorize_operator<T>(
    locked_object: &mut EnhancedLockedObject<T>,
    operator: address,
    can_deposit: bool,
    can_withdraw: bool,
    can_update_rules: bool,
    max_withdrawal_amount: u64,
    daily_withdrawal_limit: u64,
    expires_at: u64,
    ctx: &TxContext,
) {
    assert!(locked_object.owner == tx_context::sender(ctx), E_NOT_OWNER);

    authorization::authorize_operator(
        &mut locked_object.authorization,
        operator,
        can_deposit,
        can_withdraw,
        can_update_rules,
        max_withdrawal_amount,
        daily_withdrawal_limit,
        expires_at,
        ctx,
    );
}

/// 撤销操作员权限
public fun revoke_operator<T>(
    locked_object: &mut EnhancedLockedObject<T>,
    operator: address,
    ctx: &TxContext,
) {
    assert!(locked_object.owner == tx_context::sender(ctx), E_NOT_OWNER);

    authorization::revoke_operator(&mut locked_object.authorization, operator, ctx);
}

/// 启用/禁用授权模式
public fun toggle_authorization_mode<T>(
    locked_object: &mut EnhancedLockedObject<T>,
    enable: bool,
    ctx: &TxContext,
) {
    assert!(locked_object.owner == tx_context::sender(ctx), E_NOT_OWNER);
    locked_object.enable_authorization = enable;
}

/// 更新锁仓规则（支持授权）
public fun update_lock_rules<T>(
    locked_object: &mut EnhancedLockedObject<T>,
    min_lock_period: u64,
    max_withdrawal_per_day: u64,
    auto_reinvest: bool,
    emergency_withdrawal: bool,
    withdrawal_fee_rate: u64,
    ctx: &TxContext,
) {
    let sender = tx_context::sender(ctx);

    // 权限检查
    if (locked_object.enable_authorization) {
        if (sender != locked_object.owner) {
            assert!(
                authorization::check_permission(
                    &locked_object.authorization,
                    sender,
                    3, // update_rules permission
                    0,
                    tx_context::epoch(ctx),
                ),
                E_NOT_AUTHORIZED,
            );
        }
    } else {
        assert!(sender == locked_object.owner, E_NOT_OWNER);
    };

    // 验证参数
    assert!(utils::is_valid_amount(min_lock_period), E_INVALID_PARAMETERS);
    assert!(utils::is_valid_amount(max_withdrawal_per_day), E_INVALID_PARAMETERS);
    assert!(utils::is_valid_basis_points(withdrawal_fee_rate), E_INVALID_PARAMETERS);

    locked_object.lock_rules =
        LockRules {
            min_lock_period,
            max_withdrawal_per_day,
            auto_reinvest,
            emergency_withdrawal,
            withdrawal_fee_rate,
        };
}

/// 转移所有权
public fun transfer_ownership<T>(
    locked_object: EnhancedLockedObject<T>,
    new_owner: address,
    ctx: &TxContext,
) {
    assert!(locked_object.owner == tx_context::sender(ctx), E_NOT_OWNER);
    transfer::public_transfer(locked_object, new_owner);
}

// === 查询函数 ===

/// 获取Object信息
public fun get_object_info<T>(
    locked_object: &EnhancedLockedObject<T>,
): (String, String, address, u64, u64, bool) {
    (
        locked_object.name,
        locked_object.description,
        locked_object.owner,
        locked_object.created_at,
        locked_object.updated_at,
        locked_object.enable_authorization,
    )
}

/// 获取余额信息
public fun get_balances<T>(locked_object: &EnhancedLockedObject<T>): (u64, u64, u64) {
    (
        balance::value(&locked_object.balance),
        locked_object.total_deposited,
        locked_object.total_withdrawn,
    )
}

/// 获取锁仓规则
public fun get_lock_rules<T>(locked_object: &EnhancedLockedObject<T>): LockRules {
    locked_object.lock_rules
}

/// 检查操作员权限
public fun check_operator_permission<T>(
    locked_object: &EnhancedLockedObject<T>,
    operator: address,
    permission_type: u8,
    amount: u64,
    current_time: u64,
): bool {
    if (!locked_object.enable_authorization) {
        return operator == locked_object.owner
    };

    if (operator == locked_object.owner) {
        return true
    };

    authorization::check_permission(
        &locked_object.authorization,
        operator,
        permission_type,
        amount,
        current_time,
    )
}

/// 获取操作员权限详情
public fun get_operator_permission<T>(
    locked_object: &EnhancedLockedObject<T>,
    operator: address,
): (bool, bool, bool, u64, u64, u64) {
    authorization::get_operator_permission(&locked_object.authorization, operator)
}

// === 内部辅助函数 ===

/// 计算今日已提取金额
fun calculate_today_withdrawn<T>(locked_object: &EnhancedLockedObject<T>, current_time: u64): u64 {
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
    operator: address,
    amount: u64,
    timestamp: u64,
}

/// 提取事件
public struct WithdrawalEvent has copy, drop {
    object_id: ID,
    owner: address,
    operator: address,
    amount: u64,
    fee: u64,
    timestamp: u64,
}
