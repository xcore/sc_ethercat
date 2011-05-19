test: bin/tester
	bin/tester "../app_ethercat_test/bin/XK-1/app_ethercat_test.xe"

bin/tester: src/stimulus.c
	if [ ! -d bin ]; then mkdir bin; fi
	cc -o bin/tester -std=c99 -m32 -I $(installpath)/include src/stimulus.c $(installpath)/lib/libxsidevice.so 
