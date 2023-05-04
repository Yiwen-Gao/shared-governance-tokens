### Setup
```
npm install
npx hardhat compile
```

### Testing
```zsh
npx hardhat test
```

TODO @ygao: write deployment script
### Deploying Manually
- Fund your wallet address with GoerliETH
- Set your private key as an environment variable
```zsh
export PRIVATE_KEY=123
```
- Use the deployment file
```zsh
npx hardhat run scripts/deploy-<contract>.js --network goerli
```