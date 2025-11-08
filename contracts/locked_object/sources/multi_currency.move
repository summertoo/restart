#[allow(unused_use, duplicate_alias, unused_const, unused_variable)]
module locked_object::multi_currency;

use locked_object::core;
use locked_object::types;
use std::string::String;
use sui::balance::{Self, Balance};
use sui::coin::{Self, Coin};
use sui::sui::SUI;

// === 错误码定义 ===
const E_INVALID_COIN_TYPE: u64 = 100;
const E_COIN_NOT_SUPPORTED: u64 = 101;

/// 支持的代币类型枚举
public enum SupportedCoin has copy, drop, store {
    SUI,
    USDC,
    USDT,
}

/// 代币元数据
public struct CoinMetadata has copy, drop, store {
    symbol: String,
    name: String,
    decimals: u8,
}

/// 获取支持的代币元数据
public fun get_coin_metadata(coin_type: SupportedCoin): CoinMetadata {
    if (coin_type == SupportedCoin::SUI) {
        CoinMetadata {
            symbol: std::string::utf8(b"SUI"),
            name: std::string::utf8(b"Sui"),
            decimals: 9,
        }
    } else if (coin_type == SupportedCoin::USDC) {
        CoinMetadata {
            symbol: std::string::utf8(b"USDC"),
            name: std::string::utf8(b"USD Coin"),
            decimals: 6,
        }
    } else {
        CoinMetadata {
            symbol: std::string::utf8(b"USDT"),
            name: std::string::utf8(b"Tether"),
            decimals: 6,
        }
    }
}

/// 创建SUI锁仓对象
public fun create_sui_locked_object(
    name: String,
    description: String,
    min_lock_period: u64,
    max_withdrawal_per_day: u64,
    auto_reinvest: bool,
    emergency_withdrawal: bool,
    withdrawal_fee_rate: u64,
    ctx: &mut sui::tx_context::TxContext,
) {
    core::create_locked_object<SUI>(
        name,
        description,
        min_lock_period,
        max_withdrawal_per_day,
        auto_reinvest,
        emergency_withdrawal,
        withdrawal_fee_rate,
        ctx,
    )
}

/// 创建USDC锁仓对象（需要USDC代币类型）
public fun create_usdc_locked_object<USDC>(
    name: String,
    description: String,
    min_lock_period: u64,
    max_withdrawal_per_day: u64,
    auto_reinvest: bool,
    emergency_withdrawal: bool,
    withdrawal_fee_rate: u64,
    ctx: &mut sui::tx_context::TxContext,
) {
    core::create_locked_object<USDC>(
        name,
        description,
        min_lock_period,
        max_withdrawal_per_day,
        auto_reinvest,
        emergency_withdrawal,
        withdrawal_fee_rate,
        ctx,
    )
}

/// 创建USDT锁仓对象（需要USDT代币类型）
public fun create_usdt_locked_object<USDT>(
    name: String,
    description: String,
    min_lock_period: u64,
    max_withdrawal_per_day: u64,
    auto_reinvest: bool,
    emergency_withdrawal: bool,
    withdrawal_fee_rate: u64,
    ctx: &mut sui::tx_context::TxContext,
) {
    core::create_locked_object<USDT>(
        name,
        description,
        min_lock_period,
        max_withdrawal_per_day,
        auto_reinvest,
        emergency_withdrawal,
        withdrawal_fee_rate,
        ctx,
    )
}

/// 存入USDC代币
public fun deposit_usdc<USDC>(
    locked_object: &mut core::LockedObject<USDC>,
    payment: Coin<USDC>,
    ctx: &mut sui::tx_context::TxContext,
) {
    core::deposit(locked_object, payment, ctx);
}

/// 提取USDC代币
public fun withdraw_usdc<USDC>(
    locked_object: &mut core::LockedObject<USDC>,
    amount: u64,
    ctx: &mut sui::tx_context::TxContext,
): Coin<USDC> {
    core::withdraw(locked_object, amount, ctx)
}

/// 存入USDT代币
public fun deposit_usdt<USDT>(
    locked_object: &mut core::LockedObject<USDT>,
    payment: Coin<USDT>,
    ctx: &mut sui::tx_context::TxContext,
) {
    core::deposit(locked_object, payment, ctx);
}

/// 提取USDT代币
public fun withdraw_usdt<USDT>(
    locked_object: &mut core::LockedObject<USDT>,
    amount: u64,
    ctx: &mut sui::tx_context::TxContext,
): Coin<USDT> {
    core::withdraw(locked_object, amount, ctx)
}

/// 获取代币符号
public fun get_coin_symbol(coin_type: SupportedCoin): String {
    let metadata = get_coin_metadata(coin_type);
    metadata.symbol
}

/// 获取代币名称
public fun get_coin_name(coin_type: SupportedCoin): String {
    let metadata = get_coin_metadata(coin_type);
    metadata.name
}

/// 获取代币精度
public fun get_coin_decimals(coin_type: SupportedCoin): u8 {
    let metadata = get_coin_metadata(coin_type);
    metadata.decimals
}

/// 验证代币类型是否受支持
public fun is_supported_coin_type(coin_type: SupportedCoin): bool {
    if (coin_type == SupportedCoin::SUI) {
        true
    } else if (coin_type == SupportedCoin::USDC) {
        true
    } else {
        true // USDT
    }
}

/// 格式化代币数量（考虑精度）
public fun format_token_amount(amount: u64, decimals: u8): String {
    let divisor = 10u64.pow(decimals);
    let whole_part = amount / divisor;
    let fractional_part = amount % divisor;

    let mut result = whole_part.to_string();
    std::string::append(&mut result, std::string::utf8(b"."));

    let mut fractional_str = fractional_part.to_string();
    // 补零到指定精度
    let i = std::string::length(&fractional_str);
    let mut j = i;
    while (j < (decimals as u64)) {
        std::string::append(&mut fractional_str, std::string::utf8(b"0"));
        j = j + 1;
    };

    std::string::append(&mut result, fractional_str);
    result
}
