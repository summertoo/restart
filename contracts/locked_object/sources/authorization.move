#[allow(unused_use,duplicate_alias,unused_const,unused_variable,lint(self_transfer))]
module locked_object::authorization {
    use sui::object::{Self, UID};
    use sui::tx_context::{Self, TxContext};
    use sui::transfer;
    use std::vector;
    use std::string::String;
    use locked_object::core::LockedObject;

    /// 授权信息
    public struct Authorization has key, store {
        id: UID,
        owner: address,
        authorized_operators: vector<address>,
        permissions: vector<OperatorPermission>,
    }

    /// 操作员权限
    public struct OperatorPermission has copy, drop, store {
        operator: address,
        can_deposit: bool,
        can_withdraw: bool,
        can_update_rules: bool,
        max_withdrawal_amount: u64, // 单次最大提取限额
        daily_withdrawal_limit: u64, // 每日提取限额
        expires_at: u64, // 权限过期时间
    }

    /// 创建授权管理器
    public fun create_authorization(
        owner: address,
        ctx: &mut TxContext
    ): Authorization {
        Authorization {
            id: object::new(ctx),
            owner,
            authorized_operators: vector::empty(),
            permissions: vector::empty(),
        }
    }

    /// 授权操作员
    public fun authorize_operator(
        auth: &mut Authorization,
        operator: address,
        can_deposit: bool,
        can_withdraw: bool,
        can_update_rules: bool,
        max_withdrawal_amount: u64,
        daily_withdrawal_limit: u64,
        expires_at: u64,
        ctx: &TxContext
    ) {
        assert!(auth.owner == tx_context::sender(ctx), 0);

        // 如果操作员已存在，先移除旧权限
        revoke_operator(auth, operator, ctx);

        let permission = OperatorPermission {
            operator,
            can_deposit,
            can_withdraw,
            can_update_rules,
            max_withdrawal_amount,
            daily_withdrawal_limit,
            expires_at,
        };

        vector::push_back(&mut auth.permissions, permission);
        vector::push_back(&mut auth.authorized_operators, operator);
    }

    /// 撤销操作员权限
    public fun revoke_operator(
        auth: &mut Authorization,
        operator: address,
        ctx: &TxContext
    ) {
        assert!(auth.owner == tx_context::sender(ctx), 0);

        // 移除权限记录
        let mut i = 0;
        while (i < vector::length(&auth.permissions)) {
            let permission = vector::borrow(&auth.permissions, i);
            if (permission.operator == operator) {
                vector::remove(&mut auth.permissions, i);
            } else {
                i = i + 1;
            }
        };

        // 移除操作员列表
        i = 0;
        while (i < vector::length(&auth.authorized_operators)) {
            if (*vector::borrow(&auth.authorized_operators, i) == operator) {
                vector::remove(&mut auth.authorized_operators, i);
            } else {
                i = i + 1;
            }
        }
    }

    /// 检查权限
    public fun check_permission(
        auth: &Authorization,
        operator: address,
        permission_type: u8, // 1=deposit, 2=withdraw, 3=update_rules
        amount: u64,
        current_time: u64
    ): bool {
        let mut i = 0;
        while (i < vector::length(&auth.permissions)) {
            let permission = vector::borrow(&auth.permissions, i);
            if (permission.operator == operator) {
                // 检查权限是否过期
                if (current_time > permission.expires_at) {
                    return false
                };

                // 检查具体权限
                if (permission_type == 1 && !permission.can_deposit) {
                    return false
                };
                if (permission_type == 2 && !permission.can_withdraw) {
                    return false
                };
                if (permission_type == 3 && !permission.can_update_rules) {
                    return false
                };

                // 检查金额限制
                if (permission_type == 2 && amount > permission.max_withdrawal_amount) {
                    return false
                };

                return true
            };
            i = i + 1;
        };
        false
    }

    /// 获取操作员权限信息
    public fun get_operator_permission(
        auth: &Authorization,
        operator: address
    ): (bool, bool, bool, u64, u64, u64) {
        let mut i = 0;
        while (i < vector::length(&auth.permissions)) {
            let permission = vector::borrow(&auth.permissions, i);
            if (permission.operator == operator) {
                return (
                    permission.can_deposit,
                    permission.can_withdraw,
                    permission.can_update_rules,
                    permission.max_withdrawal_amount,
                    permission.daily_withdrawal_limit,
                    permission.expires_at
                )
            };
            i = i + 1;
        };
        (false, false, false, 0, 0, 0)
    }

    /// 检查是否为授权操作员
    public fun is_authorized_operator(auth: &Authorization, operator: address): bool {
        let mut i = 0;
        while (i < vector::length(&auth.authorized_operators)) {
            if (*vector::borrow(&auth.authorized_operators, i) == operator) {
                return true
            };
            i = i + 1;
        };
        false
    }
}
