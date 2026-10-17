# multisig-48h-demo

Educational 2-of-3 wallet written as a 48-hour demo.

This contract is **not audited** and is **not for mainnet or real funds**. It exists so the write-up can point at a repository that actually compiles and tests.

## What it does

- Owners and a confirmation threshold are fixed at deployment.
- An owner submits a call. That submit counts as their confirmation.
- Another owner confirms.
- Once confirmations reach the threshold, an owner can execute the call.
- An owner can revoke their confirmation before execution.

## Run

```bash
npm install
npm test
```

Requires Node.js 18+.
