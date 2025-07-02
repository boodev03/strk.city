#[starknet::contract]
mod TokenFactory {
    use starknet::storage::{StoragePointerWriteAccess, StorableStoragePointerReadAccess};
    use starknet::{ContractAddress, ClassHash, get_caller_address, syscalls::deploy_syscall};
    use openzeppelin_token::erc20::interface::{IERC20Dispatcher, IERC20DispatcherTrait};

    #[storage]
    struct Storage {
        strk_contract_address: ContractAddress,
        platform_wallet_address: ContractAddress,
        erc20_class_hash: ClassHash,
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        TokenCreated: TokenCreated,
    }

    #[derive(Drop, starknet::Event)]
    struct TokenCreated {
        #[key]
        token_address: ContractAddress,
        #[key]
        owner: ContractAddress,
        name: ByteArray,
        symbol: ByteArray,
        supply: u256,
    }

    #[constructor]
    fn constructor(
        ref self: ContractState,
        strk_contract_address: ContractAddress,
        platform_wallet_address: ContractAddress,
        erc20_class_hash: ClassHash,
    ) {
        self.strk_contract_address.write(strk_contract_address);
        self.platform_wallet_address.write(platform_wallet_address);
        self.erc20_class_hash.write(erc20_class_hash);
    }

    #[generate_trait]
    #[abi(per_item)]
    impl ExternalImpl of ExternalTrait {
        #[external(v0)]
        fn create_token(
            ref self: ContractState,
            name: ByteArray,
            symbol: ByteArray,
            fixed_supply: u256,
            token_uri: ByteArray,
            fee: u256,
        ) -> ContractAddress {
            let caller = get_caller_address();
            let strk_contract_address = self.strk_contract_address.read();
            let platform_wallet_address = self.platform_wallet_address.read();
            let erc20_class_hash = self.erc20_class_hash.read();

            // Transfer STRK fee from caller to platform wallet
            let strk_token = IERC20Dispatcher { contract_address: strk_contract_address };
            strk_token.transfer_from(caller, platform_wallet_address, fee);

            // Prepare constructor calldata for ERC20 token
            let mut constructor_calldata = ArrayTrait::new();
            name.serialize(ref constructor_calldata);
            symbol.serialize(ref constructor_calldata);
            fixed_supply.serialize(ref constructor_calldata);
            token_uri.serialize(ref constructor_calldata);
            caller.serialize(ref constructor_calldata);

            // Deploy the token contract using caller address as salt
            let (token_address, _) = deploy_syscall(
                erc20_class_hash,
                caller.into(), // Use caller address as salt
                constructor_calldata.span(),
                false
            ).unwrap();

            // Emit event
            self.emit(TokenCreated {
                token_address,
                owner: caller,
                name,
                symbol,
                supply: fixed_supply,
            });

            token_address
        }

        #[external(v0)]
        fn get_strk_token_address(self: @ContractState) -> ContractAddress {
            self.strk_contract_address.read()
        }

        #[external(v0)]
        fn get_platform_wallet(self: @ContractState) -> ContractAddress {
            self.platform_wallet_address.read()
        }

        #[external(v0)]
        fn update_strk_token_address(ref self: ContractState, new_address: ContractAddress) {
            // Add ownership check here if needed
            self.strk_contract_address.write(new_address);
        }

        #[external(v0)]
        fn update_platform_wallet(ref self: ContractState, new_wallet: ContractAddress) {
            // Add ownership check here if needed
            self.platform_wallet_address.write(new_wallet);
        }

        #[external(v0)]
        fn update_erc20_class_hash(ref self: ContractState, new_class_hash: ClassHash) {
            // Add ownership check here if needed
            self.erc20_class_hash.write(new_class_hash);
        }
    }
}
