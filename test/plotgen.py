import os.path
import os
import shutil
import math
from optparse import OptionParser

#/Users/suhanjiang/Desktop/txt2dat/plt/delete_toposize_10_fwnum_8_natnum_4.plt
def txt2dat(fp,file):
    if os.path.exists(fp):
        if fp.find('.txt')!=-1 and fp.find('delete')!=-1:
            print "processing",fp
            keylist=[]
            keylist1=[]
            keylist2=[]
            mylist=[]
            fpd=fp
            fpm=fp.replace('delete','modify')
            plotname=fp.replace('delete_','')
            ftxt1=open(fpd,'r')
            ftxt2=open(fpm,'r')
            dataname1=str(fpd[:-4])+".dat"
            dataname2=str(fpm[:-4])+".dat"
            pdfname=str(plotname[:-4])+".pdf"
            pdfname=pdfname.replace('src','pdf')
            pltname=str(plotname[:-4])+".plt"
            fdat1=open(dataname1,'w')
            for l in ftxt1.readlines():
                if l[0] == '#':
                    pass
                elif l[0]==' ':
                    pass    
                else: 
                    e=l.split('\n')
                    keylist1.append(e[0])
                    mylist.append(e[0][2:])
            mylist=[float(mylist) for mylist in mylist if mylist]
            myset = set(mylist)
            newlist=list(myset)
            newlist=sorted(newlist)
            p=0
            for item in newlist:
                p=p+round(float(mylist.count(item))/float(len(mylist)),5)
                print mylist.count(item),len(mylist),p
                l=str(item)+';'+str(p)+'\n' 
                keylist2.append(l.split('\n')[0])
            for i in keylist2:
                for j in keylist1:
                    if i.find(j[2:])!=-1:
                        k=j[0:2]+i
                        keylist.append(k) 
            for i in keylist:
                l=str(i)+'\n'                   
                fdat1.write(l)
                fdat1.flush
            fdat1.close()  
            ftxt1.close() 
            newdata1=dataname1.replace('src','dst')
            #newdata11=newdata1.replace('dst/','dst/sat_')[:-4]+".txt"
            #newdata12=newdata1.replace('dst/','dst/unsat_')[:-4]+".txt"
            shutil.move(dataname1, newdata1)
            keylist=[]
            keylist1=[]
            keylist2=[]            
            mylist=[]
            fdat2=open(dataname2,'w')
            for l in ftxt2.readlines():
                if l[0] == '#':
                    pass
                elif l[0]==' ':
                    pass    
                else: 
                    e=l.split('\n')
                    keylist1.append(e[0])
                    mylist.append(e[0][2:])
            mylist=[float(mylist) for mylist in mylist if mylist]
            myset = set(mylist)
            newlist=list(myset)
            newlist=sorted(newlist)
            p=0
            for item in newlist:
                p=p+round(float(mylist.count(item))/float(len(mylist)),5)
                print mylist.count(item),len(mylist),p
                l=str(item)+';'+str(p)+'\n' 
                keylist2.append(l.split('\n')[0])
            for i in keylist2:
                for j in keylist1:
                    if i.find(j[2:])!=-1:
                        k=j[0:2]+i
                        keylist.append(k) 
            for i in keylist:
                l=str(i)+'\n'     
                fdat2.write(l)
                fdat2.flush
            fdat2.close()  
            ftxt2.close() 
            newdata2=dataname2.replace('src','dst')
            #newdata21=newdata2.replace('dst/','dst/sat_')[:-4]+".txt"
            #newdata22=newdata2.replace('dst/','dst/unsat_')[:-4]+".txt"
            shutil.move(dataname2, newdata2)           
            gnu_script1='''set datafile separator ';'
set key right bottom
set logscale x
set style line 5 lt rgb "black" lw 2 
set style line 2 lt rgb "orange" lw 2
set xlabel "dependency discovery time (ms)"
set ylabel "CDF"
set yrange [0:1]
set output \"'''
            gnu_script2='''\"
set terminal pdfcairo  
plot \"'''
            gnu_script3='''\" using 2:3 notitle with line ls 5,\\'''
            gnu_script4='''\" using 2:($1==0?$3:1/0) notitle with points pt 1 lt rgb "green",\\'''
            gnu_script5='''\" using 2:($1==1?$3:1/0) notitle with points pt 8 lt rgb "blue",\\'''
            gnu_script6='''\" using 2:3 notitle with line ls 2,\\'''
            gnu_script7='''\" using 2:($1==0?$3:1/0) notitle with points pt 1 lt rgb "blue", \\'''           
            gnu_script8='''\" using 2:($1==1?$3:1/0) notitle with points pt 8 lt rgb "green",
set output'''
            
            gnu_script=gnu_script1+pdfname+gnu_script2+newdata1+gnu_script3+'\n'+'\"'+newdata1+gnu_script4+'\n'+'\"'+newdata1+gnu_script5+'\n'+'\"'+newdata2+gnu_script6+'\n'+'\"'+newdata2+gnu_script7+'\n'+'\"'+newdata2+gnu_script8
            fplt=open(pltname,'w')
            fplt.write(gnu_script)
            fplt.close()
            newplt=pltname.replace('src','plt')
            shutil.move(pltname, newplt)
            #print newplt
            os.system("gnuplot "+newplt)          
                            
def getfiles():
    files=os.listdir(path+"/src")
    for file in files:
        fp = path+"/src/"+file
        txt2dat(fp,file)

def optParser():
    desc = "Plot CDFs"
    usage = "%prog [options]\ntype %prog -h for details"
    parser = OptionParser(description=desc, usage=usage)
    parser.add_option("--path", "-p", type="string", default="/Users/suhanjiang/Desktop",
                      help="Choose the path to create a floder to get all execution time (default /Users/suhanjiang/Desktop)")
    return parser


if __name__=='__main__':
    parser = optParser()
    opts, args = parser.parse_args()
    if args:
        parser.print_help()
        sys.exit(0)
    path=opts.path+"/txt2data"    
    getfiles()
    print "done, press enter to stop."
    raw_input()