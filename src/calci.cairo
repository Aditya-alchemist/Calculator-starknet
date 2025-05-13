//0x023c4519777639cb8156b071b9b0916716e17de51cbfa279c24cdf63cd4f387e

#[starknet::interface]
trait ICalci<T> {
    fn add(ref self: T, a: u32, b: u32) -> u32;
    fn sub(ref self: T, a: u32, b: u32) -> u32;
    fn mul(ref self: T, a: u32, b: u32) -> u32;
    fn div(ref self: T, a: u32, b: u32) -> u32;
    fn get_value(self: @T) -> u32;
    fn set_value(ref self: T, new_value: u32);
}

#[starknet::component]
mod calci_component {
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
    
    #[embeddable_as(Calci)]
    impl CalciImpl<
        TContractState, 
        +HasComponent<TContractState>
    > of super::ICalci<ComponentState<TContractState>> {
        fn add(ref self: ComponentState<TContractState>, a: u32, b: u32) -> u32 {
            a + b
        }
        
        fn sub(ref self: ComponentState<TContractState>, a: u32, b: u32) -> u32 {
            a - b
        }
        
        fn mul(ref self: ComponentState<TContractState>, a: u32, b: u32) -> u32 {
            a * b
        }
        
        fn div(ref self: ComponentState<TContractState>, a: u32, b: u32) -> u32 {
            a / b
        }
        
        fn get_value(self: @ComponentState<TContractState>) -> u32 {
            self.value.read()
        }
        
        fn set_value(ref self: ComponentState<TContractState>, new_value: u32) {
            self.value.write(new_value);
            self.emit(Event::ValueSetEvent(ValueSetEvent { new_value }));
        }
    }
    
    // Internal methods that can be used by the contract
    #[generate_trait]
    pub impl CalciInternalImpl<
        TContractState, 
        +HasComponent<TContractState>
    > of CalciInternalTrait<TContractState> {
        fn _initialize(ref self: ComponentState<TContractState>, initial_value: u32) {
            self.value.write(initial_value);
        }
    }
}

#[starknet::contract]
mod contract_impl {
    use super::calci_component;
    
    component!(
        path: calci_component, 
        storage: calci, 
        event: CalciEvent
    );
    
    #[storage]
    pub struct Storage {
        #[substorage(v0)]
        calci: calci_component::Storage,
    }
    
    #[event]
    #[derive(Drop, Debug, PartialEq, starknet::Event)]
    pub enum Event {
        CalciEvent: calci_component::Event,
    }
    
    // Embed the component implementation
    #[abi(embed_v0)]
    impl Calci = calci_component::Calci<ContractState>;
    
    // Use internal implementation for constructor
    impl CalciInternal = calci_component::CalciInternalImpl<ContractState>;
    
    #[constructor]
    fn constructor(ref self: ContractState) {
        // Initialize the component's value using internal method
        self.calci._initialize(0);
        
        // Alternative approach would be using the public interface
        // self.calci.set_value(0);
    }
}