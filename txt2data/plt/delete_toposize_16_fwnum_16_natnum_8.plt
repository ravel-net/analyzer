set datafile separator ';'
set key right bottom
set logscale x
set xlabel "dependency discovery time (ms)"
set ylabel "CDF"
set yrange [0:1]
set output "/Users/suhanjiang/Desktop/txt2data/pdf/delete_toposize_16_fwnum_16_natnum_8.pdf"
set terminal pdfcairo  
plot "/Users/suhanjiang/Desktop/txt2data/dst/delete_toposize_16_fwnum_16_natnum_8.dat" using 1:2 notitle with linespoints,\
"/Users/suhanjiang/Desktop/txt2data/dst/sat_delete_toposize_16_fwnum_16_natnum_8.txt" using 1:2 notitle with points pointtype 7,\
"/Users/suhanjiang/Desktop/txt2data/dst/unsat_delete_toposize_16_fwnum_16_natnum_8.txt" using 1:2 notitle with points pointtype 5
set output