pragma solidity ^0.4.23;

import "./HardCappedInvestmentPool.sol";
import "./SoftCappedInvestmentPool.sol";
import "./RefundableInvestmentPool.sol";
import "./BatchTransferableInvestmentPool.sol";
//#if D_WHITELIST
import "./WhitelistedInvestmentPool.sol";
//#endif
//#if defined(D_MIN_VALUE_WEI) && D_MIN_VALUE_WEI > 0
import "./MinRestrictedInvestmentPool.sol";
//#endif
//#if defined(D_MAX_VALUE_WEI) && D_MAX_VALUE_WEI > 0
import "./MaxRestrictedInvestmentPool.sol";
//#endif
//#if D_CAN_CHANGE_TIMES
import "./ChangeableTimedInvestmentPool.sol";
//#endif
//#if D_AUTO_TRANSFER
import "./BatchTransferableInvestmentPool.sol";
//#endif

/**
 * @title InvestmentPool
 */
contract InvestmentPool is // solium-disable-line lbrace
    SoftCappedInvestmentPool
  , HardCappedInvestmentPool
  , CancellableInvestmentPool
  , RefundableInvestmentPool
  , BatchTransferableInvestmentPool
  //#if D_WHITELIST
  , WhitelistedInvestmentPool
  //#endif
  //#if defined(D_MIN_VALUE_WEI) && D_MIN_VALUE_WEI > 0
  , MinRestrictedInvestmentPool
  //#endif
  //#if defined(D_MAX_VALUE_WEI) && D_MAX_VALUE_WEI > 0
  , MaxRestrictedInvestmentPool
  //#endif
  //#if D_CAN_CHANGE_TIMES
  , ChangeableTimedInvestmentPool
  //#endif
  //#if D_AUTO_TRANSFER
  , BatchTransferableInvestmentPool
  //#endif
{
  /**
   * @param _owner              who will own the contract.
   * @param _investmentAddress  all funds will be sent to this address when soft cap will be reached.
   * @param _tokenAddress       the address of the contract token whose token we want to receive.
   */
  constructor(
    address _owner,
    address _investmentAddress,
    address _tokenAddress,
    address _serviceAccount
  )
    public
    BaseInvestmentPool(_owner, _investmentAddress, _tokenAddress, D_REWARD_PERMILLE)
    RefundableInvestmentPool(_serviceAccount)
    SoftCappedInvestmentPool(D_SOFT_CAP_WEI)
    HardCappedInvestmentPool(D_HARD_CAP_WEI)
    TimedInvestmentPool(D_START_TIME, D_END_TIME)
    //#if defined(D_MIN_VALUE_WEI) && D_MIN_VALUE_WEI > 0
    MinRestrictedInvestmentPool(D_MIN_VALUE_WEI)
    //#endif
    //#if defined(D_MAX_VALUE_WEI) && D_MAX_VALUE_WEI > 0
    MaxRestrictedInvestmentPool(D_MAX_VALUE_WEI)
    //#endif
  {
    require(softCap <= hardCap, "soft cap should be less than hard cap");
  }
  //#if defined(D_MIN_VALUE_WEI) && D_MIN_VALUE_WEI > 0

  /**
   * @return is hard cap reached or remains less than MIN_VALUE.
   */
  function hardCapReached() public view returns (bool) {
    return weiRaised.add(minInvestment) >= hardCap;
  }
  //#endif
  //#if D_CAN_FINALIZE_AFTER_HARD_CAP_ONLY_OWNER || D_CAN_FINALIZE_AFTER_SOFT_CAP_ONLY_OWNER

  /**
   * @notice validates transaction and contract state before sending funds to ICO.
   */
  function _preValidateFinalization() internal {
    super._preValidateFinalization();
    //#if D_CAN_FINALIZE_AFTER_HARD_CAP_ONLY_OWNER && D_CAN_FINALIZE_AFTER_SOFT_CAP_ONLY_OWNER
    if (hardCapReached()) {
      require(msg.sender == owner, "only owner can finalize after hardCap is reached");
    } else {
      require(msg.sender == owner, "only owner can finalize after softCap is reached");
    }
    //#elif D_CAN_FINALIZE_AFTER_HARD_CAP_ONLY_OWNER && !D_CAN_FINALIZE_AFTER_SOFT_CAP_ONLY_OWNER
    if (hardCapReached()) {
      require(msg.sender == owner, "only owner can finalize after hardCap is reached");
    }
    //#elif !D_CAN_FINALIZE_AFTER_HARD_CAP_ONLY_OWNER && D_CAN_FINALIZE_AFTER_SOFT_CAP_ONLY_OWNER
    if (!hardCapReached()) {
      require(msg.sender == owner, "only owner can finalize after softCap is reached");
    }
    //#endif
  }
  //#endif
}
