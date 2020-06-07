// BBCross0_EA.mq4
#property copyright "Copyright (c) 2012, Toyolab FX"
#property link      "http://forex.toyolab.com/"

// マイライブラリー
#define POSITIONS 1
#include <MyPosition.mqh>

// マジックナンバー
int Magic = 20121500;
string EAname = "BBCross0_EA";

// 外部パラメータ
extern double Lots = 0.1;  // 売買ロット数

// テクニカル指標の設定
#define MaxBars 3
double Enve_U[MaxBars];       // 上位ライン用の配列
double Enve_L[MaxBars];       // 下位ライン用の配列
extern int BBPeriod = 20;     // MAの期間
extern double EnDev = 0.15;   // 標準偏差の倍率
extern double SlTips =7.0;    // 損切り値幅（pips）
extern double STPpips =30.0;   // 利食い値幅（pips）
//中値
double Nakachi;
//ひげのサイズ
double Higesize;
int Uwahige;
int Shitahige;

// テクニカル指標の更新
void RefreshIndicators()
{
   for(int i=0; i<MaxBars; i++)
   {
      Enve_U[i] =iEnvelopes(NULL,0,BBPeriod,0,0,0,EnDev,1,i);
      Enve_L[i] =iEnvelopes(NULL,0,BBPeriod,0,0,0,EnDev,2,i);
      
   }
}

// 終値が指標を上抜け
bool CrossUpClose(double& ind2[], int shift)
{
   return(Close[shift+1] <= ind2[shift+1] && Close[shift] > ind2[shift]);
}

// 終値が指標を下抜け
bool CrossDownClose(double& ind2[], int shift)
{
   return(Close[shift+1] >= ind2[shift+1] && Close[shift] < ind2[shift]);
}

// エントリー関数
int EntrySignal(int pos_id)
{
   // オープンポジションの計算
   double pos = MyOrderOpenLots(pos_id);

   int ret = 0;
    // 買いシグナル
   if(pos <= 0 && CrossDownClose(Enve_L,1)&& Shitahige>0) ret = 1;
   // 売りシグナル
   if(pos >= 0 && CrossUpClose(Enve_U,1)&& Uwahige>0) ret = -1;

   return(ret);
}

// 初期化関数
int init()
{
   // ポジションの初期化
   MyInitPosition(Magic);
   return(0);
}

// ティック時実行関数
int start()
{
   // テクニカル指標の更新
   RefreshIndicators();
   
   // ポジションの更新
   MyCheckPosition();
 //中値
   {Nakachi=(iHigh(NULL,0,1)+iLow(NULL,0,1))/2;}
   //プライスアクションフィルター（下髭陽線と下髭陰線）
   {Higesize=0.04;}
   if(iOpen(NULL,0,1)<=Nakachi&&iClose(NULL,0,1)<=Nakachi&&(iHigh(NULL,0,1)-iLow(NULL,0,1))>=Higesize)
      {Uwahige=1;Shitahige=0;}
   if(iOpen(NULL,0,1)>=Nakachi&&iClose(NULL,0,1)>=Nakachi&&(iHigh(NULL,0,1)-iLow(NULL,0,1))>=Higesize)
      {Uwahige=0;Shitahige=1;} 
   // エントリーシグナル
   int sig_entry = EntrySignal(0);
 
   // 買い注文
   if(sig_entry > 0)
   {
      MyOrderClose(0);
      MyOrderSend(0, OP_BUY, Lots, 0, Ask-SlTips*0.01, Ask+STPpips*0.01, EAname);
   }
   // 売り注文
   if(sig_entry < 0)
   {
      MyOrderClose(0);
      MyOrderSend(0, OP_SELL, Lots, 0, Bid+SlTips*0.01, Bid-STPpips*0.01, EAname);
   }
   return(0);
}

