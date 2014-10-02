#!/usr/bin/python 

import socket
import time
import math
import smbus

IPADDR = '192.168.7.1'
PORTNUM = 9000

bus = smbus.SMBus(1)

def read_word_acel(adr):
    high = bus.read_byte_data(0x18, adr)
    low = bus.read_byte_data(0x18, adr-1)
    val = (high << 8) + low
    return val

def read_word_2c_acel(adr):
    val = read_word_acel(adr)
    if (val >= 0x8000):
        return -((65535 - val) + 1)
    else:
        return val
    
def read_word_gyro(adr):
    high = bus.read_byte_data(0x6A, adr)
    low = bus.read_byte_data(0x6A, adr-1)
    val = (high << 8) + low
    return val

def read_word_2c_gyro(adr):
    val = read_word_gyro(adr)
    if (val >= 0x8000):
        return -((65535 - val) + 1)
    else:
        return val    

def read_word_mag(adr):
    high = bus.read_byte_data(0x1e, adr)
    low = bus.read_byte_data(0x1e, adr+1)
    val = (high << 8) + low
    return val

def read_word_2c_mag(adr):
    val = read_word_mag(adr)
    if (val >= 0x8000):
        return -((65535 - val) + 1)
    else:
        return val
    



bus.write_byte_data(0x1e,0, 0b01110000) # Set to 8 samples @ 15Hz
bus.write_byte_data(0x1e,1, 0b00100000) # 1.3 gain LSb / Gauss 1090 (default)
bus.write_byte_data(0x1e,2, 0b00000000) # Continuous sampling

scale_mag = 0.92



x_offset_mag = -205
y_offset_mag = -78

    
    
timepres = 0
roll = 0
pitch = 0
yaw_acel = 0
roll_acel = 0
pitch_acel = 0
yaw = 0
roll_gyro = 0
pitch_gyro = 0
yaw_gyro = 0

bearing=0

for i in range(1,5):
    x_out_mag = (read_word_2c_mag(3) - x_offset_mag ) * scale_mag
    y_out_mag = (read_word_2c_mag(7) - y_offset_mag )* scale_mag
    z_out_mag = read_word_2c_mag(5) * scale_mag# Its requiered to Read this value or the Magnetometer doesn't give the data set right 
    bearing  = bearing +math.degrees(math.atan2(y_out_mag, x_out_mag))
    
bearing=bearing/5 
print "offset mag :"+str(bearing)



##########################
##Open the Socket to send the UDP data
##########################
s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM, 0)
s.connect((IPADDR, PORTNUM))


while 1:
    timepast=timepres
    timepres = time.time();
    
    #To take one measurement in gyro
    bus.write_byte_data(0x6A, 32, 15)
    dt = timepres-timepast
    x_out_gyro = read_word_2c_gyro(41)*(8.5/1000)*0.0657
    y_out_gyro = read_word_2c_gyro(43)*(8.5/1000)*0.0657
    z_out_gyro = read_word_2c_gyro(45)*(8.5/1000)*0.0657
    if (abs(x_out_gyro) < 1):
        #roll_gyro = roll_gyro + (x_out_gyro)
        x_out_gyro= 0;
    if (abs(y_out_gyro) < 1):
        #pitch_gyro = pitch_gyro + (y_out_gyro)
        y_out_gyro= 0;
    if (abs(z_out_gyro) > 1):
        yaw_gyro = yaw_gyro + (z_out_gyro)
    
     #To take one measurement in acel
    bus.write_byte_data(0x18, 32, 39)
    x_out_acel = read_word_2c_acel(41)*12/4096
    y_out_acel = read_word_2c_acel(43)*12/4096
    z_out_acel = read_word_2c_acel(45)*12/4096 
    roll_acel = - math.atan2(y_out_acel, z_out_acel)* 57.295779513082320876798154814105  #+math.pi
    pitch_acel = math.atan2(x_out_acel, z_out_acel) * 57.295779513082320876798154814105 #+math.pi
    
    x_out_mag = (read_word_2c_mag(3) - x_offset_mag ) * scale_mag
    y_out_mag = (read_word_2c_mag(7) - y_offset_mag )* scale_mag
    z_out_mag = read_word_2c_mag(5) * scale_mag# Its requiered to Read this value or the Magnetometer doesn't give the data set right 
    yaw_mag = math.degrees(math.atan2(y_out_mag, x_out_mag))
    
    #print "Acel values X:" + str(x_out) + ",Y : "+ str(y_out)+ ",Z : "+str(z_out)
    print "Pitch_acel :" + str(pitch_acel) + "\t , Roll_acel: " + str(roll_acel)
    
    
    

    s.send(str(round( roll,2))+','+str(round(pitch,2))+','+str(round( (yaw_mag-bearing),2)))

    #print "Value of  Yaw_gyro: " + str(yaw_gyro)+ ",  Roll_gyro : " +str(roll_gyro) + ",  Pitch_gyro : " +str(pitch_gyro) + ", Dt : " + str(dt)
    pitch = 0.95 *(pitch +y_out_gyro) + 0.05*pitch_acel
    roll = 0.95 *(roll+x_out_gyro) + 0.05*roll_acel
    print "Final value Pitch : " + str( pitch ) + ", Final Roll : " +str(roll)+ ", Final Yaw : " +str(yaw_mag-bearing)
    
    
    
    
    
    
    time.sleep(0.05)


# close the socket
s.close()

