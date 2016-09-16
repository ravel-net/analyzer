import os.path
import os
import shutil
 
path="/Users/suhanjiang/Desktop/txt2dat2"
#/Users/anduo/Desktop/txt2dat/plt/delete_toposize_10_fwnum_8_natnum_4.plt
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
            mylist=[int(mylist) for mylist in mylist if mylist]
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
            shutil.move(dataname, newdata)
            gnu_script1='''set datafile separator ';'
set key right bottom
set xlabel "time duration"
set ylabel "ratio"
set yrange [0:1]
set output \"'''
            gnu_script2='''\"
set terminal pdfcairo  
plot \"'''
            gnu_script3='''\" using 1:2 notitle with linespoints
set output'''
            gnu_script=gnu_script1+pdfname+gnu_script2+newdata+gnu_script3
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
 
if __name__=='__main__':
    getfiles()
    print "done, press enter to stop."
    raw_input()