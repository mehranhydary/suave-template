// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

import "suave/SuaveForge.sol";
import "../base/Structs.sol";
import {Bid} from "../base/Bid.sol";

contract EthBlockBid is Bid {
    event BuilderBoostBidEvent(Suave.BidId bidId, bytes builderBid);

    function idsEqual(
        Suave.BidId _l,
        Suave.BidId _r
    ) public pure returns (bool) {
        bytes memory l = abi.encodePacked(_l);
        bytes memory r = abi.encodePacked(_r);
        for (uint i = 0; i < l.length; i++) {
            if (bytes(l)[i] != r[i]) {
                return false;
            }
        }

        return true;
    }

    function buildMevShare(
        Suave.BuildBlockArgs memory blockArgs,
        uint64 blockHeight
    ) public returns (bytes memory) {
        require(Suave.isConfidential());

        Suave.Bid[] memory allShareMatchBids = Suave.fetchBids(
            blockHeight,
            "mevshare:v0:matchBids"
        );
        Suave.Bid[] memory allShareUserBids = Suave.fetchBids(
            blockHeight,
            "mevshare:v0:unmatchedBundles"
        );

        if (allShareUserBids.length == 0) {
            revert Suave.PeekerReverted(address(this), "no bids");
        }

        Suave.Bid[] memory allBids = new Suave.Bid[](allShareUserBids.length);
        for (uint i = 0; i < allShareUserBids.length; i++) {
            // TODO: sort matches by egp first!
            Suave.Bid memory bidToInsert = allShareUserBids[i]; // will be updated with the best match if any
            for (uint j = 0; j < allShareMatchBids.length; j++) {
                // TODO: should be done once at the start and sorted
                Suave.BidId[] memory mergedBidIds = abi.decode(
                    Suave.confidentialRetrieve(
                        allShareMatchBids[j].id,
                        "mevshare:v0:mergedBids"
                    ),
                    (Suave.BidId[])
                );
                if (idsEqual(mergedBidIds[0], allShareUserBids[i].id)) {
                    bidToInsert = allShareMatchBids[j];
                    break;
                }
            }
            allBids[i] = bidToInsert;
        }

        EgpBidPair[] memory bidsByEGP = new EgpBidPair[](allBids.length);
        for (uint i = 0; i < allBids.length; i++) {
            bytes memory simResults = Suave.confidentialRetrieve(
                allBids[i].id,
                "mevshare:v0:ethBundleSimResults"
            );
            uint64 egp = abi.decode(simResults, (uint64));
            bidsByEGP[i] = EgpBidPair(egp, allBids[i].id);
        }

        // Bubble sort, cause why not
        uint n = bidsByEGP.length;
        for (uint i = 0; i < n - 1; i++) {
            for (uint j = i + 1; j < n; j++) {
                if (bidsByEGP[i].egp < bidsByEGP[j].egp) {
                    EgpBidPair memory temp = bidsByEGP[i];
                    bidsByEGP[i] = bidsByEGP[j];
                    bidsByEGP[j] = temp;
                }
            }
        }

        Suave.BidId[] memory allBidIds = new Suave.BidId[](allBids.length);
        for (uint i = 0; i < bidsByEGP.length; i++) {
            allBidIds[i] = bidsByEGP[i].bidId;
        }

        return buildAndEmit(blockArgs, blockHeight, allBidIds, "mevshare:v0");
    }

    function buildFromPool(
        Suave.BuildBlockArgs memory blockArgs,
        uint64 blockHeight
    ) public returns (bytes memory) {
        require(Suave.isConfidential());

        Suave.Bid[] memory allBids = Suave.fetchBids(
            blockHeight,
            "default:v0:ethBundles"
        );
        if (allBids.length == 0) {
            revert Suave.PeekerReverted(address(this), "no bids");
        }

        EgpBidPair[] memory bidsByEGP = new EgpBidPair[](allBids.length);
        for (uint i = 0; i < allBids.length; i++) {
            bytes memory simResults = Suave.confidentialRetrieve(
                allBids[i].id,
                "default:v0:ethBundleSimResults"
            );
            uint64 egp = abi.decode(simResults, (uint64));
            bidsByEGP[i] = EgpBidPair(egp, allBids[i].id);
        }

        // Bubble sort, cause why not
        uint n = bidsByEGP.length;
        for (uint i = 0; i < n - 1; i++) {
            for (uint j = i + 1; j < n; j++) {
                if (bidsByEGP[i].egp < bidsByEGP[j].egp) {
                    EgpBidPair memory temp = bidsByEGP[i];
                    bidsByEGP[i] = bidsByEGP[j];
                    bidsByEGP[j] = temp;
                }
            }
        }

        Suave.BidId[] memory allBidIds = new Suave.BidId[](allBids.length);
        for (uint i = 0; i < bidsByEGP.length; i++) {
            allBidIds[i] = bidsByEGP[i].bidId;
        }

        return buildAndEmit(blockArgs, blockHeight, allBidIds, "");
    }

    function buildAndEmit(
        Suave.BuildBlockArgs memory blockArgs,
        uint64 blockHeight,
        Suave.BidId[] memory bids,
        string memory namespace
    ) public virtual returns (bytes memory) {
        require(Suave.isConfidential());

        (Suave.Bid memory blockBid, bytes memory builderBid) = this.doBuild(
            blockArgs,
            blockHeight,
            bids,
            namespace
        );

        emit BuilderBoostBidEvent(blockBid.id, builderBid);
        emit BidEvent(
            blockBid.id,
            blockBid.decryptionCondition,
            blockBid.allowedPeekers
        );
        return
            bytes.concat(
                this.emitBuilderBidAndBid.selector,
                abi.encode(blockBid, builderBid)
            );
    }

    function doBuild(
        Suave.BuildBlockArgs memory blockArgs,
        uint64 blockHeight,
        Suave.BidId[] memory bids,
        string memory namespace
    ) public view returns (Suave.Bid memory, bytes memory) {
        address[] memory allowedPeekers = new address[](2);
        allowedPeekers[0] = address(this);
        allowedPeekers[1] = Suave.BUILD_ETH_BLOCK;

        Suave.Bid memory blockBid = Suave.newBid(
            blockHeight,
            allowedPeekers,
            allowedPeekers,
            "default:v0:mergedBids"
        );
        Suave.confidentialStore(
            blockBid.id,
            "default:v0:mergedBids",
            abi.encode(bids)
        );

        (bytes memory builderBid, bytes memory payload) = Suave.buildEthBlock(
            blockArgs,
            blockBid.id,
            namespace
        );
        Suave.confidentialStore(
            blockBid.id,
            "default:v0:builderPayload",
            payload
        ); // only through this.unlock

        return (blockBid, builderBid);
    }

    function emitBuilderBidAndBid(
        Suave.Bid memory bid,
        bytes memory builderBid
    ) public returns (Suave.Bid memory, bytes memory) {
        emit BuilderBoostBidEvent(bid.id, builderBid);
        emit BidEvent(bid.id, bid.decryptionCondition, bid.allowedPeekers);
        return (bid, builderBid);
    }

    function unlock(
        Suave.BidId bidId,
        bytes memory signedBlindedHeader
    ) public view returns (bytes memory) {
        require(Suave.isConfidential());

        // TODO: verify the header is correct
        // TODO: incorporate protocol name
        bytes memory payload = Suave.confidentialRetrieve(
            bidId,
            "default:v0:builderPayload"
        );
        return payload;
    }
}
