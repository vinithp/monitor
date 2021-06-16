def lalp():
    for c in range(97, 123):
        print(chr(c));

def ualp():
    for c in range(65,91):
        print(chr(c));
        
def lmix():
    for a in range(97,123):
        for b in range(97,123):
            print(chr(a)+chr(b));

def umix():
    for a in range(65,91):
        for b in range(65,91):
            print(chr(a)+chr(b));


lalp(); 
ualp();
lmix();
umix();
