#include <stdio.h>
#include "platform.h"
#include "xil_printf.h"
#include "xbasic_types.h"
#include "xil_io.h"
#include "xparameters.h"
#include "sleep.h"

Xuint32 *baseaddr = (Xuint32 *)0x43C00000;

int main()
{
    init_platform();
    xil_printf("AES Pipelined Encryption Start\n\r");

    // ---------------------------------------
    // Register mapping:
    //  0 - reset
    //  1 - start
    //  2-5 - data_in[127:0]  (2:LSB → 5:MSB)
    //  6-9 - key_in[127:0]   (6:LSB → 9:MSB)
    // 10-13 - data_out[127:0] (10:LSB → 13:MSB)
    // 14 - done
    // ---------------------------------------

    // Example plaintext and key (AES standard test vector)
    int data_in_0 = 0x00000000;
    int data_in_1 = 0x00000000;
    int data_in_2 = 0x00000000;
    int data_in_3 = 0x00000000;

    int key_in_0  = 0x00000000;
    int key_in_1  = 0x00000000;
    int key_in_2  = 0x00000000;
    int key_in_3  = 0x00000000;

    int ctext_0, ctext_1, ctext_2, ctext_3;
    int done;

    xil_printf("Resetting AES core...\n\r");
    Xil_Out32((baseaddr + 0), 1); // reset = 1
    usleep(1000);
    Xil_Out32((baseaddr + 0), 0); // reset = 0
    usleep(1000);

    xil_printf("Writing plaintext and key...\n\r");
    // Write plaintext (2-5)
    Xil_Out32((baseaddr + 2), data_in_0);
    Xil_Out32((baseaddr + 3), data_in_1);
    Xil_Out32((baseaddr + 4), data_in_2);
    Xil_Out32((baseaddr + 5), data_in_3);

    // Write key (6-9)
    Xil_Out32((baseaddr + 6), key_in_0);
    Xil_Out32((baseaddr + 7), key_in_1);
    Xil_Out32((baseaddr + 8), key_in_2);
    Xil_Out32((baseaddr + 9), key_in_3);

    xil_printf("Starting AES encryption...\n\r");
    Xil_Out32((baseaddr + 1), 1); // start = 1
    usleep(100);

    xil_printf("Waiting for done signal...\n\r");
    while (1)
    {

        done = Xil_In32(baseaddr + 14);
        if (done == 1)
            break;
    }

    xil_printf("Encryption completed!\n\r");

    // Read ciphertext (10-13)
    ctext_0 = Xil_In32(baseaddr + 10);
    ctext_1 = Xil_In32(baseaddr + 11);
    ctext_2 = Xil_In32(baseaddr + 12);
    ctext_3 = Xil_In32(baseaddr + 13);

    xil_printf("Ciphertext (128-bit):\n\r");
    xil_printf("ctext[3] = %08x\n\r", ctext_3);
    xil_printf("ctext[2] = %08x\n\r", ctext_2);
    xil_printf("ctext[1] = %08x\n\r", ctext_1);
    xil_printf("ctext[0] = %08x\n\r", ctext_0);

    xil_printf("AES Pipelined Encryption Finished\n\r");

    cleanup_platform();
    return 0;
}