#[starknet::interface]
trait ISetable<TContractState> {
    fn set_value(ref self: TContractState, value: u32);
    fn get_value(self: @TContractState) -> u32;
}

#[starknet::component]
mod set_component {
    use starknet::storage::{StoragePointerReadAccess, StoragePointerWriteAccess};

    #[storage]
    pub struct Storage {
        value: u32,
    }
    
    #[derive(Drop, Debug, PartialEq, starknet::Event)]
    pub struct ValueSetEvent {
        pub new_value: u32,
    }

    #[event]
    #[derive(Drop, Debug, PartialEq, starknet::Event)]
    pub enum Event {
        ValueSetEvent: ValueSetEvent,
    }

    #[embeddable_as(Setable)]
    impl SetImpl<
        TContractState, 
        +HasComponent<TContractState>
    > of super::ISetable<ComponentState<TContractState>> {
        fn set_value(ref self: ComponentState<TContractState>, value: u32) {
            self.value.write(value);
            self.emit(Event::ValueSetEvent(ValueSetEvent { new_value: value }));
        }
        
        fn get_value(self: @ComponentState<TContractState>) -> u32 {
            self.value.read()
        }
    }
    
   
}

#[starknet::interface]
trait IContract<TContractState> {
    fn upgrade_value(ref self: TContractState, value: u32);
    fn get_contract_value(self: @TContractState) -> u32;
}

#[starknet::contract]
mod contract_impl {
    use super::set_component;
    
    component!(
        path: set_component,
        storage: getset,
        event: SetComponentEvent
    );

    #[storage]
    struct Storage {
        #[substorage(v0)]
        getset: set_component::Storage,
    }
    
    #[event]
    #[derive(Drop, Debug, PartialEq, starknet::Event)]
    pub enum Event {
        SetComponentEvent: set_component::Event,
    }

    #[abi(embed_v0)]
    impl Setable = set_component::Setable<ContractState>;
    
    
    
    #[abi(embed_v0)]
    impl ContractImpl of super::IContract<ContractState> {
        fn upgrade_value(ref self: ContractState, value: u32) {
            self.getset.set_value(value);
        }
        
        fn get_contract_value(self: @ContractState) -> u32 {
            self.getset.get_value()
        }
    }
    
    
}