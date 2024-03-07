```shell
npm i
yarn chain // Para ejecutar el blockchain
yarn deploy // Para hacer deploy a los contratos
yarn start // Para ejecutar el frontend
```

Los contratos y el deployment se encuentran en packages/hardhat

Tambien hacer npm i en packages/hardhat

Para agregar SupplyChain al deploy, hacer una copia del codigo de 00_deploy_your_contract.ts en un nuevo archivo, cambiar el 00 por 01 y donde dice YourContract por SupplyChain dentro del codigo.

https://scaffoldeth.io/