import binascii
import codecs
from Crypto.Cipher import AES
from Crypto import Random

def encrypt(passwrd, message):
    msglist = []
    key = bytes(passwrd, "utf-8")
    iv = Random.new().read(AES.block_size)
    cipher = AES.new(key, AES.MODE_CFB, iv)
    msg = iv + cipher.encrypt(bytes(message, "utf-8"))
    msg = binascii.hexlify(msg)
    for letter in str(msg):
        msglist.append(letter)
    msglist.remove("b")
    msglist.remove("'")
    msglist.remove("'")
    for letter in msglist:
        print(letter, end="")
    print("")

def decrypt(passwrd, message):
    msglist = []
    key = bytes(passwrd, "utf-8")
    iv = Random.new().read(AES.block_size)
    cipher = AES.new(key, AES.MODE_CFB, iv)
    msg = cipher.decrypt(binascii.unhexlify(bytes(message, "utf-8")))[len(iv):]
    for letter in str(msg):
        msglist.append(letter)
    msglist.remove("b")
    msglist.remove("'")
    msglist.remove("'")
    for letter in msglist:
        print(letter, end="")
    print("")


# decrypt('b093c0d3b281ba6da1eacc608620abd8', '')

x = b'b093c0d3b281ba6da1eacc608620abd8'
print(codecs.decode(x, 'hex'))