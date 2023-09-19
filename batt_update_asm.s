.text
.global  set_batt_from_ports
        
## ENTRY POINT FOR REQUIRED FUNCTION
set_batt_from_ports:
        ## assembly instructions here

        ## a useful technique for this problem
        #movX    SOME_GLOBAL_VAR(%rip), %reg
        # load global variable into register
        # Check the C type of the variable
        #    char / short / int / long
        # and use one of
        #    movb / movw / movl / movq 
        # and appropriately sized destination register

        movw   BATT_VOLTAGE_PORT(%rip), %dx     # Assign batt_voltage_port to %dx
        cmpw    $0, %dx                         # if(BATT_VOLTAGE_PORT < 0)
        jl     .Failed                          


        sarw    $1, %dx                         # BATT_VOLTAGE_PORT >> 1;
        movw    %dx, 0(%rdi)                    # batt->mlvolts = BATT_VOLTAGE_PORT >> 1;
        subw    $3000, %dx                      # batt->mlvolts - 3000
        sarw    $3, %dx                         # batt->mlvolts >> 3;
        movb    %dl, 2(%rdi)                    # batt->percent = (batt->mlvolts - 3000) >> 3;
        movb    BATT_STATUS_PORT(%rip), %cl     # Assign batt_status_port to cl
        movb    $1, %sil                        # assign 1 to %sil
        salb    $4, %sil                        # shifts 1 to the 4th bit
        andb    %cl, %sil                       # checks if the 4th bit is 1 or 0
        movb    %sil, 3(%rdi)                   # batt->mode = (BATT_STATUS_PORT >> 4) & 1;
        
        cmpb    $0, %sil                        # if(batt->mode == 0) else if(batt->mode == 1) nothing changes
        je      .Mode                           # jump to mode
        movb    $1, 3(%rdi)                     # batt->mode = 1;
        jmp     .Set                           
.Mode:
        movb    $2, 3(%rdi)                     # batt->mode = 2;
        jmp     .Set                            
.Set:
        cmpb    $0, 2(%rdi)                     # if(batt->percent <= 0)
        jle     .Percent0                       # jump to Percent0
        cmpb    $100, 2(%rdi)                   # if(batt->percent >= 100)
        jge     .Percent100                     # jump to percent100

        cmpw    $3000, 0(%rdi)                  # if(batt->voltage <= 3000)
        jle     .Percent0                       # jump to Percent0
        cmpw    $3800, 0(%rdi)                  # if(batt->voltage >= 3800)
        jge     .Percent100                     # jump to Percent100
        jmp     .Passed
.Percent0:
        movb    $0, 2(%rdi)                     # batt->percent = 0;
        jmp     .Passed
.Percent100:
        movb    $100, 2(%rdi)                   # batt->percent = 100;
        jmp     .Passed
.Passed:
        movl    $0, %eax                        # Assign return value as 0
        ret
.Failed:
        movl    $1, %eax                        # Assign return value as 1
        ret


### Change to definint semi-global variables used with the next function 
### via the '.data' directive
.data
	
#my_int:                                         # declare location an single integer named 'my_int'
        #.int 1234                               # value 1234

#other_int:                                      # declare another int accessible via name 'other_int'
        #.int 0b0101                             # binary value as per C

my_array:                                       # declare multiple ints sequentially starting at location
        .int 0b0111111                          # 'my_array' for an array. Each are spaced 4 bytes from the
        .int 0b0000110                          # next and can be given values using the same prefixes as 
        .int 0b1011011                          # are understood by gcc.
        .int 0b1001111
        .int 0b1100110
        .int 0b1101101
        .int 0b1111101
        .int 0b0000111
        .int 0b1111111
        .int 0b1101111


## WARNING: Don't forget to switch back to .text as below
## Otherwise you may get weird permission errors when executing 
.text
.global  set_display_from_batt

## ENTRY POINT FOR REQUIRED FUNCTION
set_display_from_batt:  
        movl    $0, (%rsi)                      # set *display to 0
        movq    %rdi, %r8                       # int volts = batt.mlvolts
        andq    $0xFFFF, %r8                    # ------------------------
        movq    %rdi, %rcx                      # int percent = batt.percent;
        sarq    $16, %rcx                       # --------------------------
        andq    $0xFF, %rcx                     # --------------------------
        movq    %rdi, %r13                      # mode
        sarq    $24, %r13                       # ---------
        andq    $0xFF, %r13                     # ---------
        leaq    my_array(%rip), %r14

        cmpq    $1, %r13                        # compare batt.mode to 1
        je      .ModeP                          # jump to ModeP if batt.mode = 1
        cmpq    $2, %r13                        # compare batt.mode to 2
        je      .RoundUp                        # jump to ModeV if batt.mode = 2
        jmp     .NotDone                        # jump to not done if batt.mode is neither 1 or 2
.AddTen:
        addq    $10, %r8                        # add 10 to volts
        jmp     .ModeV
.RoundUp:
        movq    %r8, %rax                       # assings 10 to rax is the modulo
        cqto
        movq    $10, %r9                        # assings 10 to r9 which will be idiv from
        idivq   %r9                             # idiv volts
        cmpq    $5, %rdx                        # if(volts%10 > 5)                      
        jg      .AddTen
        jmp     .ModeV
.ModeV:
        movq    %r8, %rax                       # assings volts to rax is the modulo
        cqto
        movq    $10, %r9                        # assings 10 to r9 which will be idiv from
        idivq   %r9                             # idiv volts
        movq    %rax, %r8                       # r8 is now rax

        cqto
        movq    $10, %r9                        # assings 10 to r9 which will be idiv from
        idivq   %r9                             # idiv volts
        movl    (%r14, %rdx, 4), %r10d          # right is assign to the arr[rdx]
        movq    %rax, %r8                       # r8 is now rax

        cqto
        movq    $10, %r9                        # assings 10 to r9 which will be idiv from
        idivq   %r9                             # idiv volts
        movl    (%r14, %rdx, 4), %r11d          # middle is assign to the arr[rdx]
        movq    %rax, %r8                       # r8 is now rax

        cqto
        movq    $10, %r9                        # assings 10 to r9 which will be idiv from
        idivq   %r9                             # idiv volts
        movl    (%r14, %rdx, 4), %r12d          # left is assign to the arr[rdx]
        movq    %rax, %r8                       # r8 is now rax

        movl    $1, %edx
        sall    $2, %edx
        orl     %edx, (%rsi)                    #  *display = *display | (1 << 2)
        movl    $1, %edx
        sall    $1, %edx
        orl     %edx, (%rsi)                    #  *display = *display | (1 << 1)

        jmp     .Display
.ModeP:
        cmpq    $100, %rcx                      # compare percent to 100
        je     .Pis100                          # if equals go to Pis100

        movl    $0, %r12d                       # left is blank

        cmpq    $10, %rcx                       # compare percent to 10
        jl      .Pless10                        # jump to Pless10

        movq    %rcx, %rax                      # assings percent to rax is the modulo
        cqto
        movq    $10, %r9                        # assings 10 to r9 which will be idiv from
        idivq   %r9                             # idiv percent
        movl    (%r14, %rdx, 4), %r10d          # right is assinged
        movq    %rax, %rcx

        cqto
        movq    $10, %r9                        # assings 10 to r9 which will be idiv from
        idivq   %r9                             # idiv percent
        movl    (%r14, %rdx, 4), %r11d          # middle is assinged

        movl    $1, %edx
        sall    $0, %edx
        orl     %edx, (%rsi)                    # *display = *display | (1 << 0);

        jmp     .Display
.Pis100:
        movq    $0, %rdx
        movl    (%r14, %rdx, 4), %r10d          # %r10d is 0
        movq    $0, %rdx
        movl    (%r14, %rdx, 4), %r11d          # %r11d is 0
        movq    $1, %rdx
        movl    (%r14, %rdx, 4), %r12d          # %r12d is 1

        movl    $1, %edx
        sall    $0, %edx
        orl     %edx, (%rsi)                    # *display = *display | (1 << 0);

        jmp     .Display
.Pless10:
        movl    $0, %r11d                       # middle is blank
        movl    (%r14, %rcx, 4), %r10d          # right is percent

        movl    $1, %edx
        sall    $0, %edx
        orl     %edx, (%rsi)                     # *display = *display | (1 << 0);

        jmp     .Display
.Display:
        sall    $3, %r10d                        # right << 3
        orl     %r10d, (%rsi)                     # *display = *display | (right << 3)

        sall    $10, %r11d                       # middle << 10
        orl     %r11d, (%rsi)                     #*display = *display | (middle << 10)

        sall    $17, %r12d                       # left << 17
        orl     %r12d, (%rsi)                     #*display = *display | (left << 17)

        jmp     .Insert
.Insert:    
        movq    %rdi, %rcx                       # int percent = batt.percent
        sarq    $16, %rcx                        # --------------------------
        andq    $0xFF, %rcx                      # --------------------------

        cmpq    $90, %rcx                        # compare percent to 90
        jl      .4thBar

        movl    $0b11111, %edx
        sall    $24, %edx
        orl     %edx, (%rsi)                     # *display = *display | (0b11111 << 24);
        jmp     .Done
.4thBar:
        cmpq    $70, %rcx                        # compare percent to 70
        jl      .3rdBar

        movl    $0b1111, %edx
        sall    $24, %edx
        orl     %edx, (%rsi)                     # *display = *display | (0b1111 << 24);
        jmp     .Done
.3rdBar:
        cmpq    $50, %rcx                        # compare percent to 50
        jl      .2ndBard

        movl    $0b111, %edx
        sall    $24, %edx                        # *display = *display | (0b111 << 24);
        orl     %edx, (%rsi)
        jmp     .Done
.2ndBard:
        cmpq    $30, %rcx                        # compare percent to 30
        jl      .1stBar

        movl    $0b11, %edx
        sall    $24, %edx
        orl     %edx, (%rsi)                     # *display = *display | (0b11 << 24);
        jmp     .Done
.1stBar:
        cmpq    $5, %rcx                         # compare percent to 5
        jl      .Done

        movl    $0b1, %edx
        sall    $24, %edx
        orl     %edx, (%rsi)                     # *display = *display | (1 << 24);
        jmp     .Done
.Done:
        movq    $0, %rax
        ret
.NotDone:
        movq    $1, %rax
        ret

        ## two useful techniques for this problem
        #movl    my_int(%rip),%eax    # load my_int into register eax
        #leaq    my_array(%rip),%rdx  # load pointer to beginning of my_array into rdx


.text
.global batt_update
        
## ENTRY POINT FOR REQUIRED FUNCTION
batt_update:
 	## assembly instructions here
        subq    $8, %rsp                        # batt_t batt = {}

        leaq    (%rsp), %rdi                    # &batt
        call    set_batt_from_ports             # set_batt_from_ports(&batt)
        cmpq    $1, %rax                        # (set_batt_from_ports(&batt) == 1)
        je      .TestF                          # Jump to failed

        movq    (%rsp), %rdi                       # batt
        leaq    BATT_DISPLAY_PORT(%rip), %rsi      # &BATT_DISPLAY_PORT
        call    set_display_from_batt              # set_display_from_batt(batt, &BATT_DISPLAY_PORT);

        addq    $8, %rsp
        ret
.TestF:
        addq    $8, %rsp
        ret