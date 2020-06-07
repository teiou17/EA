// MyPosition.mqh Version 131.007
#property copyright "Copyright (c) 2013, Toyolab FX"
#property link      "http://forex.toyolab.com/"

#include <stderror.mqh>
#include <stdlib.mqh>

// order type extension
#define OP_NONE -1

// structure for MyPosition
int MyPos[POSITIONS];

// magic numbers
int MAGIC_B[POSITIONS];

// SL/TP
double SLorder[POSITIONS], TPorder[POSITIONS];

// pips adjustment
double PipPoint = 0.01;

// slippage
extern double SlippagePips = 2;
int Slippage = 2;

// init MyPosition to be called in init()
void MyInitPosition(int magic)
{
   // pips adjustment
   if(Digits == 3 || Digits == 5)
   {
      Slippage = SlippagePips * 10;
      PipPoint = Point * 10;
   }
   else
   {
      Slippage = SlippagePips;
      PipPoint = Point;
   }

   // retrieve positions
   for(int i=0; i<POSITIONS; i++)
   {
      MAGIC_B[i] = magic+i;
      MyPos[i] = 0;
      SLorder[i] = 0;
      TPorder[i] = 0;
      for(int k=0; k<OrdersTotal(); k++)
      {
         if(OrderSelect(k, SELECT_BY_POS) == false) break;
         if(OrderSymbol() == Symbol() &&
            OrderMagicNumber() == MAGIC_B[i])
         {
            MyPos[i] = OrderTicket();
            break;
         }
      }
   }
}

// check MyPosition to be called in start()
void MyCheckPosition()
{
   for(int i=0; i<POSITIONS; i++)
   {
      int pos = 0;
      for(int k=0; k<OrdersTotal(); k++)
      { 
         if(OrderSelect(k, SELECT_BY_POS) == false) break;
         if(OrderTicket() == MyPos[i])
         {
            pos = MyPos[i];
            break;
         }
      }
      if(pos > 0) 
      {
         // send SL and TP orders
         if((SLorder[i] > 0 || TPorder[i] > 0) &&
             MyOrderModify(i, 0, SLorder[i], TPorder[i]))
         {
            SLorder[i] = 0;
            TPorder[i] = 0;
         }
      }
      else MyPos[i] = 0;
   }
}

// send order to open position
color ArrowColor[6] = {Blue, Red, Blue, Red, Blue, Red};
bool MyOrderSend(int pos_id, int type, double lots,
                 double price, double sl, double tp,
                 string comment="")
{
   if(MyOrderType(pos_id) != OP_NONE) return(true);
   // for no order
   price = NormalizeDouble(price, Digits);
   sl = NormalizeDouble(sl, Digits);
   tp = NormalizeDouble(tp, Digits);

   // market price
   if(type == OP_BUY) price = Ask;
   if(type == OP_SELL) price = Bid;
   
   int ret = OrderSend(Symbol(), type, lots, price,
                Slippage, 0, 0, comment,
                MAGIC_B[pos_id], 0, ArrowColor[type]);
   if(ret == -1)
   {
      int err = GetLastError();
      Print("MyOrderSend : ", err, " " ,
            ErrorDescription(err));
      return(false);
   }

   // show open position
   MyPos[pos_id] = ret;

   // send SL and TP orders
   if(sl > 0) SLorder[pos_id] = sl;
   if(tp > 0) TPorder[pos_id] = tp;
   return(true);
}

// send close order
bool MyOrderClose(int pos_id)
{
   if(MyOrderOpenLots(pos_id) == 0) return(true);
   // for open position

   int type = MyOrderType(pos_id);
   bool ret = OrderClose(MyPos[pos_id], OrderLots(),
                 OrderClosePrice(), Slippage,
                 ArrowColor[type]);
   if(!ret)
   {
      int err = GetLastError();
      Print("MyOrderClose : ", err, " ",
            ErrorDescription(err));
      return(false);
   }
   MyPos[pos_id] = 0;
   return(true);
}

// delete pending order
bool MyOrderDelete(int pos_id)
{
   int type = MyOrderType(pos_id);
   if(type == OP_NONE || type == OP_BUY ||
      type == OP_SELL) return(true);
   // for pending order
   bool ret = OrderDelete(MyPos[pos_id]);
   if(!ret)
   {
      int err = GetLastError();
      Print("MyOrderDelete : ", err, " ",
            ErrorDescription(err));
      return(false);
   }
   MyPos[pos_id] = 0;
   return(true);
}

// modify order
bool MyOrderModify(int pos_id, double price,
                   double sl, double tp)
{
   int type = MyOrderType(pos_id);
   if(type == OP_NONE) return(true);

   price = NormalizeDouble(price, Digits);
   sl = NormalizeDouble(sl, Digits);
   tp = NormalizeDouble(tp, Digits);

   if(price == 0) price = OrderOpenPrice();
   if(sl == 0) sl = OrderStopLoss();
   if(tp == 0) tp = OrderTakeProfit();
   
   if(OrderStopLoss() == sl && OrderTakeProfit() == tp)
   {
      if(type == OP_BUY || type == OP_SELL ||
         OrderOpenPrice() == price) return(true);
   }

   bool ret = OrderModify(MyPos[pos_id], price, sl, tp,
                          0, ArrowColor[type]);
   if(!ret)
   {
      int err = GetLastError();
      Print("MyOrderModify : ", err, " ",
            ErrorDescription(err));
      return(false);
   }
   return(true);
}

// get order type
int MyOrderType(int pos_id)
{
   int type = OP_NONE;
   if(MyPos[pos_id] > 0 && OrderSelect(MyPos[pos_id],
         SELECT_BY_TICKET)) type = OrderType();
   return(type);
}

// get order lots
double MyOrderLots(int pos_id)
{
   double lots = 0;
   if(MyPos[pos_id] > 0 && OrderSelect(MyPos[pos_id],
         SELECT_BY_TICKET)) lots = OrderLots();
   return(lots);   
}

// get signed lots of open position
double MyOrderOpenLots(int pos_id)
{
   int type = MyOrderType(pos_id);
   double lots = 0;
   if(type == OP_BUY) lots = OrderLots();
   if(type == OP_SELL) lots = -OrderLots();
   return(lots);   
}

// get order open price
double MyOrderOpenPrice(int pos_id)
{
   double price = 0;
   if(MyPos[pos_id] > 0 && OrderSelect(MyPos[pos_id],
         SELECT_BY_TICKET)) price = OrderOpenPrice();
   return(price);   
}

// get order open time
datetime MyOrderOpenTime(int pos_id)
{
   datetime opentime = 0;
   if(MyPos[pos_id] > 0 && OrderSelect(MyPos[pos_id],
         SELECT_BY_TICKET)) opentime = OrderOpenTime();
   return(opentime);   
}

// get order stop loss
double MyOrderStopLoss(int pos_id)
{
   double sl = 0;
   if(MyPos[pos_id] > 0 && OrderSelect(MyPos[pos_id],
         SELECT_BY_TICKET)) sl = OrderStopLoss();
   return(sl);
}

// get order take profit
double MyOrderTakeProfit(int pos_id)
{
   double tp = 0;
   if(MyPos[pos_id] > 0 && OrderSelect(MyPos[pos_id],
         SELECT_BY_TICKET)) tp = OrderTakeProfit();
   return(tp);
}

// get close price of open position
double MyOrderClosePrice(int pos_id)
{
   double price = 0;
   if(MyOrderOpenLots(pos_id) != 0 && 
      OrderSelect(MyPos[pos_id], SELECT_BY_TICKET))
      price = OrderClosePrice();
   return(price);
}

// get profit of open position
double MyOrderProfit(int pos_id)
{
   double profit = 0;
   if(MyOrderOpenLots(pos_id) != 0 && 
      OrderSelect(MyPos[pos_id], SELECT_BY_TICKET))
      profit = OrderProfit();
   return(profit);
}

// get profit of open position in pips
double MyOrderProfitPips(int pos_id)
{
   double profit = 0;
   if(MyOrderOpenLots(pos_id) > 0)
      profit = MyOrderClosePrice(pos_id)
      -MyOrderOpenPrice(pos_id);
   if(MyOrderOpenLots(pos_id) < 0)
      profit = MyOrderOpenPrice(pos_id)
      -MyOrderClosePrice(pos_id);
   return(profit/PipPoint);
}

// print order information
void MyOrderPrint(int pos_id)
{
   double minlots = MarketInfo(Symbol(), MODE_MINLOT);
   int lots_digits = MathLog(1.0/minlots)/MathLog(10.0);
   string stype[] = {"buy", "sell", "buy limit",
                     "sell limit", "buy stop", "sell stop"};
   string s = "MyPos[";
   s = s + pos_id + "] ";
   if(MyOrderType(pos_id) == OP_NONE) s = s + "No position";
   else
   {
      s = s + "#"
            + MyPos[pos_id]
            + " ["
            + TimeToStr(OrderOpenTime())
            + "] "
            + stype[MyOrderType(pos_id)]
            + " "
            + DoubleToStr(OrderLots(), lots_digits)
            + " "
            + Symbol()
            + " at " 
            + DoubleToStr(OrderOpenPrice(), Digits);
      if(OrderStopLoss() != 0)
         s = s + " sl " 
               + DoubleToStr(OrderStopLoss(), Digits);
      if(OrderTakeProfit() != 0)
         s = s + " tp "
               + DoubleToStr(OrderTakeProfit(), Digits);
      s = s + " magic " + MAGIC_B[pos_id];
   }
   Print(s);
}

