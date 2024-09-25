## Debug过程
直接make qemu就可以直接运行。如果需要debug，首先在一个terminal里执行make debug，相当于开一个debug端口。然后打开另一个terminal，执行make gdb。
单步执行，即可逐步观察从上电到执行应用程序的全过程。Debug过程不难，重在理解