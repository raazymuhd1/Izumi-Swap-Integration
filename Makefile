include .env

# TO EXECUTE EACH OF THESE COMMANDS, use "make exact-input-bsc" command in the terminal, adjust the command u want to execute
# ALL OF THESE COMMANDS ARE FOR TESTING CONTRACT
# testnet fork of bsc 
exact-input-bsc:; forge test --mt testExactInput --fork-url $(BSC_TESTNET_RPC) -vvvv
exact-output-bsc:; forge test --mt testExactOutput --fork-url $(BSC_TESTNET_RPC) -vvvv

# mainnet fork of bsc 
exact-input-bsc-mainnet:; forge test --mt test_exactInputMultihop --fork-url $(BSC_MAINNET_RPC) -vvvv
exact-output-bsc-mainnet:; forge test --mt test_exactOutputMultihop --fork-url $(BSC_MAINNET_RPC) -vvvv


# testnet fork of scroll 
exact-output-scroll:; forge test --mt test_exactOutputMultihop --fork-url $(SCROLL_TESTNET_RPC) -


# mainnet fork of bob
exact-input-bob:; forge test --mt test_exactInputBob --fork-url $(BOB_MAINNET_RPC) -vvvv
exact-output-bob:; forge test --mt test_exactOutputBob --fork-url $(BOB_MAINNET_RPC) -vvvv

# forge verify-contract \
# > --rpc-url https://rpc.gobob.xyz \
# > --verifier blockscout \
# > --verifier-url 'https://explorer-bob-mainnet-0.t.conduit.xyz/api/' \
# > 0xa0Df0E51847D68F5a5d6CCb0e76E150012CA849D \
# > src/TestSwap.sol:TestContractSwap

