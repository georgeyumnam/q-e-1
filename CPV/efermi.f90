!-----------------------------------------------------------------------
      SUBROUTINE EFERMI(NEL,NBANDS,DEL,NKPTS,OCC,EF,EIGVAL, &
     &                  entropy,ismear,nspin)
!-----------------------------------------------------------------------
!
!     FERMI ENERGY & SMEARING PACKAGE WRITTEN FOR CASTEP USE BY A. DE VITA 
!     IN JULY 1992 FROM R.J. NEEDS ORIGINAL VERSION.
!
!     THIS VERSION IS BY N. MARZARI. COLD SMEARING ADDED IN OCT 1995.
!
!     GIVEN A SET OF WEIGHTS AND THE EIGENVALUES ASSOCIATED TO THEIR
!     K-POINTS FOR BZ SAMPLING, THIS SUBROUTINE PERFORMS TWO TASKS: 
!
!     (1) DETERMINES THE FERMI LEVEL AND THE OCCUPANCY OF THE STATES
!         ACCORDING TO THE CHOSEN (ismear) THERMAL BROADENING
!
!     (2) CALCULATES -TS (for schemes 1, 2 and 4, one-half of -TS
!         is the entropy correction that should be added to the
!         total energy to recover the zero-broadening energy
!         (i.e. the true ground-state energy). This is not really
!         necessary anymore using schemes 3, 5, and 6: the free
!         energy E-TS is automatically independent of the temperature (!)
!         up to the fourth (3) or third order (5, 6) in T. Note that
!         (5, 6) do not have negative occupation numbers, at variance
!         with (3).
!
!     THE SUGGESTED SMEARING SCHEME IS ismear=6 (COLD SMEARING II,
!     Marzari et al., Phys. Rev. Lett. 82, 3296 (1999) )
!
!     THE SIX SMEARING SCHEMES (CHOOSE ONE WITH PARAMETER ISMEAR) ARE:
!     
!     (1) GAUSSIAN:
!
!     SEE: C-L FU AND K-M HO, PHYS. REV. B 28, 5480 (1983).
!     THEIR IMPLEMENTATION WAS VARIATIONAL BUT *NOT* CORRECTED FOR
!     SECOND ORDER DEVIATION IN SIGMA, AS ALSO WAS THE SIMILAR SCHEME
!     (WITH OPPOSITE SIGN DEVIATION) IN: R.J.NEEDS, R.M.MARTIN AND O.H.
!     NIELSEN, PHYS. REV. B 33 , 3778 (1986). 
!     USING THE CORRECTION CALCULATED HEREAFTER EVERYTHING SHOULD BE OK.
!     THE SMEARING FUNCTION IS A GAUSSIAN NORMALISED TO 2.
!     THE OCCUPATION FUNCTION IS THE ASSOCIATED COMPLEMENTARY 
!     ERROR FUNCTION. 
!
!     (2) FERMI-DIRAC:
!
!     SEE: M.J.GILLAN J. PHYS. CONDENS. MATTER 1, 689 (1989), FOLLOWING 
!     THE SCHEME OUTLINED IN J.CALLAWAY AND N.H.MARCH, SOLID STATE PHYS. 38,
!     136 (1984), AFTER D.N.MERMIN, PHYS. REV 137, A1441 (1965).
!     THE OCCUPATION FUNCTION IS TWICE THE SINGLE ELECTRON 
!     FERMI-DIRAC DISTRIBUTION.
!
!     (3) HERMITE-DELTA_EXPANSION:
!
!     SEE: METHFESSEL AND PAXTON, PHYS. REV.B 40, 3616 (1989).
!     THE SMEARING FUNCTION IS A TRUNCATED EXPANSION OF DIRAC'S DELTA
!     IN HERMITE POLINOMIALS. 
!     FOR THE SMEARING FUNCTION IMPLEMENTED HERE THE TRUNCATION IS 
!     AT THE FIRST NON-TRIVIAL EXPANSION TERM D1(X).
!     THE OCCUPATION FUNCTION IS THE ASSOCIATED PRIMITIVE. 
!     (NOTE: THE OCCUPATION FUNCTION IS NEITHER MONOTONIC NOR LIMITED 
!     BETWEEN 0. AND 2. : PLEASE CHECK THE COMPATIBILITY OF THIS WITH 
!     YOUR CODE'S VERSION AND VERIFY IN A TEST CALCULATION THAT THE 
!     FERMI LEVEL IS *UNIQUELY* DETERMINED).
!   
!     THE ENTROPY CORRECTION HOLDS UP TO THE THIRD ORDER IN DELTA AT LEAST,
!     AND IT IS NOT NECESSARY (PUT = 0.) FOR THE HERMITE_DELTA EXPANSION,
!     SINCE THE LINEAR ENTROPY TERM IN SIGMA IS ZERO BY CONSTRUCTION
!     IN THAT CASE. (well, we still need the correct free energy. hence
!     delcor is set to its true value, nmar)
!
!     (4) GAUSSIAN SPLINES:
!
!     similar to a Gaussian smearing, but does not require the
!     function inversion to calculate the gradients on the occupancies. 
!     It is thus to be preferred in a scheme in which the occ are 
!     independent variables. (N. Marzari)
!
!     (5) COLD SMEARING I: 
!
!     similar to Methfessel-Paxton (zeroes the linear order in the entropy), 
!     but now with positive-definite occupations (note they can be greater 
!     than 1). This version has a=-0.5634 (minimization of the bump), not 
!     a=-0.8165 (monotonic function in the tail) (N. Marzari)
!
!     (6) COLD SMEARING II: 
!
!     the one to use. (5) and (6) are practically identical; this is more elegant. 
!     For a discussion, see Marzari et al., Phys. Rev. Lett. 82, 3296 (1999), 
!     or Marzari's PhD thesis (Univ. of Cambridge, 1996), at 
!     http://alfaromeo.princeton.edu/~marzari/preprints/index.html#phd.
!
!-----------------------------------------------------------------------
!     PLEASE INQUIRE WITH ADV/NMAR FOR REFERENCE & SUGGESTIONS IF
!     YOU PLAN TO USE THE PRESENT CORRECTED BZ SAMPLING SCHEME 
!-----------------------------------------------------------------------
!
!     INPUT
!
!     NEL ..... NUMBER OF ELECTRONS PER UNIT CELL
!     NBANDS .. NUMBER OF BANDS FOR EACH K-POINT
!     DEL ..... WIDTH OF GAUSSIAN SMEARING FUNCTION
!     NKPTS ... NUMBER OF K-POINTS
!     WEIGHT .. THE WEIGHT OF EACH K-POINT
!     EIGVAL .. EIGENVALUES 
!     ISMEAR .. SMEARING SCHEME
!     NSPIN ... 1:SPIN RESTRICTED, 2:SPIN UNRESTRICTED
!
!     OUTPUT
!
!     OCC ..... THE OCCUPANCY OF EACH STATE
!     EF ...... THE FERMI ENERGY
!     entropy.. -TS (such that the variational functional, i.e.
!               the free energy, is E-TS)
!
!     Also available
!
!     SORT .... THE EIGENVALUES ARE WRITTEN INTO SORT WHICH IS
!               THEN SORTED INTO ASCENDING NUMERICAL VALUE, FROM
!               WHICH BOUNDS ON EF CAN EASILY BE OBTAINED
!     DELCOR    THE CORRECTION -0.5*T*S (the correction is needed 
!               for 1,2 and 4 only)
!     
!-----------------------------------------------------------------------
!     NOTE : 
!
!     ISMEAR = 1 GAUSSIAN BROADENING   
!            = 2 FERMI-DIRAC BROADENING
!            = 3 HERMITE EXPANSION (1ST ORD.) (right delcor now, nmar)
!            = 4 SPLINE OF GAUSSIANS (nmar)
!            = 5 COLD SMEARING I (nmar)
!            = 6 COLD SMEARING II (nmar)
!
!     JMAX       THE MAX NUMBER OF BISECTIONS TO GET EF
!     XACC       THE DESIRED ACCURACY ON EF
!-----------------------------------------------------------------------
!     ANOTHER NOTE:
!     Thanks to the possible > 2 or < 0 
!     orbital occupancies in the general case of smearing function,
!     (e.g. in the M-P case) the algorithm to find EF has been
!     chosen to be the robust bisection method (from Numerical
!     Recipes) to allow for non monotonic relation between total 
!     NEL (see above) and EF. One value for EF which solves
!     NEL(EF) - Z = 0   is always found.
!-----------------------------------------------------------------------

! ismear=0 riempie solo stati bassi
! ismear=-1 homo-lumo





 
      IMPLICIT REAL*8(A-H,O-Z)

      DIMENSION SORT(nbands*nkpts)
      DIMENSION OCC(nbands,nkpts),WEIGHT(nkpts),EIGVAL(nbands,nkpts)
      EXTERNAL ERFC
      EXTERNAL FERMID
      EXTERNAL DELTHM
      EXTERNAL POSHM
      EXTERNAL POSHM2
      PARAMETER ( JMAX =300, XACC=1.0D-17)
 

      if ((nspin.eq.1).or.(nspin.eq.2)) then
       continue
      else
       write(*,*) 'ERROR: EFERMI with nspin different from 1 or 2'
       stop
      end if

      fspin=float(nspin)
      entrofac=3.0-fspin

      if ((nspin.eq.2).and.(ismear.ne.2)) then
       write(*,*) 'ERROR: EFERMI with nspin.eq.2 and ismear.ne.2'
       stop
      end if

      if (nspin.eq.1) then
       if (2*nbands.eq.nel) then
        DO ISPPT = 1, NKPTS
         DO J = 1,NBANDS
          OCC(J,ISPPT) = 2.0 
         end do
        end do
        return
       end if
      else
       if (nbands.eq.nel) then
        DO ISPPT = 1, NKPTS
         DO J = 1,NBANDS
          OCC(J,ISPPT) = 1.0 
         end do
        end do
        return
       end if
      end if
 
      pi=acos(0.0)*2.0
      ee=exp(1.0)
      eesh=sqrt(ee)*0.5
      sq2i=sqrt(2.0)*0.5
      piesqq=sqrt(ee*pi)*0.25
 
! note that this has to be changed if k-points are introduced !

      do nkp=1,nkpts
       weight(nkp)=1.0/float(nkpts)
      end do

      Z    = FLOAT(NEL)
 
! COPY EIGVAL INTO SORT ARRAY.
 
      NEIG = 0
      DO 10 ISPPT = 1,NKPTS
        DO 20  J = 1, NBANDS
          NEIG = NEIG + 1
20        SORT(NEIG) = EIGVAL(J,ISPPT)
10      CONTINUE
 
!-----------------------------------------------------------------------
!  THE ARRAY IS ORDERED INTO ASCENDING ORDER OF EIGENVALUE
!-----------------------------------------------------------------------
 
      DO 26 N=2,NKPTS*NBANDS
        EN=SORT(N)
        DO 22 NN=N-1,1,-1
          IF (SORT(NN).LE.EN) GO TO 24
          SORT(NN+1)=SORT(NN)
  22    CONTINUE
        NN=0
  24    SORT(NN+1)=EN
  26  CONTINUE
      eigmin=sort(1)
      eigmax=sort(NKPTS*nbands) 
 
!-----------------------------------------------------------------------
!  if the temperature is 0 (well, le.1d-9) then set manually the
!  Fermi energy between the HOMO and LUMO
!-----------------------------------------------------------------------

        if ((ismear.ne.0).and.(ismear.ne.-1)) then
 
           if ((abs(del).le.1.d-9).and.(nspin.eq.1)) then
              if ((2*(nel/2)).ne.nel) then
                 write(*,*) 'EFERMI: etemp=0.0 but nel is odd !'
                 stop
              end if
              nel2=nel/2
              entropy=0.0
              ef=0.5*(sort(NKPTS*nel2)+sort(NKPTS*nel2+1))
              DO ISPPT = 1,NKPTS
                 DO J = 1, NBANDS
                    if (eigval(J,ISPPT).le.ef) then
                       occ(j,isppt)=2.0
                    else
                       occ(j,isppt)=0.0
                    end if
                 end do
              end do
              TEST = 0.0
!     write(*,'(a8,f12.6)') 'Efermi: ',ef
              DO ISPPT = 1,NKPTS
                 DO J = 1,NBANDS
!     write(*,'(a8,f12.6,f10.6)') 'Eigs,f: ',
!    &        eigval(J,ISPPT),OCC(J,ISPPT)
                    TEST = TEST + WEIGHT(ISPPT)*OCC(J,ISPPT)
                 end do
              end do
!      this is commented since occ is normalized to 2
!      test=test*2.0
              IF ( ABS(TEST-Z) .GT. 1.0D-5) THEN
                 WRITE(*,*) '*** WARNING *** OCCUPANCIES MANUALLY SET'
                 DO ISPPT = 1,NKPTS
                    DO J = 1, NBANDS
                       if (j.le.nel2) then
                          occ(j,isppt)=2.0
                       else
                          occ(j,isppt)=0.0
                       end if
!         write(*,'(a8,f12.6,f10.6)') 'Eigs,f: ',
!    &         eigval(J,ISPPT),OCC(J,ISPPT)
                    end do
                 end do
              end if
              return
           else if ((abs(del).le.1.d-9).and.(nspin.ne.1)) then
              write(*,*) 'ERROR: EFERMI with etemp.eq.0 and nspin.eq.2'
              stop
           end if
        endif


       if (ismear.eq.-1 .or. ismear.eq.0) then

           nel2=nel/2
             ef=0.5*(sort(NKPTS*nel2)+sort(NKPTS*nel2+1))
                DO ISPPT = 1,NKPTS
                      DO J = 1, NBANDS
                          if (eigval(J,ISPPT).le.ef) then
                              occ(j,isppt)=2.0
                          else
                              occ(j,isppt)=0.0
                          end if
                      end do
                 end do
              if( ismear.eq.-1) then
                 write(6,*) 'CALCOLO STATO ECCITATO'
                 do j=1,nbands
                    if(eigval(j,1) .eq. sort(NKPTS*nel2))  occ(j,1)=1.0
                  if(eigval(j,1) .eq. sort(NKPTS*nel2+1))  occ(j,1)=1.0
                 enddo
              endif
           return
       endif


!-----------------------------------------------------------------------
!     THE UPPER BOUND XE2 AND THE LOWER BOUND XE1 
!     ARE PUT TO FIRST AND LAST EIGENVALUE, THEN
!     THE ACTUAL FERMI ENERGY IS FOUND BY BISECTION
!     UPPER BOUND IS ACTUALLY UPPED A BIT, JUST IN CASE
!-----------------------------------------------------------------------
 
      XE1=SORT(1)
      XE2=SORT(NKPTS*NBANDS)+del*5.0
!     write(*,*) NEL,NBANDS,DEL,NKPTS,ismear
!     write(*,*) xe1,xe2
!
!           WRITE(*,*) ' '
          IF(ISMEAR.EQ.1) THEN
!           WRITE(*,*) 'GAUSSIAN BROADENING'
          ELSEIF(ISMEAR.EQ.2) THEN
!           WRITE(*,*) 'FERMI-DIRAC BROADENING'
          ELSEIF(ISMEAR.EQ.3) THEN
!           WRITE(*,*) 'HERMITE-DIRAC BROADENING'
          ELSEIF(ISMEAR.EQ.4) THEN
!           WRITE(*,*) 'GAUSSIAN SPLINES BROADENING'
          ELSEIF(ISMEAR.EQ.5) THEN
!           WRITE(*,*) 'COLD SMEARING I'
          ELSEIF(ISMEAR.EQ.6) THEN
!           WRITE(*,*) 'COLD SMEARING II'
          ENDIF       
!
! FMID = FUNC(X2) in Numerical Recipes. 
!
      Z1=0.D0
      DO 40 ISPPT = 1,NKPTS
        DO 50 J = 1,NBANDS
          X = (XE2 - EIGVAL(J,ISPPT))/DEL
          IF(ISMEAR.EQ.1) THEN
            Z1 = Z1 + WEIGHT(ISPPT)*( 2.0 - ERFC(X) )/fspin
          ELSEIF(ISMEAR.EQ.2) THEN
            Z1 = Z1 + WEIGHT(ISPPT)*FERMID(-X)/fspin
          ELSEIF(ISMEAR.EQ.3) THEN
            Z1 = Z1 + WEIGHT(ISPPT)*DELTHM(X)/fspin
          ELSEIF(ISMEAR.EQ.4) THEN
            Z1 = Z1 + WEIGHT(ISPPT)*SPLINE(-X)/fspin
          ELSEIF(ISMEAR.EQ.5) THEN
            Z1 = Z1 + WEIGHT(ISPPT)*POSHM(X)/fspin
          ELSEIF(ISMEAR.EQ.6) THEN
            Z1 = Z1 + WEIGHT(ISPPT)*POSHM2(X)/fspin
          ENDIF
50      CONTINUE
40    CONTINUE
 
      FMID= Z1-Z
!     write(*,*) fmid,z1,z
 
! F = FUNC(X1)
 
      Z1=0.D0
      DO 140 ISPPT = 1,NKPTS
        DO 150 J = 1,NBANDS
          X = (XE1 - EIGVAL(J,ISPPT))/DEL
          IF(ISMEAR.EQ.1) THEN
            Z1 = Z1 + WEIGHT(ISPPT)*( 2.0 - ERFC(X) )/fspin
          ELSEIF(ISMEAR.EQ.2) THEN
            Z1 = Z1 + WEIGHT(ISPPT)*FERMID(-X)/fspin
          ELSEIF(ISMEAR.EQ.3) THEN
            Z1 = Z1 + WEIGHT(ISPPT)*DELTHM(X)/fspin
          ELSEIF(ISMEAR.EQ.4) THEN
            Z1 = Z1 + WEIGHT(ISPPT)*SPLINE(-X)/fspin
          ELSEIF(ISMEAR.EQ.5) THEN
            Z1 = Z1 + WEIGHT(ISPPT)*POSHM(X)/fspin
          ELSEIF(ISMEAR.EQ.6) THEN
            Z1 = Z1 + WEIGHT(ISPPT)*POSHM2(X)/fspin
          ENDIF
150     CONTINUE
140   CONTINUE
 
      F= Z1-Z
!     write(*,*) f,z1,z
 
      IF(F*FMID .GE. 0.D0) THEN
        WRITE(*,*) 'WARNING: NO FERMI ENERGY INSIDE EIGENVALUES ?'
      ENDIF
      IF(F .LT. 0.D0) THEN
       RTBIS = XE1
       DX = XE2 - XE1
      ELSE
       RTBIS = XE2
       DX = XE1 - XE2
      ENDIF
      DO 42 J = 1, JMAX
       DX = DX * 0.5D0
       XMID = RTBIS + DX
 
! FMID=FUNC(XMID)
 
      Z1=0.D0
      DO 240 ISPPT = 1,NKPTS
        DO 250 J2 = 1,NBANDS
          X = (XMID - EIGVAL(J2,ISPPT))/DEL
          IF(ISMEAR.EQ.1) THEN
            Z1 = Z1 + WEIGHT(ISPPT)*( 2.0 - ERFC(X) )/fspin
          ELSEIF(ISMEAR.EQ.2) THEN
            Z1 = Z1 + WEIGHT(ISPPT)*FERMID(-X)/fspin
          ELSEIF(ISMEAR.EQ.3) THEN
            Z1 = Z1 + WEIGHT(ISPPT)*DELTHM(X)/fspin
          ELSEIF(ISMEAR.EQ.4) THEN
            Z1 = Z1 + WEIGHT(ISPPT)*SPLINE(-X)/fspin
          ELSEIF(ISMEAR.EQ.5) THEN
            Z1 = Z1 + WEIGHT(ISPPT)*POSHM(X)/fspin
          ELSEIF(ISMEAR.EQ.6) THEN
            Z1 = Z1 + WEIGHT(ISPPT)*POSHM2(X)/fspin
          ENDIF
250     CONTINUE
240   CONTINUE
 
      FMID= Z1-Z
 
      IF(FMID .LE. 0.D0) RTBIS=XMID
      IF(ABS(DX) .LT. XACC .OR. FMID .EQ. 0) THEN
       GOTO 1042
      ENDIF
  42  CONTINUE
        WRITE(*,*) 'CANNOT BISECT FOREVER, CAN I ?'
       CALL EXIT
 
1042  EF = RTBIS
 
!170   CONTINUE

!     WRITE (*,180) EF
!180   FORMAT (' FERMI ENERGY = ',F15.8,' EV')
 
!     FORM OCCUPATIONS OCC(NBDS,NKPTS)
      DO 190 ISPPT = 1, NKPTS
        DO 200 J = 1,NBANDS
          X = ( EF-EIGVAL(J,ISPPT))/DEL
          IF(ISMEAR.EQ.1) THEN
            OCC(J,ISPPT) = 2.0 - ERFC(X)  
          ELSEIF(ISMEAR.EQ.2) THEN
            OCC(J,ISPPT) = FERMID(-X)
          ELSEIF(ISMEAR.EQ.3) THEN
            OCC(J,ISPPT) = DELTHM(X)
          ELSEIF(ISMEAR.EQ.4) THEN
            OCC(J,ISPPT) = SPLINE(-X)
          ELSEIF(ISMEAR.EQ.5) THEN
            OCC(J,ISPPT) = POSHM(X)
          ELSEIF(ISMEAR.EQ.6) THEN
            OCC(J,ISPPT) = POSHM2(X)
          ENDIF
! occupations are normalized to two or one depending on nspin
            OCC(J,ISPPT) = OCC(J,ISPPT)/fspin
200     CONTINUE
190   CONTINUE

!-------------------------------------------------------------
! CALCULATES THE CORRECTION TERM TO GET "0 TEMPERATURE" ENERGY
!-------------------------------------------------------------

      DELCOR=0.0D0
      DO 191 ISPPT = 1, NKPTS
       DO 201 J = 1,NBANDS
        X = ( EF-EIGVAL(J,ISPPT))/DEL
        IF(ISMEAR.EQ.1) THEN
         DELCOR=DELCOR &
     &    -DEL*WEIGHT(ISPPT)*EXP(-X*X)/(2.D0*SQRT(pi))
        ELSEIF(ISMEAR.EQ.2) THEN
         FI=FERMID(-X)/entrospin
         IF(ABS(FI) .GT. 1.E-12) THEN
          IF(ABS(FI-1.D0) .GT. 1.E-12) THEN
           DELCOR=DELCOR+DEL*WEIGHT(ISPPT)* &
     &     (FI*LOG(FI)+(1.D0-FI)*LOG(1.D0-FI))
          ENDIF
         ENDIF
        ELSEIF(ISMEAR.EQ.3) THEN
         DELCOR=DELCOR+DEL/2.0*WEIGHT(ISPPT)  &
     &    *(2.0*x*x-1)*exp(-x*x)/(2.0*sqrt(pi))
        ELSEIF(ISMEAR.EQ.4) THEN
         x=abs(x)
         zeta=eesh*abs(x)*exp(-(x+sq2i)**2)+piesqq*erfc(x+sq2i)
         delcor=delcor-del*WEIGHT(ISPPT)*zeta
        ELSEIF(ISMEAR.EQ.5) THEN
         a=-0.5634
!        a=-0.8165
         DELCOR=DELCOR-DEL/2.0*WEIGHT(ISPPT) &
! NOTE g's are all intended to be normalized to 1 !
! this following line is -2*int_minf^x [t*g(t)]dt
     &   *(2.0*a*x**3-2.0*x*x+1 )*exp(-x*x)/(2.0*sqrt(pi))
        ELSEIF(ISMEAR.EQ.6) THEN
         DELCOR=DELCOR-DEL/2.0*WEIGHT(ISPPT) &
! NOTE g's are all intended to be normalized to 1 !
! this following line is -2*int_minf^x [t*g(t)]dt
     &   *(1-sqrt(2.0)*x)*exp(-(x-1/sqrt(2.))**2)/sqrt(pi)
        ENDIF
201    CONTINUE
191   CONTINUE

!--------------------------------------------------------
!  the correction is also stored in sort, for compatibility,
!  and -TS is stored in entropy
!--------------------------------------------------------

      sort(1)=delcor
      entropy=entrospin*delcor
 
!--------------------------------------------------------
!     TEST WHETHER OCCUPANCY ADDS UP TO Z
!--------------------------------------------------------

      TEST = 0.0
!     write(*,'(a8,f12.6)') 'Efermi: ',ef
      DO ISPPT = 1,NKPTS
       DO J = 1,NBANDS
!       write(*,'(a8,f12.6,f10.6)') 'Eigs,f: ',
!    &       eigval(J,ISPPT),OCC(J,ISPPT)
        TEST = TEST + WEIGHT(ISPPT)*OCC(J,ISPPT)
       end do
      end do

      IF ( ABS(TEST-Z) .GT. 1.0D-5) THEN
        WRITE(*,*) '*** WARNING ***'
        WRITE(*,220) TEST,NEL
220     FORMAT(' SUM OF OCCUPANCIES =',F30.20 ,' BUT NEL =',I5)
!      ELSE
!
!230     FORMAT(' TOTAL CHARGE = ',F15.8)
      ENDIF
!
!     TEST WHETHER THE MATERIAL IS A SEMICONDUCTOR
!
      IF ( MOD( NEL, 2) .EQ. 1) RETURN
      INEL = NEL/2
      ELOW = EIGVAL(INEL+1,1)
      DO 310 ISPPT = 2,NKPTS
        ELOW =MIN( ELOW, EIGVAL(INEL+1,ISPPT))
310   CONTINUE
      DO 320 ISPPT = 1,NKPTS
        IF (ELOW .LT. EIGVAL(INEL,ISPPT)) RETURN
320   CONTINUE

      if (NKPTS.gt.1) then
       WRITE (*,*) 'MATERIAL MAY BE A SEMICONDUCTOR'
      end if
!
      RETURN
      END
!
!-----------------------------------------------------------------------
!
!      real*8 FUNCTION ERFC(XX)
!
!     COMPLEMENTARY ERROR FUNCTION
!     FROM THE SANDIA MATHEMATICAL PROGRAM LIBRARY
!
!     XMAX IS THE VALUE BEYOND WHICH ERFC(X) = 0 .
!     IT IS COMPUTED AS SQRT(LOG(RMIN)), WHERE RMIN IS THE
!     SMALLEST REAL NUMBER REPRESENTABLE ON THE MACHINE.
!     IBM VALUE: (THE INTRINSIC ERFC COULD ALSO BE USED)
!     PARAMETER ( XMAX = 13.4 )
!     VAX VALUE: (XMAX = 9.3)
! -----------------------------------
!     12-Mar-90  Obtained from B. Hammer
!     12-MAR-90  Changed to single precision at the end XW
!                also XX1
!      PARAMETER ( XMAX = 9.3D0)
!
!      IMPLICIT DOUBLE PRECISION (A-H,O-Z)
!      DIMENSION P1(4),Q1(4),P2(6),Q2(6),P3(4),Q3(4)
!
!      DATA P1 /242.66 79552 30531 8D0 , 21.979 26161 82941 5D0 ,
!     + 6.9963 83488 61913 6D0 , -3.5609 84370 18153 9D-2/
!      DATA Q1 /215.05 88758 69861 2D0 , 91.164 90540 45149 0D0,
!     + 15.082 79763 04077 9D0 , 1.0D0/
!      DATA P2 /22.898 99285 1659D0 , 26.094 74695 6075D0 ,
!     + 14.571 89859 6926D0 , 4.2677 20107 0898D0 ,
!     + 0.56437 16068 6381D0 , -6.0858 15195 9688 D-6/
!      DATA Q2 /22.898 98574 9891D0 , 51.933 57068 7552D0 ,
!     + 50.273 20286 3803D0 , 26.288 79575 8761D0 ,
!     + 7.5688 48229 3618D0 , 1.0D0/
!      DATA P3 /-1.2130 82763 89978 D-2 , -0.11990 39552 68146 0D0 ,
!     + -0.24391 10294 88626D0 , -3.2431 95192 77746 D-2/
!      DATA Q3 /4.3002 66434 52770 D-2 , 0.48955 24419 61437D0 ,
!     + 1.4377 12279 37118D0 , 1.0D0/
!     1/SQRT(PI)
!      DATA SQPI /0.56418 95835 47756D0/
!
!----------------------------------------------------------------------
!      IF (XX .GT.  XMAX)    GOTO 330
!      IF (XX .LT. -XMAX)    GOTO 320
!      X = ABS(XX)
!      X2 = X*X
!      IF (X .GT. 4.0D0)     GOTO 300
!      IF (X .GT. 0.46875D0) GOTO 200
!
!     -46875 < X < 0.46875
!      ERFC = X*(P1(1) + X2*(P1(2) + X2*(P1(3) + X2*P1(4))))
!      ERFC = ERFC/(Q1(1) + X2*(Q1(2) + X2*(Q1(3) + X2*Q1(4))))
!      IF (XX .LT. 0.0) ERFC = - ERFC
!      ERFC = 1.0D0 - ERFC
!      GOTO 9999
!
!200   ERFC = EXP( -X2)*(P2(1) + X*(P2(2) + X*(P2(3) + X*(P2(4) +
!     + X*(P2(5) + X*P2(6))))))
!      ERFC = ERFC/(Q2(1) + X*(Q2(2) + X*(Q2(3) + X*(Q2(4) + X*(Q2(5) +
!     + X*Q2(6))))))
!      IF (XX .LE. 0.0) ERFC = 2.0D0 - ERFC
!      GOTO 9999
!
!300   XI2 = 1.0D0/X2
!      ERFC = XI2*(P3(1) + XI2*(P3(2) + XI2*(P3(3) + XI2*P3(4))))/
!     + (Q3(1) + XI2*(Q3(2) + XI2*(Q3(3) + XI2*Q3(4))))
!      ERFC = EXP( -X2)*(SQPI + ERFC)/X
!      IF (XX .LT. 0.0) ERFC = 2.0D0 - ERFC
!      GOTO 9999
!
!320   ERFC = 2.0D0
!      GOTO 9999
!330   ERFC = 0.0D0
!
!9999  RETURN
!      END
!-----------------------------------------------------------------------
      real*8 FUNCTION FERMID(XX)
!
      IMPLICIT DOUBLE PRECISION (A-H,O-Z)
      IF(XX .GT. 30.D0) THEN
        FERMID=0.D0
      ELSEIF(XX .LT. -30.D0) THEN
        FERMID=2.D0
      ELSE
        FERMID=2.D0/(1.D0+EXP(XX))
      ENDIF
!
      RETURN
      END
!-----------------------------------------------------------------------
      real*8 FUNCTION DELTHM(XX)
!
      IMPLICIT DOUBLE PRECISION (A-H,O-Z)
      pi=3.14159265358979
      IF(XX .GT. 10.D0) THEN
        DELTHM=2.D0
      ELSEIF(XX .LT. -10.D0) THEN
        DELTHM=0.D0
      ELSE
        DELTHM=(2.D0-ERFC(XX))+XX*EXP(-XX*XX)/SQRT(PI)
      ENDIF
!
      RETURN
      END
!-----------------------------------------------------------------------
      real*8 FUNCTION SPLINE(X)

      IMPLICIT DOUBLE PRECISION (A-H,O-Z)
      eesqh=sqrt(exp(1.0))*0.5
      sq2i=sqrt(2.0)*0.5
      if (x.ge.0.0) then
        fx=eesqh*exp(-(x+sq2i)**2)
      else
        fx=1.0-eesqh*exp(-(x-sq2i)**2)
      endif 
      spline=2.0*fx
!
      return
      end
!-----------------------------------------------------------------------
      real*8 FUNCTION POSHM(X)
!
! NOTE g's are all intended to be normalized to 1 !
! function = 2 * int_minf^x [g(t)] dt
!
      IMPLICIT DOUBLE PRECISION (A-H,O-Z)
      pi=3.141592653589793238
      a=-0.5634
!     a=-0.8165
      IF(X .GT. 10.D0) THEN
        POSHM=2.D0
      ELSEIF(X .LT. -10.D0) THEN
        POSHM=0.D0
      ELSE
        POSHM=(2.D0-ERFC(X))+(-2.0*a*x*x+2*x+a)*EXP(-X*X)/SQRT(PI)/2.0
      ENDIF
!
      RETURN
      END
!-----------------------------------------------------------------------
      real*8 FUNCTION POSHM2(X)
!
! NOTE g's are all intended to be normalized to 1 !
! function = 2 * int_minf^x [g(t)] dt
!
      IMPLICIT DOUBLE PRECISION (A-H,O-Z)
      pi=3.141592653589793238
      IF(X .GT. 10.D0) THEN
        POSHM2=2.D0
      ELSEIF(X .LT. -10.D0) THEN
        POSHM2=0.D0
      ELSE
        POSHM2=(2.D0-ERFC(X-1./sqrt(2.)))+ &
     &  sqrt(2.)*exp(-x*x+sqrt(2.)*x-0.5)/sqrt(pi)
      ENDIF
!
      RETURN
      END
!-----------------------------------------------------------------------
