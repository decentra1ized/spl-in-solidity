// SPDX-License-Identifier: MIT license
pragma solidity =0.8.28;

struct Mint {
    uint8 decimals;
    uint256 supply;
    address mintAuthority;
    address freezeAuthority;
    address mintAddress;
}

struct TokenAccount {
    address mintAddress;
    address owner;
    uint256 balance;
    bool isFrozen;
}

struct Metadata {
    string name;
    string symbol;
    string tokenURI;
}

contract Spl721 {
    mapping(address => Mint) public mints;
    mapping(address => TokenAccount) public tokenAccounts;
    mapping(address => Metadata) public nftMetadata;
    mapping(address => bool) public mintAddresses;
    mapping(address => bool) public tokenAddresses;

    function initializeMint(
        uint8 decimals,
        address mintAuthority,
        address freezeAuthority,
        address mintAddress
    )
        public
        returns (Mint memory)
    {
        require(!mintAddresses[mintAddress], "Mint already exists");
        mints[mintAddress] = Mint(decimals, 0, mintAuthority, freezeAuthority, mintAddress);
        mintAddresses[mintAddress] = true;
        return mints[mintAddress];
    }

    function setMetadata(
        address mintAddress,
        string memory name,
        string memory symbol,
        string memory tokenURI
    )
        public
    {
        require(mintAddresses[mintAddress], "Mint does not exist");
        nftMetadata[mintAddress] = Metadata(name, symbol, tokenURI);
    }

    function mintNFT(address toMintTokens, address mintAddress) public {
        require(mintAddresses[mintAddress], "NFT mint does not exist");
        require(mints[mintAddress].mintAuthority == msg.sender, "Only the mint authority can mint");
        require(mints[mintAddress].supply == 0, "NFT already minted");
        mints[mintAddress].supply = 1;
        address tokenAddress = address(uint160(uint256(keccak256(abi.encodePacked(toMintTokens, mintAddress)))));
        if (!tokenAddresses[tokenAddress]) {
            tokenAccounts[tokenAddress] = TokenAccount(mintAddress, toMintTokens, 0, false);
            tokenAddresses[tokenAddress] = true;
        }
        tokenAccounts[tokenAddress].balance = 1;
        tokenAccounts[tokenAddress].owner = toMintTokens;
    }

    function transfer(address to, address mintAddress, uint256 amount) public {
        address toTokenAddress = address(uint160(uint256(keccak256(abi.encodePacked(to, mintAddress)))));
        address fromTokenAddress = address(uint160(uint256(keccak256(abi.encodePacked(msg.sender, mintAddress)))));
        require(tokenAccounts[fromTokenAddress].balance >= amount, "Insufficient balance");
        require(amount == 1, "Only transferring 1 NFT at a time");
        require(tokenAccounts[fromTokenAddress].owner == msg.sender, "Not the NFT owner");
        require(!tokenAccounts[fromTokenAddress].isFrozen, "Sender token account is frozen");
        if (tokenAddresses[toTokenAddress]) {
            require(!tokenAccounts[toTokenAddress].isFrozen, "Receiver token account is frozen");
        }
        if (!tokenAddresses[toTokenAddress]) {
            tokenAccounts[toTokenAddress] = TokenAccount(mintAddress, to, 0, false);
            tokenAddresses[toTokenAddress] = true;
        }
        tokenAccounts[fromTokenAddress].balance -= amount;
        tokenAccounts[toTokenAddress].balance += amount;
        tokenAccounts[toTokenAddress].owner = to;
    }

    function freezeAccount(address owner, address mintAddress) public {
        require(mintAddresses[mintAddress], "Mint does not exist");
        require(mints[mintAddress].freezeAuthority == msg.sender, "Only the freeze authority can freeze");
        address tokenAddress = address(uint160(uint256(keccak256(abi.encodePacked(owner, mintAddress)))));
        require(tokenAddresses[tokenAddress], "Token account not found");
        tokenAccounts[tokenAddress].isFrozen = true;
    }

    function getMint(address token) public view returns (Mint memory) {
        return mints[token];
    }

    function getTokenAccount(address owner, address token) public view returns (TokenAccount memory) {
        return tokenAccounts[address(uint160(uint256(keccak256(abi.encodePacked(owner, token)))))];
    }

    function getMetadata(address mintAddress) public view returns (Metadata memory) {
        return nftMetadata[mintAddress];
    }
}



