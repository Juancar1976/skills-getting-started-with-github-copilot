//+------------------------------------------------------------------+
//|                                         SimpleMACrossoverBot.mq5 |
//|                        Copyright 2023, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2023, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property version   "1.00"

#include <Trade\Trade.mqh>

//--- Input parameters
input int FastMAPeriod = 50;
input int SlowMAPeriod = 200;
input double LotSize = 0.01;
input int MagicNumber = 12345;
//--- Stop Loss and Take Profit Inputs
input int StopLossPoints = 150;  // Stop loss in points; 0 to disable
input int TakeProfitPoints = 300; // Take profit in points; 0 to disable

//--- Global variables
CTrade trade;
int FastMA_handle;
int SlowMA_handle;
// Helper arrays for CopyBuffer - declared globally for efficiency
double arr_fastMA[2]; // Array to hold 2 values from Fast MA
double arr_slowMA[2]; // Array to hold 2 values from Slow MA

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//--- Initialize CTrade object
   trade.SetExpertMagicNumber(MagicNumber);
   trade.SetTypeFillingBySymbol(Symbol()); // Important for some brokers
   trade.SetDeviationInPoints(10); // Example slippage of 10 points

//--- Initialize Fast MA indicator
   FastMA_handle = iMA(Symbol(), Period(), FastMAPeriod, 0, MODE_SMA, PRICE_CLOSE);
   if(FastMA_handle == INVALID_HANDLE)
     {
      Print("Error initializing Fast MA indicator: ", GetLastError());
      return(INIT_FAILED);
     }

//--- Initialize Slow MA indicator
   SlowMA_handle = iMA(Symbol(), Period(), SlowMAPeriod, 0, MODE_SMA, PRICE_CLOSE);
   if(SlowMA_handle == INVALID_HANDLE)
     {
      Print("Error initializing Slow MA indicator: ", GetLastError());
      // Release previously acquired handle if necessary
      if(FastMA_handle != INVALID_HANDLE)
         IndicatorRelease(FastMA_handle);
      return(INIT_FAILED);
     }

   Print("SimpleMACrossoverBot initialized successfully.");
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
//--- Release indicator handles
   if(FastMA_handle != INVALID_HANDLE)
      IndicatorRelease(FastMA_handle);
   if(SlowMA_handle != INVALID_HANDLE)
      IndicatorRelease(SlowMA_handle);

   Print("SimpleMACrossoverBot deinitialized. Reason: ", reason);
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
// Main function called on every new tick or bar. Handles new bar detection,
// MA calculation, signal generation, and trade execution.
void OnTick()
  {
//--- New bar check
   static datetime prevBarTime = 0;
   datetime currentBarTime = (datetime)SeriesInfoInteger(Symbol(), Period(), SERIES_LASTBAR_DATE);

   // Optimization: If running in visual tester, prevBarTime might not be initialized correctly on the very first tick.
   if(MQLInfoInteger(MQL_TESTER) && prevBarTime == 0)
     {
      // Attempt to initialize prevBarTime reasonably for the first tick in tester
      // This helps avoid skipping the very first potential signal in some backtest modes.
      datetime historyReadyAfter = SeriesInfoInteger(Symbol(), Period(), SERIES_FIRSTDATE);
      if (currentBarTime > historyReadyAfter) // Ensure some history is available
        {
            prevBarTime = currentBarTime - PeriodSeconds(Period());
        }
       else
        {
            prevBarTime = currentBarTime; // Fallback if very little history
        }
     }

   if(currentBarTime == prevBarTime && !MQLInfoInteger(MQL_TESTER_EVERYTICK_EVENT)) // Allow every tick processing if that specific mode is on
     {
      return; // Not a new bar yet (unless every tick mode is active)
     }
   prevBarTime = currentBarTime;

//--- MA Value Retrieval
   // Ensure indicator handles are valid before trying to copy data
   if(FastMA_handle == INVALID_HANDLE || SlowMA_handle == INVALID_HANDLE)
     {
      Print("MA Handles are not valid. FastMA: ", FastMA_handle, ", SlowMA: ", SlowMA_handle, ". Check OnInit.");
      return;
     }

   double fastMA_curr, fastMA_prev;
   double slowMA_curr, slowMA_prev;

   // Get MA values for the last two *completed* bars.
   // For indicators, data is typically available as series (as_series=true by default).
   // Index 0 = current forming bar (bar 0)
   // Index 1 = most recently completed bar (bar 1)
   // Index 2 = the bar before that (bar 2)
   // We need values for bar 1 (arr[0] after copy) and bar 2 (arr[1] after copy)
   // So we copy 2 elements starting from shift 1.
   if(CopyBuffer(FastMA_handle, 0, 1, 2, arr_fastMA) < 2)
     {
      Print("Error copying Fast MA buffer (", GetLastError(), "), not enough data? BarsCalculated(FastMA_handle): ", BarsCalculated(FastMA_handle), ", SeriesUpdated(Symbol,Period):", SeriesUpdated(Symbol(),Period()));
      return;
     }
   fastMA_curr = arr_fastMA[0]; // Value of Fast MA on Bar 1
   fastMA_prev = arr_fastMA[1]; // Value of Fast MA on Bar 2

   if(CopyBuffer(SlowMA_handle, 0, 1, 2, arr_slowMA) < 2)
     {
      Print("Error copying Slow MA buffer (", GetLastError(), "), not enough data? BarsCalculated(SlowMA_handle): ", BarsCalculated(SlowMA_handle));
      return;
     }
   slowMA_curr = arr_slowMA[0]; // Value of Slow MA on Bar 1
   slowMA_prev = arr_slowMA[1]; // Value of Slow MA on Bar 2

//--- Position Check: Check if a position for this EA's magic number and symbol is already open
   bool positionOpen = false;
   for(int i = PositionsTotal() - 1; i >= 0; i--)
     {
      if(PositionGetTicket(i)) // Selects the position at index i, returns true if successful
        {
         if(PositionGetInteger(POSITION_MAGIC) == MagicNumber && PositionGetString(POSITION_SYMBOL) == Symbol())
           {
            positionOpen = true;
            // Print("Active position found for magic number ", MagicNumber, " on symbol ", Symbol(), ". Ticket: ", PositionGetInteger(POSITION_TICKET));
            break;
           }
        }
      else
        {
         Print("Error getting position ticket at index ", i, ": ", GetLastError());
         // It might be prudent to return here or handle this error more robustly,
         // as failure to check positions could lead to multiple trades.
        }
     }

//--- Trading Logic (only if no position is open for this EA on the current symbol)
   if(!positionOpen)
     {
      // Print("No open position for this EA on ", Symbol(), ". Checking for signals..."); // For debugging
      // Buy Signal: Fast MA crossed above Slow MA
      // On bar 2 (prev): Fast SMA was below Slow SMA
      // On bar 1 (curr): Fast SMA is now above Slow SMA
      if(fastMA_prev < slowMA_prev && fastMA_curr > slowMA_curr)
        {
         double current_ask_price = SymbolInfoDouble(Symbol(), SYMBOL_ASK);
         double point_value = SymbolInfoDouble(Symbol(), SYMBOL_POINT);
         double sl_price = 0.0;
         double tp_price = 0.0;

         if(StopLossPoints > 0)
           {
            sl_price = current_ask_price - (StopLossPoints * point_value);
            // Normalize SL price to the correct number of digits
            sl_price = NormalizeDouble(sl_price, (int)SymbolInfoInteger(Symbol(), SYMBOL_DIGITS));
           }
         if(TakeProfitPoints > 0)
           {
            tp_price = current_ask_price + (TakeProfitPoints * point_value);
            // Normalize TP price to the correct number of digits
            tp_price = NormalizeDouble(tp_price, (int)SymbolInfoInteger(Symbol(), SYMBOL_DIGITS));
           }

         Print("BUY SIGNAL DETECTED on ", Symbol(), ": Fast MA (", fastMA_curr, ") crossed above Slow MA (", slowMA_curr, "). Prev FastMA: ", fastMA_prev, ", Prev SlowMA: ", slowMA_prev);
         Print("Attempting BUY: Lot=", LotSize, ", Ask=", current_ask_price, ", SL=", (StopLossPoints > 0 ? DoubleToString(sl_price, (int)SymbolInfoInteger(Symbol(), SYMBOL_DIGITS)) : "None"), ", TP=", (TakeProfitPoints > 0 ? DoubleToString(tp_price, (int)SymbolInfoInteger(Symbol(), SYMBOL_DIGITS)) : "None"));

         if(trade.Buy(LotSize, Symbol(), current_ask_price, sl_price, tp_price, "SimpleMACrossoverBot Buy"))
           {
            Print("Buy order placed successfully. Ticket: ", trade.ResultDeal(), ", Price: ", trade.ResultPrice(), ", SL: ", trade.ResultSL(), ", TP: ", trade.ResultTP(), ", Retcode: ", trade.ResultRetcode());
           }
         else
           {
            Print("Error placing buy order on ", Symbol(), ": Retcode=", trade.ResultRetcode(), " (", trade.ResultRetcodeDescription(), "), Comment=", trade.ResultComment(), ", Deal=", trade.ResultDeal(), ", Order=", trade.ResultOrder());
            Print("Order SL: ", sl_price, " TP: ", tp_price); // Log intended SL/TP for debugging
           }
        }
      // Sell Signal: Fast MA crossed below Slow MA
      // On bar 2 (prev): Fast SMA was above Slow SMA
      // On bar 1 (curr): Fast SMA is now below Slow SMA
      else if(fastMA_prev > slowMA_prev && fastMA_curr < slowMA_curr)
        {
         double current_bid_price = SymbolInfoDouble(Symbol(), SYMBOL_BID);
         double point_value = SymbolInfoDouble(Symbol(), SYMBOL_POINT);
         double sl_price = 0.0;
         double tp_price = 0.0;

         if(StopLossPoints > 0)
           {
            sl_price = current_bid_price + (StopLossPoints * point_value);
            sl_price = NormalizeDouble(sl_price, (int)SymbolInfoInteger(Symbol(), SYMBOL_DIGITS));
           }
         if(TakeProfitPoints > 0)
           {
            tp_price = current_bid_price - (TakeProfitPoints * point_value);
            tp_price = NormalizeDouble(tp_price, (int)SymbolInfoInteger(Symbol(), SYMBOL_DIGITS));
           }

         Print("SELL SIGNAL DETECTED on ", Symbol(), ": Fast MA (", fastMA_curr, ") crossed below Slow MA (", slowMA_curr, "). Prev FastMA: ", fastMA_prev, ", Prev SlowMA: ", slowMA_prev);
         Print("Attempting SELL: Lot=", LotSize, ", Bid=", current_bid_price, ", SL=", (StopLossPoints > 0 ? DoubleToString(sl_price, (int)SymbolInfoInteger(Symbol(), SYMBOL_DIGITS)) : "None"), ", TP=", (TakeProfitPoints > 0 ? DoubleToString(tp_price, (int)SymbolInfoInteger(Symbol(), SYMBOL_DIGITS)) : "None"));

         if(trade.Sell(LotSize, Symbol(), current_bid_price, sl_price, tp_price, "SimpleMACrossoverBot Sell"))
           {
            Print("Sell order placed successfully. Ticket: ", trade.ResultDeal(), ", Price: ", trade.ResultPrice(), ", SL: ", trade.ResultSL(), ", TP: ", trade.ResultTP(), ", Retcode: ", trade.ResultRetcode());
           }
         else
           {
            Print("Error placing sell order on ", Symbol(), ": Retcode=", trade.ResultRetcode(), " (", trade.ResultRetcodeDescription(), "), Comment=", trade.ResultComment(), ", Deal=", trade.ResultDeal(), ", Order=", trade.ResultOrder());
            Print("Order SL: ", sl_price, " TP: ", tp_price); // Log intended SL/TP for debugging
           }
        }
     }
  }
//+------------------------------------------------------------------+
