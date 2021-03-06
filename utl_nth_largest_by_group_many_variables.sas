Select nth highest for mutiple variables using SAS and R (not so trivial)

   Five solutions.

   I suggest use ranking(4 or 5) due to ties. Also need to select a 'ties' method.

   I normalized the input data, mad the data key/value pairs. SAS
   requires two tansposes for normalization so I use Alea's gather macro.
   Ther eis some interesting cross fertization possible between SAS and R, Perl and Pyhton.

    Four solutions ( I left out IML and it may well be the best, O think it has a 'smallest/largest' function?)

    SOLUTIONS

    * create data;
    data have;
      input USA AUS ENG;
      datalines;
    1000 2000 500
    3000 1000 200
    1500 1500 1000
    2200 1100 1500
    700 150 900
    3000 1000 500
    ;
    run;

      1. call sortn -- Very restrictive but least code solution

         proc transpose data=have out=havxpo;
         run;quit;

         data want;
            set havxpo;
            call sortn(of col:);
            nthLargest=col5;
            keep _name_ nthLargest;
         run;quit;

          NAME     NTHLARGEST

          USA         3000
          AUS         1500
          ENG         1000

      2. gather and sort

         %utl_gather(have,key,var,val,nrm,valformat=10.);
         * (creates special key/value pairs dataset);

         proc sort data=nrm out=nrmSrt noequals;
         by key descending var;
         run;quit;

         data want(drop=cnt);
           retain cnt 0;
           set nrmSrt;
           by key;
           cnt=cnt+1;
           if cnt=2 then output;
           if last.key then cnt=0;
         run;quit;

         Up to 40 obs WORK.WANT total obs=3

         Obs    KEY     VAR

          1     AUS    1500
          2     ENG    1000
          3     USA    3000

     3.  gather proc univariate

         %utl_gather(have,key,var,val,nrm,valformat=10.);

         ods exclude all;
         ods output extremeobs=want_pre(keep=key high);
         proc univariate data=nrm nextrobs=2;
           class key;
           var var;
         run;quit;
         ods select all;

         data want;
           set want_pre;
           if mod(_n_,2)=1;
         run;quit;

         WORK.WANT total obs=3

         Obs    KEY    HIGH

          1     AUS    1500
          2     ENG    1000
          3     USA    3000


     4.   WPS/R solution

          options validvarname=upcase;
          libname sd1 "d:/sd1";
          data sd1.have;
            input USA AUS ENG;
            datalines;
          1000 2000 500
          3000 1000 200
          1500 1500 1000
          2200 1100 1500
          700 150 900
          3000 1000 500
          ;
          run;

          %utl_gather(sd1.have,key,var,,sd1.nrm,valformat=10.);

          %utl_submit_wps64('
          libname sd1 "d:/sd1";
          options set=R_HOME "C:/Program Files/R/R-3.4.0";
          libname wrk "%sysfunc(pathname(work))";
          proc r;
          submit;
          source("c:/Program Files/R/R-3.4.0/etc/Rprofile.site",echo=T);
          library(dplyr);
          library(haven);
          have<-read_sas("d:/sd1/nrm.sas7bdat");
          want<-as.data.frame(group_by(have, KEY) %>%
            mutate(rank = rank(desc(VAR),ties.method = "max")) %>%
            arrange(rank));
          want<-want[want$rank==2,];
          endsubmit;
          import r=want data=wrk.want_wps;
          run;quit;
          ');

         proc print data=want_wps;
         run;quit;

         Up to 40 obs from want_wps total obs=4

         Obs    KEY     VAR    RANK

          1     USA    3000      2
          2     AUS    1500      2
          3     ENG    1000      2
          4     USA    3000      2

     5.  SAS proc rank

         %utl_gather(have,key,var,val,nrm,valformat=10.);

         proc sort data=nrm out=nrmSrt;
            by key descending var;
         run;quit;

         proc rank data=nrmSrt out=nrmRnk(where=(_var=2))
              descending ties=high;
           by key;
           var var;
           ranks _var;
         run;quit;


         Up to 40 obs WORK.NRMRNK total obs=4

         Obs    KEY     VAR    _VAR

          1     AUS    1500      2
          2     ENG    1000      2
          3     USA    3000      2
          4     USA    3000      2


  see
   https://goo.gl/nZsdQH
   https://communities.sas.com/t5/Base-SAS-Programming/Variable-wise-nth-highest-using-SAS/m-p/402054

