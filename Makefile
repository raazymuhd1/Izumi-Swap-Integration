include .env

# TO EXECUTE EACH OF THESE COMMANDS, use "make exact-input-bsc" command in the terminal, adjust the command u want to execute
# ALL OF THESE COMMANDS ARE FOR TESTING CONTRACT
# EXACT INPUT TEST
# testnet fork of bsc 
exact-input-bsc:; forge test --mt test_exactInputMultihop --fork-url $(BSC_TESTNET_RPC) -vvvv
# mainnet fork of bsc 
exact-input-bsc-mainnet:; forge test --mt test_exactInputMultihop --fork-url $(BSC_MAINNET_RPC) -vvvv

# testnet fork of scroll 
exact-input-scroll:; forge test --mt test_exactInputMultihop --fork-url $(SCROLL_TESTNET_RPC) -

# mainnet fork of bob
exact-input-bob:; forge test --mt test_exactInputMultihop --fork-url $(BOB_MAINNET_RPC) -vvvv


# EXACT OUTPUT 
# testnet fork of bsc 
exact-output-bsc:; forge test --mt test_exactOutputMultihop --fork-url $(BSC_TESTNET_RPC) -vvvv
# mainnet fork of bsc 
exact-output-bsc-mainnet:; forge test --mt test_exactOutputMultihop --fork-url $(BSC_MAINNET_RPC) -vvvv

# testnet fork of scroll 
exact-output-scroll:; forge test --mt test_exactOutputMultihop --fork-url $(SCROLL_TESTNET_RPC) -

# mainnet fork of bob
exact-output-bob:; forge test --mt test_exactOutputMultihop --fork-url $(BOB_MAINNET_RPC) -vvvv
