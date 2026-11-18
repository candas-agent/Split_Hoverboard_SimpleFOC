

/* memory map */
MEMORY
{
  FLASH (rx)      : ORIGIN = 0x08000000 + (DEFINED(LD_FLASH_OFFSET) ? LD_FLASH_OFFSET : 0), LENGTH = 64K - (DEFINED(LD_FLASH_OFFSET) ? LD_FLASH_OFFSET : 0)
  RAM (xrw)       : ORIGIN = 0x20000000, LENGTH = 8K
}

ENTRY(Reset_Handler)

SECTIONS
{
  __stack_size = DEFINED(__stack_size) ? __stack_size : 2048;
  
/* ISR vectors */
  .vectors :
  {
    . = ALIGN(4);
    KEEP(*(.vectors))
    . = ALIGN(4);
/*    __Vectors_End = .;
    __Vectors_Size = __Vectors_End - __gVectors;*/
  } >FLASH
  

  /* GD32F1x0: only the first 32 KB of flash run without wait states (datasheet: "a long time delay when
     CPU fetches the instructions out of the range", measured 5.5x slower). The control loop code and the
     constant data it reads are placed first, the rest (init, calibration, commands, printing) after.
     The link fails if they exceed 32 KB (__fast_end). Code called every loop goes in this list. */
  .text :
  {
    . = ALIGN(4);
    /* soft float and the few libm/libc functions used in the loop */
    *libgcc.a:*(.text*)
    *libm.a:*(.text*)
    *libc_nano.a:lib_a-memcpy*.o(.text*)
    *libc_nano.a:lib_a-memset*.o(.text*)
    /* SimpleFOC control loop (FOCMotor, BLDCMotor, current sense, driver, sensors, filters, controllers) */
    *FOCMotor.cpp.o(.text*)
    *BLDCMotor.cpp.o(.text*)
    *CurrentSense.cpp.o(.text*)
    *gd32_mcu.cpp.o(.text*)
    *gd32f130_mcu.cpp.o(.text*)
    *BLDCDriver6PWM.cpp.o(.text*)
    *foc_utils.cpp.o(.text*)
    *time_utils.cpp.o(.text*)
    *generic_mcu.cpp.o(.text*)
    *pid.cpp.o(.text*)
    *lowpass_filter.cpp.o(.text*)
    *Sensor.cpp.o(.text*)
    *VoltageSense.cpp.o(.text*)
    *wiring_analog.c.o(.text*) *analog.cpp.o(.text*)
    /* sketch loop, time, hall interrupts, RTT and commander polling */
    *main.cpp.o(.text*)
    *gd32_micros.c.o(.text*)
    *(.text._ZN9Commander3run*)
    *systick.c.o(.text*)
    *wiring_time.c.o(.text*)
    *gpio_interrupt.c.o(.text*)
    *SEGGER_RTT*.o(.text*)
    *RTTStream.cpp.o(.text*)
    /* peripheral library functions called by the loop and the interrupts */
    *(.text.adc_inserted_data_read .text.timer_channel_output_pulse_value_config)
    *(.text.timer_channel_output_state_config .text.timer_channel_complementary_output_state_config)
    *(.text.exti_interrupt_flag_get .text.exti_interrupt_flag_clear .text.digitalRead .text.gpio_input_bit_get .text.__errno)
    /* C++ virtual tables: read at every virtual call (sensor, current sense, driver, stream) */
    *(.rodata._ZTV*)
    /* other constant data read in the loop and the hall interrupts */
    *FOCMotor.cpp.o(.rodata) *gd32f130_mcu.cpp.o(.rodata)
    *(.rodata._ZL16ELECTRIC_SECTORS .rodata.gpio_pin .rodata.gpio_port .rodata.digital_pins)
    __fast_end = .;
    *(.text)
    *(.text*)
    *(.glue_7) 
    *(.glue_7t)
    *(.eh_frame)

    KEEP (*(.init))
    KEEP (*(.fini))

    . = ALIGN(4);
    /* the symbol _etext will be defined at the end of code section */
    _etext = .;
  } >FLASH

  .rodata :
  {
    . = ALIGN(4);
    *(.rodata)
    *(.rodata*)
    . = ALIGN(4);
  } >FLASH

   .ARM.extab :
  { 
     *(.ARM.extab* .gnu.linkonce.armextab.*) 
  } >FLASH
  
    .ARM : {
    __exidx_start = .;
      *(.ARM.exidx*)
      __exidx_end = .;
    } >FLASH

  .ARM.attributes : { *(.ARM.attributes) } > FLASH

  .preinit_array     :
  {
    PROVIDE_HIDDEN (__preinit_array_start = .);
    KEEP (*(.preinit_array*))
    PROVIDE_HIDDEN (__preinit_array_end = .);
  } >FLASH
  .init_array :
  {
    PROVIDE_HIDDEN (__init_array_start = .);
    KEEP (*(SORT(.init_array.*)))
    KEEP (*(.init_array*))
    PROVIDE_HIDDEN (__init_array_end = .);
  } >FLASH
  .fini_array :
  {
    PROVIDE_HIDDEN (__fini_array_start = .);
    KEEP (*(.fini_array*))
    KEEP (*(SORT(.fini_array.*)))
    PROVIDE_HIDDEN (__fini_array_end = .);
  } >FLASH



  /* provide some necessary symbols for startup file to initialize data */
  _sidata = LOADADDR(.data);
  .data :
  {
    . = ALIGN(4);
    /* the symbol _sdata will be defined at the data section end start */
    _sdata = .;
    *(.data)
    *(.data*)
    . = ALIGN(4);
    /* the symbol _edata will be defined at the data section end */
    _edata = .;
  } >RAM AT> FLASH

  . = ALIGN(4);
  .bss :
  {
    /* the symbol _sbss will be defined at the bss section start */
    _sbss = .;
    __bss_start__ = _sbss;
    *(.bss)
    *(.bss*)
    *(COMMON)
    . = ALIGN(4);
    /* the symbol _ebss will be defined at the bss section end */
    _ebss = .;
    __bss_end__ = _ebss;
  } >RAM

 . = ALIGN(8);
  PROVIDE ( end = _ebss );
  PROVIDE ( _end = _ebss );
  .stack ORIGIN(RAM) + LENGTH(RAM) - __stack_size :
  {
    PROVIDE( _heap_end = . );
    . = __stack_size;
    PROVIDE( _sp = . );
  } >RAM AT>RAM
}

 ASSERT(__fast_end <= 0x08008000, "control loop code exceeds the 32 KB zero wait state flash area of the GD32F1x0")

 /* input sections */
GROUP(libgcc.a libc.a libm.a libnosys.a)
