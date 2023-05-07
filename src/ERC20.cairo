#[contract]
mod ERC20{
    use zeroable::Zeroable;
    use starknet::get_caller_address;
    use starknet::contract_address_const;
    use starknet::ContractAddress;
    use starknet::contract_address::ContractAddressZeroable;

    struct Storage{
        name : felt252,
        symbol : felt252,
        decimals : u8,
        total_supply : u256,
        balances: LegacyMap::<ContractAddress, u256>,
        allowances: LegacyMap::<(ContractAddress, ContractAddress), u256>
    }

    #[event]
    fn Transfer(from: ContractAddress, to: ContractAddress, value: u256){}

    #[event]
    fn Approval(owner: ContractAddress, spender: ContractAddress, value: u256){}

    #[contructor]
    fn constructor(
        name_: felt252,
        symbol_: felt252,
        decimals_: u8,
        initialSupply_: u256,
        recipient: ContractAddress
    ){
       name::write(name_);
       symbol::write(symbol_);
       decimals::write(decimals_);
       total_supply::write(initialSupply_);
       assert(!recipient.is_zero(), 'ERC20: mint to 0 address');
       total_supply::write(initialSupply_);
       balances::write(recipient, initialSupply_);
       Transfer(contract_address_const::<0>(), recipient, initialSupply_);
    }

    #[view]
    fn get_symbol() -> felt252 {
        symbol::read()
    }

    #[view]
    fn get_name() -> felt252 {
        name::read()
    }

    #[view]
    fn get_total_supply() -> u256 {
        total_supply::read()
    }

    #[view]
    fn get_decimals() -> u8 {
        decimals::read()
    }

    #[view]
    fn balance_of(account: ContractAddress) -> u256{
        balances::read(account)
    }

    #[view]
    fn allowance(owner: ContractAddress, spender:ContractAddress) -> u256{
        allowances::read((owner, spender))
    }

    #[external]
    fn transfer(recipient : ContractAddress, amount : u256){
        let sender = get_caller_address();
        transfer_helper(sender, recipient, amount);
    }

    #[external]
    fn transfer_from(sender : ContractAddress, recipient : ContractAddress, amount : u256){
        let caller = get_caller_address();
        spend_allowance(sender, caller, amount);
        transfer_helper(sender, recipient, amount);
    }

    #[external]
    fn approve(spender : ContractAddress, amount : u256){
        let caller = get_caller_address();
        approve_helper(caller, spender, amount);
    }

    #[external]
    fn increase_allowance(spender : ContractAddress, added_value : u256){
        let caller = get_caller_address();
        approve_helper(caller, spender, allowances::read((caller, spender)) + added_value);
    }

    #[external]
    fn decrease_allowance(spender : ContractAddress, substracted_value : u256){
        let caller = get_caller_address();
        approve_helper(caller, spender, allowances::read((caller, spender)) - substracted_value);
    }

    fn transfer_helper(sender : ContractAddress, recipient : ContractAddress, amount : u256){
        assert(!sender.is_zero(), 'ERC20: transfer from 0');
        assert(!recipient.is_zero(), 'ERC20: transfer to 0');
        // assert(balances::read(sender) >= amount, 'ERC20: sender does not have enough funds');
        balances::write(sender, balances::read(sender) - amount);
        balances::write(recipient, balances::read(recipient) + amount);
        Transfer(sender, recipient, amount);
    }

    fn spend_allowance(owner : ContractAddress, spender: ContractAddress, amount : u256){
        let current_allowance = allowances::read((owner, spender));
        let ONES_MASK = 0xffffffffffffffffffffffffffffffff_u128;
        let is_unlimited_allowance = current_allowance.low == ONES_MASK & current_allowance.high == ONES_MASK;
        if !is_unlimited_allowance {
            approve_helper(owner, spender, current_allowance - amount);
        }
    }

    fn approve_helper(owner: ContractAddress, spender : ContractAddress, amount : u256){
        assert(!spender.is_zero(), 'ERC20: approve from 0');
        allowances::write((owner, spender), amount);
        Approval(owner, spender, amount);
    }
}

#[cfg(test)]
mod tests{
    use integer::u256;
    use integer::u256_from_felt252;
    
    use starknet::contract_address_const;
    use starknet::ContractAddress;

    use super::ERC20;

    #[test]
    #[available_gas(20000000)]
    fn test_constructor(){
        let initial_supply : u256 = u256_from_felt252(2000);
        let account: ContractAddress = contract_address_const::<1>();
        let decimals : u8 = 18_u8;
        let name : felt252 = 'NFINIC';
        let symbol : felt252 = 'NFN';

        ERC20::constructor(name, symbol, decimals, initial_supply, account);

        let res_name = ERC20::get_name();

        assert(res_name == 'NFINIC', 'name is not correct');

    }
}