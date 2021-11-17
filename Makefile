SHELL=/bin/bash
ERUBY=$(wildcard *.erb)
IJM=$(ERUBY:%.erb=%.ijm)

all: $(IJM)


#$(PRFS): lab_exclude_list.txt home_exclude_list.txt common_include_diff.txt common_include_same.txt special_include_diff.txt
$(IJM): CommonFunction.txt


%.ijm: %.erb
	erb $< > $@


