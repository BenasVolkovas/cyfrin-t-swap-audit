# High

# Medium

# Low

# Informational

### [I-1] `PoolFactory::constructor` paramerter `wethToken` is not checked, so `i_wethToken` can be set to zero address

**Description:** In `PoolFactory::constructor`, the `wethToken` parameter is used to assign value to `i_wethToken`, but the parameter is not checked to ensure it is not the zero address. This means that `i_wethToken` can be set to the zero address, which can cause a `PoolFactory::createPool` call to fail.

**Recommended Mitigation:** Add a check to ensure that `wethToken` is not the zero address. Use modifier for reusability.

Modifier example:

```javascript
    modifier notZeroAddress(address _address) {
        if (_address == address(0)) {
            revert PoolFactory__ZeroAddress();
        }
        _;
    }
```

### [I-2] `PoolFactory::createPool` paramerter `tokenAddress` is not checked for zero address, which will revert when calling `ERC20::name`

**Description:** In `PoolFactory::createPool`, the `tokenAddress` parameter is used to create pool. The parameter is not checked to ensure it is not the zero address. This means that `tokenAddress` can be set to the zero address, which will cause a revert when calling `ERC20::name`.

**Recommended Mitigation:** Add a check to ensure that `tokenAddress` is not the zero address. Use modifier for reusability.

Modifier example:

```javascript
    modifier notZeroAddress(address _address) {
        if (_address == address(0)) {
            revert PoolFactory__ZeroAddress();
        }
        _;
    }
```

### [I-3] `PoolFactory::PoolFactory__PoolDoesNotExist` error is defined but not used anywhere

**Description:** In `PoolFactory`, the `PoolFactory__PoolDoesNotExist` error is defined but not used anywhere.

**Recommended Mitigation:** Remove the error definition to save contract deployment gas.

### [I-4] `PoolFactory::createPool` uses pool token name for LP token symbol

**Description:** In `PoolFactory::createPool`, the pool token name is used to concatenate with preffix `ts` to create LP token symbol. This means that the LP token symbol will be almost the same as the pool token name, which can cause confusion. Also names might have spaces, which might also be confusing.

**Recommended Mitigation:** Use pool token symbol instead of name to create LP token symbol to avoid confusion.

# Gas Optimization
