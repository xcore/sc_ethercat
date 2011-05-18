#include "xsidevice.h"
#include <assert.h>

void *xsim = 0;

int main(int argc, char **argv) {
    XsiStatus status = xsi_create(&xsim, "test.xe");
    assert(status == XSI_STATUS_OK);
    while (status != XSI_STATUS_DONE) {
        status = xsi_clock(xsim);
        asert(status == XSI_STATUS_OK
              ||	status	==	XSI_STATUS_DONE );
    }
    status = xsi_terminate(xsim);
    assert(status == XSI_STATUS_OK);
    return 0;
}
