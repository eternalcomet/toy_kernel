
out/bootblock.o:     file format elf32-i386


Disassembly of section .text:

00007c00 <start>:
    7c00:	fa                   	cli    
    7c01:	31 c0                	xor    %eax,%eax
    7c03:	8e d8                	mov    %eax,%ds
    7c05:	8e c0                	mov    %eax,%es
    7c07:	8e d0                	mov    %eax,%ss

00007c09 <seta20.1>:
    7c09:	e4 64                	in     $0x64,%al
    7c0b:	a8 02                	test   $0x2,%al
    7c0d:	75 fa                	jne    7c09 <seta20.1>
    7c0f:	b0 d1                	mov    $0xd1,%al
    7c11:	e6 64                	out    %al,$0x64

00007c13 <seta20.2>:
    7c13:	e4 64                	in     $0x64,%al
    7c15:	a8 02                	test   $0x2,%al
    7c17:	75 fa                	jne    7c13 <seta20.2>
    7c19:	b0 df                	mov    $0xdf,%al
    7c1b:	e6 60                	out    %al,$0x60

00007c1d <probe_memory>:
    7c1d:	66 c7 06 00 80       	movw   $0x8000,(%esi)
    7c22:	00 00                	add    %al,(%eax)
    7c24:	00 00                	add    %al,(%eax)
    7c26:	66 31 db             	xor    %bx,%bx
    7c29:	bf                   	.byte 0xbf
    7c2a:	04 80                	add    $0x80,%al

00007c2c <start_probe>:
    7c2c:	66 b8 20 e8          	mov    $0xe820,%ax
    7c30:	00 00                	add    %al,(%eax)
    7c32:	66 b9 14 00          	mov    $0x14,%cx
    7c36:	00 00                	add    %al,(%eax)
    7c38:	66 ba 50 41          	mov    $0x4150,%dx
    7c3c:	4d                   	dec    %ebp
    7c3d:	53                   	push   %ebx
    7c3e:	cd 15                	int    $0x15
    7c40:	73 08                	jae    7c4a <cont>
    7c42:	c7 06 00 80 39 30    	movl   $0x30398000,(%esi)
    7c48:	eb 0e                	jmp    7c58 <finish_probe>

00007c4a <cont>:
    7c4a:	83 c7 14             	add    $0x14,%edi
    7c4d:	66 ff 06             	incw   (%esi)
    7c50:	00 80 66 83 fb 00    	add    %al,0xfb8366(%eax)
    7c56:	75 d4                	jne    7c2c <start_probe>

00007c58 <finish_probe>:
    7c58:	0f 01 16             	lgdtl  (%esi)
    7c5b:	b4 7c                	mov    $0x7c,%ah
    7c5d:	0f 20 c0             	mov    %cr0,%eax
    7c60:	66 83 c8 01          	or     $0x1,%ax
    7c64:	0f 22 c0             	mov    %eax,%cr0
    7c67:	ea                   	.byte 0xea
    7c68:	6c                   	insb   (%dx),%es:(%edi)
    7c69:	7c 08                	jl     7c73 <start32+0x7>
	...

00007c6c <start32>:
    7c6c:	66 b8 10 00          	mov    $0x10,%ax
    7c70:	8e d8                	mov    %eax,%ds
    7c72:	8e c0                	mov    %eax,%es
    7c74:	8e d0                	mov    %eax,%ss
    7c76:	66 b8 00 00          	mov    $0x0,%ax
    7c7a:	8e e0                	mov    %eax,%fs
    7c7c:	8e e8                	mov    %eax,%gs
    7c7e:	bc 00 7c 00 00       	mov    $0x7c00,%esp
    7c83:	e8 e5 00 00 00       	call   7d6d <bootmain>
    7c88:	66 b8 00 8a          	mov    $0x8a00,%ax
    7c8c:	66 89 c2             	mov    %ax,%dx
    7c8f:	66 ef                	out    %ax,(%dx)
    7c91:	66 b8 e0 8a          	mov    $0x8ae0,%ax
    7c95:	66 ef                	out    %ax,(%dx)

00007c97 <spin>:
    7c97:	eb fe                	jmp    7c97 <spin>
    7c99:	8d 76 00             	lea    0x0(%esi),%esi

00007c9c <gdt>:
	...
    7ca4:	ff                   	(bad)  
    7ca5:	ff 00                	incl   (%eax)
    7ca7:	00 00                	add    %al,(%eax)
    7ca9:	9a cf 00 ff ff 00 00 	lcall  $0x0,$0xffff00cf
    7cb0:	00                   	.byte 0x0
    7cb1:	92                   	xchg   %eax,%edx
    7cb2:	cf                   	iret   
	...

00007cb4 <gdtdesc>:
    7cb4:	17                   	pop    %ss
    7cb5:	00                   	.byte 0x0
    7cb6:	9c                   	pushf  
    7cb7:	7c 00                	jl     7cb9 <gdtdesc+0x5>
	...

00007cba <waitdisk>:
    7cba:	ba f7 01 00 00       	mov    $0x1f7,%edx
    7cbf:	ec                   	in     (%dx),%al
    7cc0:	83 e0 c0             	and    $0xffffffc0,%eax
    7cc3:	3c 40                	cmp    $0x40,%al
    7cc5:	75 f8                	jne    7cbf <waitdisk+0x5>
    7cc7:	c3                   	ret    

00007cc8 <readsect>:
    7cc8:	57                   	push   %edi
    7cc9:	53                   	push   %ebx
    7cca:	8b 5c 24 10          	mov    0x10(%esp),%ebx
    7cce:	e8 e7 ff ff ff       	call   7cba <waitdisk>
    7cd3:	b8 01 00 00 00       	mov    $0x1,%eax
    7cd8:	ba f2 01 00 00       	mov    $0x1f2,%edx
    7cdd:	ee                   	out    %al,(%dx)
    7cde:	ba f3 01 00 00       	mov    $0x1f3,%edx
    7ce3:	89 d8                	mov    %ebx,%eax
    7ce5:	ee                   	out    %al,(%dx)
    7ce6:	89 d8                	mov    %ebx,%eax
    7ce8:	c1 e8 08             	shr    $0x8,%eax
    7ceb:	ba f4 01 00 00       	mov    $0x1f4,%edx
    7cf0:	ee                   	out    %al,(%dx)
    7cf1:	89 d8                	mov    %ebx,%eax
    7cf3:	c1 e8 10             	shr    $0x10,%eax
    7cf6:	ba f5 01 00 00       	mov    $0x1f5,%edx
    7cfb:	ee                   	out    %al,(%dx)
    7cfc:	89 d8                	mov    %ebx,%eax
    7cfe:	c1 e8 18             	shr    $0x18,%eax
    7d01:	83 c8 e0             	or     $0xffffffe0,%eax
    7d04:	ba f6 01 00 00       	mov    $0x1f6,%edx
    7d09:	ee                   	out    %al,(%dx)
    7d0a:	b8 20 00 00 00       	mov    $0x20,%eax
    7d0f:	ba f7 01 00 00       	mov    $0x1f7,%edx
    7d14:	ee                   	out    %al,(%dx)
    7d15:	e8 a0 ff ff ff       	call   7cba <waitdisk>
    7d1a:	8b 7c 24 0c          	mov    0xc(%esp),%edi
    7d1e:	b9 80 00 00 00       	mov    $0x80,%ecx
    7d23:	ba f0 01 00 00       	mov    $0x1f0,%edx
    7d28:	fc                   	cld    
    7d29:	f3 6d                	rep insl (%dx),%es:(%edi)
    7d2b:	5b                   	pop    %ebx
    7d2c:	5f                   	pop    %edi
    7d2d:	c3                   	ret    

00007d2e <readseg>:
    7d2e:	57                   	push   %edi
    7d2f:	56                   	push   %esi
    7d30:	53                   	push   %ebx
    7d31:	8b 5c 24 10          	mov    0x10(%esp),%ebx
    7d35:	8b 74 24 18          	mov    0x18(%esp),%esi
    7d39:	89 df                	mov    %ebx,%edi
    7d3b:	03 7c 24 14          	add    0x14(%esp),%edi
    7d3f:	89 f0                	mov    %esi,%eax
    7d41:	25 ff 01 00 00       	and    $0x1ff,%eax
    7d46:	29 c3                	sub    %eax,%ebx
    7d48:	c1 ee 09             	shr    $0x9,%esi
    7d4b:	83 c6 01             	add    $0x1,%esi
    7d4e:	39 df                	cmp    %ebx,%edi
    7d50:	76 17                	jbe    7d69 <readseg+0x3b>
    7d52:	56                   	push   %esi
    7d53:	53                   	push   %ebx
    7d54:	e8 6f ff ff ff       	call   7cc8 <readsect>
    7d59:	81 c3 00 02 00 00    	add    $0x200,%ebx
    7d5f:	83 c6 01             	add    $0x1,%esi
    7d62:	83 c4 08             	add    $0x8,%esp
    7d65:	39 df                	cmp    %ebx,%edi
    7d67:	77 e9                	ja     7d52 <readseg+0x24>
    7d69:	5b                   	pop    %ebx
    7d6a:	5e                   	pop    %esi
    7d6b:	5f                   	pop    %edi
    7d6c:	c3                   	ret    

00007d6d <bootmain>:
    7d6d:	57                   	push   %edi
    7d6e:	56                   	push   %esi
    7d6f:	53                   	push   %ebx
    7d70:	6a 00                	push   $0x0
    7d72:	68 00 20 00 00       	push   $0x2000
    7d77:	68 00 00 01 00       	push   $0x10000
    7d7c:	e8 ad ff ff ff       	call   7d2e <readseg>
    7d81:	83 c4 0c             	add    $0xc,%esp
    7d84:	b8 00 00 01 00       	mov    $0x10000,%eax
    7d89:	eb 0a                	jmp    7d95 <bootmain+0x28>
    7d8b:	83 c0 04             	add    $0x4,%eax
    7d8e:	3d 00 20 01 00       	cmp    $0x12000,%eax
    7d93:	74 35                	je     7dca <bootmain+0x5d>
    7d95:	8d 88 00 00 ff ff    	lea    -0x10000(%eax),%ecx
    7d9b:	89 c3                	mov    %eax,%ebx
    7d9d:	81 38 02 b0 ad 1b    	cmpl   $0x1badb002,(%eax)
    7da3:	75 e6                	jne    7d8b <bootmain+0x1e>
    7da5:	8b 50 08             	mov    0x8(%eax),%edx
    7da8:	03 50 04             	add    0x4(%eax),%edx
    7dab:	81 fa fe 4f 52 e4    	cmp    $0xe4524ffe,%edx
    7db1:	75 d8                	jne    7d8b <bootmain+0x1e>
    7db3:	f6 40 06 01          	testb  $0x1,0x6(%eax)
    7db7:	74 11                	je     7dca <bootmain+0x5d>
    7db9:	8b 40 10             	mov    0x10(%eax),%eax
    7dbc:	8b 53 0c             	mov    0xc(%ebx),%edx
    7dbf:	39 d0                	cmp    %edx,%eax
    7dc1:	77 07                	ja     7dca <bootmain+0x5d>
    7dc3:	8b 73 14             	mov    0x14(%ebx),%esi
    7dc6:	39 f0                	cmp    %esi,%eax
    7dc8:	76 04                	jbe    7dce <bootmain+0x61>
    7dca:	5b                   	pop    %ebx
    7dcb:	5e                   	pop    %esi
    7dcc:	5f                   	pop    %edi
    7dcd:	c3                   	ret    
    7dce:	01 c1                	add    %eax,%ecx
    7dd0:	29 d1                	sub    %edx,%ecx
    7dd2:	51                   	push   %ecx
    7dd3:	29 c6                	sub    %eax,%esi
    7dd5:	56                   	push   %esi
    7dd6:	50                   	push   %eax
    7dd7:	e8 52 ff ff ff       	call   7d2e <readseg>
    7ddc:	8b 4b 18             	mov    0x18(%ebx),%ecx
    7ddf:	8b 43 14             	mov    0x14(%ebx),%eax
    7de2:	83 c4 0c             	add    $0xc,%esp
    7de5:	39 c1                	cmp    %eax,%ecx
    7de7:	76 0c                	jbe    7df5 <bootmain+0x88>
    7de9:	29 c1                	sub    %eax,%ecx
    7deb:	89 c7                	mov    %eax,%edi
    7ded:	b8 00 00 00 00       	mov    $0x0,%eax
    7df2:	fc                   	cld    
    7df3:	f3 aa                	rep stos %al,%es:(%edi)
    7df5:	ff 53 1c             	call   *0x1c(%ebx)
    7df8:	eb d0                	jmp    7dca <bootmain+0x5d>
