"""Convert the generated artwork to legacy DXT5 with a complete mip chain."""
from pathlib import Path
from io import BytesIO
import struct
from PIL import Image
root=Path(__file__).resolve().parents[1]
image=Image.open(root/'art/stone-source.png').convert('RGBA')
levels=[]
for i in range(10):
    buffer=BytesIO()
    image.resize((512>>i,512>>i),Image.Resampling.LANCZOS).save(buffer,format='DDS',pixel_format='DXT5')
    levels.append(buffer.getvalue())
header=bytearray(levels[0][:128])
struct.pack_into('<I',header,8,struct.unpack_from('<I',header,8)[0]|0x20000)
struct.pack_into('<I',header,20,len(levels[0])-128)
struct.pack_into('<I',header,28,len(levels))
struct.pack_into('<I',header,88,0)
struct.pack_into('<I',header,108,0x1000|0x8|0x400000)
payload=bytes(header)+b''.join(level[128:] for level in levels)
assert payload[84:88]==b'DXT5'
assert len(payload)==128+sum(max(1,((512>>i)+3)//4)**2*16 for i in range(10))
(root/'PBsTetris/assets/stone.dds').write_bytes(payload)
print('stone.dds: DXT5, 512 x 512, 10 mip levels')
image=Image.open(root/'art/sanctuary-source.png').convert('RGBA')
levels=[]
for i in range(12):
    buffer=BytesIO()
    image.resize((max(1,2048>>i),max(1,1024>>i)),Image.Resampling.LANCZOS).save(buffer,format='DDS',pixel_format='DXT5')
    levels.append(buffer.getvalue())
header=bytearray(levels[0][:128])
struct.pack_into('<I',header,8,struct.unpack_from('<I',header,8)[0]|0x20000)
struct.pack_into('<I',header,20,len(levels[0])-128)
struct.pack_into('<I',header,28,len(levels))
struct.pack_into('<I',header,88,0)
struct.pack_into('<I',header,108,0x1000|0x8|0x400000)
(root/'PBsTetris/assets/sanctuary.dds').write_bytes(bytes(header)+b''.join(level[128:] for level in levels))
print('sanctuary.dds: DXT5, 2048 x 1024, 12 mip levels')

# The snowflake is generated rather than drawn: it is a soft white dot, and a source PNG for
# it would only be a copy of these four lines.
size=64
flake=Image.new('RGBA',(size,size),(0,0,0,0))
pixels=flake.load()
for y in range(size):
    for x in range(size):
        d=(((x-(size-1)/2)/(size/2))**2+((y-(size-1)/2)/(size/2))**2)**.5
        if d<1:
            pixels[x,y]=(235,244,255,int(255*(1-d)**2.2))
levels=[]
for i in range(7):
    buffer=BytesIO()
    flake.resize((max(1,size>>i),max(1,size>>i)),Image.Resampling.LANCZOS).save(buffer,format='DDS',pixel_format='DXT5')
    levels.append(buffer.getvalue())
header=bytearray(levels[0][:128])
struct.pack_into('<I',header,8,struct.unpack_from('<I',header,8)[0]|0x20000)
struct.pack_into('<I',header,20,len(levels[0])-128)
struct.pack_into('<I',header,28,len(levels))
struct.pack_into('<I',header,88,0)
struct.pack_into('<I',header,108,0x1000|0x8|0x400000)
payload=bytes(header)+b''.join(level[128:] for level in levels)
assert payload[84:88]==b'DXT5'
assert len(payload)==128+sum(max(1,((size>>i)+3)//4)**2*16 for i in range(7))
(root/'PBsTetris/assets/flake.dds').write_bytes(payload)
print('flake.dds: DXT5, 64 x 64, 7 mip levels')
