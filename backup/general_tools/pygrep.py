#!/usr/bin/python3
import typer
import sys
from html import unescape
from urllib.parse import quote_plus, unquote

#-----------------commands---------------#
comm = typer.Typer()
@comm.command()
def urldc(fname: str = typer.Argument(None)):
    if fname==None:
        pipe(dcurl)
    else:
        file(fname,dcurl)

@comm.command()
def urlec(fname: str = typer.Argument(None)):
    if fname==None:
        pipe(ecurl)
    else:
        file(fname,ecurl)

@comm.command()
def htmldc(fname: str = typer.Argument(None)):
    if fname==None:
        pipe(dchtml)
    else:
        file(fname,dchtml)

#---------------read_file-------------------#
def pipe(cmd):
    for line in sys.stdin:	
        cmd(line.replace('\n',''))
        
def file(fname,cmd):
    with open(fname) as filelines:
        for line in filelines:
            cmd(line.replace('\n',''))

#-------------------------------------------#
def dchtml(line):
    print(unescape(unescape(line)))

def dcurl(line):
    print(unquote(line))

def ecurl(line):
    print(quote_plus(line))
#-------------------------------------------#

if __name__ == "__main__":
    comm()

    
    


