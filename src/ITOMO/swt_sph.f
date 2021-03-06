C********************************************************************
C*     Program is designed for tomographic reconsts                 *
C*     of surface wave phase velocities ON SPHERICAL SURFACE        *
C*     from the data on path velocities                             *
C*     SOLUTION IS DETERMINED ON THE SPHERE DIRECTLY                *
C********************************************************************
      SUBROUTINE SWTSPH
      IMPLICIT NONE
      include "tomo.h"
      include "line.h"
c-------------------------------------------------------------
      real*4    f(NRAZ*NRAZ),dazi(NRAZ),fsl(NRAZ),denf(NRAZ),
     *          ff(NRAZ),dens(NRAZ),gis(IAZIM,NRAZ),fslr(NRAZ)
      integer*4 lidd(NRAZ),ipvt(NRAZ) 
      real*8    xk1(NRAZ),yk1(NRAZ)
c-------------------------------------------------------------
      real*8    xh,yh,zh,xk,yk,sxy
c-------------------------------------------------------------
      real*8    x1(3),x2(3),xn(3),e(3),delta,step,dlen,st1,st2,firot
      real*8    sigm,sigmx,sigs2s,sigv2v,sss,sigmw,tresh
      real*4    alpha,alpha1,azmax,gise,gsum,gval,rcond,s,s1
      real*4    s2s,sre,tc00,ww,w2w,wsum,wval,value,value1
      real*4    RBIMOD,RBIMOD1
      integer*4 i,j,ii,lj,jj,i1,i2,i3,iccc,ierr,ihome,iswt,iou,k,kk
      integer*4 kkk,lii,nff,nlidd,ns2s
      real*4    fr(NRAZ*NRAZ)
C--------- Creation cellular net ------------------------------------
      CALL TRASS(n_pnt)
      write(8,1000) wexp
      write(*,1000) wexp
 1000 format("Normalization factor :",F9.5)
C--------- Constants definition-------------------------------------
      KOD=0
      if(nm.gt.NRAZ) then
      KOD=1
      write(*,*)'SIZE OF MATRIX f TOO SMALL',NRAZ*NRAZ,
     +' SHOULD BE:',nm*nm
      write(8,*)'SIZE OF MATRIX f TOO SMALL',NRAZ*NRAZ,
     +' SHOULD BE:',nm*nm
      STOP
      endif
      write(*,*)'Cells: ',nall,', nm=',nm,' nd+1=',nd+1
      write(8,*)'Cells: ',nall,', nm=',nm,' nd+1=',nd+1
C--------------------------------------------------------------------
      alpha=alph1(1)
      sigm=alph1(2)/R
      sigmx=alph1(4)/R
      alpha1=alph1(3)
C--------------------------------------------------------------------
C**      write(8,1001) n
C** 1001 format('    Number of Paths=',i5)
C*****************************************************************
      nff=0
      do 100 i=1,nm*nm
  100 f(i)=0.0
      do 200 i=1,nm
      do 105 j=1,IAZIM
  105 gis(j,i)=0.0
      dens(i)=0.0
  200 fsl(i)=0.0
      sigs2s=0.0d0
      sigv2v=0.0d0
c**** Create lines with integrals for matrix f ***************** 
      do 6 i=1,n
      ncoin0=-1
c**** Normal to trace plane & epicentral distance *************
      CALL TO_CART(TE0(i),FI0(i),TE(i),FI(i),x1,x2,xn,delta)
      T(i)=DBLE(R)*delta/DBLE(T(i))
c      write(*,*)TE0(i),FI0(i),TE(i),FI(i),xn
      nlidd=0
      lidd(1)=0
      do 1 j=1,nm
      denf(j)=0.0
    1 ff(j)=0.0
      tc00=0.0
      step=step0*drad
      iswt=0
      st1=0.0d0
      st2=step
      dlen=0.0d0
    2 if(st2.ge.delta) then
      st2=delta
      step=st2-st1
      iswt=1
      endif
      firot=(st2+st1)/2.0d0
      CALL RTURN(firot,xn,x1,e)
      call NORM(e,e)
      CALL ESTRACE(lidd,nlidd,step,e,nm,denf,ff,xn,gis,ierr)
      tc00=tc00+step/RBIMOD(e)
      if(ierr.eq.0) dlen=dlen+step
      if(iswt.eq.1) goto 3
      st1=st2
      st2=st2+step
      goto 2
    3 continue
      tc00=tc00*R
      if(dlen.gt.0.01d0) then
c**      if(dlen.ne.0.0) then
      do 31 j=1,nm
   31 dens(j)=dens(j)+denf(j)
      nff=nff+1
      tinmod(i)=tc00
c***************** Matrix creation*******************************
      w2w=WEIGHT(i)*WEIGHT(i)
      do 4 lii=1,nlidd
      ii=lidd(lii)
      do 4 lj=lii,nlidd
      j=lidd(lj)
      s=ff(ii)*ff(j)*w2w
      s1=f((ii-1)*nm+j)+s
      f((ii-1)*nm+j)=s1
      if(ii.ne.j) f((j-1)*nm+ii)=s1
    4 continue
      s2s=(t(i)-tc00)*w2w
      do 5 ii=1,nm
    5 fsl(ii)=fsl(ii)+ff(ii)*s2s
      resid_i(i)=s2s/w2w
      sigs2s=sigs2s+DBLE(s2s/w2w)*DBLE(s2s/w2w)
      sss=DBLE(R)*delta
      sss=sss*(1.0d0/DBLE(t(i))-1.0d0/tc00)
      sigv2v=sigv2v+sss*sss
      endif
    6 continue
      ns2s=nff
      sigs2s=DSQRT(sigs2s/(DBLE(ns2s)-1.0d0))
      sigv2v=DSQRT(sigv2v/(DBLE(ns2s)-1.0d0))
      write(*,*)'Number of integrals are: ',ns2s
      write(8,*)'Number of integrals are: ',ns2s
      write(*,'("SQRT of initial residuals dispersion are: ",f9.3," sec")') sigs2s
      write(8,'("SQRT of initial residuals dispersion are: ",f9.3," sec")') sigs2s
      write(*,'("SQ_RT of initial velocities dispersion are: ",f9.5," km/sec")') sigv2v
      write(8,'("SQ_RT of initial velocities dispersion are: ",f9.5," km/sec")') sigv2v
      CALL PSTIME('Integrals ')
c*************** Azimutal distribution **************************
c*************** Azimutal distribution **************************
      azmax=0.0
      do 551 kk=1,nm
      s=0.0
      gsum=0.0
      do 561 kkk=1,IAZIM
      gise=gis(kkk,kk)
      s=s+gise
      if(gsum.lt.gise) gsum=gise
  561 continue
      dazi(kk)=0.0
      if(gsum.gt.0.0) dazi(kk)=s/gsum*180.0/FLOAT(IAZIM)
      if(dazi(kk).gt.azmax) azmax=dazi(kk)
  551 continue
      write(*,*)'MAXIMUM of asimutal parameter is : ',azmax
      write(8,*)'MAXIMUM of asimutal parameter is : ',azmax
c***************** Matrix creation*******************************
c**** Create lines with smoothing for matrix f ***************** 
c***************** Matrix creation*******************************
      if(iresol.eq.1) then
      do i=1,nm*nm
      fr(i)=f(i)
      enddo 
      endif
c****************************************************************
      if(alpha1.lt.0) goto 40
      do 30 i=1,nm
      denf(i)=0.0
      do 10 j=1,nm
   10 ff(j)=0.0
      nlidd=0
      sigmw=(sigmx-sigm)*DBLE((azmax-dazi(i))/azmax)+sigm
      tresh=DCOS(sigmw*DSQRT(2.d0*pow*DLOG(10.d0)))
cxx   CALL EGAUSS(lidd,nlidd,i,nm,ff,sigm,sigmx,dens,denf(i),dazi,azmax)
      CALL EGAUSS(lidd,nlidd,i,nm,ff,dens,denf(i),sigmw,tresh)
      nff=nff+1
      do 20 lii=1,nlidd
      ii=lidd(lii)
      do 20 lj=lii,nlidd
      jj=lidd(lj)
      s=ff(ii)*ff(jj)*alpha1*alpha1*wexp*wexp
      s1=f((ii-1)*nm+jj)+s
      f((ii-1)*nm+jj)=s1
      if(ii.ne.jj) f((jj-1)*nm+ii)=s1
   20 continue
   30 continue
   40 continue
      call PSTIME('Gauss     ')
      iccc=0
      do 50 i=1,nm*nm
      if(f(i).eq.0.0) iccc=iccc+1
   50 continue
      write(*,*) 'Matrix elements:',nm*nm,' Zero are:',iccc
      write(8,1002)
 1002 format('    matrix is calculated')
c**************** Add diagonal elements ************************
      wsum=0.0
      do 51 kk=1,nm
      ww=denf(kk)/2.0/wexp
c**      ww=denf(kk)/wexp
      denf(kk)=ww
      if(ww.gt.wsum)wsum=ww
   51 continue
      write(*,*)'Maximum intersections/cell are: ',wsum
      write(8,*)'Maximum intersections/cell are: ',wsum
      sre=0.
      do 60 kk=1,nm
   60 sre=sre+f((kk-1)*nm+kk)/nm
      if(alpha.gt.0.0) then
      do 70 kk=1,nm
   70 f((kk-1)*nm+kk)=f((kk-1)*nm+kk)+sre*alpha*
     +EXP(-0.147130*denf(kk))
      endif
      write(8,1003)sre
 1003 format('  Trace F/Size',f15.4)
c************ Matrix inversion ********************************
      CALL SGECO(f,nm,nm,ipvt,rcond,dens)
      write(8,'("Matrix condition = ",e15.6)') rcond
      CALL SGESL(f,nm,nm,ipvt,fsl,0)
      CALL PSTIME('Inresion  ')
c************ Create & Output Resolution Matrix ***************
      if(iresol.eq.1) then
c* UNCOMM      write(17) nm,cell
      do i=1,nm
      do j=1,nm
      fslr(j)=fr((i-1)*nm+j)
      enddo
      CALL SGESL(f,nm,nm,ipvt,fslr,0)
      do j=1,nm
      fr((i-1)*nm+j)=fslr(j)
      enddo
      iou=ioutr(i)
      i1=icrpnt(iou)/1000000
      i3=icrpnt(iou)-i1*1000000
      i2=i3/1000
      i3=i3-i2*1000
      sxy=DSQRT(dr(i1)*dr(i1)+dr(i2)*dr(i2)+dr(i3)*dr(i3))
      xh=dr(i1)/sxy
      yh=dr(i2)/sxy
      zh=dr(i3)/sxy
      xk=DACOS(zh)
      yk=DATAN2(yh,xh)/drad
      xk=DATAN(DTAN(dpi/2.0d0-xk)/DBLE(GEO))/drad
      xk1(i)=xk
      yk1(i)=yk
c* UNCOMM      write(17) xk,yk,(fslr(lll),lll=1,nm)
      enddo
c* UNCOMM      close(17)
      CALL PSTIME('Res_matrix')
      if(lpoint) CALL RES_OUTP(nm,xk1,yk1,fr)
      CALL RES_ANAL(nm,xk1,yk1,fr)
      CALL PSTIME('Res_analys')
      endif
c************ End *********** Resolution Matrix ***************
c*********** Calculate Residuals ******************************
      CALL RESID(sigs2s,sigv2v,step0,nm,fsl)
      write(*,'("SQRT of final residuals dispersion are: ",f9.3," sec")') sigs2s
      write(8,'("SQRT of final residuals dispersion are: ",f9.3," sec")') sigs2s
      write(*,'("SQ_RT of final velocities dispersion are: ",f9.5," km/sec")') sigv2v
      write(8,'("SQ_RT of final velocities dispersion are: ",f9.5," km/sec")') sigv2v
c*********** Return to home ***********************************
      ihome=0
      if(ihome.eq.1) then
      do 110 i=1,nm
      iou=ioutr(i)
      i1=icrpnt(iou)/1000000
      i3=icrpnt(iou)-i1*1000000
      i2=i3/1000
      i3=i3-i2*1000
      sxy=DSQRT(dr(i1)*dr(i1)+dr(i2)*dr(i2)+dr(i3)*dr(i3))
      xh=dr(i1)/sxy
      yh=dr(i2)/sxy
      zh=dr(i3)/sxy
      xk=DACOS(zh)
      yk=DATAN2(yh,xh)/drad
      xk=DATAN(DTAN(dpi/2.0d0-xk)/DBLE(GEO))/drad
      write(10,1004)yk,xk,c00/(1.+fsl(i))
 1004 format(3f12.4)
  110 continue
      NXY=nm
      else
      NXY=0
      do 120 k=1,nlat
      if(lcoout) then
        xk=DBLE(ATAN(GEO*TAN((dlat0+(k-1)*s_lat)*const)))
      else
        xk=(dlat0+(k-1)*s_lat)*const
      endif
      xk=pi/2.0d0-xk
      do 120 j=1,nlon
      NXY=NXY+1
      yk=(dlon0+(j-1)*s_lon)*const
      value1=RBIMOD1(xk,yk)
      wval=0.0
      gval=0.0
      CALL EINTPOL (xk,yk,nm,denf,wval,ierr)
      CALL EINTPOL (xk,yk,nm,dazi,gval,ierr)
      CALL EINTPOL (xk,yk,nm,fsl,value,ierr)
      if(ierr.eq.1) then
      NXY=NXY-1
      value=0.0
      goto 120
      endif
      write(10,1004) dlon0+(j-1)*s_lon,dlat0+(k-1)*s_lat,value1/(1.+value)
      if(lres) then
      write(9,1004) dlon0+(j-1)*s_lon,dlat0+(k-1)*s_lat,wval
      write(11,1004) dlon0+(j-1)*s_lon,dlat0+(k-1)*s_lat,gval
      endif
 120  continue
      endif
      CALL PSTIME('Velocities')
c*********** End Return to home *******************************
      close(10)
      close(9)
      close(11)
      RETURN
      end
c****************************************************************
      SUBROUTINE RESID(sigs2s,sigv2v,stepi,nmm,fsl)
      include "tomo.h"
      include "line.h"
      real*4 fsl(nmm)
      real*8 sigs2s,sigv2v,sss
      real*8 x1(3),x2(3),xn(3),e(3),delta,step,stepi,dlen,st1,st2,firot
      nff=0
      sigs2s=0.0d0
      sigv2v=0.0d0
      do 3 i=1,n
c**** Normal to trace plane & epicentral distance *************
      CALL TO_CART(TE0(i),FI0(i),TE(i),FI(i),x1,x2,xn,delta)
c**** Create lines with integrals for matrix f ***************** 
      fsum=0.0
      step=stepi*drad
      iswt=0
      st1=0.0d0
      st2=step
      dlen=0.0d0
    1 if(st2.ge.delta) then
      st2=delta
      step=st2-st1
      iswt=1
      endif
      firot=(st2+st1)/2.0d0
      CALL RTURN(firot,xn,x1,e)
      call NORM(e,e)
      CALL EINTEGR(step,e,nmm,sum,fsl,ierr)
      if(ierr.eq.0) dlen=dlen+step
      if(ierr.eq.0) fsum=fsum+sum
      if(iswt.eq.1) goto 2
      st1=st2
      st2=st2+step
      goto 1
    2 continue
      if(dlen.gt.0.01) then
      nff=nff+1
c***************** Matrix creation*******************************
      w2w=WEIGHT(i)*WEIGHT(i)
      s2s=fsum-(t(i)-tinmod(i))
      if(lresid) then
c output residuals ========================
        fff0=TE0(i)
        fff1=TE(i)
        if(lcoord) then
          fff0= ATAN(TAN(const*TE0(i))/GEO)/const
          fff1 = ATAN(TAN(const*TE(i))/GEO)/const
        endif
        write(35,'(i7,4f12.4,2f12.5,3f12.5)') IIII(i),
     *   fff0,FI0(i),fff1,FI(i),delta*6371.0d0/DBLE(T(i)),
     *   WEIGHT(i),0.0-s2s,resid_i(i),SNGL(delta/drad)
      endif
cxx  *   write(35,'(i7,2f12.5)') IIII(i),SNGL(delta/drad),s2s
      sigs2s=sigs2s+DBLE(s2s*s2s)
      sss=DBLE(R)*delta
      sss=sss*(1.0d0/DBLE(t(i))-1.0d0/(DBLE(fsum)+tinmod(i)))
      sigv2v=sigv2v+sss*sss
      endif
    3 continue
      if(lresid) close(35)
      sigs2s=DSQRT(sigs2s/(DBLE(nff)-1.0d0))
      sigv2v=DSQRT(sigv2v/(DBLE(nff)-1.0d0))
      return
      end
c****************************************************************
      REAL FUNCTION RBIMOD(e)
      include "tomo.h"
      include "line.h"
      real*8 dff,dfl,r0,r1,r2,r3,di,dj,e(3)
      if(.not. lmodel) goto 1
      dfl=DATAN2(e(2),e(1))/drad
      if(dfl.lt.0.d0)dfl=dfl+360.d0
      dff=e(3)
      if(DABS(dff).gt.1.d0) dff=DSIGN(1.d0,e(3))
      dff=DACOS(dff)/drad
      i=dfl+1.d0
      j=dff+1.d0
      if(i.lt.1)i=1
      if(i.gt.359)i=359
      if(j.lt.1)j=1
      if(j.gt.180)j=180
      di=dfl-i+1
      dj=dff-j+1
      r0=f2(j,i)
      r1=f2(j+1,i)-f2(j,i)
      r2=f2(j,i+1)-f2(j,i)
      r3=f2(j,i)+f2(j+1,i+1)-f2(j,i+1)-f2(j+1,i)
      RBIMOD=r0+r1*dj+r2*di+r3*di*dj
      return
********* Mean velocity *********************************
    1 RBIMOD=c00
      return
      end
c****************************************************************
      REAL FUNCTION RBIMOD1(xk,yk)
      real*8 dff,dfl,r0,r1,r2,r3,di,dj,xk,yk
      include "tomo.h"
      include "line.h"
      if(.not. lmodel) goto 1
      dfl=yk/drad
      if(dfl.lt.0.d0)dfl=dfl+360.d0
      dff=xk/drad
      i=dfl+1.d0
      j=dff+1.d0
      if(i.lt.1)i=1
      if(i.gt.359)i=359
      if(j.lt.1)j=1
      if(j.gt.180)j=180
      di=dfl-i+1
      dj=dff-j+1
      r0=f2(j,i)
      r1=f2(j+1,i)-f2(j,i)
      r2=f2(j,i+1)-f2(j,i)
      r3=f2(j,i)+f2(j+1,i+1)-f2(j,i+1)-f2(j+1,i)
      RBIMOD1=r0+r1*dj+r2*di+r3*di*dj
      return
********* Mean velocity *********************************
    1 RBIMOD1=c00
      return
      end
c****************************************************************
c Output current time relative to the start program time
c****************************************************************
      SUBROUTINE PSTIME(str)
      IMPLICIT NONE
      save
c TYPE definitions ++++++++++++++++++++++++++++++++++++++
      character*10 str
      character*24 stime,ctime
      integer*4 i,ibeg,ih,im,indt,is,itm,itime,time
c END TYPE definitions ++++++++++++++++++++++++++++++++++
      data indt/0/
      i=time()
      stime=ctime(i)
      if(indt.eq.0) then
      indt=1
      ibeg=i
      endif
      itm=i-ibeg
      itime=itm
      ibeg=i
      ih=itm/3600
      itm=itm-ih*3600
      im=itm/60
      is=itm-im*60
      write(*,'(a10," - <",a24,"> Duration: ",i2,":",i2,":",i2,i6)') str,stime,ih,im,is,itime
      write(8,'(a10," - <",a24,">, Duration: ",i2,":",i2,":",i2,i6)') str,stime,ih,im,is,itime
      return
      end
