==================================================
Simple MA Crossover Bot for MetaTrader 5 (MQL5)
==================================================

Bot Name: SimpleMACrossoverBot
Strategy: Moving Average Crossover

This Expert Advisor (EA) implements a classic Simple Moving Average (SMA) crossover strategy. It opens a buy trade when a faster SMA crosses above a slower SMA and a sell trade when the faster SMA crosses below the slower SMA. It only opens one trade at a time per symbol and manages trades using a magic number. Optional Stop Loss and Take Profit levels can be set in points.

--------------------------------------------------
Recommended Symbol & Timeframe
--------------------------------------------------
*   Symbol: Any liquid Forex pair (e.g., EURUSD, GBPUSD, USDJPY). Can also be used on other instruments, but parameters might need significant adjustments.
*   Timeframe: H1 or H4 are commonly used for crossover strategies to reduce noise, but it can be tested on other timeframes. The effectiveness of MA periods is often timeframe-dependent.

--------------------------------------------------
Installation Steps
--------------------------------------------------
1.  Open MetaEditor: In MetaTrader 5, go to "Tools" -> "MetaQuotes Language Editor" or press F4.
2.  Locate EA Folder: In the MetaEditor's "Navigator" window (usually on the left), expand "MQL5" -> "Experts".
3.  Copy EA File:
    *   If you have the `SimpleMACrossoverBot.mq5` file, right-click on the "Experts" folder (or a subfolder you create under it) and choose "Open Folder".
    *   Copy the `SimpleMACrossoverBot.mq5` file into this folder.
4.  Compile EA:
    *   Back in MetaEditor, right-click on the "Experts" folder (or the subfolder where you placed the file) in the Navigator and select "Refresh".
    *   Find `SimpleMACrossoverBot` in the list, double-click it to open the source code.
    *   Click "Compile" (the button that looks like stacked bricks, or press F7).
    *   Check the "Errors" tab at the bottom of MetaEditor for any compilation errors. There should be 0 errors if the code is correct.

--------------------------------------------------
How to Attach to Chart and Enable Algo Trading
--------------------------------------------------
1.  Open Chart: In MetaTrader 5, open the chart for the symbol and timeframe you want to trade (e.g., EURUSD, H1).
2.  Attach EA:
    *   In the "Navigator" window of MetaTrader 5 (not MetaEditor), find `SimpleMACrossoverBot` under "Experts Advisors".
    *   Drag and drop it onto the chart.
3.  Configure Inputs:
    *   The EA's input parameter window will appear.
    *   Go to the "Inputs" tab.
    *   Adjust the parameters as needed (see "Explanation of Input Parameters" below).
    *   Go to the "Common" tab.
    *   Ensure "Allow Algo Trading" is checked.
    *   Click "OK".
4.  Enable Algo Trading Globally:
    *   Ensure the main "Algo Trading" button in the MetaTrader 5 toolbar is enabled (green). If it's red, click it to enable.
    *   You should see a smiley face icon on the top right of the chart if the EA is active and running. A sad face means it's not running (usually "Algo Trading" is not allowed in its properties or globally).

--------------------------------------------------
Explanation of Input Parameters
--------------------------------------------------
*   `FastMAPeriod` (Default: 50)
    *   The period (number of bars) for the faster Simple Moving Average.
*   `SlowMAPeriod` (Default: 200)
    *   The period (number of bars) for the slower Simple Moving Average.
*   `LotSize` (Default: 0.01)
    *   The fixed lot size for each trade.
*   `MagicNumber` (Default: 12345)
    *   A unique number that the EA uses to identify and manage its own trades. This is important if you run multiple EAs on the same account.
*   `StopLossPoints` (Default: 150)
    *   Stop loss in points (not pips). For a 5-digit broker, 150 points = 15 pips.
    *   Set to 0 to disable the Stop Loss.
*   `TakeProfitPoints` (Default: 300)
    *   Take profit in points (not pips). For a 5-digit broker, 300 points = 30 pips.
    *   Set to 0 to disable the Take Profit.

--------------------------------------------------
Basic Risk Management Notes
--------------------------------------------------
*   Fixed Lot Size: This EA uses a fixed `LotSize` for every trade. This means the risk per trade will vary depending on the Stop Loss distance and the value of the instrument.
*   SL/TP in Points: Stop Loss and Take Profit are defined in points. Understand the difference between points and pips for your broker and symbol.
*   No Dynamic Sizing: The EA does not adjust lot size based on account balance or risk percentage. This is a manual risk management approach.
*   One Trade at a Time: The EA will only open a new trade if there isn't already an open trade for the same symbol managed by its Magic Number.

--------------------------------------------------
Important Disclaimers
--------------------------------------------------
*   Past Performance: Past performance of this EA in backtesting or live trading is not indicative of future results. Market conditions change.
*   Demo Testing Recommended: ALWAYS test this EA thoroughly on a demo account before using it on a live account.
*   Parameter Optimization: The default parameters are examples and may not be optimal for all symbols or timeframes. Optimization and testing are required.
*   No Guarantees: This EA is provided as an educational example of a trading strategy. There are no guarantees of profit. Trading Forex and CFDs involves significant risk of loss.
*   Use at Your Own Risk: You are solely responsible for any decisions made based on the use of this EA.

--------------------------------------------------
Basic Troubleshooting
--------------------------------------------------
*   Check Experts Tab: In MetaTrader 5's "Terminal" window (Ctrl+T), the "Experts" tab logs EA operations, including initialization, signals, trade attempts, and errors. This is the first place to look if something isn't working.
*   Check Journal Tab: The "Journal" tab in the "Terminal" provides more general platform messages, which might also include information relevant to EA operation or connection issues.
*   Smiley Face: Ensure the EA has a smiley face icon on the chart. If it's a sad face, check that "Allow Algo Trading" is enabled in the EA's properties and globally in MT5.
*   Compilation Errors: Ensure there were no errors when compiling the EA in MetaEditor.
*   Sufficient Funds: Ensure your account has sufficient margin for the specified `LotSize`.
*   Correct Symbol/Timeframe: Ensure the EA is attached to the intended chart.

==================================================
Use with caution and at your own risk.
==================================================
