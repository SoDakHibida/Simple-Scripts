import sys, re

def clean():
  fileIn = open(str(sys.argv[1]), "r")
  
  if fileIn.mode == 'r':
    html = fileIn.read()
    
    cleaner = re.compile('<.*?>')
    cleaned = re.sub(cleaner, '', html)
    print(cleaned)
    
if __name__ == "__main__":
  if len(sys.argv) == 2:
    clean()
  else:
    exit()
