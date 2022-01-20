#!/bin/python
import textwrap
import sys
ip0 = sys.argv[1].split(".")
ip1 = sys.argv[2].split(".")
sm0 = ip0[len(ip0)-1].split("/")[1]
sm1 = ip1[len(ip1)-1].split("/")[1]
ip0 = ip0[:len(ip0)-1]+[ip0[len(ip0)-1].split("/")[0]]
ip1 = ip1[:len(ip1)-1]+[ip1[len(ip1)-1].split("/")[0]]

sb0 = textwrap.wrap("1"*int(sm0)+"0"*(32-int(sm0)),8)
sb1 = textwrap.wrap("1"*int(sm1)+"0"*(32-int(sm1)),8)
print(sm0,ip0,sb0)
print(sm1,ip1,sb1)

#if sb0 == sb1:
#    return 0
#else:
#    return 1

for i in range(len(sb0)):
    print(bin(int(sb0[i],base=2) & int(ip0[i])),end=' ')
    print(bin(int(sb1[i],base=2) & int(ip1[i])),end=' ')
    if not int(sb0[i],base=2) & int(ip0[i]) == int(sb1[i],base=2) & int(ip1[i]):
        print("no stessa sottorete")
        exit(1)
print("stessa sottorete")
exit(0)
