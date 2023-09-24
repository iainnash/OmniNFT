Why worry about bridging your NFT when this NFT can live across many chains all at once.

When minting this Omnichain NFT, all supported chains receive the same NFT.
However, when you transfer this NFT on any of these chains from the owner address, all the other NFTs automatically follow, powered by Axelar multichain message passing.


[child chains]
-> message back to parent chains [mint] or [transfer]

[parent chain]
-> receives messages and updates state
if an action occurs on parent, the action is broadcast out to all child chains


Example messaging between base (main chain) and all child chains:
https://goerli.basescan.org/tx/0xe7dd4fe30ea8fcd62212105f937229b6816e8d3a86f69f88c3d69bf68321fbb6
https://testnet.axelarscan.io/gmp/0x59fed0968dafaca08c854a169b56104cc1fac5d83e2491ed960cc77c8657674e


