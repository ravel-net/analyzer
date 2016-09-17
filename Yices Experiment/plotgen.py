import os.path
import os
import shutil
import math
from optparse import OptionParser

#/Users/suhanjiang/Desktop/txt2dat/plt/delete_toposize_10_fwnum_8_natnum_4.plt
def txt2dat(fp,file):
    if os.path.exists(fp):
        if fp[-4:]=='.txt':
            print "processing",fp
            mylist=[]
            ftxt=open(fp,'r')
            dataname=str(fp[:-4])+".dat"
            pdfname=str(fp[:-4])+".pdf"
            pdfname=pdfname.replace('src','pdf')
            pltname=str(fp[:-4])+".plt"
            fdat=open(dataname,'w')
            for l in ftxt.readlines():
                if l[0] == '#':
                    pass
                elif l[0]==' ':
                    pass    
                else: 
                    e=l.split('\n')
                    mylist.append(e[0])
            mylist=[float(mylist) for mylist in mylist if mylist]
            myset = set(mylist)
            newlist=list(myset)
            newlist=sorted(newlist)
            p=0
            for item in newlist:
                p=p+round(float(mylist.count(item))/float(len(mylist)),5)
                print mylist.count(item),len(mylist),p
                l=str(item)+';'+str(p)+'\n'     
                fdat.write(l)
                fdat.flush
            fdat.close()  
            ftxt.close() 
            newdata=dataname.replace('src','dst')
            newdata1=newdata.replace('dst/','dst/sat_')[:-4]+".txt"
            newdata2=newdata.replace('dst/','dst/unsat_')[:-4]+".txt"
            shutil.move(dataname, newdata)
            gnu_script1='''set datafile separator ';'
set key right bottom
set logscale x
set xlabel "dependency discovery time (ms)"
set ylabel "CDF"
set yrange [0:1]
set output \"'''
            gnu_script2='''\"
set terminal pdfcairo  
plot \"'''
            gnu_script3='''\" using 1:2 notitle with linespoints,\\'''
            gnu_script4='''\" using 1:2 notitle with points pointtype 7,\\'''
            gnu_script5='''\" using 1:2 notitle with points pointtype 5
set output'''
            gnu_script=gnu_script1+pdfname+gnu_script2+newdata+gnu_script3+'\n'+'\"'+newdata1+gnu_script4+'\n'+'\"'+newdata2+gnu_script5
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


