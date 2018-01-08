# BA2-toolchain
clone from GravisZro/BA2-toolchain.  GCC toolchain for the "Beyond Architecture 2" CPU which is used in the NXP JN516x chip series

## 环境搭建
安装下面软件：
> sudo apt install gawk wget git-core diffstat unzip texinfo gcc-multilib \
     build-essential chrpath socat cpio python python3 python3-pip python3-pexpect \
     xz-utils debianutils iputils-ping libsdl1.2-dev flex bison libncurses5-dev automake autoconf libftdi-dev
    
## 错误及其解决：
### 错误1：
```cpp
bfd.h:529:65: error: right-hand operand of comma expression has no effect [-Werror=unused-value]
#define bfd_set_cacheable(abfd,bool) (((abfd)->cacheable = bool), TRUE)
^
opncls.c:263:5: note: in expansion of macro 'bfd_set_cacheable'
bfd_set_cacheable (nbfd, TRUE);
^
```
可以再config后面加上`--disable-werror`
