test: bin/tester
	bin/tester "$(TFLAG) ../app_ethercat_test/bin/XK-1/app_ethercat_test.xe"

bin/tester: src/stimulus.c
	if [ ! -d bin ]; then mkdir bin; fi
	cc -o bin/tester -std=c99 -m32 -I $(XMOS_TOOL_PATH)/include src/stimulus.c $(XMOS_TOOL_PATH)/lib/libxsidevice.so 
