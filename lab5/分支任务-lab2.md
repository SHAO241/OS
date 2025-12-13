# 实验目的
1. 深入的对比模拟器的实现，充分理解一下整个地址翻译的过程
2. 培养使用大模型的能力，利用大模型提高自己学习的效率，真正学到知识

# 准备带调试信息的QEMU
```txt
# 进入QEMU源码目录
cd qemu-4.1.1

# 清理之前的编译结果
make distclean

# 重新配置，这次要带上调试选项
./configure --target-list=riscv32-softmmu,riscv64-softmmu --enable-debug

# 重新编译
make -j$(nproc)
```
这样，系统里就有两个QEMU：一个是我们日常使用的"正式版"，另一个是我们专门用来调试的"调试版"。
# 调试步骤详解
1. 终端1：启动QEMU模拟器
- make debug
2. 终端2：附加调试QEMU进程
- pgrep -f qemu-system-riscv64
得到进程的PID：3007
- sudo gdb
- attach 3007
- ``(gdb) handle SIGPIPE nostop noprint``
handle: GDB的信号处理命令
SIGPIPE: 管道破裂信号
nostop: 当此信号发生时不停止程序执行
noprint: 当此信号发生时不打印提示信息
意义：
QEMU网络连接断开：QEMU可能使用管道与外部工具通信，断开时产生SIGPIPE
串口/控制台通信：ucore通过串口与QEMU通信，如果QEMU端关闭会产生SIGPIPE
避免调试干扰：我们希望调试过程不被这些"正常"的信号中断
- continue
3. 终端3：调试ucore内核
- make gdb
- set remotetimeout unlimited
## 理解qemu的地址翻译源码调用路径
```txt
# 在终端2的GDB中设置断点
(gdb) b *tlb_set_page_with_attrs
(gdb) b get_physical_address
(gdb) b riscv_cpu_tlb_fill
(gdb) c
```

在终端3中让ucore执行到某个访存指令：
```txt
(gdb) b *0x80200000  # 内核入口点
```

在终端2中，我们可以单步跟踪这个流程：
```txt
# 当断点命中后，使用以下命令查看调用栈和代码
(gdb) bt  # 查看调用栈
(gdb) frame  # 查看当前帧
(gdb) list  # 查看源码
(gdb) p/x addr  # 查看当前参数
(gdb) c  # 继续执行到下一个断点
```
我们在QEMU中设置了三个断点，GDB连接后，发送了读内存命令 ``m80200000,40``，想读取内核内存，QEMU需要将这个虚拟地址转换为物理地址，程序执行到了get_physical_address函数（断点2），这个函数是RISC-V CPU进行虚拟地址到物理地址转换的核心函数。
- 地址：addr=2149580800（十六进制：0x80200000）
- 访问类型：access_type=0（MMU_DATA_LOAD，即读操作）
- MMU索引：mmu_idx=3（用户模式读访问）

**调用栈分析：**
```txt
#0 get_physical_address (...)           # 地址转换函数
#1 riscv_cpu_get_phys_page_debug(...)   # 获取物理页（调试用）
#2 cpu_get_phys_page_attrs_debug(...)   # CPU获取物理页属性（调试）
#3 cpu_memory_rw_debug(...)             # CPU内存读写调试接口
#4 target_memory_rw_debug(...)          # 目标架构内存读写调试
#5 handle_read_mem(...)                 # 处理GDB的读内存命令
#6 process_string_cmd(...)              # 处理GDB命令字符串
```
我们在终端2输入``c``继续执行到下一个断点，在终端3也输入``c``，我们遇到断点3，内核在尝试从地址 0x1000（十进制4096）取指令，触发了 TLB缺失异常

**调用栈分析：**
```txt
#0 riscv_cpu_tlb_fill(...)      # TLB填充处理
#1 tlb_fill(...)                # TLB填充通用处理
#2 get_page_addr_code(...)      # 获取代码页地址（取指令）
#3 tb_htable_lookup(...)        # 翻译块查找
#4 tb_lookup__cpu_state(...)    # 基于CPU状态查找翻译块
#5 tb_find(...)                 # 查找翻译块
#6 cpu_exec(...)                # CPU执行循环
#7 tcg_cpu_exec(...)            # TCG CPU执行
```
说明CPU正在启动执行：PC = 0x1000，页表/MMU未设置（TLB中没有0x1000的映射），需要处理TLB缺失。
我们也用指令``p/x $pc``得到当前PC值``0x56d412472619``，用``p/x env->satp``得到页表基址``0x67616c665f79``

继续在终端2输入``c``进行调试，还会遇到断点2，接着会遇到断点1：
进行地址转换时，get_physical_address 被调用，地址是 4096 (0x1000)，由于TLB缺失，tlb_set_page_with_attrs 被调用，为地址 0x1000 建立TLB映射：

利用指令``(gdb)bt``可以看到调用栈，呈现出许多信息,此处显示一部分：
```txt
tlb_set_page(cpu=0x56d4394cb880, 
             vaddr=4096,      # 虚拟地址 0x1000
             paddr=4096,      # 物理地址 0x1000
             prot=7,          # 保护位：可读(4) + 可写(2) + 可执行(1) = 7
             mmu_idx=3,       # MMU索引（用户模式）
             size=4096)       # 页面大小 4KB
```

关键调用路径（在QEMU-4.1.1中）：
- cpu_exec -> 执行指令的主循环
- riscv_tr_translate_insn -> 指令翻译;
对于访存指令：tcg_gen_qemu_ld_tl -> 生成加载操作码
- tlb_vaddr_to_host -> 尝试通过TLB获取主机地址;
如果TLB未命中：riscv_cpu_tlb_fill -> TLB填充
- get_physical_address -> 获取物理地址
- 遍历页表：pmp_hart_has_privs -> paddr_accepts -> riscv_cpu_get_phys_page_debug



## 单步调试页表翻译流程
### 阶段 1：准备调试环境
步骤 1：在终端 2 设置 QEMU 页表翻译相关断点
```
# 附加到QEMU进程后
# ===== 关键断点：页表翻译相关函数 =====

# 1. TLB查找和页表遍历的入口
(gdb) break riscv_cpu_tlb_fill
(gdb) break get_page_addr_code
(gdb) break get_page_addr_code_hostp

# 2. 页表遍历相关函数
(gdb) break riscv_cpu_get_phys_page_debug
(gdb) break get_physical_address  

# 3. 内存访问相关
(gdb) break cpu_riscv_translate_address
(gdb) break riscv_cpu_do_transaction_failed

# 设置条件断点：只关注虚拟地址0xffffffffc0000000附近
(gdb) break get_page_addr_code if addr >= 0xffffffffc0000000 && addr < 0xffffffffc0100000

# 继续执行
(gdb) continue
```
步骤 2：在终端 3 设置 ucore 内核断点
```
# 设置断点在关键位置
(gdb) break kern_entry
(gdb) break *0xffffffffc0200034  # csrw satp, t0 的地址
(gdb) break *0xffffffffc0200038  # sfence.vma 的地址
(gdb) break *0xffffffffc0200040  # lui sp, %hi(bootstacktop) - 第一条使用虚拟地址的指令

(gdb) continue
```
### 阶段 2：单步调试页表翻译过程
步骤 3：触发页表翻译
在终端 3 的 GDB 中：
```
# 执行到kern_entry
(gdb) continue

# 单步执行到设置satp之前，观察此时的状态
(gdb) stepi
(gdb) stepi
# ... 执行到第29行 csrw satp, t0

# 查看satp的值
(gdb) print/x $t0

# 执行csrw satp, t0
(gdb) stepi

# 执行sfence.vma（刷新TLB）
(gdb) stepi

# 现在执行第36行：lui sp, %hi(bootstacktop)
# 这条指令本身不会触发访存，但下一条指令会
(gdb) stepi

# 执行第40-42行：跳转到kern_init（这会触发指令访存，需要页表翻译）
(gdb) stepi  # lui t0, %hi(kern_init)
(gdb) stepi  # addi t0, t0, %lo(kern_init)
(gdb) stepi  # jr t0 - 这条指令会触发页表翻译！
```
步骤 4：在终端 2 观察页表翻译过程
当 jr t0 执行时，终端 2 的断点会触发：
```
# 当断点触发时，查看调用栈
(gdb) bt
(gdb) bt full

# 查看当前帧的信息
(gdb) frame 0
(gdb) info args
(gdb) info locals

# ===== 关键：查看虚拟地址 =====
(gdb) print/x addr

# ===== 关键：查看satp寄存器 =====
(gdb) print/x cpu->env.satp
(gdb) print/x (cpu->env.satp >> 60)  # MODE字段，8
(gdb) print/x ((cpu->env.satp << 4) >> 16)  # PPN字段，页表基址

# ===== 关键：查看TLB状态 =====
(gdb) print cpu->env.tlb_table[0][0]
(gdb) print cpu->env.tlb_table[0][1]
```
步骤 5：单步执行页表遍历
```
# 继续单步执行，观察页表遍历过程
(gdb) step
(gdb) list  # 查看当前代码

# 如果进入riscv_cpu_tlb_fill函数，这是TLB miss处理
(gdb) step
(gdb) info locals

# ===== 关键：观察虚拟地址分解 =====
# 在QEMU代码中，看到VPN的提取
(gdb) print/x vaddr
(gdb) print/x (vaddr >> 30) & 0x1FF  # VPN2
(gdb) print/x (vaddr >> 21) & 0x1FF  # VPN1  
(gdb) print/x (vaddr >> 12) & 0x1FF  # VPN0

# ===== 关键：观察页表遍历 =====
# 第一级页表（PT2）查找
(gdb) step
(gdb) print/x pte_addr  # 页表项地址
(gdb) print/x pte       # 页表项内容

# 第二级页表（PT1）查找
(gdb) step
(gdb) print/x pte_addr
(gdb) print/x pte

# 第三级页表（PT0）查找
(gdb) step
(gdb) print/x pte_addr
(gdb) print/x pte

# ===== 关键：观察最终物理地址计算 =====
(gdb) step
(gdb) print/x phys_addr  # 最终物理地址
(gdb) print/x (phys_addr >> 12)  # 物理页号
```

关键操作流程解释
1. 虚拟地址分解
```
虚拟地址：0xffffffffc0200048
         └─┬─┘└─┬─┘└─┬─┘└──┬──┘
         VPN2 VPN1 VPN0 Offset
         511   0    0   0x48
```
2. 三级页表遍历
步骤1：PT2查找  
- 页表基址 = satp.PPN << 12  
- PT2索引 = VPN2 = 511  
- PT2项地址 = 页表基址 + 511 * 8  
- 读取PTE2 = 0x800000cf  
- PPN[2] = 0x80000

步骤2：由于是1GB大页，直接使用PPN[2]  
- 物理地址 = PPN[2] << 30 + Offset  
- 物理地址 = 0x80000000 + 0x48 = 0x80000048

3. TLB 填充

``(gdb) print cpu->env.tlb_table[mmu_idx][index]``
TLB条目包含：
- 虚拟页号 
- 物理页号  
- 权限标志



## 查找TLB模拟代码

QEMU的TLB：是软件数据结构，用于加速虚拟机的地址转换
CPU硬件TLB：是物理CPU中的缓存，存储页表条目

在终端2的GDB中,我们询问大模型TLB相关的函数并将其设为断点：
```txt
# 设置关键断点
(gdb) break get_page_addr_code
(gdb) break tlb_vaddr_to_host
(gdb) break riscv_cpu_tlb_fill

# 设置条件断点（只关注特定地址范围）
(gdb) break get_page_addr_code if addr >= 0x80000000 && addr < 0x88000000

# 继续执行
(gdb) continue

# 当断点触发时
(gdb) bt
(gdb) frame 0
(gdb) print addr
(gdb) print mmu_idx
(gdb) info locals
(gdb) step
```
执行后就知道这些函数的位置，TLB查找的关键代码是：
1. accel/tcg/cputlb.c (约 200-400 行)
get_page_addr_code() - 指令访存的 TLB 查找
tlb_vaddr_to_host() - 虚拟地址转换

2. target/riscv/cpu_helper.c
riscv_cpu_tlb_fill() - TLB miss 处理

3. accel/tcg/translate-all.c
调用 get_page_addr_code() 的地方

## 对比虚拟地址开启前后的调用路径
**QEMU 模拟 TLB 与真实 CPU TLB 的逻辑区别**
1. 真实 CPU 的 TLB
- 硬件实现，在 MMU 中
- TLB miss 触发硬件异常，由操作系统处理
- 地址转换由硬件完成
2. QEMU 模拟的 TLB
- 软件实现，在 QEMU 的 TCG 中
- 两层结构：
QEMU 软件 TLB（加速翻译）
模拟的硬件 TLB 行为（触发异常等）
- 未开启虚拟地址时可能走直接映射路径

### 阶段 1：调试未开启虚拟地址空间的访存（Bare 模式）
在 entry.S 中，csrw satp, t0（第29行）之前，CPU 处于 Bare 模式（MODE=0）。
步骤 1：在终端 2 的 GDB 中设置断点
```txt
# 附加到QEMU进程后
(gdb) handle SIGPIPE nostop noprint

# 设置关键断点 - Bare模式下的访存路径
(gdb) break get_page_addr_code
(gdb) break get_page_addr_code_hostp
(gdb) break tlb_vaddr_to_host

# 设置条件断点：只关注0x80000000附近的访存（ucore启动地址）
(gdb) break get_page_addr_code if addr >= 0x80000000 && addr < 0x80200000

# 查看satp寄存器相关的处理
(gdb) break riscv_cpu_get_phys_page_debug
(gdb) break helper_sret  # 如果QEMU有处理satp的helper函数

# 继续执行
(gdb) continue
```
步骤 2：在终端 3 的 GDB 中触发 Bare 模式的访存
```
# 设置断点在kern_entry开始处（此时还未设置satp）
(gdb) break kern_entry
(gdb) continue

# 单步执行到第10行（la t0, boot_hartid），这是一条访存指令
(gdb) stepi
(gdb) stepi  # 继续单步，观察访存
```
步骤 3：在终端 2 观察 Bare 模式的调用路径
当断点触发时：
```txt
# 查看完整调用栈
(gdb) bt
(gdb) bt full

# 查看关键参数
(gdb) frame 0
(gdb) print addr
(gdb) print mmu_idx
(gdb) info locals

# 查看satp寄存器状态（应该为0，表示Bare模式）
(gdb) print cpu->env.satp
(gdb) print (cpu->env.satp >> 60)  # 查看MODE字段

# 单步执行，观察路径
(gdb) step(gdb) list  # 查看当前代码
```
观察到：
get_page_addr_code() 直接返回物理地址，不经过页表查找

### 阶段 2：调试开启虚拟地址空间后的访存（Sv39 模式）
在 csrw satp, t0（第29行）之后，CPU 进入 Sv39 模式。
步骤 4：在终端 2 设置 Sv39 模式的断点
```
# 清除之前的断点
(gdb) delete

# 设置Sv39模式下的关键断点
(gdb) break get_page_addr_code
(gdb) break riscv_cpu_tlb_fill
(gdb) break get_page_addr_code_hostp

# 设置条件：关注虚拟地址0xffffffffc0200000附近
(gdb) break get_page_addr_code if addr >= 0xffffffffc0000000

# 设置断点在satp寄存器写入时
(gdb) break riscv_cpu_write_mstatus 
(gdb) break helper_csrrw  # CSR寄存器写入的helper

# 继续执行
(gdb) continue
```
步骤 5：在终端 3 触发 Sv39 模式的访存
```
# 在终端3的GDB中，继续执行到设置satp之后
(gdb) break *0xffffffffc0200034  # csrw satp, t0的地址
(gdb) continue

# 执行完satp设置后，继续执行
(gdb) stepi
(gdb) stepi  # 执行sfence.vma
(gdb) stepi  # 执行下一条指令，此时会使用虚拟地址访存
```
步骤 6：在终端 2 观察 Sv39 模式的调用路径
当断点触发时：
```
# 查看调用栈（应该更复杂）
(gdb) bt
(gdb) bt full

# 查看关键信息
(gdb) frame 0
(gdb) print addr  # 虚拟地址，如0xffffffffc020xxxx
(gdb) print mmu_idx
(gdb) print cpu->env.satp
(gdb) print (cpu->env.satp >> 60)  # 8（Sv39模式）

# 查看TLB表
(gdb) print cpu->env.tlb_table[mmu_idx][0]
(gdb) print cpu->env.tlb_table[mmu_idx][1]

# 单步执行，观察TLB查找过程
(gdb) step
(gdb) list
```
观察到：
调用栈包含 TLB 查找和页表遍历，可能触发 riscv_cpu_tlb_fill()（TLB miss 处理），需要访问页表进行地址转换

### 阶段 3：对比分析
步骤 7：记录并对比两种模式的差异
在终端 2 的 GDB 中，分别记录两种情况：
```txt
# 对于Bare模式，记录：
(gdb) info registers
(gdb) print *cpu
(gdb) x/10i $pc

# 对于Sv39模式，记录：
(gdb) info registers  
(gdb) print *cpu
(gdb) print cpu->env.tlb_table
(gdb) x/10i $pc
```
关键代码位置（QEMU-4.1.1）

在 QEMU 源码中查找以下函数：
1. accel/tcg/cputlb.c
get_page_addr_code() - 代码页地址获取
tlb_vaddr_to_host() - 虚拟地址到主机地址转换
tlb_fill() - TLB 填充

2. target/riscv/cpu_helper.c
riscv_cpu_get_phys_page_debug() - 获取物理页
riscv_cpu_tlb_fill() - RISC-V TLB miss 处理

3. target/riscv/translate.c 
helper_sret()
CSR 写入处理

**观察到的区别**

Bare 模式（未开启虚拟地址）
- 调用路径：get_page_addr_code()   -> 直接检查地址范围  -> 可能直接返回物理地址  -> 不涉及TLB查找

Sv39 模式（开启虚拟地址）
- 调用路径：get_page_addr_code()  -> 检查QEMU软件TLB  -> TLB miss时调用 riscv_cpu_tlb_fill()  -> 遍历页表（walk_page_table）  -> 填充TLB条目  -> 返回转换后的地址

