#[test_only]
module locked_object::tests {
    use sui::test_scenario::{Self, Scenario};
    use sui::sui::SUI;
    use locked_object::locked_object::{Self, LockedObject};

    const ADMIN: address = @0x1;
    const USER: address = @0x2;

    #[test]
    fun test_create_locked_object() {
        let mut scenario = test_scenario::begin(ADMIN);
        let scenario_val = &mut scenario;
        
        // 创建锁仓对象
        let locked_obj = test_scenario::take_shared<LockedObject>(scenario_val);
        
        // 验证锁仓对象存在
        assert!(locked_object::balance(&locked_obj) == 0, 0);
        assert!(locked_object::owner(&locked_obj) == ADMIN, 1);
        
        test_scenario::return_shared(locked_obj);
        test_scenario::end(scenario);
    }

    #[test]
    fun test_deposit_sui() {
        let mut scenario = test_scenario::begin(ADMIN);
        let scenario_val = &mut scenario;
        
        // 创建锁仓对象
        let locked_obj = test_scenario::take_shared<LockedObject>(scenario_val);
        
        // 创建一些SUI代币用于测试
        let coins = test_scenario::take_from_sender<sui::coin::Coin<SUI>>(scenario_val);
        let deposit_amount = 1000000; // 0.001 SUI
        
        // 存入SUI
        locked_object::deposit_sui(&mut locked_obj, coins, deposit_amount);
        
        // 验证余额增加
        assert!(locked_object::balance(&locked_obj) == deposit_amount, 2);
        
        test_scenario::return_shared(locked_obj);
        test_scenario::end(scenario);
    }

    #[test]
    fun test_withdraw_sui() {
        let mut scenario = test_scenario::begin(ADMIN);
        let scenario_val = &mut scenario;
        
        // 创建锁仓对象
        let locked_obj = test_scenario::take_shared<LockedObject>(scenario_val);
        
        // 存入一些SUI
        let coins = test_scenario::take_from_sender<sui::coin::Coin<SUI>>(scenario_val);
        let deposit_amount = 2000000; // 0.002 SUI
        locked_object::deposit_sui(&mut locked_obj, coins, deposit_amount);
        
        // 提取SUI
        let withdrawn_coins = locked_object::withdraw_sui(&mut locked_obj, 1000000); // 提取0.001 SUI
        
        // 验证余额减少
        assert!(locked_object::balance(&locked_obj) == 1000000, 3);
        
        // 销毁提取的代币（测试用）
        sui::coin::destroy_zero(witdrawn_coins);
        
        test_scenario::return_shared(locked_obj);
        test_scenario::end(scenario);
    }
}
