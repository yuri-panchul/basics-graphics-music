#!/usr/bin/env bash
export PATH=$PATH:"/c/Program Files/qemu"

qemu-system-riscv32 \
  -M none,memory-backend=ram0 \
  -object memory-backend-ram,id=ram0,size=8K \
  -cpu rv32,m=false,zawrs=false,zfa=false,a=false,f=false,d=false,c=false,zicsr=true,priv_spec=v1.12.0,mmu=false,pmp=false \
  -bios none \
  -device loader,file=run/final,force-raw=on\
  -nographic \
  -d in_asm,int,guest_errors \
  -D qemu.log \
  -s -S