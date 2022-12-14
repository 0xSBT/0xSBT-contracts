// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.1;

import "./TickMath.sol";
import "../interfaces/IConcentratedLiquidityPool.sol";

/// @notice Tick management library for ranged liquidity.
library Ticks {
    function getMaxLiquidity(uint24 _tickSpacing) internal pure returns (uint128) {
        return type(uint128).max / uint128(uint24(TickMath.MAX_TICK) / (2 * uint24(_tickSpacing)));
    }

    function cross(
        mapping(int24 => IConcentratedLiquidityPoolStruct.Tick) storage ticks,
        int24 nextTickToCross,
        uint160 secondsGrowthGlobal,
        uint256 currentLiquidity,
        uint256 feeGrowthGlobalA,
        uint256 feeGrowthGlobalB,
        bool zeroForOne,
        uint24 tickSpacing
    ) internal returns (uint256, int24) {
        ticks[nextTickToCross].secondsGrowthOutside = secondsGrowthGlobal - ticks[nextTickToCross].secondsGrowthOutside;

        if (zeroForOne) {
            // Moving backwards through the linked list.
            // Liquidity cannot overflow due to the MAX_TICK_LIQUIDITY requirement.
            unchecked {
                if ((nextTickToCross / int24(tickSpacing)) % 2 == 0) {
                    currentLiquidity -= ticks[nextTickToCross].liquidity;
                } else {
                    currentLiquidity += ticks[nextTickToCross].liquidity;
                }
            }
            ticks[nextTickToCross].feeGrowthOutside0 = feeGrowthGlobalB - ticks[nextTickToCross].feeGrowthOutside0;
            ticks[nextTickToCross].feeGrowthOutside1 = feeGrowthGlobalA - ticks[nextTickToCross].feeGrowthOutside1;
            nextTickToCross = ticks[nextTickToCross].previousTick;
        } else {
            // Moving forwards through the linked list.
            unchecked {
                if ((nextTickToCross / int24(tickSpacing)) % 2 == 0) {
                    currentLiquidity += ticks[nextTickToCross].liquidity;
                } else {
                    currentLiquidity -= ticks[nextTickToCross].liquidity;
                }
            }
            ticks[nextTickToCross].feeGrowthOutside1 = feeGrowthGlobalB - ticks[nextTickToCross].feeGrowthOutside1;
            ticks[nextTickToCross].feeGrowthOutside0 = feeGrowthGlobalA - ticks[nextTickToCross].feeGrowthOutside0;
            nextTickToCross = ticks[nextTickToCross].nextTick;
        }
        return (currentLiquidity, nextTickToCross);
    }

    function insert(
        mapping(int24 => IConcentratedLiquidityPoolStruct.Tick) storage ticks,
        uint256 feeGrowthGlobal0,
        uint256 feeGrowthGlobal1,
        uint160 secondsGrowthGlobal,
        int24 lowerOld,
        int24 lower,
        int24 upperOld,
        int24 upper,
        uint128 amount,
        int24 nearestTick,
        uint160 currentPrice
    ) public returns (int24, uint256 numOfInserted) {
        require(lower < upper, "WRONG_ORDER");
        require(TickMath.MIN_TICK <= lower, "LOWER_RANGE");
        require(upper <= TickMath.MAX_TICK, "UPPER_RANGE");

        {
            // Stack overflow.
            uint128 currentLowerLiquidity = ticks[lower].liquidity;
            if (currentLowerLiquidity != 0 || lower == TickMath.MIN_TICK) {
                // We are adding liquidity to an existing tick.
                ticks[lower].liquidity = currentLowerLiquidity + amount;
            } else {
                // We are inserting a new tick.
                int24 oldNextTick;
                {
                    IConcentratedLiquidityPoolStruct.Tick storage old = ticks[lowerOld];
                    oldNextTick = old.nextTick;
                    old.nextTick = lower;
                    require(
                        (old.liquidity != 0 || lowerOld == TickMath.MIN_TICK) && lowerOld < lower && lower < oldNextTick,
                        "LOWER_ORDER"
                    );
                }

                if (lower <= TickMath.getTickAtSqrtRatio(currentPrice)) {
                    ticks[lower] = IConcentratedLiquidityPoolStruct.Tick(
                        lowerOld,
                        oldNextTick,
                        amount,
                        feeGrowthGlobal0,
                        feeGrowthGlobal1,
                        secondsGrowthGlobal
                    );
                } else {
                    ticks[lower] = IConcentratedLiquidityPoolStruct.Tick(lowerOld, oldNextTick, amount, 0, 0, 0);
                }

                ticks[oldNextTick].previousTick = lower;
                numOfInserted += 1;
            }
        }

        uint128 currentUpperLiquidity = ticks[upper].liquidity;
        if (currentUpperLiquidity != 0 || upper == TickMath.MAX_TICK) {
            // We are adding liquidity to an existing tick.
            ticks[upper].liquidity = currentUpperLiquidity + amount;
        } else {
            // Inserting a new tick.
            int24 oldNextTick;
            {
                IConcentratedLiquidityPoolStruct.Tick storage old = ticks[upperOld];
                oldNextTick = old.nextTick;
                old.nextTick = upper;
                require(old.liquidity != 0 && oldNextTick > upper && upperOld < upper, "UPPER_ORDER");
            }

            if (upper <= TickMath.getTickAtSqrtRatio(currentPrice)) {
                ticks[upper] = IConcentratedLiquidityPoolStruct.Tick(
                    upperOld,
                    oldNextTick,
                    amount,
                    feeGrowthGlobal0,
                    feeGrowthGlobal1,
                    secondsGrowthGlobal
                );
            } else {
                ticks[upper] = IConcentratedLiquidityPoolStruct.Tick(upperOld, oldNextTick, amount, 0, 0, 0);
            }

            ticks[oldNextTick].previousTick = upper;
            numOfInserted += 1;
        }

        int24 tickAtPrice = TickMath.getTickAtSqrtRatio(currentPrice);

        if (nearestTick < upper && upper <= tickAtPrice) {
            nearestTick = upper;
        } else if (nearestTick < lower && lower <= tickAtPrice) {
            nearestTick = lower;
        }

        return (nearestTick, numOfInserted);
    }

    function remove(
        mapping(int24 => IConcentratedLiquidityPoolStruct.Tick) storage ticks,
        int24 lower,
        int24 upper,
        uint128 amount,
        int24 nearestTick
    ) public returns (int24, uint256 numOfRemoved) {
        IConcentratedLiquidityPoolStruct.Tick storage current = ticks[lower];

        if (lower != TickMath.MIN_TICK && current.liquidity == amount) {
            // Delete lower tick.
            IConcentratedLiquidityPoolStruct.Tick storage previous = ticks[current.previousTick];
            IConcentratedLiquidityPoolStruct.Tick storage next = ticks[current.nextTick];

            previous.nextTick = current.nextTick;
            next.previousTick = current.previousTick;

            if (nearestTick == lower) nearestTick = current.previousTick;

            delete ticks[lower];
            numOfRemoved += 1;
        } else {
            unchecked {
                current.liquidity -= amount;
            }
        }

        current = ticks[upper];

        if (upper != TickMath.MAX_TICK && current.liquidity == amount) {
            // Delete upper tick.
            IConcentratedLiquidityPoolStruct.Tick storage previous = ticks[current.previousTick];
            IConcentratedLiquidityPoolStruct.Tick storage next = ticks[current.nextTick];

            previous.nextTick = current.nextTick;
            next.previousTick = current.previousTick;

            if (nearestTick == upper) nearestTick = current.previousTick;

            delete ticks[upper];
            numOfRemoved += 1;
        } else {
            unchecked {
                current.liquidity -= amount;
            }
        }

        return (nearestTick, numOfRemoved);
    }
}