// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {Spl721, Mint, TokenAccount, Metadata} from "../src/Spl721.sol";

contract Spl721Test is Test {
    Spl721 public spl721;

    function setUp() public {
        spl721 = new Spl721();
    }

    function test_InitializeMint() public {
        address mintAuthority = address(1);
        address freezeAuthority = address(2);
        address mintAddr = address(3);

        spl721.initializeMint(0, mintAuthority, freezeAuthority, mintAddr);

        Mint memory minted = spl721.getMint(mintAddr);

        assertEq(minted.decimals, 0);
        assertEq(minted.supply, 0);
        assertEq(minted.mintAuthority, mintAuthority);
        assertEq(minted.freezeAuthority, freezeAuthority);
        assertEq(minted.mintAddress, mintAddr);
    }

    function test_SetMetadata() public {
        address mintAuthority = address(1);
        address freezeAuthority = address(2);
        address mintAddr = address(3);

        spl721.initializeMint(0, mintAuthority, freezeAuthority, mintAddr);

        spl721.setMetadata(mintAddr, "MyNFT", "MNFT", "ipfs://example");

        Metadata memory data = spl721.getMetadata(mintAddr);
        assertEq(data.name, "MyNFT");
        assertEq(data.symbol, "MNFT");
        assertEq(data.tokenURI, "ipfs://example");
    }

    function test_MintNFT() public {
        address mintAuthority = address(1);
        address freezeAuthority = address(2);
        address mintAddr = address(3);

        spl721.initializeMint(0, mintAuthority, freezeAuthority, mintAddr);

        vm.startPrank(mintAuthority);
        spl721.mintNFT(mintAuthority, mintAddr);
        vm.stopPrank();

        Mint memory minted = spl721.getMint(mintAddr);
        assertEq(minted.supply, 1);

        TokenAccount memory account = spl721.getTokenAccount(mintAuthority, mintAddr);
        assertEq(account.mintAddress, mintAddr);
        assertEq(account.owner, mintAuthority);
        assertEq(account.balance, 1);
        assertFalse(account.isFrozen);
    }

    function test_Transfer() public {
        address mintAuthority = address(1);
        address freezeAuthority = address(2);
        address mintAddr = address(3);

        spl721.initializeMint(0, mintAuthority, freezeAuthority, mintAddr);

        vm.startPrank(mintAuthority);
        spl721.mintNFT(mintAuthority, mintAddr);
        spl721.transfer(address(5), mintAddr, 1);
        vm.stopPrank();

        Mint memory minted = spl721.getMint(mintAddr);
        assertEq(minted.supply, 1);

        TokenAccount memory fromAccount = spl721.getTokenAccount(mintAuthority, mintAddr);
        assertEq(fromAccount.balance, 0);

        TokenAccount memory toAccount = spl721.getTokenAccount(address(5), mintAddr);
        assertEq(toAccount.balance, 1);
        assertEq(toAccount.owner, address(5));
    }

    function test_Freeze() public {
        address mintAuthority = address(1);
        address freezeAuthority = address(2);
        address mintAddr = address(3);

        spl721.initializeMint(0, mintAuthority, freezeAuthority, mintAddr);

        vm.startPrank(mintAuthority);
        spl721.mintNFT(mintAuthority, mintAddr);
        vm.stopPrank();

        vm.startPrank(freezeAuthority);
        spl721.freezeAccount(mintAuthority, mintAddr);
        vm.stopPrank();

        TokenAccount memory frozen = spl721.getTokenAccount(mintAuthority, mintAddr);
        assertTrue(frozen.isFrozen);
    }
}
