from freqtrade.strategy.interface import IStrategy
from freqtrade.persistence import Trade
from pandas import DataFrame
import talib.abstract as ta


class SmaRsiATRStrategy(IStrategy):
    timeframe = "1h"

    # ROI curve: earlier take more, later accept less
    minimal_roi = {"0": 0.03, "60": 0.02, "240": 0.01}

    stoploss = -0.03
    trailing_stop = False

    startup_candle_count = 50

    def populate_indicators(self, dataframe: DataFrame,
                            metadata: dict) -> DataFrame:
        dataframe["sma_fast"] = ta.SMA(dataframe, timeperiod=20)
        dataframe["sma_slow"] = ta.SMA(dataframe, timeperiod=50)
        dataframe["rsi"] = ta.RSI(dataframe, timeperiod=14)

        # simple ATR based volatility filter
        atr = ta.ATR(
            dataframe["high"],
            dataframe["low"],
            dataframe["close"],
            timeperiod=14,
        )
        dataframe["atr_pct"] = atr / dataframe["close"]

        return dataframe

    def populate_buy_trend(self, dataframe: DataFrame,
                           metadata: dict) -> DataFrame:
        dataframe.loc[:, "buy"] = 0

        cond = ((dataframe["sma_fast"] > dataframe["sma_slow"]) &
                (dataframe["sma_fast"].shift(1)
                 <= dataframe["sma_slow"].shift(1)) &  # fresh cross
                (dataframe["rsi"] < 60) &  # do not buy when already overheated
                (dataframe["atr_pct"] > 0.01
                 )  # only when volatility at least ~1 percent
                )

        dataframe.loc[cond, "buy"] = 1
        return dataframe

    def populate_sell_trend(self, dataframe: DataFrame,
                            metadata: dict) -> DataFrame:
        dataframe.loc[:, "sell"] = 0

        cond = ((dataframe["sma_fast"] < dataframe["sma_slow"]) |
                (dataframe["rsi"] > 70))

        dataframe.loc[cond, "sell"] = 1
        return dataframe
