### Setup
```
npm install
npx hardhat compile
```

### Testing
```zsh
npx hardhat test
```

### Deploying Manually
Only deployments to Ethereum mainnet and Sepolia are available at this time.
- Fund your wallet address with the network's tokens
- Copy `.env.example` to `.env`, set the environment variables, and `source` the file
- Run the deployment file
```zsh
npx hardhat run scripts/deploy-<contract>.js --network <network>
```