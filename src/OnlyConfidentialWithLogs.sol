// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

// Note: Need to update this to just Suave.sol if
// deploying to Suave Rigil Testnet (and remove SuaveForge.sol)

// import "suave/Suave.sol";
import "suave/SuaveForge.sol";

contract OnlyConfidentialWithLogs {
    event SimResultEvent(uint64 egp);

    function fetchBidConfidentialBundleData()
        public
        view
        returns (bytes memory)
    {
        // Ensure that only the MEVM(s) specified by user can fetch data in txs to this contract
        require(Suave.isConfidential());

        // Fetch data that was submitted with tx that user sent which is
        // specified in this contract
        bytes memory confidentialInputs = Suave.confidentialInputs();
        return abi.decode(confidentialInputs, (bytes));
    }

    function emitSimResultEvent(uint64 egp) public {
        emit SimResultEvent(egp);
    }

    function helloWorld() external view returns (bytes memory) {
        require(Suave.isConfidential());

        bytes memory bundleData = this.fetchBidConfidentialBundleData();

        uint64 effectiveGasPrice = Suave.simulateBundle(bundleData);

        // This enables computation result to be emitted on chain
        return
            bytes.concat(
                this.emitSimResultEvent.selector,
                abi.encode(effectiveGasPrice)
            );
    }
}
