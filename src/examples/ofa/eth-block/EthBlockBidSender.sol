// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

import "suave/SuaveForge.sol";
import {EthBlockBid} from "./EthBlockBid.sol";

contract EthBlockBidSender is EthBlockBid {
    string boostRelayUrl;

    constructor(string memory boostRelayUrl_) {
        boostRelayUrl = boostRelayUrl_;
    }

    function buildAndEmit(
        Suave.BuildBlockArgs memory blockArgs,
        uint64 blockHeight,
        Suave.BidId[] memory bids,
        string memory namespace
    ) public virtual override returns (bytes memory) {
        require(Suave.isConfidential());

        (Suave.Bid memory blockBid, bytes memory builderBid) = this.doBuild(
            blockArgs,
            blockHeight,
            bids,
            namespace
        );
        Suave.submitEthBlockBidToRelay(boostRelayUrl, builderBid);

        emit BidEvent(
            blockBid.id,
            blockBid.decryptionCondition,
            blockBid.allowedPeekers
        );
        return bytes.concat(this.emitBid.selector, abi.encode(blockBid));
    }
}
