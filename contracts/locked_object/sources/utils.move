#[allow(unused_use, duplicate_alias, unused_const, unused_variable)]
module locked_object::utils;

use std::string::String;

// === 错误码定义 ===
const E_NOT_OWNER: u64 = 0;
const E_INSUFFICIENT_BALANCE: u64 = 1;
const E_LOCK_PERIOD_NOT_MET: u64 = 2;
const E_WITHDRAWAL_LIMIT_EXCEEDED: u64 = 3;
const E_ACCESS_DENIED: u64 = 4;
const E_INVALID_PARAMETERS: u64 = 5;

// === 数学工具函数 ===

/// 安全的除法，避免除零错误
public fun safe_divide(numerator: u64, denominator: u64): u64 {
    if (denominator == 0) {
        0
    } else {
        numerator / denominator
    }
}

/// 计算百分比 (基点)
public fun calculate_percentage(part: u64, whole: u64): u64 {
    if (whole == 0) {
        0
    } else {
        (part * 10000) / whole
    }
}

/// 计算基点对应的实际值
public fun basis_points_to_value(amount: u64, basis_points: u64): u64 {
    (amount * basis_points) / 10000
}

/// 计算最小值
public fun min(a: u64, b: u64): u64 {
    if (a < b) a else b
}

/// 计算最大值
public fun max(a: u64, b: u64): u64 {
    if (a > b) a else b
}

/// 限制数值在指定范围内
public fun clamp(value: u64, min_value: u64, max_value: u64): u64 {
    let result = max(value, min_value);
    min(result, max_value)
}

// === 时间工具函数 ===

/// 检查时间间隔是否满足要求
public fun is_time_interval_satisfied(
    last_time: u64,
    current_time: u64,
    required_interval: u64,
): bool {
    current_time >= last_time + required_interval
}

/// 计算时间差
public fun time_difference(current_time: u64, past_time: u64): u64 {
    if (current_time > past_time) {
        current_time - past_time
    } else {
        0
    }
}

/// 将秒转换为天
public fun seconds_to_days(seconds: u64): u64 {
    seconds / 86400
}

/// 将天转换为秒
public fun days_to_seconds(days: u64): u64 {
    days * 86400
}

// === 字符串工具函数 ===

/// 检查字符串是否为空
public fun is_string_empty(s: &String): bool {
    let length = std::string::length(s);
    length == 0
}

// === 验证工具函数 ===

/// 验证地址是否有效
public fun is_valid_address(addr: address): bool {
    // 在Sui中，所有address都是有效的
    true
}

/// 验证金额是否在合理范围内
public fun is_valid_amount(amount: u64): bool {
    amount > 0 && amount <= 1000000_000_000_000 // 最大1e15 MIST
}

/// 验证基点是否在有效范围内
public fun is_valid_basis_points(basis_points: u64): bool {
    basis_points <= 10000 // 最大100%
}

// === 权限检查函数 ===

/// 检查是否为所有者
public fun is_owner(object_owner: address, caller: address): bool {
    object_owner == caller
}

// === 风险管理工具函数 ===

/// 计算最大可投资金额
public fun calculate_max_investment_amount(total_balance: u64, risk_percentage: u64): u64 {
    basis_points_to_value(total_balance, risk_percentage)
}

/// 检查是否超过风险限制
public fun exceeds_risk_limit(current_amount: u64, max_amount: u64): bool {
    current_amount > max_amount
}

// === 性能计算工具函数 ===

/// 计算收益率
public fun calculate_return_rate(profit: u64, investment: u64): u64 {
    calculate_percentage(profit, investment)
}

// === 统计工具函数 ===

/// 计算平均值
public fun calculate_average(values: &vector<u64>): u64 {
    let len = vector::length(values);
    if (len == 0) {
        0
    } else {
        let mut sum = 0;
        let mut i = 0;
        while (i < len) {
            sum = sum + *vector::borrow(values, i);
            i = i + 1;
        };
        sum / len
    }
}

// === 调试工具函数 ===

/// 验证合约状态一致性
public fun validate_consistency(
    total_deposited: u64,
    total_withdrawn: u64,
    current_balance: u64,
): bool {
    let expected_balance = total_deposited - total_withdrawn;
    current_balance == expected_balance
}
