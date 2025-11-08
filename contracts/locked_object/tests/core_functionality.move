
#[test_only]
#[allow(unused_use,duplicate_alias,unused_const,unused_variable)]
module locked_object::tests {
    use sui::test_scenario;
    use sui::sui::SUI;
    use sui::coin;
    use locked_object::core::{Self, LockedObject};
    use std::debug::{Self,print};
    use std::string::{Self,utf8,String};


    const ADMIN: address = @0x1;

    #[test]
    fun test_create_locked_object() {
        print(&utf8(b"test_create_locked_object start"));
        let mut scenario = test_scenario::begin(ADMIN);
        let scenario_val = &mut scenario;
        
        // 创建锁仓对象（作为共享对象）
        test_scenario::next_tx(scenario_val, ADMIN);
        {
            core::create_locked_object_for_test<SUI>(
                std::string::utf8(b"Test Object"),
                std::string::utf8(b"Test Description"),
                2592000, // 30天
                1000000, // 每日限额
                false,    // 自动再投资
                true,     // 紧急提取
                100,      // 手续费率
                test_scenario::ctx(scenario_val)
            );
        };
        
        test_scenario::next_tx(scenario_val, ADMIN);
        let locked_obj = test_scenario::take_shared<LockedObject<SUI>>(scenario_val);
        
        // 验证锁仓对象存在
        let (current_balance, total_deposited, total_withdrawn) = core::get_balances(&locked_obj);
        assert!(current_balance == 0, 0);
        assert!(total_deposited == 0, 1);
        assert!(total_withdrawn == 0, 2);
        assert!(core::is_owner(&locked_obj, ADMIN), 3);
        
        test_scenario::return_shared(locked_obj);
        test_scenario::end(scenario);
    }

    // #[test]
    // fun test_deposit_sui() {
    //     let mut scenario = test_scenario::begin(ADMIN);
    //     let scenario_val = &mut scenario;
        
    //     // 创建锁仓对象
    //     test_scenario::next_tx(scenario_val, ADMIN);
    //     {
    //         core::create_locked_object_for_test<SUI>(
    //             std::string::utf8(b"Test Object"),
    //             std::string::utf8(b"Test Description"),
    //             2592000, // 30天
    //             1000000, // 每日限额
    //             false,    // 自动再投资
    //             true,     // 紧急提取
    //             100,      // 手续费率
    //             test_scenario::ctx(scenario_val)
    //         );
    //     };
        
    //     test_scenario::next_tx(scenario_val, ADMIN);
    //     let mut locked_obj = test_scenario::take_shared<LockedObject<SUI>>(scenario_val);
        
    //     // 创建一些SUI代币用于测试
    //     test_scenario::next_tx(scenario_val, ADMIN);
    //     let coins = test_scenario::take_from_sender<coin::Coin<SUI>>(scenario_val);
    //     let deposit_amount = coin::value(&coins);
        
    //     // 存入SUI
    //     core::deposit(&mut locked_obj, coins, test_scenario::ctx(scenario_val));
        
    //     // 验证余额增加
    //     let (current_balance, total_deposited, _) = core::get_balances(&locked_obj);
    //     assert!(current_balance == deposit_amount, 0);
    //     assert!(total_deposited == deposit_amount, 1);
        
    //     test_scenario::return_shared(locked_obj);
    //     test_scenario::end(scenario);
    // }

    // #[test]
    // fun test_withdraw_sui() {
    //     let mut scenario = test_scenario::begin(ADMIN);
    //     let scenario_val = &mut scenario;
        
    //     // 创建锁仓对象
    //     test_scenario::next_tx(scenario_val, ADMIN);
    //     {
    //         core::create_locked_object_for_test<SUI>(
    //             std::string::utf8(b"Test Object"),
    //             std::string::utf8(b"Test Description"),
    //             0,        // 无锁仓时间
    //             1000000,  // 每日限额
    //             false,    // 自动再投资
    //             true,     // 紧急提取
    //             100,      // 手续费率
    //             test_scenario::ctx(scenario_val)
    //         );
    //     };
        
    //     test_scenario::next_tx(scenario_val, ADMIN);
    //     let mut locked_obj = test_scenario::take_shared<LockedObject<SUI>>(scenario_val);
        
    //     // 存入一些SUI
    //     test_scenario::next_tx(scenario_val, ADMIN);
    //     let coins = test_scenario::take_from_sender<coin::Coin<SUI>>(scenario_val);
    //     let deposit_amount = coin::value(&coins);
    //     core::deposit(&mut locked_obj, coins, test_scenario::ctx(scenario_val));
        
    //     // 提取SUI
    //     test_scenario::next_tx(scenario_val, ADMIN);
    //     let withdraw_amount = 500000; // 提取一部分
    //     let withdrawn_coins = core::withdraw(&mut locked_obj, withdraw_amount, test_scenario::ctx(scenario_val));
        
    //     // 验证余额减少
    //     let (current_balance, total_deposited, total_withdrawn) = core::get_balances(&locked_obj);
    //     assert!(current_balance == deposit_amount - withdraw_amount, 0);
    //     assert!(total_deposited == deposit_amount, 1);
    //     assert!(total_withdrawn >= withdraw_amount, 2);
        
    //     // 销毁提取的代币（测试用）
    //     coin::destroy_zero(withdrawn_coins);
        
    //     test_scenario::return_shared(locked_obj);
    //     test_scenario::end(scenario);
    // }
}
