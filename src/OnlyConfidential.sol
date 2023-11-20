// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

// Note: Need to update this to just Suave.sol if
// deploying to Suave Rigil Testnet (and remove SuaveForge.sol)

// import "suave/Suave.sol";
import "suave/SuaveForge.sol";

contract OnlyConfidential {
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

    // Note: Because of confidential execution, you will not see input as input
    // to the function lol
    function helloWorld() external {
        require(Suave.isConfidential());

        bytes memory bundleData = this.fetchBidConfidentialBundleData();

        // As the contract creator, we may want the MEVM allowed to see confidential data once it is fetched
        uint64 effectiveGasPrice = Suave.simulateBundle(bundleData);

        emit SimResultEvent(effectiveGasPrice);

        // Note: This function does not return anything so the computation result
        // will neve land on chain
    }
}
