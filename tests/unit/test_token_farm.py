from brownie import exceptions, network, config
from scripts.helpful_scripts import (
    LOCAL_BLOCKCHAIN_ENVIRONMENTS,
    INITIAL_PRICE_FEED_VALUE,
    DECIMALS,
    get_account,
    get_contract
    )
import pytest
from scripts.deploy import KEPT_BALANCE, deploy_token_farm_and_dapp_token
#shoudl start by writing teh test for the token...

def test_set_price_feed_contract():
    #Arrange
    if network.show_active() not in LOCAL_BLOCKCHAIN_ENVIRONMENTS:
        pytest.skip("Only for local testing")
    account = get_account()
    non_owner = get_account(index=1)
    token_farm, dapp_token = deploy_token_farm_and_dapp_token()
    #what is a conftest or a wrapper...

    # Act
    price_feed_address = get_contract("eth_usd_price_feed")
    token_farm.setPriceFeedContract(dapp_token.address, price_feed_address,
    {
        'from':account
    })
        # We don't have to call setPriceFeedContract() again, because it's already called
    # for all tokens in dict_of_allowed_tokens when we call deploy_token_farm_and_dapp_token()
    #
    # token_farm.setPriceFeedContract(
    #     dapp_token.address, price_feed_address, {"from": account}
    # )
    # Assert
    assert token_farm.tokenPriceFeedMapping(dapp_token.address) == price_feed_address
    with pytest.raises(exceptions.VirtualMachineError):
        token_farm.setPriceFeedContract(
            dapp_token.address, price_feed_address, {"from": non_owner}
        )
def test_stake_tokens(amount_staked):
    #Arrange
    if network.show_active() not in LOCAL_BLOCKCHAIN_ENVIRONMENTS:
        pytest.skip("Only for local networks")
    account = get_account()
    token_farm, dapp_token = deploy_token_farm_and_dapp_token()
    dapp_token.approve(token_farm.address, amount_staked, {"from": account})
    token_farm.stakeTokens(amount_staked, dapp_token.address,
    {
        'from':account
    })
    # Assert
    assert (
        token_farm.stakingBalance(dapp_token.address, account.address) == amount_staked
    )
    assert token_farm.uniqueTokensStaked(account.address) == 1
    assert token_farm.stakers(0) == account.address
    return token_farm, dapp_token

    #99000000000000000000
    #99000000000000000000
    #2000000000000000000000
def price_dapptoken():
    if network.show_active() not in LOCAL_BLOCKCHAIN_ENVIRONMENTS:
        pytest.skip("Only local blockchain-test")
    account = get_account()
    token_farm, dapp_token = deploy_token_farm_and_dapp_token()
    k = token_farm.getTokenValue(dapp_token.address(),
    {
        'from':account
    })
    k.wait(1)
    assert (0==0)

def test_issue_tokens(amount_staked):
    if network.show_active() not in LOCAL_BLOCKCHAIN_ENVIRONMENTS:
        pytest.skip("Only for local networks")
    account = get_account()
    token_farm, dapp_token = test_stake_tokens(amount_staked)
    starting_balance = dapp_token.balanceOf(account.address)
    # Act
    tx = token_farm.issuetokens(
        {
            'from':account
        }
    )
    tx.wait(1)
    # Arrange
    # we are staking 1 dapp_token == in price to 1 ETH
    # soo... we should get 2,000 dapp tokens in reward
    # since the price of eth is $2,000
    assert (
        dapp_token.balanceOf(account.address)
        == starting_balance + INITIAL_PRICE_FEED_VALUE
    )