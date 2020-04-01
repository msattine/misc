#!/cpd/misc/bin/python

import sys

sys.path.append('/home/msattine/Scripts/Python/Installed/lib/python2.7/site-packages/')

import re
from optparse import OptionParser
import xlwt

parser = OptionParser()
parser.add_option("-c", "--cmd", type="int", default=0, help="""Options available:						
#0 --> Dump bit stream from command file,						
#1 --> Decode MOSI bit stream from file and dump commands,						
#2 --> Decode MISO bit stream from file,					
#3 --> Decode MISO and MOSI bit streams from input files,						
#4 --> Dump bit stream for single command,					
#5 --> Decode single MOSI bit stream and dump command,					
#6 --> Decode single MISO bit stream,					
#7 --> Compute CRC
""")
parser.add_option("-i", "--mosi_infile", type="string", help="Input mosi command/bit-stream file")
parser.add_option("-m", "--miso_infile", type="string", help="Input miso bit-stream file")
parser.add_option("-s", "--stream", type="string", default="00", help="Input command or bit stream")
parser.add_option("-o", "--out_file", type="string", default="None", help="Output file")

(options, args) = parser.parse_args()

command = options.cmd
mosi_file = options.mosi_infile
miso_file = options.miso_infile
bs = options.stream
out_file = options.out_file


poly = '{:09b}'.format(0x12f)
seed = '{:08b}'.format(0xff)

def crc_remainder(input_bitstring, polynomial_bitstring, initial_filler):
	"""This function computes crc of given 56-bit input string
	input_bitstring --> Input bit string
	polynomial_bitstring --> Polynomial bit string
	initial_filler --> Initial seed
	"""
	len_polynomial = len(polynomial_bitstring)
	len_input = len(input_bitstring)
	input_padded_array = list(input_bitstring)
	crc = list(initial_filler)
	crc.reverse()
	crc_g = list(crc)
	poly = list(polynomial_bitstring)
	poly.reverse()
	for i in range(len_input):
		crc_g[0] = '0' if crc[len_polynomial-2] == input_padded_array[i] else '1'
		for j in range(len_polynomial - 2):
			k = '1' if crc_g[0] == '1' and poly[j+1] == '1' else '0'
			crc_g[j+1] = '0' if k == crc[j] else '1'
		crc = list(crc_g)
	crc.reverse()
	return ''.join(crc)

def comp_crc(frame):
	crc = crc_remainder(frame, poly, seed)
	return crc

def form_frame(cmd, addr, data, alen, mval):
	cmd7 = (cmd & 0x80) >> 7
	cmd7_b = 0 if cmd7 else 1
	frame_data = (cmd << 48) + (addr << 40) + (0 << 39) + (cmd7_b << 38) + (alen << 36) + ((data & 0xfffffff0) << 4) + (1 << 7) + (mval << 4) + (data & 0x0000000f)
	frame_b = '{:056b}'.format(frame_data)
	return ''.join([frame_b, comp_crc(frame_b)])

def norm_read(diag_id, sens, cm5):
	"""This function generates SPI command to do a normal mode read
	diag_id --> Diagnostic ID
	sens --> Which channel (1 - primary, 0 - secondary)
	cm5 --> cache command (1 - set)
	"""
	cmd = (1 << 7) + (0 << 6) + (cm5 << 5) + (sens << 4) + diag_id
	return form_frame(cmd, 0, 0, 0, 0)

def norm_write(addr, data, cm5, alen):
	"""This function generates SPI command to do a normal mode write
	addr --> System address to write data to
	data --> Data
	cm5 --> Cache command
	alen --> Access length
	"""
	cmd = (cm5 << 5) + 0xF
	return form_frame(cmd, addr, data, alen, 0)

def dbg_read(sysreg, addr, cm5, alen, mval):
	"""This function generates SPI command to do a debug mode read
	sysreg --> 1 - To read system registers in debug mode, 0 - To read SPI config registers
	addr --> Address
	cm5 --> Ccache command
	alen --> Access length
	mval --> auto increment mode
	"""
	cmd = (1 << 7) + (1 << 6) + (cm5 << 5) + (sysreg << 4) + 0xF
	return form_frame(cmd, addr, 0, alen, mval)

def dbg_write(sysreg, addr, cm5, data, alen, mval):
	"""This function generates SPI command to do a debug mode write
	sysreg --> 1 - To write to system registers in debug mode, 0 - To write to SPI config registers
	addr --> Address
	data --> Data
	cm5 --> Cache command
	alen --> Access length
	mval --> auto increment mode
	"""
	cmd = (0 << 7) + (1 << 6) + (cm5 << 5) + (sysreg << 4) + 0xF
	return form_frame(cmd, addr, data, alen, mval)

def dec_mosi(bs):
	frame = bs[0:56]
	cmd_76 = int(frame[0:2], 2)
	if(cmd_76 == 0):
		func = "norm_write"
		addr = hex(int(frame[8:16], 2))
		data = hex(int(''.join([frame[-36:-8], frame[-4:]]), 2))
		cm5 = int(frame[2], 2)
		alen = int(frame[18:20], 2)
		return "%s(addr=%s, data=%s, cm5=%d, alen=%d)" % (func, addr, data, cm5, alen)
	elif(cmd_76 == 2):
		func = "norm_read"
		diag_id = int(frame[4:8], 2)
		cm5 = int(frame[2], 2)
		sens = int(frame[3], 2)
		return "%s(diag_id=%d, sens=%s, cm5=%d)" % (func, diag_id, sens, cm5)
	elif(cmd_76 == 1):
		func = "dbg_write"
		addr = hex(int(frame[8:16], 2))
		data = hex(int(''.join([frame[-36:-8], frame[-4:]]), 2))
		cm5 = int(frame[2], 2)
		alen = int(frame[18:20], 2)
		sysreg = int(frame[3], 2)
		mval = int(frame[-7:-4], 2)
		return "%s(sysreg=%d, addr=%s, cm5=%d, data=%s, alen=%d, mval=%d)" % (func, sysreg, addr, cm5, data, alen, mval)
	else:
		func = "dbg_read"
		addr = hex(int(frame[8:16], 2))
		cm5 = int(frame[2], 2)
		alen = int(frame[18:20], 2)
		sysreg = int(frame[3], 2)
		mval = int(frame[-7:-4], 2)
		return "%s(sysreg=%d, addr=%s, cm5=%d, alen=%d, mval=%d)" % (func, sysreg, addr, cm5, alen, mval)

def dec_miso(bs, typ):
	mode = int(bs[0], 2)
	crc_rec = bs[-8:]
	frame = bs[0:56]
	crc = comp_crc(frame)
	crc_fail = 0
	ret1 = ""
	if(mode == 1):
		crc = list(crc)
		crc = ['1' if x == '0' else '0' for x in crc]
		crc = ''.join(crc)
	if(crc != crc_rec):
		ret1 = "CRC Fail - Exp:%s, Rec: %s" % (crc, crc_rec)
		crc_fail = 1
	elif(mode == 0): # Normal mode
		md = "Normal"
		ctr = int(frame[1:3], 2)
		sta = "0x%02x" % int(''.join([frame[4:6], frame[38:44]]), 2)
		pang = "0x%04x" % int(frame[6:20], 2)
		sang = "0x%03x" % int(frame[20:32], 2)
		diag_id = "0x%02x" % int(''.join([frame[32:35], frame[36:38]]), 2)
		diag_data = "0x%03x" % int(frame[44:], 2)
		data = "NA"
		ret1 = "Normal mode: CTR = %d, STA = %s, PANG = %s, SANG = %s, D_ID = %s, D_DATA = %s" % (ctr, sta, pang, sang, diag_id, diag_data)
	else: # Debug mode
		md = "Debug"
		ctr = int(frame[1:3], 2)
		sta = "0x%02x" % int(''.join([frame[4:6], frame[38:44]]), 2)
		diag_id = "0x%02x" % int(''.join([frame[32:35], frame[36:38]]), 2)
		data = "0x%08x" % int(''.join([frame[8:32], frame[48:56]]), 2)
		pang = "NA"
		sang = "NA"
		diag_data = "NA"
		ret1 = "Debug Mode: CTR = %d, STA = %s, D_ID = %s, DATA = %s" % (ctr, sta, diag_id, data)
	if(typ == 0):
		return ret1
	else:
		if(crc_fail):
			return ["CRC Fail"]
		else:
			return [md, ctr, sta, pang, sang, diag_id, diag_data, data]


if(command == 0):
	fh = open(mosi_file, 'r')
	lines = fh.read().split("\n")[:-1]
	write_to_file = 0
	if(out_file != "None"):
		write_to_file = 1
		fh1 = open(out_file, 'w')
	for line in lines:
		dec = eval(line)
		if(write_to_file):
			fh1.write(dec)
			fh1.write("\n")
		else: print dec
	fh.close()
	fh1.close()
elif(command == 1):
	fh = open(mosi_file, 'r')
	lines = fh.read().split("\n")[:-1]
	write_to_file = 0
	if(out_file != "None"):
		write_to_file = 1
		fh1 = open(out_file, 'w')
	for line in lines:
		line = re.sub(',', '', line)
		line = re.sub('\r', '', line)
		dec = dec_mosi(line)
		if(write_to_file):
			fh1.write(dec)
			fh1.write("\n")
		else: print dec
	fh.close()
	fh1.close()
elif(command == 2):
	fh = open(miso_file, 'r')
	lines = fh.read().split("\n")[:-1]
	write_xls = 0
	if(out_file != "None"):
		write_xls = 1
		wb = xlwt.Workbook()
		sheet = wb.add_sheet("MISO")
		style = xlwt.easyxf('font: bold 1')
		sheet.write(0,0,"Mode", style)
		sheet.write(0,1,"Frame Cntr", style)
		sheet.write(0,2,"STA", style)
		sheet.write(0,3,"PANG", style)
		sheet.write(0,4,"SANG", style)
		sheet.write(0,5,"DIAG ID", style)
		sheet.write(0,6,"DIAG DATA", style)
		sheet.write(0,7,"DATA", style)
		sheet.col(7).width = 256*12
		sheet.col(1).width = 256*12
		sheet.col(6).width = 256*12
	row = 1
	for line in lines:
		line = re.sub(',', '', line)
		line = re.sub('\r', '', line)
		if(write_xls):
			dec = dec_miso(line, 1)
			if(len(dec) == 1): sheet.write(row, 0, dec[0])
			else:
				sheet.write(row,0, dec[0])
				sheet.write(row,1, dec[1])
				sheet.write(row,2, dec[2])
				sheet.write(row,3, dec[3])
				sheet.write(row,4, dec[4])
				sheet.write(row,5, dec[5])
				sheet.write(row,6, dec[6])
				sheet.write(row,7, dec[7])
			row = row + 1
		else: 
			dec = dec_miso(line, 0)
			print dec
	if(write_xls): wb.save(out_file)
elif(command == 3):
	fh = open(miso_file, 'r')
	fh1 = open(mosi_file, 'r')
	lines_miso = fh.read().split("\n")[:-1]
	lines_mosi = fh1.read().split("\n")[:-1]
	write_xls = 0
	if(out_file != "None"):
		write_xls = 1
		wb = xlwt.Workbook()
		sheet = wb.add_sheet("MOSI_MISO")
		style = xlwt.easyxf('font: bold 1')
		sheet.write(0,0,"MOSI Command", style)
		sheet.write(0,1,"Mode", style)
		sheet.write(0,2,"Frame Cntr", style)
		sheet.write(0,3,"STA", style)
		sheet.write(0,4,"PANG", style)
		sheet.write(0,5,"SANG", style)
		sheet.write(0,6,"DIAG ID", style)
		sheet.write(0,7,"DIAG DATA", style)
		sheet.write(0,8,"DATA", style)
		sheet.col(8).width = 256*12
		sheet.col(2).width = 256*12
		sheet.col(7).width = 256*12
		sheet.col(0).width = 256*70
	row = 1
	num_cmds = len(lines_mosi)
	for num in range(num_cmds):
		line_mosi = lines_mosi[num]
		line_miso = lines_miso[num]
		line_mosi = re.sub(',', '', line_mosi)
		line_mosi = re.sub('\r', '', line_mosi)
		line_miso = re.sub(',', '', line_miso)
		line_miso = re.sub('\r', '', line_miso)
		if(write_xls):
			dec = dec_mosi(line_mosi)
			sheet.write(row,0, dec)
			dec = dec_miso(line_miso, 1)
			if(len(dec) == 1): sheet.write(row, 0, dec[0])
			else:
				sheet.write(row,1, dec[0])
				sheet.write(row,2, dec[1])
				sheet.write(row,3, dec[2])
				sheet.write(row,4, dec[3])
				sheet.write(row,5, dec[4])
				sheet.write(row,6, dec[5])
				sheet.write(row,7, dec[6])
				sheet.write(row,8, dec[7])
			row = row + 1
		else: 
			dec = dec_miso(line_mosi)
			dec1 = dec_miso(line_miso, 0)
			print "%s: %s" % (dec, dec1)
	if(write_xls): wb.save(out_file)
elif(command == 4):
	print eval(bs)
elif(command == 5):
	print dec_mosi(bs)
elif(command == 6):
	print dec_miso(bs, 0)
elif(command == 7):
	print comp_crc(bs)
else:
	print "Wrong command:"
	print parser.print_help()
