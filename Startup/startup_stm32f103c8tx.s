/******************************************************
 * @file      STARTUP_STM32F103C8TX
 * BLACK PILL LED BLINKING IN ASSEMBLER 52 BYTES LONG
 *******************************************************/

// A FEW DEFINITIONS


#define TOP_OF_STACK              0x20000700
#define CHECK_BYTE                0x20000710



#define RCC_APB2_ADDR             0x40021018
#define ENABLE_GPIOC_VALUE        0x10

#define GPIOC_CRH                 0x40011004
#define GPIOC_CRH_VALUE           0x44144444

#define GPIOC_ODR_OFFSET_FROM_CRH 0x08

#define BIT_13_VALUE              (1UL << 13)



#define ROM_START                 0x08000000
#define RAM_START                 0x20000000
#define PROGRAM_LENGTH            END_LOOP - ROM_START

#define RAMCODE2                  ram_code - ROM_START
#define RAM_CODE_2                RAMCODE2 + RAM_START +1 // thumb MODE --> +1


#define COUNTER_DELAY_OFFSET      0x08
#define RCC_ADDR_OFFSET           0x0C
#define RAM_START_OFFSET          0x10
#define PROGRAM_LENGTH_OFFSET     0x14
#define RAM_CODE_OFFSET           0x18
#define ROM_START_OFFSET          0x1C
#define CHECK_BYTE_OFFSET         0x20
#define GPIOC_CRH_VALUE_OFFSET    0x24
#define GPIOC_CRH_OFFSET          0x28
/******************************************************************************
*  VECTORS
******************************************************************************/
// ARM ASSEMBLER ATTRIBUTES
.syntax unified
.cpu cortex-m4
/*********************************************************************
*  VECTORS SECTION START
**********************************************************************/
  .section .vector_table

  .word TOP_OF_STACK            // DOESN'T MATTER WE DON'T USE STACK HERE
  .word Reset_Handler           // RESET HANDLER VECTOR

  .word 400000                  // counter delay value for ROM execute
  .word RCC_APB2_ADDR           // BASE ADDRESS OF RCC 0x40021018
  .word RAM_START               // 0x20000000
  .word PROGRAM_LENGTH          // length of program
  .word RAM_CODE_2              // start addres in ram
  .word ROM_START               // = 0x08000000
  .word CHECK_BYTE              // = 0x20000710 indicator to run program after reset in ROM or RAM
  .word GPIOC_CRH_VALUE         // 0x44144444 initial value GPIOC->CRH
  .word GPIOC_CRH               // 0x40011004 GPIOC->CRH ADDRESS
/*********************************************************************
*  VECTORS END
**********************************************************************/

  .thumb_func
  .text
/***********************************************************
* RESET CODE - BLINKING LED PC13
********************************************************************/


Reset_Handler:

  mov  r7, 0x08000000                          // * [r7 = 0x08000000] --> [VECTOR TABLE START ADDRESS]

  // init values in registers to copy data from FLASH into RAM
  ldr  r0, [R7, #RAM_START_OFFSET]             // * [r0 = 0x20000000] --> = RAM_START
  ldr  r1, [R7, #PROGRAM_LENGTH_OFFSET]        // * how many bytes to copy into RAM
  ldr  r2, [R7, #ROM_START_OFFSET]             // r2 = 0x08000000 --> start of ROM
  movs r3, #0                                  // r3 = 0 = initial value to count copied bytes


Copy_Data:
  ldr  r4, [r2, r3]                             // copy 32bit word from ROM
  str  r4, [r0, r3]                             // and store this 32bit word into RAM
  adds r3, r3, #4                               // count copied bytes
  cmp  r3, r1                                   // compare copied bytes with length of program
  bcc  Copy_Data                                // test

  ldr  r4, [r7, #COUNTER_DELAY_OFFSET]          // r4 = 400000
  lsr  r4, 2                                    // r4 = 400000/4 = 100000
  str  r4, [r0, #COUNTER_DELAY_OFFSET]          // store in RAM lower value for faster led blinking


  ldr  r5, [R0, #RAM_CODE_OFFSET]               // R5 = start addres in RAM

  ldr  r4, [R2, #CHECK_BYTE_OFFSET]             // our control byte address
  ldr  r3, [r4]                                 // get our control byte into r3 from RAM
  eor  r3, #0x01                                // toggle lowest bit
  ands r3, #0x01                                // check lowest bit to execute place
  str  r3, [r4]                                 // store our check byte after change

  beq  ram_code                                 // if 0 go to flash execute, if 1 = RAM execute

  mov  pc, r5                                   // GO TO RAM EXECUTE !!!

//****************************************************************************************************/

/* 1. ENABLE RCC CLOCK FOR GPIOC (0x40021018 ADDRESS) */
/* 2. SET REGISTER R1 AS GPIOC->CRH VALUE   (0x44144444  VALUE) */
/* 3. SET REGISTER R0 AS GPIOC->CRH ADDRESS (0x40011004  ADDRESS) AND STORE INTO GPIOC_CRH */
/* 4. TOGGLE BIT 13 IN GPIOC->ODR REGISTER  (0x4001100C  ADDRESS)  */
/* 5. A SMALL DELAY LOOP */
/* 6. GO BACK TO TOGGLE BIT 13 IN GPIOC->ODR REGISTER */


ram_code:
  mov  r7, pc                                  // check program counter where is - in RAM or ROM?
  and r7, 0x28000000                           // and make ADDRES to DATA_TABLES now we got
                                               // R7 = RAM or ROM START ADDRESS 0x20000000 or 0x08000000

//**********************************************************************************************************

/* 1. ENABLE RCC CLOCK FOR GPIOC (0x40023830 ADDRESS) */
  LDR    R0, [R7, #RCC_ADDR_OFFSET]           // R0 = ROM_OR_RAM_BASE_ADDRES (R7 = 0x08000000 or 0x20000000)  12 = RCC_APB2_BASE_ADDRES
  LDR    R1, [R0]                             // R1 = RCC_APB2_EN ADDRESS = (0x40021018)
  ORR.W  R1,  R1, #ENABLE_GPIOC_VALUE         // ENABLE GPIOC
  STR    R1, [R0]                             // STORE NEW VALUE WITH GPIOC RUNNING CLK


/* 2. SET REGISTER R1 AS GPIOC->CRH VALUE   (0x44144444  INITIAL VALUE) */
/* 3. SET REGISTER R0 AS GPIOC->CRH ADDRESS (0x40011004  BASE_ADDRESS) AND STORE INTO GPIOC->CRH */
  LDR    R1, [R7, #GPIOC_CRH_VALUE_OFFSET]    // R1 = (0x44144444  INITIAL VALUE
  LDR    R0, [r7, #GPIOC_CRH_OFFSET]          // R0 = (0x40011004  BASE_ADDRESS)
  STR    R1, [R0]                             // STORE INITIAL VALUE INTO GPIOC->CRH


  //LDR    R1, [R0, #GPIOC_ODR_REG_OFFSET]    // UNNEECESSARY

LOOP01:
/* 4. TOGGLE BIT 13 IN GPIOC->ODR REGISTER (0x4001100C  ADDRESS)  */
  EOR.W  R1,  R1,BIT_13_VALUE                 // TOGGLE BIT 13 IN R1
  STR    R1, [R0, #GPIOC_ODR_OFFSET_FROM_CRH] // STORE VALUE WITH TOGGLED BIT 13 INTO GPIOC->ODR_REGISTER

  LDR R2, [R7, #COUNTER_DELAY_OFFSET]         // SIMPLE DELAY LOOP  R2 = 400000 or 400000/4


LOOP02:

/* 5. A SMALL DELAY LOOP */
  SUBS   R2,#1                                // DECREMENT REGISTER WITH FLAGS UPDATE (ZERO FLAG WE USED)
  BNE    LOOP02                               // REGISTER NOT 0? SO STILL DECREMENT

/* 6. GO BACK TO TOGGLE BIT 13 IN GPIOC->ODR REGISTER */
  BEQ    LOOP01
END_LOOP:                         // DELAY END GO BACK TO BLINKING LOOP
/*****END OF FILE****/
