
import wave
import sys
import struct
import os
import time
import httplib
import random
from random import randint


ip = wave.open(sys.path[0]+'/test.wav', 'r')
info = ip.getparams()
# print info
frame_list = []
for i in range(ip.getnframes()):
    sframe = ip.readframes(1)
    amplitude = struct.unpack('<h', sframe)[0]
    frame_list.append(amplitude)
ip.close()
for i in range(0,len(frame_list)):
    if abs(frame_list[i]) < 25:
        frame_list[i] = 0
################################  Find Out most louder portions of the audio file ###########################
thresh = 30
output = []
nonzerotemp = []
length = len(frame_list)
i = 0
while i < length:
    zeros = []
    while i < length and frame_list[i] == 0:
        i += 1
        zeros.append(0)
    if len(zeros) != 0 and len(zeros) < thresh:
        nonzerotemp += zeros
    elif len(zeros) > thresh:
        if len(nonzerotemp) > 0 and i < length:
            output.append(nonzerotemp)
            nonzerotemp = []
    else:
        nonzerotemp.append(frame_list[i])
        i += 1
if len(nonzerotemp) > 0:
    output.append(nonzerotemp)

chunks = []
for j in range(0,len(output)):
    if len(output[j]) > 3000:
        chunks.append(output[j])
#########################################################################################################

for l in chunks:
    for m in range(0,len(l)):
        if l[m] == 0:
             l[m] = randint(-0,+0)

inc_percent = 1 #10 percent

for l in chunks:
    for m in range(0,len(l)):
        if l[m] <= 0:
            # negative value
            a = l[m]
            l[m] = 0 - abs(l[m]) + abs(l[m])*inc_percent/100
            b = l[m]
        else:
            #positive vaule
            a = l[m]
            l[m] =     abs(l[m]) + abs(l[m])*inc_percent/100
            b= l[m]

########################################################

# Below code generates separate wav files depending on the number of loud voice detected.

NEW_RATE = 1 #Change it to > 1 if any amplification is required

# print '[+] Possibly ',len(chunks),'number of loud voice detected...'
for i in range(0, len(chunks)):
    new_frame_rate = info[0]*NEW_RATE
    # print '[+] Creating No. ',str(i),'file..'
    filename = sys.path[0]+'/sound'+str(i)+'.wav'
    split = wave.open(sys.path[0]+'/sound'+str(i)+'.wav', 'w')
    split.setparams((info[0],info[1],info[2],0,info[4],info[5]))
#   split.setparams((info[0],info[1],new_frame_rate,0,info[4],info[5]))

    #Add some silence at start selecting +15 to -15
    for k in range(0,3000):
        single_frame = struct.pack('<h', randint(-25,+25))
        split.writeframes(single_frame)
    # Add the voice for the first time
    for frames in chunks[i]:
        single_frame = struct.pack('<h', frames)
        split.writeframes(single_frame)

    #Add some silence in between two digits
    for k in range(0,5000):
        single_frame = struct.pack('<h', randint(-25,+25))
        split.writeframes(single_frame)

    # # Repeat effect :  Add the voice second time
    # for frames in chunks[i]:
    #     single_frame = struct.pack('<h', frames)
    #     split.writeframes(single_frame)

    # #Add silence at end
    # for k in range(0,3000):
    #     single_frame = struct.pack('<h', randint(-25,+25))
    #     split.writeframes(single_frame)

    split.close()#Close each files

    # newfilename = sys.path[0] + '/test/' +str(random.randint(10000, 1000000)) + '.wav'
    # print newfilename
    # if not os.path.exists(newfilename) or (os.path.exists(newfilename) and (os.path.getsize(newfilename) != os.path.getsize(filename))):
    #     open(newfilename, "wb").write(open(filename, "rb").read())
    # else:
    #     print "not copy"

# print os.getcwd()
# print sys.path[0]
# print sys.argv[0]
# print os.path.split(os.path.realpath(__file__))[0]
f1 = open(sys.path[0]+'/soundindex.txt','w')
f1.write(str(i))
f1.close
