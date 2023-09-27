#[test_only]
module examples::object_tests {
    use sui::object;
    use sui::test_scenario;
    use sui::tx_context;
    
    use examples::color_object::{ColorObject, Self};

    #[test]
    fun test_create() {
        let owner: address = @0x1;
        // Create a ColorObject and transfer it to @owner.
        let scenario_val = test_scenario::begin(owner);
        let scenario = &mut scenario_val;
        {
            let ctx = test_scenario::ctx(scenario);
            color_object::create(255, 0, 255, ctx);
        };

        let not_owner = @0x2;
        test_scenario::next_tx(scenario, not_owner);
        {
            assert!(!test_scenario::has_most_recent_for_sender<ColorObject>(scenario), 0);
        };

        test_scenario::next_tx(scenario, owner);
        {
            let object = test_scenario::take_from_sender<ColorObject>(scenario);
            let (red, green, blue) = color_object::get_color(&object);
            assert!(red == 255 && green == 0 && blue == 255, 0);
            test_scenario::return_to_sender(scenario, object);
        };

        test_scenario::end(scenario_val);
    }

    #[test]
    fun test_copy_into() {
        let owner = @0x1;

        let scenario_val = test_scenario::begin(owner);
        let scenario = &mut scenario_val;

        // Create two ColorObjects owned by `owner`, and obtain their IDs.
        let (id1, id2) = {
            let ctx = test_scenario::ctx(scenario);
            color_object::create(255, 255, 255, ctx);
            let id1 = object::id_from_address(tx_context::last_created_object_id(ctx));
            color_object::create(0, 0, 0, ctx);
            let id2 = object::id_from_address(tx_context::last_created_object_id(ctx));
            (id1, id2)
        };

        test_scenario::next_tx(scenario, owner);
        {
            let obj1 = test_scenario::take_from_sender_by_id<ColorObject>(scenario, id1);
            let obj2 = test_scenario::take_from_sender_by_id<ColorObject>(scenario, id2);
            let (red, green, blue) = color_object::get_color(&obj1);
            assert!(red == 255 && green == 255 && blue == 255, 0);

            color_object::copy_object(&obj2, &mut obj1);
            test_scenario::return_to_sender(scenario, obj1);
            test_scenario::return_to_sender(scenario, obj2);
        };

        test_scenario::next_tx(scenario, owner);
        {
            let obj1 = test_scenario::take_from_sender_by_id<ColorObject>(scenario, id1);
            let (red, green, blue) = color_object::get_color(&obj1);
            assert!(red == 0 && green == 0 && blue == 0, 0);
            test_scenario::return_to_sender(scenario, obj1);
        };
        test_scenario::end(scenario_val);
    }

    #[test]
    fun test_delete() {
        let owner = @0x1;
        // Create a ColorObject and transfer it to @owner.
        let scenario_val = test_scenario::begin(owner);
        let scenario = &mut scenario_val;
        {
            let ctx = test_scenario::ctx(scenario);
            color_object::create(255, 0, 255, ctx);
        };
        // Delete the ColorObject just created.
        test_scenario::next_tx(scenario, owner);
        {
            let obj = test_scenario::take_from_sender<ColorObject>(scenario);
            color_object::delete(obj);
        };
        // Verify that the object was indeed deleted.
        test_scenario::next_tx(scenario, owner);
        {
            assert!(!test_scenario::has_most_recent_for_sender<ColorObject>(scenario), 0);
        };
        test_scenario::end(scenario_val);
    }

    #[test]
    fun test_transfer() {
        let owner = @0x1;
        // Create a ColorObject and transfer it to @owner.
        let scenario_val = test_scenario::begin(owner);
        let scenario = &mut scenario_val;
        {
            let ctx = test_scenario::ctx(scenario);
            color_object::create(255, 0, 255, ctx);
        };
        // Transfer the ColorObject to @new_owner.
        let recipient = @0x2;
        test_scenario::next_tx(scenario, owner);
        {
            let obj = test_scenario::take_from_sender<ColorObject>(scenario);
            color_object::transfer(obj, recipient);
        };
        // Check that owner no longer owns the object.
        test_scenario::next_tx(scenario, owner);
        {
            assert!(!test_scenario::has_most_recent_for_sender<ColorObject>(scenario), 0);
        };
        // Check that recipient now owns the object.
        test_scenario::next_tx(scenario, recipient);
        {
            assert!(test_scenario::has_most_recent_for_sender<ColorObject>(scenario), 0);
        };
        test_scenario::end(scenario_val);
    }

    #[test]
    fun test_immutable() {
        let sender1 = @0x1;
        let scenario_val = test_scenario::begin(sender1);
        let scenario = &mut scenario_val;
        {
            let ctx = test_scenario::ctx(scenario);
            color_object::create_immutable(255, 0, 255, ctx);
        };
        test_scenario::next_tx(scenario, sender1);
        {
            // take_owned does not work for immutable objects.
            assert!(!test_scenario::has_most_recent_for_sender<ColorObject>(scenario), 0);
        };

        // Any sender can work.
        let sender2 = @0x2;
        test_scenario::next_tx(scenario, sender2);
        {
            let object = test_scenario::take_immutable<ColorObject>(scenario);
            let (red, green, blue) = color_object::get_color(&object);
            assert!(red == 255 && green == 0 && blue == 255, 0);
            test_scenario::return_immutable(object);
        };
        test_scenario::end(scenario_val);
    }
}