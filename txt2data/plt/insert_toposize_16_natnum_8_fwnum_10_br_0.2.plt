set datafile separator ';'
set key right bottom
set logscale x
set xlabel "dependency discovery time (ms)"
set ylabel "CDF"
set yrange [0:1]
set output "/Users/suhanjiang/Desktop/txt2data/pdf/insert_toposize_16_natnum_8_fwnum_10_br_0.2.pdf"
set terminal pdfcairo  
plot "/Users/suhanjiang/Desktop/txt2data/dst/insert_toposize_16_natnum_8_fwnum_10_br_0.2.dat" using 1:2 notitle with linespoints,\
"/Users/suhanjiang/Desktop/txt2data/dst/sat_insert_toposize_16_natnum_8_fwnum_10_br_0.2.txt" using 1:2 notitle with points pointtype 7,\
"/Users/suhanjiang/Desktop/txt2data/dst/unsat_insert_toposize_16_natnum_8_fwnum_10_br_0.2.txt" using 1:2 notitle with points pointtype 5
set output