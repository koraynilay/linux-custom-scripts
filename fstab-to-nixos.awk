#!/bin/awk -f
!/^#/ && NF>0 {
	print "fileSystems.\""$2"\" = {";
	print "  fsType = \""$3"\";";
	print "  device = \""$1"\";";
	printf "  options = [ ";
	n=split($4, a, ",");
	for(i=1;i<=n;i++) {
		printf "\""a[i]"\" ";
	}
	print "];";
	print "};";
}
