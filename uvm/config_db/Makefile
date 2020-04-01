## 

x: all

#
# Include file for IUS Makefiles
#

UVM_VERBOSITY =	UVM_LOW

#
# Note that "-access rw" have an adverse impact on performance
# and should not be used unless necessary.
#
# They are used here because they are required by some examples
# (backdoor register accesses).
#

UVM_HOME	= /cad/local/apps/cadence/incisive/13.20-s05/tools/methodology/UVM/CDNS-1.1d/sv

IUS =	irun -access rw -uvmhome $(UVM_HOME) +UVM_VERBOSITY=$(UVM_VERBOSITY) -quiet  +define+UVM_OBJECT_MUST_HAVE_CONSTRUCTOR+UVM_REPORT_DISABLE_FILE_LINE +opt=$(opt)


clean:
	rm -rf *~ core csrc simv* vc_hdrs.h ucli.key *.log INCA_libs

all:
	$(IUS) -incdir ./ *.sv
