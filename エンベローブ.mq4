// BBcross1Time_EA.mq4
#property copyright "Copyright (c) 2012, Toyolab FX"
#property link      "http://forex.toyolab.com/"

// マイライブラリー
#define POSITIONS 1
#include <MyPosition.mqh>

// マジックナンバー
int Magic = 20121000;
string EAname = "BBCross1Time_EA";

// 外部パラメータ
extern double Lots = 0.1;  // 売買ロット数
extern int StartHour = 12; // 開始時刻（時）
extern int EndHour = 20;   // 終了時刻（時）

// テクニカル指標の設定
#define MaxBars 3
double Enve_U[MaxBars];      // 上位ライン用の配列
double Enve_L[MaxBars];      // 下位ライン用の配列
extern int BBPeriod = 20;  // ボリンジャーバンドの期間
extern int BBDev = 2;      // 標準偏差の倍率

// テクニカル指標の更新
void RefreshIndicators()
{
   for(int i=0; i<MaxBars; i++)
   {
   
   
      Enve_U[i] = iEnvelopes(NULL, 0, BBPeriod, MODE_EMA, 0, PRICE_CLOSE, MODE_UPPER, BBDev,i);
      Enve_L[i] = iEnvelopes(NULL, 0, BBPeriod, MODE_EMA, 0, PRICE_CLOSE, MODE_LOWER, BBDev,i);
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
   if(pos <= 0 && CrossDownClose(Enve_U, 1)) ret = 1;
   // 売りシグナル
   if(pos >= 0 && CrossUpClose(Enve_U, 1)) ret = -1;
   return(ret);
}

// フィルター関数
int FilterSignal(int signal)
{
   int ret = 0;
   if(StartHour < EndHour)
   {
      if(Hour() >= StartHour && Hour() <= EndHour) ret = signal;
   }
   else
   {
      if(Hour() >= StartHour || Hour() <= EndHour) ret = signal;
   }
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

   // エントリーシグナル
   int sig_entry = EntrySignal(0);

   // 反対シグナルによるポジションの決済
   if(sig_entry != 0) MyOrderClose(0);

   // エントリーシグナルのフィルター
   sig_entry = FilterSignal(sig_entry);

   // 買い注文
   if(sig_entry > 0) MyOrderSend(0, OP_BUY, Lots, 0, 0, 0, EAname);
   // 売り注文
   if(sig_entry < 0) MyOrderSend(0, OP_SELL, Lots, 0, 0, 0, EAname);
   return(0);
}

