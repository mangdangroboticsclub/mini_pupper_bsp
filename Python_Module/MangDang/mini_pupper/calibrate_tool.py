import re
import tkinter as tk
import tkinter.messagebox
from tkinter import *
import _thread
import time
import os
import sys

import numpy as np
from pathlib import Path
from MangDang.mini_pupper.HardwareInterface import HardwareInterface
import MangDang.mini_pupper.nvram as nvram


class LegPositionScale:

    def __init__(self,root,location_x,location_y,leg_name):


        self.LocationX = location_x
        self.LocationY = location_y

        delt_x = 40
        delt_y = 45
        
        self.Value1 = DoubleVar()
        self.Value2 = DoubleVar()
        self.Value3 = DoubleVar()

        self.title =  Label(root,text = leg_name,font = ('bold',16))
        
        self.label1 = Label(root,text = 'Hip')
        self.slider1 = Scale(root,from_=-100,to=100,variable = self.Value1,length = 120,orient = HORIZONTAL)
        
        self.label2 = Label(root,text = 'Thigh')
        self.slider2 = Scale(root,from_=-55,to=145,variable = self.Value2,length = 120,orient = HORIZONTAL)

        self.label3 = Label(root,text = 'Calf')
        self.slider3 = Scale(root,from_=-145,to=55,variable = self.Value3,length = 120,orient = HORIZONTAL)

        
        self.label1.place(x=location_x, y=location_y + 20)
        self.label2.place(x=location_x, y=location_y + delt_y*1+ 20)
        self.label3.place(x=location_x, y=location_y + delt_y*2+ 20)
        
        self.slider1.place(x=location_x + delt_x, y=location_y )
        self.slider2.place(x=location_x + delt_x, y=location_y + delt_y*1)
        self.slider3.place(x=location_x + delt_x, y=location_y + delt_y*2)
        
        self.title.place(x=location_x + 70, y=location_y + delt_y*3)

        
    def setValue(self,value):

        self.slider1.set(value[0])
        self.slider2.set(value[1])
        self.slider3.set(value[2])
        
        return True
    
    def getValue(self):
        
        value = []
        value.append(self.Value1.get())
        value.append(self.Value2.get())
        value.append(self.Value3.get())
        
        return value



class CalibrationTool:

    def __init__(self,title, width, height):

        self.Run = True
        self.FileAllLines = []
        
        
        #leg slider value
        self.Leg1SlidersValue = [0,0,0]
        self.Leg2SlidersValue = [0,0,0]
        self.Leg3SlidersValue = [0,0,0]
        self.Leg4SlidersValue = [0,0,0]

        
        # calibration data
        self.MICROS_PER_RAD = 11.111 * 180.0 / np.pi
        self.Matrix_EEPROM = np.array([[0, 0, 0, 0], [45, 45, 45, 45], [-45, -45, -45, -45]])
     
        self.ServoStandardLAngle =     [[0,0,0,0],[45,45,45,45],[-45,-45,-45,-45]]
        self.ServoNeutralLAngle =      [[0,0,0,0],[45,45,45,45],[-45,-45,-45,-45]]
        self.NocalibrationServoAngle = [[0,0,0,0],[45,45,45,45],[-45,-45,-45,-45]]
        self.CalibrationServoAngle =   [[0,0,0,0],[45,45,45,45],[-45,-45,-45,-45]]
        
        #build main window
        self.MainWindow = tk.Tk()
        screenwidth = self.MainWindow.winfo_screenwidth()
        screenheight = self.MainWindow.winfo_screenheight()
        size = '%dx%d+%d+%d' % (width, height, (screenwidth - width) / 2, (screenheight - height) / 2)
        self.MainWindow.geometry(size)
        self.MainWindow.title('Mini Pupper')   #Mini Pupper Calibration Tool
        self.MainWindow.update()
        
        #init title
        self.Title = Label(self.MainWindow,text = title,font = ('bold',30))
        self.Title.place(x=140,y=15)
        
        #init robot image
        self.photo = tk.PhotoImage(file=Path(__file__).with_name('MiniPupper.Calibration.png'))
        self.MainImg = Label(self.MainWindow,image = self.photo)
        self.MainImg.place(x=230,y=60)

        #init read update button
        self.ResetButton = Button(self.MainWindow,text   = ' Reset ',font = ('bold',20),command=self.ResetButtonEvent)
        self.UpdateButton = Button(self.MainWindow,text = 'Update',font = ('bold',20),command=self.updateButtonEvent)
        self.RestoreButton = Button(self.MainWindow,text   = 'Restore',font = ('bold',7),command=self.RestoreButtonEvent)

        self.ResetButton.place(x=600,y=100)
        self.UpdateButton.place(x=600,y=200)
        self.RestoreButton.place(x=160,y=80) 
        
        #build 4 legs sliders
        self.Leg1Calibration  = LegPositionScale(self.MainWindow,20,300, 'Leg 1')
        self.Leg2Calibration  = LegPositionScale(self.MainWindow,220,300,'Leg 2')
        self.Leg3Calibration  = LegPositionScale(self.MainWindow,420,300,'Leg 3')
        self.Leg4Calibration  = LegPositionScale(self.MainWindow,620,300,'Leg 4')
                
        self.Leg1Calibration.setValue([self.ServoNeutralLAngle[0][0],self.ServoNeutralLAngle[1][0],self.ServoNeutralLAngle[2][0]])
        self.Leg2Calibration.setValue([self.ServoNeutralLAngle[0][1],self.ServoNeutralLAngle[1][1],self.ServoNeutralLAngle[2][1]])
        self.Leg3Calibration.setValue([self.ServoNeutralLAngle[0][2],self.ServoNeutralLAngle[1][2],self.ServoNeutralLAngle[2][2]])
        self.Leg4Calibration.setValue([self.ServoNeutralLAngle[0][3],self.ServoNeutralLAngle[1][3],self.ServoNeutralLAngle[2][3]])
        

    def setLegSlidersValue(self,value):
        
        self.Leg1Calibration.setValue(value[0])
        self.Leg2Calibration.setValue(value[1])
        self.Leg3Calibration.setValue(value[2])
        self.Leg4Calibration.setValue(value[3])
        
        return value
        
    def readCalibrationFile(self):
    
        #read all lines text from EEPROM
        try:
            data = nvram.read()
            self.MICROS_PER_RAD = data['MICROS_PER_RAD']
            self.Matrix_EEPROM = data['NEUTRAL_ANGLE_DEGREES']
            print("Get nv calibration params: \n" , self.Matrix_EEPROM)
        except:
            matrix = np.array([[0, 0, 0, 0], [0, 0, 0, 0], [0, 0, 0, 0]])
            self.Matrix_EEPROM = matrix
        #update
        
        for i in range(3):
            for j in range(4):
                self.NocalibrationServoAngle[i][j] = self.Matrix_EEPROM[i,j]
                self.CalibrationServoAngle[i][j] = self.Matrix_EEPROM[i,j]
    
        return True
        
    def updateCalibrationMatrix(self,angle):
    
        for i in range(3):
            for j in range(4):
                self.Matrix_EEPROM[i,j] = angle[i][j]

        return True   
         
    def writeCalibrationFile(self):
    
        #write matrix to EEPROM
        data = {'MICROS_PER_RAD': self.MICROS_PER_RAD,
                'NEUTRAL_ANGLE_DEGREES': self.Matrix_EEPROM}
        nvram.write(data)

    def getLegSlidersValue(self):

        value = [[0,0,0,0],[0,0,0,0],[0,0,0,0]]
        self.Leg1SlidersValue = self.Leg1Calibration.getValue()
        self.Leg2SlidersValue = self.Leg2Calibration.getValue()
        self.Leg3SlidersValue = self.Leg3Calibration.getValue()
        self.Leg4SlidersValue = self.Leg4Calibration.getValue()

        value[0] = [self.Leg1SlidersValue[0],self.Leg2SlidersValue[0],self.Leg3SlidersValue[0],self.Leg4SlidersValue[0]]
        value[1] = [self.Leg1SlidersValue[1],self.Leg2SlidersValue[1],self.Leg3SlidersValue[1],self.Leg4SlidersValue[1]]
        value[2] = [self.Leg1SlidersValue[2],self.Leg2SlidersValue[2],self.Leg3SlidersValue[2],self.Leg4SlidersValue[2]]
        
        self.ServoNeutralLAngle = value
        
        return value

    def ResetButtonEvent(self):

        value = [[0,0,0],[0,0,0],[0,0,0],[0,0,0]]
        for i in range(3):
            for j in range(4):
                value[j][i] = self.ServoStandardLAngle[i][j]
            
        self.setLegSlidersValue(value)
        
        return True
    
    def updateButtonEvent(self):

        # update angle matrix 
        value = self.getLegSlidersValue()
        angle = [[0,0,0,0],[0,0,0,0],[0,0,0,0]]
        for i in range(3):
            for j in range(4):
                angle[i][j] = self.ServoStandardLAngle[i][j] - value[i][j] +self.CalibrationServoAngle[i][j]

        # limit angle
        for i in range(3):
            for j in range(4):
                if angle[i][j] > 90:
                    angle[i][j] = 90
                elif angle[i][j] < -90:
                    angle[i][j] = -90
        
        # popup message box 
        result = tk.messagebox.askquestion('Info:','****** Angle Matrix ******\n'
                                        +str(angle[0])+'\n'
                                        +str(angle[1])+'\n'
                                        +str(angle[2])+'\n'
                                        +'****************************\n'
                                        +'      Update Matrix?')
        
        # update matrix
        if result == 'yes':
            self.updateCalibrationMatrix(angle)
            self.writeCalibrationFile()   
                            
            print('******** Angle Matrix ********')
            print(angle[0])
            print(angle[1])
            print(angle[2])
            print('******************************')
        
        return True

    def RestoreButtonEvent(self):

        # update angle matrix 
        value = self.getLegSlidersValue()
        angle = [[0,0,0,0],[45,45,45,45],[-45,-45,-45,-45]]
        
        # popup message box 
        result = tk.messagebox.askquestion('Warning','Are you sure you want to Restore Factory Setting!?')
        
        # update matrix
        if result == 'yes':
            self.updateCalibrationMatrix(angle)
            self.writeCalibrationFile()   
                            
            print('******** Angle Matrix ********')
            print(angle[0])
            print(angle[1])
            print(angle[2])
            print('******************************')
            sys.exit()
            
            for i in range(3):
                for j in range(4):
                    self.NocalibrationServoAngle[i][j] = angle[i][j]
                    self.CalibrationServoAngle[i][j] = angle[i][j]
            value = [[0,0,0],[0,0,0],[0,0,0],[0,0,0]]
            for i in range(3):
                for j in range(4):
                    value[j][i] = self.ServoStandardLAngle[i][j]
            
        self.setLegSlidersValue(value)
        
        return True

    def runMainWindow(self):
        
        self.MainWindow.mainloop()
        
        return True

    def stopMainWindow(self):
        
        self.Run = False
        
        return True

def updateServoValue(MainWindow,servo):

    while MainWindow.Run:

        #update leg slider value
        value = MainWindow.getLegSlidersValue()
        
        #control servo
        joint_angles = np.zeros((3, 4))
        joint_angles2 = np.zeros((3, 4))
        for i in range(3):
            for j in range(4):
                joint_angles[i,j] = (value[i][j] - (MainWindow.NocalibrationServoAngle[i][j] - MainWindow.CalibrationServoAngle[i][j]))*0.01745
            
        servo.set_actuator_postions(joint_angles)
        time.sleep(0.01)


def main():

    ##############################################    
    MainWindow = CalibrationTool('Mini Pupper Calibration Tool',800,500)
    MainWindow.readCalibrationFile()
    hardware_interface = HardwareInterface()
    try:
        _thread.start_new_thread( updateServoValue, ( MainWindow, hardware_interface,) )
    
    except:
        print ('Thread Error')
       
    MainWindow.runMainWindow()
    MainWindow.stopMainWindow()

if __name__ == "__main__":
    main()
