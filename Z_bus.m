     linedata=sortrows(linedata, 1); % Sort rows based on the first column
Zmatrice=[];
indice_bus=[];
INDZ=zeros(1,nbr);
F=zeros(nbr,2);
%1er cas
for g=1:nbr
    if linedata(g,6) ~= 1
        Zb(g)=(linedata(g,3)+j*linedata(g,4))*linedata(g,6);
        Zs(g)=linedata(g,5);
        s1=(1/linedata(g,6))*(1/(linedata(g,6))-1);
        s2=(1/(linedata(g,6))-1);
        if Zs(g) ~=0
        Zsh(g,1)=-j*(1/linedata(g,5))*s1;
        Zsh(g,2)=-j*(1/linedata(g,5))*s2;
        else
            Zsh(g,1)=0;
        Zsh(g,2)=0;
        end
    else
Zb(g)=(linedata(g,3)+j*linedata(g,4));
     Zs(g)=linedata(g,5);
     if Zs(g) ~= 0
    Zsh(g,1)=-j*(1/linedata(g,5));
    Zsh(g,2)=-j*(1/linedata(g,5));
     else
             Zsh(g,1)=0;
    Zsh(g,2)=0;
     end
    end
end

for i=1:1:nbr
    n=length(Zmatrice);
    NI=linedata(i,1);
    NJ=linedata(i,2);
    A=zeros(n,1);
    B=zeros(1,n);
    A1=zeros(n,1);
    B1=zeros(1,n);
    exist_I = ismember(NI,indice_bus );
    exist_J = ismember(NJ,indice_bus );
    x=0;
        if  ~exist_I && F(i,1) == 0
         if Zs(i) ~= 0
        Zmatrice=[Zmatrice,A;B,Zsh(i,1)]
              indice_bus = add_unique_number(indice_bus, NI);
              F(i,1)=1;
               end
    end
        n=length(Zmatrice);
        A=zeros(n,1);
        B=zeros(1,n);
    if  ~exist_J && F(i,2) == 0
         if Zs(i) ~= 0
        Zmatrice=[Zmatrice,A;B,Zsh(i,2)]
              indice_bus = add_unique_number(indice_bus, NJ);
              F(i,2)=1;
               end
        end
cas1=1;
end


 for i=1:nbr
    n=length(Zmatrice);
    NI=linedata(i,1);
    NJ=linedata(i,2);
    A=zeros(n,1);
    B=zeros(1,n);
    A1=zeros(n,1);
    B1=zeros(1,n);
    exist_I = ismember(NI,indice_bus );
    exist_J = ismember(NJ,indice_bus );
    x=0;
      if exist_I && ~exist_J && x==0 && INDZ(i) ==0
          n=length(Zmatrice);
          ni=findRank(indice_bus,NI);%essai sinon revient a NI
%           if NI <= n
            for k=1:1:n
            A(k)=Zmatrice(k,ni);
            B(k)=Zmatrice(k,ni);
            end
        Zmatrice=[Zmatrice,A;B,Zb(i)+Zmatrice(ni,ni)]
        INDZ(i)=1;
        indice_bus = add_unique_number(indice_bus, NJ);
        x=1;
%           end
      end
      if exist_J && ~exist_I && x==0 && INDZ(i) ==0
          n=length(Zmatrice);
          nj=findRank(indice_bus,NJ);%essai sinon revient a NJ
%           if NJ <= n
            for k=1:1:n
            A(k)=Zmatrice(k,nj);
            B(k)=Zmatrice(k,nj);
            end
        Zmatrice=[Zmatrice,A;B,Zb(i)+Zmatrice(nj,nj)]
        n=length(Zmatrice);
        INDZ(i)=1;
        indice_bus = add_unique_number(indice_bus, NI);
        x=1;
%           end
          end
      
      cas2=1;
 end

 %%%hmm
%3eme cas
for i=1:1:nbr
    n=length(Zmatrice);
    NI=linedata(i,1);
    NJ=linedata(i,2);
    A=zeros(n,1);
    B=zeros(1,n);
    A1=zeros(n,1);
    B1=zeros(1,n);
    exist_I = ismember(NI,indice_bus );
    exist_J = ismember(NJ,indice_bus );
    x=0;
    if exist_I && F(i,1) == 0
    if Zs(i) ~= 0
        n=length(Zmatrice);
        ni=findRank(indice_bus,NI);%essai sinon revient a NI
        for k=1:1:n
            A(k)=Zmatrice(k,NI);
            B(k)=Zmatrice(k,NI);
        end
        Zmatrice=Zmatrice-(1/(Zmatrice(NI,NI)+Zsh(i,1)))*A*B
              F(i,1)=1;
               end
    end
    if exist_J && F(i,2) == 0
    if Zs(i) ~= 0
        n=length(Zmatrice);
        nj=findRank(indice_bus,NJ);%essai sinon revient a NI
        for k=1:1:n
            A(k)=Zmatrice(k,NJ);
            B(k)=Zmatrice(k,NJ);
        end
        Zmatrice=Zmatrice-(1/(Zmatrice(NJ,NJ)+Zsh(i,2)))*A*B
              F(i,2)=1;
               end
    end
    cas3=1;
end
% % %4eme cas
 for i=1:1:nbr
    n=length(Zmatrice);
    NI=linedata(i,1);
    NJ=linedata(i,2);
    A=zeros(n,1);
    B=zeros(1,n);
    A1=zeros(n,1);
    B1=zeros(1,n);
    exist_I = ismember(NI,indice_bus );
    exist_J = ismember(NJ,indice_bus );
    x=0;
    if exist_I && exist_J && INDZ(i) == 0
        ni=findRank(indice_bus,NI);%essai sinon revient a NI
        nj=findRank(indice_bus,NJ);%essai sinon revient a NI
       for k=1:1:n
            A(k)=Zmatrice(k,NI)-Zmatrice(k,NJ);
            B(k)=Zmatrice(k,NI)-Zmatrice(k,NJ);
       end
            Zmatrice=Zmatrice-(1/(Zmatrice(NI,NI)+Zmatrice(NJ,nj)+Zb(i)-2*Zmatrice(NI,NJ)))*A*B
            x=1;
           INDZ(i)=1;
    end
    cas4=1;
 end

%
% Display final Zbus matrix
disp('Z-bus Impedance Matrix:');
Zbus=final_form(linedata, nbus)

% end of Z_bus.m




