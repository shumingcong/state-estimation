function jacobianES(States,B,Bus,Cp,Cq,Dp,Dq,E,F,K,S,Shunt)
global Jh Jc

clear c V;

nbus=length(Bus(:,1));
nbranch=length(B(:,1));
nstate=length(States);
nflowsp=length(Cp(:,1)); 
nflowsq=length(Cq(:,1)); 
nI=length(K(:,1));
nE=length(E(:,1));
nF=length(F(:,1));
nS=length(S(:,1));

c=States(1:nbus);
V=States(nbus+1:2*nbus);
Im=States(2*nbus+1:2*nbus+nI);
ic=States(2*nbus+nI+1:nstate);

numc=length(c);
numV=length(V);
numIm=length(Im);
numic=length(ic);


%% Conventional Measurements

Gik=zeros(nbus);
Bik=zeros(nbus);

for i=1:nbus
    for k=1:nbranch
        if B(k,1)==Bus(i,1)           
           Gik(i,i)=Gik(i,i)+B(k,4)/B(k,7)^2;
           Bik(i,i)=Bik(i,i)+B(k,5)/B(k,7)^2+B(k,6)/2;
        end
         if B(k,2)==Bus(i,1)
           Gik(i,i)=Gik(i,i)+B(k,4);
           Bik(i,i)=Bik(i,i)+B(k,5)+B(k,6)/2;
        end
    end
end

for r=1:nbranch
    for t=1:nbus
        if Bus(t,1)==B(r,1)
           i=t;
        end
        if Bus(t,1)==B(r,2)
           k=t; 
        end
    end
    aik=B(r,7);
    Gik(i,k)=Gik(i,k)-B(r,4)/aik;
    Bik(i,k)=Bik(i,k)-B(r,5)/aik;
    Gik(k,i)=Gik(k,i)-B(r,4)/aik;
    Bik(k,i)=Bik(k,i)-B(r,5)/aik;
end

if isempty(Shunt)==0
    for i=1:nbus
        for r=1:length(Shunt(:,1))
            if Shunt(r,1)==Bus(i,1)
               Gik(i,i)=Gik(i,i)+Shunt(r,3);
               Bik(i,i)=Bik(i,i)+Shunt(r,4);
            end
        end
    end
end


% Pinj and Qinj Derivatives
%==========================

Q=zeros(nbus,1);P=zeros(nbus,1);
J1c=[];J1v=[];J2c=[];J2v=[];
J1Im=zeros(length(Dp(:,1)),numIm);
J1Ic=zeros(length(Dp(:,1)),numic);
J2Im=zeros(length(Dq(:,1)),numIm);
J2Ic=zeros(length(Dq(:,1)),numic);
% 
i1c=1;i1v=1;i2c=1;i2v=1;% aux

for i=1:nbus
    for k=1:nbus
        P(i)=P(i)+V(i)*V(k)*(Gik(i,k)*cos(c(i)-c(k))+Bik(i,k)*sin(c(i)-c(k)));
        Q(i)=Q(i)+V(i)*V(k)*(Gik(i,k)*sin(c(i)-c(k))-Bik(i,k)*cos(c(i)-c(k)));
    end
end

for ix=1:length(Dp(:,1))
    for s=1:nbus
         if Bus(s,1)==Dp(ix,1)
            i=s;
         end
    end
    %
    i1=1;
    for k=1:numc
        if  k~=i
            J1c(i1c,i1)=V(i)*V(k)*(Gik(i,k)*sin(c(i)-c(k))-Bik(i,k)*cos(c(i)-c(k)));
            i1=i1+1;
        else
            J1c(i1c,i1)=-Q(i)-Bik(i,i)*V(i)^2;
            i1=i1+1;
        end   
    end
    i1c=i1c+1;
    %
    i2=1;
    for k=1:numV
        if k~=i
           J1v(i1v,i2)=V(i)*(Gik(i,k)*cos(c(i)-c(k))+Bik(i,k)*sin(c(i)-c(k)));
           i2=i2+1;
        else
           J1v(i1v,i2)=P(i)/V(i)+Gik(i,i)*V(i);
           i2=i2+1;
        end
    end
    i1v=i1v+1;
end

for ix=1:length(Dq(:,1))
    for s=1:nbus
         if Bus(s,1)==Dq(ix,1)
            i=s;
         end
    end
    %
    i3=1;
    for k=1:numc
        if  k~=i
            J2c(i2c,i3)=-V(i)*V(k)*(Gik(i,k)*cos(c(i)-c(k))+Bik(i,k)*sin(c(i)-c(k)));
            i3=i3+1;
        else
            J2c(i2c,i3)=P(i)-Gik(i,i)*V(i)^2;
            i3=i3+1;
        end   
    end
    i2c=i2c+1;
    %
    i4=1;
    for k=1:numV
        if k~=i
           J2v(i2v,i4)=V(i)*(Gik(i,k)*sin(c(i)-c(k))-Bik(i,k)*cos(c(i)-c(k)));
           i4=i4+1;
        else
           J2v(i2v,i4)=Q(i)/V(i)-Bik(i,i)*V(i);
           i4=i4+1;
        end
    end
    i2v=i2v+1;
end


% Pt and Qt Derivatives
%==========================

J3c=zeros(nflowsp,numc);
J3v=zeros(nflowsp,numV);
J3Im=zeros(nflowsp,numIm);
J3Ic=zeros(nflowsp,numic);
J4c=zeros(nflowsq,numc);
J4v=zeros(nflowsq,numV);
J4Im=zeros(nflowsq,numIm);
J4Ic=zeros(nflowsq,numic);

for f=1:nflowsp
    for r=1:nbus
        if Bus(r,1)==Cp(f,1)
           i=r;
        end
        if Bus(r,1)==Cp(f,2)
           k=r;
        end
    end
   for s=1:nbranch
       if  Cp(f,1)==B(s,1) && Cp(f,2)==B(s,2)
           if B(s,3)==Cp(f,3)
           gik=B(s,4);
           bik=B(s,5);
           Bii=B(s,6)/2;
           aik=B(s,7);
           aki=1;
           end
       end
       if Cp(f,1)==B(s,2) && Cp(f,2)==B(s,1)
           if B(s,3)==Cp(f,3)
           gik=B(s,4);
           bik=B(s,5);
           Bii=B(s,6)/2;
           aik=1;
           aki=B(s,7);
           end
       end
   end
    J3c(f,i)=1/aik*V(i)*1/aki*V(k)*gik*sin(c(i)-c(k))-1/aik*V(i)*1/aki*V(k)*bik*cos(c(i)-c(k));
    J3c(f,k)=-1/aik*V(i)*1/aki*V(k)*gik*sin(c(i)-c(k))+1/aik*V(i)*1/aki*V(k)*bik*cos(c(i)-c(k));
    J3v(f,i)=2*1/aik^2*V(i)*gik-1/aik*1/aki*V(k)*gik*cos(c(i)-c(k))-1/aik*1/aki*V(k)*bik*sin(c(i)-c(k));
    J3v(f,k)=-1/aik*1/aki*V(i)*gik*cos(c(i)-c(k))-1/aik*1/aki*V(i)*bik*sin(c(i)-c(k));
end

for f=1:nflowsq
    for r=1:nbus
        if Bus(r,1)==Cq(f,1)
           i=r;
        end
        if Bus(r,1)==Cq(f,2)
           k=r;
        end
    end
 for s=1:nbranch
       if  Cq(f,1)==B(s,1) && Cq(f,2)==B(s,2)
           if B(s,3)==Cq(f,3)
           gik=B(s,4);
           bik=B(s,5);
           Bii=B(s,6)/2;
           aik=B(s,7);
           aki=1;
           end
       end
       if Cq(f,1)==B(s,2) && Cq(f,2)==B(s,1)
           if B(s,3)==Cq(f,3)
           gik=B(s,4);
           bik=B(s,5);
           Bii=B(s,6)/2;
           aik=1;
           aki=B(s,7);
           end
       end
 end
    J4c(f,i)=-1/aik*V(i)*1/aki*V(k)*bik*sin(c(i)-c(k))-1/aik*V(i)*1/aki*V(k)*gik*cos(c(i)-c(k));
    J4c(f,k)=1/aik*V(i)*1/aki*V(k)*bik*sin(c(i)-c(k))+1/aik*V(i)*1/aki*V(k)*gik*cos(c(i)-c(k));
    J4v(f,i)=-2*1/aik^2*V(i)*(bik+Bii)+1/aik*1/aki*V(k)*bik*cos(c(i)-c(k))-1/aik*1/aki*V(k)*gik*sin(c(i)-c(k));
    J4v(f,k)=1/aik*1/aki*V(i)*bik*cos(c(i)-c(k))-1/aik*1/aki*V(i)*gik*sin(c(i)-c(k));
end

% Voltage Derivatives
%==========================

J5c=zeros(nE,numc);
J5v=zeros(nE,numV);
J5Im=zeros(nE,numIm);
J5Ic=zeros(nE,numic);

for i=1:nE
    for k=1:nbus
        if Bus(k,1)==E(i,1)
           J5v(i,k)=1;
        end
    end
end

%% Synchronized Measurements

% V phasor PMU Derivatives
%=========================

J6c=zeros(nF,numc);
J6v=zeros(nF,numV);
J6Im=zeros(nF,numIm);
J6Ic=zeros(nF,numic);
J7c=zeros(nF,numc);
J7v=zeros(nF,numV);
J7Im=zeros(nF,numIm);
J7Ic=zeros(nF,numic);

yes=0;

for i=1:nF
    if F(i,2)==2 || F(i,2)==3
        yes=1;
    end
end

if yes==1
    J7c=zeros(nF-1,numc);
    J7v=zeros(nF-1,numV);
    J7Im=zeros(nF-1,numIm);
    J7Ic=zeros(nF-1,numic);
end

i1=1;
for f=1:nF
    for i=1:nbus  
        if F(f,1)==Bus(i,1)
            J6v(f,i)=1;
            if F(f,2)~=2 && F(f,2)~=3
               J7c(i1,i)=1;
               i1=i1+1;
            end
        end
    end 
end 



% Currents
%==============================

J8c=zeros(nI,numc);
J8v=zeros(nI,numV);
J8Ic=zeros(nI,numic);
J9c=zeros(nI,numc);
J9v=zeros(nI,numV);
J9Im=zeros(nI,numIm);

J8Im=eye(nI);
J9Ic=eye(nI);


Jh=[J1c J1v J1Im J1Ic;
    J2c J2v J2Im J2Ic;
    J3c J3v J3Im J3Ic;
    J4c J4v J4Im J4Ic;
    J5c J5v J5Im J5Ic;
    J6c J6v J6Im J6Ic;
    J7c J7v J7Im J7Ic;
    J8c J8v J8Im J8Ic;
    J9c J9v J9Im J9Ic;
    ];


%% Null Injected Powers
%=========================
Busnull=[];
i1=1;
cou=0;
for i=1:nbus
    if Bus(i,2)==4
       Busnull(i1,1)=i; 
       i1=i1+1;
       cou=cou+1;
    end
end

if isempty(Busnull)~=1
nnull=length(Busnull);

J1nc=zeros(cou,numc);J1nv=zeros(cou,numV);J2nc=zeros(cou,numc);J2nv=zeros(cou,numV);
J1nIc=zeros(cou,numic);J1nIm=zeros(cou,numIm);J2nIc=zeros(cou,numic);J2nIm=zeros(cou,numIm);

i1c=1;i1v=1;

for ix=1:nnull
    for s=1:nbus
         if Bus(s,1)==Busnull(ix,1)
            i=s;
         end
    end
    %
    i1=1;
    for k=1:numc
        if  k~=i
            J1nc(i1c,i1)=V(i)*V(k)*(Gik(i,k)*sin(c(i)-c(k))-Bik(i,k)*cos(c(i)-c(k)));
            J2nc(i1c,i1)=-V(i)*V(k)*(Gik(i,k)*cos(c(i)-c(k))+Bik(i,k)*sin(c(i)-c(k)));
            i1=i1+1;
        else
            J1nc(i1c,i1)=-Q(i)-Bik(i,i)*V(i)^2;
            J2nc(i1c,i1)=P(i)-Gik(i,i)*V(i)^2;
            i1=i1+1;
        end   
    end
    i1c=i1c+1;
    %
    i2=1;
    for k=1:numV
        if k~=i
           J1nv(i1v,i2)=V(i)*(Gik(i,k)*cos(c(i)-c(k))+Bik(i,k)*sin(c(i)-c(k)));
           J2nv(i1v,i2)=V(i)*(Gik(i,k)*sin(c(i)-c(k))-Bik(i,k)*cos(c(i)-c(k)));
           i2=i2+1;
        else
           J1nv(i1v,i2)=P(i)/V(i)+Gik(i,i)*V(i);
           J2nv(i1v,i2)=Q(i)/V(i)-Bik(i,i)*V(i);
           i2=i2+1;
        end
    end
    i1v=i1v+1;
end

Jc1=[J1nc J1nv J1nIm J1nIc;
     J2nc J2nv J2nIm J2nIc];

end



%% PMU Constraints
%====================


num1=0;num2=0;
for f=1:length(S)
    if S(f,3)==1
       num1=num1+1; 
    end
    if S(f,3)==0
        num2=num2+1;
    end
end


J12c1=zeros(num1,numc);
J12v1=zeros(num1,numV);
J12Im1=zeros(num1,numIm);
J12Ic1=zeros(num1,numic);
J13c1=zeros(num2,numc);
J13v1=zeros(num2,numV);
J13Im1=zeros(num2,numIm);
J13Ic1=zeros(num2,numic);
J12c2=zeros(num1,numc);
J12v2=zeros(num1,numV);
J12Im2=zeros(num1,numIm);
J12Ic2=zeros(num1,numic);
J13c2=zeros(num2,numc);
J13v2=zeros(num2,numV);
J13Im2=zeros(num2,numIm);
J13Ic2=zeros(num2,numic);

i1=1;i2=1;
for f=1:nS
    
    I=S(f,2);
 
    for r=1:nbus
        if K(I,1)==Bus(r,1)
           i=r;
        end
        if K(I,2)==Bus(r,1)
           k=r; 
        end
    end
  
    for s=1:nbranch
        if K(I,1)==B(s,1) && K(I,2)==B(s,2)
           if K(I,3)==B(s,3)
              aik=B(s,7);
              gik=1/aik*B(s,4);
              bik=1/aik*B(s,5);
              Bii=B(s,6)/2+(1/aik-1)*1/aik*B(s,5);
              Gii=(1/aik-1)*1/aik*B(s,4);
           end
        end
        if K(I,2)==B(s,1) && K(I,1)==B(s,2)
           if K(I,3)==B(s,3)
              aik=B(s,7);
              gik=1/aik*B(s,4);
              bik=1/aik*B(s,5);
              Bii=B(s,6)/2+(1-1/aik)*B(s,5);
              Gii=(1-1/aik)*B(s,4);
           end
        end   
    end
    
    Iik=Im(I);
    cik=ic(I);
    a=gik*(Gii+gik)+bik*(Bii+bik);
    b=gik*(Bii+bik)-bik*(Gii+gik);
    cp=gik^2+bik^2;
    VjR=(a*V(i)*cos(c(i))-b*V(i)*sin(c(i))-gik*Iik*cos(cik)-bik*Iik*sin(cik))/cp;
    VjI=(b*V(i)*cos(c(i))+a*V(i)*sin(c(i))+bik*Iik*cos(cik)-gik*Iik*sin(cik))/cp;
    
    if S(f,3)==1
       J12c1(i1,i)=(VjI*(-b/cp*V(i)*sin(c(i))+a/cp*V(i)*cos(c(i)))+VjR*(-a/cp*V(i)*sin(c(i))-b/cp*V(i)*cos(c(i))))/sqrt(VjR^2+VjI^2);
       J12v1(i1,i)=(VjI*(b/cp*cos(c(i))+a/cp*sin(c(i)))+VjR*(a/cp*cos(c(i))-b/cp*sin(c(i))))/sqrt(VjR^2+VjI^2);
       J12Ic1(i1,I)=(VjI*(-bik*Iik/cp*sin(cik)-gik*Iik/cp*cos(cik))+VjR*(gik*Iik/cp*sin(cik)-bik*Iik/cp*cos(cik)))/sqrt(VjR^2+VjI^2);
       J12Im1(i1,I)=(VjI*(bik/cp*cos(cik)-gik/cp*sin(cik))+VjR*(-gik/cp*cos(cik)-bik/cp*sin(cik)))/sqrt(VjR^2+VjI^2);
       J12c2(i1,k)=0;
       J12v2(i1,k)=1;
    i1=i1+1;
    end
    
    if S(f,3)==0
       J13c1(i2,i)=(VjR*(-b/cp*V(i)*sin(c(i))+a/cp*V(i)*cos(c(i)))-VjI*(-a/cp*V(i)*sin(c(i))-b/cp*V(i)*cos(c(i))))/(VjR^2+VjI^2);
       J13v1(i2,i)=(VjR*(b/cp*cos(c(i))+a/cp*sin(c(i)))-VjI*(a/cp*cos(c(i))-b/cp*sin(c(i))))/(VjR^2+VjI^2);
       J13Ic1(i2,I)=(VjR*(-bik*Iik/cp*sin(cik)-gik*Iik/cp*cos(cik))-VjI*(gik*Iik/cp*sin(cik)-bik*Iik/cp*cos(cik)))/(VjR^2+VjI^2);  
       J13Im1(i2,I)=(VjR*(bik/cp*cos(cik)-gik/cp*sin(cik))-VjI*(-gik/cp*cos(cik)-bik/cp*sin(cik)))/(VjR^2+VjI^2);  
       J13c2(i2,k)=1;
       J13v2(i2,k)=0;
       i2=i2+1;
    end
end


Jc2=[J12c1 J12v1 J12Im1 J12Ic1;J13c1 J13v1 J13Im1 J13Ic1]-[J12c2 J12v2 J12Im2 J12Ic2;J13c2 J13v2 J13Im2 J13Ic2];

Jc=[Jc1;Jc2];

