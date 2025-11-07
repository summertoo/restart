#[test_only]
#[allow(unused_use,duplicate_alias,unused_const,unused_variable)]
module locked_object::module_import_test {
    use locked_object::core::{Self, LockedObject};
    use sui::test_scenario;
    use sui::sui::SUI;

    #[test]
    fun test_module_import() {
        let mut scenario = test_scenario::begin(@0x1);
        let scenario_val = &mut scenario;
        
        // 测试模块导入是否正常工作
        test_scenario::next_tx(scenario_val, @0x1);
        
        // 这个测试只是验证模块能够正确导入和编译
        // 不需要实际创建对象，因为那需要更多的设置
        assert!(true, 0);
        
        test_scenario::end(scenario);
    }
}
