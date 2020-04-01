#!/cpd/misc/bin/python

from optparse import OptionParser
from xml.dom.minidom import parse
import xml.etree.ElementTree as et
import glob
import re
parser = OptionParser()
parser.add_option("-i", "--inp", type=str, default="inp.yda", help="""Input yoda file""")
parser.add_option("-o", "--out", type=str, default="out.yda", help="""Output yoda file""")
parser.add_option("-c", "--cmd", type=int, default=0, help="""Command""")
parser.add_option("-t", "--to", type=str, default="Private", help="""If command is 0, change all fields to specified""")
parser.add_option("-b", "--blkf", type=str, default="blkf.txt", help="""Block text file""")
parser.add_option("-B", "--bfile", type=str, default="bfile.txt", help="""Bitfiled visibility file""")
parser.add_option("-p", "--comp_file", type=str, default="inp1.yda", help="""Compare two yoda files and print diff""")
parser.add_option("-r", "--rfile", type=str, default="reg.txt", help="""Register file""")
(options, args) = parser.parse_args()
"""
-c 4   --> to get number of bit fields that are private/public from all yoda files. Need to manually change directory path for this
"""


if(options.cmd == 0):
	tree = et.parse(options.inp)
	fname = options.inp.split('/')[-1]
	rt = tree.getroot()
	for bf in rt.iter('BitField'):
		bf.find('Visibility').text = options.to
	tree.write('temp.yda')
	l = "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n" + open('temp.yda', 'r').read()
	of = open("%s" % (options.out), 'w')
	of.write(l)
	of.close()
elif(options.cmd == 1):
	tree = et.parse(options.inp)
	rt = tree.getroot()
	bf_dict = {}
	arr = open(options.bfile, 'r').read().split('\n')[:-1]
	for l in arr:
		i_arr = l.split()
		bf_dict[i_arr[0]] = i_arr[1]
	for bf in rt.iter('BitField'):
		bf_name = bf.find('Name').text
		if(bf_dict.has_key(bf_name)):
			bf.find('Visibility').text = bf_dict[bf_name]
	tree.write('temp.yda')
	l = "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n" + open('temp.yda', 'r').read()
	of = open(options.inp, 'w')
	of.write(l)
	of.close()
elif(options.cmd == 2):
	blk_arr = open(options.blkf, 'r').read().split('\n')[:-1]
	for blk in blk_arr:
		inf = 'yoda/Projects/ADAR690x/' + blk + '.yda'
		outf = 'yoda/Projects_mod/' + blk + '.yda'
		tree = et.parse(inf)
		rt = tree.getroot()
		for bf in rt.iter('BitField'):
			bf.find('Visibility').text = options.to
		tree.write('temp.yda')
		
		l = "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n" + open('temp.yda', 'r').read()
		of = open(outf, 'w')
		of.write(l)
		of.close()
elif(options.cmd == 3):
	tree = et.parse(options.inp)
	rt = tree.getroot()
	bf_dict = {}
	reg_dict = {}
	for bf in rt.iter('BitField'):
		bf_dict[bf.find('UID').text] = bf.find('Name').text
	for reg in rt.iter('Register'):
		reg_dict[reg.find('Name').text] = reg
	arr = open(options.rfile, 'r').read().split('\n')[:-1]
	bf_dict_m = {}
	for l in arr:
		for bf in reg_dict[l].iter('BitFieldRef'):
			bf_dict_m[bf_dict[bf.find('BF-UID').text]] = 1
	for bf in rt.iter('BitField'):
		bf_name = bf.find('Name').text
		if(bf_dict_m.has_key(bf_name)):
			bf.find('Visibility').text = options.to
	tree.write('temp.yda')
	l = "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n" + open('temp.yda', 'r').read()
	of = open(options.out, 'w')
	of.write(l)
	of.close()
elif(options.cmd == 4): # print number of bitfields private/public
	lst = [f for f in glob.glob(options.inp + '/*.yda')]
	bfs_p5 = {}
	bfs_c1 = {}
	for blk in lst:
		num_private = 0
		num_public = 0
		tree = et.parse(blk)
		rt = tree.getroot()
		for bf in rt.iter('BitField'):
			vis = bf.find('Visibility').text
			name = bf.find('Name').text
			if(vis == 'Private'): num_private = num_private + 1
			elif(vis == 'Public'): num_public = num_public + 1
		blk = re.sub('^.*\/', '', blk)
		bfs_p5[blk] = (num_private, num_public)

	lst = [f for f in glob.glob(options.blkf + '/*.yda')]
	for blk in lst:
		num_private = 0
		num_public = 0
		tree = et.parse(blk)
		rt = tree.getroot()
		for bf in rt.iter('BitField'):
			vis = bf.find('Visibility').text
			name = bf.find('Name').text
			if(vis == 'Private'): num_private = num_private + 1
			elif(vis == 'Public'): num_public = num_public + 1
		blk = re.sub('^.*\/', '', blk)
		bfs_c1[blk] = (num_private, num_public)
	
	for blk in bfs_c1:
		if(bfs_p5.has_key(blk)):
			if(not bfs_p5[blk] == (0,0)): print "%25s: P5(%3d,%3d), C1(%3d,%3d)" % (blk, bfs_p5[blk][0], bfs_p5[blk][1], bfs_c1[blk][0], bfs_c1[blk][1])
		else:
			print "%25s: C1(%3d,%3d)" % (blk, bfs_c1[blk][0], bfs_c1[blk][1])
		#else: print "%s is not found in P5" % blk
	for blk in bfs_p5:
		if(not bfs_p5[blk] == (0,0)):
			if(bfs_p5[blk][0] == 0): print "%25s: All Public" % blk
			elif(bfs_p5[blk][1] == 0): print "%25s: All Private" % blk
			else: print "%25s: Mix" % blk
elif(options.cmd == 5):
	itree = et.parse(options.inp)
	irt = itree.getroot()
	ptree = et.parse(options.comp_file)
	prt = ptree.getroot()
	ibf_dir = {}
	pbf_dir = {}
	for bf in irt.iter('BitField'):
		vis = bf.find('Visibility').text
		name = bf.find('Name').text
		ibf_dir[name] = vis
	for bf in prt.iter('BitField'):
		vis = bf.find('Visibility').text
		name = bf.find('Name').text
		pbf_dir[name] = vis
	inum = len(ibf_dir)
	pnum = len(pbf_dir)
	if(inum != pnum): print "Number of bit fields is different"
	if(inum >= pnum):
		print "Bitfield Name (%s, %s)" % (options.inp, options.comp_file)
		for bf in ibf_dir.keys():
			if( not pbf_dir.has_key(bf)): print "No bit field %s in %s" % (bf, options.comp_file)
			else:
				if(ibf_dir[bf] != pbf_dir[bf]): print "%s(%s, %s)" % (bf, ibf_dir[bf], pbf_dir[bf])
	else:
		print "Bitfield Name (%s, %s)" % (options.inp, options.comp_file)
		for bf in pbf_dir.keys():
			if( not ibf_dir.has_key(bf)): print "No bit field %s in %s" % (bf, options.inp)
			else:
				if(ibf_dir[bf] != pbf_dir[bf]): print "%s(%s, %s)" % (bf, ibf_dir[bf], pbf_dir[bf])
elif(options.cmd == 6):
	itree = et.parse(options.inp)
	irt = itree.getroot()
	print "	Registers without Description:"
	for bf in irt.iter('Register'):
		desc = bf.find('Description').text
		if(desc): desc = desc.strip()
		name = bf.find('Name').text
		if(not desc): print "		%s" % name
	print "	Bit Fields without Description:"
	for bf in irt.iter('BitField'):
		desc = bf.find('Description').text
		if(desc): desc = desc.strip()
		name = bf.find('Name').text
		if(not desc): print "		%s" % name
	print "	Enum Elements without Description:"
	for bf in irt.iter('EnumElement'):
		desc = bf.find('Description').text
		if(desc): desc = desc.strip()
		name = bf.find('Name').text
		if(not desc): print "		%s" % name
elif(options.cmd == 7):
	tree = et.parse(options.inp)
	rt = tree.getroot()
	pub = []
	priv = []
	for bf in rt.iter('BitField'):
		vis = bf.find('Visibility').text
		name = bf.find('Name').text
		if(vis == 'Private'): priv.append(name)
		else: pub.append(name)
	print "Private fields:"
	for f in priv:
		print "	%s" % f
	print "Public fields:"
	for f in pub:
		print "	%s" % f
elif(options.cmd == 8):
	print options.inp
	tree = et.parse(options.inp)
	rt = tree.getroot()
	pub = []
	priv = []
	for bf in rt.iter('BitField'):
		vis = bf.find('Visibility').text
		name = bf.find('Name').text
		if(vis == 'Private' and (re.search('fault', name, re.IGNORECASE) or re.search('flt', name, re.IGNORECASE))): priv.append(name)
	print "Fault bitfields which are private:"
	for f in priv:
		print "	%s" % f
