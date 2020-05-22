// BBcross1Time_EA.mq4
#property copyright "Copyright (c) 2012, Toyolab FX"

// �}�C���C�u�����[
#define POSITIONS 1
#include <MyPosition.mqh>

// �}�W�b�N�i���o�[
int Magic = 20121000;
string EAname = "BBCross1Time_EA";

// �O���p�����[�^
extern double Lots = 0.1;  // �������b�g��
extern int StartHour = 12; // �J�n�����i���j
extern int EndHour = 20;   // �I�������i���j

// �e�N�j�J���w�W�̐ݒ�
#define MaxBars 3
double Enve_U[MaxBars];      // ��ʃ��C���p�̔z��
double Enve_L[MaxBars];      // ���ʃ��C���p�̔z��
extern int BBPeriod = 20;  // �{�����W���[�o���h�̊���
extern int BBDev = 2;      // �W���΍��̔{��

// �e�N�j�J���w�W�̍X�V
void RefreshIndicators()
{
   for(int i=0; i<MaxBars; i++)
   {
   
   
      Enve_U[i] = iEnvelopes(NULL, 0, BBPeriod, MODE_EMA, 0, PRICE_CLOSE, MODE_UPPER, BBDev,i);
      Enve_L[i] = iEnvelopes(NULL, 0, BBPeriod, MODE_EMA, 0, PRICE_CLOSE, MODE_LOWER, BBDev,i);
   }
}

// �I�l���w�W���㔲��
bool CrossUpClose(double& ind2[], int shift)
{
   return(Close[shift+1] <= ind2[shift+1] && Close[shift] > ind2[shift]);
}

// �I�l���w�W��������
bool CrossDownClose(double& ind2[], int shift)
{
   return(Close[shift+1] >= ind2[shift+1] && Close[shift] < ind2[shift]);
}

// �G���g���[�֐�
int EntrySignal(int pos_id)
{
   // �I�[�v���|�W�V�����̌v�Z
   double pos = MyOrderOpenLots(pos_id);

   int ret = 0;
   // �����V�O�i��
   if(pos <= 0 && CrossDownClose(Enve_U, 1)) ret = 1;
   // ����V�O�i��
   if(pos >= 0 && CrossUpClose(Enve_U, 1)) ret = -1;
   return(ret);
}

// �t�B���^�[�֐�
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

// �������֐�
int init()
{
   // �|�W�V�����̏�����
   MyInitPosition(Magic);
   return(0);
}

// �e�B�b�N�����s�֐�
int start()
{
   // �e�N�j�J���w�W�̍X�V
   RefreshIndicators();
   
   // �|�W�V�����̍X�V
   MyCheckPosition();

   // �G���g���[�V�O�i��
   int sig_entry = EntrySignal(0);

   // ���΃V�O�i���ɂ��|�W�V�����̌���
   if(sig_entry != 0) MyOrderClose(0);

   // �G���g���[�V�O�i���̃t�B���^�[
   sig_entry = FilterSignal(sig_entry);

   // ��������
   if(sig_entry > 0) MyOrderSend(0, OP_BUY, Lots, 0, 0, 0, EAname);
   // ���蒍��
   if(sig_entry < 0) MyOrderSend(0, OP_SELL, Lots, 0, 0, 0, EAname);
   return(0);
}

