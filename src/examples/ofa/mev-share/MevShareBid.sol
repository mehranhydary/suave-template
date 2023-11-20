// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

import "suave/SuaveForge.sol";
import {Bid} from "../base/Bid.sol";

contract MevShareBid is Bid {
    event HintEvent(Suave.BidId bidId, bytes hint);

    event MatchEvent(Suave.BidId matchBidId, bytes matchHint);

    function newBid(
        uint64 decryptionCondition,
        address[] memory bidAllowedPeekers,
        address[] memory bidAllowedStores
    ) external payable returns (bytes memory) {
        // 0. check confidential execution
        require(Suave.isConfidential());

        // 1. fetch bundle data
        bytes memory bundleData = this.fetchBidConfidentialBundleData();

        // 2. sim bundle
        uint64 egp = Suave.simulateBundle(bundleData);

        // 3. extract hint
        bytes memory hint = Suave.extractHint(bundleData);

        // // 4. store bundle and sim results
        Suave.Bid memory bid = Suave.newBid(
            decryptionCondition,
            bidAllowedPeekers,
            bidAllowedStores,
            "mevshare:v0:unmatchedBundles"
        );
        Suave.confidentialStore(bid.id, "mevshare:v0:ethBundles", bundleData);
        Suave.confidentialStore(
            bid.id,
            "mevshare:v0:ethBundleSimResults",
            abi.encode(egp)
        );
        emit BidEvent(bid.id, bid.decryptionCondition, bid.allowedPeekers);
        emit HintEvent(bid.id, hint);

        // // 5. return "callback" to emit hint onchain
        return
            bytes.concat(this.emitBidAndHint.selector, abi.encode(bid, hint));
    }

    function emitBidAndHint(Suave.Bid calldata bid, bytes memory hint) public {
        emit BidEvent(bid.id, bid.decryptionCondition, bid.allowedPeekers);
        emit HintEvent(bid.id, hint);
    }

    function newMatch(
        uint64 decryptionCondition,
        address[] memory bidAllowedPeekers,
        address[] memory bidAllowedStores,
        Suave.BidId shareBidId
    ) external payable returns (bytes memory) {
        // WARNING : this function will copy the original mev share bid
        // into a new key with potentially different permsissions

        require(Suave.isConfidential());
        // 1. fetch confidential data
        bytes memory matchBundleData = this.fetchBidConfidentialBundleData();

        // 2. sim match alone for validity
        // uint64 egp = Suave.simulateBundle(matchBundleData);
        Suave.simulateBundle(matchBundleData);

        // 3. extract hint
        bytes memory matchHint = Suave.extractHint(matchBundleData);

        Suave.Bid memory bid = Suave.newBid(
            decryptionCondition,
            bidAllowedPeekers,
            bidAllowedStores,
            "mevshare:v0:matchBids"
        );
        Suave.confidentialStore(
            bid.id,
            "mevshare:v0:ethBundles",
            matchBundleData
        );
        Suave.confidentialStore(
            bid.id,
            "mevshare:v0:ethBundleSimResults",
            abi.encode(0)
        );

        //4. merge bids
        Suave.BidId[] memory bids = new Suave.BidId[](2);
        bids[0] = shareBidId;
        bids[1] = bid.id;
        Suave.confidentialStore(
            bid.id,
            "mevshare:v0:mergedBids",
            abi.encode(bids)
        );

        return emitMatchBidAndHint(bid, matchHint);
    }

    function emitMatchBidAndHint(
        Suave.Bid memory bid,
        bytes memory matchHint
    ) internal virtual returns (bytes memory) {
        emit BidEvent(bid.id, bid.decryptionCondition, bid.allowedPeekers);
        emit MatchEvent(bid.id, matchHint);

        return bytes.concat(this.emitBid.selector, abi.encode(bid));
    }
}
