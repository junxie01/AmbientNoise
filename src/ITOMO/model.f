c****************************************************************
      SUBROUTINE MODEL
      IMPLICIT NONE
      include "tomo.h"
      include "line.h"
c TYPE definitions ++++++++++++++++++++++++++++++++++++++
      real*8    ff,fl,vel,r1,r2
      real*4    sf,tf,dis,tim,fl1,fl2,ff1,ff2,wdel,wmed
      integer*4 i,j,k
c END TYPE definitions ++++++++++++++++++++++++++++++++++
      if(.not. lmodel) goto 70
      do 10 i=1,360
      do 10 j=1,181
   10 f2(j,i)=0.0
   20 read(16,*,end=30)fl,ff,vel
      i=fl+1.5d0
      j=-ff+91.5d0
      if(i.lt.1.or.i.gt.360.or.j.lt.1.or.j.gt.181) then
      write(*,*)'ERROR IN MODEL  fi=',ff,', lam=',fl
      stop
      endif
      f2(j,i)=vel
      goto 20
   30 close(16)
      r1=0.d0
      r2=0.d0
      do 40 k=1,360
      r1=r1+f2(2,k)
   40 r2=r2+f2(180,k)
      r1=r1/360.d0
      r2=r2/360.d0
      do 50 k=1,360
      f2(1,k)=r1
   50 f2(181,k)=r2
      do 60 i=1,360
      do 60 j=1,181
      if(DABS(f2(j,i)).lt.0.1d0) then
      write(*,*)i,j
      STOP 'ERROR: WRONG MODEL'
      endif
   60 continue
      close(16)
********* Mean velocity & weight normalizing ************
   70 sf=0.0
      tf=0.0
      do i=1,n
        ff1=(90.0-TE0(i))*const
        ff2=(90.0-TE(i))*const
        fl1=FI0(i)*const
        fl2=FI(i)*const
        wdel=COS(ff1)*COS(ff2)+SIN(ff1)*SIN(ff2)*COS(fl2-fl1)
        if(ABS(wdel).ge.1.0) wdel=SIGN(1.0,wdel)
        dis=R*ATAN2(SQRT(1.-wdel*wdel),wdel)
        tim=dis/T(i)
        wmed=wmed+WEIGHT(i)
        sf=sf+dis*tim
        tf=tf+tim*tim
      enddo
      c00=sf/tf
      write(8,1000) c00
      write(*,1000) c00
 1000 format(' Square root mean velocity=',f8.3,' (km/sec)')
********* Time delays *******************************************
      CALL PSTIME('Input     ')
      return
      end
